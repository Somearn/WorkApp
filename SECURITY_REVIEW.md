# SECURITY REVIEW - WorkApp PowerShell Application
**Review Date:** 2025-12-23  
**Reviewer:** Senior PowerShell 5.1 AppSec & Enterprise Endpoint Defense Engineer  
**Context:** TXT-driven PowerShell WinForms app launched from UNC path in corporate environment with EDR + AppLocker/WDAC

---

## A) EXECUTIVE SUMMARY

### Overall Risk Rating: **HIGH**

### Top 3 Items Most Likely to Trigger EDR:
1. **ScriptBlock::Create with untrusted UNC content** - String-to-execution from network share (RunMenu.txt lines 48, 71; Launcher code lines 2-3; AG_ScriptLauncherControlRoom.txt line 279)
2. **Base64-encoded PowerShell command execution** - AG_DiagnosticsAndRepair.txt lines 199-200 creates encoded commands that will trigger EDR
3. **Dynamic script execution without validation** - Loading .txt files from UNC and executing without signature/hash validation

### Top 3 Items Most Likely to Be Policy Violations:
1. **Executing code from user-writable UNC paths** - No integrity validation before execution
2. **Credential elevation prompts** - AG_DiagnosticsAndRepair.txt line 207 uses runas verb without proper justification
3. **Remote WMI/service enumeration** - Multiple tools query remote systems without proper authentication/authorization checks

---

## B) FINDINGS TABLE

