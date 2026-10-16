"""Small, isolated app fixtures using the same shipped configuration schema."""
from __future__ import annotations

import copy
from pathlib import Path
import plistlib
import struct
import sys
import tempfile
import unittest

FACTORY_ROOT = Path(__file__).resolve().parents[2]
for directory in (FACTORY_ROOT / "automation", FACTORY_ROOT / "automation/scripts"):
    if str(directory) not in sys.path:
        sys.path.insert(0, str(directory))

from model import read_yaml, write_yaml


def substitute(value, replacements):
    if isinstance(value, dict):
        return {key: substitute(item, replacements) for key, item in value.items()}
    if isinstance(value, list):
        return [substitute(item, replacements) for item in value]
    if isinstance(value, str):
        for old, new in replacements.items():
            value = value.replace(old, new)
    return value


class AppFixture(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="factory-offline-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / "factory"
        self.root.mkdir()
        self.app = self.root / "apps/sample_app"
        self.app.mkdir(parents=True)
        data = read_yaml(FACTORY_ROOT / "templates/app_config/app.yaml")
        self.data = substitute(data, {"__APP_TITLE__": "Sample Utility", "__APP_NAME__": "sample_app",
                                      "__ORG__": "org.sample", "__APP_ID__": "sampleapp"})
        self.data["ios"]["team_id"] = "ABCDEFGHIJ"
        self.data["privacy"].update(policy_url="https://apps.sample.org/privacy", store_declarations_reviewed=True)
        self.data["assets"]["reviewed"] = True
        self.data["deployment"].update(codemagic_app_id="configured_app", app_store_connect_integration="configured_apple",
                                         apple_app_id="1234567890")
        self.store = read_yaml(FACTORY_ROOT / "templates/store_metadata/en-US.yaml")
        self.store["android"].update(title="Sample Utility", short_description="A small useful tool.",
                                     full_description="Describes the actual tool.", release_notes="Improves reliability.")
        self.store["ios"].update(name="Sample Utility", description="Describes the actual tool.",
                                 release_notes="Improves reliability.", support_url="https://apps.sample.org/support",
                                 keywords="utility,tools")
        self.store["screenshots"] = {"android": ["store/android.png"], "ios": ["store/ios.png"]}
        self.save()
        write_yaml(self.app / "pubspec.yaml", {"name": "sample_app", "version": "1.0.0+1"})
        write_yaml(self.root / "factory.yaml", {"schema_version": 1, "apps": ["sample_app"]})
        for package in ("core", "ui_kit", "analytics", "ads", "networking", "app_config"):
            write_yaml(self.root / "packages" / package / "pubspec.yaml", {"name": package})
        gradle = self.app / "android/app/build.gradle.kts"
        gradle.parent.mkdir(parents=True)
        gradle.write_text('\n'.join(f'create("{flavor}") {{ applicationId = "{self.data["flavors"][flavor]["android_application_id"]}" }}'
                                   for flavor in ("dev", "prod")))
        manifest = self.app / "android/app/src/main/AndroidManifest.xml"
        manifest.parent.mkdir(parents=True)
        manifest.write_text("<manifest/>")
        pbx = self.app / "ios/Runner.xcodeproj/project.pbxproj"
        pbx.parent.mkdir(parents=True)
        pbx.write_text('\n'.join(f'Release-{flavor} {self.data["flavors"][flavor]["ios_bundle_id"]}' for flavor in ("dev", "prod")))
        for flavor in ("dev", "prod"):
            scheme = pbx.parent / f"xcshareddata/xcschemes/{flavor}.xcscheme"
            scheme.parent.mkdir(parents=True, exist_ok=True)
            scheme.write_text("<Scheme/>")
        info = self.app / "ios/Runner/Info.plist"
        info.parent.mkdir(parents=True)
        info.write_bytes(plistlib.dumps({}))
        icon = self.app / self.data["assets"]["icon"]
        icon.parent.mkdir(parents=True)
        # The dimension checker consumes the PNG signature and IHDR dimensions only.
        icon.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\0" * 8 + struct.pack(">II", 1024, 1024))
        for platform in ("android", "ios"):
            (self.app / f"store/{platform}.png").write_bytes(b"offline screenshot fixture")
        # The export allowlist under test: every maintained starter file is listed,
        # so credential/machine files written by the test stay excluded.
        manifest_entries = [
            "factory.yaml",
            "apps/sample_app/app.yaml",
            "apps/sample_app/store/en-US.yaml",
            "apps/sample_app/pubspec.yaml",
            "apps/sample_app/android/app/build.gradle.kts",
            "apps/sample_app/android/app/src/main/AndroidManifest.xml",
            "apps/sample_app/ios/Runner.xcodeproj/project.pbxproj",
            "apps/sample_app/ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme",
            "apps/sample_app/ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme",
            "apps/sample_app/ios/Runner/Info.plist",
            f"apps/sample_app/{self.data['assets']['icon']}",
            "apps/sample_app/store/android.png",
            "apps/sample_app/store/ios.png",
            *["packages/" + package + "/pubspec.yaml" for package in ("core", "ui_kit", "analytics", "ads", "networking", "app_config")],
        ]
        manifest_path = self.root / "automation/export-manifest.txt"
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text("\n".join(manifest_entries) + "\n")

    def save(self):
        write_yaml(self.app / "app.yaml", self.data)
        write_yaml(self.app / "store/en-US.yaml", self.store)

    def add_app(self, slug="other_app"):
        other = copy.deepcopy(self.data)
        other["app"]["slug"] = slug
        other["app"]["name"] = "Other Utility"
        write_yaml(self.root / "apps" / slug / "app.yaml", other)
        write_yaml(self.root / "factory.yaml", {"schema_version": 1, "apps": ["sample_app", slug]})
        return other
