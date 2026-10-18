import { chromium } from "@playwright/test";
const browser = await chromium.launch({
  executablePath:
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  headless: true,
});
try {
  const page = await browser.newPage({
    viewport: { width: 1300, height: 900 },
  });
  page.on("pageerror", (e) => console.error(e));
  await page.goto("http://127.0.0.1:8766/probe.html");
  await page.waitForFunction(() => window.probeReady || window.probeError);
  console.log(await page.locator("#result").textContent());
  await page.screenshot({ path: "docs/phase1-wisp.png" });
} finally {
  await browser.close();
}
