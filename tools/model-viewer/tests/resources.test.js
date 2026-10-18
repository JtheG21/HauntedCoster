import { test } from "node:test";
import assert from "node:assert/strict";
import { disposeObject } from "../src/resources.js";
test("releasing a model frees shared GPU and bitmap resources exactly once", () => {
  const released = {
    texture: 0,
    geometry: 0,
    material: 0,
    skeleton: 0,
    bitmap: 0,
  };
  const bitmap = { close: () => released.bitmap++ };
  const texture = {
    isTexture: true,
    source: { data: bitmap },
    dispose: () => released.texture++,
  };
  const geometry = { dispose: () => released.geometry++ };
  const skeleton = { dispose: () => released.skeleton++ };
  const material = {
    map: texture,
    normalMap: texture,
    dispose: () => released.material++,
  };
  const nodes = [
    { geometry, skeleton, material },
    { geometry, skeleton, material: [material] },
  ];
  disposeObject({ traverse: (callback) => nodes.forEach(callback) });
  assert.deepEqual(released, {
    texture: 1,
    geometry: 1,
    material: 1,
    skeleton: 1,
    bitmap: 1,
  });
});
