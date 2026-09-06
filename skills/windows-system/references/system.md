# System — OS, Hardware, Environment

## OS Info
```
# Version, build, edition
Get-CimInstance Win32_OperatingSystem | Select Caption,Version,BuildNumber,OSArchitecture

# Installed hotfixes
Get-HotFix | Sort InstalledOn -Desc | Select HotFixID,InstalledOn,Description

# Activation status
slmgr /dli
```

## Hardware
```
# CPU
Get-CimInstance Win32_Processor | Select Name,NumberOfCores,MaxClockSpeed

# RAM (total/available)
Get-CimInstance Win32_ComputerSystem | Select TotalPhysicalMemory
Get-Counter "\Memory\Available MBytes"

# Motherboard
Get-CimInstance Win32_BaseBoard | Select Manufacturer,Product

# GPU
Get-CimInstance Win32_VideoController | Select Name,RAM,DriverVersion

# Disk drives (physical, not volumes)
Get-CimInstance Win32_DiskDrive | Select Model,Size,MediaType
```

## BIOS / UEFI
```
Get-CimInstance Win32_BIOS | Select Manufacturer,SMBIOSBIOSVersion,SerialNumber
# Boot mode: if SecureBoot == 1 → UEFI
Get-CimInstance Win32_ComputerSystem | Select BootupState
Confirm-SecureBootUEFI
```

## Environment Variables
```
# User
Get-ChildItem Env: | Out-GridView

# Read one
$env:PATH

# Set (session only)
$env:MYVAR = "value"

# Set persistent (user scope)
[Environment]::SetEnvironmentVariable("MYVAR","value","User")
```

## System Restore
```
# List restore points
Get-ComputerRestorePoint

# ⚠️ Create restore point
Checkpoint-Computer -Description "Before changes" -RestorePointType MODIFY_SETTINGS

# ⚠️ Restore
Restore-Computer -RestorePoint 1
```

## Other
```
# Windows edition
(Get-CimInstance Win32_OperatingSystem).Caption

# System uptime
(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

# Computer name, domain/workgroup
Get-CimInstance Win32_ComputerSystem | Select Name,Domain,Workgroup,PartOfDomain
```
