"""Pure stdlib, one-stud sampled hub navigation (not a physics simulation).

WalkSpeed=16 and JumpHeight=7.2: Roblox creator-docs Humanoid.yaml,
https://create.roblox.com/docs/reference/engine/classes/Humanoid . JumpHeight
applies with UseJumpPower=false; the engine normally defaults to JumpPower mode.
STEP_UP=1 is an explicit modelling assumption: Roblox's public Humanoid API does
not document a fixed automatic step-up limit. Never fit it to Studio lengths.
Blocking footprints are dilated on the 1-stud grid by AgentRadius=2 (a disk),
from creator-docs/content/en-us/characters/pathfinding.md:231-234 and
reference/engine/classes/PathfindingService.yaml:157-162. No jump flight time
or airborne gap traversal is modelled. Jump-up edges cost horizontal distance.
Overlapping floors retain separate elevations; 5 studs of headroom are required.
Mesh collision hulls are unavailable in XML; oriented bounds approximate them.
"""
from __future__ import annotations

import argparse
import base64
from dataclasses import dataclass
import heapq
import math
from pathlib import Path
import time
import xml.etree.ElementTree as ET

WALK_SPEED = 16.0
STEP_UP = 1.0
JUMP_UP = 7.2
HEADROOM = 5.0
AGENT_RADIUS = 2.0
HUB = Path(__file__).resolve().parents[1] / 'games/mathshow/map/Hub.rbxmx'
EPS = 1e-7


@dataclass(frozen=True)
class Part:
    name: str
    cls: str
    centre: tuple
    rotation: tuple
    size: tuple
    shape: int
    collide: bool
    tags: tuple

    def interval(self, x, z):
        """Intersect a vertical world ray with an oriented block/ellipsoid/cylinder."""
        r, c = self.rotation, self.centre
        q = tuple(r[0][i] * (x-c[0]) + r[2][i] * (z-c[2]) for i in range(3))
        d = r[1]
        half = tuple(s/2 for s in self.size)
        lo, hi = -math.inf, math.inf
        axes = range(3) if self.shape == 1 else (0,) if self.shape == 2 else ()
        for i in axes:
            if abs(d[i]) < EPS:
                if abs(q[i]) > half[i] + EPS:
                    return None
            else:
                a, b = sorted(((-half[i]-q[i])/d[i], (half[i]-q[i])/d[i]))
                lo, hi = max(lo, a), min(hi, b)
        if self.shape != 1:
            axes = (1, 2) if self.shape == 2 else (0, 1, 2)
            a = sum((d[i]/half[i])**2 for i in axes)
            b = 2*sum(d[i]*q[i]/half[i]**2 for i in axes)
            cc = sum((q[i]/half[i])**2 for i in axes)-1
            if a < EPS:
                if cc > EPS:
                    return None
            else:
                disc = b*b-4*a*cc
                if disc < -EPS:
                    return None
                root = math.sqrt(max(0, disc))
                lo, hi = max(lo, (-b-root)/(2*a)), min(hi, (-b+root)/(2*a))
        if lo > hi + EPS:
            return None
        return c[1]+lo, c[1]+hi


def load_parts(path=HUB):
    parts = []
    for item in ET.parse(path).iter('Item'):
        props = {p.get('name'): p for p in item.find('Properties')}
        cf, size = props.get('CFrame'), props.get('Size')
        if size is None:
            size = props.get('size')
        if cf is None or size is None:
            continue
        def vector(el):
            return tuple(float(el.findtext(k)) for k in 'XYZ')
        collide = props.get('CanCollide')
        tags = props.get('Tags')
        p = Part(props['Name'].text, item.get('class'), vector(cf),
                 tuple(tuple(float(cf.findtext(f'R{i}{j}')) for j in range(3)) for i in range(3)),
                 vector(size), int(props['shape'].text) if 'shape' in props else 1,
                 collide is None or collide.text == 'true',
                 tuple(base64.b64decode(tags.text or '').decode().split('\0')) if tags is not None else ())
        if p.collide and p.cls not in ('Part', 'SpawnLocation', 'MeshPart'):
            raise ValueError(f'Unsupported collidable geometry: {p.cls} {p.name}')
        parts.append(p)
    return parts


