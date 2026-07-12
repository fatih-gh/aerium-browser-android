#!/bin/bash
# Aerium for Android — staged/resumable build.
#
# Usage:
#   ./build.sh          one-shot build (needs a beefy machine)
#   ./build.sh --ci     time-boxed CI stage: builds for at most
#                       $BUILD_TIMEOUT_MIN minutes, then stops gracefully so
#                       the next stage can resume from the build tree.
#
# On success writes release/aerium-<version>-arm64-v8a.apk and release/finished.marker
set -e
source common.sh

MODE_CI=0
[ "$1" = "--ci" ] && MODE_CI=1
# Total time budget for this script per CI stage (setup + compile). The job
# timeout is 350 min; the remainder is left for artifact packing/upload.
TOTAL_BUDGET_MIN=${TOTAL_BUDGET_MIN:-250}
START_TS=$(date +%s)

export VERSION=$(grep -m1 -o '[0-9]\+\(\.[0-9]\+\)\{3\}' vanadium/args.gn)
export CHROMIUM_SOURCE=https://chromium.googlesource.com/chromium/src.git
export DEBIAN_FRONTEND=noninteractive
echo "[aerium] chromium version: $VERSION  ci: $MODE_CI"

# Keep the big tool caches on the large build mount (chromium/) instead of the
# small root filesystem: vpython venvs alone are multiple GB and overflow the
# CI runner's root disk otherwise. Not part of the stage artifact; they are
# recreated cheaply on each stage.
mkdir -p chromium/.vpython-root chromium/.cipd-cache chromium/.tmp
export VPYTHON_VIRTUALENV_ROOT="$SCRIPT_DIR/chromium/.vpython-root"
export CIPD_CACHE_DIR="$SCRIPT_DIR/chromium/.cipd-cache"
export TMPDIR="$SCRIPT_DIR/chromium/.tmp"

# --- system dependencies: needed on every (fresh) CI runner -----------------
sudo apt-get update
sudo apt-get install -y sudo lsb-release file nano git curl python3 python3-pillow imagemagick librsvg2-bin zstd

if [ ! -d depot_tools ]; then
    git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi
export PATH="$SCRIPT_DIR/depot_tools:$PATH"

# --- source setup: only on the first stage ----------------------------------
if [ ! -f chromium/src/BUILD.gn ]; then
    # git am needs a committer identity on fresh CI runners
    git config --global user.name  >/dev/null 2>&1 || git config --global user.name 'github-actions[bot]'
    git config --global user.email >/dev/null 2>&1 || git config --global user.email 'github-actions[bot]@users.noreply.github.com'
    mkdir -p chromium/src/out/Default
    cd chromium
    gclient root
    cd src
    git init
    git remote add origin $CHROMIUM_SOURCE
    git fetch --depth 1 $CHROMIUM_SOURCE +refs/tags/$VERSION:chromium_$VERSION
    git checkout $VERSION
    export COMMIT=$(git show-ref -s $VERSION | head -n1)
    cat > ../.gclient <<EOF
solutions = [
  {
    "name": "src",
    "url": "$CHROMIUM_SOURCE@$COMMIT",
    "deps_file": "DEPS",
    "managed": False,
    "custom_vars": {
      "checkout_android_prebuilts_build_tools": True,
      "checkout_pgo_profiles": False,
      "checkout_telemetry_dependencies": False,
      "codesearch": "Debug",
    },
  },
]
target_os = ["android"]
EOF
    git submodule foreach git config -f ./.git/config submodule.$name.ignore all
    git config --add remote.origin.fetch '+refs/tags/*:refs/tags/*'

    # https://grapheneos.org/build#browser-and-webview
    rm -rf $SCRIPT_DIR/vanadium/patches/*trichrome-{apk-build-targets,browser-apk-targets}.patch
    rm -rf $SCRIPT_DIR/vanadium/patches/*{detailed,supported}-language*.patch
    rm -rf $SCRIPT_DIR/vanadium/patches/*component-updates.patch
    rm -rf $SCRIPT_DIR/vanadium/patches/*{pdf,PDF,for-content-public}*.patch
    replace "$SCRIPT_DIR/vanadium/patches" "VANADIUM" "AERIUM"
    replace "$SCRIPT_DIR/vanadium/patches" "Vanadium" "Aerium"
    replace "$SCRIPT_DIR/vanadium/patches" "vanadium" "aerium"
    git am --whitespace=nowarn --keep-non-patch $SCRIPT_DIR/vanadium/patches/*.patch

    gclient sync -D --no-history --nohooks
    gclient runhooks
    rm -rf third_party/angle/third_party/VK-GL-CTS/
    ./build/install-build-deps.sh --no-prompt

    source $SCRIPT_DIR/patch.sh
    source $SCRIPT_DIR/theme.sh

    # Some Vanadium patches modify .grd string files without updating the
    # checked-in .gritdeps snapshots (e.g. 0272 touches
    # components_strings.grd), which fails the *_check_gritdeps build
    # targets. Regenerate every snapshot with the official command.
    find . -name '*.grd.gritdeps' -not -path './out/*' | while read -r deps; do
        grd="${deps%.gritdeps}"
        [ -f "$grd" ] || continue
        if python3 tools/grit/grit_info.py --all-inputs "$grd" > "$deps.new" 2>/dev/null; then
            if ! cmp -s "$deps" "$deps.new"; then
                echo "[aerium] regenerated $deps"
            fi
            mv "$deps.new" "$deps"
        else
            echo "[aerium] warning: could not regenerate $deps; keeping original"
            rm -f "$deps.new"
        fi
    done

    cp $SCRIPT_DIR/args.gn out/Default/args.gn
    gn gen out/Default
    cd $SCRIPT_DIR
fi

cd chromium/src

# compile prerequisites must exist on every fresh runner
./build/install-build-deps.sh --no-prompt || true

# --- build (time-boxed in CI mode) -------------------------------------------
if [ $MODE_CI = 1 ]; then
    ELAPSED_MIN=$(( ($(date +%s) - START_TS) / 60 ))
    REMAINING_MIN=$(( TOTAL_BUDGET_MIN - ELAPSED_MIN ))
    if [ $REMAINING_MIN -lt 15 ]; then
        echo "[aerium] no time left for compiling this stage; resuming next stage"
        exit 0
    fi
    echo "[aerium] compiling for at most $REMAINING_MIN minutes"
    set +e
    timeout --foreground -s INT -k 5m ${REMAINING_MIN}m autoninja -C out/Default chrome_public_apk
    RET=$?
    set -e
    if [ $RET = 124 ]; then
        echo "[aerium] time budget reached; build will resume on the next stage"
        exit 0
    elif [ $RET != 0 ]; then
        echo "[aerium] build failed with exit code $RET"
        exit $RET
    fi
else
    autoninja -C out/Default chrome_public_apk
fi

# --- sign & finish ------------------------------------------------------------
export PATH=$PWD/third_party/jdk/current/bin/:$PATH
export ANDROID_HOME=$PWD/third_party/android_sdk/public

mkdir -p $SCRIPT_DIR/release
set_keys
sign_apk "$(find out/Default/apks -name 'Chrome*.apk' | head -n1)" "$SCRIPT_DIR/release/aerium-$VERSION-arm64-v8a.apk"
rm -rf $SCRIPT_DIR/keys
echo "$VERSION" > $SCRIPT_DIR/release/version.txt
touch $SCRIPT_DIR/release/finished.marker
echo "[aerium] build finished: release/aerium-$VERSION-arm64-v8a.apk"
