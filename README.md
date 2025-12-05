# CuseShares 🍎📍

> **Real-Time Food Rescue Platform for Syracuse University.**

CuseShares connects event organizers who have surplus food with students facing food insecurity. It leverages real-time cloud messaging to ensure food is claimed within minutes, reducing campus waste and hunger simultaneously.

![Status](https://img.shields.io/badge/Status-Beta-yellow)
![Tech](https://img.shields.io/badge/Mobile-Flutter-blue)
![Tech](https://img.shields.io/badge/Backend-Firebase-orange)

## 📱 Features

* **Real-Time Feeds:** Students see food drops instantly without refreshing (via Firestore listeners).
* **Push Notifications:** Geo-fenced alerts sent via FCM (Firebase Cloud Messaging) when food is posted nearby.
* **Live Status Toggle:** Organizers can toggle a post from "Available" to "Over" instantly to prevent overcrowding.
* **Image Optimization:** Automatic compression of food photos to save bandwidth.

## 🛠 Tech Stack

* **Framework:** Flutter (Dart)
* **Auth:** Firebase Authentication (Edu-email verification)
* **Database:** Cloud Firestore (NoSQL)
* **Storage:** Firebase Storage
* **Notifications:** Firebase Cloud Messaging (FCM)

## 📸 Screenshots
| Feed View | Map View | Post Creation |
|:---:|:---:|:---:|
| *(Placeholders for Screenshots)* | *(Placeholders for Screenshots)* | *(Placeholders for Screenshots)* |

## 🚀 Getting Started

### Prerequisites
* Flutter SDK
* Android Studio / Xcode
* A Firebase Project set up with `google-services.json` / `GoogleService-Info.plist`.

### Installation

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/yourusername/cuse-shares.git](https://github.com/yourusername/cuse-shares.git)
    cd cuse-shares
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run on Emulator**
    ```bash
    flutter run
    ```

## 🏗 Engineering Challenges Solved
* **Concurrency:** Handled race conditions where two users claim the same item simultaneously using Firestore Transactions.
* **State Management:** Used BLoC pattern to manage the complex state of real-time streams and user authentication.
