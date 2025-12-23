# WorkApp Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing the WorkApp PowerApp with all required features, security measures, and integrations.

## Prerequisites

### Required Access & Licenses

- **Microsoft 365 Subscription** with:
  - Power Apps license (per app or per user)
  - Power Automate license
  - Microsoft Dataverse access
  - Azure Active Directory Premium (for MFA)

### Required Permissions

- Power Apps environment creation
- Dataverse table creation
- Power Automate flow creation
- Azure AD user/group management
- SharePoint site creation (if using as alternative storage)

### Development Tools

- Power Apps Studio (web or desktop)
- Power Automate portal access
- Browser: Edge, Chrome, or Firefox (latest version)
- Optional: Power Apps CLI for advanced scenarios

## Phase 1: Environment Setup

### Step 1.1: Create Power Apps Environment

1. Go to **Power Platform Admin Center** (admin.powerplatform.microsoft.com)
2. Click **Environments** > **+ New**
3. Configure:
   - **Name**: WorkApp Production
   - **Type**: Production (or Sandbox for testing)
   - **Region**: Select appropriate region
   - **Create Database**: Yes
   - **Currency**: Your currency
   - **Language**: English
4. Click **Save**
5. Wait for environment provisioning (5-10 minutes)

### Step 1.2: Configure Security Groups

1. Go to **Azure Portal** (portal.azure.com)
2. Navigate to **Azure Active Directory** > **Groups**
3. Create security groups:
   - **WorkApp-Viewers**
   - **WorkApp-Operators**
   - **WorkApp-SeniorOperators**
   - **WorkApp-Administrators**
4. Add appropriate users to each group
5. Note group Object IDs for later use

### Step 1.3: Enable Audit Logging

1. In **Power Platform Admin Center**
2. Select your environment
3. Go to **Audit and logs** > **Audit settings**
4. Enable:
   - User access to app
   - User access to resource
   - Data operations
5. Set retention period: 90 days minimum

## Phase 2: Data Model Setup

### Step 2.1: Create Dataverse Tables

#### Applications Table

```
Table Name: Applications
Primary Column: Name (Text)

Columns:
- name (Text, 100 chars, Required)
- version (Text, 20 chars)
- description (Multiple lines of text)
- category (Choice: Business, Development, Infrastructure, Security)
- status (Choice: Active, Deprecated, In Development)
- dependencies (Multiple lines of text)
- installationNotes (Multiple lines of text)
- configurationNotes (Multiple lines of text)
- troubleshooting (Multiple lines of text)
- supportTeam (Lookup to Teams)
- lastUpdated (Date and Time, auto-set)
- updatedBy (Text, 100 chars, auto-set to current user)

Relationships:
- Self-referential: RelatedApplications (Many-to-Many)
```

**Creation Steps**:
1. Go to **make.powerapps.com**
2. Select your environment
3. Navigate to **Tables** > **+ New table** > **Create new table**
4. Set **Display name**: Applications
5. Set **Primary column**: Name
6. Click **Save**
7. Add each column listed above:
   - Click **+ New** > **Column**
   - Set properties as specified
   - Click **Save**
8. Create relationships as needed

#### Teams Table

```
Table Name: Teams
Primary Column: Name (Text)

Columns:
- name (Text, 100 chars, Required)
- description (Multiple lines of text)
- manager (Lookup to TeamMembers)
- contactEmail (Text, 100 chars, Email format)
- contactPhone (Text, 20 chars, Phone format)
- department (Choice: Infrastructure, Security, Development, Support)

Relationships:
- One-to-Many with Applications (supportTeam)
- One-to-Many with TeamMembers (team)
```

#### TeamMembers Table

```
Table Name: TeamMembers
Primary Column: Name (Text)

Columns:
- name (Text, 100 chars, Required)
- role (Choice: Engineer, Manager, Specialist, On-Call)
- email (Text, 100 chars, Email format, Required)
- phone (Text, 20 chars, Phone format)
- department (Choice: Infrastructure, Security, Development, Support)
- specializations (Multiple lines of text)
- availability (Choice: Available, Busy, Out of Office)
- team (Lookup to Teams)

Relationships:
- Many-to-One with Teams
```

#### DiagnosticLogs Table

