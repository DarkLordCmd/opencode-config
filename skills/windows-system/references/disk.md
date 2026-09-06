# Disk — Volumes, Permissions, Symlinks, BitLocker

## Drives & Volumes
```
# All volumes
Get-Volume | Select DriveLetter,FileSystemType,SizeRemaining,Size

# Free space %
Get-PSDrive -PSProvider FileSystem | Select Name,@{N='FreeGB';E={$_.Free/1GB}},@{N='Used%';E={[math]::Round((1-$_.Free/$_.Used)*100,1)}}

# Disk partitions
Get-Partition | Select DiskNumber,DriveLetter,Size,Type

# Disk health (SMART)
Get-PhysicalDisk | Select FriendlyName,MediaType,HealthStatus,Size
```

## File & Folder Permissions
```
# Who has access
icacls C:\Path\To\Folder

# Get owner
Get-Acl C:\Path | Select Owner

# ⚠️ Take ownership
takeown /f C:\Path /r
icacls C:\Path /grant "$env:USERNAME:F" /t

# Check if file is in use
Get-Process | Where { $_.Modules.FileName -eq "C:\Path\file.dll" }
```

## Symbolic Links, Junctions, Hard Links
```
# List all symlinks in folder
Get-ChildItem -Recurse | Where { $_.LinkType }

# Create symlink (file)
New-Item -ItemType SymbolicLink -Path "link.txt" -Target "real.txt"

# Create symlink (directory)
New-Item -ItemType SymbolicLink -Path "LinkDir" -Target "RealDir"

# Create junction
New-Item -ItemType Junction -Path "JunctionDir" -Target "RealDir"

# Create hard link
New-Item -ItemType HardLink -Path "hardlink.txt" -Target "real.txt"
```

## Large Files & Cleanup
```
# Top 20 largest files
Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue | Sort Length -Desc | Select -f 20

# Folder sizes
Get-ChildItem C:\Users -Directory | ForEach { $s=(Get-ChildItem $_ -Recurse -ErrorAction 0 | Measure Length -Sum).Sum; [PSCustomObject]@{Folder=$_.Name;SizeGB=[math]::Round($s/1GB,2)} } | Sort SizeGB -Desc

# Disk cleanup (built-in)
cleanmgr /sageset:1
cleanmgr /sagerun:1

# Temp files
Get-ChildItem $env:TEMP -Recurse -ErrorAction 0 | Remove-Item -Recurse -Force -ErrorAction 0
```

## BitLocker
```
# Encryption status
Get-BitLockerVolume | Select MountPoint,ProtectionStatus,EncryptionPercentage

# Recovery key (AD)
Get-BitLockerVolume | fl RecoveryPassword*

# ⚠️ Enable BitLocker
Enable-BitLocker C: -PasswordProtector -Password (ConvertTo-SecureString "xxxx" -AsPlainText -Force)
```

## Other
```
# Mount point / reparse points
Get-ChildItem C: -Directory | Where { $_.Attributes -match 'ReparsePoint' }

# Disk usage per directory (large folders)
Get-PSDrive C | ForEach { $_.Used }

# Volume shadow copies
Get-CimInstance Win32_ShadowCopy | Select ID,InstallDate,DeviceObject
```
