# GitFolio Web Build Script (PowerShell)
# Builds the Flutter web application with optimizations

Write-Host "🚀 Building GitFolio for Web..." -ForegroundColor Cyan
Write-Host ""

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Run code generation (if needed)
# Write-Host "⚙️  Running code generation..." -ForegroundColor Yellow
# flutter pub run build_runner build --delete-conflicting-outputs

# Build for web with optimizations
Write-Host "🔨 Building web application..." -ForegroundColor Yellow
flutter build web --release `
  --web-renderer canvaskit `
  --base-href "/" `
  --dart-define=FLUTTER_WEB_USE_SKIA=true

# Check if build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Output directory: build/web" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To test locally, run:" -ForegroundColor Cyan
    Write-Host "  cd build/web"
    Write-Host "  python -m http.server 8000"
    Write-Host "  # Or use: npx serve -s . -p 8000"
    Write-Host ""
    Write-Host "To deploy:" -ForegroundColor Cyan
    Write-Host "  - Upload the build/web directory to your hosting service"
    Write-Host "  - Configure GitHub OAuth callback URLs"
    Write-Host "  - Update AppConstants with production credentials"
} else {
    Write-Host ""
    Write-Host "❌ Build failed! Check the errors above." -ForegroundColor Red
    exit 1
}
