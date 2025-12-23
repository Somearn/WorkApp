# WorkApp Security Documentation

## Security Overview

This document outlines the security measures, protocols, and best practices implemented in WorkApp to ensure safe operation of network diagnostic tools and protection of sensitive information.

## Security Principles

1. **Defense in Depth**: Multiple layers of security controls
2. **Least Privilege**: Users have minimum necessary permissions
3. **Zero Trust**: Verify every request, never assume trust
4. **Audit Everything**: Comprehensive logging of all operations
5. **Secure by Default**: Security built-in, not bolted on

## Authentication & Authorization

### Azure Active Directory Integration

**Implementation**:
- PowerApp uses Azure AD for authentication
- Single Sign-On (SSO) for seamless access
- Multi-factor authentication (MFA) enforced
- Session timeout: 8 hours of inactivity

**User Roles**:

| Role | Permissions | Description |
|------|-------------|-------------|
| **Viewer** | Read-only access to Knowledge Base | Can view but not modify information |
| **Operator** | Full Knowledge Base access, Limited Network Diagnostics | Standard IT operator permissions |
| **Senior Operator** | All Operator permissions, Advanced Network Diagnostics | Can use all diagnostic tools |
| **Administrator** | Full access, User management, Configuration | System administration |

### Role-Based Access Control (RBAC)

**Knowledge Base**:
- Viewer: Read applications, teams, notes
- Operator: Create/Edit/Delete entries, Update team info
- Senior Operator: All Operator permissions + bulk operations
- Administrator: All permissions + user management

**Network Diagnostics**:
- Viewer: No access
- Operator: Ping, NSLookup (internal only)
- Senior Operator: All tools + expanded IP ranges
- Administrator: All tools + configuration management

## Input Validation & Sanitization

### Network Diagnostics Input Validation

#### IP Address Validation
```
Allowed Formats:
- IPv4: 0.0.0.0 to 255.255.255.255
- IPv6: Standard notation
- Hostnames: Alphanumeric with dots and hyphens

Validation Rules:
1. Regex pattern matching for format
2. No special characters (except dots, hyphens in hostnames)
3. Maximum length: 253 characters (DNS standard)
4. IP range whitelist check
5. Blocked list check (external/dangerous IPs)
```

#### Hostname Validation
```
Rules:
1. Length: 1-253 characters
2. Valid characters: a-z, A-Z, 0-9, hyphen, dot
3. Must not start/end with hyphen
4. Domain must be in approved list (for external lookups)
5. No executable extensions (.exe, .bat, .sh, etc.)
```

#### Port Number Validation
```
Rules:
1. Integer between 1-65535
2. Must be in whitelist of approved ports
3. Well-known ports (0-1023) restricted to Senior Operators
4. No port scanning ranges allowed
```

**Approved Ports Whitelist**:
- 22 (SSH)
- 80 (HTTP)
- 443 (HTTPS)
- 3389 (RDP)
- 1433 (SQL Server)
- 3306 (MySQL)
- 5432 (PostgreSQL)
- 8080 (HTTP Alt)
- 8443 (HTTPS Alt)

### Knowledge Base Input Validation

**Text Fields**:
- Maximum lengths enforced
- HTML/Script tag sanitization
- SQL injection prevention
- XSS protection

**Rich Text Fields**:
- Allowed HTML tags whitelist
- Script tags blocked
- External resource loading disabled
- Sanitized before rendering

## Network Security

### IP Range Restrictions

**Internal Network Ranges** (Allowed by default):
```
- 10.0.0.0/8 (Private Class A)
- 172.16.0.0/12 (Private Class B)
- 192.168.0.0/16 (Private Class C)
- Organization-specific ranges (configured)
```

**Blocked Ranges**:
```
- 0.0.0.0/8 (Current network)
- 127.0.0.0/8 (Loopback)
- 169.254.0.0/16 (Link-local)
- 224.0.0.0/4 (Multicast)
- 240.0.0.0/4 (Reserved)
- External internet ranges (unless explicitly allowed)
```

### Rate Limiting

**Per User Limits**:
- Ping: 5 requests per minute
- NSLookup: 10 requests per minute
- Port Check: 3 requests per minute
- Trace Route: 2 requests per 5 minutes

**Global Limits**:
- Maximum concurrent diagnostics: 50
- Maximum queue size: 100
- Request timeout: 30 seconds

**Enforcement**:
- Implemented in Power Automate Flow
- Counter stored in Dataverse
- Resets every minute
- Exceeded limits result in error message

### Command Execution Security

**No Direct Shell Access**:
- Network commands NEVER executed directly from PowerApp
- All operations go through Power Automate Flow
- Flow uses Azure Logic Apps connectors
- Sandboxed execution environment

**Command Whitelisting**:
```
Allowed Operations:
- Test-NetConnection (PowerShell)
- Resolve-DnsName (PowerShell)
- Test-Port (PowerShell)
- Get-NetIPConfiguration (Read-only)

Blocked Operations:
- Any write operations (Set-*, New-*, Remove-*)
- File system access
- Process execution
- Service manipulation
- Registry access
```

**Execution Timeout**:
- Maximum execution time: 30 seconds
- Automatic termination on timeout
- Error returned to user
- Logged for investigation

## Data Security

### Data at Rest

**Storage**: Microsoft Dataverse
- Encryption: AES-256 by default
- Transparent Data Encryption (TDE)
- Key management: Azure Key Vault
- Backup encryption enabled

**Sensitive Data**:
- Phone numbers: Masked for Viewer role
- Email addresses: Visible only to authenticated users
- No passwords or credentials stored
- Audit logs: Encrypted and access-restricted

