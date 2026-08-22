@echo off
echo ================================================
echo  CampusCore Admin Dashboard
echo ================================================
echo.
echo When ready, open Chrome and go to:
echo   http://localhost:3081
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
call flutter run -d web-server --web-port 3081 --web-hostname localhost

pause
