# WorkApp Data Schema and Sample Data

## Overview

This document defines the complete data schema for WorkApp, including table structures, relationships, sample data, and data governance policies.

## Data Architecture

### Storage Technology
**Primary**: Microsoft Dataverse
- Cloud-based relational database
- Built-in security and compliance
- Native PowerApps integration
- Automatic audit trails
- Scalable and performant

**Alternative**: SharePoint Lists
- For simpler deployments
- Limited relational capabilities
- Easier to set up

## Table Definitions

### 1. Applications Table

**Purpose**: Store information about all supported applications

**Schema**:

| Column Name | Data Type | Max Length | Required | Description |
|------------|-----------|------------|----------|-------------|
| ApplicationId | GUID | - | Yes (PK) | Unique identifier |
| Name | Text | 100 | Yes | Application name |
| Version | Text | 20 | No | Current version |
| Description | Rich Text | 4000 | No | Detailed description |
| Category | Choice | - | Yes | Business, Development, Infrastructure, Security |
| Status | Choice | - | Yes | Active, Deprecated, In Development |
| Dependencies | Multi-line Text | 4000 | No | Required dependencies |
| InstallationNotes | Rich Text | 8000 | No | Installation instructions |
| ConfigurationNotes | Rich Text | 8000 | No | Configuration details |
| TroubleshootingTips | Rich Text | 8000 | No | Common issues and fixes |
| SupportTeamId | Lookup | - | No | Reference to Teams table |
| Documentation URL | URL | 500 | No | Link to external docs |
| VendorName | Text | 100 | No | Software vendor |
| LicenseInfo | Text | 200 | No | License type/details |
| CriticalityLevel | Choice | - | No | High, Medium, Low |
| LastUpdated | DateTime | - | Yes | Auto-populated |
| UpdatedBy | Lookup | - | Yes | Reference to User |
| CreatedOn | DateTime | - | Yes | Auto-populated |
| CreatedBy | Lookup | - | Yes | Reference to User |

**Indexes**:
- Primary Key: ApplicationId
- Index on: Name, Category, Status

**Business Rules**:
- Name must be unique
- Status change from Active to Deprecated requires approval
- LastUpdated auto-updates on any modification

### 2. Teams Table

**Purpose**: Organize support teams and their responsibilities

**Schema**:

| Column Name | Data Type | Max Length | Required | Description |
|------------|-----------|------------|----------|-------------|
| TeamId | GUID | - | Yes (PK) | Unique identifier |
| Name | Text | 100 | Yes | Team name |
| Description | Multi-line Text | 2000 | No | Team description |
| ManagerId | Lookup | - | No | Reference to TeamMembers |
| Department | Choice | - | Yes | Infrastructure, Security, Development, Support |
| ContactEmail | Email | 100 | Yes | Team email address |
| ContactPhone | Phone | 20 | No | Team phone number |
| OnCallPhone | Phone | 20 | No | After-hours contact |
| Responsibilities | Multi-line Text | 4000 | No | Team responsibilities |
| WorkingHours | Text | 100 | No | e.g., "Mon-Fri 8am-5pm EST" |
| EscalationPath | Multi-line Text | 1000 | No | Escalation procedure |
| ActiveMemberCount | Whole Number | - | No | Calculated field |
| CreatedOn | DateTime | - | Yes | Auto-populated |
| CreatedBy | Lookup | - | Yes | Reference to User |

**Indexes**:
- Primary Key: TeamId
- Index on: Name, Department

**Business Rules**:
- Name must be unique
- ContactEmail must be valid format
- At least one contact method required

### 3. TeamMembers Table

**Purpose**: Individual team member information and contact details

**Schema**:

| Column Name | Data Type | Max Length | Required | Description |
|------------|-----------|------------|----------|-------------|
| TeamMemberId | GUID | - | Yes (PK) | Unique identifier |
| Name | Text | 100 | Yes | Full name |
| FirstName | Text | 50 | No | First name |
| LastName | Text | 50 | No | Last name |
| Role | Choice | - | Yes | Engineer, Manager, Specialist, On-Call |
| Email | Email | 100 | Yes | Work email |
| Phone | Phone | 20 | No | Work phone |
| MobilePhone | Phone | 20 | No | Mobile phone |
| Department | Choice | - | Yes | Infrastructure, Security, Development, Support |
| TeamId | Lookup | - | Yes | Reference to Teams |
| Specializations | Multi-line Text | 2000 | No | Areas of expertise |
| Certifications | Text | 500 | No | Professional certifications |
| Availability | Choice | - | Yes | Available, Busy, Out of Office, On Leave |
| TimeZone | Text | 50 | No | e.g., "EST", "PST" |
| StartDate | Date | - | No | Employment start date |
| ProfilePhotoUrl | URL | 500 | No | Photo URL |
| IsActive | Yes/No | - | Yes | Default: Yes |
| PreferredContact | Choice | - | No | Email, Phone, Teams |
| CreatedOn | DateTime | - | Yes | Auto-populated |
| CreatedBy | Lookup | - | Yes | Reference to User |

