# WorkApp UI/UX Specifications

## UI Design Principles

### Core Principles
1. **Clarity**: Information should be immediately understandable
2. **Efficiency**: Minimize clicks to complete tasks
3. **Consistency**: Uniform patterns across the app
4. **Accessibility**: Usable by all operators
5. **Professional**: Star Trek LCARS-inspired aesthetic

### Design Language

**Visual Hierarchy**:
- Large headers for page titles
- Medium text for section headers
- Standard text for content
- Small text for metadata

**Spacing System**:
- XS: 4px (tight spacing)
- SM: 8px (compact spacing)
- MD: 16px (standard spacing)
- LG: 24px (loose spacing)
- XL: 32px (section spacing)
- XXL: 48px (major section spacing)

**Border Radius**:
- Buttons: 4px
- Cards: 8px
- Modals: 12px
- None for angular LCARS-style elements

## Layout System

### Grid Structure
- **Desktop** (1366 x 768): 12-column grid
- **Tablet** (1024 x 768): 8-column grid
- **Gutter**: 16px
- **Margin**: 24px

### Responsive Breakpoints
- Desktop: ≥1366px (primary target)
- Tablet: 768px - 1365px
- Mobile: <768px (reference only)

## Component Specifications

### 1. Navigation Panel

**Dimensions**:
- Width: 200px (fixed)
- Height: 100vh
- Position: Fixed left

**Structure**:
```
┌─────────────────────┐
│   WORKAPP LOGO      │ ← 60px height
├─────────────────────┤
│ 🏠 Dashboard        │ ← 60px height each
│ 📚 Knowledge Base   │
│ 🔧 Diagnostics      │
│ ⚙️  Settings        │
├─────────────────────┤
│                     │ ← Spacer (flex-grow)
├─────────────────────┤
│ 👤 User Name        │ ← 80px height
│    [Logout]         │
└─────────────────────┘
```

**Colors**:
- Background: #1A1A1A
- Active item: #2A2A2A
- Hover: #3399FF with 20% opacity
- Border-right: 1px solid #3399FF with 40% opacity

**Typography**:
- Logo: 24px, Bold, Uppercase
- Menu items: 16px, Medium
- User name: 14px, Regular

### 2. Page Header

**Dimensions**:
- Height: 80px
- Width: 100% (minus nav panel)
- Margin-bottom: 24px

**Structure**:
```
┌─────────────────────────────────────────────┐
│ Page Title                    [Action] [+]   │
│ Subtitle or breadcrumb                       │
└─────────────────────────────────────────────┘
```

**Typography**:
- Title: 32px, Bold, Uppercase
- Subtitle: 14px, Regular
- Color: #E0E0E0

### 3. Card Component

**Standard Card**:
```
┌───────────────────────────────┐
│ ┌───┐                         │ ← 8px padding
│ │🔷│ Card Title      [Action] │
│ └───┘                         │
├───────────────────────────────┤ ← 1px border
│                               │
│ Card content area             │
│ Multiple lines supported      │
│                               │
├───────────────────────────────┤
│ Footer / Metadata             │ ← Optional
└───────────────────────────────┘
```

**Dimensions**:
- Min-height: 120px
- Padding: 16px
- Border: 1px solid #3399FF with 40% opacity
- Border-radius: 8px
- Background: #2A2A2A

**Stat Card** (Dashboard):
```
┌─────────────┐
│    ▲▲▲      │ ← Icon
│             │
│    1,234    │ ← Large number (28px)
│             │
│ Applications│ ← Label (14px)
└─────────────┘
```

