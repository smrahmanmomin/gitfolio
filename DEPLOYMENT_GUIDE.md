# 🚀 GitFolio Deployment Guide

Complete step-by-step guide for deploying GitFolio to GitHub Pages and other platforms.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [GitHub OAuth Setup](#github-oauth-setup)
3. [GitHub Pages Deployment](#github-pages-deployment)
4. [Custom Domain Setup](#custom-domain-setup)
5. [Environment Configuration](#environment-configuration)
6. [Alternative Hosting](#alternative-hosting)
7. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

Before deploying, ensure you have:

- ✅ GitHub account
- ✅ Git installed locally
- ✅ Flutter SDK 3.24.0+ installed
- ✅ Project building successfully locally
- ✅ Repository pushed to GitHub

Verify your Flutter installation:
```bash
flutter doctor -v
flutter --version
```

---

## 🔐 GitHub OAuth Setup

### Step 1: Create OAuth Application

1. **Navigate to GitHub Settings:**
   - Go to https://github.com/settings/developers
   - Click **"OAuth Apps"** in the left sidebar
   - Click **"New OAuth App"** button

2. **Fill in Application Details:**

   **For Development:**
   ```
   Application name: GitFolio (Development)
   Homepage URL: http://localhost:8000
   Authorization callback URL: http://localhost:8000
   ```

   **For Production:**
   ```
   Application name: GitFolio
   Homepage URL: https://yourusername.github.io/gitfolio/
   Authorization callback URL: https://yourusername.github.io/gitfolio/
   ```

   > 💡 **Tip:** Create separate OAuth apps for development and production

3. **Register the Application:**
   - Click **"Register application"**
   - You'll see your **Client ID** immediately
   - Click **"Generate a new client secret"** to get your **Client Secret**
   - ⚠️ **Important:** Copy and save these credentials immediately - the secret won't be shown again!

### Step 2: Configure Application

1. **Update Constants File:**

   Open `lib/core/constants/app_constants.dart` and update:

   ```dart
   class AppConstants {
     // GitHub OAuth Configuration
     static const String githubClientId = 'YOUR_CLIENT_ID_HERE';
     static const String githubClientSecret = 'YOUR_CLIENT_SECRET_HERE';
     static const String githubCallbackUrl = 'https://yourusername.github.io/gitfolio/';
     
     // ... rest of the file
   }
   ```

2. **Create Environment File (Optional):**

   Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

   Edit `.env`:
   ```env
   GITHUB_CLIENT_ID_PROD=your_actual_client_id
   GITHUB_CLIENT_SECRET_PROD=your_actual_client_secret
   GITHUB_CALLBACK_URL_PROD=https://yourusername.github.io/gitfolio/
   ```

   > ⚠️ **Security:** Never commit `.env` files to Git! They're already in `.gitignore`

---

## 🌐 GitHub Pages Deployment

### Method 1: Automatic Deployment (Recommended)

GitHub Actions will automatically build and deploy your app.

#### Step 1: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** → **Pages**
3. Under **"Source"**, select **"GitHub Actions"**
4. Click **Save**

#### Step 2: Update Workflow Configuration

Edit `.github/workflows/deploy.yml`:

```yaml
- name: Build web
  run: |
    flutter build web --release \
      --web-renderer canvaskit \
      --base-href /gitfolio/ \  # ← Change 'gitfolio' to your repo name
      --dart-define=FLUTTER_WEB_USE_SKIA=true
```

**Important:** Update `/gitfolio/` to match your repository name!

#### Step 3: Commit and Push

```bash
git add .
git commit -m "Configure GitHub Pages deployment"
git push origin main
```

#### Step 4: Monitor Deployment

1. Go to **Actions** tab in your repository
2. Watch the deployment workflow run
3. Once complete, your site will be live at:
   ```
   https://yourusername.github.io/gitfolio/
   ```

### Method 2: Manual Deployment

If you prefer manual deployment:

#### Step 1: Build the App

```bash
# PowerShell (Windows)
.\scripts\build_web.ps1

# Bash (Linux/macOS)
./scripts/build_web.sh
```

Or manually:
```bash
flutter clean
flutter pub get
flutter build web --release \
  --web-renderer canvaskit \
  --base-href /gitfolio/
```

#### Step 2: Copy Build Output

```bash
# Copy build output to docs folder
rm -rf docs/*
cp -r build/web/* docs/
```

#### Step 3: Commit and Push

```bash
git add docs/
git commit -m "Deploy to GitHub Pages"
git push origin main
```

#### Step 4: Configure GitHub Pages

1. Go to **Settings** → **Pages**
2. Under **"Source"**, select **"Deploy from a branch"**
3. Select **"main"** branch and **"/docs"** folder
4. Click **Save**

---

## 🌍 Custom Domain Setup

### Step 1: Configure DNS

Add these DNS records at your domain provider:

**For apex domain (example.com):**
```
Type: A
Name: @
Value: 185.199.108.153
```
```
Type: A  
Name: @
Value: 185.199.109.153
```
```
Type: A
Name: @
Value: 185.199.110.153
```
```
Type: A
Name: @
Value: 185.199.111.153
```

**For subdomain (gitfolio.example.com):**
```
Type: CNAME
Name: gitfolio
Value: yourusername.github.io
```

### Step 2: Update GitHub Pages Settings

1. Go to **Settings** → **Pages**
2. Under **"Custom domain"**, enter your domain
3. Click **Save**
4. Wait for DNS check to complete (may take up to 48 hours)
5. Once verified, enable **"Enforce HTTPS"**

### Step 3: Update Application URLs

1. **Update OAuth App:**
   - Go to GitHub OAuth app settings
   - Change Homepage URL and Callback URL to your custom domain

2. **Update Constants:**
   ```dart
   static const String githubCallbackUrl = 'https://gitfolio.example.com/';
   ```

3. **Update workflow:**
   Edit `.github/workflows/deploy.yml`:
   ```yaml
   - name: Copy build to docs
     run: |
       rm -rf docs/*
       cp -r build/web/* docs/
       echo "gitfolio.example.com" > docs/CNAME  # Add custom domain
   ```

4. **Rebuild and Deploy:**
   ```bash
   git add .
   git commit -m "Configure custom domain"
   git push origin main
   ```

---

## ⚙️ Environment Configuration

### Development Environment

```dart
// lib/core/constants/app_constants.dart (Development)
static const String githubClientId = 'dev_client_id';
static const String githubCallbackUrl = 'http://localhost:8000';
```

Run locally:
```bash
flutter run -d chrome --dart-define=ENVIRONMENT=development
```

### Staging Environment

Create a separate branch for staging:
```bash
git checkout -b staging
```

Update constants for staging:
```dart
static const String githubCallbackUrl = 'https://yourusername.github.io/gitfolio-staging/';
```

### Production Environment

```dart
// lib/core/constants/app_constants.dart (Production)
static const String githubClientId = 'prod_client_id';
static const String githubCallbackUrl = 'https://yourusername.github.io/gitfolio/';
```

### Environment-Specific Builds

Create different configurations:

```bash
# Development
flutter build web --dart-define=ENV=dev

# Staging  
flutter build web --dart-define=ENV=staging

# Production
flutter build web --dart-define=ENV=prod
```

---

## 🔄 Alternative Hosting Platforms

### Vercel

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Build the app:**
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

3. **Deploy:**
   ```bash
   cd build/web
   vercel --prod
   ```

4. **Configure:**
   - Set output directory to `build/web`
   - Update OAuth callback URL

### Netlify

1. **Build the app:**
   ```bash
   flutter build web --release
   ```

2. **Create `netlify.toml`:**
   ```toml
   [build]
     publish = "build/web"
     command = "flutter build web --release"

   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```

3. **Deploy:**
   - Connect GitHub repository to Netlify
   - Or use Netlify CLI:
     ```bash
     netlify deploy --prod --dir=build/web
     ```

### Firebase Hosting

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login and init:**
   ```bash
   firebase login
   firebase init hosting
   ```

3. **Configure `firebase.json`:**
   ```json
   {
     "hosting": {
       "public": "build/web",
       "ignore": ["firebase.json"],
       "rewrites": [{
         "source": "**",
         "destination": "/index.html"
       }]
     }
   }
   ```

4. **Build and deploy:**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

### AWS Amplify

1. **Build the app:**
   ```bash
   flutter build web --release
   ```

2. **Create `amplify.yml`:**
   ```yaml
   version: 1
   frontend:
     phases:
       build:
         commands:
           - flutter build web --release
     artifacts:
       baseDirectory: build/web
       files:
         - '**/*'
   ```

3. **Deploy:**
   - Connect GitHub repository
   - Configure build settings
   - Deploy

---

## 🐛 Troubleshooting

### Issue: OAuth Callback Not Working

**Symptoms:** After GitHub login, app doesn't navigate to dashboard

**Solutions:**
1. Verify callback URL matches exactly in:
   - GitHub OAuth app settings
   - `app_constants.dart`
   - `web/index.html` (if custom handling)

2. Check browser console for errors
3. Ensure `sessionStorage` is being populated
4. Verify no CORS issues (open browser console)

### Issue: 404 Error on GitHub Pages

**Symptoms:** Page loads but shows 404 for routes

**Solutions:**
1. Verify `--base-href` matches repository name:
   ```bash
   flutter build web --base-href /gitfolio/
   ```

2. Check if GitHub Pages is enabled in repository settings

3. Ensure `docs/` folder has content after build

### Issue: Assets Not Loading

**Symptoms:** Images, fonts, or icons missing

**Solutions:**
1. Verify `base href` is set correctly
2. Check `pubspec.yaml` assets are declared:
   ```yaml
   flutter:
     assets:
       - assets/images/
       - assets/icons/
   ```

3. Rebuild with:
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release
   ```

### Issue: Build Fails in CI/CD

**Symptoms:** GitHub Actions workflow fails

**Solutions:**
1. Check Flutter version in workflow matches local:
   ```yaml
   - uses: subosito/flutter-action@v2
     with:
       flutter-version: '3.24.0'
   ```

2. Verify all dependencies are compatible:
   ```bash
   flutter pub get
   flutter pub outdated
   ```

3. Check workflow logs for specific errors

### Issue: White Screen After Deploy

**Symptoms:** App loads but shows blank white page

**Solutions:**
1. Check browser console for JavaScript errors
2. Verify web renderer compatibility:
   ```bash
   # Try different renderer
   flutter build web --web-renderer html
   ```

3. Clear browser cache and hard reload (Ctrl+Shift+R)

4. Check if service worker is causing issues (disable in DevTools)

### Issue: Slow Loading Time

**Solutions:**
1. Use CanvasKit renderer for better performance:
   ```bash
   flutter build web --web-renderer canvaskit
   ```

2. Enable tree-shaking:
   ```bash
   flutter build web --release --tree-shake-icons
   ```

3. Add loading screen (already implemented in `web/index.html`)

4. Consider code splitting for large apps

---

## 📊 Deployment Checklist

Before deploying to production:

- [ ] GitHub OAuth app created (production)
- [ ] OAuth credentials updated in `app_constants.dart`
- [ ] Callback URLs match deployment URL
- [ ] `.env` file not committed to Git
- [ ] Build completes without errors locally
- [ ] All tests passing (`flutter test`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Code formatted (`dart format .`)
- [ ] `base-href` configured correctly
- [ ] GitHub Pages enabled in repository settings
- [ ] Workflow file updated with correct repo name
- [ ] Custom domain configured (if applicable)
- [ ] HTTPS enforced (for custom domains)
- [ ] OAuth tested end-to-end
- [ ] All routes working correctly
- [ ] Assets loading properly
- [ ] Responsive design tested on different devices
- [ ] Browser compatibility verified (Chrome, Firefox, Safari, Edge)

---

## 🎯 Quick Deploy Commands

### Development
```bash
flutter run -d chrome
```

### Test Build
```powershell
.\scripts\test_build.ps1
```

### Production Build
```powershell
.\scripts\build_web.ps1
```

### Deploy to GitHub Pages
```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

---

## 📞 Support

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review [GitHub Pages documentation](https://docs.github.com/pages)
3. Check [Flutter web deployment docs](https://docs.flutter.dev/deployment/web)
4. Open an [issue on GitHub](https://github.com/yourusername/gitfolio/issues)

---

## 🎉 Success!

Once deployed, your GitFolio app will be live at:

```
https://yourusername.github.io/gitfolio/
```

Or your custom domain:
```
https://gitfolio.example.com/
```

**Next Steps:**
- Share your portfolio URL
- Customize the design
- Add more features
- Collect feedback
- Star the repo ⭐

---

<div align="center">

**Happy Deploying! 🚀**

[← Back to README](README.md)

</div>
