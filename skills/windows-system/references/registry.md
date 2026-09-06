# Registry — Read, Write, Search, ACL

## Read
```
# Keys / subkeys
Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion"

# Values
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion"

# Specific value
(Get-ItemProperty "HKLM:\...\Windows\CurrentVersion").ProgramFilesDir

# Registry for current user
Get-ChildItem HKCU:\Software
```

## ⚠️ Write (confirm with user first!)
```
# Create key
New-Item -Path "HKLM:\Software\MyApp"

# Set value
Set-ItemProperty -Path "HKLM:\Software\MyApp" -Name "Version" -Value "1.0"

# Delete value
Remove-ItemProperty -Path "HKLM:\Software\MyApp" -Name "Version"

# Delete key
Remove-Item -Path "HKLM:\Software\MyApp" -Recurse
```

## Search
```
# Recursive search for key/value
Get-ChildItem HKLM:\Software -Recurse -ErrorAction 0 | Where { $_.Name -match "keyword" }

# Search for specific value data
Get-ChildItem HKCU:\ -Recurse -ErrorAction 0 | ForEach { $props = $_ | Get-ItemProperty -ErrorAction 0; if ($props.PSObject.Properties.Match('keyword')) { $_ } }

# Popular search: uninstall entries
Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach { $_ | Get-ItemProperty } | Select DisplayName,Publisher,InstallDate
```

## Registry Security (ACL)
```
# Get ACL
Get-Acl -Path "HKLM:\Software\MyKey" | Format-List

# ⚠️ Set ACL (grant full control to user)
$acl = Get-Acl "HKLM:\Software\MyKey"
$rule = New-Object System.Security.AccessControl.RegistryAccessRule("Everyone","FullControl","Allow")
$acl.SetAccessRule($rule)
Set-Acl -Path "HKLM:\Software\MyKey" -AclObject $acl
```

## Common Registry Locations
```
# Startup programs (user)
HKCU:\Software\Microsoft\Windows\CurrentVersion\Run

# Startup programs (machine)
HKLM:\Software\Microsoft\Windows\CurrentVersion\Run

# Uninstall
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall

# File associations
HKLM:\Software\Classes\.txt

# Windows settings
HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced

# Network profiles
HKLM:\Software\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles
```
