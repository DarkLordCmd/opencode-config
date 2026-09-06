# Process, Services, Task Scheduler, Startup

## Processes
```
# All processes
Get-Process | Select Name,CPU,WS,Id,StartTime

# Top 10 by memory
gps | sort ws -desc | select -f 10

# Top 10 by CPU
gps | sort cpu -desc | select -f 10

# Specific process detail
gps -Name chrome | fl *

# Process with most handles
gps | sort handles -desc | select -f 10

# Port → process mapping
netstat -ano | findstr LISTEN
# Then: gps -Id <PID>

# ⚠️ Kill by name
Stop-Process -Name notepad -Force

# Kill by port
$pid = (netstat -ano | findstr :8080 | select -f 1) -split ' ' | ?{$_} | select -l 1
Stop-Process -Id $pid -Force
```

## Services
```
# All services with status
Get-Service | Select Name,DisplayName,Status,StartType

# Specific
Get-Service spooler

# Can start/stop/restart
Restart-Service spooler
Start-Service wuauserv
Stop-Service wuauserv

# Set startup type
Set-Service wuauserv -StartupType Automatic

# Services that failed to start
Get-Service | Where Status -eq 'Stopped' -and StartType -ne 'Disabled'
```

## Task Scheduler
```
# All tasks
Get-ScheduledTask | Select TaskName,State

# Task details
Get-ScheduledTask -TaskName "\Microsoft\Windows\..." | fl *

# Run task
Start-ScheduledTask -TaskName "..."

# ⚠️ Disable task
Disable-ScheduledTask -TaskName "..."
```

## Startup Programs
```
# From registry (user)
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# From registry (machine)
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"

# From Task Manager startup tab
Get-CimInstance Win32_StartupCommand | Select Name,Command,Location
```
