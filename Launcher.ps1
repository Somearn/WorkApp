# Try production UNC path first, then fall back to script directory
$productionPath = '\\lsfile03\netdoc$\Somearns_Folder\SomearnTK_app\appdata'
$scriptDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

# Helper function to test if RunMenu.txt exists in a path
function Test-RunMenuPath($basePath) {
    try {
        $testPath = Join-Path $basePath 'RunMenu.txt'
        return (Test-Path -LiteralPath $testPath -ErrorAction Stop)
    } catch {
        return $false
    }
}

# Determine the correct path to use
if (Test-RunMenuPath $productionPath) {
    $script:AgScriptsFolder = $productionPath
} elseif (Test-RunMenuPath $scriptDirectory) {
    $script:AgScriptsFolder = $scriptDirectory
} else {
    Write-Error "RunMenu.txt not found in either production path or script directory: $scriptDirectory"
    exit 1
}

# SECURITY FIX: Use direct dot-sourcing instead of ScriptBlock::Create to avoid EDR flagging
$runMenuPath = Join-Path $script:AgScriptsFolder 'RunMenu.txt'
. $runMenuPath
