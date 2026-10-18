import { chromium } from "@playwright/test";
import { spawn } from "node:child_process";
import http from "node:http";
import assert from "node:assert/strict";
let origin;
const server = spawn("python3", ["serve.py", "--port", "0"], {
  stdio: ["ignore", "pipe", "ignore"],
});
let browser;
try {
  origin = await new Promise((resolve, reject) => {
    const timeout = setTimeout(
      () => reject(new Error("Viewer server did not start")),
      10000,
    );
    server.stdout.once("data", (data) => {
      clearTimeout(timeout);
      const match = data.toString().match(/http:\/\/127\.0\.0\.1:\d+/);
      if (match) resolve(match[0]);
      else reject(new Error("No viewer URL"));
    });
    server.once("error", (error) => {
      clearTimeout(timeout);
      reject(error);
    });
  });
  for (let i = 0; i < 100; i++) {
    try {
      const r = await fetch(origin);
      if (r.ok) break;
    } catch {}
    if (i === 99) throw new Error("Viewer server did not start");
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  browser = await chromium.launch(
    process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {},
  );
  const page = await browser.newPage({
    viewport: { width: 1400, height: 900 },
  });
  page.setDefaultTimeout(60000);
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto(origin);
  await page
    .locator("#model-files")
    .setInputFiles("tests/fixtures/animated.glb");
  await page.waitForFunction(
    () => window.viewerDiagnostics?.().clips.length === 3,
  );
  await page.getByRole("button", { name: "Ability", exact: true }).click();
  await page.waitForFunction(() => window.viewerDiagnostics().state.time > 0.1);
  await page.locator("#play").click();
  await page.locator("#scrub").fill("1");
  await page.locator("#scrub").dispatchEvent("input");
  let info = await page.evaluate(() => window.viewerDiagnostics());
  assert.equal(info.state.time, 1);
  assert.ok(info.bounds[1] > 1.4);
  await page.locator("#still").click();
  info = await page.evaluate(() => window.viewerDiagnostics());
  assert.ok(info.bounds[1] < 0.6);
  await page.locator("#model-files").setInputFiles({
    name: "broken.glb",
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
  assert.deepEqual(errors, []);
  for (const path of [
    "/scripts/library.py",
    "/library/",
    "/.private-test",
    "/%2e%2e/AGENTS.md",
  ])
    assert.notEqual((await fetch(`${origin}${path}`)).status, 200);
  const rejectedHost = await new Promise((resolve, reject) => {
    http
      .get(origin, { headers: { Host: "untrusted.example" } }, (response) => {
        response.resume();
        resolve(response.statusCode);
      })
      .on("error", reject);
  });
  assert.equal(rejectedHost, 403);
  console.log(
    "PASS CI browser: real file load, actual animated transforms, rest pose, corrupt input recovery, server isolation",
  );
} finally {
  await browser?.close();
  server.kill();
}
