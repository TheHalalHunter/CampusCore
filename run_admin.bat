@echo off
echo Starting CampusCore Admin Dashboard...
echo.
echo When ready, open Chrome and go to:
echo http://localhost:8081
echo.
echo Press Ctrl+C to stop.
echo.
cd /d "C:\Users\USER\Documents\CampusCore\admin_dashboard"
flutter create . --platforms web 2>nul
flutter pub get
flutter run -d web-server --web-port 8081 --web-hostname localhost
pause