```
Table Name: DiagnosticLogs
Primary Column: Timestamp (auto-generated)

Columns:
- operator (Lookup to Users/System User)
- operatorIP (Text, 45 chars - supports IPv6)
- toolUsed (Choice: Ping, TraceRoute, NSLookup, ReverseDNS, PortCheck)
- target (Text, 253 chars, Required)
- parameters (Multiple lines of text)
- result (Multiple lines of text)
- status (Choice: Success, Failed, Blocked)
- timestamp (Date and Time, auto-set, Required)
- executionTime (Whole Number, milliseconds)
```

#### AuditLogs Table

```
Table Name: AuditLogs
Primary Column: Timestamp (auto-generated)

Columns:
- timestamp (Date and Time, auto-set, Required)
- operator (Lookup to Users/System User)
- operatorIP (Text, 45 chars)
- action (Text, 100 chars, Required)
- resource (Text, 100 chars)
- resourceId (Text, 100 chars)
- result (Choice: Success, Failed, Blocked)
- details (Multiple lines of text)
- severity (Choice: Info, Warning, Error, Critical)
- sessionId (Text, 50 chars)
```

#### Notes Table

```
Table Name: Notes
Primary Column: Title (Text)

Columns:
- title (Text, 200 chars, Required)
- content (Multiple lines of text, Required)
- category (Text, 50 chars)
- relatedApplication (Lookup to Applications)
- author (Lookup to Users/System User)
- createdDate (Date and Time, auto-set)
- lastModified (Date and Time, auto-set)
- tags (Text, 200 chars - comma separated)
```

### Step 2.2: Configure Table Permissions

1. For each table, set permissions:
   - **WorkApp-Viewers**: Read
   - **WorkApp-Operators**: Create, Read, Update
   - **WorkApp-SeniorOperators**: Create, Read, Update, Delete
   - **WorkApp-Administrators**: Full control

2. For DiagnosticLogs and AuditLogs:
   - **WorkApp-Administrators**: Read only
   - System account: Create, Read

### Step 2.3: Create Sample Data

Create sample records for testing:

**Applications** (3-5 sample applications):
```
Example:
- Name: Microsoft Exchange Server
- Version: 2019
- Category: Infrastructure
- Status: Active
- Description: Enterprise email server
```

**Teams** (2-3 sample teams):
```
Example:
- Name: Infrastructure Team
- Department: Infrastructure
- Contact Email: infra-team@company.com
```

**TeamMembers** (5-10 sample members):
```
Example:
- Name: John Doe
- Role: Engineer
- Email: john.doe@company.com
- Department: Infrastructure
```

## Phase 3: Power Automate Flow Development

### Flow 1: Knowledge Base CRUD Operations

**Flow Name**: WorkApp-KnowledgeBase-Operations

**Trigger**: PowerApps (V2)

**Input Parameters**:
- Operation (Text): "Create", "Read", "Update", "Delete"
- Entity (Text): "Application", "Team", "TeamMember", "Note"
- EntityId (Text): GUID of entity (for Read, Update, Delete)
- Data (Object): JSON object with entity data

**Actions**:

1. **Initialize Variables**:
   - varOperation (String): Trigger input
   - varEntity (String): Trigger input
   - varResult (Object): Empty object

2. **Compose - Current User**:
   - Expression: `triggerBody()['PowerApps_User']`

3. **Compose - Current Timestamp**:
   - Expression: `utcNow()`

4. **Switch - Operation Type**:
   
   **Case: Create**:
   - Switch - Entity Type
   - For each entity: Add Dataverse row
   - Set varResult with success/error

   **Case: Read**:
   - Switch - Entity Type
   - For each entity: Get Dataverse row
   - Set varResult with data

   **Case: Update**:
   - Switch - Entity Type
   - For each entity: Update Dataverse row
   - Set varResult with success/error

   **Case: Delete**:
   - Switch - Entity Type
   - For each entity: Delete Dataverse row
   - Set varResult with success/error

5. **Audit Logging**:
   - Add row to AuditLogs table
   - Fields: operator, action, resource, result, timestamp

6. **Respond to PowerApp**:
   - Return varResult object

**Error Handling**:
- Configure run after settings for error paths
- Catch errors and return friendly messages
- Log errors to AuditLogs

### Flow 2: Network Diagnostics Execution

**Flow Name**: WorkApp-NetworkDiagnostics-Runner

**Trigger**: PowerApps (V2)

**Input Parameters**:
- Tool (Text): "Ping", "NSLookup", "PortCheck", "TraceRoute"
- Target (Text): Hostname or IP
- Parameters (Object): Additional parameters (e.g., port number)

**Actions**:

1. **Initialize Variables**:
   - varTool (String)
   - varTarget (String)
   - varResult (String)
   - varStatus (String)
   - varStartTime (String)

2. **Get Current User**:
   - Expression: `triggerBody()['PowerApps_User']`

3. **Validate Input - IP Address**:
   ```
   Condition: Check if target matches IP regex pattern
   Expression: 
   or(
     startsWith(variables('varTarget'), '10.'),
     startsWith(variables('varTarget'), '172.16.'),
     startsWith(variables('varTarget'), '192.168.')
   )
   ```

4. **Check Rate Limit**:
   - List rows from DiagnosticLogs
   - Filter: operator = current user AND timestamp > (now - 1 minute)
   - Count rows
   - If count > limit: Return error

5. **Switch - Tool Selection**:

   **Case: Ping**:
   - **HTTP Request** to Azure Function or Logic App:
     - Method: POST
     - URI: [Your secure endpoint]
     - Body: { "action": "ping", "target": "@{variables('varTarget')}" }
   - Parse JSON response
   - Set varResult and varStatus

   **Case: NSLookup**:
   - **HTTP Request** to secure endpoint
   - Body: { "action": "nslookup", "target": "@{variables('varTarget')}" }
   - Parse response

   **Case: PortCheck**:
   - **HTTP Request** to secure endpoint
   - Body: { "action": "portcheck", "target": "@{variables('varTarget')}", "port": "@{triggerBody()['Parameters']['port']}" }
   - Parse response

   **Case: TraceRoute**:
   - **HTTP Request** to secure endpoint
   - Body: { "action": "traceroute", "target": "@{variables('varTarget')}" }
   - Parse response

6. **Calculate Execution Time**:
   - Expression: `sub(ticks(utcNow()), ticks(variables('varStartTime')))`

7. **Log to DiagnosticLogs**:
   - Add row to DiagnosticLogs table
   - Fields: operator, toolUsed, target, result, status, timestamp, executionTime

8. **Respond to PowerApp**:
   - Return result object with status and output

**Security Controls**:
- Input validation at each step
- Rate limiting enforcement
- IP whitelist checking
- Comprehensive logging
- Timeout: 30 seconds

**Note**: The actual network command execution should be handled by a secure Azure Function or API that:
- Runs in isolated environment
- Uses PowerShell Core with restricted execution policy
- Has timeout and resource limits
- Logs all operations
- Returns sanitized output

### Flow 3: Notification System

**Flow Name**: WorkApp-Notifications

**Trigger**: When an item is created or modified (Dataverse)

**Table**: Applications (or other monitored tables)

**Actions**:

1. **Condition - Check if Important Update**:
   - If status changed to "Deprecated"
   - Or if critical field modified

2. **Get Team Members**:
   - List rows from TeamMembers
   - Filter by relevant team

3. **Apply to Each Team Member**:
   - **Post message in Teams** (or Send email):
     - Recipient: Team member email
     - Subject: Application Update Notification
     - Body: Details of change

4. **Log Notification**:
   - Add row to AuditLogs

## Phase 4: PowerApp Development

### Step 4.1: Create New Canvas App

1. Go to **make.powerapps.com**
2. Click **+ Create** > **Canvas app from blank**
3. Name: **WorkApp**
4. Format: **Tablet** (1366 x 768)
5. Click **Create**

### Step 4.2: Configure App Settings

1. Click **Settings** (gear icon)
2. **Display**:
   - Orientation: Landscape
   - Scale to fit: On
   - Lock aspect ratio: On
   - Lock orientation: On

3. **Upcoming features**:
   - Enable relevant features for better performance

4. **Advanced settings**:
   - Set app description
   - Configure data row limits (2000 for galleries)

### Step 4.3: Implement Theme

Create theme variables in App.OnStart:

```powerFx
// Star Trek LCARS Theme Colors
Set(colorPrimaryBg, RGBA(13, 13, 13, 1));        // #0D0D0D
Set(colorSecondaryBg, RGBA(26, 26, 26, 1));      // #1A1A1A
Set(colorAccentBg, RGBA(42, 42, 42, 1));         // #2A2A2A
Set(colorAccentPrimary, RGBA(51, 153, 255, 1));  // #3399FF LCARS Blue
Set(colorAccentSecondary, RGBA(255, 153, 0, 1)); // #FF9900 LCARS Orange
Set(colorSuccess, RGBA(0, 204, 153, 1));         // #00CC99 LCARS Teal
Set(colorWarning, RGBA(255, 204, 0, 1));         // #FFCC00 LCARS Yellow
Set(colorDanger, RGBA(255, 51, 102, 1));         // #FF3366 LCARS Red
Set(colorTextPrimary, RGBA(224, 224, 224, 1));   // #E0E0E0
Set(colorTextSecondary, RGBA(176, 176, 176, 1)); // #B0B0B0
Set(colorBorder, RGBA(51, 153, 255, 0.4));       // #3399FF with 40% opacity

// Get current user
Set(varCurrentUser, User());

// Initialize navigation
Set(varCurrentPage, "Dashboard");
```

