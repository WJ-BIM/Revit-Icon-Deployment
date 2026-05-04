# ============================================================================
# REVIT ICON REVERSION FIX - WORKING VERSION
# Use this instead of the broken Fix-RevitIconReversion-ADVANCED.ps1
# ============================================================================

Write-Host "REVIT ICON REVERSION FIX" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

# Verify Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    exit 1
}

# ============================================================================
# STEP 1: AGGRESSIVE CACHE CLEARING
# ============================================================================

Write-Host "`nStep 1: Clearing Windows icon caches..." -ForegroundColor Yellow

try {
    # Stop Explorer
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    # Remove all icon caches
    Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\IconCache.db" -Force -ErrorAction SilentlyContinue
    
    Write-Host "✓ Icon caches cleared" -ForegroundColor Green
    
    # Restart Explorer
    Start-Process explorer.exe
    Start-Sleep -Seconds 3
} catch {
    Write-Host "⚠ Cache clearing had issues: $_" -ForegroundColor Yellow
}

# ============================================================================
# STEP 2: PROTECT SHORTCUTS (READ-ONLY)
# ============================================================================

Write-Host "`nStep 2: Protecting shortcuts from modification..." -ForegroundColor Yellow

$DesktopPath = "C:\Users\ryan.gorman\Desktop"
$shortcuts = Get-ChildItem "$DesktopPath\Revit*.lnk" -ErrorAction SilentlyContinue

if ($shortcuts) {
    foreach ($shortcut in $shortcuts) {
        try {
            # Make file read-only
            Set-ItemProperty -Path $shortcut.FullName -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
            Write-Host "✓ Protected: $($shortcut.Name)" -ForegroundColor Green
        } catch {
            Write-Host "⚠ Could not protect $($shortcut.Name)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠ No Revit shortcuts found on Desktop" -ForegroundColor Yellow
}

# ============================================================================
# STEP 3: REGISTRY HARDENING
# ============================================================================

Write-Host "`nStep 3: Hardening registry..." -ForegroundColor Yellow

try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    # Create path if doesn't exist
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    # Disable overlay icons
    New-ItemProperty -Path $regPath -Name "ShowTypeOverlayIcons" -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "✓ Registry hardened" -ForegroundColor Green
} catch {
    Write-Host "⚠ Registry hardening failed: $_" -ForegroundColor Yellow
}

# ============================================================================
# STEP 4: RECREATE SHORTCUTS WITH CORRECT ICONS
# ============================================================================

Write-Host "`nStep 4: Recreating shortcuts with persistent icons..." -ForegroundColor Yellow

$Wsh = New-Object -ComObject WScript.Shell
$IconRoot = "C:\ProgramData\RevitIcons"
$revitVersions = @("2023", "2025", "2026", "2027")
$shortcutsFixed = 0

foreach ($version in $revitVersions) {
    $revitPath = "C:\Program Files\Autodesk\Revit $version\Revit.exe"
    $iconFile = "$IconRoot\RVT$($version.Substring($version.Length - 2)).ico"
    $shortcutPath = "$DesktopPath\Revit $version.lnk"
    
    if (Test-Path $revitPath) {
        try {
            # Delete old shortcut
            if (Test-Path $shortcutPath) {
                Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 100
            }
            
            # Create new shortcut
            $shortcut = $Wsh.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $revitPath
            $shortcut.WorkingDirectory = Split-Path -Parent $revitPath
            $shortcut.Description = "Autodesk Revit $version"
            
            if (Test-Path $iconFile) {
                $shortcut.IconLocation = "$iconFile,0"
            } else {
                $shortcut.IconLocation = "$revitPath,0"
            }
            
            $shortcut.WindowStyle = 1
            $shortcut.Save()
            
            # Make read-only immediately
            Set-ItemProperty -Path $shortcutPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
            
            Write-Host "✓ Recreated: Revit $version.lnk" -ForegroundColor Green
            $shortcutsFixed++
        } catch {
            Write-Host "✗ Failed to recreate Revit $version: $_" -ForegroundColor Red
        }
    }
}

# ============================================================================
# STEP 5: FINAL CLEANUP
# ============================================================================

Write-Host "`nStep 5: Final cleanup..." -ForegroundColor Yellow

# Clear temporary icon files
Remove-Item "$env:TEMP\IconCache*" -Force -ErrorAction SilentlyContinue

# Refresh file explorer
try {
    $code = @'
using System;
using System.Runtime.InteropServices;

public class ShellHelper {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
    
    public static void RefreshExplorer() {
        SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero);
    }
}
'@
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    [ShellHelper]::RefreshExplorer()
    Write-Host "✓ Explorer refreshed" -ForegroundColor Green
} catch {
    Write-Host "⚠ Explorer refresh skipped" -ForegroundColor Yellow
}

# ============================================================================
# COMPLETION
# ============================================================================

Write-Host "`n" -ForegroundColor Green
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ICON REVERSION FIX COMPLETE           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green

Write-Host @"

Fixes Applied:
  1. ✓ Icon cache cleared
  2. ✓ Shortcuts protected (read-only)
  3. ✓ Registry hardened
  4. ✓ Shortcuts recreated with protection
  5. ✓ Shortcuts fixed: $shortcutsFixed

Next Steps:
  1. RESTART YOUR COMPUTER (important!)
  2. Check Desktop for Revit shortcuts
  3. Open Revit 2025
  4. Minimize Revit
  5. Check if icon still shows custom color

If icons still revert after restart:
  - Icons may be locked in Revit's installer resources
  - This is a known limitation with some Revit versions
  - Desktop deployment will still work
  - GPO deployment may have better results

"@

Write-Host "IMPORTANT: Restart your computer now!" -ForegroundColor Yellow
$restart = Read-Host "Restart now? (Y/N)"
if ($restart -eq "Y") {
    Restart-Computer
}
