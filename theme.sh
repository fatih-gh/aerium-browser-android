#!/bin/bash
# Aerium identity pass (sourced from build.sh inside chromium/src, after
# patch.sh): complete product rename + space-navy dark theme.

# --- Product name in every UI string source (.grd/.grdp/.xtb). Vanadium's
# branding patches already renamed their subset; this sweep catches the rest
# (e.g. "About Chromium" strings living inside <if expr> branches). Changed
# source texts get new grit IDs, so affected strings fall back to English in
# non-English locales.
grep -rl --include='*.grd' --include='*.grdp' --include='*.xtb' 'Chromium' \
    chrome components ui extensions content 2>/dev/null | while read -r f; do
    sed -i 's/The Chromium Authors/Dioide/g; s/Chromium/Aerium/g' "$f"
done

# --- Use the Android Autofill framework by default so third-party password
# managers (Bitwarden etc.) fill web forms natively instead of relying on
# flaky accessibility-based compatibility mode. User-changeable in
# Settings -> Autofill services.
sed -i 's/registry->RegisterBooleanPref(kAutofillUsingPlatformAutofill, false);/registry->RegisterBooleanPref(kAutofillUsingPlatformAutofill, true);/' \
    components/autofill/core/common/autofill_prefs.cc

# --- Default to dark theme (user can still change it in appearance settings)
sed -i 's/return ThemeType.SYSTEM_DEFAULT;/return ThemeType.DARK;/' \
    chrome/browser/ui/android/night_mode/java/src/org/chromium/chrome/browser/night_mode/NightModeUtils.java

# --- Keep our palette: do not recolor the UI from the system wallpaper
# (Material You dynamic colors would override the Aerium navy)
sed -i '/protected boolean shouldApplyDynamicColors() {/,/^    }/ s/return true;/return false;/' \
    chrome/android/java/src/org/chromium/chrome/browser/ChromeBaseAppCompatActivity.java

# --- Space-navy dark surfaces: retint the GM3 baseline dark palette from
# neutral grey to deep navy (values verified against Chromium 150)
P=ui/android/java/res/values/color_palette.xml
sed -i 's/#131314/#101730/g; s/#1E1F20/#1A2340/g; s/#1B1B1B/#151D38/g; s/#282A2C/#232D4E/g; s/#333537/#2C3859/g; s/#37393B/#313D61/g' "$P"
sed -i 's/#28282A/#262E4C/g; s/#2D2E31/#2A3354/g; s/#313336/#2E3859/g; s/#333539/#303B5D/g; s/#37393D/#344062/g; s/#42454B/#3D4B72/g' "$P"

echo "[aerium] theme + rename pass applied"
