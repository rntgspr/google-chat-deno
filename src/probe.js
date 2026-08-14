// Runs inside the hosted Google Chat page, not in the Deno host. Nothing here
// can reference the host's scope: it is serialized as text and evaluated in the
// page, and its only channel back is `globalThis.bindings`.

/**
 * Reads what the page can see about its own identity — the URL it settled on,
 * the user agent it reports, and whether the host bridge reached it.
 */
function readIdentity() {
  return {
    href: location.href,
    title: document.title,
    userAgent: navigator.userAgent,
    uaData: navigator.userAgentData
      ? navigator.userAgentData.brands.map((b) => b.brand + "/" + b.version).join(" ")
      : null,
    hasBindings: typeof globalThis.bindings,
    notificationPermission: (window.Notification && window.Notification.permission) || null,
  };
}

/**
 * Replaces window.Notification with a wrapper that reports clicks to the host,
 * so clicking a desktop notification can raise the window. Idempotent: a marker
 * on window keeps repeated probes from wrapping the wrapper.
 */
function installNotificationWrapper() {
  // DEBT: applied after load, so it only holds while Chat reads the global lazily.
  if (window.__chatNotificationWrapped) return true;

  const Native = window.Notification;

  const Wrapped = function (title, options) {
    const instance = new Native(title, options);
    instance.addEventListener("click", () => globalThis.bindings.notificationClicked());
    return instance;
  };

  Wrapped.requestPermission = Native.requestPermission.bind(Native);
  Object.defineProperty(Wrapped, "permission", { get: () => Native.permission });

  window.Notification = Wrapped;
  window.__chatNotificationWrapped = true;

  return true;
}

/**
 * Counts the DOM landmarks the desktop integrations would need: unread groups,
 * the favicon that signals notification state, and the search input.
 */
function readLandmarks() {
  // UNFINISHED: the tooltip selectors match nothing on the current Chat; they need rediscovery.
  const favicon = document.querySelector('link[rel="shortcut icon"], link[rel="icon"]');

  return {
    chatGroups: document.querySelectorAll('div[data-tooltip="Chat"][role="group"]').length,
    spaceGroups: document.querySelectorAll('div[data-tooltip="Spaces"][role="group"]').length,
    favicon: (favicon && favicon.href) || null,
    searchInput: !!document.querySelector('input[name="q"]'),
  };
}

(async () => {
  const report = readIdentity();

  try {
    report.overrideHeld = installNotificationWrapper();
  } catch (e) {
    report.overrideHeld = "threw: " + e.message;
  }

  report.scrape = readLandmarks();

  await globalThis.bindings.report(report);
})();
