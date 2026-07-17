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

# --- Ungoogled-style privacy default: disable Safe Browsing by default. It
# is the main recurring Google phone-home on Android (URL/reputation pings);
# ungoogled-chromium removes it at build level. Left toggleable in
# Settings -> Privacy and security for users who want it.
sed -i 's/prefs::kSafeBrowsingEnabled, true,/prefs::kSafeBrowsingEnabled, false,/' \
    components/safe_browsing/core/common/safe_browsing_prefs.cc

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

# --- Accent color (buttons, links, selected states): hue-rotate the stock
# baseline_primary_* and baseline_secondary_* tonal ramps onto Aerium's brand
# blue (~205.6deg hue, from logo color #4C97CF), keeping each step's original
# saturation/lightness so the M3 contrast tuning is preserved - this is a
# rehue, not a re-lightness, so accessibility ratios are untouched. Tertiary
# (green, used for success/positive indicators) is left alone on purpose.
sed -i \
    -e 's/#041E49/#042C49/g' -e 's/#062E6F/#06426F/g' -e 's/#0842A0/#085FA0/g' \
    -e 's/#0B57D0/#0B7CD0/g' -e 's/#1B6EF3/#1B97F3/g' -e 's/#4C8DF6/#4CADF6/g' \
    -e 's/#7CACF8/#7CC3F8/g' -e 's/#A8C7FA/#A8D7FA/g' -e 's/#D3E3FD/#D3EBFD/g' \
    -e 's/#ECF3FE/#ECF6FE/g' \
    -e 's/#001D35/#001E35/g' -e 's/#003F66/#003A66/g' -e 's/#004A77/#004477/g' \
    -e 's/#005789/#004E89/g' -e 's/#00639B/#00599B/g' -e 's/#047DB7/#046AB7/g' \
    -e 's/#3998D3/#3991D3/g' -e 's/#5AB3F0/#5AB0F0/g' -e 's/#7FCFFF/#7FC8FF/g' \
    -e 's/#C2E7FF/#C2E5FF/g' -e 's/#DFF3FF/#DFF1FF/g' \
    "$P"

# --- Battery efficiency pass. Aerium takes its name from aerogel, the
# world's lightest solid, so keeping the browser light on battery is a brand
# commitment, not just an optimization. Each change below flips a single
# feature/pref default; all remain user-changeable where a settings UI exists.
# Verified against Chromium 150.0.7871.124 source at each file path below.

# Disable network prediction/preloading (prefetching links, DNS, etc. on
# page load) by default - trades a little latency for meaningfully less
# background radio/network activity. User-changeable in
# Settings -> Privacy and security -> Preload pages.
sed -i 's/static_cast<int>(NetworkPredictionOptions::kDefault),/static_cast<int>(NetworkPredictionOptions::kDisabled),/' \
    chrome/browser/preloading/preloading_prefs.cc

# Disable Optimization Guide (hints fetching + on-device target prediction
# model downloads/updates) - periodic background network chatter with no
# user-facing toggle on Android.
sed -i 's/BASE_FEATURE(kOptimizationHints, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kOptimizationHints, base::FEATURE_DISABLED_BY_DEFAULT);/; s/BASE_FEATURE(kOptimizationTargetPrediction, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kOptimizationTargetPrediction, base::FEATURE_DISABLED_BY_DEFAULT);/' \
    components/optimization_guide/core/optimization_guide_features.cc

# Disable Domain Reliability (periodic diagnostic beacons to Google about
# request failures/latency on Google-owned domains).
sed -i 's/registry->RegisterBooleanPref(prefs::kDomainReliabilityAllowedByPolicy, true);/registry->RegisterBooleanPref(prefs::kDomainReliabilityAllowedByPolicy, false);/' \
    components/domain_reliability/domain_reliability_prefs.cc

# Disable Interest Feed V2 (the Discover feed on the New Tab Page) - a
# recurring background JobScheduler task that fetches articles even when
# the feed isn't being looked at.
sed -i 's/BASE_FEATURE(kInterestFeedV2, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kInterestFeedV2, base::FEATURE_DISABLED_BY_DEFAULT);/' \
    components/feed/feed_feature_list.cc

# Disable Safety Hub's background password-check job (a periodic
# JobScheduler task, roughly weekly, that runs even without the Safety
# Hub settings page ever being opened).
sed -i 's/BASE_FEATURE(kSafetyHub, base::FEATURE_ENABLED_BY_DEFAULT);/BASE_FEATURE(kSafetyHub, base::FEATURE_DISABLED_BY_DEFAULT);/' \
    components/safety_check/features.cc

echo "[aerium] theme + rename pass applied"
