# VentureBridge - Flutter Frontend

A modern Flutter application for connecting entrepreneurs with investors. This is the frontend-only implementation, ready to connect to your backend API.

## Features

### Authentication
- ✅ Login screen
- ✅ Register screen (Entrepreneur/Investor selection)
- ✅ JWT token storage (secure storage)
- ✅ Auto-login if token exists
- ✅ Auth guards with GoRouter

### Dashboards
**Entrepreneur Dashboard:**
- ✅ Create project
- ✅ View my projects
- ✅ View matched investors (with match percentage)
- ✅ Messaging button

**Investor Dashboard:**
- ✅ Set investment criteria
- ✅ View matched projects (with match percentage)
- ✅ Messaging button

### Global Search
- ✅ Single search bar
- ✅ Filter by type (Investor / Entrepreneur / Project)
- ✅ Display results in list
- ✅ Open details page

### Browse Screens
- ✅ Browse Investors
- ✅ Browse Projects
- ✅ Filters + sorting (Newest / Highest rated / Most liked)
- ✅ Infinite scroll pagination

### Likes / Favorites
- ✅ Like/unlike investors, entrepreneurs, projects
- ✅ Show liked state
- ✅ My Likes screen with tabs

### Ratings Display
- ✅ Show average rating (e.g. 4.6 ⭐ from 23 ratings)
- ✅ Display on Profile screen, Browse cards, Search results
- ✅ Rating submission UI (1–5 stars + comment)
- ✅ Rating distribution chart

### Messaging UI
- ✅ Chat list screen
- ✅ Chat detail screen
- ✅ Send message
- ✅ Message timestamps
- ✅ Read receipts

## Tech Stack

- **Flutter** (latest stable)
- **Riverpod** for state management
- **Dio** for HTTP client
- **GoRouter** for navigation with auth guards
- **flutter_secure_storage** for JWT token storage
- **Material 3** modern UI

## Project Structure

```
lib/
├── main.dart                     # Entry point
├── app.dart                      # App configuration
├── core/
│   ├── constants/
│   │   ├── api_constants.dart    # API endpoint definitions
│   │   └── app_constants.dart    # App-wide constants
│   ├── network/
│   │   ├── api_service.dart      # Centralized API service
│   │   └── dio_client.dart       # Dio HTTP client setup
│   ├── router/
│   │   └── app_router.dart       # GoRouter configuration
│   ├── storage/
│   │   └── secure_storage.dart   # Secure token storage
│   └── theme/
│       └── app_theme.dart        # Material 3 theme
├── features/
│   ├── auth/                     # Authentication screens
│   ├── dashboard/                # Entrepreneur & Investor dashboards
│   ├── browse/                   # Browse & detail screens
│   ├── search/                   # Global search
│   ├── likes/                    # Favorites/likes
│   ├── ratings/                  # Rating components
│   └── messaging/                # Chat UI
├── models/                       # Data models
│   ├── user.dart
│   ├── project.dart
│   ├── investor.dart
│   ├── match.dart
│   ├── message.dart
│   ├── like.dart
│   └── rating.dart
├── providers/                    # Riverpod providers
│   ├── auth_provider.dart
│   ├── project_provider.dart
│   ├── investor_provider.dart
│   ├── match_provider.dart
│   ├── search_provider.dart
│   ├── likes_provider.dart
│   ├── ratings_provider.dart
│   └── messaging_provider.dart
└── widgets/                      # Reusable widgets
    ├── common/
    │   ├── app_drawer.dart
    │   └── rating_display.dart
    └── cards/
        ├── project_card.dart
        ├── investor_card.dart
        └── match_card.dart
```

## API Endpoints

Configure your backend URL in `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'https://your-backend-api.com';
```

### Authentication
- `POST /auth/login`
- `POST /auth/register`
- `POST /auth/refresh`
- `POST /auth/logout`

### Projects
- `GET /projects`
- `GET /projects/{id}`
- `POST /projects`
- `PUT /projects/{id}`
- `DELETE /projects/{id}`
- `GET /projects/my`

### Investors
- `GET /investors`
- `GET /investors/{id}`
- `PUT /investors/criteria`

### Matches
- `GET /matches/investors`
- `GET /matches/projects`

### Search
- `GET /search?q={query}&type={type}`

### Likes
- `POST /likes`
- `DELETE /likes/{id}`
- `GET /likes/my`

### Ratings
- `POST /ratings`
- `GET /ratings/summary/{userId}`

### Messages
- `GET /messages/conversations`
- `GET /messages/conversations/{id}`
- `POST /messages`

## Getting Started

1. **Prerequisites**
   - Flutter SDK (latest stable)
   - Android Studio or VS Code with Flutter extension
   - Xcode (for iOS development on macOS)

2. **Installation**
   ```bash
   # Clone or download this project
   cd venturebridge

   # Get dependencies
   flutter pub get

   # Run code generation (for freezed/json_serializable if needed)
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Configure API**
   - Open `lib/core/constants/api_constants.dart`
   - Change `baseUrl` to your backend API URL

4. **Run the app**
   ```bash
   # Run on connected device/emulator
   flutter run

   # Run on specific device
   flutter run -d chrome    # Web
   flutter run -d ios       # iOS Simulator
   flutter run -d android   # Android Emulator
   ```

## Backend API Requirements

Your backend should implement these response formats:

### Auth Response
```json
{
  "access_token": "jwt_token_here",
  "refresh_token": "refresh_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "user_type": "entrepreneur"
  }
}
```

### Paginated List Response
```json
{
  "data": [...],
  "total": 100,
  "page": 1,
  "limit": 20
}
```

### Error Response
```json
{
  "message": "Error description"
}
```

## Customization

### Theme
Modify `lib/core/theme/app_theme.dart` to customize colors, typography, and component styles.

### Industries & Stages
Update `lib/core/constants/app_constants.dart` to modify available industries and investment stages.

## License

This project is for your use. Feel free to modify and extend as needed.
