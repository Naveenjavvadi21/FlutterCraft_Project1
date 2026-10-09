# ChatFlow

> **Real-Time Firebase Chat**

ChatFlow is a clean, modern, responsive, and secure real-time messaging application built with **Flutter** and **Firebase**. It provides production-grade one-to-one messaging, multi-user group chats, media sharing, debounced typing indicators, live presence tracking, read receipts, and granular Firestore security rules.

---

## 🌟 Key Features

* **Firebase Authentication**:
  * Email and password registration with automatic Firestore profile creation
  * Secure sign-in, sign-out, and password reset flows
  * Persistent authentication listener & protected application screens
  * Real-time online presence sync on login and logout

* **Real-Time One-to-One Messaging**:
  * Deterministic room ID generation (`chatRooms/{sortedUid1_sortedUid2}`) ensures reliable, duplicate-free conversations
  * Live snapshot streams via Cloud Firestore with reverse ordering
  * Infinite pagination (`startAfterDocument`) for loading historical messages

* **Group Chats**:
  * Create multi-member groups with custom group titles and photo avatars
  * Real-time sender name attribution for incoming group messages
  * Group participant directory and admin badge display

* **Image & Media Sharing**:
  * Camera and gallery photo selection with compression via `image_picker`
  * Uploads to Firebase Storage (`chat_images/{roomId}/{uuid}.jpg`) with download URL generation
  * Interactive fullscreen photo viewer with hero animations and network caching

* **Presence & Last-Seen Status**:
  * Real-time online indicator (emerald glowing badge)
  * Smart human-readable last-seen formatting ("Online", "Last seen 5m ago", "Last seen yesterday at 10:30 AM")
  * Lifecycle-aware tracking (`WidgetsBindingObserver`)

* **Typing Indicator**:
  * Real-time animated 3-dot wave bubble ("[Name] is typing...")
  * Debounced and throttled Firestore updates to prevent excessive database writes
  * Automatic typing timeout reset

* **Message Lifecycle & Read Receipts**:
  * Visual indicators: Sending (`🕒`), Sent (`✓`), and Read (`✓✓` with teal highlight)
  * Automatic unread badge counts per conversation tile
  * Batch read-receipt updates when a recipient opens a chat

* **Push Notifications**:
  * Firebase Cloud Messaging (FCM) integration
  * User token management synchronized to Firestore (`fcmToken`)
  * Notification tap handling navigating directly to the relevant conversation

* **Polished Modern UI & Dark Mode**:
  * Light and Dark themes via Material 3 `ThemeData`
  * Instant theme switching persisted across app launches (`shared_preferences`)
  * WhatsApp/Telegram-inspired responsive chat bubbles with tails and date separators

* **Security & Database Rules**:
  * Production-ready `firestore.rules` enforcing participant-only read/write access
  * Secure `storage.rules` restricting chat and profile media access
  * Composite query definitions in `firestore.indexes.json`

---

## 🛠 Tech Stack

* **Flutter** & **Dart**
* **Firebase Authentication** (`firebase_auth`)
* **Cloud Firestore** (`cloud_firestore`)
* **Firebase Storage** (`firebase_storage`)
* **Firebase Cloud Messaging** (`firebase_messaging`)
* **Provider** (`provider`) for reactive state management
* **image_picker** for camera and gallery image selection
* **cached_network_image** for image caching and performance
* **intl** for date and timestamp formatting
* **shared_preferences** for local theme persistence
* **uuid** for deterministic IDs and media file naming

---

## 📁 Project Structure

