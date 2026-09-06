---
name: win11-admin
description: "Windows 11 system administration and hardening. PROACTIVELY activate for: (1) Registry tweaking and optimization, (2) Windows services management and cleanup, (3) Group Policy (GPO) configuration, (4) Debloating and telemetry control, (5) System optimization and performance tuning, (6) CIS/STIG security hardening, (7) Windows Firewall and network configuration, (8) Windows Defender and security management, (9) Scheduled tasks and automation, (10) Driver and hardware management, (11) Windows Update management, (12) User account and permission management. Provides: Production-ready PowerShell commands, registry paths, GPO settings, hardening baselines, and rollback procedures for Windows 11 Pro/Enterprise."
---

# Windows 11 Administration & Hardening

## CRITICAL: Safety Rules

1. **ALWAYS create a System Restore Point before changes**
2. **ALWAYS backup registry keys before modifying them**
3. **ALWAYS test on non-production systems first**
4. **NEVER disable Windows Update completely**
5. **NEVER disable Windows Defender without explicit user consent**
6. **Provide rollback commands for every change**

```powershell
# Create restore point before ANY system change
Checkpoint-Computer -Description "Before Win11 Admin changes" -RestorePointType MODIFY_SETTINGS

# Backup specific registry key before modification
reg export "HKLM\SOFTWARE\Key" "C:\Users\cesco\backups\reg_backup_$(Get-Date -Format yyyyMMdd_HHmmss).reg"
```

---

## When to Activate

PROACTIVELY activate for ANY Windows 11 administration task:

- Registry modifications (HKLM, HKCU, policies)
- Service management (disable, enable, startup type)
- Group Policy configuration (local or domain)
- Bloatware removal and telemetry control
- Performance optimization (visual effects, memory, disk)
- Security hardening (CIS, STIG, DISA baselines)
- Firewall rules and network configuration
- Windows Defender settings and exclusions
- Scheduled tasks management
- Driver and hardware troubleshooting
- Windows Update control and WSUS
- User accounts, UAC, and permissions

---

## 1. Registry Administration

### Common Registry Hives

| Hive | Abbreviation | Scope |
|------|-------------|-------|
| HKEY_LOCAL_MACHINE | HKLM: | System-wide |
| HKEY_CURRENT_USER | HKCU: | Current user |
| HKEY_CLASSES_ROOT | HKCR: | File associations |
| HKEY_USERS | HKU: | All user profiles |

### Registry Operations

```powershell
# Read registry value
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "ProgramFilesDir"

# Create/set registry value
New-ItemProperty -Path "HKCU:\Software\MyApp" -Name "Setting" -Value 1 -PropertyType DWord -Force

# Modify existing value
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 1

# Delete registry value
Remove-ItemProperty -Path "HKCU:\Software\MyApp" -Name "Setting"

# Create registry key (folder)
New-Item -Path "HKLM:\SOFTWARE\Policies\MyPolicy" -Force

# Test if key/value exists
Test-Path "HKLM:\SOFTWARE\Policies\MyPolicy"
(Get-ItemProperty "HKLM:\SOFTWARE\MyKey" -Name "MyValue" -ErrorAction SilentlyContinue) -ne $null

# Export registry key (backup)
reg export "HKLM\SOFTWARE\Policies\Microsoft" "C:\backup\policies.reg" /y

# Import registry key (restore)
reg import "C:\backup\policies.reg"
```

### Common Win11 Registry Tweaks

```powershell
# --- TASKBAR ---
# Hide Search button (0=Hidden, 1=Icon, 2=SearchBox)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0

# Hide Task View button
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

# Hide Widgets
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0

# Hide Chat/Teams icon
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0

# Left-align taskbar (0=Left, 1=Center)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0

# --- EXPLORER ---
# Show file extensions
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

# Show hidden files
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# Show full path in title bar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name "FullPath" -Value 1

# Disable Snap Assist flyout
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -Value 0

# Classic right-click context menu (Win10 style)
New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Value "" -Force

# Revert to Win11 context menu
Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force

# --- STARTUP ---
# Disable startup delay
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Value 0 -PropertyType DWord -Force
```

