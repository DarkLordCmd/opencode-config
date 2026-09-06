# Management — Updates, Programs, Remote, Boot, Power, UI Automation

## 📷 Screen Reading — See What's On Screen
```
# === Screenshot ===
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$bmp = [Drawing.Bitmap]::new([Screen]::PrimaryScreen.Bounds.Width,[Screen]::PrimaryScreen.Bounds.Height)
$g = [Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen(0,0,0,0,$bmp.Size)
$bmp.Save("$env:TEMP\screen.png"); $g.Dispose(); $bmp.Dispose()

# === OCR: Tesseract (install once: winget install UB-Mannheim.TesseractOCR) ===
# Screenshot → text
tesseract "$env:TEMP\screen.png" stdout -l eng+chi_sim

# Screenshot → text file
tesseract "$env:TEMP\screen.png" "$env:TEMP\screen-out" -l eng+chi_sim
Get-Content "$env:TEMP\screen-out.txt"

# Recognize specific region (x,y,w,h)
tesseract "$env:TEMP\screen.png" stdout --psm 6 -l eng

# Check if tesseract is installed
Get-Command tesseract -ErrorAction 0

# === Read All Window Titles ===
Add-Type -AssemblyName UIAutomationClient
$r = [System.Windows.Automation.AutomationElement]::RootElement
$r.FindAll([System.Windows.Automation.TreeScope]::Children,[System.Windows.Automation.Condition]::TrueCondition) |
  ForEach { $_.Current.Name } | Where { $_ } | Sort -Unique

# === Read Text From Specific Window (e.g. Notepad) ===
$cond = [System.Windows.Automation.PropertyCondition]::new(
  [System.Windows.Automation.AutomationElement]::NameProperty, "*Notepad*")
$wnd = $r.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
if ($wnd) { $wnd.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern).DocumentRange.GetText(5000) }
```

## 🖱️ Keyboard & Mouse (UI Automation)

### Prerequisite: Set Input Method to English
```
# Fix: Chinese IME intercepts SendKeys, switch to en-US first
Add-Type @"
using System.Runtime.InteropServices;
public class IME {
  [DllImport("user32.dll")] public static extern nint LoadKeyboardLayout(string s,uint f);
  [DllImport("user32.dll")] public static extern nint ActivateKeyboardLayout(nint h,uint f); }"@
$null = [IME]::ActivateKeyboardLayout([IME]::LoadKeyboardLayout("00000409",1),0)
```

### Prerequisite: Install Tesseract OCR (one-time)
```
winget install UB-Mannheim.TesseractOCR
# Then add to PATH if needed:
$env:PATH += ";$env:ProgramFiles\Tesseract-OCR"
```

### SendKeys Reference
```
$ws = New-Object -ComObject wscript.shell
$ws.SendKeys("text{ENTER}")   # Type text and press Enter
$ws.SendKeys("^{c}")           # Ctrl+C
$ws.SendKeys("^{v}")           # Ctrl+V
$ws.SendKeys("^{a}")           # Ctrl+A
$ws.SendKeys("%{F4}")          # Alt+F4 (close window)
$ws.SendKeys("{TAB}")          # Tab
$ws.SendKeys("+{TAB}")         # Shift+Tab
$ws.SendKeys("{ESC}")          # Escape
$ws.SendKeys("{ENTER}")        # Enter
$ws.SendKeys("{F5}")           # F5 (refresh)
$ws.SendKeys("^{s}")           # Ctrl+S
$ws.SendKeys("^{z}")           # Ctrl+Z
$ws.SendKeys("^{ESC}")         # Start menu
$ws.SendKeys("^+{ESC}")        # Task Manager
$ws.SendKeys("^{F4}")          # Ctrl+F4 (close tab)
```

### Window Management
```
# Activate by title fragment
$ws.AppActivate("Notepad"); Start-Sleep 1
$ws.SendKeys("Hello from AI")

# Activate by process ID
(Get-Process notepad).MainWindowHandle
$h = (Get-Process notepad)[0].MainWindowHandle
Add-Type @"
using System.Runtime.InteropServices;
public class W { [DllImport("user32.dll")] public static extern bool SetForegroundWindow(nint h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(nint h,int c); }"@
[W]::SetForegroundWindow($h)
[W]::ShowWindow($h,1)  # 1=norm,3=max,6=min

# Find window by title
Add-Type @"
using System.Runtime.InteropServices; using System.Text;
public class W2 { [DllImport("user32.dll")] public static extern nint FindWindow(string c,string w);
  [DllImport("user32.dll")] public static extern int GetWindowText(nint h,StringBuilder s,int n);
  public static string[] Enum() {
    var r=System.Collections.Generic.List[string]::new(); return r.ToArray(); } }"@
```

