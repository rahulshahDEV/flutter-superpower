# App Bootstrap, Flavors, Firebase

## Entry points

```dart
// lib/main_dev.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.dev');
  AppConfig.initialize(flavor: Flavor.dev);
  await app.main(); // lib/app.dart's main
}
```

`main_prod.dart` is identical with `.env.prod` / `Flavor.prod`.

```dart
// lib/app.dart  — real bootstrap
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.isInitialized) {
    await dotenv.load(fileName: '.env.dev');
    AppConfig.initialize(flavor: Flavor.dev);
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await configureDependencies();          // get_it + injectable
  await getIt<FcmService>().initialize(); // after DI, before runApp

  runApp(const App());
}
```

Order is a real pitfall: **dotenv → AppConfig → Firebase → configureDependencies → FCM → runApp**.
Never call `getIt<>()` before DI completes.

## App root widget

```dart
class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Firebase.apps.isEmpty) return;
      try {
        getIt<FcmService>().markAppReady();
      } on Object {
        // best-effort; widget tests build without Firebase
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { /* best-effort syncs */ }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppSizes.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<CurrentUserCubit>()..loadFromStorage()),
          // only genuinely app-wide cubits here
        ],
        child: MaterialApp.router(
          title: AppConfig.instance.appName,
          debugShowCheckedModeBanner: AppConfig.instance.isDev,
          theme: AppTheme.lightTheme,
          // darkTheme + themeMode only if the app actually supports dark mode
          routerConfig: getIt<AppRouter>().router,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.systemUiOverlayStyle,
            child: ConnectivityWrapper(child: child!),
          ),
        ),
      ),
    );
  }
}
```

## AppConfig / FlavorConfig

```dart
enum Flavor { dev, prod }

class AppConfig {
  AppConfig._();
  static AppConfig? _instance;
  static AppConfig get instance => _instance!;
  static bool get isInitialized => _instance != null;

  static void initialize({required Flavor flavor}) {
    _instance = AppConfig._internal(
      flavor: flavor,
      baseUrl: dotenv.env['BASE_URL'] ?? (throw StateError('BASE_URL missing')),
      cdnBaseUrl: dotenv.env['S3_BASE_URL'] ?? '',
      appName: 'MyApp',
    );
  }

  final Flavor flavor;
  final String baseUrl;
  final String cdnBaseUrl;
  final String appName;
  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
}
```

Keep `.env.dev` / `.env.prod` as declared assets, plus a committed `.env.sample`
documenting every key. Secrets (`key.properties`, `google-services.json`,
`GoogleService-Info.plist`, `.env.*`) are gitignored.

## Pubspec starter (minimal baseline)

```yaml
name: my_app
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ^3.6.0

dependencies:
  flutter: {sdk: flutter}
  cupertino_icons: ^1.0.8
  flutter_bloc: ^9.1.1
  get_it: ^8.0.3
  injectable: ^2.5.0
  go_router: ^14.8.0
  dartz: ^0.10.1
  equatable: ^2.0.7
  dio: ^5.8.0+1
  pretty_dio_logger: ^1.4.0
  flutter_dotenv: ^6.0.0
  flutter_screenutil: ^5.9.3
  intl: ^0.20.2
  shared_preferences: ^2.5.3
  flutter_svg: ^2.2.0
  cached_network_image: ^3.4.1
  google_fonts: ^7.0.2
  json_annotation: ^4.9.0
  internet_connection_checker_plus: ^3.0.0
  firebase_core: ^4.6.0
  firebase_messaging: ^16.1.3
  flutter_local_notifications: ^18.0.1

dev_dependencies:
  flutter_test: {sdk: flutter}
  flutter_lints: ^5.0.0
  build_runner: ^2.4.15
  injectable_generator: ^2.7.0
  json_serializable: ^6.9.4

flutter:
  uses-material-design: true
  assets:
    - .env.dev
    - .env.prod
    - assets/images/
    - assets/icons/
```

Add `freezed_annotation`/`freezed` only if the app will use freezed states.
Add per-feature packages (maps, health, video, crypto) when the feature lands — not before.

`analysis_options.yaml`: `include: package:flutter_lints/flutter.yaml` + exclude
`build/**`, `android/**`, `ios/**`. No custom rules; style is enforced by this skill.

## Flavors — Android/iOS checklist

Android (`android/app/build.gradle.kts`):
- `flavorDimensions += "environment"`, `productFlavors { create("dev"); create("prod") }`
- same `applicationId` for both (or `.dev` suffix if both must coexist)
- `resValue("string", "app_name", "MyApp")` per flavor
- `google-services` plugin + Java/Kotlin 17 + core library desugaring

iOS:
- xcconfig chain `Debug-dev/Release-prod` setting `FLUTTER_FLAVOR` + `FLUTTER_TARGET`
- schemes `Dev` / `Prod`; `platform :ios, '15.0'` (or higher per app)

VS Code `.vscode/launch.json`:

```json
{ "name": "Dev",  "type": "dart", "program": "lib/main_dev.dart",  "args": ["--flavor", "dev"] },
{ "name": "Prod", "type": "dart", "program": "lib/main_prod.dart", "args": ["--flavor", "prod"] }
```

Run: `flutter run --flavor dev -t lib/main_dev.dart`.

## Firebase / FCM

Only `firebase_core` + `firebase_messaging` by default. Add analytics/crashlytics only when
requested. FCM wiring:

- `core/services/fcm_background_handler.dart` — top-level `@pragma('vm:entry-point')` fn; re-initializes Firebase in the background isolate; never rethrows.
- `core/services/fcm_service.dart` — `@lazySingleton`; channel (`myapp_notifications`, icon, color), foreground presentation, `onMessage`/`onMessageOpenedApp`/`onTokenRefresh`, persists token via `LocalStorageService`, `markAppReady()` + `consumePendingNotificationRoute()` for cold-start deep links, `@disposeMethod dispose()`.
- `fcm_tap_route_handler.dart` — maps payload data → route path/extra.
- Token registration with backend happens in a feature use case, not inside FcmService.
- iOS: request permission via `FirebaseMessaging.instance.requestPermission()` at the right UX moment (onboarding/notification prompt), not at cold start.

## Verify (run before claiming done)

```bash
dart format .
fdev gen          # if annotations/generated code changed (fallback: dart run build_runner build --delete-conflicting-outputs)
                  # build-hook error on Dart 3.10+? append: --force-jit
flutter analyze
flutter test
fdev apk dev      # or: flutter run --flavor dev -t lib/main_dev.dart (smoke test)
```

Prefer the owner's `fdev` CLI for codegen/builds — full command map in `fdev.md`.
