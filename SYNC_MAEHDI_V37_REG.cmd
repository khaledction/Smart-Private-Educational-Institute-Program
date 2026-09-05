@echo off
setlocal

set "PROJECT=E:\projects\Smart-Private-Educational-Institute-Program"
set "DESKTOP_MIRROR=%USERPROFILE%\Desktop\Smart-Private-Educational-Institute-Program"
set "DOWNLOADS=%USERPROFILE%\Downloads"
set "TEMP_DIR=%TEMP%\maehdi_sync_v37"
set "ZIP="

if exist "%DOWNLOADS%\maehdi_sync_all_v37_registration_db.zip" set "ZIP=%DOWNLOADS%\maehdi_sync_all_v37_registration_db.zip"
if not defined ZIP if exist "%DOWNLOADS%\maehdi_sync_all_v37_registration_db_b.zip" set "ZIP=%DOWNLOADS%\maehdi_sync_all_v37_registration_db_b.zip"

echo == Check files ==
if not defined ZIP (
  echo Project zip not found in Downloads.
  exit /b 1
)
if not exist "%PROJECT%" (
  echo Project folder not found.
  exit /b 1
)

echo == Extract zip ==
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path '%TEMP_DIR%') { Remove-Item -LiteralPath '%TEMP_DIR%' -Recurse -Force }; New-Item -ItemType Directory -Path '%TEMP_DIR%' ^| Out-Null; Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%TEMP_DIR%' -Force"
if errorlevel 1 exit /b 1

echo == Sync local project ==
xcopy "%TEMP_DIR%\*" "%PROJECT%\" /E /I /Y >nul
if errorlevel 1 exit /b 1

if exist "%DESKTOP_MIRROR%" (
  echo == Sync desktop mirror ==
  xcopy "%TEMP_DIR%\*" "%DESKTOP_MIRROR%\" /E /I /Y >nul
)

echo == Quick verify ==
findstr /n /c:"v3.7" "%PROJECT%\flutter_app\lib\main.dart"
findstr /n /c:"sqflite_common_ffi" "%PROJECT%\flutter_app\pubspec.yaml"
findstr /n /c:"RegistrationStore" "%PROJECT%\flutter_app\lib\screens\registration.dart"

echo == Flutter packages ==
cd /d "%PROJECT%\flutter_app"
flutter pub get
if errorlevel 1 exit /b 1

echo == Run app ==
echo flutter run -d windows

echo == Git sync ==
cd /d "%PROJECT%"
if exist ".git" (
  git status
  git add .
  git commit -m v37-registration-db
  if not errorlevel 1 git push
) else (
  echo This folder is not a git repo. Skipped git sync.
)

echo == Done ==
endlocal
