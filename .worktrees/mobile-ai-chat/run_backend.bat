@echo off
echo ================================================
echo  CampusCore Backend API
echo ================================================
echo.
echo API will be available at:
echo   http://localhost:3000/api/v1
echo.
echo Swagger docs at:
echo   http://localhost:3000/api/docs
echo.
echo NOTE: Make sure .env file is configured.
echo       See .env.example for required variables.
echo.
echo Press Ctrl+C to stop the server.
echo.

cd /d "C:\Users\USER\OneDrive\Documents\CampusCore\backend"

call npm run start:dev

pause
