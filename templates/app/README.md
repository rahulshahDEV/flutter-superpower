# __APP_TITLE__

Flutter app built with the flutter-superpower house style.

## Run

```sh
flutter pub get
flutter run                          # dev config (lib/main.dart)

# flavored (after wiring native flavors — see the skill's app-bootstrap reference):
flutter run --flavor dev -t lib/main_dev.dart
```

## Codegen

```sh
fdev gen                             # or: dart run build_runner build --delete-conflicting-outputs
```

## Structure

```
lib/
├── app.dart            # bootstrap + root widget
├── main.dart           # dev entry
├── main_dev.dart       # flavor entries
├── main_prod.dart
├── core/               # config, constants, error, network, storage, theme, widgets, router
├── di/                 # get_it + injectable
└── features/
    ├── splash/
    └── home/
```

Add a feature:

```sh
<path-to-flutter-superpower>/scripts/new_feature.sh orders
```

## Gate before every commit

```sh
dart format .
fdev gen
flutter analyze
flutter test
```