**Indexes**:
- Primary Key: TeamMemberId
- Index on: Email, Name, TeamId

**Business Rules**:
- Email must be unique
- Email must be valid format
- At least one phone number recommended
- Cannot delete if set as Team Manager

### 4. Notes Table

**Purpose**: Shared documentation and knowledge base articles

**Schema**:

| Column Name | Data Type | Max Length | Required | Description |
|------------|-----------|------------|----------|-------------|
| NoteId | GUID | - | Yes (PK) | Unique identifier |
| Title | Text | 200 | Yes | Note title |
| Content | Rich Text | 32000 | Yes | Note content |
| Category | Text | 50 | No | Category for grouping |
| Tags | Text | 200 | No | Comma-separated tags |
| RelatedApplicationId | Lookup | - | No | Reference to Applications |
| RelatedTeamId | Lookup | - | No | Reference to Teams |
| Priority | Choice | - | No | High, Medium, Low |
| IsPublic | Yes/No | - | Yes | Default: Yes |
| IsPinned | Yes/No | - | No | Pin to top |
| ViewCount | Whole Number | - | No | Number of views |
| AuthorId | Lookup | - | Yes | Reference to User |
| CreatedOn | DateTime | - | Yes | Auto-populated |
| LastModified | DateTime | - | Yes | Auto-populated |
| LastModifiedBy | Lookup | - | Yes | Reference to User |

**Indexes**:
- Primary Key: NoteId
- Index on: Title, Category, Tags
- Full-text index on: Content

**Business Rules**:
- Title must be unique per category
- Content minimum length: 10 characters
- Tags stored as comma-separated values
- ViewCount increments on read

### 5. DiagnosticLogs Table

**Purpose**: Log all network diagnostic tool executions

**Schema**:

| Column Name | Data Type | Max Length | Required | Description |
|------------|-----------|------------|----------|-------------|
| LogId | GUID | - | Yes (PK) | Unique identifier |
| OperatorId | Lookup | - | Yes | Reference to User |
| OperatorIP | Text | 45 | Yes | IPv4 or IPv6 address |
| ToolUsed | Choice | - | Yes | Ping, TraceRoute, NSLookup, ReverseDNS, PortCheck |
| Target | Text | 253 | Yes | Hostname or IP |
| Parameters | Multi-line Text | 2000 | No | JSON with parameters |
| Result | Multi-line Text | 8000 | No | Command output |
| Status | Choice | - | Yes | Success, Failed, Blocked |
| ErrorMessage | Text | 500 | No | Error details if failed |
| ExecutionTimeMs | Whole Number | - | No | Execution time in milliseconds |
| Timestamp | DateTime | - | Yes | When executed |
| SessionId | Text | 50 | No | User session identifier |
| UserAgent | Text | 200 | No | Browser/device info |

**Indexes**:
- Primary Key: LogId
- Index on: OperatorId, Timestamp, ToolUsed, Status

**Business Rules**:
- Records are immutable (no updates allowed)
- Auto-delete records older than 90 days
- Blocked attempts logged with reason
- All fields required except ErrorMessage

### 6. AuditLogs Table

**Purpose**: Comprehensive audit trail of all system operations

**Schema**:

| Column Name | Data Type | Max Length | Required | Description |
|------------|-----------|------------|----------|-------------|
| AuditId | GUID | - | Yes (PK) | Unique identifier |
| Timestamp | DateTime | - | Yes | When action occurred |
| OperatorId | Lookup | - | Yes | Reference to User |
| OperatorIP | Text | 45 | No | IPv4 or IPv6 address |
| Action | Text | 100 | Yes | Action performed |
| Resource | Text | 100 | No | Resource type |
| ResourceId | Text | 100 | No | Resource identifier |
| Result | Choice | - | Yes | Success, Failed, Blocked |
| Details | Multi-line Text | 4000 | No | JSON with details |
| Severity | Choice | - | Yes | Info, Warning, Error, Critical |
| SessionId | Text | 50 | No | User session identifier |
| ChangedFields | Multi-line Text | 2000 | No | Fields modified (JSON) |
| OldValues | Multi-line Text | 4000 | No | Previous values (JSON) |
| NewValues | Multi-line Text | 4000 | No | New values (JSON) |