| # | Type | Severity | Confidence | Evidence | Explanation | Practical Impact | Safer Replacement | Effort |
|---|------|----------|------------|----------|-------------|------------------|-------------------|--------|
| 1 | **POLICY VIOLATION** | **Critical** | High | **Launcher code (Run this PowerShell ISE).txt** lines 2-3:<br/>`[scriptblock]::Create((Get-Content -LiteralPath ... -Raw))` | The launcher uses ScriptBlock::Create to execute content from a UNC path. This is string-to-execution from potentially untrusted network storage. | If an attacker compromises the UNC share or performs MITM, they can inject arbitrary code. EDR will flag this as suspicious execution pattern. Corporate policy typically blocks execution from user-writable network shares. | Use dot-sourcing with integrity validation:<br/>```powershell<br/>$path = Join-Path $trusted 'RunMenu.txt'<br/>$hash = Get-FileHash $path -Algorithm SHA256<br/>if ($hash.Hash -eq $expectedHash) {<br/>  . $path<br/>}``` | M |
| 2 | **POLICY VIOLATION** | **Critical** | High | **RunMenu.txt** lines 47-48:<br/>`$themeCode = Get-Content ... -Raw`<br/>`. ([scriptblock]::Create($themeCode))` | Loading theme module uses ScriptBlock::Create to execute text content from UNC share. | Same as #1 - string-to-execution from network. If UNC share is writable by non-admins, code injection is trivial. | Use direct dot-sourcing with path validation:<br/>```powershell<br/>$themePath = Resolve-TrustedPath $base 'AG_Themes.txt'<br/>. $themePath``` | S |
| 3 | **POLICY VIOLATION** | **Critical** | High | **RunMenu.txt** lines 63, 71:<br/>`$menuCode = Get-Content ... -Raw`<br/>`. ([scriptblock]::Create($menuCode))` | Main menu module loaded via ScriptBlock::Create from UNC. | Core application entry point vulnerable to code injection via UNC share compromise. | Use direct dot-sourcing after validation:<br/>```powershell<br/>$menuPath = Resolve-TrustedPath $base 'AG_MenuMain.txt'<br/>. $menuPath``` | S |
| 4 | **HIGH-RISK FLAW** | **Critical** | High | **AG_ScriptLauncherControlRoom.txt** line 279:<br/>`$sb = [scriptblock]::Create($code)` | Reads arbitrary .txt files from disk and creates scriptblocks for execution without any validation. | User could place malicious .txt file in scripts folder. Tool executes it with current user privileges. Perfect for lateral movement or privilege escalation. | Require script signing or hash allowlist:<br/>```powershell<br/>$sig = Get-AuthenticodeSignature $path<br/>if ($sig.Status -ne 'Valid') { throw 'Unsigned' }<br/>. $path``` | M |
| 5 | **HIGH-RISK FLAW** | **Critical** | High | **AG_DiagnosticsAndRepair.txt** lines 199-200:<br/>`$bytes = [System.Text.Encoding]::Unicode.GetBytes($psCommand)`<br/>`$encodedCommand = [Convert]::ToBase64String($bytes)` | Creates base64-encoded PowerShell commands and executes them via powershell.exe -EncodedCommand. | EDR will flag base64-encoded command execution as obfuscation/malware pattern. This is a top IOC (Indicator of Compromise) for most EDR vendors. | Execute PowerShell scripts directly with -File parameter or use remoting with constrained language mode:<br/>```powershell<br/>Start-Process powershell.exe -ArgumentList "-File $tempScript"``` | M |
| 6 | **POLICY VIOLATION** | **High** | High | **AG_DiagnosticsAndRepair.txt** line 207:<br/>`$psi.Verb = "runas"` | Prompts for elevation using runas verb without proper justification or audit logging. | UAC prompts can be social engineering vectors. Policy often requires elevation to be pre-authorized or justified with specific reason codes. | Check privileges upfront, provide clear justification:<br/>```powershell<br/>$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)<br/>if (-not $isAdmin) {<br/>  Write-Warning "This tool requires admin privileges"<br/>  return<br/>}``` | S |
| 7 | **HIGH-RISK FLAW** | **High** | High | **AG_MenuMain.txt** lines 27-34:<br/>`$candidate = Join-Path $baseResolved $leaf`<br/>`$resolved = (Resolve-Path ... ).Path`<br/>Path validation insufficient | Resolve-AgTrustedPath function only checks filename is leaf and path is under base. No validation of file integrity or source trust. | Attacker with write access to UNC share can modify any .txt module. Path traversal may still be possible through symlinks/junctions. | Add integrity validation:<br/>```powershell<br/>$resolved = Resolve-Path -LiteralPath $candidate<br/>$hash = Get-FileHash $resolved -Algorithm SHA256<br/>if (-not $allowedHashes[$leaf].Contains($hash.Hash)) {<br/>  throw "Integrity check failed: $leaf"<br/>}``` | M |
| 8 | **HIGH-RISK FLAW** | **High** | Medium | **AG_AppGroups.txt** line 538:<br/>`Start-Process -FilePath 'excel.exe' -ArgumentList "`"$path`""` | Executes Excel with user-provided CSV path without validation. | If $path is manipulated (CSV injection, path traversal), could execute arbitrary commands via Excel CSV formula injection (DDE/macro attack). | Validate file extension and sanitize:<br/>```powershell<br/>if ($path -notmatch '\.csv$') { throw 'Invalid file type' }<br/>$fullPath = Resolve-Path -LiteralPath $path<br/>Start-Process excel.exe -ArgumentList "`"$fullPath`""``` | S |
| 9 | **HIGH-RISK FLAW** | **High** | Medium | **AG_DiagnosticsAndRepair.txt** lines 126-133:<br/>`$oldest.Kill()` | Process termination without validation of process identity or user consent. | If process list is manipulated or timing attack occurs, could kill wrong process. Corporate policy often prohibits automated process termination. | Validate process before killing:<br/>```powershell<br/>if ($oldest.MainWindowTitle -match 'DIAGNOSTICS') {<br/>  try { $oldest.Kill() } catch {}<br/>}``` | S |
| 10 | **HIGH-RISK FLAW** | **Medium** | High | **AG_DiagnosticsAndRepair.txt** lines 152-156:<br/>`[Microsoft.VisualBasic.Interaction]::InputBox(...)` | User input for hostname/IP without validation before use in commands. | User could input malicious hostnames like `localhost; rm -rf /` or use command injection via backticks, semicolons. | Validate input strictly:<br/>```powershell<br/>if ($target -notmatch '^[a-zA-Z0-9.-]+$') {<br/>  throw 'Invalid hostname format'<br/>}<br/>if ($target.Length -gt 253) {<br/>  throw 'Hostname too long'<br/>}``` | S |
| 11 | **HIGH-RISK FLAW** | **Medium** | High | **AG_PhoneBookDirectory.txt** lines 593-600:<br/>`Start-Process -FilePath $path` | Opens user-provided file path without validation, could execute arbitrary files. | If path is manipulated to point to .exe, .bat, .ps1, etc., will execute it. | Validate file type:<br/>```powershell<br/>if ($path -notmatch '\.(csv\|txt)$') {<br/>  throw 'Invalid file type'<br/>}<br/>Start-Process notepad.exe -ArgumentList $path``` | S |
| 12 | **POLICY VIOLATION** | **Medium** | High | **AG_DiagnosticsAndRepair.txt** lines 422-423:<br/>`Get-Service -ComputerName {TARGET}`<br/>`Get-WmiObject Win32_LogicalDisk -ComputerName {TARGET}` | Remote service/WMI enumeration without authentication or authorization checks. | Corporate policy typically requires explicit authorization for remote system queries. Can be used for reconnaissance. | Add authentication and logging:<br/>```powershell<br/>$cred = Get-Credential -Message "Enter admin credentials for $target"<br/>Get-WmiObject Win32_LogicalDisk -ComputerName $target -Credential $cred``` | M |
| 13 | **LOW-RISK / HYGIENE** | **Medium** | Medium | **AG_MenuMain.txt** line 44:<br/>`if ($fi.Length -gt 2MB) { throw ... }` | File size limit is hygiene but arbitrary (2MB). No explanation why this limit. | Could block legitimate large modules. DoS if attacker creates 1.9MB file with infinite loop. | Document limit and add content validation:<br/>```powershell<br/># Max 2MB prevents UI freeze from huge files<br/>if ($fi.Length -gt 2MB) { throw "File too large" }<br/># Also check for obvious malicious patterns<br/>if ($content -match '(Start-Sleep -Seconds [0-9]{3,}|while.*true)') {<br/>  throw "Suspicious content detected"<br/>}``` | S |
| 14 | **LOW-RISK / HYGIENE** | **Low** | Medium | **All files**:<br/>No logging of security events | Application doesn't log script execution, file loads, or user actions. | Incident response will be difficult. Cannot detect if UNC share was compromised. | Add security event logging:<br/>```powershell<br/>function Write-SecurityLog {<br/>  param([string]$Event, [string]$Details)<br/>  $msg = "{0} - {1}: {2}" -f (Get-Date).ToString('o'), $Event, $Details<br/>  Add-Content -Path $securityLog -Value $msg<br/>}``` | M |
| 15 | **LOW-RISK / HYGIENE** | **Low** | Medium | **RunMenu.txt** lines 25-26:<br/>Hard-coded UNC paths | UNC paths are hard-coded, not configurable. | If share moves or is renamed, application breaks. Cannot use alternate shares for testing. | Use configuration file or registry:<br/>```powershell<br/>$configPath = Join-Path $env:APPDATA 'SomearnTK\config.json'<br/>$config = Get-Content $configPath \| ConvertFrom-Json<br/>$script:AG_AppDataPath = $config.AppDataPath``` | M |
| 16 | **LOW-RISK / HYGIENE** | **Low** | Low | **Multiple files**:<br/>`$ErrorActionPreference = 'Stop'` | Error action is set to Stop, but errors in scriptblocks may not propagate correctly. | Errors might be silently caught and hidden. Debugging becomes harder. | Use try-catch with proper error handling:<br/>```powershell<br/>try {<br/>  # risky operation<br/>} catch {<br/>  Write-SecurityLog "Error" $_.Exception.Message<br/>  throw<br/>}``` | S |
| 17 | **LOW-RISK / HYGIENE** | **Low** | Low | **AG_DiagnosticsAndRepair.txt** lines 174-196:<br/>Inline here-string with user input | PowerShell command is built as here-string with string interpolation of user input. | While $target is provided via InputBox, string interpolation could introduce injection if variable manipulation occurs. | Use parameterized scriptblock:<br/>```powershell<br/>$sb = {<br/>  param($Target)<br/>  Write-Host "Target: $Target"<br/>  # command logic<br/>}<br/>& $sb -Target $target``` | M |

