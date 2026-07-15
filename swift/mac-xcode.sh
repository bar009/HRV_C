#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "mac-xcode.sh must run on macOS." >&2
    exit 1
fi

readonly XCODEGEN_VERSION="2.45.4"
readonly CACHE_ROOT="${HOME}/Library/Caches/com.bar009.hrvc/XcodeGen/${XCODEGEN_VERSION}"
XCODEGEN_BIN=""

find_xcodegen() {
    if command -v xcodegen >/dev/null 2>&1; then
        command -v xcodegen
    elif [[ -x "./XcodeGen/.build/release/xcodegen" ]]; then
        # Compatibility with the no-admin setup used on the current cloud Mac.
        printf '%s\n' "${PWD}/XcodeGen/.build/release/xcodegen"
    elif [[ -x "${CACHE_ROOT}/source/.build/release/xcodegen" ]]; then
        printf '%s\n' "${CACHE_ROOT}/source/.build/release/xcodegen"
    fi
}

install_xcodegen_for_user() {
    echo "XcodeGen ${XCODEGEN_VERSION} is not installed; building it in the user cache."
    mkdir -p "${CACHE_ROOT}"
    rm -rf "${CACHE_ROOT}/source"
    git clone --depth 1 --branch "${XCODEGEN_VERSION}" \
        https://github.com/yonaskolb/XcodeGen.git "${CACHE_ROOT}/source"
    swift build --package-path "${CACHE_ROOT}/source" -c release
}

ensure_xcodegen() {
    XCODEGEN_BIN="$(find_xcodegen || true)"
    if [[ -z "${XCODEGEN_BIN}" ]]; then
        install_xcodegen_for_user
        XCODEGEN_BIN="${CACHE_ROOT}/source/.build/release/xcodegen"
    fi
}

generate_project() {
    ensure_xcodegen
    plutil -lint Support/Info.plist Support/HRV.entitlements
    "${XCODEGEN_BIN}" generate --spec project.yml
}

action="${1:-open}"

case "${action}" in
    generate)
        generate_project
        ;;
    open)
        generate_project
        open HRV.xcodeproj
        ;;
    build)
        generate_project
        xcodebuild \
            -project HRV.xcodeproj \
            -scheme HRV \
            -destination 'generic/platform=iOS Simulator' \
            CODE_SIGNING_ALLOWED=NO \
            build
        ;;
    test)
        swift test
        generate_project
        xcodebuild \
            -project HRV.xcodeproj \
            -scheme HRV \
            -destination 'generic/platform=iOS Simulator' \
            CODE_SIGNING_ALLOWED=NO \
            build
        ;;
    *)
        echo "Usage: $0 [generate|open|build|test]" >&2
        exit 2
        ;;
esac
