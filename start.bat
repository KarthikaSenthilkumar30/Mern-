@echo off
echo ========================================================
echo   Starting DocuManage AI - Placement Ready Project
echo ========================================================
echo.

echo [1/3] Checking dependencies...
if not exist "backend\node_modules" (
    echo Installing backend dependencies...
    cd backend && npm install && cd ..
)
if not exist "frontend\node_modules" (
    echo Installing frontend dependencies...
    cd frontend && npm install && cd ..
)

echo [2/3] Starting Backend Server on http://localhost:5000 ...
start "DocuManage Backend" cmd /k "cd backend && npm run dev"

timeout /t 3 /nobreak >nul

echo [3/3] Starting Frontend Vite App on http://localhost:5173 ...
start "DocuManage Frontend" cmd /k "cd frontend && npm run dev"

echo.
echo ========================================================
echo   Application Launched!
echo   Frontend UI:      http://localhost:5173
echo   Backend Server:   http://localhost:5000
echo   Swagger API Docs: http://localhost:5000/api-docs
echo ========================================================
pause