---

## 2. Services Management

### Service Operations

```powershell
# List all services with status
Get-Service | Sort-Object Status, Name | Format-Table Name, DisplayName, Status, StartType

# Get specific service info
Get-Service -Name "wuauserv" | Select-Object *

# Check service dependencies
Get-Service -Name "wuauserv" -DependentServices
Get-Service -Name "wuauserv" -RequiredServices

# Change startup type
Set-Service -Name "ServiceName" -StartupType Disabled   # Disabled/Manual/Automatic/AutomaticDelayedStart

# Stop and disable
Stop-Service -Name "ServiceName" -Force
Set-Service -Name "ServiceName" -StartupType Disabled

# Start and set automatic
Set-Service -Name "ServiceName" -StartupType Automatic
Start-Service -Name "ServiceName"
```

### Safe-to-Disable Services (Win11 Pro)

```powershell
# Services commonly safe to disable on standalone workstations
# ALWAYS verify before disabling - requirements vary by environment

$safeToDisable = @(
    "DiagTrack"          # Connected User Experiences and Telemetry
    "dmwappushservice"   # WAP Push Message Routing
    "MapsBroker"         # Downloaded Maps Manager
    "RetailDemo"         # Retail Demo Service
    "WMPNetworkSvc"      # Windows Media Player Network Sharing
    "XblAuthManager"     # Xbox Live Auth Manager
    "XblGameSave"        # Xbox Live Game Save
    "XboxGipSvc"         # Xbox Accessory Management
    "XboxNetApiSvc"      # Xbox Live Networking
)

# Review before disabling
$safeToDisable | ForEach-Object {
    $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
    if ($svc) {
        [PSCustomObject]@{
            Name = $svc.Name
            DisplayName = $svc.DisplayName
            Status = $svc.Status
            StartType = $svc.StartType
        }
    }
}

# Disable after review (user must confirm)
# $safeToDisable | ForEach-Object {
#     Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
# }
```

### NEVER Disable These Services

```
- wuauserv (Windows Update)
- WinDefend (Windows Defender)
- EventLog (Windows Event Log)
- RpcSs (Remote Procedure Call)
- LSM (Local Session Manager)
- Schedule (Task Scheduler)
- Winmgmt (WMI)
- CryptSvc (Cryptographic Services)
- BITS (Background Intelligent Transfer)
```

---

## 3. Group Policy (Local)

### GPO via PowerShell (Registry-Based)

Most local GPOs write to registry. Use `Set-ItemProperty` targeting policy paths:

```powershell
# --- TELEMETRY & PRIVACY ---
# Disable telemetry (0=Security, 1=Basic, 2=Enhanced, 3=Full)
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

# Disable advertising ID
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0

# Disable activity history
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0

# --- WINDOWS UPDATE ---
# Configure Windows Update (0=NotConfigured, 1=Disabled, 2-5=various)
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force
# Notify before download
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 2
# Disable auto-restart
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1

# --- DEFENDER ---
# Enable Controlled Folder Access
Set-MpPreference -EnableControlledFolderAccess Enabled

# Add exclusion (path)
Add-MpPreference -ExclusionPath "C:\Dev"

# Enable Network Protection
Set-MpPreference -EnableNetworkProtection Enabled

# Enable PUA Protection
Set-MpPreference -PUAProtection Enabled

# --- LOCK SCREEN ---
# Disable lock screen ads/tips
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0
```

### Edit Local GPO with gpedit.msc

```powershell
# Open Group Policy Editor (Pro/Enterprise only)
gpedit.msc

# Key paths:
# Computer Configuration > Administrative Templates > Windows Components > Data Collection
# Computer Configuration > Administrative Templates > Windows Components > Windows Update
# User Configuration > Administrative Templates > Start Menu and Taskbar
```

