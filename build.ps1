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

# --- 2. upstream game IP list (Keviin Game_IP.mrs -> text) ---
$gameIpUrl = 'https://raw.githubusercontent.com/Keviin560/Shunt_Rules/main/rule/Mihomo/Game_IP.mrs'
$gameIpMrs = Join-Path $build 'upstream-game-ip.mrs'
$gameIpTxt = Join-Path $build 'upstream-game-ip.txt'
Write-Host 'Downloading upstream Game_IP.mrs...'
Invoke-WebRequest $gameIpUrl -OutFile $gameIpMrs -UseBasicParsing
& $exe convert-ruleset ipcidr mrs $gameIpMrs $gameIpTxt
if ($LASTEXITCODE -ne 0) { throw 'failed to convert upstream Game_IP.mrs' }

# --- 3. merge public lists + local rules ---
Write-Host 'Merging sources...'
& python (Join-Path $root 'scripts\merge.py')
if ($LASTEXITCODE -ne 0) { throw 'merge.py failed' }

# --- 4. build mrs ---
function Build-Mrs([string]$behavior, [string]$src, [string]$dst) {
    if (-not (Test-Path $src)) { throw "source not found: $src" }
    Write-Host "  $behavior  $(Split-Path -Leaf $src)  ->  $(Split-Path -Leaf $dst)"
    & $exe convert-ruleset $behavior text $src $dst
    if ($LASTEXITCODE -ne 0) { throw "convert-ruleset failed: $src" }
}

$pairs = @(
    @('domain', (Join-Path $build 'games-domains.txt'),   (Join-Path $dist 'k4reon-games-domains.mrs')),
    @('ipcidr', (Join-Path $build 'games-ip.txt'),        (Join-Path $dist 'k4reon-games-ip.mrs')),
    @('domain', (Join-Path $build 'discord-domains.txt'), (Join-Path $dist 'k4reon-discord-domains.mrs')),
    @('ipcidr', (Join-Path $build 'discord-ip.txt'),      (Join-Path $dist 'k4reon-discord-ip.mrs'))
)
foreach ($p in $pairs) { Build-Mrs $p[0] $p[1] $p[2] }

Copy-Item (Join-Path $root 'rules\games\ports.txt')   (Join-Path $dist 'k4reon-games-ports.txt')   -Force
Copy-Item (Join-Path $root 'rules\discord\ports.txt') (Join-Path $dist 'k4reon-discord-ports.txt') -Force

Write-Host ''
Write-Host 'Built files:'
Get-ChildItem $dist | Sort-Object Name | ForEach-Object {
    '{0,-28} {1,8} bytes' -f $_.Name, $_.Length
}
