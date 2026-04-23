# ============================================================================
# REVIT CUSTOM SHORTCUTS DEPLOYMENT - ENHANCED HYBRID VERSION
# Icon Naming Convention: RVT23.ico, RVT24.ico, etc (RVT + 2-digit year)
#
# Features:
#   - Dynamic Revit version detection (no hardcoding)
#   - Icons from GitHub repository (WJ-BIM/revit-deployment)
#   - Updates Start Menu + Desktop shortcuts
#   - Taskbar pin/unpin management
#   - Anti-reversion protections (cache clear, registry harden, read-only)
#   - One status line per year for automation
#
# Requirements:
#   - Run as Administrator
#   - GitHub access (public repo or valid PAT for private)
#   - Revit 2014+ installed (rolling window detection)
#
# References:
#   - https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
#   - https://www.bimpure.com/blog/revit-icons
#
# ============================================================================

param(
    [string]$GitHubToken = "",  # Leave empty for public repo, set PAT for private
    [string]$MinYear = 2014,    # Earliest Revit to check for
    [switch]$SkipTaskbar        # Set to skip taskbar pin/unpin operations
)

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================================
# CONFIGURATION
# ============================================================================

$GitHubRepo           = "WJ-BIM/revit-deployment"
$GitHubBranch         = "main"
$IconRoot             = "C:\ProgramData\RevitIcons"
$IconBaseUrl          = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/ICONS"
$StartMenuRoot        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Autodesk"
$DesktopPath          = [Environment]::GetFolderPath("Desktop")
$LogPath              = "C:\ProgramData\RevitDeploymentLog.txt"
$CurrentYear          = (Get-Date).Year
$MaxYear              = $CurrentYear + 5

# GitHub headers (for private repos)
$GitHubHeaders = @{}
if ($GitHubToken) {
    $GitHubHeaders = @{
        "Authorization" = "token $GitHubToken"
        "Accept"        = "application/vnd.github.v3.raw"
    }
}

# ============================================================================
# LOGGING FUNCTION
# ============================================================================

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    Write-Host $logEntry
}

function Write-StatusLine {
    param(
        [int]$Year,
        [string]$Status
    )
    $output = "[$Year] $Status"
    Add-Content -Path $LogPath -Value $output -ErrorAction SilentlyContinue
    Write-Output $output
}

# ============================================================================
# INITIALIZATION
# ============================================================================

Write-Log "========== REVIT DEPLOYMENT STARTED ==========" 
Write-Log "Admin check, directory setup..."

# Verify Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Log "ERROR: Must run as Administrator"
    exit 1
}

# Create icon cache directory
New-Item -ItemType Directory -Path $IconRoot -Force | Out-Null
Write-Log "Icon cache directory: $IconRoot"

# COM objects for shortcuts and shell
$Wsh   = New-Object -ComObject WScript.Shell
$Shell = New-Object -ComObject Shell.Application

Write-Log "Starting dynamic version scanning ($MinYear to $MaxYear)..."
Write-Log ""

# ============================================================================
# MAIN DEPLOYMENT LOOP - DYNAMIC YEAR DETECTION
# ============================================================================

$deploymentResults = @{}

