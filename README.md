<p align="center">
  <img src="res/aerium.svg" width="96" height="96" alt="Aerium logo">
</p>

<h1 align="center">Aerium for Android</h1>

<p align="center"><i>by Dioide</i></p>

[![build](https://img.shields.io/github/actions/workflow/status/fatih-gh/aerium-browser-android/build.yml?label=build)](https://github.com/fatih-gh/aerium-browser-android/actions/workflows/build.yml)
[![release](https://img.shields.io/github/v/release/fatih-gh/aerium-browser-android)](https://github.com/fatih-gh/aerium-browser-android/releases/latest)
[![license](https://img.shields.io/badge/License-GPLv2-blue.svg)](LICENSE)

A privacy-hardened, extension-capable Chromium browser for Android, built on [Vanadium](https://github.com/GrapheneOS/Vanadium) (GrapheneOS), with a deep-navy space identity and a handful of defaults chosen for a saner out-of-the-box experience. arm64 only, built entirely on free GitHub Actions runners.

[**Download the latest release**](https://github.com/fatih-gh/aerium-browser-android/releases/latest)

## What's different from stock Vanadium

- **Extensions, including Manifest V2**, installable straight from the Chrome Web Store, plus Opera and Microsoft Edge add-on stores. Unpacked extensions can also be loaded manually via the Storage Access Framework picker.
- **Space-navy theme by default** — dark UI, a radial deep-space gradient on the New Tab Page, and the Aerium roundel in place of the stock icon.
- **Android platform autofill enabled by default**, so third-party password managers (Bitwarden and friends) fill web forms natively instead of falling back to unreliable accessibility-based autofill.
- **Safe Browsing off by default** — the main recurring Google phone-home on Android — toggleable back on in Settings if you want it.
- **Aerium branding throughout**: app name, package ID (`io.github.fatihgh.aerium`), icons, launcher tiles.

## Usage

### Installing extensions

Open the [Chrome Web Store](https://chromewebstore.google.com/), switch on **Desktop site** from the <kbd>⋮</kbd> menu, and install as normal. Manifest V2 (MV2) extensions are supported — [uBlock Origin](https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm) and [floccus bookmarks sync](https://chromewebstore.google.com/detail/floccus-bookmarks-sync/fnaicdffflnofjppbagibeoednhnbjhg) are both good starting points.

Opera and Microsoft Edge add-on stores work too. You can also load an unpacked extension by opening **Manage extensions** (`chrome://extensions`), enabling **Developer mode**, and choosing **Load unpacked** — pick the extension's folder in the file picker.

### Using extensions

Pin an extension's icon to the toolbar from the <kbd>⋮</kbd> menu next to it in the extensions list to access its popup directly. To allow an extension in Incognito, go to **Manage extensions → Details** and enable **Allow in Incognito**.

### Debug and flags

`chrome://chrome-urls` lists every internal page; `chrome://flags` has the full set of experiments, same as upstream Chromium.

### WebRTC IP handling

**Settings → Privacy and security → WebRTC IP handling policy**. If a WebRTC service (e.g. Discord voice) misbehaves because your IP is shielded by default, switch this to **Default public interface only** or **Default**.

## Building it yourself

Builds run entirely on free GitHub Actions (public repo, staged across resumable jobs to fit Chromium's compile time into the free-tier limits). To build your own signed APK:

1. Fork this repository.
2. Generate a signing keystore and add it as two base64-encoded repository secrets, `STORE_TEST_JKS` and `LOCAL_TEST_JKS` (see `common.sh` for the expected format).
3. Go to **Actions → Build → Run workflow**.

See [UPDATING.md](UPDATING.md) for the version-bump/maintenance playbook.

## Credits

Built on [Vanadium](https://github.com/GrapheneOS/Vanadium) by [GrapheneOS](https://github.com/GrapheneOS), and forked from [jqssun/android-helium-browser](https://github.com/jqssun/android-helium-browser), which pioneered extension support on Chromium for Android. Also indebted to [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium) for the broader de-Googling approach this project draws on. All credit for the underlying engineering goes to those projects; Aerium is our own fork, theme, and set of default choices layered on top.

## License

[GPLv2](LICENSE), inherited from the upstream projects this is built on.