**Indexes**:
- Primary Key: AuditId
- Index on: Timestamp, OperatorId, Action, Severity

**Business Rules**:
- Records are immutable
- Retain for 7 years
- Administrator access only
- Auto-archived to cold storage after 90 days

### 7. RateLimitTracking Table

**Purpose**: Track API rate limits per user

**Schema**:

| Column Name | Data Type | Max Length | Required | Description |
|------------|-----------|------------|----------|-------------|
| TrackingId | GUID | - | Yes (PK) | Unique identifier |
| UserId | Lookup | - | Yes | Reference to User |
| Tool | Text | 50 | Yes | Tool name |
| WindowStart | DateTime | - | Yes | Rate limit window start |
| RequestCount | Whole Number | - | Yes | Requests in window |
| LastRequest | DateTime | - | Yes | Last request time |

**Indexes**:
- Primary Key: TrackingId
- Index on: UserId, Tool, WindowStart

**Business Rules**:
- Auto-delete records older than 1 hour
- Reset count when window expires

## Table Relationships

### Relationship Diagram

```
Applications ──┐
               ├──> Teams ──> TeamMembers
Notes ─────────┘

DiagnosticLogs ──> User (System)
AuditLogs ──────> User (System)
```

### Detailed Relationships

1. **Applications → Teams** (Many-to-One):
   - Field: SupportTeamId
   - Delete behavior: Restrict (cannot delete team if referenced)

2. **TeamMembers → Teams** (Many-to-One):
   - Field: TeamId
   - Delete behavior: Restrict

3. **Teams → TeamMembers** (One-to-One for Manager):
   - Field: ManagerId
   - Delete behavior: Set null

4. **Notes → Applications** (Many-to-One):
   - Field: RelatedApplicationId
   - Delete behavior: Set null

5. **Notes → Teams** (Many-to-One):
   - Field: RelatedTeamId
   - Delete behavior: Set null

6. **DiagnosticLogs → User** (Many-to-One):
   - Field: OperatorId
   - Delete behavior: Restrict (cannot delete user with logs)

7. **AuditLogs → User** (Many-to-One):
   - Field: OperatorId
   - Delete behavior: Restrict

## Sample Data

### Applications Sample Data

