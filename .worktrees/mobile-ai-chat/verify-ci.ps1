# CampusCore CI Verification Script (PowerShell)
# Run this before pushing to GitHub to catch issues early

Write-Host "======================================"
Write-Host "CampusCore CI Verification"
Write-Host "======================================"
Write-Host ""

$ErrorActionPreference = "Stop"

try {
    # Backend checks
    Write-Host "[1/12] Backend: Lint..."
    Set-Location backend
    npm run lint
    Write-Host "[OK] Lint passed"
    Write-Host ""

    Write-Host "[2/12] Backend: Build..."
    npm run build
    Write-Host "[OK] Build passed"
    Write-Host ""

    Write-Host "[3/12] Backend: Tests..."
    npm test -- --passWithNoTests
    Write-Host "[OK] Tests passed"
    Write-Host ""
    Set-Location ..

    # Mobile app
    Write-Host "[4/12] Mobile App: Dependencies..."
    Set-Location mobile_app
    flutter pub get
    Write-Host "[OK] Dependencies resolved"
    Write-Host ""

    Write-Host "[5/12] Mobile App: Analyze..."
    flutter analyze
    Write-Host "[OK] Analyze passed"
    Write-Host ""

    Write-Host "[6/12] Mobile App: Tests..."
    flutter test
    Write-Host "[OK] Tests passed"
    Write-Host ""
    Set-Location ..

    # Admin dashboard
    Write-Host "[7/12] Admin Dashboard: Dependencies..."
    Set-Location admin_dashboard
    flutter pub get
    Write-Host "[OK] Dependencies resolved"
    Write-Host ""

    Write-Host "[8/12] Admin Dashboard: Analyze..."
    flutter analyze
    Write-Host "[OK] Analyze passed"
    Write-Host ""

    Write-Host "[9/12] Admin Dashboard: Tests..."
    flutter test
    Write-Host "[OK] Tests passed"
    Write-Host ""
    Set-Location ..

    # Web app
    Write-Host "[10/12] Web App: Dependencies..."
    Set-Location web_app
    flutter pub get
    Write-Host "[OK] Dependencies resolved"
    Write-Host ""

    Write-Host "[11/12] Web App: Analyze..."
    flutter analyze
    Write-Host "[OK] Analyze passed"
    Write-Host ""

    Write-Host "[12/12] Web App: Tests..."
    flutter test
    Write-Host "[OK] Tests passed"
    Write-Host ""
    Set-Location ..

    Write-Host ""
    Write-Host "======================================"
    Write-Host "SUCCESS: ALL CHECKS PASSED!"
    Write-Host "Safe to push to GitHub"
    Write-Host "======================================"
}
catch {
    Write-Host ""
    Write-Host "FAILED: VERIFICATION ERROR"
    Write-Host "Error: $_"
    Write-Host "======================================"
    exit 1
}
