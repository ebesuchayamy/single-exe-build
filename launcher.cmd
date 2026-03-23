@echo off
setlocal
set "APP_DIR=%LOCALAPPDATA%\__APP_DIRECTORY_NAME__"

if not exist "%APP_DIR%\__APP_EXECUTABLE_NAME__" (
  mkdir "%APP_DIR%" 2>nul
  tar -xf "%~dp0payload.zip" -C "%APP_DIR%"
)

start "" "%APP_DIR%\__APP_EXECUTABLE_NAME__"
endlocal
