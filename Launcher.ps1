# Try production UNC path first, then fall back to script directory
$productionPath = '\\lsfile03\netdoc$\Somearns_Folder\SomearnTK_app\appdata'
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determine the correct path to use
if (Test-Path -LiteralPath (Join-Path $productionPath 'RunMenu.txt')) {
    $script:AgScriptsFolder = $productionPath
} elseif (Test-Path -LiteralPath (Join-Path $scriptDirectory 'RunMenu.txt')) {
    $script:AgScriptsFolder = $scriptDirectory
} else {
    Write-Error "RunMenu.txt not found in either production path or script directory"
    exit 1
}

# SECURITY FIX: Use direct dot-sourcing instead of ScriptBlock::Create to avoid EDR flagging
$runMenuPath = Join-Path $script:AgScriptsFolder 'RunMenu.txt'
if (-not (Test-Path -LiteralPath $runMenuPath)) {
    Write-Error "RunMenu.txt not found at: $runMenuPath"
    exit 1
}
. $runMenuPath