```json
[
  {
    "Name": "Microsoft Exchange Server",
    "Version": "2019 CU12",
    "Description": "Enterprise email and calendaring server providing email, contacts, calendars, and task management capabilities.",
    "Category": "Infrastructure",
    "Status": "Active",
    "Dependencies": "- Active Directory\n- SQL Server 2019\n- Windows Server 2019\n- IIS 10.0\n- .NET Framework 4.8",
    "InstallationNotes": "<h3>Prerequisites</h3><ul><li>Domain-joined server</li><li>Minimum 16GB RAM</li><li>100GB disk space</li></ul><h3>Steps</h3><ol><li>Run Exchange setup</li><li>Configure databases</li><li>Set up mail flow</li></ol>",
    "ConfigurationNotes": "<h3>Post-Installation</h3><ul><li>Configure send/receive connectors</li><li>Set up accepted domains</li><li>Configure SSL certificates</li><li>Enable mailbox auditing</li></ul>",
    "TroubleshootingTips": "<h3>Common Issues</h3><ul><li><strong>Mail flow stopped</strong>: Check transport queues and connectors</li><li><strong>High CPU usage</strong>: Review MAPI/RPC connections</li><li><strong>Database mounting failed</strong>: Check disk space and logs</li></ul>",
    "VendorName": "Microsoft Corporation",
    "LicenseInfo": "Server + User CALs",
    "CriticalityLevel": "High",
    "DocumentationUrl": "https://docs.microsoft.com/exchange"
  },
  {
    "Name": "SQL Server",
    "Version": "2019 Standard",
    "Description": "Relational database management system for business applications.",
    "Category": "Infrastructure",
    "Status": "Active",
    "Dependencies": "- Windows Server 2019\n- .NET Framework 4.7.2+\n- PowerShell 5.1+",
    "InstallationNotes": "<h3>Installation</h3><ol><li>Mount ISO</li><li>Run setup.exe</li><li>Select features: Database Engine, Management Tools</li><li>Configure service accounts</li><li>Set authentication mode</li></ol>",
    "ConfigurationNotes": "<h3>Post-Install Configuration</h3><ul><li>Enable TCP/IP protocol</li><li>Configure firewall (port 1433)</li><li>Set up SQL Agent</li><li>Configure backups</li><li>Optimize tempdb</li></ul>",
    "TroubleshootingTips": "<h3>Troubleshooting</h3><ul><li><strong>Cannot connect</strong>: Verify SQL Browser service, check firewall</li><li><strong>Slow queries</strong>: Check execution plans, update statistics</li><li><strong>Transaction log full</strong>: Backup log, check log retention</li></ul>",
    "VendorName": "Microsoft Corporation",
    "LicenseInfo": "Core-based licensing",
    "CriticalityLevel": "High",
    "DocumentationUrl": "https://docs.microsoft.com/sql"
  },
  {
    "Name": "Active Directory Domain Services",
    "Version": "Windows Server 2019",
    "Description": "Directory service for identity and access management in Windows environments.",
    "Category": "Security",
    "Status": "Active",
    "Dependencies": "- Windows Server 2019\n- DNS Server\n- Static IP address\n- Time synchronization",
    "InstallationNotes": "<h3>DC Promotion</h3><ol><li>Add AD DS role</li><li>Run dcpromo</li><li>Create new forest or join existing</li><li>Set DSRM password</li><li>Configure DNS</li></ol>",
    "ConfigurationNotes": "<h3>Best Practices</h3><ul><li>Multiple domain controllers for redundancy</li><li>Regular backups of system state</li><li>Monitor replication health</li><li>Implement Group Policy structure</li></ul>",
    "TroubleshootingTips": "<h3>Common Issues</h3><ul><li><strong>Replication errors</strong>: Check network, DNS, time sync</li><li><strong>Login failures</strong>: Verify account status, password policy</li><li><strong>GPO not applying</strong>: Run gpupdate, check WMI filters</li></ul>",
    "VendorName": "Microsoft Corporation",
    "LicenseInfo": "Included with Windows Server",
    "CriticalityLevel": "High",
    "DocumentationUrl": "https://docs.microsoft.com/windows-server/identity"
  },
  {
    "Name": "JIRA Service Desk",
    "Version": "8.20.2",
    "Description": "IT service management and ticketing system for support operations.",
    "Category": "Business",
    "Status": "Active",
    "Dependencies": "- Java JDK 11\n- PostgreSQL 12+\n- Tomcat 9.0\n- Minimum 8GB RAM",
    "InstallationNotes": "<h3>Installation Steps</h3><ol><li>Install Java JDK</li><li>Set up PostgreSQL database</li><li>Download JIRA installer</li><li>Run installation wizard</li><li>Configure database connection</li><li>Set up administrator account</li></ol>",
    "ConfigurationNotes": "<h3>Configuration</h3><ul><li>Configure SMTP for email</li><li>Set up LDAP authentication</li><li>Create service desk queues</li><li>Configure SLA policies</li><li>Set up automation rules</li></ul>",
    "TroubleshootingTips": "<h3>Troubleshooting</h3><ul><li><strong>Slow performance</strong>: Check database queries, increase JVM heap</li><li><strong>Email not sending</strong>: Verify SMTP settings, check logs</li><li><strong>Login issues</strong>: Check LDAP sync, verify credentials</li></ul>",
    "VendorName": "Atlassian",
    "LicenseInfo": "Subscription-based",
    "CriticalityLevel": "Medium",
    "DocumentationUrl": "https://confluence.atlassian.com/servicedesk"
  },
  {
    "Name": "VMware vSphere",
    "Version": "7.0 U3",
    "Description": "Virtualization platform for running and managing virtual machines.",
    "Category": "Infrastructure",
    "Status": "Active",
    "Dependencies": "- ESXi hosts\n- vCenter Server\n- Shared storage (SAN/NAS)\n- Management network",
    "InstallationNotes": "<h3>Deployment</h3><ol><li>Install ESXi on physical hosts</li><li>Deploy vCenter appliance</li><li>Add hosts to vCenter</li><li>Configure networking</li><li>Set up shared storage</li><li>Create resource pools</li></ol>",
    "ConfigurationNotes": "<h3>Configuration</h3><ul><li>Enable HA and DRS</li><li>Configure vMotion</li><li>Set up distributed switches</li><li>Implement backup solution</li><li>Configure monitoring</li></ul>",
    "TroubleshootingTips": "<h3>Troubleshooting</h3><ul><li><strong>VM won't start</strong>: Check resource availability, datastore space</li><li><strong>vMotion fails</strong>: Verify networking, shared storage access</li><li><strong>HA failover issues</strong>: Check heartbeat network, host isolation</li></ul>",
    "VendorName": "VMware Inc.",
    "LicenseInfo": "Per-processor licensing",
    "CriticalityLevel": "High",
    "DocumentationUrl": "https://docs.vmware.com/en/VMware-vSphere/"
  },
  {
    "Name": "Legacy CRM System",
    "Version": "3.2",
    "Description": "Legacy customer relationship management system (to be replaced).",
    "Category": "Business",
    "Status": "Deprecated",
    "Dependencies": "- Windows Server 2012 R2\n- SQL Server 2014\n- .NET Framework 4.5",
    "InstallationNotes": "<p><strong>DO NOT INSTALL</strong> - System is deprecated and scheduled for decommissioning Q2 2024.</p>",
    "ConfigurationNotes": "<p>No new configurations should be made. System in read-only mode for data migration.</p>",
    "TroubleshootingTips": "<p>For issues, contact CRM migration team. Do not attempt repairs. Redirect users to new CRM system.</p>",
    "VendorName": "Legacy Vendor (unsupported)",
    "LicenseInfo": "Perpetual (no longer valid)",
    "CriticalityLevel": "Low",
    "DocumentationUrl": ""
  }
]
```

