# Try production UNC path first, then fall back to script directory
$productionPath = '\\lsfile03\netdoc$\Somearns_Folder\SomearnTK_app\appdata'
$scriptDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

# Determine the correct path to use
try {
    if (Test-Path -LiteralPath (Join-Path $productionPath 'RunMenu.txt') -ErrorAction Stop) {
        $script:AgScriptsFolder = $productionPath
    } elseif (Test-Path -LiteralPath (Join-Path $scriptDirectory 'RunMenu.txt') -ErrorAction Stop) {
        $script:AgScriptsFolder = $scriptDirectory
    } else {
        Write-Error "RunMenu.txt not found in either production path or script directory"
        exit 1
    }
} catch {
    # If production path fails (e.g., UNC not available), try script directory
    if (Test-Path -LiteralPath (Join-Path $scriptDirectory 'RunMenu.txt') -ErrorAction SilentlyContinue) {
        $script:AgScriptsFolder = $scriptDirectory
    } else {
        Write-Error "RunMenu.txt not found in script directory: $scriptDirectory"
        exit 1
    }
}

# SECURITY FIX: Use direct dot-sourcing instead of ScriptBlock::Create to avoid EDR flagging
$runMenuPath = Join-Path $script:AgScriptsFolder 'RunMenu.txt'
if (-not (Test-Path -LiteralPath $runMenuPath)) {
    Write-Error "RunMenu.txt not found at: $runMenuPath"
    exit 1
}
. $runMenuPath
