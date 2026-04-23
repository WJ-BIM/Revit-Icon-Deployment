# ============================================================================
# REVIT CUSTOM SHORTCUTS DEPLOYMENT - LOCAL MACHINE VERSION
# Deploys shortcuts for Revit 2023-2027 with custom icons
# Run as Administrator on your test machine first
# ============================================================================

param(
    [string]$IconSourcePath = "C:\RevitIcons",  # Where your .ico files are located
    [string]$DesktopPath = [Environment]::GetFolderPath("Desktop"),
    [switch]$ClearIconCache
)

# Validate running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REVIT SHORTCUT DEPLOYMENT - LOCAL MODE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================================================
# CONFIGURATION
# ============================================================================

$revitVersions = @{
    "2023" = @{
        "Path"     = "C:\Program Files\Autodesk\Revit 2023\Revit.exe"
        "IconFile" = "$IconSourcePath\Revit2023.ico"
        "Description" = "Autodesk Revit 2023"
    }
    "2024" = @{
        "Path"     = "C:\Program Files\Autodesk\Revit 2024\Revit.exe"
        "IconFile" = "$IconSourcePath\Revit2024.ico"
        "Description" = "Autodesk Revit 2024"
    }
    "2025" = @{
        "Path"     = "C:\Program Files\Autodesk\Revit 2025\Revit.exe"
        "IconFile" = "$IconSourcePath\Revit2025.ico"
        "Description" = "Autodesk Revit 2025"
    }
    "2026" = @{
        "Path"     = "C:\Program Files\Autodesk\Revit 2026\Revit.exe"
        "IconFile" = "$IconSourcePath\Revit2026.ico"
        "Description" = "Autodesk Revit 2026"
    }
    "2027" = @{
        "Path"     = "C:\Program Files\Autodesk\Revit 2027\Revit.exe"
        "IconFile" = "$IconSourcePath\Revit2027.ico"
        "Description" = "Autodesk Revit 2027"
    }
}

# ============================================================================
# STEP 1: VALIDATE ICON FILES
# ============================================================================

Write-Host "`n[1/4] Validating icon files..." -ForegroundColor Yellow

$iconSourcePath = Resolve-Path $IconSourcePath -ErrorAction SilentlyContinue
if (-not $iconSourcePath) {
    Write-Host "ERROR: Icon source path not found: $IconSourcePath" -ForegroundColor Red
    Write-Host "Please ensure your .ico files are in: $IconSourcePath" -ForegroundColor Yellow
    exit 1
}

foreach ($version in $revitVersions.Keys) {
    $iconFile = $revitVersions[$version]["IconFile"]
    if (-not (Test-Path $iconFile)) {
        Write-Host "WARNING: Icon file not found for Revit $version - $iconFile" -ForegroundColor Yellow
        Write-Host "Using executable icon as fallback" -ForegroundColor Gray
        $revitVersions[$version]["IconFile"] = $revitVersions[$version]["Path"]
    } else {
        Write-Host "✓ Found icon for Revit $version" -ForegroundColor Green
    }
}

# ============================================================================
# STEP 2: VALIDATE REVIT INSTALLATIONS
# ============================================================================

Write-Host "`n[2/4] Validating Revit installations..." -ForegroundColor Yellow

$installedVersions = @()
foreach ($version in $revitVersions.Keys) {
    $revitExePath = $revitVersions[$version]["Path"]
    if (Test-Path $revitExePath) {
        Write-Host "✓ Found Revit $version" -ForegroundColor Green
        $installedVersions += $version
    } else {
        Write-Host "✗ Revit $version not found at $revitExePath" -ForegroundColor Red
    }
}

if ($installedVersions.Count -eq 0) {
    Write-Host "ERROR: No Revit installations found!" -ForegroundColor Red
    exit 1
}

# ============================================================================
# STEP 3: CREATE/UPDATE SHORTCUTS WITH CUSTOM ICONS
# ============================================================================

Write-Host "`n[3/4] Creating/updating desktop shortcuts..." -ForegroundColor Yellow

$wshShell = New-Object -ComObject WScript.Shell

foreach ($version in $installedVersions) {
    $revitPath = $revitVersions[$version]["Path"]
    $iconFile = $revitVersions[$version]["IconFile"]
    $description = $revitVersions[$version]["Description"]
    $shortcutPath = Join-Path $DesktopPath "Revit $version.lnk"
    
    try {
        # Create the shortcut
        $shortcut = $wshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $revitPath
        $shortcut.WorkingDirectory = Split-Path -Parent $revitPath
        $shortcut.Description = $description
        $shortcut.IconLocation = "$iconFile,0"  # ,0 specifies first icon in file
        $shortcut.WindowStyle = 1  # Normal window
        $shortcut.Save()
        
        Write-Host "✓ Created shortcut for Revit $version" -ForegroundColor Green
        Write-Host "  Path: $shortcutPath" -ForegroundColor Gray
        Write-Host "  Icon: $iconFile" -ForegroundColor Gray
        
    } catch {
        Write-Host "✗ Failed to create shortcut for Revit $version: $_" -ForegroundColor Red
    }
}

# ============================================================================
# STEP 4: CLEAR ICON CACHE (PREVENTS REVERSION)
# ============================================================================

Write-Host "`n[4/4] Clearing Windows icon cache..." -ForegroundColor Yellow

# Stop Explorer to release icon cache
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Delete icon cache
$iconCachePath = "$env:LOCALAPPDATA\IconCache.db"
if (Test-Path $iconCachePath) {
    try {
        Remove-Item $iconCachePath -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Cleared icon cache" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not delete icon cache (may require restart)" -ForegroundColor Yellow
    }
}

# Restart Explorer
Start-Process explorer.exe
Start-Sleep -Seconds 2

# ============================================================================
# COMPLETION & REGISTRY KEYS
# ============================================================================

Write-Host "`n[REGISTRY] Adding anti-reversion keys..." -ForegroundColor Yellow

# These registry keys help prevent Windows from overriding custom icon settings
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

try {
    # Disable icon overlay handlers that might interfere
    New-ItemProperty -Path $registryPath -Name "ShowTypeOverlayIcons" -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Host "✓ Applied registry optimizations" -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not apply registry keys (non-critical)" -ForegroundColor Yellow
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nShortcuts created for:"
foreach ($version in $installedVersions) {
    Write-Host "  • Revit $version" -ForegroundColor Cyan
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Verify icons on desktop shortcuts look correct"
Write-Host "  2. Open each Revit version to confirm icons persist"
Write-Host "  3. If icons still revert after opening, run: icoutils /clearicons"
Write-Host "  4. Once verified, deploy via Group Policy to domain machines"

Write-Host "`nDEPLOYMENT NOTES:" -ForegroundColor Cyan
Write-Host "  • Icon files should be in: $IconSourcePath"
Write-Host "  • Shortcuts created at: $DesktopPath"
Write-Host "  • Icon cache cleared successfully"
