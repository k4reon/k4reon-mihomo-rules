# Build k4reon mihomo rule-sets: merge public sources + local additions.
$ErrorActionPreference = 'Stop'

$root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$tools = Join-Path $root '.tools'
$build = Join-Path $root 'build'
$dist  = Join-Path $root 'dist'
$exe   = Join-Path $tools 'mihomo.exe'

New-Item -ItemType Directory -Force -Path $tools, $build, $dist | Out-Null

# --- 1. mihomo ---
if (-not (Test-Path $exe)) {
    Write-Host 'Downloading latest mihomo for Windows...'
    $release = Invoke-RestMethod 'https://api.github.com/repos/MetaCubeX/mihomo/releases/latest' `
        -Headers @{ 'User-Agent' = 'k4reon-mrs-build' }
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

$env:MIHOMO_BIN = $exe

# --- 2. merge public lists + local rules ---
Remove-Item "$dist\*" -Force -ErrorAction SilentlyContinue
Remove-Item "$build\*-domains.txt","$build\*-ip.txt","$build\upstream-*" -Force -ErrorAction SilentlyContinue
Write-Host 'Merging sources...'
& python (Join-Path $root 'scripts\merge.py')
if ($LASTEXITCODE -ne 0) { throw 'merge.py failed' }

# --- 3. build mrs from every build/<group>-domains.txt / <group>-ip.txt ---
function Build-Mrs([string]$behavior, [string]$src, [string]$dst) {
    if (-not (Test-Path $src)) { return }
    Write-Host "  $behavior  $(Split-Path -Leaf $src)  ->  $(Split-Path -Leaf $dst)"
    & $exe convert-ruleset $behavior text $src $dst
    if ($LASTEXITCODE -ne 0) { throw "convert-ruleset failed: $src" }
}

Get-ChildItem $build -Filter '*-domains.txt' | ForEach-Object {
    $g = $_.BaseName -replace '-domains$', ''
    Build-Mrs 'domain' $_.FullName (Join-Path $dist "k4reon-$g-domains.mrs")
}
Get-ChildItem $build -Filter '*-ip.txt' | ForEach-Object {
    $g = $_.BaseName -replace '-ip$', ''
    Build-Mrs 'ipcidr' $_.FullName (Join-Path $dist "k4reon-$g-ip.mrs")
}

# --- 4. copy classical rule files (ports/classical/custom) ---
Get-ChildItem (Join-Path $root 'rules') -Directory | ForEach-Object {
    $group = $_.Name
    Get-ChildItem $_.FullName -Filter '*.txt' | Where-Object {
        $_.Name -notin @('domains.txt', 'ipcidr.txt')
    } | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $dist "k4reon-$group-$($_.Name)") -Force
    }
}

# --- 5. publish readable full lists (merged, not just local additions) ---
$lists = Join-Path $dist 'lists'
Remove-Item $lists -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $lists | Out-Null
Get-ChildItem $build -Filter '*-domains.txt' | ForEach-Object {
    $g = $_.BaseName -replace '-domains$', ''
    Copy-Item $_.FullName (Join-Path $lists "k4reon-$g-domains.txt") -Force
}
Get-ChildItem $build -Filter '*-ip.txt' | ForEach-Object {
    $g = $_.BaseName -replace '-ip$', ''
    Copy-Item $_.FullName (Join-Path $lists "k4reon-$g-ip.txt") -Force
}

Write-Host ''
Write-Host 'Built files:'
Get-ChildItem $dist | Sort-Object Name | ForEach-Object {
    '{0,-32} {1,8} bytes' -f $_.Name, $_.Length
}
