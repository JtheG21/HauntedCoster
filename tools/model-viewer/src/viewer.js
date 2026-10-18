import { disposeObject } from "./resources.js";
import * as T from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { RoomEnvironment } from "three/addons/environments/RoomEnvironment.js";
import {
  defaults,
  validateScene,
  clipTime,
  resolveCompanion,
  safeModelPath,
} from "./state.js";

const $ = (id) => document.getElementById(id);
let state = defaults(),
  root = null,
  mixer = null,
  action = null,
  clips = [],
  playing = false,
  loadGeneration = 0,
  modelLabel = "",
  radius = 1,
  modelPath = null;
let renderer,
  controls,
  camera,
  scene,
  ground,
  grid,
  hemi,
  key,
  rim,
  environment;
let sceneGeneration = 0;
let effects = new T.Group(),
  stage = new T.Group(),
  effectTime = 0,
  effectNodes = [];
const viewport = $("viewport");
function message(text, error = false) {
  $("message").textContent = text;
  $("message").classList.toggle("error", error);
}
const dispose = disposeObject;
function download(blob, name) {
  const url = URL.createObjectURL(blob),
    a = document.createElement("a");
  a.href = url;
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
function initialize() {
  renderer = new T.WebGLRenderer({
    antialias: true,
    preserveDrawingBuffer: true,
  });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.outputColorSpace = T.SRGBColorSpace;
  renderer.toneMapping = T.ACESFilmicToneMapping;
  viewport.prepend(renderer.domElement);
  scene = new T.Scene();
  camera = new T.PerspectiveCamera(40, 1, 0.01, 10000);
  camera.position.set(3, 2, 5);
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.target.set(0, 1, 0);
  hemi = new T.HemisphereLight(0xe1f4ff, 0x424351, 2);
  key = new T.DirectionalLight(0xfff4df, 3);
  key.position.set(4, 7, 5);
  rim = new T.DirectionalLight(0x81bde9, 2);
  rim.position.set(-4, 3, -4);
  scene.add(hemi, key, rim, stage, effects);
  const room = new RoomEnvironment(),
    pmrem = new T.PMREMGenerator(renderer);
  environment = pmrem.fromScene(room);
  scene.environment = environment.texture;
  room.dispose();
  pmrem.dispose();
  ground = new T.Mesh(
    new T.CircleGeometry(1, 96),
    new T.MeshStandardMaterial({
      color: 0x1a2734,
      roughness: 0.85,
      metalness: 0.15,
    }),
  );
  ground.rotation.x = -Math.PI / 2;
  scene.add(ground);
  new ResizeObserver(resize).observe(viewport);
  renderer.domElement.addEventListener("webglcontextlost", (event) => {
    event.preventDefault();
    message(
      "Graphics context lost. Reload the page to restore the viewer.",
      true,
    );
  });
  resize();
  applyPresentation();
  animate();
}
function resize() {
  const w = viewport.clientWidth,
    h = viewport.clientHeight;
  if (!w || !h) return;
  renderer.setSize(w, h);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}
function makeFloor(box) {
  const center = box.getCenter(new T.Vector3()),
    size = box.getSize(new T.Vector3());
  radius = Math.max(size.length() / 2, 0.001);
  ground.scale.setScalar(radius * 2.5);
  ground.position.set(center.x, box.min.y - radius * 0.005, center.z);
  if (grid) {
    scene.remove(grid);
    dispose(grid);
  }
  grid = new T.GridHelper(radius * 5, 20, 0x43576a, 0x2b3949);
  grid.position.copy(ground.position);
  grid.position.y += radius * 0.001;
  scene.add(grid);
  grid.visible = state.grid;
  camera.near = Math.max(radius / 10000, 0.00001);
  camera.far = Math.max(radius * 200, 100);
  camera.updateProjectionMatrix();
  controls.minDistance = radius * 0.05;
  controls.maxDistance = radius * 80;
}
function fit(view = "three") {
  if (!root) return;
  const box = new T.Box3().setFromObject(root),
    center = box.getCenter(new T.Vector3());
  const directions = {
    front: [0, 0, 1],
    side: [1, 0, 0],
    back: [0, 0, -1],
    three: [1, 0.35, 1.5],
  };
  const halfFov = Math.min(
    T.MathUtils.degToRad(camera.fov / 2),
    Math.atan(Math.tan(T.MathUtils.degToRad(camera.fov / 2)) * camera.aspect),
  );
  const distance = (radius / Math.sin(halfFov)) * 1.15;
  controls.target.copy(center);
  camera.position
    .copy(center)
    .add(
      new T.Vector3(...directions[view]).normalize().multiplyScalar(distance),
    );
  controls.update();
}
function setPose(time) {
  if (!action) return;
  action.paused = false;
  action.enabled = true;
  mixer.setTime(time);
}
function chooseClip(name, reset = true) {
  if (mixer) mixer.stopAllAction();
  action = null;
  state.clip = name;
  const clip = clips.find((c) => c.name === name);
  if (clip) {
    action = mixer.clipAction(clip);
    action.setLoop(
      state.loop ? T.LoopRepeat : T.LoopOnce,
      state.loop ? Infinity : 1,
    );
    action.clampWhenFinished = true;
    action.play();
    if (reset) state.time = 0;
    state.time = clipTime(state.time, clip.duration, state.loop);
    setPose(state.time);
  } else {
    state.clip = "";
    state.time = 0;
    playing = false;
  }
  $("clip").value = state.clip;
  syncTransport();
}
function syncTransport() {
  const duration = action?.getClip().duration || 0;
  $("scrub").max = duration || 1;
  $("scrub").value = state.time;
  $("clock").textContent =
    `${state.time.toFixed(2)} / ${duration.toFixed(2)} s`;
  $("play").textContent = playing ? "Ⅱ" : "▶";
  $("play").setAttribute(
    "aria-label",
    playing ? "Pause animation" : "Play animation",
  );
  for (const id of ["play", "replay", "scrub", "speed", "loop"])
    $(id).disabled = !action;
}
function mappingsUI() {
  $("mappings").replaceChildren();
  for (const mode of ["Idle", "Move", "Ability"]) {
    const label = document.createElement("label");
    label.append(mode);
    const select = document.createElement("select");
    select.setAttribute("aria-label", `${mode} clip mapping`);
    for (const [value, text] of [
      ["", "Not mapped"],
      ...clips.map((c) => [c.name, c.name]),
    ])
      select.add(new Option(text, value));
    select.value = state.mappings[mode];
    select.addEventListener("change", () => {
      state.mappings[mode] = select.value;
      modeButtons();
    });
    label.append(select);
    $("mappings").append(label);
  }
  modeButtons();
}
function modeButtons() {
  for (const b of document.querySelectorAll("[data-mode]")) {
    const name = state.mappings[b.dataset.mode];
    b.disabled = !clips.some((c) => c.name === name);
    b.title = b.disabled
      ? "Map an imported animation clip in the right panel."
      : `Play ${name}`;
  }
}
function stats(object) {
  let meshes = 0,
    triangles = 0;
  const materials = new Set();
  object.traverse((o) => {
    if (o.isMesh) {
      meshes++;
      triangles +=
        (o.geometry.index?.count ||
          o.geometry.attributes.position?.count ||
          0) / 3;
      for (const m of Array.isArray(o.material) ? o.material : [o.material])
        if (m) materials.add(m);
    }
  });
  return {
    meshes,
    triangles: Math.round(triangles),
    materials: materials.size,
    clips: clips.length,
  };
}
function acceptModel(gltf, label, path) {
  const box = new T.Box3().setFromObject(gltf.scene);
  if (
    box.isEmpty() ||
    !Number.isFinite(box.min.length()) ||
    !Number.isFinite(box.max.length())
  ) {
    dispose(gltf.scene);
    throw new Error("Model contains no finite visible geometry.");
  }
  if (root) {
    mixer?.stopAllAction();
    mixer?.uncacheRoot(root);
    stage.remove(root);
    dispose(root);
  }
  root = gltf.scene;
  stage.rotation.y = 0;
  stage.add(root);
  mixer = new T.AnimationMixer(root);
  clips = gltf.animations;
  const names = new Set();
  clips.forEach((c, i) => {
    let name = c.name || `Clip ${i + 1}`;
    while (names.has(name)) name += ` (${i + 1})`;
    c.name = name;
    names.add(name);
  });
  modelPath = path;
  modelLabel = label;
  state.model = path;
  state.time = 0;
  state.clip = "";
  state.mappings = { Idle: "", Move: "", Ability: "" };
  for (const mode of Object.keys(state.mappings))
    state.mappings[mode] =
      clips.find((c) => c.name.toLowerCase().includes(mode.toLowerCase()))
        ?.name || "";
  $("model-name").textContent = label;
  $("empty").hidden = true;
  const s = stats(root);
  $("stats").textContent =
    `${s.meshes} meshes · ${s.materials} materials\n${s.triangles.toLocaleString()} triangles\n${s.clips} imported animation clips`;
  $("source-note").textContent =
    path ||
    "Local file · export scene settings separately; keep this model alongside them.";
  $("clip").replaceChildren(new Option("Rest pose", ""));
  clips.forEach((c) => $("clip").add(new Option(c.name, c.name)));
  $("animation-note").textContent = clips.length
    ? "Only imported clips are played. Map them to the action buttons."
    : "This model has no animation clips. Still inspection and viewer effects remain available.";
  makeFloor(box);
  fit();
  mappingsUI();
  chooseClip("");
  applyPresentation();
  buildEffects();
  message(
    `${label} loaded. ${clips.length ? `${clips.length} animation clips available.` : "Static model — no imported animation clips."}`,
  );
}
async function loadAsset(label, path, parse) {
  const token = ++loadGeneration;
  $("busy").hidden = false;
  try {
    const gltf = await parse();
    if (token !== loadGeneration) {
      dispose(gltf.scene);
      return false;
    }
    acceptModel(gltf, label, path);
    return true;
  } catch (error) {
    if (token === loadGeneration)
      message(
        `Could not load ${label}: ${error.message}. Try a self-contained GLB; Draco/KTX2/meshopt compressed files need conversion first.`,
        true,
      );
    return false;
  } finally {
    if (token === loadGeneration) $("busy").hidden = true;
  }
}
async function openFiles(files) {
  ++sceneGeneration;
  const models = files.filter((f) => /\.(glb|gltf)$/i.test(f.name));
  if (models.length !== 1) {
    message(
      "Select exactly one .glb or .gltf model, plus any companion textures/buffers.",
      true,
    );
    return;
  }
  if (models[0].size > 250 * 1024 * 1024) {
    message(
      "Model exceeds the 250 MiB input limit. Export a smaller review copy.",
      true,
    );
    return;
  }
  const urls = [];
  let resourceError;
  const manager = new T.LoadingManager();
  manager.setURLModifier((url) => {
    if (url.startsWith("data:") || url.startsWith("blob:")) return url;
    const file = resolveCompanion(url, files);
    const objectURL = URL.createObjectURL(file);
    urls.push(objectURL);
    return objectURL;
  });
  manager.onError = (url) => {
    resourceError = `Missing or unreadable companion: ${url}`;
  };
  const loader = new GLTFLoader(manager);
  try {
    await loadAsset(models[0].name, null, async () => {
      const data = await models[0].arrayBuffer();
      const gltf = await loader.parseAsync(data, "");
      if (resourceError) {
        dispose(gltf.scene);
        throw new Error(resourceError);
      }
      return gltf;
    });
  } finally {
    urls.forEach((url) => URL.revokeObjectURL(url));
    $("model-files").value = "";
  }
}
async function openPackage(path, label = path) {
  if (!safeModelPath(path)) {
    message("Invalid library model path.", true);
    return false;
  }
  const manager = new T.LoadingManager();
  let resourceError;
  manager.setURLModifier((url) => {
    if (
      url === `/${path}` ||
      url.startsWith("data:") ||
      url.startsWith("blob:")
    )
      return url;
    throw new Error("Library packages must use self-contained GLB files.");
  });
  manager.onError = (url) => {
    resourceError = `Unreadable asset: ${url}`;
  };
  return loadAsset(label, path, async () => {
    const gltf = await new GLTFLoader(manager).loadAsync(`/${path}`);
    if (resourceError) {
      dispose(gltf.scene);
      throw new Error(resourceError);
    }
    return gltf;
  });
}
async function readScene(input) {
  const next = validateScene(input);
  const operation = ++sceneGeneration;
  ++loadGeneration;
  $("busy").hidden = true;
  if (next.model && next.model !== modelPath) {
    const loaded = await openPackage(next.model);
    if (operation !== sceneGeneration) return;
    if (!loaded)
      throw new Error(
        "Scene model could not be loaded; scene settings were not applied.",
      );
  }
  if (!root)
    throw new Error("Open the matching model first, then import its scene.");
  if (!Object.hasOwn(input, "mappings")) next.mappings = { ...state.mappings };
  if (next.model === null && modelPath !== null)
    throw new Error(
      "This scene refers to a loose local file. Open that model first, then import the scene.",
    );
  if (next.clip && !clips.some((c) => c.name === next.clip))
    throw new Error(`Missing animation clip: ${next.clip}`);
  for (const name of Object.values(next.mappings))
    if (name && !clips.some((c) => c.name === name))
      throw new Error(`Missing mapped clip: ${name}`);
  state = next;
  playing = false;
  stage.rotation.y = 0;
  syncUI();
  applyPresentation();
  buildEffects();
  mappingsUI();
  chooseClip(next.clip, false);
  if (state.camera && state.target) {
    camera.position.fromArray(state.camera);
    controls.target.fromArray(state.target);
    controls.update();
  }
  message("Scene restored. Playback is paused for inspection.");
}
function exportState() {
  state.model = modelPath;
  state.camera = camera.position.toArray();
  state.target = controls.target.toArray();
  return validateScene(state);
}
function syncUI() {
  for (const id of [
    "lighting",
    "background",
    "exposure",
    "effect",
    "effectColor",
    "effectIntensity",
    "speed",
  ])
    $(id).value = state[id];
  for (const id of ["grid", "wireframe", "turntable", "loop"])
    $(id).checked = state[id];
}
function applyPresentation() {
  if (!renderer) return;
  scene.background = new T.Color(state.background);
  renderer.toneMappingExposure = state.exposure;
  grid && (grid.visible = state.grid);
  ground.visible = state.grid;
  const settings = {
    studio: [2, 3, 2, 1],
    bright: [3, 4, 2, 1.5],
    night: [0.65, 1.4, 3, 0.45],
  }[state.lighting];
  [hemi.intensity, key.intensity, rim.intensity, scene.environmentIntensity] =
    settings;
  root?.traverse((o) => {
    if (o.isMesh)
      for (const m of Array.isArray(o.material) ? o.material : [o.material])
        if (m) m.wireframe = state.wireframe;
  });
}
function buildEffects() {
  scene.remove(effects);
  dispose(effects);
  effects = new T.Group();
  scene.add(effects);
  effectNodes = [];
  if (!root || state.effect === "none") return;
  const box = new T.Box3().setFromObject(root),
    c = box.getCenter(new T.Vector3());
  effects.position.copy(c);
  const color = new T.Color(state.effectColor),
    material = new T.MeshBasicMaterial({
      color,
      transparent: true,
      opacity: 0.5,
      depthWrite: false,
      blending: T.AdditiveBlending,
    });
  if (state.effect === "rings")
    for (let i = 0; i < 3; i++) {
      const mesh = new T.Mesh(
        new T.TorusGeometry(radius * (0.7 + i * 0.15), radius * 0.009, 8, 100),
        material.clone(),
      );
      mesh.rotation.x = Math.PI / 2 + i * 0.35;
      effects.add(mesh);
      effectNodes.push(mesh);
    }
  else {
    const count = state.effect === "sparks" ? 100 : 180;
    for (let i = 0; i < count; i++) {
      const mesh = new T.Mesh(
        new T.SphereGeometry(
          radius * (state.effect === "sparks" ? 0.009 : 0.014),
          5,
          4,
        ),
        material,
      );
      mesh.userData = {
        angle: i * 2.39996,
        height: (i / count - 0.5) * 1.8,
        phase: i * 0.37,
      };
      effects.add(mesh);
      effectNodes.push(mesh);
    }
  }
}
function updateEffects(time) {
  effects.visible = state.effect !== "none" && state.effectIntensity > 0;
  for (let i = 0; i < effectNodes.length; i++) {
    const n = effectNodes[i];
    n.material.opacity = Math.min(0.9, state.effectIntensity * 0.35);
    if (state.effect === "rings") {
      n.rotation.z = time * (i % 2 ? -0.3 : 0.4);
      n.scale.setScalar(1 + Math.sin(time * 2 + i) * 0.035);
    } else {
      const u = n.userData,
        a = u.angle + time * 0.3;
      const r = radius * (0.55 + 0.12 * Math.sin(time + u.phase));
      n.position.set(
        Math.cos(a) * r,
        radius * (u.height + 0.12 * Math.sin(time * 1.2 + u.phase)),
        Math.sin(a) * r,
      );
    }
  }
}
let previous = performance.now();
function animate(now = performance.now()) {
  requestAnimationFrame(animate);
  const dt = Math.min((now - previous) / 1000, 0.05);
  previous = now;
  if (!document.hidden) {
    if (playing && action) {
      const duration = action.getClip().duration;
      state.time = clipTime(
        state.time + dt * state.speed,
        duration,
        state.loop,
      );
      setPose(state.time);
      if (!state.loop && state.time >= duration) playing = false;
      syncTransport();
    }
    effectTime += dt;
    if (root && state.turntable) {
      const offset = camera.position.clone().sub(controls.target);
      offset.applyAxisAngle(new T.Vector3(0, 1, 0), dt * 0.25);
      camera.position.copy(controls.target).add(offset);
    }
    updateEffects(effectTime);
    controls.update();
    renderer.render(scene, camera);
  }
}
async function refreshLibrary() {
  const list = $("library");
  list.replaceChildren();
  try {
    const response = await fetch("/library/index.json");
    if (response.status === 404) {
      list.textContent = "No library packages yet.";
      return;
    }
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const entries = await response.json();
    if (!Array.isArray(entries) || entries.length > 1000)
      throw new Error("Invalid library index");
    for (const entry of entries) {
      if (
        !entry ||
        typeof entry.name !== "string" ||
        !safeModelPath(entry.model)
      )
        throw new Error("Invalid library entry");
      const b = document.createElement("button");
      b.textContent = entry.name;
      const sub = document.createElement("small");
      sub.textContent = entry.model.split("/")[1];
      b.append(sub);
      b.addEventListener("click", async () => {
        const sceneToken = ++sceneGeneration;
        if (await openPackage(entry.model, entry.name)) {
          try {
            const generation = loadGeneration;
            const r = await fetch(
              `/${entry.model.replace("model.glb", "scene.json")}`,
            );
            if (r.ok) {
              const saved = await r.json();
              if (
                generation === loadGeneration &&
                sceneToken === sceneGeneration
              )
                await readScene(saved);
            }
          } catch (e) {
            message(
              `Model opened; saved scene could not be restored: ${e.message}`,
              true,
            );
          }
        }
      });
      list.append(b);
    }
  } catch (e) {
    list.textContent = "Library unavailable";
    message(
      `Library: ${e.message}. Use Open model or validate the library.`,
      true,
    );
  }
}
function wire() {
  $("open").onclick = () => $("model-files").click();
  $("model-files").onchange = (e) => openFiles([...e.target.files]);
  $("refresh").onclick = refreshLibrary;
  document.addEventListener("dragover", (e) => e.preventDefault());
  document.addEventListener("drop", (e) => {
    e.preventDefault();
    openFiles([...e.dataTransfer.files]);
  });
  for (const b of document.querySelectorAll("[data-view]"))
    b.onclick = () => fit(b.dataset.view);
  $("fit").onclick = () => fit();
  for (const b of document.querySelectorAll("[data-mode]"))
    b.onclick = () => {
      chooseClip(state.mappings[b.dataset.mode]);
      playing = !!action;
      syncTransport();
    };
  $("still").onclick = () => chooseClip("");
  $("clip").onchange = (e) => chooseClip(e.target.value);
  $("play").onclick = () => {
    if (action) {
      if (!state.loop && state.time >= action.getClip().duration)
        state.time = 0;
      playing = !playing;
      syncTransport();
    }
  };
  $("replay").onclick = () => {
    state.time = 0;
    setPose(0);
    playing = !!action;
    syncTransport();
  };
  $("scrub").oninput = (e) => {
    state.time = +e.target.value;
    playing = false;
    setPose(state.time);
    syncTransport();
  };
  $("loop").onchange = (e) => {
    state.loop = e.target.checked;
    if (action) {
      action.setLoop(
        state.loop ? T.LoopRepeat : T.LoopOnce,
        state.loop ? Infinity : 1,
      );
      action.enabled = true;
    }
  };
  $("speed").onchange = (e) => (state.speed = +e.target.value);
  for (const id of [
    "lighting",
    "background",
    "exposure",
    "grid",
    "wireframe",
    "turntable",
    "effect",
    "effectColor",
    "effectIntensity",
  ])
    $(id).addEventListener("input", (e) => {
      state[id] =
        e.target.type === "checkbox"
          ? e.target.checked
          : e.target.type === "range"
            ? +e.target.value
            : e.target.value;
      applyPresentation();
      if (["effect", "effectColor"].includes(id)) buildEffects();
    });
  $("save").onclick = () => {
    try {
      if (!root) throw new Error("Open a model first.");
      download(
        new Blob([JSON.stringify(exportState(), null, 2)], {
          type: "application/json",
        }),
        "scene.json",
      );
      message(
        "Scene exported. Keep it with the original model; use the package CLI to share.",
      );
    } catch (e) {
      message(e.message, true);
    }
  };
  $("import").onclick = () => $("scene-file").click();
  $("scene-file").onchange = async (e) => {
    try {
      const f = e.target.files[0];
      if (!f) return;
      if (f.size > 100000) throw new Error("Scene JSON exceeds 100 KB.");
      await readScene(JSON.parse(await f.text()));
    } catch (e) {
      message(e.message, true);
    } finally {
      e.target.value = "";
    }
  };
  $("remember").onclick = () => {
    try {
      if (!root) throw new Error("Open a model first.");
      localStorage.setItem("atelier-scene", JSON.stringify(exportState()));
      message(
        "Setup saved in this browser. Export JSON for a durable shared copy.",
      );
    } catch (e) {
      message(`Could not save setup: ${e.message}`, true);
    }
  };
  $("restore").onclick = async () => {
    try {
      const text = localStorage.getItem("atelier-scene");
      if (!text) throw new Error("No browser setup saved yet.");
      await readScene(JSON.parse(text));
    } catch (e) {
      message(`Could not restore setup: ${e.message}`, true);
    }
  };
  $("capture").onclick = () => {
    try {
      if (!root) throw new Error("Open a model first.");
      renderer.render(scene, camera);
      renderer.domElement.toBlob((blob) => {
        if (blob) {
          download(
            blob,
            `${modelLabel.replace(/[^a-z0-9_-]/gi, "_") || "model"}-review.png`,
          );
          message("Clean viewport PNG captured.");
        } else message("Screenshot unavailable.", true);
      }, "image/png");
    } catch (e) {
      message(`Capture failed: ${e.message}`, true);
    }
  };
  document.addEventListener("keydown", (e) => {
    if (["INPUT", "SELECT", "TEXTAREA", "BUTTON"].includes(e.target.tagName))
      return;
    if (e.key.toLowerCase() === "f") fit();
    if (e.code === "Space") {
      e.preventDefault();
      $("play").click();
    }
  });
}
try {
  initialize();
  wire();
  syncTransport();
  modeButtons();
  refreshLibrary();
} catch (e) {
  message(
    `Viewer initialization failed: ${e.message}. Enable WebGL and reload.`,
    true,
  );
}
// Read-only diagnostics make reviews repeatable in either assistant's browser tooling.
window.viewerDiagnostics = () => ({
  loaded: !!root,
  model: modelPath,
  label: modelLabel,
  clips: clips.map((c) => ({ name: c.name, duration: c.duration })),
  state: root ? exportState() : null,
  playing,
  stats: root ? stats(root) : null,
  bounds: root
    ? new T.Box3().setFromObject(root).getCenter(new T.Vector3()).toArray()
    : null,
  renderer: renderer?.info.render,
});
