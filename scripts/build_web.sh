#!/bin/bash

# GitFolio Web Build Script
# Builds the Flutter web application with optimizations

echo "🚀 Building GitFolio for Web..."
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run code generation (if needed)
# echo "⚙️  Running code generation..."
# flutter pub run build_runner build --delete-conflicting-outputs

# Build for web with optimizations
echo "🔨 Building web application..."
flutter build web --release \
  --web-renderer canvaskit \
  --base-href "/" \
  --dart-define=FLUTTER_WEB_USE_SKIA=true

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📁 Output directory: build/web"
    echo ""
    echo "To test locally, run:"
    echo "  cd build/web"
    echo "  python -m http.server 8000"
    echo "  # Or use any static file server"
    echo ""
    echo "To deploy:"
    echo "  - Upload the build/web directory to your hosting service"
    echo "  - Configure GitHub OAuth callback URLs"
    echo "  - Update AppConstants with production credentials"
else
    echo ""
    echo "❌ Build failed! Check the errors above."
    exit 1
fi