---

## C) "WHAT WILL GET ME FLAGGED TOMORROW" LIST

### Exact constructs likely to trigger EDR/AppLocker:

1. **ScriptBlock::Create() with network content**
   - `[scriptblock]::Create((Get-Content -LiteralPath (Join-Path $script:AgScriptsFolder ...)))` 
   - Location: Launcher code line 2, RunMenu.txt lines 48, 71

2. **Base64-encoded command execution**
   - `powershell.exe -EncodedCommand $encodedCommand`
   - Location: AG_DiagnosticsAndRepair.txt line 211

3. **Dynamic PowerShell spawning**
   - `Start-Process powershell.exe -ArgumentList "-NoExit -EncodedCommand ..."`
   - Location: AG_DiagnosticsAndRepair.txt lines 203-215

4. **UNC path execution**
   - Executing .txt files directly from `\\lsfile03\netdoc$\...`
   - Location: All modules loading from hard-coded UNC path

5. **Process.Kill() calls**
   - `$oldest.Kill()`
   - Location: AG_DiagnosticsAndRepair.txt line 129

6. **Credential prompts**
   - `$psi.Verb = "runas"`
   - Location: AG_DiagnosticsAndRepair.txt line 207

7. **Remote WMI queries without explicit credentials**
   - `Get-WmiObject Win32_* -ComputerName {TARGET}`
   - Location: AG_DiagnosticsAndRepair.txt lines 440, 451-453

