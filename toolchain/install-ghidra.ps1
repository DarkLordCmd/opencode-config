# Portable Ghidra: no admin, no installer. Extracts to E:\pintest\tools\ghidra.
$ErrorActionPreference = 'Stop'
$root = 'E:\pintest\tools'
$zip = Join-Path $root 'ghidra.zip'
$dst = Join-Path $root 'ghidra'

if (Test-Path (Join-Path $dst 'ghidraRun.bat')) { Write-Host '[=] Ghidra already present'; exit 0 }

Write-Host '[*] resolving latest Ghidra release'
$rel = Invoke-RestMethod 'https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest' `
    -Headers @{ 'User-Agent' = 'pt-install' }
$asset = $rel.assets | Where-Object { $_.name -like '*_PUBLIC_*.zip' } | Select-Object -First 1
if (-not $asset) { throw 'no PUBLIC zip asset in latest release' }

Write-Host ("[*] {0} ({1:n1} MB)" -f $asset.name, ($asset.size / 1MB))
Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing

Write-Host '[*] extracting'
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $root -Force
$inner = Get-ChildItem $root -Directory | Where-Object { $_.Name -like 'ghidra_*_PUBLIC' } | Select-Object -First 1
if ($inner -and $inner.FullName -ne $dst) {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Move-Item $inner.FullName $dst
}
Remove-Item $zip -Force

$run = Join-Path $dst 'ghidraRun.bat'
if (Test-Path $run) {
    Write-Host ("[+] Ghidra ready: {0}" -f $run)
    $j = (Get-Command java -ErrorAction SilentlyContinue)
    if ($j) { Write-Host ("[+] java: " + ((& $j.Source -version 2>&1) | Select-Object -First 1)) }
    else { Write-Host '[!] java not found in PATH — Ghidra needs JDK 21+' }
} else {
    throw 'ghidraRun.bat not found after extraction'
}
