<#
.SYNOPSIS
    Test script to verify the RunMenu launcher fix

.DESCRIPTION
    Copy this entire script and paste it into PowerShell to test the fix.
    This simulates the exact scenario reported in the issue.

.INSTRUCTIONS
    1. Open PowerShell (not ISE)
    2. Navigate to the WorkApp folder: cd "C:\path\to\WorkApp"
    3. Copy this ENTIRE file content
    4. Paste into PowerShell and press Enter
    5. Check the results below
#>

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  RUNMENU LAUNCHER FIX TEST" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Display current context
Write-Host "CURRENT CONTEXT:" -ForegroundColor Yellow
Write-Host "  Working Directory: $(Get-Location)" -ForegroundColor White
Write-Host "  PSScriptRoot: [$PSScriptRoot]" -ForegroundColor White
Write-Host "  MyInvocation.MyCommand.Path: [$($MyInvocation.MyCommand.Path)]" -ForegroundColor White
Write-Host ""

$testResults = @()

# ============================================================================
# TEST 1: OLD CODE (Should FAIL with null parameter error)
# ============================================================================
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "[TEST 1] OLD CODE - Before the fix" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "Testing: `$scriptDirectory = if (`$PSScriptRoot) { `$PSScriptRoot } else { Split-Path -Parent `$MyInvocation.MyCommand.Path }" -ForegroundColor Gray
Write-Host ""

try {
    $scriptDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    Write-Host "  Result: `$scriptDirectory = '$scriptDirectory'" -ForegroundColor Red
    Write-Host "  Status: ✗ UNEXPECTED - Should have thrown error" -ForegroundColor Red
    $testResults += @{ Test = "Test 1"; Status = "FAIL"; Reason = "Old code did not throw expected error" }
} catch {
    if ($_.Exception.Message -match "Cannot bind argument to parameter 'Path' because it is null") {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Status: ✓ EXPECTED - This is the bug reported in the issue" -ForegroundColor Green
        $testResults += @{ Test = "Test 1"; Status = "PASS"; Reason = "Old code correctly throws the error" }
    } else {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Status: ✗ UNEXPECTED ERROR" -ForegroundColor Red
        $testResults += @{ Test = "Test 1"; Status = "FAIL"; Reason = "Wrong error message" }
    }
}
Write-Host ""

# ============================================================================
# TEST 2: NEW CODE (Should SUCCEED without errors)
# ============================================================================
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "[TEST 2] NEW CODE - After the fix" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "Testing the fixed code with Get-Location fallback..." -ForegroundColor Gray
Write-Host ""

try {
    $scriptDirectory = if ($PSScriptRoot) { 
        $PSScriptRoot 
    } elseif ($MyInvocation.MyCommand.Path) { 
        Split-Path -Parent $MyInvocation.MyCommand.Path 
    } else { 
        # Fallback for pasted code in console: use current directory
        (Get-Location).Path 
    }
    
    Write-Host "  Result: `$scriptDirectory = '$scriptDirectory'" -ForegroundColor Green
    Write-Host "  Status: ✓ SUCCESS - No error thrown" -ForegroundColor Green
    $testResults += @{ Test = "Test 2"; Status = "PASS"; Reason = "New code resolves to current directory" }
} catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Status: ✗ FAILED - New code should not throw error" -ForegroundColor Red
    $testResults += @{ Test = "Test 2"; Status = "FAIL"; Reason = $_.Exception.Message }
}
Write-Host ""

# ============================================================================
# TEST 3: FULL LAUNCHER LOGIC (Test path resolution and RunMenu.txt lookup)
# ============================================================================
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "[TEST 3] FULL LAUNCHER LOGIC - Path resolution" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "Testing complete launcher path resolution logic..." -ForegroundColor Gray
Write-Host ""

try {
    $productionPath = '\\lsfile03\netdoc$\Somearns_Folder\SomearnTK_app\appdata'
    $scriptDirectory = if ($PSScriptRoot) { 
        $PSScriptRoot 
    } elseif ($MyInvocation.MyCommand.Path) { 
        Split-Path -Parent $MyInvocation.MyCommand.Path 
    } else { 
        (Get-Location).Path 
    }
    
    function Test-RunMenuPath($basePath) {
        try {
            $testPath = Join-Path $basePath 'RunMenu.txt'
            return (Test-Path -LiteralPath $testPath -ErrorAction Stop)
        } catch {
            return $false
        }
    }
    
    Write-Host "  Checking production path: $productionPath" -ForegroundColor Gray
    $foundProduction = Test-RunMenuPath $productionPath
    Write-Host "    Result: $foundProduction" -ForegroundColor $(if ($foundProduction) { "Green" } else { "Gray" })
    
    Write-Host "  Checking script directory: $scriptDirectory" -ForegroundColor Gray
    $foundLocal = Test-RunMenuPath $scriptDirectory
    Write-Host "    Result: $foundLocal" -ForegroundColor $(if ($foundLocal) { "Green" } else { "Gray" })
    
    if ($foundProduction) {
        $script:AgScriptsFolder = $productionPath
        Write-Host ""
        Write-Host "  Final Path: $script:AgScriptsFolder (production)" -ForegroundColor Green
        Write-Host "  Status: ✓ RunMenu.txt found at production path" -ForegroundColor Green
        $testResults += @{ Test = "Test 3"; Status = "PASS"; Reason = "Found at production path" }
    } elseif ($foundLocal) {
        $script:AgScriptsFolder = $scriptDirectory
        Write-Host ""
        Write-Host "  Final Path: $script:AgScriptsFolder (local)" -ForegroundColor Green
        Write-Host "  Status: ✓ RunMenu.txt found at local directory" -ForegroundColor Green
        $testResults += @{ Test = "Test 3"; Status = "PASS"; Reason = "Found at local directory" }
    } else {
        Write-Host ""
        Write-Host "  Status: ✗ RunMenu.txt not found in either location" -ForegroundColor Red
        Write-Host "  Note: Make sure you're in the WorkApp directory" -ForegroundColor Yellow
        $testResults += @{ Test = "Test 3"; Status = "FAIL"; Reason = "RunMenu.txt not found" }
    }
} catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Status: ✗ FAILED" -ForegroundColor Red
    $testResults += @{ Test = "Test 3"; Status = "FAIL"; Reason = $_.Exception.Message }
}
Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count

foreach ($result in $testResults) {
    $statusColor = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
    $statusSymbol = if ($result.Status -eq "PASS") { "✓" } else { "✗" }
    Write-Host "  $statusSymbol $($result.Test): $($result.Status)" -ForegroundColor $statusColor
    Write-Host "    Reason: $($result.Reason)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  Tests Passed: $passCount" -ForegroundColor $(if ($passCount -gt 0) { "Green" } else { "Gray" })
Write-Host "  Tests Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""

if ($failCount -eq 0 -or ($failCount -eq 1 -and $testResults[2].Status -eq "FAIL")) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ✓ LAUNCHER FIX IS WORKING!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "The fix successfully prevents the 'Cannot bind argument to" -ForegroundColor White
    Write-Host "parameter Path because it is null' error when pasting code" -ForegroundColor White
    Write-Host "into PowerShell console." -ForegroundColor White
    
    if ($testResults[2].Status -eq "FAIL") {
        Write-Host ""
        Write-Host "Note: Test 3 failed because RunMenu.txt wasn't found." -ForegroundColor Yellow
        Write-Host "      Run this test from the WorkApp directory for Test 3 to pass." -ForegroundColor Yellow
    }
} else {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ✗ TESTS FAILED" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
}

Write-Host ""