---

## D) FIX-FIRST PLAN

### Phase 1 (Same Day) - Eliminate Top EDR Triggers and Critical Issues

**Priority: Eliminate string-to-execution and base64 encoding**

1. **Replace ScriptBlock::Create with direct dot-sourcing**
   - Files: Launcher code, RunMenu.txt, AG_MenuMain.txt
   - Change: Replace all `[scriptblock]::Create($code)` with `. $path`
   - **Effort: 2 hours**

2. **Remove base64 command encoding**
   - File: AG_DiagnosticsAndRepair.txt
   - Change: Write commands to temporary .ps1 file, execute with -File instead of -EncodedCommand
   - **Effort: 1 hour**

3. **Add input validation for hostnames**
   - File: AG_DiagnosticsAndRepair.txt
   - Change: Validate hostname format with regex before use
   - **Effort: 30 minutes**

4. **Validate file paths before execution**
   - Files: AG_AppGroups.txt, AG_PhoneBookDirectory.txt, AG_SiteManager.txt
   - Change: Validate file extension and use Resolve-Path before Start-Process
   - **Effort: 1 hour**

**Phase 1 Total Effort: ~4.5 hours**

---

### Phase 2 (1-3 Days) - Integrity + Share-Permission Hardening

1. **Implement file integrity validation**
   - Add hash-based validation for all .txt modules
   - Maintain allowlist of known-good file hashes
   - **Effort: 4 hours**

2. **Add UNC share permission validation**
   - Check that UNC paths are read-only for current user
   - Warn if share has excessive write permissions
   - **Effort: 2 hours**

3. **Implement security event logging**
   - Log all module loads, script executions, user actions
   - Store logs locally or send to SIEM
   - **Effort: 3 hours**

4. **Add authentication for remote operations**
   - Require explicit credentials for remote WMI/service queries
   - Use constrained delegation where possible
   - **Effort: 4 hours**

5. **Remove or restrict elevation prompts**
   - Check privileges upfront, fail gracefully if insufficient
   - Provide clear error messages about required privileges
   - **Effort: 2 hours**

**Phase 2 Total Effort: ~15 hours**

---

### Phase 3 (Later) - Polish, Logging, Guardrails

1. **Implement configuration management**
   - Move hard-coded paths to config file
   - Support multiple environments (dev/test/prod)
   - **Effort: 3 hours**

2. **Add content security scanning**
   - Scan loaded .txt files for suspicious patterns
   - Block execution if malicious content detected
   - **Effort: 4 hours**

3. **Improve error handling**
   - Consistent error handling across all modules
   - Better error messages for users
   - Proper error propagation
   - **Effort: 3 hours**

4. **Add process validation**
   - Validate process identity before Kill()
   - Add user confirmation for dangerous operations
   - **Effort: 2 hours**

5. **Documentation**
   - Document security model
   - Create incident response procedures
   - User training materials
   - **Effort: 4 hours**

**Phase 3 Total Effort: ~16 hours**

---

## SUMMARY

**Total Issues Found:** 17
- **Policy Violations:** 5
- **High-Risk Flaws:** 9
- **Low-Risk / Hygiene:** 3

**Critical Issues:** 5 (Must fix immediately)
**High Issues:** 7 (Fix within 1-3 days)
**Medium Issues:** 3 (Fix within 1 week)
**Low Issues:** 2 (Fix when time permits)

**Recommendation:** Begin Phase 1 fixes immediately. String-to-execution patterns and base64 encoding are the highest risk for EDR flagging and policy violations.