### Teams Sample Data

```json
[
  {
    "Name": "Infrastructure Team",
    "Description": "Manages servers, storage, virtualization, and network infrastructure.",
    "Department": "Infrastructure",
    "ContactEmail": "infra-team@company.com",
    "ContactPhone": "+1-555-0100",
    "OnCallPhone": "+1-555-0199",
    "Responsibilities": "- Server management\n- Storage administration\n- Virtualization platform\n- Network infrastructure\n- Backup systems\n- Disaster recovery",
    "WorkingHours": "Monday-Friday 8:00 AM - 5:00 PM EST",
    "EscalationPath": "1. Team Engineer\n2. Senior Engineer\n3. Team Manager\n4. IT Director"
  },
  {
    "Name": "Security Team",
    "Description": "Responsible for security infrastructure, monitoring, and incident response.",
    "Department": "Security",
    "ContactEmail": "security-team@company.com",
    "ContactPhone": "+1-555-0200",
    "OnCallPhone": "+1-555-0299",
    "Responsibilities": "- Security monitoring\n- Incident response\n- Vulnerability management\n- Access control\n- Security policies\n- Compliance",
    "WorkingHours": "24/7 On-Call Rotation",
    "EscalationPath": "1. Security Analyst\n2. Security Engineer\n3. Security Manager\n4. CISO"
  },
  {
    "Name": "Application Support Team",
    "Description": "Supports business applications and end-user software.",
    "Department": "Support",
    "ContactEmail": "app-support@company.com",
    "ContactPhone": "+1-555-0300",
    "OnCallPhone": "+1-555-0399",
    "Responsibilities": "- Application support\n- User training\n- Ticket management\n- Application deployments\n- License management\n- Vendor coordination",
    "WorkingHours": "Monday-Friday 7:00 AM - 7:00 PM EST",
    "EscalationPath": "1. Support Specialist\n2. Senior Specialist\n3. Team Lead\n4. Support Manager"
  },
  {
    "Name": "Development Team",
    "Description": "Internal software development and custom integrations.",
    "Department": "Development",
    "ContactEmail": "dev-team@company.com",
    "ContactPhone": "+1-555-0400",
    "OnCallPhone": null,
    "Responsibilities": "- Custom application development\n- API integrations\n- Automation scripts\n- Database development\n- Code reviews\n- DevOps processes",
    "WorkingHours": "Monday-Friday 9:00 AM - 5:00 PM EST",
    "EscalationPath": "1. Developer\n2. Senior Developer\n3. Team Lead\n4. Development Manager"
  }
]
```

### TeamMembers Sample Data

