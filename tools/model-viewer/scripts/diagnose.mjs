import { chromium } from "@playwright/test";
const browser = await chromium.launch({
  executablePath:
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  headless: true,
});
try {
  const page = await browser.newPage();
  page.setDefaultTimeout(15000);
  page.on("pageerror", (e) => console.log("ERROR", e.message));
  await page.goto("http://127.0.0.1:8766");
  await page.getByRole("button", { name: "Animation test · fixture" }).click();
  await page.waitForFunction(() => window.viewerDiagnostics?.().loaded);
  console.log(await page.evaluate(() => window.viewerDiagnostics()));
  console.log(await page.locator("#message").textContent());
  await page.getByRole("button", { name: "Ability", exact: true }).click();
  await page.waitForTimeout(300);
  console.log(await page.evaluate(() => window.viewerDiagnostics()));
  console.log(await page.locator("#message").textContent());
} finally {
  await browser.close();
}
