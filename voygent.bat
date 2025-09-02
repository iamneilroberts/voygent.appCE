@echo off
REM VoygentCE Launcher Script for Windows
REM Simple command to start, stop, and manage VoygentCE services

setlocal enabledelayedexpansion

cd /d "%~dp0"

REM Colors for output (limited support in Windows)
set "GREEN=[32m"
set "RED=[31m"
set "YELLOW=[33m"
set "BLUE=[34m"
set "NC=[0m"

REM Show usage
if "%1"=="help" goto :show_usage
if "%1"=="--help" goto :show_usage
if "%1"=="-h" goto :show_usage

REM Default to start if no command given
if "%1"=="" goto :start_services
if "%1"=="start" goto :start_services
if "%1"=="stop" goto :stop_services
if "%1"=="restart" goto :restart_services
if "%1"=="status" goto :show_status
if "%1"=="logs" goto :show_logs
if "%1"=="setup" goto :run_setup
if "%1"=="update" goto :update_services
if "%1"=="clean" goto :clean_services
if "%1"=="health" goto :check_health

echo %RED%❌ Unknown command: %1%NC%
echo.
goto :show_usage

:show_usage
echo VoygentCE - AI-powered travel planning assistant
echo.
echo Usage: %0 [COMMAND]
echo.
echo Commands:
echo   start          Start VoygentCE services (default)
echo   stop           Stop all VoygentCE services
echo   restart        Restart all services
echo   status         Show service status
echo   logs           Show service logs
echo   setup          Run initial setup
echo   update         Update services and rebuild
echo   clean          Stop services and clean up volumes
echo   health         Check service health
echo.
echo Examples:
echo   %0              # Start services
echo   %0 start        # Start services
echo   %0 logs         # Show logs
echo   %0 stop         # Stop services
echo.
goto :eof

:check_docker
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%❌ Docker is not running. Please start Docker Desktop first.%NC%
    exit /b 1
)
goto :eof

:check_health
echo %BLUE%ℹ️  Checking VoygentCE service health...%NC%

REM Check if containers are running
docker-compose ps | findstr "Up" >nul
if %errorlevel% neq 0 (
    echo %YELLOW%⚠️  Services are not running. Use '%0 start' to start them.%NC%
    goto :eof
)

REM Check LibreChat health
curl -sf http://localhost:3080 >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✅ LibreChat is healthy (http://localhost:3080)%NC%
) else (
    echo %YELLOW%⚠️  LibreChat may not be fully started yet%NC%
)

REM Check MeiliSearch
curl -sf http://localhost:7700/health >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✅ MeiliSearch is healthy (http://localhost:7700)%NC%
) else (
    echo %YELLOW%⚠️  MeiliSearch may not be ready%NC%
)

goto :eof

:start_services
echo %BLUE%ℹ️  Starting VoygentCE services...%NC%
call :check_docker
if %errorlevel% neq 0 goto :eof

REM Check if .env file exists
if not exist ".env" (
    echo %RED%❌ .env file not found. Running setup first...%NC%
    call scripts\setup.sh
)

REM Start services
if exist "scripts\start-services.sh" (
    bash scripts/start-services.sh
) else (
    docker-compose up -d
    echo %BLUE%ℹ️  Waiting for services to start...%NC%
    timeout /t 10 >nul
)

REM Check health
call :check_health

echo %GREEN%✅ VoygentCE is ready!%NC%
echo.
echo 🌐 Access your services:
echo    • LibreChat UI:    http://localhost:3080
echo    • MeiliSearch:     http://localhost:7700
echo.
echo %BLUE%ℹ️  Create an account in LibreChat and start planning trips!%NC%
goto :eof

:stop_services
echo %BLUE%ℹ️  Stopping VoygentCE services...%NC%
docker-compose down
echo %GREEN%✅ VoygentCE services stopped%NC%
goto :eof

:restart_services
echo %BLUE%ℹ️  Restarting VoygentCE services...%NC%
docker-compose restart
echo %GREEN%✅ VoygentCE services restarted%NC%

echo %BLUE%ℹ️  Waiting for services to be ready...%NC%
timeout /t 10 >nul
call :check_health
goto :eof

:show_status
echo %BLUE%ℹ️  VoygentCE service status:%NC%
echo.
docker-compose ps
echo.

echo %BLUE%ℹ️  Service endpoints:%NC%
echo    • LibreChat UI:    http://localhost:3080
echo    • MeiliSearch:     http://localhost:7700
docker-compose ps | findstr "orchestrator" >nul
if %errorlevel% equ 0 (
    echo    • Orchestrator API: http://localhost:3000
)
echo.
goto :eof

:show_logs
if "%2"=="" (
    echo %BLUE%ℹ️  Showing logs for all services (Ctrl+C to exit)...%NC%
    docker-compose logs -f
) else (
    echo %BLUE%ℹ️  Showing logs for %2...%NC%
    docker-compose logs -f %2
)
goto :eof

:run_setup
echo %BLUE%ℹ️  Running VoygentCE setup...%NC%
bash scripts/setup.sh
goto :eof

:update_services
echo %BLUE%ℹ️  Updating VoygentCE services...%NC%

REM Pull latest images
docker-compose pull

REM Rebuild if needed
docker-compose build

REM Restart services
call :restart_services

echo %GREEN%✅ VoygentCE services updated%NC%
goto :eof

:clean_services
echo %YELLOW%⚠️  This will stop services and remove volumes (data will be lost!)%NC%
set /p "confirm=Are you sure? (y/N): "
if /i "!confirm!"=="y" (
    echo %BLUE%ℹ️  Cleaning up VoygentCE...%NC%
    docker-compose down -v
    docker system prune -f
    echo %GREEN%✅ VoygentCE cleaned up%NC%
) else (
    echo %BLUE%ℹ️  Clean up cancelled%NC%
)
goto :eof

:eof