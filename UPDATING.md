# Updating Aerium (Android)

How to move Aerium onto a newer Chromium/Vanadium release when the
**Upstream watch** workflow opens a tracking issue.

## Where things live

- **Base**: `vanadium` submodule (GrapheneOS Vanadium) + upstream
  `jqssun/android-helium-browser` scripts. Chromium version is derived
  from `vanadium/args.gn`.
- **Our changes**: `build.sh` (staged CI build), `theme.sh` (rename +
  navy theme + platform autofill), `patch.sh` (extension/UX seds — kept
  in sync with upstream), `res/` (Aerium icons), `args.gn`, the staged
  workflow under `.github/`.

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
  update the sed's match text. `theme.sh`'s palette seds are the most
  fragile across versions — verify the GM3 color names still exist in
  `ui/android/java/res/values/color_palette.xml`.

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