---

## 4. Debloating

### Remove Pre-installed Apps

```powershell
# List all installed UWP/AppX packages
Get-AppxPackage | Select-Object Name, PackageFullName | Sort-Object Name

# List provisioned packages (installed for all users)
Get-AppxProvisionedPackage -Online | Select-Object DisplayName

# Common bloatware to remove
$bloatware = @(
    "Microsoft.BingNews"
    "Microsoft.BingWeather"
    "Microsoft.GamingApp"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.People"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.Todos"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "MicrosoftTeams"
    "Clipchamp.Clipchamp"
    "Microsoft.549981C3F5F10"  # Cortana
)

# Preview what would be removed
$bloatware | ForEach-Object {
    $pkg = Get-AppxPackage -Name $_ -ErrorAction SilentlyContinue
    if ($pkg) { Write-Host "Found: $($pkg.Name)" -ForegroundColor Yellow }
    else { Write-Host "Not found: $_" -ForegroundColor Gray }
}

# Remove for current user (uncomment after review)
# $bloatware | ForEach-Object {
#     Get-AppxPackage -Name $_ | Remove-AppxPackage -ErrorAction SilentlyContinue
# }

# Remove provisioned (prevents reinstall for new users)
# $bloatware | ForEach-Object {
#     Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $_ |
#         Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
# }
```

### NEVER Remove These

```
- Microsoft.WindowsStore (Store - needed for updates)
- Microsoft.WindowsCalculator
- Microsoft.WindowsTerminal
- Microsoft.DesktopAppInstaller (winget)
- Microsoft.VCLibs (Visual C++ runtime)
- Microsoft.UI.Xaml (UI framework)
- Microsoft.NET (runtime)
- Microsoft.HEIFImageExtension / Microsoft.WebpImageExtension (image codecs)
```

### Disable Telemetry & Tracking

```powershell
# Disable Diagnostic Data
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

# Disable feedback notifications
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0 -Force

# Disable app suggestions and pre-installed apps
$cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-ItemProperty -Path $cdm -Name "ContentDeliveryAllowed" -Value 0
Set-ItemProperty -Path $cdm -Name "OemPreInstalledAppsEnabled" -Value 0
Set-ItemProperty -Path $cdm -Name "PreInstalledAppsEnabled" -Value 0
Set-ItemProperty -Path $cdm -Name "SilentInstalledAppsEnabled" -Value 0
Set-ItemProperty -Path $cdm -Name "SoftLandingEnabled" -Value 0
Set-ItemProperty -Path $cdm -Name "SubscribedContentEnabled" -Value 0
Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 0

# Disable Copilot (Win11 23H2+)
New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Force
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1

# Disable Recall (Win11 24H2+)
New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Force
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1
```

---

## 5. Performance Optimization

### Visual Effects

```powershell
# Disable animations and visual effects for performance
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 2  # 2=Custom

$advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $advanced -Name "TaskbarAnimations" -Value 0

# Disable transparency effects
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0

# Disable animation effects via SystemParametersInfo
# Best performance settings
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
Set-ItemProperty -Path $regPath -Name "MenuShowDelay" -Value "0"

# Disable window animations
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0"
```

### Power Plan

```powershell
# List power plans
powercfg /list

# Set High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Create Ultimate Performance plan (desktop)
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61

# Disable hibernation (saves disk space)
powercfg /hibernate off

# Disable USB selective suspend
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setactive SCHEME_CURRENT
```

### Memory & Disk

