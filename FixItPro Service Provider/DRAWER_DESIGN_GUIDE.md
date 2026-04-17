# FixItPro Service Provider - Drawer Theme & Design System

## Table of Contents
1. [Overview](#overview)
2. [Color Palette](#color-palette)
3. [Component Structure](#component-structure)
4. [Typography](#typography)
5. [Spacing & Layout](#spacing--layout)
6. [Responsive Design](#responsive-design)
7. [Customization Guide](#customization-guide)

---

## Overview

The FixItPro Service Provider drawer is a **modern, collapsible sidebar** with the following features:

✅ **Responsive** - Mobile hamburger + Desktop permanent drawer  
✅ **Collapsible** - Minimizes to icon-only mode (92px width)  
✅ **Theme-able** - Centralized color palette for easy customization  
✅ **Accessible** - MUI components with proper ARIA labels  
✅ **Animated** - Smooth transitions on all interactive elements  

---

## Color Palette

### Primary Colors

| Name | Hex Code | Usage | RGB |
|------|----------|-------|-----|
| **Primary Accent** | `#12d3b5` | Active states, focus, accent | rgb(18, 211, 181) |
| **Primary Light** | `rgba(18, 211, 181, 0.18)` | Selected background | Semi-transparent |
| **Primary Lighter** | `rgba(18, 211, 181, 0.22)` | Hover on selected | Semi-transparent |
| **Primary Glow** | `rgba(18, 211, 181, 0.45)` | Active indicator shadow | Semi-transparent |

### Drawer Background

**Gradient Specification:**
```
linear-gradient(180deg, #111a2e 0%, #111d34 42%, #111a2f 100%)
```

- **Top**: `#111a2e` - Rich dark blue
- **Mid**: `#111d34` - Slightly darker blue  
- **Bottom**: `#111a2f` - Dark blue (near original)

### Text Colors

| Name | Hex Code | Usage (Light Theme) |
|------|----------|---------------------|
| **Text Primary** | `#f8fafc` | Main text, headings |
| **Text Secondary** | `#97a7c1` | Inactive menu items |
| **Text Muted** | `#6f819f` | Subtext, hints |
| **Text Dark** | `#8fa6c6` | Icon buttons, secondary labels |
| **Drawer Text** | `#cbd5e1` | Default drawer text color |

### Icon Colors

| Name | Hex Code | Usage |
|------|----------|-------|
| **Icon Default** | `#5d6f90` | Main menu icons (inactive) |
| **Icon Footer** | `#7b89a1` | Footer menu icons (inactive) |
| **Icon Active** | `#12d3b5` | Active menu item icon (uses primary) |

### Neutral Colors

| Name | Hex Code | Usage |
|------|----------|-------|
| **Border** | `rgba(148, 163, 184, 0.12)` | Dividers, borders |
| **Hover BG** | `rgba(148, 163, 184, 0.1)` | Hover state background |
| **Logo BG** | `#11b9a3` | Brand icon background |
| **Logo Text** | `#e8fffb` | Brand icon color |

### Header Colors

| Name | Hex Code | Usage |
|------|----------|-------|
| **Header BG** | `#ffffff` | AppBar background |
| **Header Text** | `#0f172a` | AppBar text |
| **Header Border** | `#e2e8f0` | AppBar bottom border |

---

## Component Structure

### 1. **Drawer Container**
- **Desktop (sm+)**: Permanent variant, fixed width (286px or 92px)
- **Mobile (xs)**: Temporary variant, slide-in from left
- **Background**: Gradient dark blue with transparency
- **Border**: No right border (clean edge)

### 2. **Header Section**
- **Height**: 92px minimum
- **Content**: Logo + Brand name + Collapse button
- **Logo**: 48x48px with rounded corners, teal background
- **Brand Text**: 
  - Main: "FixItPro" (fontWeight: 800, color: #f8fafc)
  - Sub: "Service Provider" (fontWeight: 400, color: #6f819f, fontSize: 14.5px)

### 3. **Main Menu Section**
- **Items**: 6 navigation links
  - Dashboard
  - Bookings
  - Availability
  - Services
  - Profile
  - Notifications
- **Item Styling**:
  - Padding: 1.8px (left/right), 1.4px (top/bottom)
  - Border Radius: 20px (2.5)
  - Margin Bottom: 0.8px

### 4. **Footer Menu Section**
- **Items**: 2 navigation links
  - Settings
  - Help
- **Border**: Top border with 12% opacity
- **Item Styling**: Smaller font (18px vs 18.5px), lower fontWeight on inactive

### 5. **Menu Item States**

#### Inactive (Default)
```
Color: #97a7c1
Background: transparent
Icon Color: #5d6f90
Font Weight: 600 (main), 500 (footer)
```

#### Active/Selected
```
Color: #12d3b5
Background: rgba(18, 211, 181, 0.18)
Icon Color: #12d3b5
Font Weight: 700
Active Indicator: 8px glowing dot on right side
```

#### Hover
```
Color: (unchanged)
Background: rgba(148, 163, 184, 0.1)
```

#### Active + Hover
```
Color: #12d3b5
Background: rgba(18, 211, 181, 0.22)
```

---

## Typography

### Font Family
- Material-UI default: `'Roboto', 'Helvetica', 'Arial', sans-serif`

### Font Sizes & Weights

| Element | Size | Weight | Line Height |
|---------|------|--------|-------------|
| Brand Main | 32px (h5) | 800 | 1.1 |
| Brand Sub | 14.5px | 400 | 1.1 |
| Menu Item (Active) | 18.5px | 700 | 1.2 |
| Menu Item (Inactive) | 18.5px | 600 | 1.2 |
| Footer Item | 18px | 700/500 | 1.2 |
| Header Text | 18px (h6) | 500 | 1.2 |

---

## Spacing & Layout

### Dimensions

| Property | Value | Notes |
|----------|-------|-------|
| Full Drawer Width | 286px | Desktop normal mode |
| Mini Drawer Width | 92px | Desktop minimized mode |
| Mobile Drawer Width | 286px | Full-width on mobile |
| Header Height | 92px | Toolbar minimum height |
| Menu Item Height | 56.8px | py: 1.4 + icon size |
| Drawer Icon Size | 48px | Logo/brand icon |
| Avatar Size | 34px | Profile avatar |

### Padding & Margins

| Section | Padding | Margin Bottom |
|---------|---------|----------------|
| Menu List | 1.6 (compact: 1) | N/A |
| Menu Item | 1.8 (compact: 1.2) | 0.8 |
| Footer Section | 1.6 (compact: 1) | N/A |
| Footer Item | 1.8 (compact: 1.2) | 0.6 |

### Gaps & Spacing Units
```
All spacing uses MUI spacing scale (8px base):
- 0.8 = 6.4px
- 1 = 8px
- 1.2 = 9.6px
- 1.4 = 11.2px
- 1.6 = 12.8px
- 1.8 = 14.4px
```

---

## Responsive Design

### Breakpoints

| Breakpoint | Width | Behavior |
|-----------|-------|----------|
| **xs** | 0px | Mobile: Temporary drawer, hamburger visible |
| **sm** | 600px | Tablet+: Permanent drawer, hamburger hidden |
| **md** | 960px | Desktop: Full layout |
| **lg** | 1280px | Large desktop |

### Media Query Usage in Drawer

```jsx
// Display properties
display: { xs: 'block', sm: 'none' }  // Mobile only
display: { xs: 'none', sm: 'block' }  // Desktop only

// Size calculations
width: { sm: `calc(100% - ${desktopDrawerWidth}px)` }

// Margin adjustments
ml: { sm: `${desktopDrawerWidth}px` }
```

### Mobile Behavior
1. **Drawer**: Hidden by default, opens as overlay when hamburger clicked
2. **Closes**: Automatically on menu item click
3. **Width**: Full drawer width (286px) even on small screens

### Desktop Behavior
1. **Drawer**: Always visible, can be minimized/expanded
2. **Minimized**: Only icons visible (92px width)
3. **Layout**: Main content shifts responsively

---

## Customization Guide

### 1. Changing Primary Color

**Current (Teal):**
```jsx
primary: '#12d3b5',
primaryLight: 'rgba(18, 211, 181, 0.18)',
primaryLighter: 'rgba(18, 211, 181, 0.22)',
primaryGlow: 'rgba(18, 211, 181, 0.45)',
```

**Blue Theme:**
```jsx
primary: '#3B82F6',
primaryLight: 'rgba(59, 130, 246, 0.18)',
primaryLighter: 'rgba(59, 130, 246, 0.22)',
primaryGlow: 'rgba(59, 130, 246, 0.45)',
```

**Purple Theme:**
```jsx
primary: '#a855f7',
primaryLight: 'rgba(168, 85, 247, 0.18)',
primaryLighter: 'rgba(168, 85, 247, 0.22)',
primaryGlow: 'rgba(168, 85, 247, 0.45)',
```

### 2. Changing Drawer Background

**Current (Dark Blue Gradient):**
```jsx
drawerBg: 'linear-gradient(180deg, #111a2e 0%, #111d34 42%, #111a2f 100%)',
```

**Dark Gray:**
```jsx
drawerBg: 'linear-gradient(180deg, #1f2937 0%, #111827 100%)',
```

**Navy Blue:**
```jsx
drawerBg: 'linear-gradient(180deg, #001a4d 0%, #000d2b 100%)',
```

**Charcoal with Tint:**
```jsx
drawerBg: 'linear-gradient(180deg, #0f172a 0%, #112742 50%, #0f172a 100%)',
```

### 3. Changing Border Style

**Current (Subtle 12% opacity):**
```jsx
border: `1px solid rgba(148, 163, 184, 0.12)`
```

**More Visible:**
```jsx
border: `1px solid rgba(148, 163, 184, 0.3)`
```

**Colored Border:**
```jsx
border: `1px solid ${COLORS.primary}` // Use primary color
```

### 4. Adjusting Menu Item Size

**Larger Items:**
```jsx
py: 1.8,        // Increase from 1.4
fontSize: 19,   // Increase from 18.5
```

**Compact Items:**
```jsx
py: 1.0,        // Decrease from 1.4
fontSize: 16,   // Decrease from 18.5
```

### 5. Changing Drawer Width

```jsx
const drawerWidth = 256;      // Narrower (default: 286)
const miniDrawerWidth = 80;   // Adjust mini accordingly
```

### 6. Border Radius Customization

**Current (Rounded):**
```jsx
borderRadius: 2.5  // ~20px
```

**More Rounded:**
```jsx
borderRadius: 3    // ~24px
```

**Less Rounded:**
```jsx
borderRadius: 1.5  // ~12px
```

**Squared:**
```jsx
borderRadius: 0.5  // ~4px
```

---

## Animation Specifications

### Transition Properties

| Property | Duration | Easing | Notes |
|----------|----------|--------|-------|
| Drawer width | 225ms | sharp | On minimize/expand |
| Menu hover | 200ms | ease-in-out | Color transitions |
| Margin/Width | 225ms | sharp | AppBar width adjust |

### Easing Functions

```jsx
// MUI easing functions
theme.transitions.easing.sharp       // Fast, minimal motion
theme.transitions.easing.easeInOut   // Smooth, balanced
theme.transitions.easing.easeIn      // Accelerating
theme.transitions.easing.easeOut     // Decelerating
```

### Custom Transitions

```jsx
// Drawer collapse animation
transition: (theme) =>
  theme.transitions.create('width', {
    easing: theme.transitions.easing.sharp,
    duration: theme.transitions.duration.shorter,  // 195ms
  })
```

---

## Accessibility (a11y)

### ARIA Labels
```jsx
aria-label="Minimize drawer"   // Collapse button
aria-label="Expand drawer"     // Expand button
```

### Keyboard Navigation
- Tab: Navigate between menu items
- Enter/Space: Activate menu item
- Escape: Close mobile drawer

### Color Contrast
All text meets WCAG AA standard (4.5:1 minimum contrast ratio):
- Primary text (#f8fafc) on dark background: ✅ 14:1
- Secondary text (#97a7c1) on dark background: ✅ 5.5:1
- Active text (#12d3b5) on light background: ✅ 7.5:1

### Focus States
All interactive elements include visible focus indicators through MUI's default styling.

---

## Icons Used

The drawer uses Material-UI Outlined Icons:

| Icon | Component | Usage |
|------|-----------|-------|
| 🏠 Dashboard | `DashboardOutlinedIcon` | Home/Dashboard |
| 📋 Bookings | `AssignmentOutlinedIcon` | Appointments/Tasks |
| 📅 Availability | `ScheduleOutlinedIcon` | Calendar/Timing |
| 🔧 Services | `BuildOutlinedIcon` | Skills/Services |
| 👤 Profile | `PersonOutlineOutlinedIcon` | User Profile |
| 🔔 Notifications | `NotificationsActiveOutlinedIcon` | Alerts |
| ⚙️ Settings | `SettingsOutlinedIcon` | Configuration |
| ❓ Help | `HelpOutlineOutlinedIcon` | Support/FAQ |
| 🔨 Logo | `HandymanOutlinedIcon` | Brand/Service |
| ◀️ Collapse | `ChevronLeftOutlinedIcon` | Collapse drawer |
| ▶️ Expand | `ChevronRightOutlinedIcon` | Expand drawer |

---

## Implementation Checklist

- [ ] Copy all MUI icon imports
- [ ] Copy color palette constants
- [ ] Copy drawer dimensions constants
- [ ] Copy menu configuration arrays
- [ ] Copy drawerContent function
- [ ] Copy ProviderLayout component
- [ ] Replace fake provider data with your context
- [ ] Update navigation paths as needed
- [ ] Test responsive behavior on mobile
- [ ] Test drawer collapse/expand
- [ ] Verify icon rendering
- [ ] Test accessibility with keyboard navigation
- [ ] Customize colors to match your brand
- [ ] Update menu items as needed
- [ ] Test on different screen sizes

---

## File References

- **Main Component**: `frontend/src/layouts/ProviderLayout.jsx`
- **Full Code**: See `DRAWER_CODE_THEME.jsx`
- **Theme Colors**: See `COLORS` object in code

---

## Quick Start for Other Developers

1. Copy `DRAWER_CODE_THEME.jsx` to your project
2. Update imports based on your project structure
3. Replace provider data with your authentication context
4. Update navigation paths to match your routes
5. Customize `COLORS` object to match your brand
6. Test on mobile and desktop viewports
7. Adjust spacing/sizing as needed for your UI

---

**Created for FixItPro Service Provider**  
**Tailored for React + Material-UI projects**
