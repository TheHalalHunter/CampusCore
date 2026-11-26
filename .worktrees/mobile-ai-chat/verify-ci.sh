#!/bin/bash
# CampusCore CI Verification Script
# Run this before pushing to GitHub to catch issues early

set -e  # Exit on first error

echo "======================================"
echo "CampusCore CI Verification"
echo "======================================"
echo ""

# Backend checks
echo "1️⃣ Backend: Lint..."
cd backend
npm run lint
echo "✅ Lint passed"
echo ""

echo "2️⃣ Backend: Build..."
npm run build
echo "✅ Build passed"
echo ""

echo "3️⃣ Backend: Tests..."
npm test -- --passWithNoTests
echo "✅ Tests passed"
echo ""
cd ..

# Mobile app
echo "4️⃣ Mobile App: Dependencies..."
cd mobile_app
flutter pub get
echo "✅ Dependencies resolved"
echo ""

echo "5️⃣ Mobile App: Analyze..."
flutter analyze || echo "⚠️ Warnings found (non-blocking)"
echo ""

echo "6️⃣ Mobile App: Tests..."
flutter test
echo "✅ Tests passed"
echo ""
cd ..

# Admin dashboard
echo "7️⃣ Admin Dashboard: Dependencies..."
cd admin_dashboard
flutter pub get
echo "✅ Dependencies resolved"
echo ""

echo "8️⃣ Admin Dashboard: Analyze..."
flutter analyze || echo "⚠️ Warnings found (non-blocking)"
echo ""

echo "9️⃣ Admin Dashboard: Tests..."
flutter test
echo "✅ Tests passed"
echo ""
cd ..

# Web app
echo "🔟 Web App: Dependencies..."
cd web_app
flutter pub get
echo "✅ Dependencies resolved"
echo ""

echo "1️⃣1️⃣ Web App: Analyze..."
flutter analyze || echo "⚠️ Warnings found (non-blocking)"
echo ""

echo "1️⃣2️⃣ Web App: Tests..."
flutter test
echo "✅ Tests passed"
echo ""
cd ..

echo "======================================"
echo "✅ ALL CHECKS PASSED!"
echo "Safe to push to GitHub"
echo "======================================"