```powershell
# Check memory usage
Get-CimInstance Win32_OperatingSystem | Select-Object @{N='TotalGB';E={[math]::Round($_.TotalVisibleMemorySize/1MB,2)}}, @{N='FreeGB';E={[math]::Round($_.FreePhysicalMemory/1MB,2)}}, @{N='UsedPct';E={[math]::Round((1-$_.FreePhysicalMemory/$_.TotalVisibleMemorySize)*100,1)}}

# Check disk space
Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N='UsedGB';E={[math]::Round($_.Used/1GB,2)}}, @{N='FreeGB';E={[math]::Round($_.Free/1GB,2)}}

# Disk cleanup (silent)
cleanmgr /sagerun:1

# Clear temp files
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear Windows Update cache
Stop-Service wuauserv -Force
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force
Start-Service wuauserv

# Analyze disk usage (largest folders)
Get-ChildItem "C:\" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    [PSCustomObject]@{
        Folder = $_.FullName
        SizeGB = [math]::Round((Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1GB, 2)
    }
} | Sort-Object SizeGB -Descending | Format-Table
```

### Startup Optimization

```powershell
# List startup programs
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location

# Registry startup locations
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue

# Scheduled tasks at startup
Get-ScheduledTask | Where-Object {$_.Triggers -match "AtStartup" -or $_.Triggers -match "AtLogon"} | Select-Object TaskName, State

# Disable specific startup item
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "ProgramName" -ErrorAction SilentlyContinue
```

---

## 6. Security Hardening (CIS/STIG)

### CIS Benchmark Key Settings

```powershell
# --- ACCOUNT POLICIES ---
# Set minimum password length (14 chars - CIS)
net accounts /minpwlen:14

# Set password history (24 - CIS)
net accounts /uniquepw:24

# Set account lockout threshold (5 attempts - CIS)
net accounts /lockoutthreshold:5

# --- AUDIT POLICY ---
# Enable auditing for key events
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Policy Change" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable

# --- NETWORK ---
# Disable NetBIOS over TCP/IP
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"
foreach ($adapter in $adapters) {
    $adapter.SetTcpipNetbios(2)  # 2 = Disable
}

# Disable LLMNR (Link-Local Multicast Name Resolution)
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0

# --- SMB ---
# Disable SMBv1 (critical security)
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

# Enable SMB signing
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force

# --- UAC ---
# Ensure UAC is enabled and set to highest level
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2  # Prompt for consent on secure desktop
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 1

# --- REMOTE ---
# Disable Remote Desktop (if not needed)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1

# Disable Remote Assistance
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 0

# --- BITLOCKER ---
# Check BitLocker status
Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, EncryptionMethod, ProtectionStatus

# Enable BitLocker on C:
# Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -RecoveryPasswordProtector
```

### Windows Defender Hardening

```powershell
# Enable all protection features
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -DisableBlockAtFirstSeen $false
Set-MpPreference -DisableIOAVProtection $false
Set-MpPreference -DisablePrivacyMode $false
Set-MpPreference -DisableScriptScanning $false

# Enable cloud protection (high)
Set-MpPreference -MAPSReporting Advanced
Set-MpPreference -SubmitSamplesConsent SendAllSamples

# Enable Attack Surface Reduction rules
$asrRules = @(
    "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550"  # Block executable content from email/webmail
    "D4F940AB-401B-4EFC-AADC-AD5F3C50688A"  # Block Office apps from creating child processes
    "3B576869-A4EC-4529-8536-B80A7769E899"  # Block Office apps from creating executable content
    "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84"  # Block Office apps from injecting into other processes
    "D3E037E1-3EB8-44C8-A917-57927947596D"  # Block JavaScript/VBScript launching downloaded content
    "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC"  # Block execution of potentially obfuscated scripts
    "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B"  # Block Win32 API calls from Office macros
    "01443614-CD74-433A-B99E-2ECDC07BFC25"  # Block executable files unless they meet criteria
    "C1DB55AB-C21A-4637-BB3F-A12568109D35"  # Use advanced protection against ransomware
    "9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2"  # Block credential stealing from LSASS
    "D1E49AAC-8F56-4280-B9BA-993A6D77406C"  # Block process creations from PSExec and WMI
    "B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4"  # Block untrusted/unsigned processes from USB
    "26190899-1602-49E8-8B27-EB1D0A1CE869"  # Block Office communication apps from creating child processes
    "7674BA52-37EB-4A4F-A9A1-F0F9A1619A2C"  # Block Adobe Reader from creating child processes
    "E6DB77E5-3DF2-4CF1-B95A-636979351E5B"  # Block persistence through WMI event subscription
    "56A863A9-875E-4185-98A7-B882C64B5CE5"  # Block abuse of exploited vulnerable signed drivers
)

# Enable in Block mode (1=Block, 2=Audit, 6=Warn)
$asrRules | ForEach-Object {
    Add-MpPreference -AttackSurfaceReductionRules_Ids $_ -AttackSurfaceReductionRules_Actions 1
}

# Enable Network Protection
Set-MpPreference -EnableNetworkProtection Enabled

# Enable Controlled Folder Access (ransomware protection)
Set-MpPreference -EnableControlledFolderAccess Enabled
Add-MpPreference -ControlledFolderAccessAllowedApplications "C:\Program Files\MyApp\app.exe"
Add-MpPreference -ControlledFolderAccessProtectedFolders "D:\ImportantData"

# Run full scan
Start-MpScan -ScanType FullScan

# Update definitions
Update-MpSignature
```

