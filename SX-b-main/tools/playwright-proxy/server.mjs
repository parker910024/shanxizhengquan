import http from "http";
import { URL } from "url";
import { chromium } from "playwright";

const PORT = Number(process.env.PORT || 3001);
const HEADLESS = process.env.HEADLESS !== "false";
const NAV_TIMEOUT = Number(process.env.NAV_TIMEOUT || 15000);
const ALLOW_HOSTS = (process.env.ALLOW_HOSTS || "eastmoney.com")
  .split(",")
  .map((item) => item.trim())
  .filter(Boolean);

const USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

// ── Browser & long-lived context (reused across requests) ──────────────

const browser = await chromium.launch({
  headless: HEADLESS,
  args: ["--no-sandbox", "--disable-dev-shm-usage"],
});

/** Persistent browser context – avoids creating a new one per request. */
let sharedContext = await createContext();

async function createContext() {
  const ctx = await browser.newContext({
    userAgent: USER_AGENT,
    viewport: { width: 1280, height: 720 },
    javaScriptEnabled: true,
  });
  return ctx;
}

/**
 * Get the shared context, recreating it if it was closed or errored.
 */
async function getContext() {
  try {
    // Quick liveness check – will throw if context is closed
    await sharedContext.pages();
  } catch {
    sharedContext = await createContext();
  }
  return sharedContext;
}

// ── Host allow-list check ──────────────────────────────────────────────

function isHostAllowed(hostname) {
  return ALLOW_HOSTS.some(
    (h) => hostname === h || hostname.endsWith(`.${h}`) || hostname.includes(h),
  );
}

// ── Sector list helper (dedicated endpoint used by EastMoneyMarketRepository) ─

const CLIST_URL = "https://push2.eastmoney.com/api/qt/clist/get";

function buildSectorUrl(type) {
  return (
    `${CLIST_URL}?pn=1&pz=20&po=1&np=1&fltt=2&invt=2&fid=f3` +
    `&fs=m:90+t:${type}` +
    `&fields=f3,f12,f14,f128,f136`
  );
}

// ── Fast fetch via page.evaluate(fetch(...)) ───────────────────────────
//    Much faster than full page.goto() for simple JSON/JSONP API calls.

async function fetchViaPage(targetUrl) {
  const ctx = await getContext();
  const page = await ctx.newPage();
  try {
    await page.setExtraHTTPHeaders({
      Referer: "https://quote.eastmoney.com/",
    });
    // Use the browser's native fetch inside the page context.
    // This inherits cookies, TLS fingerprint, etc. from the Chromium process.
    const text = await page.evaluate(async (url) => {
      const resp = await fetch(url, {
        credentials: "omit",
        headers: { Accept: "*/*" },
      });
      return resp.text();
    }, targetUrl);
    return text;
  } finally {
    await page.close();
  }
}

// ── Full navigation fetch (fallback for pages that need JS execution) ──

async function fetchViaNavigation(targetUrl) {
  const ctx = await getContext();
  const page = await ctx.newPage();
  try {
    await page.setExtraHTTPHeaders({
      Referer: "https://quote.eastmoney.com/",
    });
    await page.route("**/*", (route) => {
      const type = route.request().resourceType();
      if (["image", "stylesheet", "font", "media"].includes(type)) {
        return route.abort();
      }
      return route.continue();
    });
    const response = await page.goto(targetUrl, {
      waitUntil: "domcontentloaded",
      timeout: NAV_TIMEOUT,
    });
    if (!response) throw new Error("no response");
    return await response.text();
  } finally {
    await page.close();
  }
}

// ── HTTP Server ────────────────────────────────────────────────────────

const server = http.createServer(async (req, res) => {
  try {
    if (!req.url) {
      res.writeHead(400, { "content-type": "text/plain; charset=utf-8" });
      res.end("missing url");
      return;
    }

    const parsed = new URL(req.url, `http://${req.headers.host || "localhost"}`);

    // ── Health check ──
    if (parsed.pathname === "/health") {
      res.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
      res.end("ok");
      return;
    }

    // ── /sectors?type=2|3  (dedicated endpoint for EastMoneyMarketRepository) ──
    if (parsed.pathname === "/sectors") {
      const sectorType = Number(parsed.searchParams.get("type") || "2");
      const sectorUrl = buildSectorUrl(sectorType);
      const text = await fetchViaPage(sectorUrl);
      res.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
      res.end(text);
      return;
    }

    // ── /proxy?url=...  (generic proxy endpoint) ──
    if (parsed.pathname !== "/proxy") {
      res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      res.end("not found");
      return;
    }

    const target = parsed.searchParams.get("url");
    if (!target) {
      res.writeHead(400, { "content-type": "text/plain; charset=utf-8" });
      res.end("missing url param");
      return;
    }

    const targetUrl = new URL(target);
    if (!isHostAllowed(targetUrl.hostname)) {
      res.writeHead(403, { "content-type": "text/plain; charset=utf-8" });
      res.end("host not allowed");
      return;
    }

    // Prefer fast fetch mode; fall back to full navigation on failure
    const mode = parsed.searchParams.get("mode"); // "nav" forces navigation
    let responseText = "";
    if (mode === "nav") {
      responseText = await fetchViaNavigation(target);
    } else {
      try {
        responseText = await fetchViaPage(target);
      } catch (fetchErr) {
        console.warn(`[proxy] fetch-mode failed, falling back to nav: ${fetchErr.message}`);
        responseText = await fetchViaNavigation(target);
      }
    }

    res.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
    res.end(responseText);
  } catch (err) {
    console.error(`[proxy] error: ${err.message}`);
    res.writeHead(502, { "content-type": "text/plain; charset=utf-8" });
    res.end(String(err?.message || err));
  }
});

server.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Playwright proxy listening on :${PORT}`);
});

// ── Graceful shutdown ──────────────────────────────────────────────────

const shutdown = async () => {
  try { await sharedContext.close(); } catch { /* ignore */ }
  await browser.close();
  server.close(() => process.exit(0));
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
