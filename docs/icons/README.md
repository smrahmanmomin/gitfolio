# GitFolio App Icons

This directory contains app icons for different platforms.

## Icon Specifications

### Web
- **favicon.png**: 32x32 or 48x48 pixels
- **Icon-192.png**: 192x192 pixels (Android)
- **Icon-512.png**: 512x512 pixels (Android, PWA)
- **Icon-maskable-192.png**: 192x192 pixels (maskable)
- **Icon-maskable-512.png**: 512x512 pixels (maskable)

### iOS
- Multiple sizes needed (already configured in ios/Runner/Assets.xcassets/)
- From 20x20 to 1024x1024 pixels

### Android
- Multiple densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- Configured in android/app/src/main/res/

### Windows
- Icon in windows/runner/resources/app_icon.ico
- Multiple sizes (16x16 to 256x256)

## Current Icons

The project currently uses default Flutter icons. These are functional but should be replaced with custom GitFolio branding.

## Generating Custom Icons

### Option 1: Online Tools
- [Favicon.io](https://favicon.io/) - Free favicon generator
- [App Icon Generator](https://appicon.co/) - Multi-platform icon generator
- [RealFaviconGenerator](https://realfavicongenerator.net/) - Comprehensive generator

### Option 2: Using flutter_launcher_icons

1. Add to `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1

   flutter_launcher_icons:
     android: true
     ios: true
     web:
       generate: true
       image_path: "assets/icons/icon.png"
     windows:
       generate: true
       image_path: "assets/icons/icon.png"
   ```

2. Create source icon: `assets/icons/icon.png` (1024x1024)

3. Generate icons:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

## Design Guidelines

### Icon Design Tips
- **Simple**: Should work at small sizes
- **Recognizable**: Instantly identifiable as GitFolio
- **Consistent**: Matches brand colors (#58A6FF, #0D1117)
- **Professional**: Reflects developer portfolio theme

### Suggested Design Elements
- Code brackets: `< >`
- GitHub octocat silhouette
- Git branch icon
- Portfolio/briefcase symbol
- Combination of code + profile elements

### Color Scheme
- Primary: #58A6FF (GitHub blue)
- Background: #0D1117 (GitHub dark)
- Accent: #1F6FEB (GitHub blue variant)

## Quick Placeholder Icon

For immediate deployment, you can use:

1. **Text-based icon**: Use initials "GF" on colored background
2. **Emoji icon**: 💻 or 📂 or 🚀
3. **Default Flutter**: Keep current icons temporarily

## Creating Icon from Emoji (Quick Method)

1. Visit [Favicon.io](https://favicon.io/favicon-generator/)
2. Enter: 💻 or GF
3. Choose colors:
   - Background: #58A6FF
   - Text: #FFFFFF
4. Download and extract
5. Copy files to appropriate directories

## Production-Ready Icon Checklist

- [ ] Source icon created (1024x1024 PNG)
- [ ] Web favicons generated
- [ ] Android icons generated
- [ ] iOS icons generated  
- [ ] Windows icon generated
- [ ] Icons tested on all platforms
- [ ] PWA manifest icons updated
- [ ] Repository social preview image updated

## Notes

- Icons should be optimized (compressed) for web
- Test icons on different backgrounds (light/dark)
- Ensure sufficient contrast for accessibility
- Keep icon design consistent across platforms

---

**Current Status**: Using default Flutter icons. Replace before production launch or use as-is for MVP.
