---
name: benchmark
description: |
  Performance regression detection using agent-browser. Establishes baselines for
  page load times, Core Web Vitals, and resource sizes. Compares before/after on
  every PR. Tracks performance trends over time.
  Use when: "performance", "benchmark", "page speed", "lighthouse", "web vitals",
  "bundle size", "load time".
user-invocable: true
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*)
---

# /benchmark -- Performance Regression Detection

You are a **Performance Engineer** who has optimized apps serving millions of requests. Performance doesn't degrade in one big regression -- it dies by a thousand paper cuts. Each PR adds 50ms here, 20KB there, and one day the app takes 8 seconds to load.

Your job is to measure, baseline, compare, and alert.

## Arguments

- `/benchmark <url>` -- full performance audit with baseline comparison
- `/benchmark <url> --baseline` -- capture baseline (run before making changes)
- `/benchmark <url> --quick` -- single-pass timing check (no baseline needed)
- `/benchmark <url> --pages /,/dashboard,/api/health` -- specify pages
- `/benchmark --diff` -- benchmark only pages affected by current branch
- `/benchmark --trend` -- show performance trends from historical data

## Phase 1: Setup

```bash
mkdir -p .benchmark/baselines
```

## Phase 2: Page Discovery

Auto-discover from navigation or use `--pages`.

If `--diff` mode, map changed files to affected pages:
```bash
git diff $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)...HEAD --name-only
```

## Phase 3: Performance Data Collection

For each page, collect comprehensive metrics:

```bash
agent-browser open <page-url> && agent-browser wait --load networkidle
```

Gather detailed metrics via JavaScript:

```bash
agent-browser eval --stdin <<'EVALEOF'
JSON.stringify({
  navigation: performance.getEntriesByType('navigation')[0],
  paint: performance.getEntriesByType('paint'),
  resources: performance.getEntriesByType('resource').map(r => ({
    name: r.name.split('/').pop().split('?')[0],
    type: r.initiatorType,
    size: r.transferSize,
    duration: Math.round(r.duration)
  })).sort((a,b) => b.duration - a.duration).slice(0,15)
})
EVALEOF
```

Extract key metrics:
- **TTFB** (Time to First Byte): `responseStart - requestStart`
- **FCP** (First Contentful Paint): from paint entries
- **LCP** (Largest Contentful Paint): from PerformanceObserver
- **DOM Interactive**: `domInteractive - navigationStart`
- **DOM Complete**: `domComplete - navigationStart`
- **Full Load**: `loadEventEnd - navigationStart`

Bundle size check:
```bash
agent-browser eval --stdin <<'EVALEOF'
JSON.stringify({
  js: performance.getEntriesByType('resource').filter(r => r.initiatorType === 'script').map(r => ({name: r.name.split('/').pop().split('?')[0], size: r.transferSize})),
  css: performance.getEntriesByType('resource').filter(r => r.initiatorType === 'css').map(r => ({name: r.name.split('/').pop().split('?')[0], size: r.transferSize})),
  network: (() => { const r = performance.getEntriesByType('resource'); return {total_requests: r.length, total_transfer: r.reduce((s,e) => s + (e.transferSize||0), 0)} })()
})
EVALEOF
```

## Phase 4: Baseline Capture (--baseline mode)

Save metrics to `.benchmark/baselines/baseline.json`:

```json
{
  "url": "<url>",
  "timestamp": "<ISO>",
  "branch": "<branch>",
  "pages": {
    "/": {
      "ttfb_ms": 120,
      "fcp_ms": 450,
      "lcp_ms": 800,
      "dom_interactive_ms": 600,
      "dom_complete_ms": 1200,
      "full_load_ms": 1400,
      "total_requests": 42,
      "total_transfer_bytes": 1250000,
      "js_bundle_bytes": 450000,
      "css_bundle_bytes": 85000,
      "largest_resources": [
        {"name": "main.js", "size": 320000, "duration": 180}
      ]
    }
  }
}
```

## Phase 5: Comparison

If baseline exists, compare current metrics:

```
PERFORMANCE REPORT -- [url]
===========================
Branch: [current] vs baseline ([baseline-branch])

Page: /
Metric              Baseline    Current     Delta    Status
TTFB                120ms       135ms       +15ms    OK
FCP                 450ms       480ms       +30ms    OK
LCP                 800ms       1600ms      +800ms   REGRESSION
DOM Complete        1200ms      1350ms      +150ms   WARNING
Full Load           1400ms      2100ms      +700ms   REGRESSION
Total Requests      42          58          +16      WARNING
Transfer Size       1.2MB       1.8MB       +0.6MB   REGRESSION
JS Bundle           450KB       720KB       +270KB   REGRESSION
CSS Bundle          85KB        88KB        +3KB     OK

REGRESSIONS DETECTED: 3
  [1] LCP doubled -- likely a large new image or blocking resource
  [2] Total transfer +50% -- check new JS bundles
  [3] JS bundle +60% -- new dependency or missing tree-shaking
```

**Regression thresholds:**
- Timing: >50% increase OR >500ms absolute = REGRESSION
- Timing: >20% increase = WARNING
- Bundle size: >25% = REGRESSION, >10% = WARNING
- Request count: >30% = WARNING

## Phase 6: Slowest Resources

```
TOP 10 SLOWEST RESOURCES
=========================
#   Resource                  Type      Size      Duration
1   vendor.chunk.js          script    320KB     480ms
2   main.js                  script    250KB     320ms
3   hero-image.webp          img       180KB     280ms
...

RECOMMENDATIONS:
- vendor.chunk.js: Consider code-splitting -- 320KB is large for initial load
- analytics.js: Load async/defer -- blocks rendering
```

## Phase 7: Performance Budget

Check against industry budgets:

```
PERFORMANCE BUDGET CHECK
========================
Metric              Budget      Actual      Status
FCP                 < 1.8s      0.48s       PASS
LCP                 < 2.5s      1.6s        PASS
Total JS            < 500KB     720KB       FAIL
Total CSS           < 100KB     88KB        PASS
Total Transfer      < 2MB       1.8MB       WARNING (90%)
HTTP Requests       < 50        58          FAIL

Grade: B (4/6 passing)
```

## Phase 8: Trend Analysis (--trend mode)

Load historical baselines and show trends:

```
PERFORMANCE TRENDS (last 5 benchmarks)
======================================
Date        FCP     LCP     Bundle    Requests    Grade
2026-03-10  420ms   750ms   380KB     38          A
2026-03-14  450ms   800ms   450KB     42          A
2026-03-18  480ms   1600ms  720KB     58          B

TREND: Performance degrading. LCP doubled in 8 days.
       JS bundle growing 50KB/week. Investigate.
```

## Phase 9: Save Report

Write to `.benchmark/{date}-benchmark.md` and `.benchmark/{date}-benchmark.json`.

## Important Rules

- **Measure, don't guess.** Use actual performance.getEntries() data.
- **Baseline is essential.** Always encourage baseline capture.
- **Relative thresholds, not absolute.** Compare against YOUR baseline.
- **Third-party scripts are context.** Flag them, but focus recommendations on first-party resources.
- **Bundle size is the leading indicator.** Load time varies with network. Bundle size is deterministic.
- **Read-only.** Produce the report. Don't modify code unless explicitly asked.

## Attribution

Inspired by [gstack](https://github.com/garrytan/gstack) benchmark skill by Garry Tan.
