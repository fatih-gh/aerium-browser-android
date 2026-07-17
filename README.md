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
- **Its own name, its own icon — your own colors.** Dynamic color from your wallpaper and the light/dark toggle work exactly like stock Android Chrome; nothing forces a palette on top of it.
- **Safe Browsing off by default.** It's the one Android feature that phones home to Google on every page you visit. Turn it back on in Settings if you want it.
- **Lighter by default.** Background network chatter — hint prefetching, the Discover feed's background refresh, domain reliability pings — is off out of the box. The name comes from aerogel, the lightest solid there is.
- **HTTPS by default.** Balanced Mode upgrades navigations to HTTPS automatically, without the disruptive full-site warnings of strict HTTPS-only enforcement.

## Using extensions

Open the [Chrome Web Store](https://chromewebstore.google.com/), switch on **Desktop site** from the <kbd>⋮</kbd> menu, and install as normal. A few worth knowing about, all free and open-source:

- [**uBlock Origin**](https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm) — content blocking that doesn't get in your way.
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

## Building

Every push to `main` builds automatically on GitHub Actions, split across sequential jobs to fit a full compile inside the free tier's per-job time limit. Every finished build is published as a release.

Want your own signed build?

1. Fork this repository.
2. Generate a signing keystore and add it as two base64-encoded repository secrets, `STORE_TEST_JKS` and `LOCAL_TEST_JKS` (see `common.sh` for the expected format).
3. Run the `Build` workflow from the Actions tab.

## Contributing

Issues and pull requests are welcome. See [UPDATING.md](UPDATING.md) for how the build stays in sync with upstream releases.

## About

Aerium is built on [Vanadium](https://github.com/GrapheneOS/Vanadium) by [GrapheneOS](https://github.com/GrapheneOS), with its own branding and defaults layered on top, and draws on [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium) for its broader approach to privacy. Licensed under [GPLv2](LICENSE).
