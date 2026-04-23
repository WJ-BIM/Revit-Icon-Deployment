# ============================================================================
# REVIT CUSTOM SHORTCUTS DEPLOYMENT - HYBRID GPO VERSION
# Icon Naming Convention: RVT23.ico, RVT24.ico, etc (RVT + 2-digit year)
#
# Deploys to all domain machines via Group Policy startup script
# Dynamically detects installed Revit versions and downloads icons from GitHub
#
# Features:
#   - Dynamic Revit detection (2014-current+5)
#   - GitHub icon repository (WJ-BIM/Revit-Icon-Deployment)
#   - Updates both Start Menu and Desktop
#   - Taskbar management
#   - Anti-reversion protections
#
# Deployment:
#   - Computer Configuration > Windows Settings > Scripts (Startup)
#   - ExecutionPolicy: Allow local scripts and remote signed scripts
#
# References:
#   - https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
#   - https://www.bimpure.com/blog/revit-icons
#
# ============================================================================

param(
    [string]$GitHubToken = ""  # Set to PAT if private repo
)

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================================
# CONFIGURATION
# ============================================================================

$GitHubRepo           = "WJ-BIM/Revit-Icon-Deployment"
$GitHubBranch         = "main"
$IconRoot             = "C:\ProgramData\RevitIcons"
$IconBaseUrl          = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/Icons"
$StartMenuRoot        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Autodesk"
$LogPath              = "C:\ProgramData\RevitDeploymentLog.txt"
$CurrentYear          = (Get-Date).Year
$MinYear              = 2014
$MaxYear              = $CurrentYear + 5

# GitHub headers for authentication
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

function Write-DeployLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

function Write-StatusLine {
    param(
        [int]$Year,
        [string]$Status
    )
    $output = "[$Year] $Status"
    Add-Content -Path $LogPath -Value $output -ErrorAction SilentlyContinue
}

# ============================================================================
# INITIALIZATION
# ============================================================================

Write-DeployLog "========== REVIT GPO DEPLOYMENT STARTED ==========" "START"

# Create icon cache directory
New-Item -ItemType Directory -Path $IconRoot -Force -ErrorAction SilentlyContinue | Out-Null
Write-DeployLog "Icon cache initialized: $IconRoot" "INFO"

# COM objects for shortcuts and shell
$Wsh   = New-Object -ComObject WScript.Shell
$Shell = New-Object -ComObject Shell.Application

# ============================================================================
# DETERMINE TARGET DESKTOP PATHS (ALL USERS)
# ============================================================================

Write-DeployLog "Scanning user profiles..." "INFO"

$targetDesktops = @()
$userProfiles = Get-ChildItem "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\ProfileList" | 
    Where-Object { $_.PSChildName -match "S-1-5-21-.*-\d+$" }

foreach ($profile in $userProfiles) {
    $profilePath = $profile.GetValue("ProfileImagePath")
    if ($profilePath -and (Test-Path $profilePath)) {
        $desktopPath = Join-Path $profilePath "Desktop"
        if (Test-Path $desktopPath) {
            $targetDesktops += $desktopPath
        }
    }
}

Write-DeployLog "Target desktop paths found: $($targetDesktops.Count)" "INFO"

# ============================================================================
# MAIN DEPLOYMENT LOOP - DYNAMIC VERSION SCANNING
# ============================================================================

Write-DeployLog "Starting version scan ($MinYear to $MaxYear)..." "INFO"

$deploymentStats = @{
    Installed = 0
    Skipped   = 0
    Failed    = 0
}

