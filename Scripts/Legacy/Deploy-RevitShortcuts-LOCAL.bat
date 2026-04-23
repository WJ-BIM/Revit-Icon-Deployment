@ECHO OFF
REM ============================================================================
REM REVIT CUSTOM SHORTCUTS DEPLOYMENT - BATCH FILE VERSION
REM For systems without PowerShell or as backup deployment method
REM Run as Administrator
REM ============================================================================

SETLOCAL ENABLEDELAYEDEXPANSION

ECHO.
ECHO ============================================================================
ECHO REVIT SHORTCUT DEPLOYMENT - BATCH VERSION
ECHO ============================================================================
ECHO.

REM Check for Administrator privileges
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: This script must be run as Administrator!
    ECHO Please right-click and select "Run as administrator"
    TIMEOUT /T 5
    EXIT /B 1
)

REM ============================================================================
REM CONFIGURATION
REM ============================================================================

SET "ICON_PATH=C:\RevitIcons"
SET "DESKTOP=%USERPROFILE%\Desktop"

REM Revit installation paths
SET "REVIT2023=C:\Program Files\Autodesk\Revit 2023\Revit.exe"
SET "REVIT2024=C:\Program Files\Autodesk\Revit 2024\Revit.exe"
SET "REVIT2025=C:\Program Files\Autodesk\Revit 2025\Revit.exe"
SET "REVIT2026=C:\Program Files\Autodesk\Revit 2026\Revit.exe"
SET "REVIT2027=C:\Program Files\Autodesk\Revit 2027\Revit.exe"

REM ============================================================================
REM STEP 1: VALIDATE ICON FOLDER
REM ============================================================================

ECHO [1/3] Validating icon files...
ECHO.

IF NOT EXIST "%ICON_PATH%" (
    ECHO ERROR: Icon path not found: %ICON_PATH%
    ECHO Please ensure icon files are in: %ICON_PATH%
    ECHO.
    ECHO Required files:
    ECHO   - Revit2023.ico
    ECHO   - Revit2024.ico
    ECHO   - Revit2025.ico
    ECHO   - Revit2026.ico
    ECHO   - Revit2027.ico
    ECHO.
    TIMEOUT /T 5
    EXIT /B 1
)

ECHO ✓ Icon folder found: %ICON_PATH%
ECHO.

REM ============================================================================
REM STEP 2: CREATE SHORTCUTS FOR EACH REVIT VERSION
REM ============================================================================

ECHO [2/3] Creating shortcuts...
ECHO.

SET "SHORTCUT_COUNT=0"

REM REVIT 2023
IF EXIST "%REVIT2023%" (
    CALL :CREATE_SHORTCUT "Revit 2023" "%REVIT2023%" "%ICON_PATH%\Revit2023.ico"
    SET /A SHORTCUT_COUNT+=1
    ECHO ✓ Revit 2023 shortcut created
) ELSE (
    ECHO ✗ Revit 2023 not found at: %REVIT2023%
)

REM REVIT 2024
IF EXIST "%REVIT2024%" (
    CALL :CREATE_SHORTCUT "Revit 2024" "%REVIT2024%" "%ICON_PATH%\Revit2024.ico"
    SET /A SHORTCUT_COUNT+=1
    ECHO ✓ Revit 2024 shortcut created
) ELSE (
    ECHO ✗ Revit 2024 not found at: %REVIT2024%
)

REM REVIT 2025
IF EXIST "%REVIT2025%" (
    CALL :CREATE_SHORTCUT "Revit 2025" "%REVIT2025%" "%ICON_PATH%\Revit2025.ico"
    SET /A SHORTCUT_COUNT+=1
    ECHO ✓ Revit 2025 shortcut created
) ELSE (
    ECHO ✗ Revit 2025 not found at: %REVIT2025%
)

REM REVIT 2026
IF EXIST "%REVIT2026%" (
    CALL :CREATE_SHORTCUT "Revit 2026" "%REVIT2026%" "%ICON_PATH%\Revit2026.ico"
    SET /A SHORTCUT_COUNT+=1
    ECHO ✓ Revit 2026 shortcut created
) ELSE (
    ECHO ✗ Revit 2026 not found at: %REVIT2026%
)

REM REVIT 2027
IF EXIST "%REVIT2027%" (
    CALL :CREATE_SHORTCUT "Revit 2027" "%REVIT2027%" "%ICON_PATH%\Revit2027.ico"
    SET /A SHORTCUT_COUNT+=1
    ECHO ✓ Revit 2027 shortcut created
) ELSE (
    ECHO ✗ Revit 2027 not found at: %REVIT2027%
)

ECHO.
ECHO Created %SHORTCUT_COUNT% shortcuts
ECHO.

REM ============================================================================
REM STEP 3: CLEAR ICON CACHE
REM ============================================================================

ECHO [3/3] Clearing Windows icon cache...
ECHO.

REM Kill Explorer
TASKKILL /F /IM explorer.exe >nul 2>&1
TIMEOUT /T 2

REM Delete icon cache
DEL /F /S "%LOCALAPPDATA%\IconCache.db" >nul 2>&1

REM Restart Explorer
START explorer.exe

REM ============================================================================
REM COMPLETION
REM ============================================================================

ECHO.
ECHO ============================================================================
ECHO DEPLOYMENT COMPLETE!
ECHO ============================================================================
ECHO.
ECHO Shortcuts created: %SHORTCUT_COUNT%
ECHO Desktop path: %DESKTOP%
ECHO Icon location: %ICON_PATH%
ECHO.
ECHO NEXT STEPS:
ECHO   1. Check Desktop for new shortcuts
ECHO   2. Verify custom icons are displaying
ECHO   3. Open each Revit version to test persistence
ECHO   4. If icons revert, use the PowerShell advanced fix script
ECHO.
TIMEOUT /T 10
GOTO :EOF

REM ============================================================================
REM FUNCTION: CREATE_SHORTCUT
REM ============================================================================

:CREATE_SHORTCUT
SETLOCAL

SET "SHORTCUT_NAME=%~1"
SET "TARGET_PATH=%~2"
SET "ICON_PATH=%~3"
SET "SHORTCUT_FILE=%DESKTOP%\%SHORTCUT_NAME%.lnk"

REM Create shortcut using VBScript (more compatible than PowerShell)
(
    ECHO Set oWS = WScript.CreateObject("WScript.Shell"^)
    ECHO sLinkFile = "%SHORTCUT_FILE%"
    ECHO Set oLink = oWS.CreateShortcut(sLinkFile^)
    ECHO oLink.TargetPath = "%TARGET_PATH%"
    ECHO oLink.WorkingDirectory = "%TEMP%"
    ECHO oLink.Description = "Autodesk %SHORTCUT_NAME%"
    IF EXIST "%ICON_PATH%" (
        ECHO oLink.IconLocation = "%ICON_PATH%,0"
    ) ELSE (
        ECHO oLink.IconLocation = "%TARGET_PATH%,0"
    )
    ECHO oLink.WindowStyle = 1
    ECHO oLink.Save
) > "%TEMP%\CreateShortcut.vbs"

CSCRIPT.EXE "%TEMP%\CreateShortcut.vbs" >nul 2>&1

DEL "%TEMP%\CreateShortcut.vbs" >nul 2>&1

ENDLOCAL
EXIT /B

REM ============================================================================
REM END OF SCRIPT
REM ============================================================================