```text
lib/
├── firebase_options.dart          # Cross-platform Firebase config options
├── main.dart                      # App entry point, MultiProvider & setup fallback screen
├── models/
│   ├── chat_room_model.dart       # Room model, unread counts & deterministic ID generator
│   ├── message_model.dart         # Message model, read status & timestamps
│   └── user_model.dart            # User profile model & serialization
├── providers/
│   ├── auth_provider.dart         # Authentication lifecycle, profile edits & dark mode
│   ├── chat_provider.dart         # Messaging state, image dispatch & debounced typing
│   └── user_provider.dart         # User directory search & contact caching
├── screens/
│   ├── auth/
│   │   ├── forgot_password_screen.dart # Password reset instructions & form
│   │   ├── login_screen.dart           # Email/password login with validation
│   │   └── signup_screen.dart          # Full registration form
│   ├── chat/
│   │   ├── chat_list_screen.dart       # Conversations dashboard with unread badges
│   │   ├── chat_room_screen.dart       # Real-time chat, typing dots & image viewer
│   │   ├── group_chat_screen.dart      # Group creation & member checklist
│   │   └── new_chat_screen.dart        # Contact directory & 1-1 chat creator
│   ├── home/
│   │   └── home_screen.dart            # Main container with bottom navigation & app bar
│   ├── profile/
│   │   ├── edit_profile_screen.dart    # Name & avatar photo updates
│   │   └── profile_screen.dart         # User profile card, dark mode toggle & logout
│   └── search/
│       └── search_users_screen.dart    # Live directory search by name or email
├── services/
│   ├── auth_service.dart          # Firebase Auth operations & user doc synchronization
│   ├── chat_service.dart          # Firestore room queries, messages stream & batch reads
│   ├── notification_service.dart  # FCM token sync, push listeners & notification routing
│   ├── presence_service.dart      # Online/offline presence & lifecycle observer
│   └── storage_service.dart       # Media upload service for avatars and chat images
├── utils/
│   ├── app_theme.dart             # Centralized light & dark themes
│   ├── constants.dart             # App constants, collections & palette
│   ├── date_utils.dart            # Date separators, timestamps & last seen formatters
│   └── validators.dart            # Reusable input validators
└── widgets/
    ├── chat_tile.dart             # Conversation row with avatar & unread pill
    ├── empty_state.dart           # Illustrated empty states with CTA
    ├── loading_widget.dart        # Clean animated loading spinner
    ├── message_bubble.dart        # Responsive incoming/outgoing bubbles with checkmarks
    ├── message_input.dart         # Composer with attachment bottom sheet & send button
    ├── online_indicator.dart      # Live green presence dot
    ├── typing_indicator.dart      # Animated 3-dot wave typing indicator
    └── user_avatar.dart           # Cached network avatar with initials gradient fallback
```

---

## 🚀 Firebase Setup Guide

Follow these steps to connect ChatFlow to your Firebase project:

### 1. Create a Firebase Project
1. Visit the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and name it (e.g., `chatflow-app`).

### 2. Install and Authenticate the Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 3. Install the FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 4. Configure Your Flutter App with FlutterFire
Run the following command inside the project directory:
```bash
flutterfire configure
```
* Select your Firebase project.
* Select target platforms (Android, iOS, Web, macOS, Windows).
* This will automatically update `lib/firebase_options.dart` with your live project credentials.

### 5. Enable Firebase Services in the Firebase Console
* **Authentication**: Go to *Build > Authentication > Sign-in method* and enable **Email/Password**.
* **Cloud Firestore**: Go to *Build > Firestore Database* and click **Create database** (start in production or test mode).
* **Firebase Storage**: Go to *Build > Storage* and click **Get started**.
* **Cloud Messaging (Optional for Push Notifications)**: Go to *Project Settings > Cloud Messaging* to configure keys or APNs for iOS.

### 6. Deploy Security Rules & Indexes
Deploy the pre-configured rules and composite indexes included in this repository using the Firebase CLI:
```bash
firebase deploy --only firestore:rules,storage,firestore:indexes
```

---

## 🏃 Running the Project

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run static analysis:**
   ```bash
   flutter analyze
   ```

3. **Run unit & widget tests:**
   ```bash
   flutter test
   ```

4. **Launch the application:**
   ```bash
   flutter run
   ```

---

## 🔒 Security Architecture

ChatFlow follows strict security best practices:
* **Participant Authorization**: Only users who are in `members` of a `chatRooms/{roomId}` document can view, send, or update messages.
* **Non-spoofable Sender ID**: When creating a message, Firestore rules enforce that `request.resource.data.senderId == request.auth.uid`.
* **Private Media Storage**: Chat media uploads require authenticated membership, and profile pictures can only be uploaded by the respective account owner.
* **Passwords**: Never stored or handled in Firestore; all credentials use Firebase Authentication.

---

## 📱 Demo & Verification

* **GitHub Repository**: `[Add GitHub URL]`
* **Demo Video**: `[Add Demo Video URL]`
#   F l u t t e r C r a f t _ P r o j e c t 1  
 