---

## 7. Windows Firewall

### Firewall Management

```powershell
# Check firewall status
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction

# Enable all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Set default deny inbound
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow

# List all rules
Get-NetFirewallRule | Where-Object Enabled -eq True | Select-Object DisplayName, Direction, Action, Profile | Sort-Object DisplayName

# Create allow rule
New-NetFirewallRule -DisplayName "Allow MyApp" -Direction Inbound -Program "C:\MyApp\app.exe" -Action Allow -Profile Private

# Create port rule
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow

# Block specific IP
New-NetFirewallRule -DisplayName "Block BadIP" -Direction Inbound -RemoteAddress "1.2.3.4" -Action Block

# Remove rule
Remove-NetFirewallRule -DisplayName "Allow MyApp"

# Disable rule
Disable-NetFirewallRule -DisplayName "Allow MyApp"

# Export/Import rules (backup)
netsh advfirewall export "C:\Users\cesco\backups\firewall_$(Get-Date -Format yyyyMMdd).wfw"
# netsh advfirewall import "C:\Users\cesco\backups\firewall_backup.wfw"
```

---

## 8. Network Configuration

### Network Diagnostics

```powershell
# IP configuration
Get-NetIPAddress | Where-Object AddressFamily -eq "IPv4" | Select-Object InterfaceAlias, IPAddress, PrefixLength

# DNS configuration
Get-DnsClientServerAddress | Where-Object AddressFamily -eq 2 | Select-Object InterfaceAlias, ServerAddresses

# Set DNS (e.g., Cloudflare)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "1.1.1.1","1.0.0.1"

# Flush DNS cache
Clear-DnsClientCache

# Check active connections
Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess | Sort-Object RemoteAddress

# Check listening ports
Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess | Sort-Object LocalPort

# Resolve process for port
Get-NetTCPConnection -LocalPort 8080 | ForEach-Object { Get-Process -Id $_.OwningProcess }

# Network adapter info
Get-NetAdapter | Select-Object Name, Status, LinkSpeed, MacAddress

# Wi-Fi profiles
netsh wlan show profiles

# Speed test (basic)
Test-NetConnection -ComputerName "8.8.8.8" -InformationLevel Detailed
```

---

## 9. Scheduled Tasks

```powershell
# List all scheduled tasks
Get-ScheduledTask | Select-Object TaskName, State, TaskPath | Sort-Object TaskPath, TaskName

# Get task details
Get-ScheduledTask -TaskName "TaskName" | Get-ScheduledTaskInfo

# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\backup.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "03:00"
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun
Register-ScheduledTask -TaskName "DailyBackup" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest

# Disable task
Disable-ScheduledTask -TaskName "TaskName"

# Remove task
Unregister-ScheduledTask -TaskName "TaskName" -Confirm:$false

# Run task immediately
Start-ScheduledTask -TaskName "TaskName"

# Common telemetry tasks to disable
$telemetryTasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
)

$telemetryTasks | ForEach-Object {
    $task = Get-ScheduledTask -TaskPath ($_ -replace '[^\\]*$','') -TaskName ($_ -replace '.*\\','') -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "Found: $($task.TaskName) [$($task.State)]"
    }
}
```

