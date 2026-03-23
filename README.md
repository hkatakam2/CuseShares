# CuseShares

A Flutter-based food rescue platform for Syracuse University that connects students facing food insecurity with organizers who have surplus food. Users can post available food with photos and locations, chat in real-time, and receive push notifications when new food is shared nearby.

## Features

- **Authentication** — Email/password sign-up and sign-in via Firebase Auth
- **Food Post Feed** — Real-time scrollable feed of available food posts with images, locations, and status
- **Post Creation** — Share surplus food with a name, description, photo (camera or gallery), and map-picked location
- **Real-Time Chat** — In-app messaging on each post for coordination between posters and recipients
- **Push Notifications** — Automatic alerts via Firebase Cloud Messaging when new food is posted
- **Location & Maps** — Google Maps integration for picking drop-off locations and getting directions
- **User Profiles** — View your posted items and manage your account
- **Theme Support** — Light, dark, and system theme modes
- **Platform-Aware UI** — Cupertino widgets on iOS, Material on Android

## Architecture

The app follows an **MVVM** pattern with a service/repository layer:

```
Views (UI)  →  ViewModels (State/ChangeNotifier)  →  Repositories  →  Services  →  Firebase
```

### Project Structure

```
lib/
├── main.dart                  # App entry point, Firebase init, theme & provider setup
├── firebase_options.dart      # Firebase platform credentials
├── models/                    # Data models (AppUser, FoodPost, ChatMessage)
├── services/                  # Firebase wrappers (Auth, Firestore, Storage, Notifications, Location)
├── repositories/              # Data access layer (AuthRepository, PostRepository)
├── viewmodels/                # State management (Auth, Home, CreatePost, PostDetails, Profile)
├── views/                     # UI screens
│   ├── auth/                  #   Login & registration
│   ├── home/                  #   Main feed & post list items
│   ├── post/                  #   Create post, post details, map picker
│   └── profile/               #   User profile
└── utils/                     # Theme notifier

functions/
└── index.js                   # Cloud Function: sends FCM notification on new post creation
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) |
| State Management | Provider (ChangeNotifier) |
| Backend | Firebase (Auth, Firestore, Storage, Messaging, App Check) |
| Cloud Functions | Node.js (Firebase Functions v6) |
| Maps | Google Maps Flutter |
| Notifications | Firebase Messaging + flutter_local_notifications |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.7+)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [Node.js](https://nodejs.org/) 22+ (for Cloud Functions)
- A Google Maps API key (for map features)
- Xcode (for iOS) / Android Studio (for Android)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/hemakatakam/CuseShares.git
cd CuseShares
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Install Cloud Functions dependencies

```bash
cd functions
npm install
cd ..
```

### 4. Run the app

```bash
flutter run
```

### 5. Deploy Cloud Functions (optional)

```bash
firebase deploy --only functions
```

## Firebase Services

| Service | Usage |
|---------|-------|
| **Authentication** | Email/password user accounts |
| **Cloud Firestore** | `foodPosts` collection (with `messages` subcollection for chat) |
| **Cloud Storage** | Food images stored at `food_images/{userId}_{timestamp}.jpg` |
| **Cloud Messaging** | Topic-based push notifications (`new_food` topic) |
| **App Check** | Play Integrity (Android) and App Attest (iOS) |

## Platforms

- iOS
- Android
- macOS (configured)
