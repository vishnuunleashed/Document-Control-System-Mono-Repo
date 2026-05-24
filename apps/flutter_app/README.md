# Document Control System — Flutter Client App

This is the client application for the Document Control System. It is structured using **Feature-first Clean Architecture** with **BLoC** state management.

## Setup Instructions

Since terminal actions are restricted inside this container, follow these steps in your local command prompt or terminal:

### 1. Initialize the runner templates
Run `flutter create` to generate the platform-specific files (Android, iOS, Windows, macOS, Web, Linux) using the designated organization:
```bash
flutter create --org com.dcs .
```

### 2. Install dependencies
Run pub get to retrieve and link the required packages:
```bash
flutter pub get
```

### 3. Generate Code
If you are adding models with `freezed` or `json_serializable`, or generating `isar` schemas, execute the build runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Set Environment Variables
Ensure you have a `.env` file at the root of `apps/flutter_app/` (this matches the asset inclusion in `pubspec.yaml`):
```env
API_BASE_URL=http://localhost:5000/api/v1
```

### 5. Run the Application
Execute the app on your emulator or connected device:
```bash
flutter run
```

---

## Architectural Guidelines

The application follows the **Feature-first Clean Architecture**:

- `app/`: Routing definitions, DI registrations, and app-wide configs.
- `core/`: Global widgets, themes, caching implementations (Isar), HTTP interceptors (Dio), and static constants.
- `shared/`: Generic models, interfaces, and shared packages across features.
- `features/`: Isolated business logic and UI folders.
  - Structure inside each feature (e.g. `documents/`):
    - `data/`: Local/remote data sources, DTOs, and concrete repository implementations.
    - `domain/`: Pure Dart entities, use-cases, and repository interfaces.
    - `presentation/`: BLoCs, cubits, screen pages, and feature-specific widgets.