### Step 4.4: Create Navigation Structure

**Left Navigation Panel**:

1. **Container (cntNavigation)**:
   - X: 0, Y: 0
   - Width: 200
   - Height: Parent.Height
   - Fill: colorSecondaryBg

2. **App Logo/Title**:
   - Label at top
   - Text: "WORKAPP"
   - Font: Bold, Size: 24
   - Color: colorAccentPrimary
   - Align: Center

3. **Navigation Buttons** (Vertical stack):
   - Button: Dashboard
   - Button: Knowledge Base
   - Button: Network Diagnostics
   - Button: Settings

   **Button Properties**:
   - Width: cntNavigation.Width - 20
   - Height: 60
   - Fill: If(varCurrentPage = "Dashboard", colorAccentBg, Transparent)
   - BorderColor: colorBorder
   - Color: colorTextPrimary
   - OnSelect: `Set(varCurrentPage, "Dashboard")`

4. **User Info at Bottom**:
   - Small label showing current user
   - Logout button (if applicable)

### Step 4.5: Create Dashboard Screen

**Container (cntDashboard)**:
- Visible: varCurrentPage = "Dashboard"
- X: 220, Y: 20
- Width: Parent.Width - 240
- Height: Parent.Height - 40

**Components**:

1. **Welcome Header**:
   ```powerFx
   Text: "Welcome, " & varCurrentUser.FullName
   Font: Bold, Size: 28
   Color: colorTextPrimary
   ```

2. **Quick Stats Cards** (Horizontal container):
   - Card 1: Total Applications
   - Card 2: Active Diagnostics
   - Card 3: Recent Updates
   - Card 4: System Status

   **Card Template**:
   - Container with colorAccentBg
   - Large number (main stat)
   - Label below (stat description)
   - Icon at top

3. **Recent Activity Gallery**:
   ```powerFx
   Items: Sort(
       Filter(Applications, lastUpdated > DateAdd(Today(), -7, Days)),
       lastUpdated,
       Descending
   )
   ```

4. **Quick Actions**:
   - Button: "Add New Application"
   - Button: "Run Network Test"
   - Button: "View Team Directory"

### Step 4.6: Create Knowledge Base Screen

**Container (cntKnowledgeBase)**:
- Visible: varCurrentPage = "Knowledge Base"

**Tab Control** for sub-sections:

**Tab 1: Applications**:

1. **Search Bar**:
   ```powerFx
   Text Input: txtSearchApps
   HintText: "Search applications..."
   ```

2. **Filter Dropdowns**:
   - Category filter
   - Status filter

3. **Applications Gallery** (galApplications):
   ```powerFx
   Items: SortByColumns(
       Filter(
           Applications,
           (IsBlank(txtSearchApps.Text) || 
            name in txtSearchApps.Text ||
            description in txtSearchApps.Text) &&
           (IsBlank(ddCategory.Selected.Value) || 
            category = ddCategory.Selected.Value)
       ),
       "name",
       Ascending
   )
   
   Template Layout:
   - Application name (large, bold)
   - Version badge
   - Status indicator (color-coded)
   - Description (truncated)
   - View Details button
   ```

4. **Detail Panel** (slides in from right):
   - Visible when item selected
   - Shows full application details
   - Edit button (if user has permission)
   - Delete button (if user has permission)

5. **Add/Edit Form**:
   - Connected to Applications table
   - All fields from schema
   - Validation rules
   - Save/Cancel buttons

**Tab 2: Teams**:

Similar structure for Teams table

**Tab 3: Team Members**:

1. **Team Member Gallery** with search/filter
2. **Contact cards** with:
   - Photo (if available)
   - Name, role, department
   - Email (click to send)
   - Phone (click to call)
   - Availability status

### Step 4.7: Create Network Diagnostics Screen

**Container (cntNetworkDiagnostics)**:
- Visible: varCurrentPage = "Network Diagnostics"

