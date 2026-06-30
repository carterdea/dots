import { mkdirSync, writeFileSync } from "node:fs";
import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

const baseUrl = process.env.BASE_URL ?? process.env.SHOPIFY_PREVIEW_URL;
const targetBaseUrl = baseUrl ?? "http://127.0.0.1";
const paths = (process.env.SHOPIFY_A11Y_PATHS ?? "/")
  .split(",")
  .map((path) => path.trim())
  .filter(Boolean);

// Full violation detail lands in this *directory* as one JSON file per scanned
// path; the test failure message stays a compact summary so a single bad page
// can't flood an agent's context. Read a file when you need node-level detail.
// SHOPIFY_A11Y_OUT_DIR must be a directory, not a file path.
const outDir = process.env.SHOPIFY_A11Y_OUT_DIR ?? "test-results/a11y";

test.skip(!baseUrl, "Set BASE_URL or SHOPIFY_PREVIEW_URL to run Shopify accessibility smoke tests.");

for (const [index, path] of paths.entries()) {
  test(`axe scan ${path}`, async ({ page }, testInfo) => {
    const url = new URL(path, targetBaseUrl).toString();
    await page.goto(url, { waitUntil: "domcontentloaded" });

    const { violations } = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
      .analyze();

    if (violations.length === 0) return;

    const slug = path.replace(/[^a-z0-9]+/gi, "-").replace(/^-+|-+$/g, "") || "root";
    mkdirSync(outDir, { recursive: true });
    // Qualify the filename so reports never overwrite each other: the loop index
    // disambiguates distinct paths that normalize to the same slug (/foo-bar vs
    // /foo/bar), and project name + retry keep multi-project (e.g. desktop/mobile)
    // and retried runs separate.
    const project = testInfo.project.name.replace(/[^a-z0-9]+/gi, "-").replace(/^-+|-+$/g, "");
    const parts = [project, `${index}-${slug}`].filter(Boolean);
    if (testInfo.retry) parts.push(`retry${testInfo.retry}`);
    const artifact = `${outDir}/${parts.join("-")}.json`; // slug project too: "desktop/chromium" would break the path
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
