import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

const baseUrl = process.env.BASE_URL ?? process.env.SHOPIFY_PREVIEW_URL;
const targetBaseUrl = baseUrl ?? "http://127.0.0.1";
const paths = (process.env.SHOPIFY_A11Y_PATHS ?? "/")
  .split(",")
  .map((path) => path.trim())
  .filter(Boolean);

test.skip(!baseUrl, "Set BASE_URL or SHOPIFY_PREVIEW_URL to run Shopify accessibility smoke tests.");

for (const path of paths) {
  test(`axe scan ${path}`, async ({ page }) => {
    const url = new URL(path, targetBaseUrl).toString();
    await page.goto(url, { waitUntil: "domcontentloaded" });

    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
      .analyze();

    expect(results.violations).toEqual([]);
  });
}
