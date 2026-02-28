import { chromium } from "playwright";

const arg = process.argv[2] || "sz002470";
const url = arg.startsWith("http") ? arg : `https://quote.eastmoney.com/${arg}.html`;

// ── Patterns to intercept ──────────────────────────────────────────────

const patterns = [
  {
    name: "snapshot",
    test: (u) =>
      u.includes("push2.eastmoney.com/api/qt/stock/get") &&
      u.includes("fields=f43"),
  },
  {
    name: "orderbook",
    test: (u) =>
      u.includes("push2.eastmoney.com/api/qt/stock/get") &&
      u.includes("f11") &&
      u.includes("f31"),
  },
  {
    name: "timeshare",
    test: (u) => u.includes("push2his.eastmoney.com/api/qt/stock/trends2/get"),
  },
  {
    name: "kline",
    test: (u) => u.includes("push2his.eastmoney.com/api/qt/stock/kline/get"),
  },
  {
    name: "sectors",
    test: (u) =>
      u.includes("push2.eastmoney.com/api/qt/clist/get") &&
      u.includes("m:90"),
  },
  {
    name: "article",
    test: (u) => u.includes("gbapi.eastmoney.com") && u.includes("Articlelist"),
  },
];

const results = new Map();
// Allow multiple kline captures (5min, daily, weekly, etc.)
const klineResults = [];

// ── Helpers ────────────────────────────────────────────────────────────

function unwrapJsonp(text) {
  if (!text) return text;
  const firstParen = text.indexOf("(");
  const lastParen = text.lastIndexOf(")");
  if (firstParen >= 0 && lastParen > firstParen) {
    return text.slice(firstParen + 1, lastParen);
  }
  return text;
}

function pickFields(obj, fields) {
  const out = {};
  fields.forEach((k) => {
    if (obj && Object.prototype.hasOwnProperty.call(obj, k)) {
      out[k] = obj[k];
    }
  });
  return out;
}

function extractKlt(urlStr) {
  try {
    const u = new URL(urlStr);
    return u.searchParams.get("klt") || "?";
  } catch {
    const m = urlStr.match(/klt=(\d+)/);
    return m ? m[1] : "?";
  }
}

// ── Snapshot field labels (for human-readable output) ──────────────────

const snapshotLabels = {
  f43: "price(最新价)",
  f44: "high(最高)",
  f45: "low(最低)",
  f46: "open(今开)",
  f47: "volume(成交量)",
  f48: "amount(成交额)",
  f51: "limitUp(涨停价)",
  f52: "limitDown(跌停价)",
  f57: "code(代码)",
  f58: "name(名称)",
  f60: "preClose(昨收)",
  f116: "marketValue(总市值)",
  f117: "circulationMV(流通市值)",
  f168: "turnover(换手率)",
  f169: "change(涨跌额)",
  f170: "changePct(涨跌幅)",
};

// ── Browser setup ──────────────────────────────────────────────────────

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({
  userAgent:
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
});
await page.setExtraHTTPHeaders({
  Referer: "https://quote.eastmoney.com/",
});

// ── Intercept responses ────────────────────────────────────────────────

page.on("response", async (resp) => {
  const u = resp.url();
  const match = patterns.find((p) => p.test(u));
  if (!match) return;

  // Allow multiple kline captures; skip duplicates for others
  if (match.name !== "kline" && results.has(match.name)) return;

  try {
    const text = await resp.text();
    const json = JSON.parse(unwrapJsonp(text));
    const data = json?.data || {};
    let sample = {};

    if (match.name === "snapshot") {
      // Show ALL snapshot fields that the app uses
      sample = pickFields(data, [
        "f43", "f44", "f45", "f46", "f47", "f48",
        "f51", "f52", "f57", "f58", "f60",
        "f116", "f117", "f168", "f169", "f170",
      ]);
    } else if (match.name === "orderbook") {
      sample = pickFields(data, [
        "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20",
        "f31", "f32", "f33", "f34", "f35", "f36", "f37", "f38", "f39", "f40",
      ]);
    } else if (match.name === "timeshare") {
      const trends = Array.isArray(data.trends) ? data.trends : [];
      sample = {
        trendsCount: trends.length,
        firstPoint: trends[0] || null,
        lastPoint: trends[trends.length - 1] || null,
      };
    } else if (match.name === "kline") {
      const klines = Array.isArray(data.klines) ? data.klines : [];
      const klt = extractKlt(u);
      const entry = {
        klt,
        klinesCount: klines.length,
        firstPoint: klines[0] || null,
        lastPoint: klines[klines.length - 1] || null,
      };
      klineResults.push(entry);
      // Store latest for summary
      sample = entry;
    } else if (match.name === "sectors") {
      const diff = Array.isArray(data.diff) ? data.diff : [];
      sample = {
        total: data.total || diff.length,
        firstSector: diff[0]
          ? pickFields(diff[0], ["f3", "f12", "f14", "f128", "f136"])
          : null,
      };
    } else if (match.name === "article") {
      const re = Array.isArray(json.re) ? json.re : [];
      sample = {
        articleCount: re.length,
        firstTitle: re[0]?.post_title || null,
      };
    }

    const info = { url: u, keys: Object.keys(data), sample };
    if (match.name === "kline") {
      // Use unique key per klt
      results.set(`kline_klt${extractKlt(u)}`, info);
    } else {
      results.set(match.name, info);
    }
  } catch (e) {
    results.set(match.name, { url: u, error: e?.message || String(e) });
  }
});

// ── Navigate and wait ──────────────────────────────────────────────────

console.log(`\nNavigating to: ${url}\n`);
await page.goto(url, { waitUntil: "domcontentloaded", timeout: 20000 });
await page.waitForTimeout(6000);

// ── Print results ──────────────────────────────────────────────────────

console.log("=".repeat(70));
console.log(`TARGET: ${url}`);
console.log("=".repeat(70));

if (results.size === 0) {
  console.log("\n⚠  No API responses captured. The page may require interaction or a different URL.\n");
}

for (const [name, info] of results.entries()) {
  console.log(`\n── ${name} ${"─".repeat(Math.max(0, 60 - name.length))}`);
  console.log(`URL: ${info.url}`);
  if (info.error) {
    console.log(`ERROR: ${info.error}`);
  } else {
    // For snapshot, print labelled fields
    if (name === "snapshot" && info.sample) {
      console.log("Fields (app mapping):");
      for (const [k, v] of Object.entries(info.sample)) {
        const label = snapshotLabels[k] || k;
        console.log(`  ${k} = ${v}  (${label})`);
      }
    } else {
      console.log(`Sample: ${JSON.stringify(info.sample, null, 2)}`);
    }
    console.log(`Data keys: [${info.keys.join(", ")}]`);
  }
}

// Summary for multiple kline captures
if (klineResults.length > 0) {
  console.log(`\n── kline summary ${"─".repeat(48)}`);
  for (const kr of klineResults) {
    console.log(`  klt=${kr.klt}: ${kr.klinesCount} points | first=${kr.firstPoint} | last=${kr.lastPoint}`);
  }
}

console.log("\n" + "=".repeat(70));
console.log("Done.");

await browser.close();
