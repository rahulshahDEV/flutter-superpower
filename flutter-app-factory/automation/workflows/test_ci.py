"""Offline regression checks for CI isolation, release safety, and API handling."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

import yaml

from . import ci


def fixture(slug="sample_app"):
    return {
        "app": {"slug": slug, "name": "Sample App", "version": "1.2.0", "build_number": 7},
        "android": {"application_id": "org.example.sample", "signing_reference": "sample_android"},
        "ios": {"bundle_id": "org.example.sample"},
        "flavors": {"dev": {"ios_bundle_id": "org.example.sample.dev"}, "prod": {"ios_bundle_id": "org.example.sample"}},
        "platforms": {"android": True, "ios": True},
        "deployment": {"environment_group": "sample_prod", "app_store_connect_integration": "sample_apple", "notification_emails": ["builds@example.org"]},
    }


class GeneratorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.addCleanup(self.temp.cleanup)

    def add_app(self, slug):
        path = self.root / "apps" / slug / "app.yaml"
        path.parent.mkdir(parents=True)
        path.write_text(yaml.safe_dump(fixture(slug)))

    def test_app_platform_flavor_isolation_and_distribution(self):
        self.add_app("sample_app")
        self.add_app("other_app")
        target = ci.generate(self.root)
        content = target.read_text()
        workflows = yaml.safe_load(content)["workflows"]
        self.assertEqual(len(workflows), 12)
        self.assertEqual(ci.generate(self.root).read_text(), content)
        for key, workflow in workflows.items():
            self.assertNotIn("triggering", workflow, "Builds require explicit authorization")
            self.assertIn("packages/", workflow["when"]["changeset"]["includes"])
            app_slug = key.split("-")[0]
            self.assertIn(f"apps/{app_slug}/", workflow["when"]["changeset"]["includes"])
            self.assertFalse(workflow.get("publishing", {}).get("app_store_connect", {}).get("submit_to_app_store", False))
            self.assertNotEqual(workflow.get("publishing", {}).get("google_play", {}).get("track"), "production")
            if key.endswith("-build"):
                self.assertNotIn("google_play", workflow.get("publishing", {}))
                self.assertNotIn("app_store_connect", workflow.get("publishing", {}))
        self.assertEqual(workflows["sample_app-dev-android-build"]["environment"]["groups"], ["sample_app_dev"])
        android = workflows["sample_app-prod-android-internal"]
        self.assertEqual(android["environment"]["android_signing"], ["sample_android"])
        self.assertEqual(android["publishing"]["google_play"]["track"], "internal")
        self.assertTrue(any("--release --platform android" in step["script"] for step in android["scripts"]))
        ios = workflows["sample_app-prod-ios-testflight"]
        self.assertEqual(ios["environment"]["ios_signing"]["bundle_identifier"], "org.example.sample")
        self.assertTrue(ios["publishing"]["app_store_connect"]["submit_to_testflight"])
        self.assertTrue(any("--build-number=7" in step["script"] for step in ios["scripts"]))

    def test_handwritten_yaml_and_unsafe_config_are_rejected(self):
        self.add_app("sample_app")
        (self.root / "codemagic.yaml").write_text("workflows: {}\n")
        with self.assertRaisesRegex(ValueError, "handwritten"):
            ci.generate(self.root)
        config = fixture()
        config["app"]["version"] = "1.0.0; echo bad"
        with self.assertRaisesRegex(ValueError, "version"):
            ci._workflow(config, "prod", "android", False)


class ApiTests(unittest.TestCase):
    @patch.object(ci, "_request")
    def test_trigger_only_confirms_accepted_build(self, request):
        request.return_value = {"buildId": "build123", "token": "must never return"}
        result = ci.trigger("secret", "app123", "sample_app-prod-android-internal", "main")
        self.assertEqual(result["build_id"], "build123")
        self.assertFalse(result["deployment_confirmed"])
        self.assertNotIn("token", result)
        request.assert_called_once_with("secret", "https://api.codemagic.io/builds", {"appId": "app123", "workflowId": "sample_app-prod-android-internal", "branch": "main"})
        with self.assertRaises(ValueError):
            ci.trigger("secret", "app123", "sample_app-production", "main")

    @patch.object(ci, "_request")
    def test_finished_is_build_success_without_store_confirmation(self, request):
        request.return_value = {"data": {"status": "finished", "environment": {"secret": "redact"}}}
        result = ci.status("secret", "build123")
        self.assertTrue(result["build_succeeded"])
        self.assertTrue(result["terminal"])
        self.assertFalse(result["deployment_confirmed"])
        self.assertNotIn("environment", result)
        request.assert_called_once_with("secret", "https://codemagic.io/api/v3/builds/build123")

    @patch.object(ci, "build_opener")
    def test_http_errors_do_not_expose_credentials(self, opener):
        opener.return_value.open.side_effect = HTTPError("https://codemagic.io", 403, "secret response", {}, None)
        with self.assertRaisesRegex(RuntimeError, "HTTP 403") as error:
            ci._request("private-token", "https://api.codemagic.io/builds")
        self.assertNotIn("private-token", str(error.exception))
        self.assertNotIn("secret response", str(error.exception))


if __name__ == "__main__":
    unittest.main()