class Heightfield:
    def __init__(self, parts):
        self.parts = parts
        columns = {}
        for part_id, p in enumerate(parts):
            if not p.collide:
                continue
            rx = sum(abs(p.rotation[0][i])*p.size[i]/2 for i in range(3))
            rz = sum(abs(p.rotation[2][i])*p.size[i]/2 for i in range(3))
            for x in range(math.ceil(p.centre[0]-rx), math.floor(p.centre[0]+rx)+1):
                for z in range(math.ceil(p.centre[2]-rz), math.floor(p.centre[2]+rz)+1):
                    interval = p.interval(x, z)
                    if interval is not None:
                        columns.setdefault((x,z), []).append((*interval, part_id))
        # Dilate blockers, not supporting floors: an avatar may stand on a ramp
        # without treating that same inclined part as an obstacle to its feet.
        offsets = [(dx, dz) for dx in range(-2, 3) for dz in range(-2, 3)
                   if dx*dx+dz*dz <= AGENT_RADIUS**2]
        self.floors = {}
        for cell, spans in columns.items():
            spans.sort()
            merged = []
            for lo, hi, part_id in spans:
                if merged and lo <= merged[-1][1]+EPS:
                    old_lo, old_hi, support = merged[-1]
                    if hi > old_hi+EPS:
                        support = {part_id}
                    elif abs(hi-old_hi) <= EPS:
                        support = support | {part_id}
                    merged[-1] = (old_lo, max(hi, old_hi), support)
                else:
                    merged.append((lo,hi,{part_id}))
            floors = []
            for i, (_, hi, support) in enumerate(merged):
                if i+1 < len(merged) and merged[i+1][0]-hi < HEADROOM-EPS:
                    continue
                # Any part that rises above step height into the avatar's body
                # blocks this floor within the radius. Leave its own top usable.
                blocked = any(top > hi+STEP_UP+EPS and bottom < hi+HEADROOM-EPS
                              and owner not in support
                              for dx, dz in offsets
                              for bottom, top, owner in columns.get((cell[0]+dx,cell[1]+dz), ()))
                if not blocked:
                    floors.append(hi)
            self.floors[cell] = tuple(floors)

    def node(self, position):
        x, y, z = position
        cell = (round(x), round(z))
        floors = self.floors.get(cell, ())
        if not floors:
            raise ValueError(f'No supporting floor at {position}')
        below = [h for h in floors if h <= y+EPS]
        if not below:
            raise ValueError(f'No supporting floor below {position}')
        return cell[0], cell[1], max(below)

    @staticmethod
    def allowed(a, b):
        rise = b[2]-a[2]
        return rise <= STEP_UP+EPS or rise <= JUMP_UP+EPS

    def neighbours(self, a):
        x,z,h = a
        for dx,dz in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
            for y in self.floors.get((x+dx,z+dz), ()):
                b = (x+dx,z+dz,y)
                if not self.allowed(a,b):
                    continue
                # No diagonal corner cutting across a blocking column.
                if dx and dz and any(not any(self.allowed(a,(cx,cz,cy)) and self.allowed((cx,cz,cy),b)
                                               for cy in self.floors.get((cx,cz), ()))
                                     for cx,cz in ((x+dx,z),(x,z+dz))):
                    continue
                yield b, self.edge_cost(a, b)

    @staticmethod
    def edge_cost(a, b):
        horizontal = math.hypot(b[0]-a[0], b[1]-a[1])
        # A2: no fitted jump penalty or vertical jump distance.
        if b[2]-a[2] > STEP_UP+EPS:
            return horizontal
        return math.hypot(horizontal, b[2]-a[2])

    def route(self, start, target):
        try:
            a, goal = self.node(start), self.node(target)
        except ValueError:
            return math.inf, []
        def heuristic(n):
            # Jump edges omit vertical cost; a 3D heuristic would overestimate.
            return math.hypot(n[0]-goal[0], n[1]-goal[1])
        queue = [(heuristic(a),0.0,a)]
        costs, previous = {a:0.0}, {}
        while queue:
            _,cost,n = heapq.heappop(queue)
            if cost > costs[n]+EPS:
                continue
            if n == goal:
                path = [n]
                while n != a:
                    n = previous[n]
                    path.append(n)
                return cost, list(reversed(path))
            for b, length in self.neighbours(n):
                candidate = cost+length
                if candidate < costs.get(b, math.inf)-EPS:
                    costs[b], previous[b] = candidate,n
                    heapq.heappush(queue,(candidate+heuristic(b),candidate,b))
        return math.inf, []

    def routes(self):
        spawn_part = next(p for p in self.parts if p.cls == 'SpawnLocation')
        spawn = (spawn_part.centre[0], spawn_part.centre[1]+3, spawn_part.centre[2])
        for p in self.parts:
            if 'ModePad' in p.tags:
                for name, origin in (('spawn',spawn),('centre',(0,5,0))):
                    yield f'{name}->{p.name}', self.route(origin,(p.centre[0],p.centre[1]+3,p.centre[2]))
            if p.name.startswith('Glyph_'):
                yield f'spawn->{p.name}', self.route(spawn,p.centre)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('hub', nargs='?', type=Path, default=HUB)
    args = parser.parse_args()
    started = time.perf_counter()
    nav = Heightfield(load_parts(args.hub))
    for name,(length,path) in nav.routes():
        print(f'{name},{length:.2f},{length/WALK_SPEED:.3f},{len(path)} cells')
    print(f'Runtime: {time.perf_counter()-started:.3f}s')


if __name__ == '__main__':
    main()
