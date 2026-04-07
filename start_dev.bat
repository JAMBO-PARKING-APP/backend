@echo off
setlocal enabledelayedexpansion
echo Starting Jambo Park Development Environment...

REM --- Redis Setup ---
echo Starting Redis...
set "REDIS_EXE=C:\Program Files\Redis\redis-server.exe"
where redis-server >nul 2>nul
if %errorlevel% == 0 (
    echo [INFO] redis-server found in PATH.
    start "Redis Server" redis-server
) else (
    echo [WARNING] redis-server not found in PATH.
    if exist "%REDIS_EXE%" (
        echo [INFO] Found Redis at %REDIS_EXE%
        start "Redis Server" "%REDIS_EXE%"
    ) else if exist "C:\Program Files\Memurai\memurai.exe" (
        echo [INFO] Found Memurai at C:\Program Files\Memurai\memurai.exe
        start "Redis Server" "C:\Program Files\Memurai\memurai.exe"
    ) else (
        echo [ERROR] Redis not found. Please ensure Redis is installed.
    )
)

timeout /t 3

REM --- Celery Setup ---
echo Starting Celery Worker...
REM Using 'solo' pool for Windows/Python 3.14 compatibility (gevent has DLL issues)
start "Celery Worker" cmd /k "venv\Scripts\python.exe -m celery -A config worker --loglevel=info -P solo"

echo Starting Celery Beat...
start "Celery Beat" cmd /k "venv\Scripts\python.exe -m celery -A config beat --loglevel=info"

REM --- Ngrok Setup ---
echo Starting Ngrok Tunnel...
set "NGROK_EXE=C:\Users\callc\AppData\Local\Microsoft\WinGet\Packages\Ngrok.Ngrok_Microsoft.Winget.Source_8wekyb3d8bbwe\ngrok.exe"
where ngrok >nul 2>nul
if %errorlevel% == 0 (
    echo [INFO] ngrok found in PATH.
    start "Ngrok Tunnel" ngrok http --domain=curtis-unmobilized-clarence.ngrok-free.dev 8000
) else (
    echo [WARNING] ngrok not found in PATH.
    if exist "%NGROK_EXE%" (
        echo [INFO] Found Ngrok at %NGROK_EXE%
        start "Ngrok Tunnel" "%NGROK_EXE%" http --domain=curtis-unmobilized-clarence.ngrok-free.dev 8000
    ) else (
        echo [ERROR] Ngrok not found in common winget path.
    )
)

REM --- Django Setup ---
echo Starting Django Server with Daphne...
venv\Scripts\python.exe -m daphne config.asgi:application --bind 0.0.0.0 --port 8000

pause
