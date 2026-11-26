@echo off
echo ================================================
echo  CampusCore Admin Dashboard
echo ================================================
echo.
echo When ready, open Chrome and go to:
echo   http://localhost:5081
echo.
echo Backend API: https://campuscore-production-3f94.up.railway.app/api/v1
echo.
echo Press Ctrl+C to stop the server.
echo.

cd /d "C:\Users\USER\OneDrive\Documents\CampusCore\admin_dashboard"

if not exist "web\" (
  echo Setting up web support...
  call flutter create . --platforms web
)

echo Cleaning previous build...
call flutter clean

echo Getting packages...
call flutter pub get

echo Starting server...
call flutter run -d web-server --web-port 5081 --web-hostname localhost --dart-define=API_BASE_URL=https://campuscore-production-3f94.up.railway.app/api/v1

pause
