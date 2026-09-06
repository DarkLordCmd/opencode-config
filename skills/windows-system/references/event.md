# Event Logs, Performance, Crash Dumps

## Quick Diagnosis
```
# System errors (recent)
Get-WinEvent -FilterHashtable @{LogName='System';Level=1,2} -MaxEvents 20 | Select TimeCreated,Id,LevelDisplayName,Message

# Application errors
Get-WinEvent -FilterHashtable @{LogName='Application';Level=1,2} -MaxEvents 20

# Last 3 crash/restart events
Get-WinEvent -FilterHashtable @{LogName='System';ID=1001,1074,6008} -MaxEvents 10 | Select TimeCreated,Id,Message
```

## Common Event IDs
| ID | Meaning | Log |
|----|---------|-----|
| 1001 | Application crash / Windows Error Reporting | System |
| 1074 | Shutdown / restart by user or process | System |
| 6008 | Unexpected shutdown (power loss / crash) | System |
| 41 | Kernel-Power (unexpected shutdown) | System |
| 4624 | Successful logon | Security |
| 4625 | Failed logon | Security |
| 4634 | Logoff | Security |
| 4688 | Process created | Security |
| 5156 | Network connection allowed | Security |
| 5157 | Network connection blocked | Security |

## Event Log Details
```
# Log names available
Get-WinEvent -ListLog * | Where RecordCount -gt 0 | Select LogName,RecordCount

# Filter by time range
$start = (Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{LogName='System';StartTime=$start;Level=1,2}

# Filter by source (application name)
Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='.NET Runtime'} -MaxEvents 10

# Export logs
wevtutil epl System C:\temp\system.evtx
```

## Performance Counters
```
# CPU usage
Get-Counter "\Processor(_Total)\% Processor Time"

# Memory
Get-Counter "\Memory\Available MBytes"
Get-Counter "\Memory\Pages/sec"

# Disk
Get-Counter "\PhysicalDisk(_Total)\% Disk Time"

# Network
Get-Counter "\Network Interface(*)\Bytes Total/sec"

# All counters for a category
Get-Counter -ListSet "Processor" | Select -ExpandProperty Paths
```

## Crash Dumps & Reliability
```
# Reliability history
Get-CimInstance Win32_ReliabilityRecords | Sort TimeGenerated -Desc | Select TimeGenerated,ProductName,ProblemIdentifier | Format-Table -AutoSize

# Minidumps
Get-ChildItem C:\Windows\Minidump | Sort LastWriteTime -Desc

# Full memory dumps
Get-ChildItem C:\Windows\MEMORY.DMP

# Read minidump (brief)
# Requires Debugging Tools for Windows
# !analyze -v in WinDbg
```

## Scripted Performance Capture
```
# Quick perf snapshot (10s CPU/RAM/Disk)
$samples = Get-Counter "\Processor(_Total)\% Processor Time","\Memory\Available MBytes","\PhysicalDisk(_Total)\% Disk Time" -SampleInterval 1 -MaxSamples 10
$samples | Select Timestamp,CounterSamples
```

## Disk & Memory Analysis
```
# Processes with highest handle count
gps | sort handles -desc | select -f 10

# Memory pressure
(Get-Counter "\Memory\Available MBytes").CounterSamples[0].CookedValue

# Commit charge
Get-CimInstance Win32_OperatingSystem | Select TotalVisibleMemorySize,FreePhysicalMemory,TotalVirtualMemorySize,FreeVirtualMemory
```
