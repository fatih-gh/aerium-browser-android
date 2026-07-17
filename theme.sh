#!/bin/bash
# Aerium identity pass (sourced from build.sh inside chromium/src, after
# patch.sh): product rename, privacy defaults, and battery efficiency.
# Visual theming is left stock so Android's own dynamic-color/dark-theme
# settings work as expected instead of being overridden.

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

# --- HTTPS-First Balanced Mode by default: upgrades navigations to HTTPS
# when a site is expected to support it, without the disruptive full-site
# interstitials of strict HTTPS-Only Mode. Stock Chromium ships this off,
# with a gradual auto-enable heuristic for "typically secure" users that is
# itself feature-flagged off at this version - so nobody gets it without
# this flip. User-changeable in Settings -> Privacy and security -> Security.
sed -i 's/prefs::kHttpsFirstBalancedMode, false,/prefs::kHttpsFirstBalancedMode, true,/' \
    chrome/browser/ui/browser_ui_prefs.cc

# --- Global Privacy Control (https://w3c.github.io/gpc/): a Sec-GPC opt-out
# header plus a readable navigator.globalPrivacyControl JS property, neither
# of which stock Chromium implements (Brave and DuckDuckGo do; CCPA requires
# it from browsers serving California users starting 2027-01-01). Sent/
# reported unconditionally - there's no per-site toggle, matching how DNT
# (still present in Chromium, just hidden from the settings UI) already
# behaves at these same call sites.
sed -i 's|\[MeasureAs=NavigatorVendor\] readonly attribute DOMString vendor;|&\n    // https://w3c.github.io/gpc/#dom-navigator-globalprivacycontrol\n    readonly attribute boolean globalPrivacyControl;|' \
    third_party/blink/renderer/core/frame/navigator.idl
sed -i 's|String vendorSub() const;|&\n  bool globalPrivacyControl() const;|' \
    third_party/blink/renderer/core/frame/navigator.h
sed -i '/^String Navigator::vendorSub() const {$/,/^}$/{/^}$/a\
\
bool Navigator::globalPrivacyControl() const {\
  // https://w3c.github.io/gpc/#dom-navigator-globalprivacycontrol\
  return true;\
}
}' third_party/blink/renderer/core/frame/navigator.cc
sed -i '/^  \/\/ TODO(crbug\.com\/40833603): WARNING: This bypasses the permissions policy\.$/i\
  // Global Privacy Control opt-out signal (https://w3c.github.io/gpc/),\
  // legally recognized under CCPA. Sent unconditionally, matching\
  // Brave/DuckDuckGo'"'"'s default behavior - there'"'"'s no per-site toggle.\
  if (should_update_existing_headers) {\
    headers->RemoveHeader("Sec-GPC");\
  }\
  headers->SetHeaderIfMissing("Sec-GPC", "1");\
' content/browser/loader/browser_initiated_resource_request.cc
sed -i '/^  \/\/ The request.s extra data may indicate that we should set a custom user$/i\
  // Global Privacy Control - see content\/browser\/loader\/\
  \/\/ browser_initiated_resource_request.cc for the browser-initiated case.\
  request.SetHttpHeaderField(blink::WebString::FromUtf8("Sec-GPC"), "1");
' content/renderer/render_frame_impl.cc
sed -i '/^  auto url_request_extra_data = base::MakeRefCounted<WebURLRequestExtraData>();$/i\
  request.SetHttpHeaderField(WebString::FromUtf8("Sec-GPC"), "1");
' third_party/blink/renderer/platform/loader/fetch/url_loader/dedicated_or_shared_worker_global_scope_context_impl.cc \
  third_party/blink/renderer/modules/service_worker/web_service_worker_fetch_context_impl.cc

echo "[aerium] theme + rename pass applied"
