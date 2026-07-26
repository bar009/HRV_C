"""Regression checks for files consumed only by Xcode on macOS."""

from __future__ import annotations

import plistlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SWIFT = ROOT / "swift"


def test_ios_info_plist_is_valid_and_has_required_bundle_metadata() -> None:
    with (SWIFT / "Support" / "Info.plist").open("rb") as stream:
        info = plistlib.load(stream)

    assert info["CFBundleExecutable"] == "$(EXECUTABLE_NAME)"
    assert info["CFBundleIdentifier"] == "$(PRODUCT_BUNDLE_IDENTIFIER)"
    assert info["CFBundlePackageType"] == "APPL"
    assert info["CFBundleShortVersionString"] == "$(MARKETING_VERSION)"
    assert info["CFBundleVersion"] == "$(CURRENT_PROJECT_VERSION)"
    assert info["NSHealthShareUsageDescription"].strip()

    # HealthKit observer wake-ups use the dedicated background-delivery
    # entitlement. Do not claim BGProcessing unless the app schedules BGTasks.
    assert "processing" not in info.get("UIBackgroundModes", [])


def test_healthkit_entitlements_plist_is_valid() -> None:
    with (SWIFT / "Support" / "HRV.entitlements").open("rb") as stream:
        entitlements = plistlib.load(stream)

    assert entitlements["com.apple.developer.healthkit"] is True
    assert entitlements["com.apple.developer.healthkit.background-delivery"] is True


def test_xcodegen_links_the_explicit_hrvcore_product_to_all_app_targets() -> None:
    project_spec = (SWIFT / "project.yml").read_text(encoding="utf-8")

    # HRV, the phone-only test host, and HRVWatch all consume the shared core.
    assert project_spec.count("product: HRVCore") == 3
    assert "PRODUCT_BUNDLE_IDENTIFIER: com.bar009.hrvc" in project_spec
    assert "PRODUCT_BUNDLE_IDENTIFIER: com.bar009.hrvc.watchkitapp" in project_spec