foreach ($Year in $MinYear..$MaxYear) {
    
    # Convert year to RVT naming convention: 2023 -> RVT23, 2024 -> RVT24
    $YearShort = $Year % 100
    $IconFile    = "RVT$($YearShort.ToString('D2')).ico"
    $IconUrl     = "$IconBaseUrl/$IconFile"
    $IconPath    = Join-Path $IconRoot $IconFile
    $RevitExePath = "C:\Program Files\Autodesk\Revit $Year\Revit.exe"
    
    # ========================================================================
    # STEP 1: Check if Revit version is installed
    # ========================================================================
    
    if (-not (Test-Path $RevitExePath)) {
        Write-StatusLine $Year "NOT INSTALLED"
        continue
    }
    
    # ========================================================================
    # STEP 2: Download icon from GitHub
    # ========================================================================
    
    try {
        Invoke-WebRequest -Uri $IconUrl -Headers $GitHubHeaders `
            -OutFile $IconPath -UseBasicParsing -ErrorAction Stop | Out-Null
        Write-Log "  Downloaded: $IconFile from GitHub"
    }
    catch {
        Write-StatusLine $Year "DOWNLOAD FAILED"
        Write-Log "  Error downloading $IconUrl : $_"
        continue
    }
    
    if (-not (Test-Path $IconPath)) {
        Write-StatusLine $Year "DOWNLOAD FAILED"
        Write-Log "  Icon file not created: $IconPath"
        continue
    }
    
    # ========================================================================
    # STEP 3: Update Start Menu Shortcuts
    # ========================================================================
    
    $startMenuFolder = Join-Path $StartMenuRoot "Revit $Year"
    $startMenuUpdated = $false
    
    if (Test-Path $startMenuFolder) {
        $startMenuShortcuts = Get-ChildItem $startMenuFolder -Filter "*.lnk" -ErrorAction SilentlyContinue
        
        foreach ($lnk in $startMenuShortcuts) {
            try {
                $shortcut = $Wsh.CreateShortcut($lnk.FullName)
                $shortcut.IconLocation = "$IconPath,0"
                $shortcut.Save()
                
                # Make read-only to prevent reversion
                Set-ItemProperty -Path $lnk.FullName -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
                
                $startMenuUpdated = $true
                Write-Log "  Updated Start Menu: $($lnk.Name)"
            }
            catch {
                Write-Log "  Failed to update Start Menu shortcut $($lnk.Name): $_"
            }
        }
    }
    
    # ========================================================================
    # STEP 4: Update Desktop Shortcuts
    # ========================================================================
    
    $desktopShortcutName = "Revit $Year.lnk"
    $desktopShortcutPath = Join-Path $DesktopPath $desktopShortcutName
    $desktopUpdated = $false
    
    try {
        # Create or update desktop shortcut
        $shortcut = $Wsh.CreateShortcut($desktopShortcutPath)
        $shortcut.TargetPath = $RevitExePath
        $shortcut.WorkingDirectory = Split-Path -Parent $RevitExePath
        $shortcut.Description = "Autodesk Revit $Year"
        $shortcut.IconLocation = "$IconPath,0"
        $shortcut.WindowStyle = 1
        $shortcut.Save()
        
        # Make read-only
        Set-ItemProperty -Path $desktopShortcutPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
        
        $desktopUpdated = $true
        Write-Log "  Updated Desktop: $desktopShortcutName"
    }
    catch {
        Write-Log "  Failed to create Desktop shortcut: $_"
    }
    
    # ========================================================================
    # STEP 5: Taskbar Management (Best-Effort)
    # ========================================================================
    
    if (-not $SkipTaskbar) {
        try {
            # Unpin old taskbar shortcuts
            Get-ChildItem "C:\Users" -Directory -Exclude "Public","Default","Default User","All Users" -ErrorAction SilentlyContinue | ForEach-Object {
                $taskbarPath = "$($_.FullName)\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
                if (Test-Path $taskbarPath) {
                    Get-ChildItem $taskbarPath -Filter "*Revit*$Year*.lnk" -ErrorAction SilentlyContinue | 
                        Remove-Item -Force -ErrorAction SilentlyContinue
                }
            }
            
            # Re-pin taskbar with new icon (if desktop shortcut exists)
            if ($desktopUpdated) {
                try {
                    $folderObj = $Shell.Namespace($DesktopPath)
                    $item = $folderObj.ParseName($desktopShortcutName)
                    $item.InvokeVerb("taskbarpin")
                    Write-Log "  Taskbar re-pinned for Revit $Year"
                }
                catch {
                    Write-Log "  Taskbar pin skipped (non-critical)"
                }
            }
        }
        catch {
            Write-Log "  Taskbar operations skipped: $_"
        }
    }
    
    # ========================================================================
    # STEP 6: Status Output
    # ========================================================================
    
    if ($startMenuUpdated -or $desktopUpdated) {
        Write-StatusLine $Year "INSTALLED"
        $deploymentResults[$Year] = "INSTALLED"
    }
    else {
        Write-StatusLine $Year "SKIPPED"
        $deploymentResults[$Year] = "SKIPPED"
    }
}

# ============================================================================
# ANTI-REVERSION HARDENING
# ============================================================================

Write-Log ""
Write-Log "Applying anti-reversion protections..."

# Clear icon caches
try {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    
    Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    
    Start-Process explorer.exe
    Start-Sleep -Seconds 2
    
    Write-Log "✓ Icon cache cleared"
}
catch {
    Write-Log "⚠ Icon cache clear skipped: $_"
}

# Registry hardening
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    New-ItemProperty -Path $regPath -Name "ShowTypeOverlayIcons" -Value 0 `
        -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Log "✓ Registry hardening applied"
}
catch {
    Write-Log "⚠ Registry hardening skipped: $_"
}

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

Write-Log ""
Write-Log "========== REVIT DEPLOYMENT COMPLETED ==========" 

$installedCount = ($deploymentResults.Values | Where-Object { $_ -eq "INSTALLED" } | Measure-Object).Count
$skippedCount = ($deploymentResults.Values | Where-Object { $_ -eq "SKIPPED" } | Measure-Object).Count

Write-Log "Summary: $installedCount installed, $skippedCount skipped"
Write-Log "Log file: $LogPath"
Write-Log ""

Write-Host @"

╔════════════════════════════════════════╗
║   REVIT DEPLOYMENT COMPLETE            ║
╚════════════════════════════════════════╝

Installed versions: $installedCount
Skipped versions:   $skippedCount

Shortcuts created:
  - Start Menu:  C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Autodesk\Revit YYYY
  - Desktop:     %USERPROFILE%\Desktop\Revit YYYY.lnk
  - Taskbar:     Automatically pinned (if available)

Icon location:    $IconRoot
Icon naming:      RVTYY.ico (RVT23.ico, RVT24.ico, etc.)
Log file:         $LogPath

GitHub Repository: https://github.com/WJ-BIM/revit-deployment

References:
  - https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
  - https://www.bimpure.com/blog/revit-icons

Next steps:
  1. Check Start Menu and Desktop for Revit shortcuts
  2. Verify custom icons are displaying
  3. Open each Revit version to confirm icons persist
  4. If icons revert, run: Fix-RevitIconReversion-ADVANCED.ps1

For company-wide deployment via GPO:
  1. Update Deploy-RevitShortcuts-GPO-HYBRID.ps1 with GitHub settings
  2. Create Group Policy with script as startup script
  3. Link to target OU
  4. Force: gpupdate /force /boot

"@

Exit 0
