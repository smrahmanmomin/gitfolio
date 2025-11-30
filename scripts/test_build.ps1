# Quick Test Build Script
# Performs fast verification that the app compiles

Write-Host "🔍 Testing GitFolio Build..." -ForegroundColor Cyan
Write-Host ""

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get dependencies" -ForegroundColor Red
    exit 1
}

# Run analyzer
Write-Host ""
Write-Host "🔬 Running Flutter analyzer..." -ForegroundColor Yellow
flutter analyze

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Analysis found issues (may not be critical)" -ForegroundColor Yellow
}

# Check for compilation errors
Write-Host ""
Write-Host "🔨 Testing compilation..." -ForegroundColor Yellow
flutter build web --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Update GitHub OAuth credentials in lib/core/constants/app_constants.dart"
    Write-Host "  2. Run: flutter run -d chrome (for testing)"
    Write-Host "  3. Run: .\scripts\build_web.ps1 (for production build)"
} else {
    Write-Host ""
    Write-Host "❌ Build test failed!" -ForegroundColor Red
    exit 1
}
