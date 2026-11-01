"""Read-only fail-closed Studio preflight; never starts/syncs/stops Studio or Rojo."""
import argparse
import json
from pathlib import Path
import shlex
import re
import subprocess
import sys
from urllib.parse import unquote

GAMES = {
    'GAME-001': ('default.project.json', 'Rg1'),
    'GAME-002': ('haunted.project.json', 'HauntedCollector'),
    'GAME-003': ('hike-or-die.project.json', 'HikeOrDieGate1'),
}


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def sources(root, project):
    """Use Rojo's resolved paths, including init scripts; no hand-maintained module list."""
    tree = json.loads(run('rojo', 'sourcemap', str(root / project)))
    result = {}

    def visit(node, path):
        if node['className'] in ('Script', 'LocalScript', 'ModuleScript'):
            files = [p for p in node.get('filePaths', []) if p.endswith(('.lua', '.luau'))]
            if len(files) != 1:
                raise ValueError(f'ambiguous source: {path}')
            source = (root / files[0]).resolve()
            if not source.is_relative_to(root):
                raise ValueError(f'source outside checkout: {source}')
            result[path] = source.read_bytes().decode('utf-8').replace('\r\n', '\n')
        for child in node.get('children', []):
            visit(child, path + '/' + child['name'] if path else child['name'])
    visit(tree, '')
    if not result:
        raise ValueError('no synced scripts found')
    return result


def probe(expected):
    # JSON strings also encode these ordinary instance names as valid Luau strings.
    paths = ',\n'.join('{' + ','.join(json.dumps(p) for p in path.split('/')) + '}' for path in expected)
    return '''-- Read only: run in EDIT mode in the independently identified Studio instance.
local result = {name = game.Name, placeId = game.PlaceId, edit = not game:GetService("RunService"):IsRunning(), sources = {}}
for _, path in {\n''' + paths + '''\n} do
    local node = game
    for _, name in path do
        node = node and node:FindFirstChild(name)
    end
    if node and node:IsA("LuaSourceContainer") then
        result.sources[table.concat(path, "/")] = node.Source
    end
end
return game:GetService("HttpService"):JSONEncode(result)
'''


def inspect_processes():
    rows = []
    for line in run('ps', '-axo', 'pid=,ppid=,command=').splitlines():
        parts = line.strip().split(None, 2)
        if len(parts) == 3:
            rows.append((int(parts[0]), int(parts[1]), parts[2]))
    rojo = []
    studios = []
    for pid, ppid, command in rows:
        args = shlex.split(command)
        if len(args) >= 2 and Path(args[0]).name == 'rojo' and args[1] == 'serve':
            rojo.append({'pid': pid, 'ppid': ppid, 'args': args[2:]})
        if args and args[0].endswith('/RobloxStudio.app/Contents/MacOS/RobloxStudio'):
            studios.append(command)
    pids = {s['pid'] for s in rojo}
    servers = []
    for server in rojo:
        if server['ppid'] in pids:
            continue
        cwd = run('lsof', '-a', '-p', str(server['pid']), '-d', 'cwd', '-Fn')
        server['cwd'] = next((line[1:] for line in cwd.splitlines() if line.startswith('n')), '')
        servers.append(server)
    return servers, studios


def validate_servers(root, project, servers):
    if len(servers) != 1:
        raise ValueError(f'exactly one Rojo server required; found {len(servers)}')
    server = servers[0]
    if not server['cwd'] or Path(server['cwd']).resolve() != root:
        raise ValueError('Rojo cwd is unknown or belongs to another checkout')
    args = server['args']
    projects = [a for a in args if a.endswith('.project.json')]
    if not projects:
        projects = ['default.project.json']
    if len(projects) != 1 or (root / projects[0]).resolve() != root / project:
        raise ValueError('Rojo project does not match selected game/checkout')


def validate_snapshot(snapshot, expected, name):
    if snapshot.get('edit') is not True or snapshot.get('name') != name:
        raise ValueError('Studio is running or its DataModel name does not match selected place')
    actual = snapshot.get('sources')
    if not isinstance(actual, dict) or set(actual) != set(expected):
        raise ValueError('Studio source inventory is missing or ambiguous; rerun current probe')
    stale = [p for p, value in expected.items() if actual[p] != value]
    if stale:
        raise ValueError('stale/empty Studio Source: ' + ', '.join(stale))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--game', choices=GAMES, default='GAME-002')
    parser.add_argument('--project', help='explicit matching project filename (optional)')
    parser.add_argument('--place', type=Path, help='exact local place file; required for READY')
    parser.add_argument('--snapshot', type=Path, help='fresh JSON returned by the read-only Studio probe')
    parser.add_argument('--print-probe', action='store_true', help='print read-only Luau query; not a preflight pass')
    args = parser.parse_args(argv)
    try:
        root = args.root.resolve(strict=True)
        if Path(run('git', '-C', str(root), 'rev-parse', '--show-toplevel')).resolve() != root:
            raise ValueError('--root must be a checkout top level')
        project, name = GAMES[args.game]
        if args.project and args.project != project:
            raise ValueError('--project does not match --game')
        expected = sources(root, project)
        if args.print_probe:
            print(probe(expected))
            return 0
        if not args.place or not args.snapshot:
            raise ValueError('--place and fresh --snapshot required; use --print-probe and documented MCP checks')
        place = args.place.resolve(strict=True)
        if place.stem != name or place.suffix not in ('.rbxl', '.rbxlx'):
            raise ValueError('local place filename does not match selected game')
        servers, studios = inspect_processes()
        validate_servers(root, project, servers)
        # Unknown/cloud launches cannot establish an exact local place identity.
        if len(studios) != 1:
            raise ValueError('exactly one identifiable local Studio window required')
        tokens = shlex.split(studios[0])
        launch = next((unquote(t.removeprefix('file://')) for t in tokens if t.startswith('file://')), None)
        if not launch or Path(launch).resolve() != place:
            raise ValueError('Studio launch place unknown or does not match --place; verify manually, no READY')
        validate_snapshot(json.loads(args.snapshot.read_text()), expected, name)
        try:
            memory = run('memory_pressure', '-Q')
            print('INFO: ' + memory)
            free = re.search(r'percentage:\s*(\d+)%', memory)
            if free and int(free.group(1)) < 20:
                print('WARN: under 20% free memory; close other apps before multi-client/capture work')
        except (OSError, subprocess.CalledProcessError):
            print('WARN: memory unavailable; check manually before multi-client/capture work')
        print(f'READY: {args.game} {project} {root}; fresh snapshot sources match. No runtime proof.')
        return 0
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        print(f'FAIL: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
