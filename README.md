<div align="center">

# 💻 GitFolio

### Your Professional GitHub Portfolio

[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.1-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Pages](https://img.shields.io/badge/Demo-Live-success)](https://yourusername.github.io/gitfolio/)

Showcase your GitHub profile with beautiful visualizations, repository insights, and contribution analytics.

[🚀 Live Demo](https://yourusername.github.io/gitfolio/) • [📖 Documentation](DEPLOYMENT_GUIDE.md) • [🐛 Report Bug](https://github.com/yourusername/gitfolio/issues)

<img src="docs/screenshots/demo.gif" alt="GitFolio Demo" width="800"/>

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🔐 Authentication
- GitHub OAuth 2.0 integration
- Secure token storage
- Auto-login on app restart
- One-click logout

### 👤 Profile Management
- User avatar and bio display
- GitHub stats overview
- Location and contact info
- Direct profile links

</td>
<td width="50%">

### 📦 Repository Browser
- Search across all repos
- Sort by name, stars, or updates
- Repository statistics
- Quick access to repo URLs

### 📊 Analytics
- Interactive contribution heatmap
- 365-day activity visualization
- Color-coded contribution levels
- Hover details for each day

</td>
</tr>
</table>

### 🎨 Design & UX
- 🌓 **Dark/Light Mode** - Automatic theme detection
- 📱 **Responsive** - Optimized for web, mobile, and desktop
- 🎯 **Material 3** - Modern, GitHub-inspired design system
- ⚡ **Fast** - Optimized performance with caching
- ♿ **Accessible** - WCAG compliant interface

---

## 📸 Screenshots

<div align="center">

### Light Theme
<img src="docs/screenshots/profile-light.png" alt="Profile Page Light" width="400"/> <img src="docs/screenshots/repos-light.png" alt="Repos Page Light" width="400"/>

### Dark Theme  
<img src="docs/screenshots/profile-dark.png" alt="Profile Page Dark" width="400"/> <img src="docs/screenshots/repos-dark.png" alt="Repos Page Dark" width="400"/>

</div>

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart 3.10.1 or higher
- Git
- A GitHub account

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/gitfolio.git
cd gitfolio

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

### GitHub OAuth Setup

1. **Create a GitHub OAuth App:**
   - Go to [GitHub Developer Settings](https://github.com/settings/developers)
   - Click **"New OAuth App"**
   - Fill in the details:
     - **Application name:** GitFolio
     - **Homepage URL:** `http://localhost:8000` (dev) or your deployment URL
     - **Authorization callback URL:** Same as homepage URL
   - Click **"Register application"**
   - Copy your **Client ID** and **Client Secret**

2. **Configure the app:**
   - Open `lib/core/constants/app_constants.dart`
   - Update the OAuth credentials:
   ```dart
   static const String githubClientId = 'YOUR_CLIENT_ID_HERE';
   static const String githubClientSecret = 'YOUR_CLIENT_SECRET_HERE';
   static const String githubCallbackUrl = 'YOUR_CALLBACK_URL_HERE';
   ```

3. **Run the app:**
   ```bash
   flutter run -d chrome
   ```

---

## 🏗️ Architecture

GitFolio follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                           # Core utilities and shared code
│   ├── constants/                  # App-wide constants
│   │   └── app_constants.dart      # GitHub OAuth config, API URLs
│   ├── themes/                     # Theme definitions
│   │   └── app_theme.dart          # Light/dark Material 3 themes
│   ├── utils/                      # Utility functions and extensions
│   │   └── extensions.dart         # String, DateTime, Context extensions
│   └── errors/                     # Error handling
│       ├── failures.dart           # Failure classes
│       └── exceptions.dart         # Custom exceptions
│
├── data/                           # Data layer
│   ├── datasources/                # Data sources
│   │   └── github_remote_data_source.dart  # GitHub API client
│   ├── models/                     # Data models with JSON serialization
│   │   ├── github_user_model.dart  # User data model
│   │   └── repository_model.dart   # Repository data model
│   └── repositories/               # Repository implementations
│       └── github_repository_impl.dart  # GitHub repo implementation
│
├── domain/                         # Domain layer (Business logic)
│   ├── entities/                   # Business entities
│   │   └── README.md
│   ├── repositories/               # Repository interfaces
│   │   └── github_repository.dart  # GitHub repo interface
│   └── usecases/                   # Use cases
│       └── README.md
│
├── presentation/                   # Presentation layer (UI)
│   ├── bloc/                       # BLoC state management
│   │   ├── bloc_providers.dart     # Dependency injection
│   │   └── github/                 # GitHub BLoC
│   │       ├── github_bloc.dart    # Business logic
│   │       ├── github_event.dart   # Events
│   │       └── github_state.dart   # States
│   ├── pages/                      # Screen pages
│   │   ├── splash_screen.dart      # Initial splash screen
│   │   ├── login_page.dart         # OAuth login
│   │   ├── dashboard_page.dart     # Main navigation hub
│   │   ├── profile_page.dart       # User profile display
│   │   └── repos_page.dart         # Repository browser
│   └── widgets/                    # Reusable widgets
│       ├── loading_indicator.dart  # Loading states
│       ├── error_retry_widget.dart # Error handling
│       ├── github_user_card.dart   # User profile card
│       ├── repo_card.dart          # Repository card
│       └── contribution_heatmap.dart  # Contribution visualization
│
└── main.dart                       # App entry point
```

### Architecture Layers

#### 🎯 Domain Layer (Business Logic)
- **Entities:** Pure business objects (User, Repository)
- **Repositories:** Abstract contracts defining data operations
- **Use Cases:** Application-specific business rules

#### 💾 Data Layer
- **Models:** Concrete implementations with JSON serialization
- **Data Sources:** API clients (GitHub REST & GraphQL)
- **Repository Implementations:** Concrete data operations

#### 🎨 Presentation Layer
- **BLoC:** Business logic and state management
- **Pages:** Full-screen UI components
- **Widgets:** Reusable UI elements

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** - UI framework
- **Material 3** - Design system
- **Dart** - Programming language

### State Management
- **flutter_bloc** - BLoC pattern implementation
- **provider** - Dependency injection
- **equatable** - Value equality

### Networking & Data
- **http** - REST API client
- **dartz** - Functional programming
- **shared_preferences** - Local storage

### Developer Tools
- **GitHub Actions** - CI/CD
- **Flutter DevTools** - Debugging
- **Dart Analyzer** - Static analysis

---

## 🧪 Development

### Running Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Code Quality
```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated
```

### Building

```bash
# Web (debug)
flutter build web --debug

# Web (release)
flutter build web --release --web-renderer canvaskit

# Windows
flutter build windows --release

# Android APK
flutter build apk --release

# iOS (macOS only)
flutter build ios --release
```

### Using Build Scripts

```powershell
# Quick test build
.\scripts\test_build.ps1

# Production web build
.\scripts\build_web.ps1
```

---

## 🚀 Deployment

### GitHub Pages (Automatic)

1. **Enable GitHub Pages:**
   - Go to repository Settings → Pages
   - Source: GitHub Actions

2. **Push to main branch:**
   ```bash
   git push origin main
   ```

3. **GitHub Actions will automatically:**
   - Build the Flutter web app
   - Deploy to GitHub Pages
   - Make it live at: `https://yourusername.github.io/gitfolio/`

### Manual Deployment

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions on:
- GitHub Pages setup
- Custom domain configuration
- Environment variables
- OAuth callback URLs
- CORS configuration

---

## 📁 Project Structure

```
gitfolio/
├── .github/
│   └── workflows/
│       ├── deploy.yml          # GitHub Pages deployment
│       └── ci.yml              # Continuous integration
├── android/                    # Android platform files
├── ios/                        # iOS platform files
├── lib/                        # Flutter application code
│   ├── core/                   # Core utilities
│   ├── data/                   # Data layer
│   ├── domain/                 # Business logic
│   ├── presentation/           # UI layer
│   └── main.dart               # Entry point
├── web/                        # Web platform files
│   ├── index.html              # Main HTML with OAuth handling
│   └── manifest.json           # PWA manifest
├── docs/                       # GitHub Pages output
│   └── screenshots/            # App screenshots
├── scripts/                    # Build and deployment scripts
│   ├── build_web.ps1           # PowerShell build script
│   ├── build_web.sh            # Bash build script
│   └── test_build.ps1          # Quick test script
├── .env.example                # Environment variables template
├── pubspec.yaml                # Flutter dependencies
├── README.md                   # This file
├── DEPLOYMENT_GUIDE.md         # Deployment instructions
└── BUILD_SUCCESS.md            # Build verification report
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add some amazing feature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Coding Standards
- Follow Dart style guide
- Write meaningful commit messages
- Add tests for new features
- Update documentation
- Ensure all tests pass

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) for the amazing framework
- [GitHub](https://github.com) for the API
- [Material Design](https://m3.material.io) for design guidelines
- [Bloc Library](https://bloclibrary.dev) for state management patterns

---

## 📧 Contact

**Your Name** - [@yourhandle](https://twitter.com/yourhandle)

Project Link: [https://github.com/yourusername/gitfolio](https://github.com/yourusername/gitfolio)

---

<div align="center">

Made with ❤️ using Flutter

⭐ Star this repo if you find it helpful!

[Report Bug](https://github.com/yourusername/gitfolio/issues) • [Request Feature](https://github.com/yourusername/gitfolio/issues) • [Documentation](DEPLOYMENT_GUIDE.md)

</div>

### 1. Domain Layer (Business Logic)
- **Entities**: Core business objects (GithubUser, Repository)
- **Repositories**: Abstract contracts for data operations
- **Use Cases**: Application-specific business rules

### 2. Data Layer
- **Models**: Concrete implementations with JSON serialization
- **Data Sources**: Remote (GitHub API) and Local (Cache) data sources
- **Repository Implementations**: Concrete implementations of domain contracts

### 3. Presentation Layer
- **Pages**: Full-screen UI components (Splash, Login, Dashboard, Profile, Repos)
- **Widgets**: Reusable UI components (Cards, Loading states, Error widgets)
- **BLoC**: Business Logic Components for state management

## 📱 Application Flow

1. **Splash Screen** → Check authentication status
2. **Login Page** → GitHub OAuth authentication
3. **Dashboard** → Main navigation hub with tabs:
   - **Profile Tab**: User info, stats, contribution graph
   - **Repos Tab**: Browse, search, filter repositories
   - **Analytics Tab**: (Coming soon) Detailed statistics
   - **Portfolio Tab**: (Coming soon) Custom portfolio builder

## 🎨 UI Features

- **Material 3 Design**: Modern, GitHub-inspired interface
- **Responsive Layout**: Adapts to mobile, tablet, and desktop
- **Dark/Light Themes**: System-based automatic switching
- **Pull to Refresh**: Update data with pull gesture
- **Search & Filter**: Find repositories quickly
- **Sort Options**: By stars, forks, updated date
- **Error Handling**: User-friendly error messages with retry
- **Loading States**: Smooth transitions and progress indicators

## 🧪 Testing

Run tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Desktop
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- GitHub for their comprehensive API
- BLoC library maintainers

---

**Built with ❤️ using Flutter**
- **BLoC**: Business Logic Component for state management

### 4. Core Layer
- **Constants**: App-wide constants
- **Themes**: UI themes
- **Utils**: Helper functions
- **Errors**: Error handling (Failures & Exceptions)

## Next Steps

1. Define your entities in domain/entities/
2. Create repository interfaces in domain/repositories/
3. Implement use cases in domain/usecases/
4. Create data models in data/models/
5. Implement data sources in data/datasources/
6. Implement repositories in data/repositories/
7. Create BLoCs in presentation/bloc/
8. Build pages and widgets in presentation/

## License

This project is created for portfolio purposes.