**Dimensions**:
- Width: 200px
- Height: 160px
- Centered content
- Background gradient: Linear (top: #2A2A2A, bottom: #1A1A1A)

### 4. Button Styles

**Primary Button**:
- Background: #3399FF
- Color: #FFFFFF
- Padding: 12px 24px
- Font: 14px, Medium
- Border-radius: 4px
- Hover: Brighten 10%
- Active: Darken 10%
- Disabled: 50% opacity

**Secondary Button**:
- Background: Transparent
- Color: #3399FF
- Border: 1px solid #3399FF
- Padding: 12px 24px
- Hover: Background #3399FF with 20% opacity

**Danger Button**:
- Background: #FF3366
- Color: #FFFFFF
- Other properties same as primary

**Icon Button**:
- Size: 40px x 40px
- Background: Transparent
- Color: #3399FF
- Border-radius: 4px
- Hover: Background #3399FF with 20% opacity

### 5. Input Fields

**Text Input**:
```
┌─────────────────────────────┐
│ Label Text                  │ ← 14px, #B0B0B0
├─────────────────────────────┤
│ Input value here...         │ ← 16px, #E0E0E0
└─────────────────────────────┘
  Helper text or error         ← 12px, #B0B0B0 or #FF3366
```

**Dimensions**:
- Height: 44px
- Padding: 12px
- Background: #0D0D0D
- Border: 1px solid #3399FF with 60% opacity
- Border-radius: 4px
- Focus: Border solid #3399FF, no opacity

**States**:
- Normal: Border 60% opacity
- Focus: Border 100% opacity, 2px blue glow
- Error: Border #FF3366, error text below
- Disabled: 50% opacity, cursor not-allowed

**Dropdown/Select**:
- Same as text input
- Chevron icon on right
- Options list with dark background
- Hover state on options: #3399FF with 20% opacity

### 6. Tables & Lists

**Data Table**:
```
┌─────────────────────────────────────────────┐
│ Column 1    │ Column 2    │ Column 3  │ ⚡  │ ← Header
├─────────────┼─────────────┼───────────┼────┤
│ Data 1      │ Data 2      │ Data 3    │ ⋮  │ ← Row
│ Data 1      │ Data 2      │ Data 3    │ ⋮  │
│ Data 1      │ Data 2      │ Data 3    │ ⋮  │
└─────────────────────────────────────────────┘
```

**Styling**:
- Header background: #2A2A2A
- Header text: 14px, Bold, Uppercase
- Row height: 48px
- Row separator: 1px solid #3399FF with 20% opacity
- Hover row: #3399FF with 10% opacity
- Alternate rows: Optional #1A1A1A / #0D0D0D

**Gallery/List View**:
```
┌────────────────────────┐
│ ┌──┐                   │
│ │🔷│ Item Title        │ ← 56px height
│ │  │ Subtitle/meta     │
│ └──┘                   │
├────────────────────────┤
│ ┌──┐                   │
│ │🔷│ Item Title        │
│ │  │ Subtitle/meta     │
│ └──┘                   │
└────────────────────────┘
```

### 7. Status Indicators

**Status Badge**:
- Pill shape (border-radius: 12px)
- Padding: 4px 12px
- Font: 12px, Medium, Uppercase

**Colors by Status**:
- Active: Background #00CC99, Text #000000
- Inactive: Background #B0B0B0, Text #000000
- Deprecated: Background #FF3366, Text #FFFFFF
- In Development: Background #FFCC00, Text #000000
- Success: Background #00CC99
- Warning: Background #FFCC00
- Error: Background #FF3366

**Availability Indicator**:
- Circle: 10px diameter
- Colors:
  - Available: #00CC99
  - Busy: #FFCC00
  - Out of Office: #B0B0B0
- Position: Next to name

### 8. Modal/Dialog

```
┌─────────────────────────────────────────┐
│ Dialog Title                        [×] │ ← Header: 60px
├─────────────────────────────────────────┤
│                                         │
│                                         │
│         Dialog Content Area             │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│                    [Cancel]  [Confirm]  │ ← Footer: 60px
└─────────────────────────────────────────┘
```

**Dimensions**:
- Width: 600px (medium), 800px (large), 400px (small)
- Max-height: 80vh
- Background: #1A1A1A
- Border: 2px solid #3399FF
- Border-radius: 12px
- Backdrop: RGBA(0, 0, 0, 0.8)

**Animation**:
- Fade in backdrop: 200ms
- Scale up modal: 300ms ease-out

### 9. Toast Notifications

```
┌─────────────────────────────────┐
│ ⓘ Notification message here     │ ← 60px height
└─────────────────────────────────┘
```

**Position**: Top-center, 24px from top
**Width**: Max 600px
**Auto-dismiss**: 5 seconds
**Close button**: Optional X on right

**Types**:
- Info: Border-left 4px solid #3399FF
- Success: Border-left 4px solid #00CC99
- Warning: Border-left 4px solid #FFCC00
- Error: Border-left 4px solid #FF3366

### 10. Loading States

**Spinner**:
- Size: 40px
- Color: #3399FF
- Animation: Rotation 1s infinite linear
- Centered in container

**Skeleton Loading**:
- Background: #2A2A2A
- Animated gradient: Light gray sweep
- Matches component dimensions

**Progress Bar**:
- Height: 4px
- Background: #2A2A2A
- Fill: #3399FF
- Animation: Smooth fill

## Screen Layouts

### Dashboard Screen

```
┌─[Nav]──────────────────────────────────────────────────┐
│       │ DASHBOARD                                       │
│       ├─────────────────────────────────────────────────┤
│ Menu  │ Welcome, John Doe                               │
│       │                                                 │
│ Items │ ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐            │
│       │ │ 256 │  │  12 │  │  4  │  │ ✓   │            │
│       │ │Apps │  │Teams│  │Tests│  │Good │            │
│       │ └─────┘  └─────┘  └─────┘  └─────┘            │
│       │                                                 │
│       │ Recent Activity                                 │
│       │ ┌───────────────────────────────────────────┐  │
│       │ │ • Exchange Server updated       2m ago   │  │
│       │ │ • Network diagnostic run        5m ago   │  │
│       │ │ • New team member added         1h ago   │  │
│       │ └───────────────────────────────────────────┘  │
│       │                                                 │
│       │ Quick Actions                                   │
│       │ [+ New App]  [Run Test]  [View Teams]          │
└───────┴─────────────────────────────────────────────────┘
```

### Knowledge Base Screen

```
┌─[Nav]──────────────────────────────────────────────────┐
│       │ KNOWLEDGE BASE              [+ Add New]         │
│       ├─────────────────────────────────────────────────┤
│       │ [Applications] [Teams] [Team Members] [Notes]   │
│       ├─────────────────────────────────────────────────┤
│ Menu  │ ┌────────────┬──────────────┐                  │
│       │ │ Search     │ Category  ▼  │                  │
│ Items │ └────────────┴──────────────┘                  │
│       │                                                 │
│       │ ┌─────────────────────────────────────────┐    │
│       │ │ 🔷 Microsoft Exchange Server      ✓     │    │
│       │ │    Version 2019 | Active | Infra       │    │
│       │ └─────────────────────────────────────────┘    │
│       │ ┌─────────────────────────────────────────┐    │
│       │ │ 🔷 SQL Server 2019               ✓     │    │
│       │ │    Version 2019 | Active | Database    │    │
│       │ └─────────────────────────────────────────┘    │
│       │ ┌─────────────────────────────────────────┐    │
│       │ │ 🔷 Active Directory               ⚠     │    │
│       │ │    Version 2016 | Deprecated | Infra   │    │
│       │ └─────────────────────────────────────────┘    │
└───────┴─────────────────────────────────────────────────┘
```

### Network Diagnostics Screen

```
┌─[Nav]──────────────────────────────────────────────────┐
│       │ NETWORK DIAGNOSTICS                             │
│       ├─────────────────────────────────────────────────┤
│       │ [Ping] [NSLookup] [Port Check] [Trace Route]   │
│ Menu  ├─────────────────────────────────────────────────┤
│       │                                                 │
│ Items │ Target Host or IP Address                       │
│       │ ┌─────────────────────────────────────────┐    │
│       │ │ 192.168.1.1                             │    │
│       │ └─────────────────────────────────────────┘    │
│       │                                                 │
│       │ Packet Count: [====●─────] 4                   │
│       │                                                 │
│       │                     [Run Diagnostic]            │
│       │                                                 │
│       │ ┌─────────────────────────────────────────┐    │
│       │ │ Results                                 │    │
│       │ │ ──────────────────────────────────────  │    │
│       │ │ $ ping 192.168.1.1 -n 4                │    │
│       │ │                                         │    │
│       │ │ Pinging 192.168.1.1 with 32 bytes:     │    │
│       │ │ Reply from 192.168.1.1: time=1ms TTL=64│    │
│       │ │ Reply from 192.168.1.1: time=1ms TTL=64│    │
│       │ │ Reply from 192.168.1.1: time=1ms TTL=64│    │
│       │ │ Reply from 192.168.1.1: time=1ms TTL=64│    │
│       │ │                                         │    │
│       │ │ Statistics: 4 sent, 4 received, 0% loss│    │
│       │ └─────────────────────────────────────────┘    │
│       │                                                 │
│       │ ▼ Recent Diagnostics (5)                        │
└───────┴─────────────────────────────────────────────────┘
```

### Application Detail View (Modal/Slide-in)

```
┌─────────────────────────────────────────┐
│ Microsoft Exchange Server          [×]  │
├─────────────────────────────────────────┤
│ Version: 2019                           │
│ Status: ✓ Active                        │
│ Category: Infrastructure                │
│                                         │
│ Description                             │
│ ─────────────────────────────────────   │
│ Enterprise email and calendar server    │
│ used across the organization...         │
│                                         │
│ Dependencies                            │
│ ─────────────────────────────────────   │
│ • Active Directory                      │
│ • SQL Server 2019                       │
│ • Windows Server 2019                   │
│                                         │
│ Support Team                            │
│ ─────────────────────────────────────   │
│ Infrastructure Team                     │
│ 📧 infra@company.com                    │
│ 📞 555-0100                             │
│                                         │
│ [View Full Details]                     │
│                                         │
├─────────────────────────────────────────┤
│ Last updated: 2 hours ago by John Doe   │
│                                         │
│                      [Edit]  [Delete]   │
└─────────────────────────────────────────┘
```

### Team Member Card

```
┌─────────────────────────────────┐
│ ┌───┐                           │
│ │ JD│  John Doe                 │
│ └───┘  Senior Engineer      ● Available
│                                 │
│ 📧 john.doe@company.com         │
│ 📞 555-0123                     │
│                                 │
│ Department: Infrastructure      │
│ Specializations:                │
│ • Active Directory              │
│ • Exchange Server               │
│ • Windows Server                │
│                                 │
│ [Send Email]    [View Profile]  │
└─────────────────────────────────┘
```

## Interactive States

### Hover States
- **Buttons**: Brightness +10%, Cursor: pointer
- **Cards**: Subtle elevation (box-shadow), Border brightness +20%
- **List items**: Background: #3399FF with 10% opacity
- **Links**: Underline, Color brightness +20%

### Focus States
- **Inputs**: Border color: #3399FF 100%, 2px blue glow
- **Buttons**: Blue outline 2px, 2px offset
- **Links**: Blue outline

### Active/Pressed States
- **Buttons**: Brightness -10%, Scale: 0.98
- **Cards**: Elevation reduced

### Disabled States
- **All elements**: Opacity: 50%, Cursor: not-allowed
- **Buttons**: No hover effects

### Loading States
- **Buttons**: Spinner inside, Text: "Loading..."
- **Content areas**: Skeleton placeholders
- **Full screen**: Centered spinner with backdrop

## Animation Guidelines

### Timing Functions
- **Standard**: ease-out (0.25s)
- **Fast**: ease-out (0.15s)
- **Slow**: ease-out (0.4s)

### Animations
- **Page transitions**: Fade (300ms)
- **Modal open**: Scale + fade (300ms)
- **Toast appear**: Slide down (200ms)
- **Hover**: All transitions (150ms)
- **Loading spinner**: Rotate (1s infinite)
- **Pulse**: Scale (2s infinite) for notifications

### Best Practices
- Keep animations subtle
- Use for feedback and guidance
- Never block user interaction
- Reduce motion for accessibility

## Accessibility Requirements

### Color Contrast
- Text on background: Minimum 4.5:1 ratio
- Large text: Minimum 3:1 ratio
- All colors tested and compliant

### Keyboard Navigation
- All interactive elements: Tab accessible
- Logical tab order maintained
- Skip navigation link available
- Focus indicators visible

### Screen Readers
- All images: Alt text
- Form inputs: Proper labels
- ARIA labels where needed
- Semantic HTML structure

### Responsive Text
- Minimum font size: 14px
- Line height: 1.5 minimum
- Adjustable text size support

## Icon System

### Icon Style
- Line icons (not filled)
- 24px default size
- Consistent stroke width: 2px
- Color: #3399FF (can be overridden)

### Common Icons
- Dashboard: 🏠 Home
- Knowledge Base: 📚 Book
- Diagnostics: 🔧 Wrench
- Settings: ⚙️ Gear
- Add: ➕ Plus
- Edit: ✏️ Pencil
- Delete: 🗑️ Trash
- Search: 🔍 Magnifying glass
- Filter: 🔻 Funnel
- Info: ℹ️ Circle-i
- Success: ✓ Checkmark
- Warning: ⚠️ Triangle
- Error: ✖️ X

## Typography Scale

### Font Family
- Primary: Segoe UI, Roboto, -apple-system, sans-serif
- Monospace: 'Courier New', Courier, monospace (for code/diagnostics)

### Type Scale
- **H1**: 32px / 2rem, Bold, Uppercase, Line-height: 1.2
- **H2**: 24px / 1.5rem, Bold, Uppercase, Line-height: 1.3
- **H3**: 20px / 1.25rem, Semi-bold, Line-height: 1.4
- **H4**: 18px / 1.125rem, Semi-bold, Line-height: 1.4
- **Body Large**: 16px / 1rem, Regular, Line-height: 1.5
- **Body**: 14px / 0.875rem, Regular, Line-height: 1.5
- **Small**: 12px / 0.75rem, Regular, Line-height: 1.4
- **Caption**: 11px / 0.6875rem, Regular, Line-height: 1.3

### Font Weights
- Regular: 400
- Medium: 500
- Semi-bold: 600
- Bold: 700

## Responsive Behavior

### Desktop (≥1366px)
- Full feature set
- Multi-column layouts
- Hover states active
- Side-by-side views

### Tablet (768-1365px)
- Slightly condensed layouts
- Some columns stack
- Touch-friendly targets (44px minimum)
- Simplified navigation

### Mobile (<768px)
- Reference only (not primary use case)
- Single column layout
- Hamburger navigation
- Essential features only
- Increased padding for touch

## Dark Theme Optimization

### Readability
- Light text on dark background
- Sufficient contrast ratios
- Avoid pure white (#E0E0E0 instead of #FFFFFF)
- Avoid pure black (use #0D0D0D)

### Elevation
- Use subtle borders instead of heavy shadows
- Light borders (#3399FF with opacity)
- Minimal depth effects

### Color Intensity
- Slightly desaturated colors
- No bright whites
- Softer highlights

## Performance Guidelines

### Image Optimization
- Use SVG for icons
- Compress images
- Lazy load off-screen images
- Use appropriate formats (WebP where supported)

### Animation Performance
- Use CSS transforms (not position)
- Limit simultaneous animations
- Use will-change sparingly
- Debounce scroll/resize events

### Rendering
- Minimize repaints
- Use efficient selectors
- Limit nested components
- Virtualize long lists

## Print Styles (Optional)

If printing support needed:

### Adjustments
- Switch to white background
- Black text
- Remove navigation
- Remove interactive elements
- Expand collapsed sections
- Show all data (unpaginated)

---

**Document Version**: 1.0  
**Last Updated**: [Creation Date]  
**Design Owner**: UI/UX Team
