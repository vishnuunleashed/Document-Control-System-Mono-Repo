# Document Control System (DCS) Monorepo

Welcome to the Document Control System monorepo. This repository contains the complete stack for a production-ready, offline-first Document Control System designed to manage document lifecycles, approvals, and secure storage.

## Project Structure

This project is organized as a monorepo:

```
project-root/
│
├── apps/
│   ├── flutter_app/      # Cross-platform client (Flutter App)
│   └── admin_web/        # Admin web portal (placeholder)
│
├── backend/
│   ├── api/              # Node.js + Express + TypeScript backend API
│   └── workers/          # Background workers (placeholder)
│
├── packages/             # Shared typescript/dart libraries
│   ├── shared_models/    # Shared schema and data contracts
│   ├── shared_constants/ # Shared status codes, roles, and boundaries
│   └── shared_utils/     # Common helpers
│
├── docs/                 # Architectural plans, UMLs, and roadmaps
└── README.md             # This file
```

## Technology Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: BLoC / Cubit
- **Architecture**: Feature-first Clean Architecture
- **Local Cache**: Isar Database (Offline-first support)
- **Routing**: GoRouter
- **HTTP Client**: Dio

### Backend
- **Runtime**: Node.js + TypeScript
- **Framework**: Express.js
- **Architecture**: Feature-first Clean Architecture
- **Database**: MongoDB Atlas (metadata storage only)
- **Object Storage**: Cloudflare R2 (S3-compatible bucket)
- **Validation**: Zod
- **Auth**: JSON Web Tokens (JWT) & bcrypt

---

## Getting Started

Because terminal execution is restricted inside our sandbox environment, please use your local terminal to run the following initialization commands:

### 1. Backend Setup

Navigate to the `backend/api/` directory:
```bash
cd backend/api
npm install
```

Configure your environment variables:
Create a `.env` file in `backend/api/` based on `backend/api/.env.example`:
```env
PORT=5000
MONGO_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/dcs
JWT_SECRET=your_jwt_secret_key
R2_ENDPOINT=https://65664a68602fa3aeaf1afbc93cd574f3.r2.cloudflarestorage.com
R2_ACCESS_KEY=your_access_key_id
R2_SECRET_KEY=your_secret_access_key
R2_BUCKET_NAME=dcs-files
```

Start the API server in development mode:
```bash
npm run dev
```

### 2. Flutter App Setup

Since this environment has created the Dart files and configurations in a clean folder structure, you need to generate the platform-specific project runner files (Android, iOS, Windows, macOS, Web):

Navigate to `apps/flutter_app/` and run:
```bash
cd apps/flutter_app
flutter create --org com.dcs .
flutter pub get
```

Then, configure your local environment variables in `apps/flutter_app/.env` (using `.env.example` as a template):
```env
API_BASE_URL=http://localhost:5000/api/v1
```

Run the application:
```bash
# Run on connected device/emulator
flutter run
```

---

## Architecture Design Decisions

1. **Clean Architecture Separation**: We separate the codebase into `core`, `features`, and `shared` modules.
2. **Metadata vs Binaries**: MongoDB stores document metadata (titles, versions, approval states, owners, paths) while Cloudflare R2 stores the raw files (PDFs, DOCX, PNG, JPG under 5MB).
3. **Offline-first with Isar**: Local data caching and queuing mechanism are built into the data layer, syncing back to the backend once an active internet connection is detected.
