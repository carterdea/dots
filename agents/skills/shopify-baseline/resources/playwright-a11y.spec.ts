import { mkdirSync, writeFileSync } from "node:fs";
import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

const baseUrl = process.env.BASE_URL ?? process.env.SHOPIFY_PREVIEW_URL;
const targetBaseUrl = baseUrl ?? "http://127.0.0.1";
const paths = (process.env.SHOPIFY_A11Y_PATHS ?? "/")
  .split(",")
  .map((path) => path.trim())
  .filter(Boolean);

// Full violation detail lands here as JSON; the test failure message stays a
// compact summary so a single bad page can't flood an agent's context. Read the
// artifact when you need to dig into specific nodes.
const outDir = process.env.SHOPIFY_A11Y_OUT ?? "test-results/a11y";

test.skip(!baseUrl, "Set BASE_URL or SHOPIFY_PREVIEW_URL to run Shopify accessibility smoke tests.");

for (const [index, path] of paths.entries()) {
  test(`axe scan ${path}`, async ({ page }) => {
    const url = new URL(path, targetBaseUrl).toString();
    await page.goto(url, { waitUntil: "domcontentloaded" });

    const { violations } = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
      .analyze();

    if (violations.length === 0) return;

    const slug = path.replace(/[^a-z0-9]+/gi, "-").replace(/^-+|-+$/g, "") || "root";
    mkdirSync(outDir, { recursive: true });
    // Prefix the loop index so distinct paths that normalize to the same slug
    // (e.g. /foo-bar and /foo/bar) don't overwrite each other's report.
    const artifact = `${outDir}/${index}-${slug}.json`;
    writeFileSync(artifact, JSON.stringify(violations, null, 2));

    const byImpact = violations.reduce<Record<string, number>>((acc, v) => {
      const impact = v.impact ?? "unknown";
      acc[impact] = (acc[impact] ?? 0) + 1;
      return acc;
    }, {});
    const impacts = Object.entries(byImpact)
      .map(([impact, count]) => `${count} ${impact}`)
      .join(", ");
    const topRules = violations
      .slice(0, 5)
      .map((v) => `${v.id} (${v.nodes.length})`)
      .join(", ");

    expect(
      violations.length,
      `${path}: ${violations.length} a11y violations — ${impacts}. Top rules: ${topRules}. Full report: ${artifact}`,
    ).toBe(0);
  });
}
