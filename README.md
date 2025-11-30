# Colours of Wine 🍷

PR Software Praktikum WS 2025/26

Sofia Zauner, Peter Balint

---

"Colours of Wine" is a Flutter application that transforms a wine’s taste profile into a visually expressive, AI-generated image.
Users can either scan wine labels or provide details manually. Based on this information, the app produces:
* a structured and well-defined wine profile
* an AI-generated visual representation of the wine’s flavour characteristics
* curated web-based descriptions and an automatically generated summary
* a searchable history of all scans tied to the user’s account

The goal is to provide an intuitive, visually driven interpretation of a wine’s flavour — turning aroma, body, and character into a unique, colour- and shape-based “fingerprint.”

## Architecture

lib/
  config/                                → Environment configuration (API Base URL)
  models/                                → Data models (WineData, exceptions, ...)
  services/                              → HTTP + backend communication
  features/                              → central controller for the app state
    descriptions.dart
    login.dart
    orchestrator.dart
    previous_searches.dart
    winedata_registration_camera.dart
    winedata_registration_manual.dart
  views/                       → UI components (start, result, history, ...)
  utils/                       → reusable helpers (ErrorMessages, AppConstants)

---

UI (Widgets/Views)
        │
        ▼
Feature-Logic (Extensions: descriptions, summary, camera, history)
        │
        ▼
Service Layer (WineService)
        │
        ▼
Backend API (Cloud Functions / HTTP)


## Setup & Development

### Requirements

- Flutter SDK
- Firebase project configuration
- A running backend for cloud functions (locally via emulator, or deployed)

### Local Development Setup

1. install dependencies:
   ```bash
   flutter pub get

2. run with according base_URL (see config.dart for more information)


## API Documentation

```markdown
### API Endpoints (Cloud Functions)

- `POST /callGemini`
  - Goal: Analyze front + back label via LLM
  - Input: Multipart with `front`, `back`, `token`
  - Output: JSON → WineData-Map

- `GET /fetchDescriptions`
  - Goal: Runs a web search for wine descriptions
  - Query: `token`, `q`, `name`
  - Output: `organic_results[]` with `title`, `snippet`, `link`

- `GET /generateSummary`
  - Goal: generate a summary from provided web descriptions + AI-image based on this information
  - Query: `token`, `q`
  - Output: `{ summary, approved, image }`

- `GET /searchHistory`
  - Goal: Returns the authenticated user’s previous scans
  - Query: `token`
  - Output: list of StoredWine JSONs

- `POST /deleteSearch`
  - Goal: Deletes an entry from the search history
  - Query: `token`, `id`
  - Output: 200 for success

## Development Guidelines

- No HTTP calls inside UI widgets  
- Use constants from AppConstants and ErrorMessages no hardcoded Strings/Numbers
- In case of errors: UI displays SnackBar, while service layer throws exception
- Add new features in according file in the project struture (models, API-calls, ...)