### Data in Transit

- All communications: HTTPS/TLS 1.2+
- PowerApp to Flow: Encrypted API calls
- Flow to Dataverse: Encrypted connection
- Certificate validation enforced
- No fallback to unencrypted protocols

### Data Classification

| Level | Examples | Protection |
|-------|----------|------------|
| **Public** | Application names, General notes | Standard encryption |
| **Internal** | Team contacts, Configurations | Encrypted, authenticated access |
| **Confidential** | Diagnostic logs, Audit trails | Encrypted, role-restricted |
| **Restricted** | Security configurations | Encrypted, admin-only |

## Audit Logging

### Logged Events

**User Actions**:
- Login/Logout events
- Knowledge base CRUD operations
- Network diagnostic executions
- Role changes
- Configuration modifications

**System Events**:
- Security policy violations
- Rate limit exceeded
- Blocked command attempts
- Authentication failures
- Error conditions

**Log Schema**:
```
AuditLog {
  id: GUID
  timestamp: DateTime (UTC)
  operator: Text (User Principal Name)
  operatorIP: Text
  action: Text
  resource: Text
  resourceId: Text
  result: Choice (Success, Failed, Blocked)
  details: Text (JSON)
  severity: Choice (Info, Warning, Error, Critical)
  sessionId: Text
}
```

### Log Retention

- Active logs: 90 days in Dataverse
- Archived logs: 7 years in Azure Storage
- Audit logs: Immutable, cannot be deleted by users
- Access: Administrator role only
- Export: Available for compliance audits

### Security Monitoring

**Real-time Alerts**:
- Multiple failed authentication attempts
- Blocked command execution attempts
- Rate limit violations (excessive)
- Suspicious patterns (e.g., scanning behavior)
- Administrative actions

**Alert Destinations**:
- Security team email
- Microsoft Teams channel
- Security Information and Event Management (SIEM) system

## Incident Response

### Security Incident Categories

1. **Authentication Breach**: Unauthorized access attempts
2. **Data Breach**: Unauthorized data access/exfiltration
3. **Network Abuse**: Misuse of diagnostic tools
4. **Privilege Escalation**: Unauthorized role changes
5. **System Compromise**: Malicious code or backdoors

### Response Procedures

**Immediate Actions**:
1. Isolate affected user accounts
2. Revoke active sessions
3. Review audit logs
4. Assess impact
5. Notify security team

**Investigation**:
1. Collect evidence from logs
2. Identify scope of incident
3. Determine root cause
4. Document timeline
5. Preserve evidence

**Remediation**:
1. Close security gaps
2. Reset compromised credentials
3. Restore from clean backup if needed
4. Update security policies
5. Implement additional controls

**Post-Incident**:
1. Conduct lessons learned review
2. Update incident response plan
3. User awareness training
4. Security control improvements
5. Documentation updates

## Compliance

### Regulatory Requirements

**GDPR** (if applicable):
- Data minimization
- Right to access
- Right to deletion
- Data portability
- Consent management

**SOC 2** (if applicable):
- Security controls documentation
- Audit trails
- Access controls
- Change management
- Incident response

### Security Assessment Schedule

- **Weekly**: Automated vulnerability scans
- **Monthly**: Security log review
- **Quarterly**: Penetration testing
- **Annually**: Full security audit
- **Ad-hoc**: After major changes

## Security Best Practices for Users

### For Operators

1. **Use Strong Passwords**: Minimum 12 characters, complexity requirements
2. **Enable MFA**: Multi-factor authentication required
3. **Lock Workstation**: When leaving desk
4. **Report Suspicious Activity**: Immediately to security team
5. **Follow Least Privilege**: Don't request unnecessary permissions
6. **Verify Results**: Ensure diagnostic results make sense
7. **No Sharing Credentials**: Never share login information
8. **Log Out**: At end of shift

### For Administrators

1. **Review Audit Logs**: Daily review of critical events
2. **Manage User Roles**: Regular access reviews
3. **Update Security Policies**: Keep configurations current
4. **Monitor Alerts**: Respond to security notifications
5. **Backup Verification**: Regular backup testing
6. **Security Training**: Keep team informed of threats
7. **Patch Management**: Keep systems updated
8. **Incident Drills**: Practice response procedures

## Security Configuration Checklist

### Initial Setup
- [ ] Enable Azure AD authentication
- [ ] Configure MFA for all users
- [ ] Set up RBAC roles
- [ ] Configure IP range whitelist
- [ ] Enable audit logging
- [ ] Set up security alerts
- [ ] Configure rate limiting
- [ ] Enable data encryption
- [ ] Set up backup schedule
- [ ] Document security policies

### Regular Maintenance
- [ ] Review user access quarterly
- [ ] Update IP whitelist as needed
- [ ] Review audit logs monthly
- [ ] Test incident response procedures
- [ ] Update security documentation
- [ ] Verify backup integrity
- [ ] Check security alerts
- [ ] Review and update approved ports list

## Vulnerability Management

### Reporting Security Issues

**Internal**: security@company.com
**External**: Responsible disclosure program

**Do Not**:
- Exploit vulnerabilities
- Access unauthorized data
- Disrupt service
- Disclose publicly before fix

**Expected Response**:
- Acknowledgment: 24 hours
- Initial assessment: 72 hours
- Fix timeline: Based on severity
- Disclosure: After fix deployed

## Security Updates

This security documentation should be reviewed and updated:
- After any security incident
- Quarterly as part of security review
- When security requirements change
- After major system updates
- When new threats are identified

**Last Updated**: [To be filled during implementation]  
**Next Review**: [To be scheduled]  
**Owner**: Security Team / IT Management
