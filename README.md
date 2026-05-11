<div align="center">

# 🦈 Shark Space

### _Where Bold Ideas Meet Smart Capital_

**A modern Flutter platform bridging the gap between visionary entrepreneurs and forward-thinking investors.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-0553B1?style=for-the-badge&logo=flutter&logoColor=white)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blueviolet?style=for-the-badge)]()

[Features](#-key-features) • [Demo](#-screenshots) • [Getting Started](#-getting-started) • [Architecture](#%EF%B8%8F-architecture) • [Contributing](#-contributing)

</div>

---

## 📑 Table of Contents

- [About The Project](#-about-the-project)
- [Key Features](#-key-features)
- [Tech Stack](#%EF%B8%8F-tech-stack)
- [Screenshots](#-screenshots)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Supabase Configuration](#-supabase-configuration)
- [Dependencies](#-dependencies)
- [Architecture](#%EF%B8%8F-architecture)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [Author](#-author)
- [License](#-license)

---

## 📖 About The Project

**Shark Space** _(also known as VentureBridge)_ is a cross-platform mobile application inspired by global investment programs like *Shark Tank*. It creates an intelligent digital ecosystem where:

- 💼 **Entrepreneurs** can pitch their projects, showcase their vision, and reach serious investors.
- 💰 **Investors** can discover, evaluate, and connect with promising ventures aligned with their interests.

By combining a **smart matching algorithm**, **real-time communication**, and a **trust-driven rating system**, Shark Space removes friction from the investment journey — making the path from idea to funding faster, more transparent, and more efficient.

> 🎯 **Mission:** To democratize access to investment opportunities and empower the next generation of entrepreneurs across the region and beyond.

---

## ✨ Key Features

<table>
  <tr>
    <td width="50%">

### 🔐 Dual Account System
Tailored dashboards for **Entrepreneurs** and **Investors**, each with role-specific tools and workflows.

### 🔍 Smart Browsing
Explore projects and investor profiles through clean, performant UI with detailed views and rich media.

### ❤️ Likes & Matching
Mutual-interest matching system — when both sides show interest, a connection is automatically created.

### 💬 Real-time Chat
Instant messaging powered by **Supabase Realtime**, enabling seamless conversations between matched users.

   </td>
   <td width="50%">

### ⭐ Ratings & Reviews
Build credibility and trust through a transparent feedback system between users.

### 🔎 Advanced Search
Powerful filters to discover the right projects or investors based on specific criteria.

### 👤 Profile Management
Upload avatars, manage pitch decks, and customize your professional presence.

### 🔒 Secure Authentication
Email-based sign-up with confirmation, persistent sessions, and **Row Level Security** at the database layer.

   </td>
  </tr>
</table>

---

## 🛠️ Tech Stack

<div align="center">

| Layer | Technology |
|:-----:|:----------:|
| **Frontend** | Flutter (Dart) |
| **Backend** | Supabase (BaaS) |
| **Database** | PostgreSQL |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Real-time** | Supabase Realtime |
| **Storage** | Supabase Storage |
| **Security** | Row Level Security (RLS) |

</div>

---

## 📸 Screenshots

> _Screenshots coming soon — stay tuned!_

<!--
<div align="center">
  <img src="screenshots/login.png" width="200" alt="Login Screen"/>
  <img src="screenshots/dashboard.png" width="200" alt="Dashboard"/>
  <img src="screenshots/chat.png" width="200" alt="Chat Screen"/>
  <img src="screenshots/profile.png" width="200" alt="Profile"/>
</div>
-->

---

## 🚀 Getting Started

Follow these steps to get **Shark Space** running locally in just a few minutes.

### ✅ Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Dart SDK](https://dart.dev/get-dart) (3.x or later)
- A free [Supabase](https://supabase.com) account
- Android Studio / VS Code with Flutter extensions

---

### 📦 Installation

#### **1️⃣ Clone the Repository**

```bash
git clone https://github.com/OsamaALHajj/Shark-Space.git
cd Shark-Space
```

#### **2️⃣ Create a Free Supabase Project**

1. Visit [supabase.com](https://supabase.com) → **New Project**
2. Navigate to **Settings → API**
3. Copy your:
   - 🔗 **Project URL**
   - 🔑 **anon public key**

#### **3️⃣ Configure Your Credentials**

Open `lib/core/constants/supabase_constants.dart` and update the two lines below:

```dart
static const String supabaseUrl     = 'https://xxxx.supabase.co';  // ← your Project URL
static const String supabaseAnonKey = 'eyJ...';                    // ← your anon key
```

#### **4️⃣ Initialize the Database**

1. Open **Supabase Dashboard → SQL Editor → New query**
2. Paste the entire contents of `supabase_schema.sql`
3. Click **RUN** ✅

#### **5️⃣ Install Dependencies & Launch**

```bash
flutter pub get
flutter run
```

🎉 **That's it!** The app should now be running on your emulator or connected device.

---

## 📁 Project Structure

```
lib/
├── main.dart                          # 🚪 Entry point + Supabase initialization
├── app.dart                           # 🎨 MaterialApp + Router setup
│
├── core/                              # 🧠 Core utilities & shared services
│   ├── constants/
│   │   ├── supabase_constants.dart    # 🔑 Supabase URL & AnonKey
│   │   └── app_constants.dart         # App-wide constants
│   ├── supabase/
│   │   ├── supabase_service.dart      # All DB operations
│   │   └── supabase_client_provider.dart
│   ├── router/
│   │   └── app_router.dart            # Navigation + route guards
│   └── theme/
│       └── app_theme.dart             # App theming
│
├── models/                            # 📦 Data models (User, Project, Investor…)
│
├── providers/                         # 🔄 Riverpod state management
│   ├── auth_provider.dart
│   ├── project_provider.dart
│   ├── investor_provider.dart
│   ├── match_provider.dart
│   ├── likes_provider.dart
│   ├── ratings_provider.dart
│   ├── search_provider.dart
│   └── messaging_provider.dart        # ⚡ Realtime chat
│
├── features/                          # 🧩 Feature-based modules
│   ├── auth/                          # Login, Register, Splash
│   ├── dashboard/                     # Entrepreneur & Investor dashboards
│   ├── browse/                        # Projects, Investors, Detail, Profile
│   ├── messaging/                     # Conversations & Real-time Chat
│   ├── search/                        # Advanced search
│   └── likes/                         # My Likes
│
└── widgets/                           # 🧱 Reusable UI components
    ├── cards/                         # ProjectCard, InvestorCard, MatchCard
    └── common/                        # AppDrawer, RatingDisplay, …
```

---

## ⚙️ Supabase Configuration

### 🔌 Features Used

| Feature | Purpose |
|---------|---------|
| **Auth** | Sign up / Sign in with email + automatic session persistence |
| **Database** | All application data tables |
| **Row Level Security** | Per-user data isolation and protection |
| **Realtime** | Instant messaging in the chat module |
| **Storage** | Profile pictures and pitch deck file uploads |

### 🔗 Redirect URL (Required for Email Confirmation)

In **Authentication → URL Configuration**, add:

```
io.supabase.venturebridge://login-callback
```

### 🪣 Storage Buckets _(Optional)_

In **Storage**, create the following buckets:

| Bucket | Visibility | Purpose |
|--------|------------|---------|
| `avatars` | 🌍 Public | User profile pictures |
| `pitch-decks` | 🔒 Private | Confidential pitch documents |

---

## 📦 Dependencies

```yaml
dependencies:
  supabase_flutter: ^2.5.6      # Complete backend solution
  flutter_riverpod: ^2.5.1      # State management
  go_router: ^14.2.0            # Declarative navigation
  equatable: ^2.0.5             # Value equality for models
  flutter_rating_bar: ^4.0.1    # Star rating widget
  cached_network_image: ^3.3.1  # Image caching & loading
  intl: ^0.19.0                 # Date formatting & i18n
  image_picker: ^1.1.2          # Image selection & upload
```

---

## 🏗️ Architecture

Shark Space follows a **clean, feature-based architecture** with strict separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│              (Features, Widgets, Screens)                │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                  State Management Layer                  │
│                (Riverpod Providers)                      │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                     Service Layer                        │
│             (Supabase Service & Models)                  │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                   Backend (Supabase)                     │
│         Auth • Database • Realtime • Storage             │
└─────────────────────────────────────────────────────────┘
```

**Core Principles:**

- 🧩 **Modular** — Each feature is self-contained and independently maintainable.
- 🔄 **Reactive** — Riverpod ensures predictable, reactive state across the app.
- 🔐 **Secure by Design** — RLS policies enforce data security at the database level.
- 📈 **Scalable** — Easy to add new features without touching existing code.
- 🧪 **Testable** — Clear separation between UI, state, and business logic.

---

## 🗺️ Roadmap

- [x] User authentication & dual role system
- [x] Project & investor browsing
- [x] Likes & matching system
- [x] Real-time chat
- [x] Ratings system
- [ ] Push notifications
- [ ] Video pitch uploads
- [ ] AI-powered project recommendations
- [ ] Multi-language support (Arabic / English)
- [ ] Investment tracking dashboard
- [ ] Web version

> See [open issues](https://github.com/OsamaALHajj/Shark-Space/issues) for a full list of proposed features and known issues.

---

## 🤝 Contributing

Contributions make the open-source community an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. **Fork** the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a **Pull Request**

---

## 👤 Author

<div align="center">

**Osama AL Hajj**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/OsamaALHajj)

_Crafted with passion and clean code._

</div>

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<div align="center">

### ⭐ If you found this project helpful, please consider giving it a star!

**Made with ❤️ using Flutter & Supabase**

<sub>© 2026 Shark Space — All rights reserved.</sub>

</div>
