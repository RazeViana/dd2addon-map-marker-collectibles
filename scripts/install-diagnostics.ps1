param(
    [Parameter(Mandatory = $true)]
    [string]$GamePath
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$gameRoot = (Resolve-Path -LiteralPath $GamePath).Path
if (-not (Test-Path -LiteralPath (Join-Path $gameRoot 'DD2.exe') -PathType Leaf)) {
    throw 'The target must be the game folder containing DD2.exe.'
}
$relativeFiles = @(
    'reframework/autorun/raze_MapMarkersAndCollectables_Diagnostics.lua',
    'reframework/autorun/raze_MapMarkersAndCollectables/diagnostics.lua'
)
$copies = foreach ($relativePath in $relativeFiles) {
    $source = [IO.Path]::GetFullPath((Join-Path $projectRoot $relativePath))
    $destination = [IO.Path]::GetFullPath((Join-Path $gameRoot $relativePath))
    if (-not $destination.StartsWith($gameRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Destination is outside the game folder.'
    }
    $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if (Test-Path -LiteralPath $destination) {
        if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $sourceHash) {
            throw "A different diagnostics file already exists: $destination"
        }
    }
    [pscustomobject]@{Source = $source; Destination = $destination; Hash = $sourceHash}
}
foreach ($copy in $copies) {
    if (-not (Test-Path -LiteralPath $copy.Destination)) {
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $copy.Destination) -Force
        Copy-Item -LiteralPath $copy.Source -Destination $copy.Destination
    }
    if ((Get-FileHash -LiteralPath $copy.Destination -Algorithm SHA256).Hash -ne $copy.Hash) {
        throw "Installed diagnostics verification failed: $($copy.Destination)"
    }
    Write-Output "Verified $($copy.Destination)"
}
Write-Output 'Diagnostics staged. The next game launch exports the minimap report; existing mods and settings were not changed.'
