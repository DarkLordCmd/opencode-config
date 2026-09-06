# User — Accounts, Groups, Permissions, UAC

## User Accounts
```
# All users
Get-LocalUser | Select Name,Enabled,LastLogon,PasswordLastSet

# Current user
whoami
$env:USERNAME

# User details
Get-LocalUser -Name "username" | fl *

# Logon events (recent)
Get-WinEvent -FilterHashtable @{LogName='Security';ID=4624} -MaxEvents 20
```

## ⚠️ User Management
```
# Create user
New-LocalUser -Name "username" -Password (ConvertTo-SecureString "Pass123!" -AsPlainText -Force)

# Enable/disable user
Enable-LocalUser -Name "username"
Disable-LocalUser -Name "username"

# Change password
Set-LocalUser -Name "username" -Password (ConvertTo-SecureString "NewPass!" -AsPlainText -Force)

# Remove user
Remove-LocalUser -Name "username"

# Lock/unlock
Set-LocalUser -Name "username" -AccountNeverExpires $true
```

## Groups
```
# All groups
Get-LocalGroup | Select Name,Description

# Group members
Get-LocalGroupMember -Group Administrators

# Add user to group
Add-LocalGroupMember -Group Administrators -Member "username"

# Remove user from group
Remove-LocalGroupMember -Group Administrators -Member "username"
```

## Privilege & Security Policy
```
# Current user privileges
whoami /priv

# User rights assignments
secedit /export /cfg C:\secpolicy.inf
Get-Content C:\secpolicy.inf | Select-String "SeNetworkLogonRight"

# Password policy
net accounts

# ⚠️ Set password policy (domain)
net accounts /minpwlen:8 /maxpwage:90
```

## UAC
```
# UAC status
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" | Select EnableLUA,ConsentPromptBehaviorAdmin

# Check if running as admin
[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

## Audit Policy
```
# Current audit policy
auditpol /get /category:*

# ⚠️ Enable account logon auditing
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
```
