# CampusAR — Tongmyong University Campus Navigator

An offline-first campus navigation app with a foundation for AR
navigation, built as a V1 MVP for Tongmyong University (Busan, South
Korea). The architecture is deliberately university-agnostic: another
campus can be supported later by replacing data files, not by rewriting
the app.

> **Sample data notice:** all building names, coordinates, facilities, and
> routes bundled with this project are a **fictional, illustrative
> dataset** — not verified Tongmyong University information. Every sample
> file is marked with a `_comment` field saying so. See
> ["How to Replace Campus Data"](#how-to-replace-campus-data) below.

---

## Project overview

CampusAR lets a student:

1. Open the app and see the campus.
2. Search for a building (by name, number, short name, or facility).
3. View building details (floors, facilities, accessibility).
4. See their current location on the campus map.
5. Get a calculated walking route to a building, with live distance/ETA.
6. Enter an AR navigation mode (camera + directional indicator).
7. Do all of the above — except live turn-by-turn GPS tracking, which
   inherently needs a live GPS fix — with **no internet connection**.

## Features

- Offline-first: campus data ships bundled in the app and is loaded into a
  local SQLite database on first launch. Search, building details, and
  route calculation all work with the device in airplane mode.
- A* pedestrian routing over a campus path graph, computed **on-device**
  in Dart and mirrored **server-side** in Python — both implementations
  use the same algorithm and edge weights, so they agree.
- Honest AR: the AR screen combines GPS + device compass to show an
  *approximate* direction and distance to a destination. It does not claim
  centimeter-accurate positioning, and the code is structured so a future
  ARCore/ARKit/VPS/beacon-based implementation can be swapped in later
  (see [AR architecture](#ar-architecture)).
- Graceful degradation everywhere: no GPS, no camera, no internet, no
  route found — every failure path has a mapped, user-friendly message
  (see `backend/app/services` / `mobile/lib/core/errors`). The app never
  crashes because a sensor or network call is unavailable.

## Architecture

Two independently runnable pieces:

```
campusar/
├── backend/     FastAPI + PostgreSQL REST API (optional sync source)
├── mobile/      Flutter app (the actual product — works with no backend)
├── data/        Canonical sample campus dataset (source of truth,
│                copied into both backend/ and mobile/ at build time)
└── docker-compose.yml
```

The mobile app is offline-first by design: the backend exists only so a
future admin panel / sync pipeline has somewhere to publish updated
campus data to. **The app is fully functional with the backend never
running.**

### Backend structure

```
backend/app/
├── main.py                 FastAPI app + startup seeding
├── core/                   config, geo math (haversine, bearing)
├── database/               SQLAlchemy engine/session, seed loader
├── models/                 SQLAlchemy ORM models
├── schemas/                Pydantic request/response schemas
├── repositories/            DB access layer (campus/building/route)
├── services/routing_service.py   A* pathfinding, framework-free
└── api/routes/              health, campus, buildings, routes endpoints
backend/alembic/             Migrations
backend/tests/               pytest unit + API integration tests
```

### Mobile structure

```
mobile/lib/
├── core/            constants, theme, geo utilities, location service, errors
├── data/
│   ├── models/       Campus, Building, Entrance, Facility, RouteNode/Edge
│   ├── local/        SQLite schema + bundled-JSON seed loader
│   ├── remote/       optional backend sync client
│   └── repositories/ offline-first data access (search, nearby, etc.)
├── features/
│   ├── campus/       Home screen, Campus Map screen
│   ├── buildings/    Search, Detail screens
│   ├── navigation/   A* routing service (Dart), live navigation screen
│   ├── ar/           AR guidance abstraction + AR navigation screen
│   └── settings/     Theme, permission/offline status, about
└── shared/           reusable widgets (BuildingCard, ErrorView, LoadingView)
```

## Technology stack

| Layer | Choice |
|---|---|
| Mobile | Flutter (Dart), Riverpod for state management |
| Local storage | SQLite via `sqflite` |
| Maps | `flutter_map` (OpenStreetMap tiles — no Google Maps billing) |
| Backend | Python + FastAPI |
| Database | PostgreSQL (SQLite fallback for zero-config local dev) |
| API | REST, versioned under `/api/v1` |
| Routing | A* over a campus pedestrian graph (ported identically to Dart and Python) |
| AR | GPS + compass heading V1, behind an `ArNavigationService` interface |

---

## Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22+ (Dart 3.3+)
- Python 3.11+
- Docker + Docker Compose (optional, for PostgreSQL + backend)
- Android Studio (Android SDK/emulator) and/or Xcode (iOS, macOS only)

### Flutter setup

This repo ships `mobile/lib`, `mobile/assets`, and `mobile/pubspec.yaml`,
but **not** the native `android/` and `ios/` platform folders — those are
machine-specific and are meant to be generated by the Flutter tool itself,
not hand-written:

```bash
cd mobile
flutter create . --platforms=android,ios --org com.campusar --project-name campusar
flutter pub get
```

This creates `android/` and `ios/` without touching your existing
`lib/`, `assets/`, or `pubspec.yaml` (answer "yes" if it asks to
overwrite `pubspec.yaml`'s boilerplate name/description — the
dependencies section you already have will be preserved by re-running
`flutter pub get` afterward if needed; safest is to diff before
overwriting).

Then apply the permission snippets:

- Merge `mobile/android_manifest_snippets/README.md`'s XML into
  `android/app/src/main/AndroidManifest.xml`.
- Merge `mobile/ios_snippets/README.md`'s XML into `ios/Runner/Info.plist`.

### Android setup

```bash
flutter devices          # confirm your emulator/device is listed
flutter run -d <device-id>
```

Minimum SDK 21 (see `android_manifest_snippets/README.md`). Test on a
**physical device** first — this project was built with a real Android
phone as the primary test target, per the product brief.

### iOS setup (macOS only)

```bash
cd ios && pod install && cd ..
flutter run -d <ios-device-or-simulator-id>
```

AR navigation needs a physical device (simulators have no camera).

### Backend setup

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # edit DATABASE_URL if using Postgres
python3 -m alembic upgrade head
python3 -m uvicorn app.main:app --reload
```

Visit `http://127.0.0.1:8000/docs` for interactive API docs. On first
startup the backend seeds itself from `backend/app/data/seed/*.json`.

### PostgreSQL setup

Either run Postgres yourself and point `DATABASE_URL` at it, or use the
bundled Compose file:

```bash
docker compose up -d db          # starts just Postgres
# or, to run backend + Postgres together:
docker compose up --build
```

Default `docker-compose.yml` credentials: user/password/db all `campusar`,
matching `.env.example`.

### Running locally

- **Mobile only, fully offline:** `flutter run` — the app seeds itself
  from bundled assets; no backend needed.
- **Mobile + backend sync:** start the backend (above), then run Flutter
  with the platform-correct base URL:
  ```bash
  # Android emulator (10.0.2.2 = host machine, NOT 127.0.0.1):
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  # iOS simulator:
  flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
  # Physical device (same Wi-Fi as your dev machine):
  flutter run --dart-define=API_BASE_URL=http://<your-lan-ip>:8000
  ```

### Running tests

```bash
# Backend
cd backend && python3 -m pytest -q

# Mobile
cd mobile && flutter test
```

---

## Offline architecture

```
First launch
  → CampusDataLoader reads assets/data/*.json
  → Writes into local SQLite (AppDatabase)
  → All screens read from SQLite from then on

Later, if online
  → CampusRepository.checkForUpdates() compares local vs.
    GET /api/v1/campus/version
  → (extension point) re-fetch + re-seed only if the backend has a
    strictly newer version — never blocks the UI, never required
```

Search, building details, distance/nearby calculations, and route
calculation all read exclusively from the local database — none of them
call the network. The backend and its sync endpoint exist purely as an
optional "keep the bundled dataset fresh" mechanism for a future admin
panel to push into.

## AR architecture

`ArNavigationService` (`mobile/lib/features/ar/services/ar_navigation_service.dart`)
is an abstract interface. The V1 implementation,
`GpsCompassArNavigationService`, combines:

- GPS position (via `geolocator`)
- Device compass heading (via `flutter_compass`)

to compute a *relative bearing* to the destination, which drives a
directional arrow overlaid on the live camera feed
(`camera` package). This is explicitly **not** claimed to be
centimeter-accurate: consumer GPS is typically accurate to ~3–8m outdoors
(worse near buildings), and phone magnetometers drift, especially indoors
or near metal/electronics. The AR screen surfaces this honestly (a
"compass reading is unreliable" hint appears when heading data looks
untrustworthy).

The interface is the seam for future, more accurate positioning:

- ARCore Geospatial API / ARKit Geo-anchors (VPS-based)
- Visual anchors placed at building entrances
- QR-code markers at fixed campus locations
- BLE beacons for indoor micro-positioning

Any of these can implement `ArNavigationService` (or an extended version
of it) and be swapped in via the `arNavigationServiceProvider` Riverpod
provider, with zero changes to the AR screen's UI code.

## Campus data structure

Five JSON files, kept identical between `backend/app/data/seed/` and
`mobile/assets/data/`:

| File | Contents |
|---|---|
| `campus.json` | One campus: name, university, coordinates, map bounds/zoom |
| `buildings.json` | Buildings: id, number, name, floors, facility/entrance ids, accessibility |
| `entrances.json` | Physical entrance points per building |
| `facilities.json` | Facility rows (classrooms, restrooms, etc.), one row per facility per building |
| `routes.json` | The pedestrian graph: `nodes` (pathway/intersection/entrance/destination) and `edges` (distance, accessible/indoor/outdoor flags) |

Every building has a `destinationNodeId` (the routable point representing
"arrived") and an `entranceNodeId` (the point where the outdoor path
network connects to the building), so the routing engine never needs a
separate lookup step.

## How to Replace Campus Data

1. Replace the five files under `data/` (the canonical source) with
   verified Tongmyong University data, keeping the exact same JSON shape.
   Use a real GPS survey, campus facilities maps, or official building
   coordinates — the current values are synthetic placeholders centered
   near Tongmyong's real Busan location but **not surveyed**.
2. Run `cp data/*.json backend/app/data/seed/` and
   `cp data/*.json mobile/assets/data/` to sync both copies (or wire up a
   small build script / symlink if you prefer never to let them drift).
3. Backend: delete any existing dev database (or bump `CAMPUS_DATA_VERSION`
   in `.env`) and re-run `alembic upgrade head` — the app auto-seeds an
   empty database on startup.
4. Mobile: bump `campus.json`'s `"version"` field; on next install (or by
   calling `CampusDataLoader.loadBundledDataIfNeeded(force: true)`) the app
   re-seeds from the new bundled assets.
5. Building images: drop files into `mobile/assets/images/buildings/` and
   update each building's `"image"` field in `buildings.json` to match; add
   the new paths to `pubspec.yaml`'s `flutter: assets:` list.
6. Regenerate the route graph (`routes.json`) to match real campus
   pathways — the included generator script's approach (grid of
   intersection nodes + one entrance/destination node pair per building)
   is a reasonable starting structure to hand-edit or re-run against real
   surveyed points.

## How to add another university

Nothing in `lib/`, `app/`, or the database schema is Tongmyong-specific —
only the *data* is. To add a second campus:

1. Create a new set of the five JSON files for the new campus (own `id`,
   coordinates, buildings, etc.).
2. Either (a) swap the bundled files entirely for a single-campus build per
   university, or (b) extend `campus_id` filtering (already present on
   `Building`, and in the backend's `BuildingRepository.list_all`) to
   support multiple campuses in one build with a campus switcher — the
   schema already keys every table off `campus_id` in anticipation of this.
3. Update `AppConstants.appSubtitle` / branding assets for the new
   university if shipping as a separate app.

## Known limitations

- **AR positioning is GPS + compass only.** No VPS, markers, or beacons in
  V1 — see [AR architecture](#ar-architecture).
- **Sample data is fictional.** Coordinates are illustrative, not
  surveyed; see the notice at the top of this file.
- **No turn-by-turn indoor navigation.** The routing graph only models
  outdoor pathways plus a single entrance/destination node per building;
  it does not route between floors or rooms.
- **"Next direction" is always "Continue straight"** in V1 until arrival —
  the graph doesn't yet encode turn geometry needed for "turn left/right"
  instructions. This is honest rather than fabricated; extending
  `RouteNode`/`RouteEdge` with bearing data is the natural next step.
- **No authentication/accounts**, by design (section 19 of the product
  brief: "Do not over-engineer authentication").
- **No admin dashboard.** The backend schema anticipates one (see
  `backend/app/` `TODO`-style notes in `seed.py`), but building it is out
  of scope for V1.
- Backend defaults to a local SQLite file if `DATABASE_URL` isn't set —
  fine for development, but use PostgreSQL (`docker-compose.yml`) for
  anything beyond a single developer's machine.

## Future roadmap

- Admin panel for managing buildings/routes/facilities without editing
  JSON by hand (backend schema is already structured to support this).
- Turn-by-turn instructions using edge bearing/geometry, not just distance.
- ARCore Geospatial API / ARKit geo-anchors for meter-or-better outdoor AR
  accuracy, and BLE beacons or QR markers for indoor micro-positioning.
- Multi-campus support in a single build with a campus switcher.
- Real-time crowding/closure data feeding into route weights.
- Push notifications for campus data updates.

---

## Docker / networking notes for local development

`docker-compose.yml` (project root) starts PostgreSQL + the backend
together. Key gotcha for connecting the *mobile app* to a *locally run*
backend during development — **the emulator/simulator does not see your
machine as `127.0.0.1`**:

| Target | Backend URL from the app |
|---|---|
| Android **emulator** | `http://10.0.2.2:8000` |
| iOS **simulator** | `http://127.0.0.1:8000` |
| Physical Android/iOS **device** | `http://<your-machine's-LAN-IP>:8000`, same Wi-Fi network, host firewall allowing incoming :8000 |

Pass the right one via `--dart-define=API_BASE_URL=...` as shown above in
["Running locally"](#running-locally). None of this matters for using the
app itself — it only affects the optional background sync check.

## Environment configuration

- Backend: copy `backend/.env.example` to `backend/.env` and edit.
  **Never commit `.env`.**
- Mobile: no secrets to manage in V1 (no API keys required — OpenStreetMap
  tiles and the local backend need none). Runtime config
  (`API_BASE_URL`) is passed via `--dart-define`, not files, so there's
  nothing to accidentally commit.
- `.gitignore` at the project root excludes `.env`, build artifacts,
  `*.db`, and native platform build output for both projects.
