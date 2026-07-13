# SLE Prep Flutter client

This directory contains the shared Android and web Flutter app. Complete setup,
AI configuration, troubleshooting, broker instructions, and deployment steps
are maintained in the [repository README](../README.md).

Quick verification:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
```
