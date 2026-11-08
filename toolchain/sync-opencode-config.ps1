# Sync the local opencode config into the GitHub mirror (DarkLordCmd/opencode-config).
# Copies only what changed: new skill directories and AGENTS.md. Existing tracked files are left
# alone, so line-ending differences never produce a 900-file commit.
#
#   powershell -ExecutionPolicy Bypass -File E:\pintest\tools\sync-opencode-config.ps1
#   ... -Message "custom commit message" -DryRun

param(
    [string]$Message = "",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$mirror = 'E:\pintest\tools\opencode-config-sync'
$local  = "$env:USERPROFILE\.config\opencode"
$agents = "$env:USERPROFILE\.agents\skills"
$remote = 'https://github.com/DarkLordCmd/opencode-config.git'

if (-not (Test-Path $mirror)) {
    git clone --depth 1 $remote $mirror
} else {
    git -C $mirror fetch --depth 1 origin main | Out-Null
    # Never reset a dirty mirror: that would silently discard edits made by hand (e.g. README).
    $dirty = (git -C $mirror status --porcelain | Measure-Object).Count
    if ($dirty -gt 0) {
        Write-Warning "mirror has $dirty uncommitted change(s) - not resetting; commit or discard them first"
    } else {
        git -C $mirror merge --ff-only origin/main | Out-Null
    }
}

# AGENTS.md
Copy-Item "$local\AGENTS.md" "$mirror\AGENTS.md" -Force
if (-not (Test-Path "$mirror\opencode.json")) { Copy-Item "$local\opencode.json" "$mirror\opencode.json" -Force }

# new skill directories only
$added = @()
foreach ($pair in @(@{ src = "$local\skills"; dst = "$mirror\skills" },
                    @{ src = $agents;        dst = "$mirror\agents-skills" })) {
    if (-not (Test-Path $pair.src)) { continue }
    $existing = @()
    if (Test-Path $pair.dst) { $existing = (Get-ChildItem $pair.dst -Directory).Name }
    foreach ($d in Get-ChildItem $pair.src -Directory) {
        if ($existing -contains $d.Name) { continue }
        Copy-Item $d.FullName (Join-Path $pair.dst $d.Name) -Recurse -Force
        $added += $d.Name
    }
}

Write-Host ("[+] new skills: {0}" -f ($added.Count)) -ForegroundColor Cyan
if ($added.Count) { $added -join ', ' | Write-Host }

git -C $mirror add -A
$changed = (git -C $mirror status --porcelain | Measure-Object).Count
Write-Host ("[+] changed entries: {0}" -f $changed)

if ($changed -eq 0) { Write-Host '[=] nothing to sync'; exit 0 }
if ($DryRun) { git -C $mirror status --short | Select-Object -First 40; exit 0 }

if (-not $Message) {
    $Message = "sync: add $($added.Count) skills, refresh AGENTS.md"
}
git -C $mirror -c user.name="DarkLordCmd" -c user.email="operator@local" commit -q -m $Message
git -C $mirror push origin main
Write-Host '[+] pushed' -ForegroundColor Green
