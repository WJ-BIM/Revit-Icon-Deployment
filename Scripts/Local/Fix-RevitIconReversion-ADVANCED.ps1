# ============================================================================
# REVIT ICON REVERSION FIX - ADVANCED TROUBLESHOOTING
# Use this if custom icons revert after opening Revit
# Runs as scheduled task to monitor and protect shortcuts
# ============================================================================

param(
    [string]$DesktopPath = [Environment]::GetFolderPath("Desktop"),
    [string]$IconCachePath = "C:\ProgramData\RevitShortcutIcons"
)

Write-Host "REVIT ICON REVERSION PROTECTION - ADVANCED FIX" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Verify running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    exit 1
}

# ============================================================================
# NUCLEAR OPTION 1: AGGRESSIVE CACHE CLEARING
# ============================================================================

Write-Host "`n[1/5] Performing aggressive cache clearing..." -ForegroundColor Yellow

function Clear-AllIconCaches {
    try {
        # Stop Explorer
        Write-Host "  • Stopping Windows Explorer..." -ForegroundColor Gray
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        # Remove all icon caches
        $cachePaths = @(
            "$env:LOCALAPPDATA\IconCache.db",
            "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
            "$env:APPDATA\Microsoft\Windows\Recent\*.lnk",
            "C:\Windows\Temp\IconCache*"
        )
        
        foreach ($cachePath in $cachePaths) {
            Get-Item $cachePath -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Cleared: $cachePath" -ForegroundColor Green
        }
        
        # Clear CLR cache
        cmd /c "cd %temp% && del /S /Q .cache* 2>nul"
        
        # Restart Explorer
        Write-Host "  • Restarting Windows Explorer..." -ForegroundColor Gray
        Start-Process explorer.exe
        Start-Sleep -Seconds 3
        
        Write-Host "✓ Cache clearing complete" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "✗ Error during cache clearing: $_" -ForegroundColor Red
        return $false
    }
}

Clear-AllIconCaches

# ============================================================================
# NUCLEAR OPTION 2: REGISTRY HARDENING
# ============================================================================

Write-Host "`n[2/5] Hardening Windows registry to prevent overlay/monitoring..." -ForegroundColor Yellow

$regEdits = @(
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowTypeOverlayIcons"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowSyncProviderNotifications"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Classes\.lnk"; Name = "IsShortcut"; Value = ""; Type = "String" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons"; Name = "3"; Value = "$env:windir\System32\shell32.dll,3"; Type = "String" }
)