**Security Check**:
```powerFx
OnVisible: 
If(
    !(varCurrentUser.Email in WorkAppOperators || 
      varCurrentUser.Email in WorkAppSeniorOperators ||
      varCurrentUser.Email in WorkAppAdministrators),
    Navigate(Dashboard, ScreenTransition.None);
    Notify("Access Denied: You don't have permission to use Network Diagnostics", NotificationType.Error)
)
```

**Tool Selector (Radio Buttons or Buttons)**:
- Ping
- NSLookup
- Port Check
- Trace Route

**Input Section** (changes based on tool):

For Ping:
```powerFx
Label: "Target Host or IP"
TextInput: txtTarget
  HintText: "Enter hostname or IP address (e.g., 192.168.1.1)"
  
Label: "Packet Count"
Slider: sliderPacketCount
  Min: 1, Max: 10, Default: 4
```

**Run Diagnostic Button**:
```powerFx
OnSelect:
  Set(varDiagnosticRunning, true);
  Set(varDiagnosticResult, 
    'WorkApp-NetworkDiagnostics-Runner'.Run(
      varSelectedTool,
      txtTarget.Text,
      {
        packetCount: sliderPacketCount.Value,
        port: txtPort.Text
      }
    )
  );
  Set(varDiagnosticRunning, false);

DisplayMode: If(varDiagnosticRunning, DisplayMode.Disabled, DisplayMode.Edit)
Text: If(varDiagnosticRunning, "Running...", "Run Diagnostic")
```

**Results Display**:
```powerFx
HTML Text Control: htmlResults
HtmlText: 
  "<div style='background-color: " & colorPrimaryBg & "; 
               color: " & colorTextPrimary & "; 
               font-family: 'Courier New', monospace; 
               padding: 10px; 
               border: 1px solid " & colorAccentPrimary & ";'>" &
  "<pre>" & varDiagnosticResult.output & "</pre>" &
  "</div>"
  
Visible: !IsBlank(varDiagnosticResult)
```

**History Panel** (collapsible):
```powerFx
Gallery: galDiagnosticHistory
Items: Sort(
    Filter(DiagnosticLogs, operator = varCurrentUser.Email),
    timestamp,
    Descending
)
ItemsVisible: 10

Template:
- Timestamp
- Tool used
- Target
- Status badge (color-coded)
- View button (shows full result in modal)
```

### Step 4.8: Connect Flows to PowerApp

1. In Power Apps Studio, click **Power Automate** in left panel
2. Click **Add flow**
3. Select **WorkApp-KnowledgeBase-Operations**
4. Select **WorkApp-NetworkDiagnostics-Runner**
5. Flows now available in formulas

### Step 4.9: Add Error Handling

Global error handler in App.OnStart:
```powerFx
Set(varErrorMessage, "");
Set(varShowError, false);

// Function to show errors
Set(fxShowError, {
    Show: (message: String) =>
        Set(varErrorMessage, message);
        Set(varShowError, true);
        Timer.Start()
})
```

Error display component:
```powerFx
Container: cntErrorNotification
Visible: varShowError
Position: Top-center overlay
Background: colorDanger
Text: varErrorMessage
Auto-dismiss: Timer (5 seconds)
```

### Step 4.10: Implement Loading States

```powerFx
// In App.OnStart
Set(varIsLoading, false);

// Before API calls
Set(varIsLoading, true);

// After API calls
Set(varIsLoading, false);

// Loading overlay
Container: cntLoading
Visible: varIsLoading
Fill: RGBA(0, 0, 0, 0.5)
Spinner in center
```

### Step 4.11: Save and Publish

1. Click **File** > **Save**
2. Add app icon (create Star Trek themed icon)
3. Add description
4. Click **Publish**
5. Click **Publish this version**

## Phase 5: Testing

### Step 5.1: Unit Testing

Test each component:
- [ ] Navigation works correctly
- [ ] Theme colors display properly
- [ ] Forms validate inputs
- [ ] API calls succeed
- [ ] Error handling works
- [ ] Loading states display

### Step 5.2: Integration Testing

- [ ] Knowledge base CRUD operations
- [ ] Network diagnostics execution
- [ ] Audit logging captures events
- [ ] Notifications trigger correctly
- [ ] Rate limiting enforces limits
- [ ] Security blocks unauthorized access

### Step 5.3: Security Testing

