@echo off
echo ================================================
echo  CampusCore Mobile App (Web)
echo ================================================
echo.
echo When the app is ready, open Chrome and go to:
echo   http://localhost:3080
echo.
echo Press Ctrl+C to stop the server.
echo.

cd /d "C:\Users\USER\OneDrive\Documents\CampusCore\mobile_app"

if not exist "web\" (
  echo Setting up web support...
  call flutter create . --platforms web
)

echo Cleaning previous build...
call flutter clean

echo Getting packages...
call flutter pub get

echo Starting server...
call flutter run -d web-server --web-port 3080 --web-hostname localhost

pause
