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

# --- Widevine, toggleable and off by default (Brave-style). Aerium doesn't
# bundle Google's proprietary CDM binary, but the interface is compiled in
# (enable_widevine defaults to true for is_android and would default to true
# for Chrome-branded desktop builds too - see third_party/widevine/cdm/
# widevine.gni). Registering it unconditionally means every DRM-gated site
# can silently probe for it, so gate registration on a new chrome://flags
# entry instead. No ungoogled-chromium existing_switch_flag_entries.h here
# (Vanadium isn't ungoogled-chromium-based), so the flag is added directly
# to the main kFeatureEntries array.
sed -i '/^const FeatureEntry kFeatureEntries\[\] = {$/a\
    {"enable-widevine",\
     "Enable Widevine DRM",\
     "Registers the Widevine CDM so DRM-protected sites can play back content. Off by default - Aerium flag.",\
     kOsAll, SINGLE_VALUE_TYPE("enable-widevine")},
' chrome/browser/about_flags.cc
sed -i '/^  AddWidevine(cdms);$/c\
  // Off by default - Aerium doesn'"'"'t bundle Google'"'"'s proprietary CDM, and\
  // registering it unconditionally means every DRM-gated site can silently\
  // probe for it. Users who want DRM playback turn it on at\
  // chrome://flags/#enable-widevine.\
  if (base::CommandLine::ForCurrentProcess()->HasSwitch("enable-widevine")) {\
    AddWidevine(cdms);\
  }' chrome/common/media/cdm_registration.cc

# --- Default search engines: replace every per-country engine list with one
# fixed privacy-focused set - Startpage (default), DuckDuckGo, DuckDuckGo
# Lite, DuckDuckGo HTML and SearXNG (searx.be instance). Stock keeps
# Google-led per-country lists; ungoogled-style builds leave the user with a
# broken/absent default until they configure one manually. Any other engine
# can still be added by hand in settings.
#
# Mechanics (verified against Chromium 150.0.7871.124 source):
# - prepopulated_engines.json is the master engine list (startpage already
#   exists upstream, id 113, with a bundled icon; the DuckDuckGo variants and
#   SearXNG are new entries). New IDs use 1001+ so they can never collide
#   with upstream IDs on a version bump (kMaxPrepopulatedEngineID tracks the
#   highest, UMA-only). kCurrentDataVersion is raised so profiles created by
#   earlier builds pick up the new list on update.
# - regional_settings.json's "ZZ" element is the fallback list for countries
#   without their own entry; GetRegionalSettings() in
#   regional_capabilities_utils.cc is redirected to always use it
#   (CountryId() == "ZZ" == unknown country, see country_codes.h), which
#   makes the ZZ list the single list for every country.
# - GetPrepopulatedFallbackSearch() in template_url_prepopulate_data.cc picks
#   the engine it looks up by ID first, falling back to the list head;
#   pointing it at startpage.id makes Startpage the out-of-the-box default
#   (Vanadium's patch 0116 already retargeted the stock google.id lookup to
#   duckduckgo.id, hence the dual pattern below).
SE_DEFS=third_party/search_engines_data/resources/definitions
sed -i '/^    "ecosia": {$/i\
    "duckduckgo_html": {\
      "name": "DuckDuckGo HTML",\
      "keyword": "html.duckduckgo.com",\
      "favicon_url": "https://duckduckgo.com/favicon.ico",\
      "search_url": "https://html.duckduckgo.com/html/?q={searchTerms}",\
      "suggest_url": "https://duckduckgo.com/ac/?q={searchTerms}\&type=list",\
      "type": "SEARCH_ENGINE_DUCKDUCKGO",\
      "id": 1001\
    },\
\
    "duckduckgo_lite": {\
      "name": "DuckDuckGo Lite",\
      "keyword": "lite.duckduckgo.com",\
      "favicon_url": "https://duckduckgo.com/favicon.ico",\
      "search_url": "https://lite.duckduckgo.com/lite/?q={searchTerms}",\
      "suggest_url": "https://duckduckgo.com/ac/?q={searchTerms}\&type=list",\
      "type": "SEARCH_ENGINE_DUCKDUCKGO",\
      "id": 1002\
    },\
' $SE_DEFS/prepopulated_engines.json
sed -i '/^    "seznam": {$/i\
    "searx": {\
      "name": "SearXNG",\
      "keyword": "searx.be",\
      "favicon_url": "https://searx.be/favicon.ico",\
      "search_url": "https://searx.be/search?q={searchTerms}",\
      "type": "SEARCH_ENGINE_OTHER",\
      "id": 1003\
    },\
' $SE_DEFS/prepopulated_engines.json
sed -i 's/"kMaxPrepopulatedEngineID": [0-9]\+,/"kMaxPrepopulatedEngineID": 1003,/; s/"kCurrentDataVersion": [0-9]\+/"kCurrentDataVersion": 250/; s/"name": "startpage",/"name": "Startpage",/' \
    $SE_DEFS/prepopulated_engines.json
sed -i '/^    "ZZ": {$/,/^    }$/{s/^        "&google",$/        "\&startpage",\n        "\&duckduckgo",\n        "\&duckduckgo_lite",\n        "\&duckduckgo_html",\n        "\&searx"/; /^        "&bing",$/d; /^        "&yahoo"$/d}' \
    $SE_DEFS/regional_settings.json
sed -i 's|auto iter = TemplateURLPrepopulateData::kRegionalSettings.find(country_id);|// Aerium: every country gets the same privacy-focused engine list - the\n  // "ZZ" default in regional_settings.json - instead of per-country\n  // Google-led lists.\n  auto iter = TemplateURLPrepopulateData::kRegionalSettings.find(CountryId());|' \
    components/regional_capabilities/regional_capabilities_utils.cc
sed -i 's/^\( *\)\(google\|duckduckgo\)\.id,$/\1startpage.id,/' \
    components/search_engines/template_url_prepopulate_data.cc

echo "[aerium] theme + rename pass applied"
