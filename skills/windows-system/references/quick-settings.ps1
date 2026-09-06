<# 
  Quick Settings Panel for Windows v3
  Tray tool: HDR, power mode, dark mode, volume, RGB off/on, monitor sleep, network monitor
  Pure PowerShell 5.1+ with LightsOff.exe (C#, HID direct to ASUS Aura)
  RGB: COM daemon (ASUS Aura COM Token + SetLightColor) - kills process to restore
  Credit: Reverse-engineered from ASUS Aura HID descriptor (UsagePage 0xFF72, VID_0B05 PID_18F3)
#>

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing

#===================== Win32 API =====================
Add-Type -Name QS -MemberDefinition @'
[DllImport("user32.dll")] public static extern int SendMessage(int h,int m,int w,int l);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int SystemParametersInfo(int uAction,int uParam,string lpvParam,int fuWinIni);
'@

#===================== State =====================
$script:darkMode = $null
$script:vol = 50

#===================== RGB Light Control =====================
$script:sleepModeOn = $false
$script:sleepWasDark = $false
$script:sleepWasVol = 50
$script:lightsOffExe = "$PSScriptRoot\LightsOff.exe"

function Invoke-LightsOff {
    if (Test-Path $script:lightsOffExe) {
        Start-Process $script:lightsOffExe -WindowStyle Hidden
        return $true
    }
    return $false
}

function Invoke-LightsOn {
    Get-Process LightsOff -EA 0 | Stop-Process -Force
    return $true
}

function Invoke-SleepMode {
    $script:sleepWasDark = Get-DarkMode
    $script:sleepWasVol = Get-Volume
    Set-Volume 0
    if (-not $script:sleepWasDark) { Set-DarkMode $true }
    Invoke-LightsOff
    Start-Sleep 5
    $script:sleepModeOn = $true
}

function Invoke-WakeMode {
    Invoke-LightsOn
    Start-Sleep 5
    if (-not $script:sleepWasDark) { Set-DarkMode $false }
    Set-Volume $script:sleepWasVol
    $script:sleepModeOn = $false
}

#===================== Network Monitor =====================
$script:suspiciousPids = @{}

function Show-NetMonitor {
    $nf = New-Object Windows.Forms.Form
    $nf.Text = "Network Monitor"
    $nf.Size = New-Object Drawing.Size(600, 420)
    $nf.StartPosition = "Manual"
    $nf.FormBorderStyle = "FixedToolWindow"
    $nf.TopMost = $true
    $scr = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $nf.Location = New-Object Drawing.Point($scr.Right - $nf.Width - 20, $scr.Bottom - $nf.Height - 60)

    $lv = New-Object Windows.Forms.ListView
    $lv.View = "Details"; $lv.FullRowSelect = $true; $lv.GridLines = $true
    $lv.Location = New-Object Drawing.Point(10, 40); $lv.Size = New-Object Drawing.Size(565, 300)
    $lv.Columns.Add("Process", 140) | Out-Null
    $lv.Columns.Add("PID", 60) | Out-Null
    $lv.Columns.Add("Outbound", 80) | Out-Null
    $lv.Columns.Add("Remote", 200) | Out-Null
    $lv.Columns.Add("State", 60) | Out-Null

    $lblNStatus = New-Object Windows.Forms.Label
    $lblNStatus.Location = New-Object Drawing.Point(10, 10)
    $lblNStatus.Size = New-Object Drawing.Size(400, 25)

    function Refresh-NetList {
        $lv.Items.Clear()
        $conns = try { Get-NetTCPConnection -EA 0 } catch { @() }
        $groups = $conns | Where-Object { $null -ne $_.RemotePort } | Group-Object OwningProcess
        $script:suspiciousPids = @{}
        foreach ($g in $groups) {
            $pname = "unknown"
            try { $p = Get-Process -Id $g.Name -EA 0; if ($p) { $pname = $p.ProcessName } } catch {}
            $cnt = $g.Count
            $rip = ($g.Group | Select-Object -First 5 RemoteAddress,RemotePort | ForEach-Object { "$($_.RemoteAddress):$($_.RemotePort)" }) -join ", "
            if ($cnt -gt 5) { $rip += " ... +$(($cnt-5)) more" }
            $st = ($g.Group | Select-Object -First 1 -ExpandProperty State)
            $item = New-Object Windows.Forms.ListViewItem($pname)
            $item.SubItems.Add($g.Name) | Out-Null
            $item.SubItems.Add($cnt) | Out-Null
            $item.SubItems.Add($rip) | Out-Null
            $item.SubItems.Add($st) | Out-Null
            if ($cnt -gt 15 -and $pname -notmatch "^(chrome|firefox|edge|brave|opera|svchost|System|Idle|WmiPrvSE|lsass|services|explorer)$") {
                $item.BackColor = [Drawing.Color]::FromArgb(255, 200, 200)
                $script:suspiciousPids[$g.Name] = $pname
            }
            $lv.Items.Add($item) | Out-Null
        }
        $lblNStatus.Text = "Conns: $($conns.Count) | Suspicious: $($script:suspiciousPids.Count)"
        if ($script:suspiciousPids.Count -gt 0) { $lblNStatus.ForeColor = [Drawing.Color]::Red }
        else { $lblNStatus.ForeColor = [Drawing.Color]::DarkGreen }
    }

    $btnRefresh = New-Object Windows.Forms.Button
    $btnRefresh.Text = "Refresh"; $btnRefresh.Location = New-Object Drawing.Point(420, 8); $btnRefresh.Size = New-Object Drawing.Size(70, 25)
    $btnRefresh.Add_Click({ Refresh-NetList })

    $btnKill = New-Object Windows.Forms.Button
    $btnKill.Text = "Kill"; $btnKill.Location = New-Object Drawing.Point(495, 8); $btnKill.Size = New-Object Drawing.Size(80, 25)
    $btnKill.Add_Click({
        if ($lv.SelectedItems.Count -gt 0) {
            $pidn = [int]$lv.SelectedItems[0].SubItems[1].Text
            $name = $lv.SelectedItems[0].SubItems[0].Text
            if ($pidn -gt 0) {
                $r = [Windows.Forms.MessageBox]::Show("Kill $name (PID $pidn)?", "Confirm", [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
                if ($r -eq "Yes") { try { Stop-Process -Id $pidn -Force -EA 0 } catch {}; Refresh-NetList }
            }
        }
    })

    $btnCloseNet = New-Object Windows.Forms.Button
    $btnCloseNet.Text = "Close"; $btnCloseNet.Location = New-Object Drawing.Point(495, 345); $btnCloseNet.Size = New-Object Drawing.Size(80, 25)
    $btnCloseNet.Add_Click({ $nf.Close() })

    $nf.Controls.AddRange(@($lblNStatus, $btnRefresh, $btnKill, $lv, $btnCloseNet))
    Refresh-NetList
    if ($script:suspiciousPids.Count -gt 0) {
        $icon.ShowBalloonTip(5000, "Network Monitor", "Found $($script:suspiciousPids.Count) suspicious processes", [Windows.Forms.ToolTipIcon]::Warning)
    }
    $nf.Show()
}

#===================== Helper functions =====================
function Get-DarkMode {
    $reg = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -EA 0
    return $reg.AppsUseLightTheme -eq 0
}
function Set-DarkMode($on) {
    $v = if ($on) { 0 } else { 1 }
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value $v -Type DWord
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value $v -Type DWord
    [QS]::SystemParametersInfo(0x1040,0,"",2)
}
function Get-HDR {
    $reg = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\MonitorDataStore" -EA 0
    return $null -ne $reg
}
function Toggle-HDR {
    Start-Process "ms-settings:display" -WindowStyle Hidden
    Start-Sleep 0.5
    (New-Object -ComObject wscript.shell).SendKeys("{TAB 3}{ENTER}")
}
function Get-PowerScheme { (powercfg /getactivescheme) -replace '.*\((.*?)\).*','$1' }
function Set-PowerScheme($guid) { powercfg /setactive $guid | Out-Null }
function Get-Volume { $v = 0; Add-Type -Name Audio -MemberDefinition '[DllImport("winmm.dll")] public static extern int waveOutGetVolume(int h, out int v);' -EA 0 | Out-Null; [Audio]::waveOutGetVolume(0,[ref]$v); [math]::Round($v / 655.35) }
function Set-Volume($pct) {
    Add-Type -Name Audio2 -MemberDefinition '[DllImport("winmm.dll")] public static extern int waveOutSetVolume(int h, int v);' -EA 0 | Out-Null
    $v = [math]::Round($pct * 655.35)
    if ($v -gt 65535) { $v = 65535 }; if ($v -lt 0) { $v = 0 }
    [Audio2]::waveOutSetVolume(0,$v)
}

#===================== Main form =====================
$form = New-Object Windows.Forms.Form
$form.Text = "Quick Settings"
$form.Size = New-Object Drawing.Size(300,430)
$form.StartPosition = "Manual"
$form.FormBorderStyle = "FixedToolWindow"
$form.ShowInTaskbar = $false
$form.TopMost = $true

$script:darkMode = Get-DarkMode
$script:vol = Get-Volume

# Title
$title = New-Object Windows.Forms.Label
$title.Text = "Quick Settings"
$title.Font = New-Object Drawing.Font("Segoe UI",14,[Drawing.FontStyle]::Bold)
$title.Location = New-Object Drawing.Point(15,15)
$title.Size = New-Object Drawing.Size(260,30)

# HDR
$lblHDR = New-Object Windows.Forms.Label
$lblHDR.Text = "HDR: OFF"; $lblHDR.Location = New-Object Drawing.Point(15,60); $lblHDR.Size = New-Object Drawing.Size(80,25)
$btnHDR = New-Object Windows.Forms.Button
$btnHDR.Text = "Switch"; $btnHDR.Location = New-Object Drawing.Point(180,58); $btnHDR.Size = New-Object Drawing.Size(90,25)
$btnHDR.Add_Click({ Toggle-HDR; [Windows.Forms.MessageBox]::Show("HDR toggle sent.") })

# Power Mode
$lblPower = New-Object Windows.Forms.Label
$lblPower.Text = "Power Mode:"; $lblPower.Location = New-Object Drawing.Point(15,100); $lblPower.Size = New-Object Drawing.Size(80,25)
$cmbPower = New-Object Windows.Forms.ComboBox
$cmbPower.Location = New-Object Drawing.Point(95,98); $cmbPower.Size = New-Object Drawing.Size(175,25)
$cmbPower.DropDownStyle = "DropDownList"
$items = @(
    @{g="381b4222-f694-41f0-9685-ff5bb260df2e";n="Balanced"},
    @{g="a1841308-3541-4fab-bc81-f71556f20b4a";n="Power Saver"},
    @{g="8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c";n="High Performance"}
)
foreach ($i in $items) { [void]$cmbPower.Items.Add($i.n) }
$cmbPower.Add_SelectedIndexChanged({ Set-PowerScheme $items[$cmbPower.SelectedIndex].g })

# Dark Mode
$chkDark = New-Object Windows.Forms.CheckBox
$chkDark.Text = "Dark Mode"; $chkDark.Location = New-Object Drawing.Point(15,140); $chkDark.Size = New-Object Drawing.Size(150,25)
$chkDark.Checked = $script:darkMode
$chkDark.Add_CheckedChanged({ Set-DarkMode $chkDark.Checked })

# Volume
$lblVol = New-Object Windows.Forms.Label
$lblVol.Text = "Volume: $($script:vol)%"; $lblVol.Location = New-Object Drawing.Point(15,180); $lblVol.Size = New-Object Drawing.Size(80,25)
$trackVol = New-Object Windows.Forms.TrackBar
$trackVol.Location = New-Object Drawing.Point(95,175); $trackVol.Size = New-Object Drawing.Size(175,40)
$trackVol.Minimum = 0; $trackVol.Maximum = 100; $trackVol.Value = $script:vol; $trackVol.TickFrequency = 10
$trackVol.Add_Scroll({ $script:vol = $trackVol.Value; Set-Volume $script:vol; $lblVol.Text = "Volume: $($script:vol)%" })

# RGB Lights Off/On
$lblSleep = New-Object Windows.Forms.Label
$lblSleep.Text = "Lights:"; $lblSleep.Location = New-Object Drawing.Point(15,225); $lblSleep.Size = New-Object Drawing.Size(80,25)
$btnSleep = New-Object Windows.Forms.Button
$btnSleep.Text = "Off"; $btnSleep.Location = New-Object Drawing.Point(95,223); $btnSleep.Size = New-Object Drawing.Size(75,25)
$btnSleep.BackColor = [Drawing.Color]::FromArgb(50, 50, 80); $btnSleep.ForeColor = [Drawing.Color]::White
$btnSleep.Add_Click({
    if ($script:sleepModeOn) {
        Invoke-WakeMode
        $btnSleep.Text = "Off"; $btnSleep.BackColor = [Drawing.Color]::FromArgb(50, 50, 80)
        $lblSleep.Text = "Lights:"
        $script:vol = Get-Volume; $trackVol.Value = $script:vol; $lblVol.Text = "Volume: $($script:vol)%"
    } else {
        Invoke-SleepMode
        $btnSleep.Text = "On"; $btnSleep.BackColor = [Drawing.Color]::FromArgb(80, 140, 80)
        $lblSleep.Text = "Lights: OFF"
        $trackVol.Value = 0; $lblVol.Text = "Volume: 0%"
    }
})

# Monitor Sleep
$lblScreen = New-Object Windows.Forms.Label
$lblScreen.Text = "Screen:"; $lblScreen.Location = New-Object Drawing.Point(15,260); $lblScreen.Size = New-Object Drawing.Size(80,25)
$btnScreen = New-Object Windows.Forms.Button
$btnScreen.Text = "Sleep"; $btnScreen.Location = New-Object Drawing.Point(95,258); $btnScreen.Size = New-Object Drawing.Size(75,25)
$btnScreen.Add_Click({
    [QS]::SendMessage(-1, 0x0112, 0xF170, 2)
    if ($btnScreen.Text -eq "Sleep") { $btnScreen.Text = "Wake" }
    else { $btnScreen.Text = "Sleep"; [QS]::SendMessage(-1, 0x0112, 0xF170, -1) }
})

# Net Monitor
$btnNetMon = New-Object Windows.Forms.Button
$btnNetMon.Text = "Net Monitor"; $btnNetMon.Location = New-Object Drawing.Point(180,256); $btnNetMon.Size = New-Object Drawing.Size(90,25)
$btnNetMon.Add_Click({ Show-NetMonitor })

# Close
$btnClose = New-Object Windows.Forms.Button
$btnClose.Text = "Close"; $btnClose.Location = New-Object Drawing.Point(100,370); $btnClose.Size = New-Object Drawing.Size(100,30)
$btnClose.Add_Click({ $form.Close() })

$form.Controls.AddRange(@($title,$lblHDR,$btnHDR,$lblPower,$cmbPower,$chkDark,$lblVol,$trackVol,$lblSleep,$btnSleep,$lblScreen,$btnScreen,$btnNetMon,$btnClose))

#===================== System Tray =====================
$icon = New-Object Windows.Forms.NotifyIcon
$icon.Text = "Quick Settings"
$icon.Icon = [Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell).Source)
$icon.Visible = $true
$icon.Add_Click({
    if ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
        $scr = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $form.Location = New-Object Drawing.Point($scr.Right - $form.Width, $scr.Bottom - $form.Height)
        $form.Show(); $form.Activate()
    }
})

$menu = New-Object Windows.Forms.ContextMenuStrip
$exitItem = New-Object Windows.Forms.ToolStripMenuItem("Exit")
$exitItem.Add_Click({ $icon.Visible = $false; $form.Close(); [System.Windows.Forms.Application]::Exit() })
$menu.Items.Add($exitItem)
$icon.ContextMenuStrip = $menu

Write-Host "[OK] Quick Settings running. Click tray icon to open." -Fore Cyan
Write-Host "Press Ctrl+C in this terminal to exit." -Fore Yellow
$icon.ShowBalloonTip(3000,"Quick Settings","Click tray icon for HDR, power, dark, volume, lights, screen, net",[Windows.Forms.ToolTipIcon]::Info)

[System.Windows.Forms.Application]::Run($form)
