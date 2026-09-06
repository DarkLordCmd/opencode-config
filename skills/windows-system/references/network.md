# Network — IP, DNS, Firewall, WiFi, Connections

## Quick Diagnosis Chain
```
# Test connectivity
Test-Connection 8.8.8.8 -Count 2

# DNS resolution
Resolve-DnsName google.com

# Default gateway
Get-NetRoute | Where DestinationPrefix -eq '0.0.0.0/0'

# Active connections summary
Get-NetTCPConnection | Group State | Sort Count -Desc

# Firewall status
Get-NetFirewallProfile | Select Name,Enabled
```

## IP Configuration
```
# All adapters with IP
Get-NetIPAddress | Select InterfaceAlias,IPAddress,PrefixLength

# DHCP status
Get-NetIPInterface | Select InterfaceAlias,Dhcp

# Release/renew IP
ipconfig /release; ipconfig /renew

# Flush DNS
ipconfig /flushdns
```

## DNS
```
# DNS client cache
Get-DnsClientCache

# DNS servers per adapter
Get-DnsClientServerAddress | Select InterfaceAlias,ServerAddresses

# Clear cache
Clear-DnsClientCache
```

## Active Connections
```
# All TCP connections
Get-NetTCPConnection | Select LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess

# Listening ports
Get-NetTCPConnection | Where State -eq 'Listen'

# ESTABLISHED connections by remote IP
Get-NetTCPConnection | Where State -eq 'Established' | Group RemoteAddress | Sort Count -Desc
```

## Firewall
```
# All enabled rules
Get-NetFirewallRule | Where Enabled -eq $true | Select DisplayName,Direction,Action

# Rules blocking a port
Get-NetFirewallRule | Where { $_.Enabled -and ($_. | Get-NetFirewallPortFilter).LocalPort -eq 8080 }

# ⚠️ Allow port
New-NetFirewallRule -DisplayName "Allow 8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

## WiFi
```
# Available networks
netsh wlan show networks

# Current connection
netsh wlan show interfaces

# Saved profiles
netsh wlan show profiles

# ⚠️ Connect
netsh wlan connect name="SSID"

# ⚠️ Forget profile
netsh wlan delete profile name="SSID"

# Generate QR for guest WiFi
netsh wlan show profile name="SSID" key=clear
```

## Network Shares & Routing
```
# Mapped drives
Get-SmbMapping

# ⚠️ Map drive
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\server\share" -Persist

# Routing table
Get-NetRoute | Select DestinationPrefix,NextHop,InterfaceAlias

# ⚠️ Add route
route add 10.0.0.0 mask 255.0.0.0 192.168.1.1

# Current network speed/adapter info
Get-NetAdapter | Select Name,LinkSpeed,Status,MacAddress
```
