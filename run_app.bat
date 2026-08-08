@echo off
echo Starting CampusCore Web App...
echo.
echo When the app is ready, open Chrome and go to:
echo http://localhost:8080
echo.
echo Press Ctrl+C to stop.
echo.
cd /d "C:\Users\USER\Documents\CampusCore\mobile_app"
flutter run -d web-server --web-port 8080 --web-hostname localhost
pause
