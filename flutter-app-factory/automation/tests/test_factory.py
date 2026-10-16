"""CLI safety, local plans, identifier isolation, and portable starter export."""
import contextlib
import io
import json
from pathlib import Path
from unittest.mock import patch

from .fixtures import AppFixture
import factory
import model
import operations


class FactoryTests(AppFixture):
    def test_slug_paths_and_symlink_escape_rejected(self):
        for slug in ("../outside", "sample_app/../../outside", "/absolute", "sample-app", "sample_app;true"):
            with self.subTest(slug=slug), self.assertRaises(model.FactoryError):
                model.app_path(self.root, slug)
        outside = self.root.parent / "outside"
        outside.mkdir()
        (self.root / "apps/linked_app").symlink_to(outside, target_is_directory=True)
        with self.assertRaises(model.FactoryError):
            model.app_path(self.root, "linked_app")

    def test_load_app_rejects_directory_config_identity_mismatch(self):
        self.data["app"]["slug"] = "different_app"
        self.save()
        with self.assertRaisesRegex(model.FactoryError, "match its directory"):
            model.load_app(self.root, "sample_app")

    def test_create_cannot_collide_with_another_flavor_id(self):
        # sample_app's flattened suffix is sampleapp; the alternative slug would collide.
        with patch.object(operations, "run") as run:
            with self.assertRaisesRegex(model.FactoryError, "collides"):
                operations.create(self.root, "Sampleapp", "sampleapp", "org.sample")
        run.assert_not_called()
        self.assertFalse((self.root / "apps/sampleapp").exists())

    def test_create_idempotent_preserves_existing_configuration(self):
        before = (self.app / "app.yaml").read_bytes()
        with patch.object(operations, "run") as run:
            result = operations.create(self.root, "Sample Utility", "sample_app", "org.sample")
        self.assertEqual(result["status"], "already_exists")
        self.assertEqual((self.app / "app.yaml").read_bytes(), before)
        run.assert_not_called()
        with self.assertRaisesRegex(model.FactoryError, "preserved"):
            operations.create(self.root, "Different Utility", "sample_app", "org.sample")

    def test_build_plan_runs_no_native_changes_or_tools(self):
        before = {path.relative_to(self.root): path.read_bytes() for path in self.root.rglob("*") if path.is_file()}
        with patch.object(operations.native, "sync") as sync, patch.object(operations.native, "prepare_firebase") as firebase, patch.object(operations, "run") as run:
            result = operations.build(self.root, self.app, self.data, "prod", "android", False)
        self.assertEqual(result["status"], "build_plan")
        self.assertIn("appbundle", result["command"])
        sync.assert_not_called()
        firebase.assert_not_called()
        run.assert_not_called()
        after = {path.relative_to(self.root): path.read_bytes() for path in self.root.rglob("*") if path.is_file()}
        self.assertEqual(before, after)

    def test_remote_build_plan_never_contacts_ci(self):
        args = factory.parser().parse_args(["--root", str(self.root), "ci-trigger", "sample_app", "--platform", "android", "--flavor", "prod"])
        with patch.object(factory.ci, "trigger") as trigger:
            result = factory.execute(args)
        trigger.assert_not_called()
        self.assertFalse(result["paid_build_started"])

    def test_cli_validation_failure_has_nonzero_exit(self):
        self.data["app"]["build_number"] = 0
        self.save()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            code = factory.main(["--root", str(self.root), "validate", "sample_app"])
        self.assertEqual(code, 1)
        self.assertFalse(json.loads(output.getvalue())["ready"])

    def test_cli_path_error_has_useful_safe_message(self):
        errors = io.StringIO()
        with contextlib.redirect_stderr(errors):
            code = factory.main(["--root", str(self.root), "validate", "../outside"])
        self.assertEqual(code, 1)
        self.assertIn("slug", json.loads(errors.getvalue())["error"].lower())

    def test_metadata_exports_official_client_schemas_without_api_calls(self):
        args = factory.parser().parse_args(["--root", str(self.root), "metadata", "sample_app"])
        with patch.object(factory.ci, "trigger") as trigger:
            result = factory.execute(args)
        trigger.assert_not_called()
        out = Path(result["exported_to"])
        self.assertEqual(json.loads((out / "play.json").read_text())["en-US"]["shortDescription"], "A small useful tool.")
        self.assertEqual(json.loads((out / "apple.json").read_text())["en-US"]["keywords"], "utility,tools")
        self.assertFalse(result["remote_metadata_updated"])

    def test_export_excludes_credentials_signing_and_ignored_machine_files(self):
        names = (".env", ".env.production", "android/key.properties", "keys/upload.jks", "keys/ios.p12",
                 "keys/AuthKey_OFFLINE.p8", "keys/ios.mobileprovision", "service-account.json", ".factory/private.json",
                 ".git/config", "apps/sample_app/android/local.properties", "apps/sample_app/ios/Flutter/Generated.xcconfig")
        for name in names:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("offline fixture excluded from export")
        destination = self.root.parent / "exported"
        result = operations.initialize(self.root, destination)
        self.assertEqual(result["status"], "factory_exported")
        self.assertTrue((destination / "apps/sample_app/app.yaml").exists())
        for name in names:
            with self.subTest(name=name):
                self.assertFalse((destination / name).exists(), f"Export leaked {name}")

    def test_export_refuses_existing_or_nested_destination(self):
        for destination in (self.root, self.root / "nested"):
            with self.assertRaises(model.FactoryError):
                operations.initialize(self.root, destination)