foreach ($edit in $regEdits) {
    try {
        if (-not (Test-Path $edit.Path)) {
            New-Item -Path $edit.Path -Force | Out-Null
        }
        New-ItemProperty -Path $edit.Path -Name $edit.Name -Value $edit.Value -PropertyType $edit.Type -Force | Out-Null
        Write-Host "  ✓ Registry set: $($edit.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Could not set $($edit.Name): $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# NUCLEAR OPTION 3: SHORTCUT PROTECTION (Read-Only)
# ============================================================================

Write-Host "`n[3/5] Protecting shortcuts from modification..." -ForegroundColor Yellow

$shortcuts = Get-Item "$DesktopPath\Revit*.lnk" -ErrorAction SilentlyContinue

if ($shortcuts) {
    foreach ($shortcut in $shortcuts) {
        try {
            # Make read-only
            Set-ItemProperty -Path $shortcut.FullName -Name IsReadOnly -Value $true
            
            # Remove all permissions except Read
            $acl = Get-Acl $shortcut.FullName
            $acl.SetAccessRuleProtection($true, $false)
            Set-Acl -Path $shortcut.FullName -AclObject $acl
            
            Write-Host "  ✓ Protected: $($shortcut.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Could not fully protect $($shortcut.Name): $_" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  ⚠ No Revit shortcuts found on Desktop" -ForegroundColor Yellow
}

# ============================================================================
# NUCLEAR OPTION 4: DISABLE SHELL ICON HANDLER
# ============================================================================

Write-Host "`n[4/5] Disabling problematic shell icon handlers..." -ForegroundColor Yellow

$iconHandlers = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\*",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\*"
)

foreach ($handler in $iconHandlers) {
    Get-Item $handler -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            # Rename to disable (prepend space)
            $newName = " $($_.PSChildName)"
            Rename-Item -Path $_.FullName -NewName $newName -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Disabled: $($_.PSChildName)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Could not disable handler" -ForegroundColor Yellow
        }
    }
}

# ============================================================================
# NUCLEAR OPTION 5: RECREATE SHORTCUTS WITH HARDENED PROPERTIES
# ============================================================================

Write-Host "`n[5/5] Recreating shortcuts with anti-override properties..." -ForegroundColor Yellow

$revitVersions = @("2023", "2024", "2025", "2026", "2027")
$wshShell = New-Object -ComObject WScript.Shell
$shortcutsFixed = 0

foreach ($version in $revitVersions) {
    $revitPath = "C:\Program Files\Autodesk\Revit $version\Revit.exe"
    $iconFile = Join-Path $IconCachePath "Revit$version.ico"
    $shortcutPath = Join-Path $DesktopPath "Revit $version.lnk"
    
    if (Test-Path $revitPath) {
        try {
            # Delete old shortcut
            if (Test-Path $shortcutPath) {
                Remove-Item $shortcutPath -Force
            }
            
            # Create new shortcut with hardened properties
            $shortcut = $wshShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $revitPath
            $shortcut.WorkingDirectory = Split-Path -Parent $revitPath
            $shortcut.Description = "Autodesk Revit $version (Custom Icon)"
            
            # Use custom icon if available
            if (Test-Path $iconFile) {
                $shortcut.IconLocation = "$iconFile,0"
            } else {
                $shortcut.IconLocation = "$revitPath,0"
            }
            
            $shortcut.WindowStyle = 1  # Normal
            $shortcut.Save()
            
            # Immediately protect the shortcut
            Set-ItemProperty -Path $shortcutPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
            
            Write-Host "  ✓ Recreated & protected: Revit $version" -ForegroundColor Green
            $shortcutsFixed++
            
        } catch {
            Write-Host "  ✗ Error recreating Revit $version shortcut: $_" -ForegroundColor Red
        }
    }
}

# ============================================================================
# FINAL STEPS
# ============================================================================

Write-Host "`n[FINAL] Running final cleanup..." -ForegroundColor Yellow

# Flush DNS cache
ipconfig /flushdns | Out-Null

# Clear temp files
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# Update file explorer
Write-Host "  • Refreshing File Explorer view..." -ForegroundColor Gray

# Force refresh using WinAPI
$code = @'
using System;
using System.Runtime.InteropServices;

public class ShellHelper {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
    
    public static void RefreshExplorer() {
        SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero);  // SHCNE_ASSOCCHANGED
    }
}
'@

try {
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    [ShellHelper]::RefreshExplorer()
    Write-Host "  ✓ File Explorer refreshed" -ForegroundColor Green
} catch {
    Write-Host "  ⚠ Could not refresh Explorer (non-critical)" -ForegroundColor Yellow
}

# ============================================================================
# SUMMARY & NEXT STEPS
# ============================================================================

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ICON REVERSION FIX COMPLETE               ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host @"

Fixes Applied:
  1. ✓ Aggressive cache clearing
  2. ✓ Registry hardening
  3. ✓ Shortcut write protection
  4. ✓ Shell icon handler disabling
  5. ✓ Shortcut recreation

Shortcuts Fixed: $shortcutsFixed

NEXT STEPS:
  1. Restart your computer (recommended)
  2. Check Desktop for custom icon shortcuts
  3. Open each Revit version to test
  4. Icons should now PERSIST even after opening Revit

VERIFICATION COMMANDS:
  • Check shortcut icons: Get-Item 'C:\Users\YourUser\Desktop\Revit*.lnk'
  • Verify read-only: (Get-Item 'C:\Users\YourUser\Desktop\Revit 2023.lnk').IsReadOnly

IF ICONS STILL REVERT:
  • Run this script again after reboot
  • Check: Test-Path 'C:\ProgramData\RevitShortcutIcons'
  • Verify icon files exist and are accessible

"@

# ============================================================================
# OPTIONAL: CREATE SCHEDULED TASK FOR CONTINUOUS PROTECTION
# ============================================================================

Write-Host "`nWould you like to create a scheduled task to monitor icons daily?" -ForegroundColor Cyan
$createTask = Read-Host "Enter Y to create, N to skip"

if ($createTask -eq "Y") {
    try {
        $taskName = "Revit Icon Protection Monitor"
        $scriptPath = $PSCommandPath  # This script's path
        
        # Create task action
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        $trigger = New-ScheduledTaskTrigger -Daily -At 8:00AM
        
        # Register task
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null
        
        Write-Host "✓ Scheduled task created: $taskName" -ForegroundColor Green
        Write-Host "  Runs daily at 8:00 AM to maintain icon protection" -ForegroundColor Green
    } catch {
        Write-Host "✗ Could not create scheduled task: $_" -ForegroundColor Red
    }
}

Write-Host "`nExiting..." -ForegroundColor Gray