```json
[
  {
    "Name": "John Smith",
    "FirstName": "John",
    "LastName": "Smith",
    "Role": "Manager",
    "Email": "john.smith@company.com",
    "Phone": "+1-555-0101",
    "MobilePhone": "+1-555-0151",
    "Department": "Infrastructure",
    "Specializations": "- VMware virtualization\n- Windows Server\n- Storage systems\n- Team leadership",
    "Certifications": "VCP-DCV, MCSE, ITIL v4",
    "Availability": "Available",
    "TimeZone": "EST",
    "PreferredContact": "Email"
  },
  {
    "Name": "Sarah Johnson",
    "FirstName": "Sarah",
    "LastName": "Johnson",
    "Role": "Engineer",
    "Email": "sarah.johnson@company.com",
    "Phone": "+1-555-0102",
    "MobilePhone": "+1-555-0152",
    "Department": "Infrastructure",
    "Specializations": "- Active Directory\n- Exchange Server\n- PowerShell automation\n- Group Policy",
    "Certifications": "MCSA, MCSE: Messaging",
    "Availability": "Available",
    "TimeZone": "EST",
    "PreferredContact": "Phone"
  },
  {
    "Name": "Michael Chen",
    "FirstName": "Michael",
    "LastName": "Chen",
    "Role": "Engineer",
    "Email": "michael.chen@company.com",
    "Phone": "+1-555-0103",
    "MobilePhone": "+1-555-0153",
    "Department": "Infrastructure",
    "Specializations": "- SQL Server DBA\n- Database performance tuning\n- Backup and recovery\n- High availability",
    "Certifications": "MCSA: SQL Server, Oracle DBA",
    "Availability": "Available",
    "TimeZone": "PST",
    "PreferredContact": "Email"
  },
  {
    "Name": "Emily Rodriguez",
    "FirstName": "Emily",
    "LastName": "Rodriguez",
    "Role": "Manager",
    "Email": "emily.rodriguez@company.com",
    "Phone": "+1-555-0201",
    "MobilePhone": "+1-555-0251",
    "Department": "Security",
    "Specializations": "- Security operations\n- Incident response\n- Security architecture\n- Compliance",
    "Certifications": "CISSP, CISM, CEH",
    "Availability": "Available",
    "TimeZone": "EST",
    "PreferredContact": "Email"
  },
  {
    "Name": "David Park",
    "FirstName": "David",
    "LastName": "Park",
    "Role": "Engineer",
    "Email": "david.park@company.com",
    "Phone": "+1-555-0202",
    "MobilePhone": "+1-555-0252",
    "Department": "Security",
    "Specializations": "- Security monitoring\n- SIEM administration\n- Vulnerability scanning\n- Penetration testing",
    "Certifications": "Security+, OSCP, GPEN",
    "Availability": "On-Call",
    "TimeZone": "CST",
    "PreferredContact": "Phone"
  },
  {
    "Name": "Lisa Anderson",
    "FirstName": "Lisa",
    "LastName": "Anderson",
    "Role": "Specialist",
    "Email": "lisa.anderson@company.com",
    "Phone": "+1-555-0301",
    "MobilePhone": "+1-555-0351",
    "Department": "Support",
    "Specializations": "- JIRA administration\n- ServiceNow\n- User training\n- Process improvement",
    "Certifications": "ITIL v4, HDI Support Center Manager",
    "Availability": "Available",
    "TimeZone": "EST",
    "PreferredContact": "Teams"
  },
  {
    "Name": "Robert Taylor",
    "FirstName": "Robert",
    "LastName": "Taylor",
    "Role": "Engineer",
    "Email": "robert.taylor@company.com",
    "Phone": "+1-555-0401",
    "MobilePhone": "+1-555-0451",
    "Department": "Development",
    "Specializations": "- Full-stack development\n- Python, JavaScript\n- REST APIs\n- CI/CD pipelines",
    "Certifications": "AWS Certified Developer, Azure DevOps Engineer",
    "Availability": "Available",
    "TimeZone": "PST",
    "PreferredContact": "Email"
  },
  {
    "Name": "Jennifer Lee",
    "FirstName": "Jennifer",
    "LastName": "Lee",
    "Role": "Engineer",
    "Email": "jennifer.lee@company.com",
    "Phone": "+1-555-0104",
    "MobilePhone": "+1-555-0154",
    "Department": "Infrastructure",
    "Specializations": "- Network administration\n- Cisco routing/switching\n- Firewall management\n- VPN configuration",
    "Certifications": "CCNA, CCNP, Fortinet NSE4",
    "Availability": "Busy",
    "TimeZone": "EST",
    "PreferredContact": "Email"
  },
  {
    "Name": "Thomas Wilson",
    "FirstName": "Thomas",
    "LastName": "Wilson",
    "Role": "Specialist",
    "Email": "thomas.wilson@company.com",
    "Phone": "+1-555-0105",
    "MobilePhone": "+1-555-0155",
    "Department": "Infrastructure",
    "Specializations": "- Backup systems (Veeam)\n- Disaster recovery\n- Storage management\n- Tape libraries",
    "Certifications": "VMCE, Veeam VMTSP",
    "Availability": "Available",
    "TimeZone": "CST",
    "PreferredContact": "Phone"
  },
  {
    "Name": "Amanda Martinez",
    "FirstName": "Amanda",
    "LastName": "Martinez",
    "Role": "On-Call",
    "Email": "amanda.martinez@company.com",
    "Phone": "+1-555-0203",
    "MobilePhone": "+1-555-0253",
    "Department": "Security",
    "Specializations": "- Security incident response\n- Forensics\n- Threat intelligence\n- Security automation",
    "Certifications": "GCIH, GCFA, GCIA",
    "Availability": "On-Call",
    "TimeZone": "EST",
    "PreferredContact": "Phone"
  }
]
```

