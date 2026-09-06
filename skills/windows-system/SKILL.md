---
name: windows-system
description: Use when managing, troubleshooting, or inspecting Windows systems — processes, services, disk, network, registry, users, event logs, updates, or system configuration. Covers PowerShell-native commands for system administration.
---

# Windows System Skill

## Overview
PowerShell-native Windows administration — inspect and control every major subsystem. Commands are production-ready one-liners, usable as-is.

## 反例清单（不要做什么）

| 反模式 | 为什么不要做 | 替代做法 |
|--------|------------|---------|
| 未经确认直接执行破坏性命令 | 可能导致数据丢失或系统不可用 | 先用 `-WhatIf` 预览，再向用户确认 |
| 在非管理员 PowerShell 执行 admin 操作 | 命令静默失败或 Access Denied | 先检查 `[Security.Principal.WindowsIdentity]::GetCurrent().Groups` |
| 改注册表/系统配置前不建还原点 | 改坏了无法恢复 | 先执行 `Checkpoint-Computer` |
| 杀死进程/服务前不确认 | 可能误杀系统关键进程 | 先 `Get-Process -Name` 确认，再问用户 |
| 跳过诊断直接给方案 | 可能方向错误浪费时间 | 按 Symptom → File Map 先跑诊断命令 |

## Quick Symptom → File Map

| If user says... | Open this file |
|----------------|----------------|
| "电脑卡/慢/CPU高" | [process.md](references/process.md) |
| "网络不通/掉线/防火墙" | [network.md](references/network.md) |
| "磁盘满了/文件删不掉" | [disk.md](references/disk.md) |
| "蓝屏/报错/崩溃" | [event.md](references/event.md) |
| "装了什么/更新/卸载" | [manage.md](references/manage.md) |
| "用户权限不够/加人" | [user.md](references/user.md) |
| "改注册表/搜注册表" | [registry.md](references/registry.md) |
| "啥系统/多少内存/硬件" | [system.md](references/system.md) |

## Safety Rules

- `⚠️` prefix = destructive. **Always confirm with user before running.**
- Add `-WhatIf` to preview before write operations
- Admin operations require elevated PowerShell
- Registry/system changes should have a restore point first
- Before UI automation (SendKeys): always switch IME to English first
- Before killing processes/services: confirm with user AND verify the process name

### 🔴 CHECKPOINT: 执行任何破坏性操作前

```
1. 确认操作用户 → 谁是目标进程/文件的 owner?
2. 确认影响范围 → 就这一个进程，还是有依赖链?
3. 备份机制 → 有还原点吗？有备份吗？
4. 确认用户许可 → 用户明确说"执行"了吗？
```

**以上 4 条有一条不满足 → 🛑 STOP，先补齐再执行。**

## Recommended Workflow

1. Identify symptom → open matching reference file
2. Run diagnostic commands to confirm root cause
3. Propose fix to user, confirm, then execute
4. Verify fix and report result

### 🔴 CHECKPOINT: 工作流关键节点

| 阶段 | 必须检查 | 如果通不过 → |
|------|---------|-----------|
| Step 2 诊断后 | 诊断结果明确指向一个根因 | 返回到 Step 1 重新匹配症状 |
| Step 3 提议后 | 用户明确同意执行 | 解释风险后再次确认 |
| Step 4 执行后 | 验证命令返回预期结果 | 回滚操作或尝试备用方案 |

## Quick Diagnosis Chains