### Mouse Control
```
# Get cursor position
Add-Type -AssemblyName System.Windows.Forms
[Windows.Forms.Cursor]::Position

# Move mouse to (X,Y)
[Windows.Forms.Cursor]::Position = [Drawing.Point]::new(500,300)

# Left click at current position
Add-Type @"
using System.Runtime.InteropServices;
public class M { [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint x,uint y,uint d,int i); }"@
[M]::mouse_event(0x02,0,0,0,0)  # DOWN
[M]::mouse_event(0x04,0,0,0,0)  # UP

# Right click
[M]::mouse_event(0x08,0,0,0,0); [M]::mouse_event(0x10,0,0,0,0)
```

### Launch + Automate Pattern
```
Start-Process notepad; Start-Sleep 1.5
$ws = New-Object -ComObject wscript.shell
$ws.AppActivate("Notepad"); Start-Sleep 0.5
$ws.SendKeys("AI typed this automatically!{ENTER}Line 2")
```

## Windows Update
```
# Check for updates
(New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0")

# Install updates (manual)
# Use Settings > Windows Update or:
usoclient StartScan
usoclient StartDownload
usoclient StartInstall

# ⚠️ Update history
Get-WUHistory | Select Date,Title,Result

# ⚠️ Pause updates for 7 days
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ") -PropertyType String -Force

# ⚠️ Resume updates
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -ErrorAction 0
```

## Installed Programs
```
# All installed programs (registry)
Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach { $_ | Get-ItemProperty } | Select DisplayName,DisplayVersion,Publisher,InstallDate | Sort DisplayName

# 64-bit programs (if running 32-bit PowerShell)
Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction 0 | ForEach { $_ | Get-ItemProperty } | Select DisplayName,DisplayVersion

# Winget (modern package manager)
winget list
winget search firefox
# ⚠️ Install
winget install Mozilla.Firefox
# ⚠️ Uninstall
winget uninstall "Mozilla Firefox"

# AppX packages (Windows Store apps)
Get-AppxPackage | Select Name,Version,InstallLocation | Sort Name

# ⚠️ Remove AppX package for all users
Get-AppxPackage -Name "*xbox*" | Remove-AppxPackage -AllUsers
```

## Remote Management
```
# WinRM status
winrm get winrm/config/service

# ⚠️ Enable WinRM
Enable-PSRemoting -Force

# One-time remote PowerShell
Enter-PSSession -ComputerName "PC-NAME" -Credential (Get-Credential)

# Remote command
Invoke-Command -ComputerName "PC-NAME" -ScriptBlock { Get-Service } -Credential (Get-Credential)

# Test WinRM connectivity
Test-WSMan "PC-NAME"

# RDP status
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections
# 0 = enabled, 1 = disabled
```

## Boot Configuration
```
# Boot entries
bcdedit /enum

# Safe mode boot
bcdedit /set {default} safeboot minimal

# Normal boot
bcdedit /deletevalue {default} safeboot

# Boot from ISO (add entry)
bcdedit /create /d "Windows PE" /application osloader
```

## Power Settings
```
# Power scheme
powercfg /list

# Current scheme details
powercfg /query

# ⚠️ Set scheme to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Sleep/hibernate status
powercfg /a

# Battery report (laptop)
powercfg /batteryreport /output "$env:USERPROFILE\Desktop\battery.html"

# Energy report
powercfg /energy /output "$env:USERPROFILE\Desktop\energy.html"
```

## System Protection & Recovery
```
# Create restore point
Checkpoint-Computer -Description "Before change" -RestorePointType MODIFY_SETTINGS

# System protection status
Get-CimInstance Win32_SystemRestore | Select *

# Advanced startup (reboot to recovery)
# Shutdown /r /o /t 0

# System File Checker
sfc /scannow

# DISM health
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /RestoreHealth
```
