# Build custom mihomo rule-sets (mrs + classical yaml).
# Requires: PowerShell 5+, internet access on first run.
$ErrorActionPreference = 'Stop'

$root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$tools = Join-Path $root '.tools'
$dist  = Join-Path $root 'dist'
$exe   = Join-Path $tools 'mihomo.exe'

New-Item -ItemType Directory -Force -Path $tools, $dist | Out-Null

if (-not (Test-Path $exe)) {
    Write-Host 'Downloading latest mihomo for Windows...'
    $release = Invoke-RestMethod 'https://api.github.com/repos/MetaCubeX/mihomo/releases/latest' `
        -Headers @{ 'User-Agent' = 'MRS-MIHOMO-build' }
    $asset = $release.assets |
        Where-Object { $_.name -match 'windows-amd64' -and $_.name -notmatch 'compatible' -and $_.name -like '*.zip' } |
        Select-Object -First 1
    if (-not $asset) { throw 'mihomo windows-amd64 zip asset not found' }

    $zip = Join-Path $tools 'mihomo.zip'
    Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing
    $tmp = Join-Path $tools 'unpack'
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive $zip -DestinationPath $tmp -Force
    $found = Get-ChildItem $tmp -Recurse -Filter 'mihomo*.exe' | Select-Object -First 1
    if (-not $found) { throw 'mihomo.exe not found in archive' }
    Move-Item $found.FullName $exe -Force
    Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

function Build-Mrs([string]$behavior, [string]$src, [string]$dst) {
    if (-not (Test-Path $src)) { throw "source not found: $src" }
    Write-Host "  $behavior  $(Split-Path -Leaf $src)  ->  $(Split-Path -Leaf $dst)"
    & $exe convert-ruleset $behavior text $src $dst
    if ($LASTEXITCODE -ne 0) { throw "convert-ruleset failed: $src" }
}

$groups = @('games', 'discord')
foreach ($g in $groups) {
    $srcDir = Join-Path $root "rules\$g"
    Build-Mrs 'domain' (Join-Path $srcDir 'domains.txt') (Join-Path $dist "k4reon-$g-domains.mrs")
    Build-Mrs 'ipcidr' (Join-Path $srcDir 'ipcidr.txt')  (Join-Path $dist "k4reon-$g-ip.mrs")
    Copy-Item (Join-Path $srcDir 'ports.yaml') (Join-Path $dist "k4reon-$g-ports.yaml") -Force
}

Write-Host ''
Write-Host 'Built files:'
Get-ChildItem $dist | Sort-Object Name | ForEach-Object {
    '{0,-28} {1,8} bytes' -f $_.Name, $_.Length
}