| Symptom | Run this first | 如果诊断不出 → |
|---------|---------------|--------------|
| "电脑卡/慢" | `gps \| sort cpu -desc \| select -f 10` → `Get-Counter "\Processor(_Total)\% Processor Time"` → `gps \| sort ws -desc \| select -f 5` | 检查磁盘 I/O（`Get-Counter "\LogicalDisk(*)\% Disk Time"`）或内存页错误 |
| "上不了网" | `Test-Connection 8.8.8.8 -Count 2` → `Resolve-DnsName google.com` → `Get-NetRoute \| Where DestinationPrefix -eq '0.0.0.0/0'` → `Get-NetFirewallProfile \| Select Name,Enabled` | 检查 `ipconfig` → 是否 DHCP 获取正常 → `netsh winsock reset` |
| "磁盘满了" | `Get-PSDrive -PSProvider FileSystem \| Select Name,@{N='FreeGB';E={[int]($_.Free/1GB)}},@{N='Used%';E={[math]::Round((1-$_.Free/($_.Used+$_.Free))*100,1)}}` | `Get-ChildItem -Recurse \| Sort Length -desc \| select -f 20` 找大文件 |
| "蓝屏/崩溃" | `Get-WinEvent -FilterHashtable @{LogName='System';ID=1001,1074,6008,41} -MaxEvents 10 \| Select TimeCreated,Id,Message` | 检查 `%SystemRoot%\Minidump` 里有没有 dump 文件 |
| "某应用打不开" | `Get-WinEvent -FilterHashtable @{LogName='Application';Level=1,2} -MaxEvents 20` → `Get-Process -Name "appname" -ErrorAction 0` | 检查服务依赖：`Get-Service \| Where DependentServices` |
| "开机慢" | `Get-CimInstance Win32_StartupCommand \| Select Name,Command,Location` → `Get-Service \| Where { \$_.StartType -eq 'Automatic' -and \$_.Status -ne 'Running' }` | `Get-WinEvent -FilterHashtable @{LogName='System';ID=12,13} -MaxEvents 10` 检查驱动加载耗时 |
| "端口被占用" | `Get-NetTCPConnection \| Where State -eq 'Listen' \| Select LocalPort,@{N='Proc';E={(gps -Id \$_.OwningProcess -ErrorAction 0).ProcessName}} \| Sort LocalPort` | 用 `netstat -ano \| findstr :PORT` 二次确认 PID |
| "WiFi连不上" | `netsh wlan show interfaces` → `netsh wlan show networks` → `ipconfig /flushdns` | `netsh wlan delete profile name="SSID"` 重新连接 |
| "文件删不掉" | `Get-Process \| Where { \$_.Modules.FileName -like "*filename*" }` → `icacls "path"` → `Get-Acl "path" \| Select Owner` | `handle64.exe "path"`（Sysinternals）或重启后删除 |
| "用户密码忘了" | `net user username *` (管理员运行，可设新密码) | 用 PE 盘做密码重置 |

## JSON Output Mode (for AI consumption)

Wrap any command to return structured JSON:
```
# Single command
[PSCustomObject]@{status='ok';data=(gps | sort cpu -desc | select -f 3 Name,CPU,Id)} | ConvertTo-Json

# Error wrapper
try { $r = Get-Process -Name chrome -ErrorAction Stop; [PSCustomObject]@{status='ok';count=$r.Count} }
catch { [PSCustomObject]@{status='error';message=$_.Exception.Message} } | ConvertTo-Json
```

## Edge/Chrome Browser Control (CDP)

Start Edge/Chrome with remote debugging, then send CDP commands via PowerShell:
```
# Launch browser with CDP
Start-Process msedge "--remote-debugging-port=9222 --user-data-dir=$env:TEMP\edge-cdp"
# Or Chrome: Start-Process chrome "--remote-debugging-port=9222"

# Navigate to URL
$ws = New-Object System.Net.WebSockets.ClientWebSocket
$ws.ConnectAsync("ws://127.0.0.1:9222/devtools/page/$(curl -s http://127.0.0.1:9222/json | ConvertFrom-Json | Select -First 1 -Expand id)", [System.Threading.CancellationToken]::None).Wait()
# Then send Page.navigate, Runtime.evaluate, etc. via WebSocket
# Shortcut: use Python + playwright/websockets for complex automation
```

### 🛑 STOP: CDP 使用前提
- 确保 360 等安全软件已退出（CDP 会被标记）
- 浏览器启动参数 `--remote-debugging-port=9222` 必须正确
- WebSocket 端点从 `/json` 接口获取，硬编码会失效

## Before Destructive Operations

Run this to create a restore point (admin required):
```
Checkpoint-Computer -Description "Before change at $(Get-Date)" -RestorePointType MODIFY_SETTINGS
```
