# Updating Aerium (Android)

How to move Aerium onto a newer Chromium/Vanadium release when the
**Upstream watch** workflow opens a tracking issue.

## Where things live

- **Base**: `vanadium` submodule (GrapheneOS Vanadium) + upstream
  `jqssun/android-helium-browser` scripts. Chromium version is derived
  from `vanadium/args.gn`.
- **Our changes**: `build.sh` (staged CI build), `theme.sh` (rename,
  privacy/battery-efficiency defaults, platform autofill, search-engine
  defaults, fingerprint-protection parity — visual theming is left
  stock), `patch.sh` (extension/UX seds — kept in sync with upstream),
  `res/` (Aerium icons), `args.gn`, the staged workflow under `.github/`.

## Sync procedure

> ⚠️ Upstream **force-pushes** its `main`. Never `git merge upstream/main`
> after the first time — the history is rewritten. Cherry-pick instead.

1. `git fetch upstream`
2. Diff the scripts that upstream owns:
   ```
   git diff HEAD upstream/main -- patch.sh common.sh args.gn
   ```
3. Port **only** the new lines into our copies by hand:
   - New `patch.sh` sed blocks → paste into our `patch.sh`, keeping our
     `helium`→`aerium` path renames (`aerium/android_config/...`,
     `AeriumConfParser.java`, etc.).
   - Ignore upstream changes to `res/icon.sh`, `res/icon.svg`,
     `build.sh`, `.github/` — those are fully replaced by our versions.
4. Bump the base: `git -C vanadium fetch --tags && git -C vanadium checkout <newtag>`
   then `git add vanadium`.
5. `bash -n build.sh patch.sh theme.sh common.sh` (syntax check).
6. Commit, then dispatch **Build** with `fresh: true` (the saved tree is
   for the old version and must be discarded).
7. When green, the `publish-release` job tags `v<version>` automatically.
8. Update `.github/.upstream-seen` if you want to silence the watcher for
   that commit (the workflow also updates it via its issue flow).

## When a patch fails to apply

A bumped Chromium often moves code a `patch.sh` sed targets, so the sed
silently no-ops or `git am` (Vanadium patches) rejects.

- **Vanadium `git am` reject** (stage 1 fails fast): the offending patch
  is named in the log. Check whether Vanadium upstream already updated it
  for the new Chromium — usually bumping the submodule to a tag that
  matches the Chromium version fixes it.
- **Our `patch.sh` sed no-op** (compile error later, e.g. an expected
  symbol missing): grep the new Chromium source for the changed line and
  update the sed's match text.
- **Search-engine block in `theme.sh`**: targets
  `third_party/search_engines_data/resources/definitions/*.json` — a
  DEPS-pulled subproject that only exists after `gclient sync`, which is
  why the block lives in `theme.sh` (runs post-sync) and not in a
  `git am` patch (those run pre-sync). Its fallback-ID sed matches both
  `google.id` and `duckduckgo.id` because Vanadium's patch 0116 already
  retargets the stock lookup — if Vanadium drops or renames 0116 this
  still works. Our engine IDs start at 1001 so upstream additions can
  never collide; if upstream raises `kCurrentDataVersion` past 250,
  raise ours above it again.
- **Fingerprint-protection block in `theme.sh`**: touches
  `runtime_enabled_features.json5` (new `status: "stable"` entries -
  no flag or command-line switch needed, unlike Windows's
  ungoogled-chromium/bromite flags which need `components/ungoogled`,
  absent on Vanadium) plus `document.cc/.h`, `element.cc`, `range.cc`,
  `text_metrics.cc/.h`, `base_rendering_context_2d.cc` (two call
  sites - measureText and getImageData), `static_bitmap_image.cc/.h`,
  `image_encoder.cc`, `platform/BUILD.gn` (one `include_dirs` entry for
  `third_party/skia/include/private`), and `blink/common/features.cc`/
  `public/common/features.h` (new `kSpoofWebGLInfo` BASE_FEATURE,
  self-contained - no `components/ungoogled` dep needed since there's
  no command-line delivery, just a compile-time default). If a sed
  no-ops, the anchor line moved; re-derive it from the *pristine*
  Chromium source at the new tag (not from Windows's patches, which are
  diffed against a different intermediate state) - `git diff` against a
  fresh checkout of the new tag's `third_party/blink/...` files is the
  fastest way to spot what shifted.

## Seeded incremental builds (planned)

A minor Chromium bump changes ~10% of files, so recompiling from scratch
(9–12 stages) is wasteful in principle. The **within-run resume** already
implemented (zstd build-tree artifact handed between stages, restored on
re-dispatch) covers the common case: a failed/timed-out build continues
instead of restarting.

Cross-*version* seeding (reuse the previous version's compiled tree when
bumping Chromium) is **not yet wired up** — it requires checking a new
Chromium tag out over a tree that carries Vanadium's `git am` commits and
already-applied `patch.sh`/`theme.sh` edits, which is fiddly to get right
and must be validated against a real bump. Until then, bump builds use
`fresh: true` and rebuild from scratch. Track this in the roadmap.
