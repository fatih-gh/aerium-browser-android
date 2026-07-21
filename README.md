<p align="center">
  <img src="res/aerium.svg" width="96" height="96" alt="Aerium logo">
</p>

<h1 align="center">Aerium</h1>

<p align="center"><i>by Dioide</i></p>

[![build](https://img.shields.io/github/actions/workflow/status/fatih-gh/aerium-browser-android/build.yml?label=build)](https://github.com/fatih-gh/aerium-browser-android/actions/workflows/build.yml)
[![release](https://img.shields.io/github/v/release/fatih-gh/aerium-browser-android)](https://github.com/fatih-gh/aerium-browser-android/releases/latest)
[![license](https://img.shields.io/badge/License-GPLv2-blue.svg)](LICENSE)

Aerium is a browser for people who'd rather their browser stayed out of the way. No telemetry calling home, no ad platform baked into the settings page. Extensions — including Manifest V2 — install straight from the Chrome Web Store, something most Android browsers still can't do.

[**Download for Android**](https://github.com/fatih-gh/aerium-browser-android/releases/latest)

## What you get

- **Extensions that actually work.** Manifest V2 support and Chrome Web Store access, plus Opera and Microsoft Edge add-on stores. Load an unpacked extension manually if you need to.
- **Your password manager, working properly.** Android's own autofill framework is on by default, so Bitwarden and similar apps fill forms natively instead of falling back to flaky accessibility tricks.
- **Search that works from the first keystroke.** Startpage is the default engine, with DuckDuckGo, DuckDuckGo Lite, DuckDuckGo HTML, and SearXNG ready to pick in Settings — and any other engine addable by hand.
- **Its own name, its own icon — your own colors.** Dynamic color from your wallpaper and the light/dark toggle work exactly like stock Android Chrome; nothing forces a palette on top of it.
- **Safe Browsing off by default.** It's the one Android feature that phones home to Google on every page you visit. Turn it back on in Settings if you want it.
- **Lighter by default.** Background network chatter — hint prefetching, the Discover feed's background refresh, domain reliability pings — is off out of the box. The name comes from aerogel, the lightest solid there is.
- **HTTPS by default.** Balanced Mode upgrades navigations to HTTPS automatically, without the disruptive full-site warnings of strict HTTPS-only enforcement.
- **Global Privacy Control sent by default.** The `Sec-GPC` opt-out signal and `navigator.globalPrivacyControl` — recognized under CCPA, but still not implemented in stock Chromium — are on for every page, no toggle needed.
- **Canvas, text-measurement, and WebGL fingerprinting resistance on by default.** Canvas readbacks and `getClientRects()`/`measureText()` get a barely-perceptible noise; WebGL's renderer/vendor strings return generic values instead of your actual GPU. Same protections Windows Aerium ships, no toggle needed.
- **DRM off by default, your call either way.** Widevine isn't registered unless you turn it on at `chrome://flags/#enable-widevine`.

## Using extensions

Open the [Chrome Web Store](https://chromewebstore.google.com/), switch on **Desktop site** from the <kbd>⋮</kbd> menu, and install as normal. A few worth knowing about, all free and open-source:

- **[uBlock Origin](https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm) (recommended)** — content blocking that doesn't get in your way. Install this one first.
- [**uBlock Origin Lite**](https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh) — same author, same filter lists, a lighter footprint if that's what you'd rather trade for.
- [**floccus**](https://chromewebstore.google.com/detail/floccus-bookmarks-sync/fnaicdffflnofjppbagibeoednhnbjhg) — bookmark sync across browsers, using storage you control.
- [**TablissNG**](https://chromewebstore.google.com/detail/tablissng/dlaogejjiafeobgofajdlkkhjlignalk) — a new tab page worth looking at twice, actively maintained.
- [**Cookie AutoDelete V3**](https://chromewebstore.google.com/detail/cookie-autodelete-v3/jofioghmpdcgiiobkhmdojhjbjiejfbd) — clears a site's cookies once you close its tabs, with a whitelist for the ones you want to keep.
- [**Decentraleyes**](https://chromewebstore.google.com/detail/decentraleyes/ldpochfccmkkmhdbclfhpagapcfdljkj) — serves common libraries locally instead of fetching them from a CDN, cutting a quiet tracking channel most blockers miss.

Opera and Microsoft Edge add-on stores work too. To load an unpacked extension, open **Manage extensions** (`chrome://extensions`), enable **Developer mode**, and choose **Load unpacked**.

Pin an extension's icon to the toolbar from the <kbd>⋮</kbd> menu next to it in the extensions list to reach its popup directly. To allow one in Incognito, go to **Manage extensions → Details** and enable **Allow in Incognito**.

## Other things worth knowing

- `chrome://chrome-urls` lists every internal page; `chrome://flags` has the full set of experiments.
- WebRTC IP handling lives under **Settings → Privacy and security**. If a voice service misbehaves because your IP is shielded by default, switch it to **Default public interface only** or **Default**.

## More privacy flags to consider

These aren't on by default — each is a deliberate tradeoff, so Aerium leaves them for you to opt into individually at `chrome://flags`:

- `chrome://flags/#disable-search-engine-collection` — stop Chromium from scraping search engines it notices on visited pages.
- `chrome://flags/#enable-parallel-downloading` — split downloads into multiple simultaneous requests for faster large files.
- `chrome://flags/#fingerprinting-canvas-image-data-noise` — slightly perturb Canvas image-data readback to resist fingerprinting.
- `chrome://flags/#fingerprinting-canvas-measuretext-noise` — add tiny random noise to Canvas measureText() output.
- `chrome://flags/#fingerprinting-client-rects-noise` — add tiny random noise to getClientRects()/getBoundingClientRect().
- `chrome://flags/#force-punycode-hostnames` — always show internationalized domain names as punycode, closing a homograph-spoofing vector.
- `chrome://flags/#increase-incognito-storage-quota` — raise the storage quota for Incognito and Guest profiles.
- `chrome://flags/#popups-to-tabs` — open popup windows as new tabs instead.
- `chrome://flags/#reduced-system-info` — reduce system info exposed via headers/JS, and report two CPU cores regardless of the real count.
- `chrome://flags/#remove-client-hints` — strip Client Hints headers (detailed system info sent to servers).
- `chrome://flags/#remove-tabsearch-button` — remove the tab-search button from the tab strip.
- `chrome://flags/#show-avatar-button` — control when the profile avatar button appears (always, only in Incognito/Guest, or never).
- `chrome://flags/#spoof-webgl-info` — return generic WebGL renderer/vendor strings instead of your real GPU info.

## Building

Every push to `main` builds automatically on GitHub Actions, split across sequential jobs to fit a full compile inside the free tier's per-job time limit. Every finished build is published as a release.

Want your own signed build?

1. Fork this repository.
2. Generate a signing keystore and add it as two base64-encoded repository secrets, `STORE_TEST_JKS` and `LOCAL_TEST_JKS` (see `common.sh` for the expected format).
3. Run the `Build` workflow from the Actions tab.

## Contributing

Issues and pull requests are welcome. See [UPDATING.md](UPDATING.md) for how the build stays in sync with upstream releases.

## About

Aerium is a fork of [Titanium Browser for Android](https://github.com/jqssun/android-titanium-browser). Licensed under [GPLv2](LICENSE).