foreach ($Year in $MinYear..$MaxYear) {
    
    # Convert year to RVT naming convention: 2023 -> RVT23, 2024 -> RVT24
    $YearShort = $Year % 100
    $IconFile    = "RVT$($YearShort.ToString('D2')).ico"
    $IconUrl     = "$IconBaseUrl/$IconFile"
    $IconPath    = Join-Path $IconRoot $IconFile
    $RevitExePath = "C:\Program Files\Autodesk\Revit $Year\Revit.exe"
    
    # ========================================================================
    # STEP 1: Check Revit Installation
    # ========================================================================
    
    if (-not (Test-Path $RevitExePath)) {
        Write-StatusLine $Year "NOT INSTALLED"
        continue
    }
    
    Write-DeployLog "Processing Revit $Year..." "INFO"
    
    # ========================================================================
    # STEP 2: Download Icon
    # ========================================================================
    
    try {
        Invoke-WebRequest -Uri $IconUrl -Headers $GitHubHeaders `
            -OutFile $IconPath -UseBasicParsing -ErrorAction Stop | Out-Null
    }
    catch {
        Write-StatusLine $Year "DOWNLOAD FAILED"
        Write-DeployLog "Failed to download $IconFile : $_" "ERROR"
        $deploymentStats.Failed++
        continue
    }
    
    if (-not (Test-Path $IconPath)) {
        Write-StatusLine $Year "DOWNLOAD FAILED"
        Write-DeployLog "Icon file not created at $IconPath" "ERROR"
        $deploymentStats.Failed++
        continue
    }
    
    # ========================================================================
    # STEP 3: Update Start Menu Shortcuts (All Users)
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
                
                # Protect from reversion
                Set-ItemProperty -Path $lnk.FullName -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
                
                $startMenuUpdated = $true
            }
            catch {
                Write-DeployLog "Failed updating Start Menu $($lnk.Name) for year $Year : $_" "WARN"
            }
        }
        
        if ($startMenuUpdated) {
            Write-DeployLog "Updated Start Menu shortcuts for Revit $Year" "SUCCESS"
        }
    }
    
    # ========================================================================
    # STEP 4: Update Desktop Shortcuts (All Users)
    # ========================================================================
    
    $desktopUpdated = 0
    
    foreach ($desktopPath in $targetDesktops) {
        $desktopShortcutName = "Revit $Year.lnk"
        $desktopShortcutPath = Join-Path $desktopPath $desktopShortcutName
        
        try {
            # Create or update shortcut
            $shortcut = $Wsh.CreateShortcut($desktopShortcutPath)
            $shortcut.TargetPath = $RevitExePath
            $shortcut.WorkingDirectory = Split-Path -Parent $RevitExePath
            $shortcut.Description = "Autodesk Revit $Year"
            $shortcut.IconLocation = "$IconPath,0"
            $shortcut.WindowStyle = 1
            $shortcut.Save()
            
            # Protect from reversion
            Set-ItemProperty -Path $desktopShortcutPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
            
            $desktopUpdated++
        }
        catch {
            Write-DeployLog "Failed creating Desktop shortcut for $Year : $_" "WARN"
        }
    }
    
    # ========================================================================
    # STEP 5: Taskbar Management (Best-Effort)
    # ========================================================================
    
    try {
        # Unpin old taskbar shortcuts for all users
        Get-ChildItem "C:\Users" -Directory -Exclude "Public","Default","Default User","All Users" -ErrorAction SilentlyContinue | ForEach-Object {
            $taskbarPath = "$($_.FullName)\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
            if (Test-Path $taskbarPath) {
                Get-ChildItem $taskbarPath -Filter "*Revit*$Year*.lnk" -ErrorAction SilentlyContinue | 
                    Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-DeployLog "Taskbar unpin skipped for year $Year: $_" "WARN"
    }
    
    # ========================================================================
    # STEP 6: Status Output
    # ========================================================================
    
    if ($startMenuUpdated -or $desktopUpdated -gt 0) {
        Write-StatusLine $Year "INSTALLED"
        $deploymentStats.Installed++
        Write-DeployLog "Revit $Year deployment successful (Start Menu + $desktopUpdated desktops)" "SUCCESS"
    }
    else {
        Write-StatusLine $Year "SKIPPED"
        $deploymentStats.Skipped++
        Write-DeployLog "Revit $Year deployment skipped (no updates)" "INFO"
    }
}

# ============================================================================
# ANTI-REVERSION HARDENING (GLOBAL)
# ============================================================================

Write-DeployLog "Applying anti-reversion protections..." "INFO"

# Clear icon caches
try {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    
    Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    
    Start-Process explorer.exe -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    Write-DeployLog "Icon caches cleared" "SUCCESS"
}
catch {
    Write-DeployLog "Icon cache clear skipped: $_" "WARN"
}

# Registry hardening
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    New-ItemProperty -Path $regPath -Name "ShowTypeOverlayIcons" -Value 0 `
        -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    
    Write-DeployLog "Registry hardening applied" "SUCCESS"
}
catch {
    Write-DeployLog "Registry hardening skipped: $_" "WARN"
}

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

Write-DeployLog "========== REVIT GPO DEPLOYMENT FINISHED ==========" "END"
Write-DeployLog "Summary: Installed=$($deploymentStats.Installed), Skipped=$($deploymentStats.Skipped), Failed=$($deploymentStats.Failed)" "INFO"

Exit 0
