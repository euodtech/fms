# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

E-FMS (Electronic Fleet Management System) — a Flutter mobile app for fleet management with real-time vehicle tracking, job management, and role-based access control. Package name: `com.querta.fms`.

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run on device/emulator (default BASE_URL is local dev server)
flutter run

# Run with custom API base URL
flutter run --dart-define=BASE_URL=http://your-server/myapi

# Build APK
flutter build apk --dart-define=BASE_URL=http://production-server/myapi

# Regenerate app icons after changing assets/images/logo.jpg
dart run flutter_launcher_icons

# Run tests (minimal coverage — single widget_test.dart)
flutter test
```

The `BASE_URL` is configured via `--dart-define` and defaults to `http://192.168.254.110:8000/myapi` in `lib/core/constants/variables.dart`.

## Architecture

**Clean Architecture + MVVM with GetX** for state management, routing, and dependency injection.

### Layer Structure

```
lib/
├── core/           # Shared infrastructure (network, theme, widgets, services, constants)
├── data/           # Datasources (API calls) and models (response/data)
├── page/           # Features: auth, home, jobs, profile, vehicles
├── main.dart       # Entry point — Firebase init, AuthController registration, RootGate
└── nav_bar.dart    # Bottom navigation with role-based tab configuration
```

### Feature Module Pattern

Each feature under `page/` follows:
```
page/<feature>/
├── controller/      # GetxController with reactive state (Rx variables)
├── presentation/    # Screen widgets
└── widget/          # Feature-specific components
```

### Key Architectural Decisions

- **API Client (`core/network/api_client.dart`)**: Wraps `http` with company subscription validation before every request. If subscription type mismatches, auto-logs out the user. Auth endpoints bypass this wrapper and call `http` directly.
- **Dual API integration**: E-FMS backend (jobs, auth, profiles) + Traxroot API (vehicle tracking, geozones). Traxroot tokens are cached with 5-minute expiry in SharedPreferences.
- **Auth flow**: `main.dart` → `RootGate` observes `AuthController.isAuthenticated` → routes to `LoginPage` or `NavBar`.
- **Role-based navigation**: `NavigationController.configureTabs()` shows/hides tabs (Dashboard, Vehicles, Jobs) based on subscription plan (pro/non-pro) and user role (basic, monitor, field).
- **Persistent state**: SharedPreferences stores API key, user role, company info, company logo URL, Traxroot tokens. `SecureStorage` wrapper switches between `FlutterSecureStorage` (release) and `SharedPreferences` (debug).

### Data Flow

1. Datasource (e.g., `GetJobDatasource`) makes HTTP call via `ApiClient`
2. Response parsed into model (e.g., `GetJobResponseModel.fromJson()`)
3. Controller stores result in reactive variables (`RxList`, `RxBool`, etc.)
4. UI rebuilds via `Obx()` widgets

### API Response Models

Models handle multiple field name conventions (snake_case, camelCase, PascalCase) from the backend — when accessing response fields, check existing models for the pattern used.

### Navigation

- `GetMaterialApp` for root routing
- `Get.to()` / `Get.offAll()` for screen navigation
- Bottom `NavigationBar` with `IndexedStack` for tab persistence
- Back button on home tab triggers exit confirmation dialog

## Constants & Configuration

All API endpoints, SharedPreferences keys, and base URLs are centralized in `lib/core/constants/variables.dart`. Add new endpoints and pref keys there.
