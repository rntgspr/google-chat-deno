import PROBE from "./probe.js" with { type: "text" };

const CHAT_URL = "https://mail.google.com/chat/u/0";
const CHAT_HOSTS = ["mail.google.com", "chat.google.com", "accounts.google.com", "accounts.youtube.com"];
const RUNTIME_BOOT_MS = 18_000;
const PROBE_INTERVAL_MS = 10_000;

/**
 * Serves a placeholder page so the runtime stops waiting for an application
 * server. The page is never meant to be seen — the window is navigated to Chat
 * once the runtime has finished booting.
 */
const serveBootPage = () => {
  Deno.serve({ port: 0, onListen: () => {} }, () =>
    new Response("<!doctype html><title>booting</title>", {
      headers: { "content-type": "text/html" },
    }));
};

/** Condenses a page report into a single log line. */
const formatReport = (r: Record<string, unknown>): string => {
  const s = (r.scrape as Record<string, unknown>) ?? {};

  return [
    `href=${String(r.href).slice(0, 72)}`,
    `title=${r.title}`,
    `perm=${r.notificationPermission}`,
    `override=${r.overrideHeld}`,
    `chat=${s.chatGroups} spaces=${s.spaceGroups} search=${s.searchInput}`,
    `favicon=${s.favicon ? String(s.favicon).split("/").pop() : null}`,
  ].join("  ");
};

/**
 * Creates the application window and wires the bindings the hosted page calls
 * back through.
 */
const openWindow = () => {
  const win = new Deno.BrowserWindow({
    title: "Google Chat",
    width: 1280,
    height: 860,
  });

  win.bind("report", (payload: Record<string, unknown>) => {
    lastReport = payload;
    return "ack";
  });

  win.bind("notificationClicked", () => {
    win.show();
    win.focus();
    return "ack";
  });

  return win;
};

/**
 * Re-runs the probe on a fixed interval, logging each report and steering the
 * window back to Chat if it ends up anywhere else.
 */
const startProbeLoop = (win: Deno.BrowserWindow) => {
  let tick = 0;

  setInterval(async () => {
    tick++;

    try {
      // The resolved value is always `{ok:true,value:{}}` — read results from `lastReport`.
      await win.executeJs(PROBE);
    } catch (e) {
      console.log(`[t+${tick * 10}s] executeJs threw: ${(e as Error).message}`);
      return;
    }

    console.log(`[t+${tick * 10}s] ${formatReport(lastReport)}`);

    const href = String(lastReport.href ?? "");
    if (!CHAT_HOSTS.some((h) => href.includes(h)) && tick > 2) {
      console.log(`  ^ drifted to ${href || "(unknown)"} — re-navigating`);
      win.navigate(CHAT_URL);
    }
  }, PROBE_INTERVAL_MS);
};

let lastReport: Record<string, unknown> = {};

serveBootPage();
const win = openWindow();

// DEBT: the runtime navigates the window itself on boot, so Chat has to wait it out.
setTimeout(() => win.navigate(CHAT_URL), RUNTIME_BOOT_MS);

startProbeLoop(win);