### Notes Sample Data

```json
[
  {
    "Title": "Exchange Server Database Maintenance",
    "Content": "<h2>Weekly Maintenance Tasks</h2><ol><li>Check database health: <code>Get-MailboxDatabaseCopyStatus</code></li><li>Review transport queues</li><li>Check disk space on all database volumes</li><li>Review event logs for errors</li><li>Verify backup completion</li></ol><h3>Monthly Tasks</h3><ul><li>Run database integrity check</li><li>Review mailbox sizes and implement archiving</li><li>Update accepted domains if needed</li></ul>",
    "Category": "Maintenance",
    "Tags": "exchange, email, maintenance, checklist",
    "Priority": "High",
    "IsPublic": true,
    "IsPinned": true
  },
  {
    "Title": "SQL Server Backup Best Practices",
    "Content": "<h2>Backup Strategy</h2><h3>Full Backups</h3><p>Schedule: Daily at 2:00 AM</p><p>Retention: 30 days</p><h3>Differential Backups</h3><p>Schedule: Every 6 hours</p><p>Retention: 7 days</p><h3>Transaction Log Backups</h3><p>Schedule: Every 15 minutes</p><p>Retention: 48 hours</p><h3>Verification</h3><p>Test restore monthly to verify backup integrity.</p>",
    "Category": "Best Practices",
    "Tags": "sql, database, backup, disaster recovery",
    "Priority": "High",
    "IsPublic": true,
    "IsPinned": false
  },
  {
    "Title": "Security Incident Response Contacts",
    "Content": "<h2>Emergency Contacts</h2><h3>Internal</h3><ul><li>Security Operations Center: +1-555-0299 (24/7)</li><li>Security Manager: Emily Rodriguez</li><li>CISO: [Name] - [Phone]</li></ul><h3>External</h3><ul><li>Cyber Insurance: [Policy Number]</li><li>FBI Cyber Division: [Contact]</li><li>Security Vendor Support: [Contact]</li></ul><h3>Response Steps</h3><ol><li>Contain the incident</li><li>Notify Security Team</li><li>Document everything</li><li>Preserve evidence</li><li>Follow incident response plan</li></ol>",
    "Category": "Emergency",
    "Tags": "security, incident response, emergency, contacts",
    "Priority": "High",
    "IsPublic": false,
    "IsPinned": true
  },
  {
    "Title": "Active Directory Group Policy Naming Convention",
    "Content": "<h2>Naming Standard</h2><p>Format: <code>[Scope]-[Category]-[Purpose]-[Environment]</code></p><h3>Examples</h3><ul><li><code>DOMAIN-SEC-PasswordPolicy-PROD</code></li><li><code>OU-APP-Chrome-DEV</code></li><li><code>SITE-NET-WiFi-PROD</code></li></ul><h3>Scopes</h3><ul><li>DOMAIN: Applies to entire domain</li><li>OU: Applies to specific OU</li><li>SITE: Applies to AD site</li></ul><h3>Categories</h3><ul><li>SEC: Security settings</li><li>APP: Application settings</li><li>NET: Network settings</li><li>USR: User settings</li></ul>",
    "Category": "Standards",
    "Tags": "active directory, group policy, naming convention, standards",
    "Priority": "Medium",
    "IsPublic": true,
    "IsPinned": false
  },
  {
    "Title": "VMware Host Patching Procedure",
    "Content": "<h2>Pre-Patching</h2><ol><li>Review VMware compatibility guide</li><li>Check VUM for available patches</li><li>Schedule maintenance window</li><li>Notify stakeholders</li><li>Verify HA/DRS enabled</li><li>Check host has no VMs pinned</li></ol><h2>Patching</h2><ol><li>Place host in maintenance mode</li><li>VMs auto-migrate via DRS</li><li>Apply patches via VUM</li><li>Reboot if required</li><li>Verify host health</li><li>Exit maintenance mode</li></ol><h2>Post-Patching</h2><ol><li>Verify all VMs running normally</li><li>Check vCenter alarms</li><li>Document patch level</li><li>Update change record</li></ol>",
    "Category": "Procedures",
    "Tags": "vmware, patching, maintenance, procedure",
    "Priority": "Medium",
    "IsPublic": true,
    "IsPinned": false
  }
]
```

