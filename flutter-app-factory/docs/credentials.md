# Credential setup checklist

Application identifiers, AdMob IDs, and Firebase client configuration identify apps;
they are not authorization secrets. Signing keys, access tokens, passwords, private API
keys, and Google service credentials are secrets. Keep them outside Git and release
artifacts. Firebase client configuration still needs appropriate security rules and API
restrictions. Do not place private credentials in Dart defines; compiled apps expose them.

## Local automation

Create a project virtual environment and install `automation/requirements.txt`. These
clients load optional authentication libraries only for an authorized external operation
or a status query. Local artifact/metadata plans work without store credentials.

| Integration | Secure input | Initial action |
| --- | --- | --- |
| Codemagic API | `CODEMAGIC_API_TOKEN` | Create a token and connect the monorepo once |
| Google Play | `GOOGLE_APPLICATION_CREDENTIALS` | Point to a protected, temporary JSON credential file; enable API and grant app/track access |
| Apple REST and upload | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_PATH` | Generate/download a team API key once and store the `.p8` in secure storage |
| Apple multi-provider upload | Optional `--provider-id` | Confirm correct App Store Connect provider |
| AAB validation | `BUNDLETOOL_JAR` | Install a verified official bundletool JAR; this is a tool path, not a secret |
| Firebase CLI | Supported CLI login/ADC | Authenticate outside source control and select separate dev/prod projects |

Google authentication uses the Android Publisher scope with Application Default
Credentials and refreshes in memory. Prefer short-lived federation/ADC where the execution
environment supports it. Keep service-account access scoped to the apps and tracks needed.
[Google API access setup](https://developers.google.com/android-publisher/getting_started)

Apple REST tokens use ES256 and expire after ten minutes; private material and JWTs are
never printed or written to the receipt. The uploader supports team keys, copies the key
to a mode-0600 file in a private temporary directory for altool, then deletes that directory.
Normal process termination cleans it up; a hard system kill may require secure temporary
file cleanup by the host. Revoke compromised keys immediately.
[Apple JWT authentication](https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests)

Do not paste real credentials into examples, terminal command arguments, screenshots,
agent prompts, logs, issue bodies, or commit messages. Use the password manager, host
secret injection, or CI encrypted variables. Shell tracing (`set -x`) must remain disabled
while handling secrets. Never print an entire environment to debug authentication.

## Codemagic setup

1. Connect the GitHub repository and restrict who can start release workflows.
2. Create environment variable groups per app and environment. Match the group references
   in configuration exactly; review group visibility and account permissions.
3. Upload each Android upload keystore and configure the matching signing reference.
   Keep keystore password, alias, and private-key password in secure settings.
4. Configure an App Store Connect integration and the required distribution signing
   certificates/profiles, or supported automatic signing using that integration.
5. Provide the Play publishing credential via an encrypted variable referenced by the
   generated workflow. The raw JSON value is a secret; do not write it to repository files.
6. If invoking the direct Play client, materialize a temporary protected JSON file outside
   checkout and set `GOOGLE_APPLICATION_CREDENTIALS`; remove it when the job exits.
7. If invoking the direct Apple client, inject a protected `.p8` file and set the three ASC
   variables. Never include private signing inputs in the artifact glob.
8. Firebase client files may be injected by environment. Firebase service-account JSON is
   private and must never be committed or packaged into an application.

Generated configuration references secret names, signing references, and integration
names only. Confirm names and ownership in Codemagic before authorizing the first paid
build. Signing permissions do not imply permission to publish production.

## Authorization and operational ownership

| Task | Automation boundary |
| --- | --- |
| Scaffold, flavor edits, local tests, metadata/artifact plans | Fully local automation |
| Store accounts, legal agreements, first Play setup, Apple app record, signing keys | Initial manual setup |
| API status queries | Read-only after credentials are configured |
| CI build or test-track upload | Requires task authorization; builds may incur charges |
| Production submission or rollout | Explicit approval of the concrete app/version/target every release |
| Store review, policy forms, identity checks, CAPTCHA | Human-owned; never bypass |

Private `.factory/releases/` receipts store app IDs, artifact hashes, build versions, and
request phases. They do not store keys or tokens. Keep them out of Git and retain them
with controlled release logs so a resumed agent can reconcile uncertain operations.
An approval flag must reflect an actual authorization in the conversation or release
process. An agent must not infer approval from a saved flag or an earlier app's release.

Before enabling release access, run the offline publishing tests and credential scanning,
confirm the configured app identifiers match the store records, test least privilege on
internal/TestFlight targets, and establish key rotation/revocation ownership. Never run
an upload just to test whether a credential works; use the read-only status APIs.