---

## 10. Windows Update Management

```powershell
# Check for updates (requires PSWindowsUpdate module)
# Install-Module -Name PSWindowsUpdate -Force
# Get-WindowsUpdate

# Check update history
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 20

# Current Windows version
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber

# Pause updates (35 days max via registry)
$pauseDate = (Get-Date).AddDays(35).ToString("yyyy-MM-ddTHH:mm:ssZ")
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pauseDate

# Active hours (prevent restarts during work)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursStart" -Value 8
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursEnd" -Value 23

# WSUS configuration (enterprise)
# New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "WUServer" -Value "https://wsus.company.com:8531"
```

---

## 11. User & Permission Management

```powershell
# List local users
Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordExpires

# List local groups
Get-LocalGroup | Select-Object Name, Description

# Get group members
Get-LocalGroupMember -Group "Administrators"

# Create local user
New-LocalUser -Name "newuser" -Password (Read-Host -AsSecureString "Password") -FullName "New User" -Description "Created by admin"

# Add user to group
Add-LocalGroupMember -Group "Administrators" -Member "newuser"

# Disable user
Disable-LocalUser -Name "username"

# Check UAC level
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" | Select-Object EnableLUA, ConsentPromptBehaviorAdmin, PromptOnSecureDesktop

# File/folder permissions
Get-Acl "C:\Folder" | Format-List

# Set permissions
$acl = Get-Acl "C:\Folder"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($rule)
Set-Acl "C:\Folder" $acl
```

---

## 12. System Information & Diagnostics

```powershell
# Full system info
Get-ComputerInfo | Select-Object CsName, WindowsProductName, WindowsVersion, OsBuildNumber, OsArchitecture, CsProcessors, CsTotalPhysicalMemory

# Hardware info
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer, Capacity, Speed, MemoryType
Get-CimInstance Win32_DiskDrive | Select-Object Model, Size, MediaType

# BIOS/UEFI info
Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate

# Drivers
Get-CimInstance Win32_PnPSignedDriver | Where-Object DeviceName -ne $null | Select-Object DeviceName, DriverVersion, DriverDate | Sort-Object DeviceName

# System uptime
(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

# Event logs (errors last 24h)
Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddHours(-24)} -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message -First 20

# Check system file integrity
# sfc /scannow
# DISM /Online /Cleanup-Image /RestoreHealth

# Installed software
Get-CimInstance Win32_Product | Select-Object Name, Version, Vendor | Sort-Object Name
# Faster alternative (registry-based)
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher | Sort-Object DisplayName
```

---

## Quick Reference: Common Admin Tasks

| Task | Command |
|------|---------|
| System restore point | `Checkpoint-Computer -Description "desc"` |
| Restart Explorer | `Stop-Process -Name explorer -Force` |
| Flush DNS | `Clear-DnsClientCache` |
| Check disk | `chkdsk C: /f /r` (requires reboot) |
| Repair system files | `sfc /scannow` |
| Repair Windows image | `DISM /Online /Cleanup-Image /RestoreHealth` |
| Reset network stack | `netsh winsock reset && netsh int ip reset` |
| Clear Windows Store cache | `wsreset.exe` |
| Open device manager | `devmgmt.msc` |
| Open disk management | `diskmgmt.msc` |
| Open services | `services.msc` |
| Open firewall | `wf.msc` |
| Open event viewer | `eventvwr.msc` |
| Open task scheduler | `taskschd.msc` |
| Open registry editor | `regedit` |
| System properties | `sysdm.cpl` |
| Network connections | `ncpa.cpl` |
| Programs and features | `appwiz.cpl` |