## Data Validation Rules

### Global Rules
- All text inputs: Trim whitespace
- All dates: UTC timezone
- All GUIDs: Auto-generated
- All lookups: Validate referential integrity

### Field-Specific Validation

**Email Fields**:
- Pattern: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- Max length: 100 characters
- Convert to lowercase

**Phone Fields**:
- Pattern (US): `^\+?1?[-.]?(\d{3})[-.]?(\d{3})[-.]?(\d{4})$`
- Format: +1-555-0100
- Store normalized format

**URL Fields**:
- Must start with http:// or https://
- Max length: 500 characters
- Validate reachability (optional)

**IP Address Fields**:
- IPv4 pattern: `^(\d{1,3}\.){3}\d{1,3}$`
- IPv6 pattern: Standard notation
- Range validation: 0-255 for each octet

**Choice Fields**:
- Must match predefined options
- Case-insensitive matching
- Default value if blank

## Data Governance

### Data Quality
- **Completeness**: Required fields enforced
- **Accuracy**: Validation rules applied
- **Consistency**: Standardized formats
- **Timeliness**: Auto-update timestamps
- **Validity**: Referential integrity maintained

### Data Security
- **Classification**: Data labeled by sensitivity
- **Access Control**: Role-based permissions
- **Encryption**: At rest and in transit
- **Audit**: All changes logged
- **Retention**: Policy-based deletion

### Data Lifecycle

**Creation**:
- User creates record
- System assigns ID
- Timestamps set
- Audit log entry

**Update**:
- User modifies record
- LastModified updated
- Old values captured
- Audit log entry

**Deletion**:
- Soft delete preferred (IsActive = false)
- Hard delete with approval
- Cascade rules enforced
- Audit log entry

**Archival**:
- Records older than retention moved to archive
- Read-only access maintained
- Compressed storage
- Periodic review for deletion

### Backup Strategy

**Frequency**:
- Full backup: Daily
- Incremental: Hourly
- Transaction log: Every 15 minutes

**Retention**:
- Daily backups: 30 days
- Weekly backups: 12 weeks
- Monthly backups: 12 months
- Yearly backups: 7 years

**Testing**:
- Monthly restore test
- Quarterly disaster recovery drill
- Annual full recovery test

## Data Migration

### Initial Data Load

**Phase 1: Applications** (50-100 records)
- Import from existing documentation
- Validate data quality
- Assign support teams

**Phase 2: Teams & Members** (20-50 records)
- Import from HR system or AD
- Validate contact information
- Set up team relationships

**Phase 3: Notes** (100-200 records)
- Import from existing wikis/docs
- Convert formats (Markdown → Rich Text)
- Categorize and tag

**Phase 4: Historical Logs** (Optional)
- Import previous diagnostic logs
- Import audit history
- Set proper timestamps

### Data Import Templates

CSV templates provided for bulk import:
- Applications.csv
- Teams.csv
- TeamMembers.csv
- Notes.csv

### Validation Checklist

Before go-live:
- [ ] All required applications documented
- [ ] All team members added
- [ ] Contact information verified
- [ ] Support team assignments made
- [ ] Relationships established
- [ ] Sample notes created
- [ ] Data quality validated
- [ ] Permissions configured
- [ ] Backup schedule active

---

**Document Version**: 1.0  
**Last Updated**: [Date]  
**Data Owner**: IT Management
