# Contributing to GitFolio

First off, thank you for considering contributing to GitFolio! 🎉

It's people like you that make GitFolio such a great tool.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How Can I Contribute?](#how-can-i-contribute)
3. [Development Setup](#development-setup)
4. [Coding Guidelines](#coding-guidelines)
5. [Commit Messages](#commit-messages)
6. [Pull Request Process](#pull-request-process)

---

## Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inspiring community for all.

### Our Standards

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

### Unacceptable Behavior

- Trolling, insulting/derogatory comments, and personal attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**When submitting a bug report, include:**

- A clear and descriptive title
- Steps to reproduce the problem
- Expected behavior
- Actual behavior
- Screenshots (if applicable)
- Your environment (OS, Flutter version, browser)
- Any error messages or logs

**Example:**
```markdown
**Title:** Profile page fails to load on Firefox

**Description:**
The profile page shows a blank screen on Firefox 120.

**Steps to Reproduce:**
1. Open GitFolio in Firefox 120
2. Log in with GitHub OAuth
3. Navigate to profile page

**Expected:** Profile page displays user information
**Actual:** Blank white screen

**Environment:**
- OS: Windows 11
- Browser: Firefox 120.0
- Flutter: 3.24.0
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues.

**Include:**

- A clear and descriptive title
- A detailed description of the proposed feature
- Explain why this enhancement would be useful
- List any alternatives you've considered
- Mockups or examples (if applicable)

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Simple issues for beginners
- `help wanted` - Issues that need assistance
- `documentation` - Documentation improvements

### Pull Requests

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write or update tests
5. Update documentation
6. Submit a pull request

---

## Development Setup

### Prerequisites

```bash
# Check Flutter installation
flutter doctor -v

# Verify version
flutter --version  # Should be 3.24.0+
```

### Getting Started

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/gitfolio.git
cd gitfolio

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/gitfolio.git

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

### Project Structure

```
lib/
├── core/           # Shared utilities
├── data/           # Data layer (API, models, repos)
├── domain/         # Business logic
└── presentation/   # UI (pages, widgets, BLoC)
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

---

## Coding Guidelines

### Dart Style Guide

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

```bash
# Format code
dart format .

# Check formatting
dart format --output=none --set-exit-if-changed .
```

### Code Organization

- **One class per file** (exceptions: small helper classes)
- **File naming:** snake_case (e.g., `github_user_card.dart`)
- **Class naming:** PascalCase (e.g., `GithubUserCard`)
- **Variable naming:** camelCase (e.g., `userName`)
- **Constants:** camelCase with `static const` (e.g., `static const maxRetries`)

### Documentation

```dart
/// Brief description of what this class/method does.
///
/// More detailed explanation if needed, including:
/// - Usage examples
/// - Important notes
/// - Parameter descriptions
///
/// Example:
/// ```dart
/// final card = GithubUserCard(user: user);
/// ```
class GithubUserCard extends StatelessWidget {
  /// Creates a card displaying GitHub user information.
  ///
  /// The [user] parameter must not be null.
  const GithubUserCard({
    super.key,
    required this.user,
  });

  /// The user to display information for.
  final GithubUserModel user;
}
```

### BLoC Pattern

Follow the [bloc library](https://bloclibrary.dev/) conventions:

```dart
// Events - What can happen
sealed class GithubEvent extends Equatable {}

// States - Possible states
sealed class GithubState extends Equatable {}

// Bloc - Business logic
class GithubBloc extends Bloc<GithubEvent, GithubState> {
  // Implementation
}
```

### Widget Guidelines

```dart
// Prefer const constructors
const Text('Hello');

// Use named parameters for clarity
Container(
  padding: const EdgeInsets.all(16),
  child: Text('Content'),
);

// Extract complex widgets
Widget _buildHeader() {
  return Container(/* ... */);
}

// Use descriptive names
Widget _buildUserStatisticsSection() {
  // Not: _buildSection1()
}
```

### Error Handling

```dart
// Use try-catch with specific exceptions
try {
  final result = await repository.fetchData();
  return Right(result);
} on NetworkException catch (e) {
  return Left(NetworkFailure(e.message));
} on CacheException catch (e) {
  return Left(CacheFailure(e.message));
} catch (e) {
  return Left(UnknownFailure(e.toString()));
}
```

---

## Commit Messages

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, missing semicolons, etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, build, etc)
- `ci`: CI/CD changes

### Examples

```bash
feat(auth): add GitHub OAuth login

- Implement OAuth 2.0 flow
- Add token storage with SharedPreferences
- Create login page UI

Closes #123
```

```bash
fix(profile): resolve avatar loading issue

The user avatar wasn't loading when the URL contained special characters.
Now properly encoding URLs before making requests.

Fixes #456
```

```bash
docs(readme): update installation instructions

- Add prerequisites section
- Include troubleshooting steps
- Update screenshots
```

### Rules

- Use present tense ("add feature" not "added feature")
- Use imperative mood ("move cursor to..." not "moves cursor to...")
- First line should be 50 characters or less
- Reference issues and pull requests when applicable
- Separate subject from body with a blank line

---

## Pull Request Process

### Before Submitting

- [ ] Code follows the style guidelines
- [ ] Self-review of code completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] Tests added/updated and passing
- [ ] No new warnings from `flutter analyze`
- [ ] Formatted with `dart format`

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
Describe how you tested your changes

## Screenshots (if applicable)
Add screenshots showing the changes

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented complex code
- [ ] I have updated documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests
- [ ] All tests pass
```

### Review Process

1. **Automated Checks:** CI/CD runs tests and linting
2. **Code Review:** Maintainers review your code
3. **Changes Requested:** Address feedback if any
4. **Approval:** Once approved, changes will be merged
5. **Merge:** Squash and merge to main branch

### After Merge

- Delete your feature branch
- Pull latest changes from upstream
- Celebrate! 🎉

---

## Additional Notes

### Issue and Pull Request Labels

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Documentation improvements
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `question` - Further information requested
- `wontfix` - This will not be worked on
- `duplicate` - This issue/PR already exists
- `invalid` - This doesn't seem right

### Getting Help

- Read the [README](README.md)
- Check [DEPLOYMENT_GUIDE](DEPLOYMENT_GUIDE.md)
- Review existing [Issues](https://github.com/yourusername/gitfolio/issues)
- Ask in discussions

---

## Recognition

Contributors will be recognized in:

- README.md Contributors section
- Release notes
- CHANGELOG.md

Thank you for contributing to GitFolio! 💙
