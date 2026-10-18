// Original mechanical test fixture. Not production art or a model-quality example.
import { writeFileSync, mkdirSync } from "node:fs";
const positions = new Float32Array([-0.5, 0, 0, 0.5, 0, 0, 0, 1, 0]);
const times = new Float32Array([0, 1, 2]);
const translations = new Float32Array([0, 0, 0, 0, 1, 0, 0, 0, 0]);
const bin = Buffer.concat([
  Buffer.from(positions.buffer),
  Buffer.from(times.buffer),
  Buffer.from(translations.buffer),
]);
const doc = {
  asset: { version: "2.0", generator: "Original viewer test fixture" },
  scene: 0,
  scenes: [{ nodes: [0] }],
  nodes: [{ name: "Animated_Test_Triangle", mesh: 0 }],
  meshes: [{ primitives: [{ attributes: { POSITION: 0 }, material: 0 }] }],
  materials: [
    {
      doubleSided: true,
      pbrMetallicRoughness: {
        baseColorFactor: [0.25, 0.85, 0.7, 1],
        metallicFactor: 0,
        roughnessFactor: 0.5,
      },
    },
  ],
  buffers: [{ byteLength: bin.length }],
  bufferViews: [
    { buffer: 0, byteOffset: 0, byteLength: 36 },
    { buffer: 0, byteOffset: 36, byteLength: 12 },
    { buffer: 0, byteOffset: 48, byteLength: 36 },
  ],
  accessors: [
    {
      bufferView: 0,
      componentType: 5126,
      count: 3,
      type: "VEC3",
      min: [-0.5, 0, 0],
      max: [0.5, 1, 0],
    },
    {
      bufferView: 1,
      componentType: 5126,
      count: 3,
      type: "SCALAR",
      min: [0],
      max: [2],
    },
    { bufferView: 2, componentType: 5126, count: 3, type: "VEC3" },
  ],
  animations: ["Idle", "Move", "Ability"].map((name) => ({
    name,
    samplers: [{ input: 1, output: 2, interpolation: "LINEAR" }],
    channels: [{ sampler: 0, target: { node: 0, path: "translation" } }],
  })),
};
let json = Buffer.from(JSON.stringify(doc));
json = Buffer.concat([json, Buffer.alloc((4 - (json.length % 4)) % 4, 32)]);
const header = Buffer.alloc(20);
header.writeUInt32LE(0x46546c67);
header.writeUInt32LE(2, 4);
header.writeUInt32LE(28 + json.length + bin.length, 8);
header.writeUInt32LE(json.length, 12);
header.writeUInt32LE(0x4e4f534a, 16);
const binHeader = Buffer.alloc(8);
binHeader.writeUInt32LE(bin.length);
binHeader.writeUInt32LE(0x004e4942, 4);
mkdirSync("tests/fixtures", { recursive: true });
writeFileSync(
  "tests/fixtures/animated.glb",
  Buffer.concat([header, json, binHeader, bin]),
);
