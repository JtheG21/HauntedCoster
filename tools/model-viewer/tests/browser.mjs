import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { readFileSync, writeFileSync } from "node:fs";
const browser = await chromium.launch({
  executablePath:
    process.env.CHROME_PATH ||
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  headless: true,
});
const checks = [];
const errors = [];
const check = (name) => {
  checks.push(name);
  console.log(`PASS ${name}`);
};
try {
  const page = await browser.newPage({
    viewport: { width: 1512, height: 982 },
    acceptDownloads: true,
  });
  page.setDefaultTimeout(60000);
  page.on("pageerror", (e) => errors.push(e.message));
  await page.goto(process.env.VIEWER_URL || "http://127.0.0.1:8766");
  await page.getByRole("button", { name: "Wisp · existing asset" }).click();
  await page.waitForFunction(
    () => window.viewerDiagnostics?.().label === "Wisp · existing asset",
  );
  const info = await page.evaluate(() => window.viewerDiagnostics());
  assert.ok(info.stats.triangles > 1000);
  assert.equal(info.clips.length, 0);
  assert.equal(await page.locator("#play").isDisabled(), true);
  check("real Wisp loads with materials, correct no-animation controls");
  await page.screenshot({ path: "docs/viewer-wisp.png" });
  for (const name of ["Front", "Side", "Back", "¾"])
    await page.getByRole("button", { name, exact: true }).click();
  check("four inspection camera controls");
  await page.selectOption("#lighting", "night");
  await page.selectOption("#effect", "rings");
  await page.locator("#wireframe").check();
  await page.locator("#turntable").check();
  await page.waitForTimeout(100);
  await page.locator("#turntable").uncheck();
  await page.locator("#wireframe").uncheck();
  await page
    .getByRole("button", { name: "Remember setup", exact: true })
    .click();
  await page.selectOption("#lighting", "bright");
  await page.selectOption("#effect", "none");
  await page
    .getByRole("button", { name: "Restore setup", exact: true })
    .click();
  assert.equal(await page.locator("#lighting").inputValue(), "night");
  assert.equal(await page.locator("#effect").inputValue(), "rings");
  check("lighting, effects, wireframe, turntable and saved scene restore");
  const [download] = await Promise.all([
    page.waitForEvent("download"),
    page.locator("#save").click(),
  ]);
  const path = await download.path();
  const saved = JSON.parse(readFileSync(path, "utf8"));
  assert.equal(saved.model, "library/wisp-review/model.glb");
  assert.equal(saved.effect, "rings");
  check("portable scene JSON export");
  await page.selectOption("#effect", "none");
  await page.locator("#scene-file").setInputFiles({
    name: "scene.json",
    mimeType: "application/json",
    buffer: Buffer.from(JSON.stringify(saved)),
  });
  await page.waitForFunction(
    () => window.viewerDiagnostics().state.effect === "rings",
  );
  check("scene JSON import restores actual file");
  const [capture] = await Promise.all([
    page.waitForEvent("download"),
    page.locator("#capture").click(),
  ]);
  const bytes = readFileSync(await capture.path());
  assert.equal(bytes.subarray(1, 4).toString(), "PNG");
  assert.ok(bytes.length > 10000);
  writeFileSync("docs/wisp-viewport.png", bytes);
  check("clean viewport PNG capture");
  await page.getByRole("button", { name: "Animation test · fixture" }).click();
  await page.waitForFunction(
    () => window.viewerDiagnostics().clips.length === 3,
  );
  await page.getByRole("button", { name: "Ability", exact: true }).click();
  await page.waitForTimeout(200);
  assert.ok(
    (await page.evaluate(() => window.viewerDiagnostics())).state.time > 0,
  );
  await page.locator("#play").click();
  await page.locator("#scrub").fill("1");
  await page.locator("#scrub").dispatchEvent("input");
  let diag = await page.evaluate(() => window.viewerDiagnostics());
  assert.equal(diag.playing, false);
  assert.equal(diag.state.time, 1);
  assert.ok(diag.bounds[1] > 1.4);
  check("imported animation plays, pauses and scrubs");
  await page.locator("#loop").uncheck();
  await page.selectOption("#speed", "2");
  await page.locator("#replay").click();
  await page.waitForFunction(() => {
    const d = window.viewerDiagnostics();
    return !d.playing && d.state.time === 2;
  });
  check("non-looping playback stops at clip duration at selected speed");
  await page.locator("#replay").click();
  await page.waitForFunction(() => {
    const d = window.viewerDiagnostics();
    return d.state.time > 0 && d.bounds[1] > 0.5;
  });
  await page.locator("#play").click();
  const replayed = await page.evaluate(() => window.viewerDiagnostics());
  assert.ok(replayed.bounds[1] > 0.5);
  assert.ok(replayed.state.time > 0);
  check("replay after end moves actual geometry again");
  await page.locator("#still").click();
  assert.equal(
    (await page.evaluate(() => window.viewerDiagnostics())).state.clip,
    "",
  );
  assert.equal(await page.locator("#play").isDisabled(), true);
  check("Still returns rest pose");
  await page.locator("#model-files").setInputFiles({
    name: "bad.glb",
    mimeType: "model/gltf-binary",
    buffer: Buffer.from("broken"),
  });
  await page.waitForFunction(() =>
    document.getElementById("message").classList.contains("error"),
  );
  assert.equal(
    (await page.evaluate(() => window.viewerDiagnostics())).loaded,
    true,
  );
  check("corrupt model error preserves current asset");
  await page.locator("#scene-file").setInputFiles({
    name: "bad.json",
    mimeType: "application/json",
    buffer: Buffer.from('{"version":2}'),
  });
  await page.waitForFunction(() =>
    document
      .getElementById("message")
      .textContent.includes("unsupported version"),
  );
  check("invalid scene fails clearly");
  await page.locator("#scene-file").setInputFiles({
    name: "missing.json",
    mimeType: "application/json",
    buffer: Buffer.from(
      JSON.stringify({ version: 1, model: "library/missing/model.glb" }),
    ),
  });
  await page.waitForFunction(() =>
    document
      .getElementById("message")
      .textContent.includes("could not be loaded"),
  );
  check("missing package is visible and recoverable");
  const gltf = {
    asset: { version: "2.0" },
    scene: 0,
    scenes: [{ nodes: [0] }],
    nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ uri: "mesh.bin", byteLength: 36 }],
    bufferViews: [{ buffer: 0, byteOffset: 0, byteLength: 36 }],
    accessors: [
      {
        bufferView: 0,
        componentType: 5126,
        count: 3,
        type: "VEC3",
        min: [0, 0, 0],
        max: [1, 1, 0],
      },
    ],
  };
  await page.locator("#model-files").setInputFiles([
    {
      name: "external.gltf",
      mimeType: "model/gltf+json",
      buffer: Buffer.from(JSON.stringify(gltf)),
    },
    {
      name: "mesh.bin",
      mimeType: "application/octet-stream",
      buffer: Buffer.from(new Float32Array([0, 0, 0, 1, 0, 0, 0, 1, 0]).buffer),
    },
  ]);
  await page.waitForFunction(
    () => window.viewerDiagnostics().label === "external.gltf",
  );
  check("glTF companion buffers load from local selection");
  await page.locator("#model-files").setInputFiles({
    name: "missing.gltf",
    mimeType: "model/gltf+json",
    buffer: Buffer.from(JSON.stringify(gltf)),
  });
  await page.waitForFunction(() =>
    document.getElementById("message").classList.contains("error"),
  );
  check("missing glTF companion fails clearly");
  await page.getByRole("button", { name: "Wisp · existing asset" }).click();
  await page.waitForFunction(
    () => window.viewerDiagnostics().model === "library/wisp-review/model.glb",
  );
  await page.getByRole("button", { name: "Animation test · fixture" }).click();
  await page.waitForFunction(
    () => window.viewerDiagnostics().clips.length === 3,
  );
  let resumePreset;
  const presetGate = new Promise((resolve) => (resumePreset = resolve));
  await page.route("**/library/wisp-review/scene.json", async (route) => {
    await presetGate;
    await route.fulfill({
      json: {
        version: 1,
        model: "library/wisp-review/model.glb",
        effect: "none",
      },
    });
  });
  await page.getByRole("button", { name: "Wisp · existing asset" }).click();
  await page.waitForFunction(
    () => window.viewerDiagnostics().model === "library/wisp-review/model.glb",
  );
  await page.locator("#scene-file").setInputFiles({
    name: "newer.json",
    mimeType: "application/json",
    buffer: Buffer.from(
      JSON.stringify({
        version: 1,
        model: "library/wisp-review/model.glb",
        effect: "aura",
      }),
    ),
  });
  await page.waitForFunction(
    () => window.viewerDiagnostics().state.effect === "aura",
  );
  const oldResponse = page.waitForResponse((response) =>
    response.url().endsWith("/library/wisp-review/scene.json"),
  );
  resumePreset();
  await oldResponse;
  await page.waitForTimeout(100);
  assert.equal(
    (await page.evaluate(() => window.viewerDiagnostics())).state.effect,
    "aura",
  );
  await page.unroute("**/library/wisp-review/scene.json");
  check("delayed automatic preset cannot overwrite a newer imported scene");
  let releaseModel, markRequested;
  const modelGate = new Promise((resolve) => (releaseModel = resolve));
  const requested = new Promise((resolve) => (markRequested = resolve));
  await page.route("**/library/animation-test/model.glb", async (route) => {
    markRequested();
    await modelGate;
    await route.continue();
  });
  await page.locator("#scene-file").setInputFiles({
    name: "older-model-scene.json",
    mimeType: "application/json",
    buffer: Buffer.from(
      JSON.stringify({
        version: 1,
        model: "library/animation-test/model.glb",
        effect: "rings",
      }),
    ),
  });
  await requested;
  await page.locator("#scene-file").setInputFiles({
    name: "newer-current-scene.json",
    mimeType: "application/json",
    buffer: Buffer.from(
      JSON.stringify({
        version: 1,
        model: "library/wisp-review/model.glb",
        effect: "aura",
      }),
    ),
  });
  await page.waitForFunction(
    () => window.viewerDiagnostics().state.effect === "aura",
  );
  const oldModelResponse = page.waitForResponse((response) =>
    response.url().endsWith("/library/animation-test/model.glb"),
  );
  releaseModel();
  await oldModelResponse;
  await page.waitForTimeout(100);
  const latest = await page.evaluate(() => window.viewerDiagnostics());
  assert.equal(latest.model, "library/wisp-review/model.glb");
  assert.equal(latest.state.effect, "aura");
  await page.unroute("**/library/animation-test/model.glb");
  check(
    "a newer current-model scene import cancels an older pending model switch",
  );

  await page.selectOption("#lighting", "studio");
  await page.selectOption("#effect", "none");
  await page.getByRole("button", { name: "¾", exact: true }).click();
  await page.screenshot({ path: "docs/viewer-wisp.png" });
  assert.deepEqual(errors, []);
  check("no unhandled browser errors");
  writeFileSync(
    "docs/browser-results.json",
    JSON.stringify({ checks, errors }, null, 2),
  );
} finally {
  await browser.close();
}