- [ ] Input validation blocks malicious inputs
- [ ] SQL injection attempts fail
- [ ] XSS attempts fail
- [ ] IP whitelist enforces restrictions
- [ ] Rate limiting prevents abuse
- [ ] Audit logs capture all security events

### Step 5.4: User Acceptance Testing

- [ ] Operators can complete common tasks
- [ ] UI is intuitive
- [ ] Performance is acceptable
- [ ] Mobile/tablet experience is functional
- [ ] Search and filters work as expected

## Phase 6: Deployment

### Step 6.1: Create Production Environment

1. Repeat Phase 1 steps for production
2. Import solution from development
3. Configure production security settings
4. Update connection references

### Step 6.2: User Training

1. Create user documentation
2. Record training videos
3. Conduct training sessions
4. Provide quick reference guides

### Step 6.3: Rollout Plan

**Week 1**: Pilot with 5-10 users
- Gather feedback
- Fix critical issues
- Monitor performance

**Week 2-3**: Phased rollout to departments
- 25% of users
- Continue monitoring
- Address feedback

**Week 4**: Full deployment
- All users
- Ongoing support
- Performance optimization

### Step 6.4: Post-Deployment

- [ ] Monitor audit logs daily
- [ ] Review performance metrics
- [ ] Collect user feedback
- [ ] Plan feature enhancements
- [ ] Schedule regular security reviews

## Troubleshooting

### Common Issues

**Issue**: Users can't see data
- Check: Security roles assigned?
- Check: Tables shared with users?
- Check: Network connectivity?

**Issue**: Flows timeout
- Check: Execution time limits
- Check: API endpoint availability
- Optimize: Reduce operations per flow

**Issue**: Performance slow
- Check: Data row limits in galleries
- Check: Number of API calls
- Optimize: Implement caching
- Optimize: Use delegation where possible

## Maintenance

### Daily Tasks
- Review audit logs for security events
- Monitor flow run history
- Check for failed operations

### Weekly Tasks
- Review user feedback
- Update documentation
- Check for Microsoft updates

### Monthly Tasks
- Security review
- Performance optimization
- Backup verification
- User access review

### Quarterly Tasks
- Penetration testing
- Full security audit
- User training refresher
- Feature enhancement planning

## Support

### Getting Help

**Internal Support**:
- IT Help Desk: [contact info]
- App Administrator: [contact info]
- Documentation: [link to docs]

**Microsoft Resources**:
- Power Apps Community: powerusers.microsoft.com
- Microsoft Learn: docs.microsoft.com/powerapps
- Support: support.microsoft.com

## Appendix

### A: PowerFx Formula Reference

Common formulas used in WorkApp:

**Navigation**:
```powerFx
Set(varCurrentPage, "PageName")
```

**Filtering**:
```powerFx
Filter(Table, Condition)
```

**Sorting**:
```powerFx
SortByColumns(Table, "Column", Ascending)
```

**API Calls**:
```powerFx
FlowName.Run(param1, param2)
```

### B: API Endpoint Specifications

If implementing custom Azure Function for network diagnostics:

**Endpoint**: https://[your-function].azurewebsites.net/api/diagnostic

**Authentication**: Function key (stored in Azure Key Vault)

**Request**:
```json
{
  "action": "ping|nslookup|portcheck|traceroute",
  "target": "hostname or IP",
  "parameters": {
    "packetCount": 4,
    "port": 443
  }
}
```

**Response**:
```json
{
  "status": "success|failed|blocked",
  "output": "command output text",
  "executionTime": 1234,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### C: Color Palette Reference

Quick reference for Star Trek LCARS theme:

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| Deep Black | #0D0D0D | 13,13,13 | Primary background |
| Dark Gray | #1A1A1A | 26,26,26 | Secondary background |
| Medium Gray | #2A2A2A | 42,42,42 | Accent background |
| LCARS Blue | #3399FF | 51,153,255 | Primary accent/buttons |
| LCARS Orange | #FF9900 | 255,153,0 | Secondary accent |
| LCARS Teal | #00CC99 | 0,204,153 | Success messages |
| LCARS Yellow | #FFCC00 | 255,204,0 | Warnings |
| LCARS Red | #FF3366 | 255,51,102 | Errors/danger |
| Light Gray | #E0E0E0 | 224,224,224 | Primary text |
| Med-Light Gray | #B0B0B0 | 176,176,176 | Secondary text |

---

**Document Version**: 1.0  
**Last Updated**: [Implementation Date]  
**Next Review**: [3 months after implementation]
