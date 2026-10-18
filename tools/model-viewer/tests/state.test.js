import { test } from "node:test";
import assert from "node:assert/strict";
import {
  defaults,
  validateScene,
  clipTime,
  resolveCompanion,
  safeModelPath,
} from "../src/state.js";
test("scene round trip preserves all settings and isolates input", () => {
  const scene = defaults();
  scene.camera = [1, 2, 3];
  scene.target = [0, 1, 0];
  scene.mappings.Idle = "hover";
  scene.clip = "hover";
  scene.time = 1.25;
  scene.effect = "rings";
  const valid = validateScene(JSON.parse(JSON.stringify(scene)));
  assert.deepEqual(valid, scene);
  valid.mappings.Idle = "changed";
  assert.equal(scene.mappings.Idle, "hover");
});
test("rejects unsafe paths, versions, types and nonfinite data", () => {
  for (const patch of [
    { version: 2 },
    { model: "../../secrets.glb" },
    { model: "https://example.com/a.glb" },
    { camera: [NaN, 1, 2] },
    { camera: [1, 2] },
    { speed: 0 },
    { time: Infinity },
    { effect: "code" },
    { grid: "false" },
    { background: "red" },
    { mappings: { Idle: "x" } },
    { constructor: "x" },
    { unknown: 1 },
  ])
    assert.throws(() => validateScene({ ...defaults(), ...patch }));
  assert.equal(safeModelPath("library/my-model_2/model.glb"), true);
  assert.equal(safeModelPath("library/x/../model.glb"), false);
});
test("timeline clamps or wraps at actual duration", () => {
  assert.equal(clipTime(2.5, 2, true), 0.5);
  assert.equal(clipTime(2.5, 2, false), 2);
  assert.equal(clipTime(-1, 2, false), 0);
  assert.equal(clipTime(1, 0, true), 0);
});
test("companion resolution accepts local unique files and rejects network/traversal/ambiguity", () => {
  const files = [{ name: "tex.png" }, { name: "model.bin" }];
  assert.equal(resolveCompanion("textures/tex.png", files), files[0]);
  assert.equal(resolveCompanion("data:foo", files), "data:foo");
  for (const url of [
    "https://evil/tex.png",
    "../tex.png",
    "%2e%2e/tex.png",
    "file:///tmp/key",
    "/tmp/key",
    "missing.png",
    "%bad%",
  ])
    assert.throws(() => resolveCompanion(url, files));
  assert.throws(() =>
    resolveCompanion("tex.png", [{ name: "tex.png" }, { name: "tex.png" }]),
  );
});
