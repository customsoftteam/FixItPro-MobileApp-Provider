/**
 * FixItPro Drawer - QUICK REFERENCE & CODE SNIPPETS
 * 
 * Use this file to quickly extract specific parts of the drawer implementation
 */

// ============================================================================
// 1. COLOR PALETTE - Copy & Paste this into your theme file
// ============================================================================

export const DrawerTheme = {
  colors: {
    // Primary Accent - MAIN THEME COLOR
    primary: '#12d3b5',              // Teal (change this for different theme)
    primaryLight: 'rgba(18, 211, 181, 0.18)',
    primaryLighter: 'rgba(18, 211, 181, 0.22)',
    primaryGlow: 'rgba(18, 211, 181, 0.45)',

    // Drawer styling
    drawerBg: 'linear-gradient(180deg, #111a2e 0%, #111d34 42%, #111a2f 100%)',
    drawerText: '#cbd5e1',
    drawerBorder: 'rgba(148, 163, 184, 0.12)',

    // Text colors
    textPrimary: '#f8fafc',
    textSecondary: '#97a7c1',
    textMuted: '#6f819f',
    textDark: '#8fa6c6',

    // Icon colors
    iconDefault: '#5d6f90',
    iconFooter: '#7b89a1',

    // Interactions
    hoverBg: 'rgba(148, 163, 184, 0.1)',

    // Header
    headerBg: '#ffffff',
    headerText: '#0f172a',
    headerBorder: '#e2e8f0',

    // Logo
    logoBg: '#11b9a3',
    logoText: '#e8fffb',
  },

  dimensions: {
    drawerWidth: 286,
    miniDrawerWidth: 92,
    headerHeight: 92,
    avatarSize: 34,
  },

  spacing: {
    menuItemPadding: 1.8,
    menuItemPaddingCompact: 1.2,
    menuItemMargin: 0.8,
    drawerListPadding: 1.6,
    drawerListPaddingCompact: 1,
  },

  transitions: {
    drawerWidth: 225,
    easing: 'sharp',
  },
};

// ============================================================================
// 2. MENU CONFIGURATION - Update paths & labels as needed
// ============================================================================

export const menuConfig = {
  main: [
    { label: 'Dashboard', path: '/app/dashboard', icon: 'DashboardOutlinedIcon' },
    { label: 'Bookings', path: '/app/bookings', icon: 'AssignmentOutlinedIcon' },
    { label: 'Availability', path: '/app/availability', icon: 'ScheduleOutlinedIcon' },
    { label: 'Services', path: '/app/skills', icon: 'BuildOutlinedIcon' },
    { label: 'Profile', path: '/app/profile', icon: 'PersonOutlineOutlinedIcon' },
    { label: 'Notifications', path: '/app/notifications', icon: 'NotificationsActiveOutlinedIcon' },
  ],

  footer: [
    { label: 'Settings', path: '/app/settings', icon: 'SettingsOutlinedIcon' },
    { label: 'Help', path: '/app/help', icon: 'HelpOutlineOutlinedIcon' },
  ],
};

// ============================================================================
// 3. STYLING PRESETS - Use these sx prop values directly
// ============================================================================

export const menuItemStyles = {
  base: {
    borderRadius: 2.5,
    mb: 0.8,
    px: 1.8,
    py: 1.4,
    justifyContent: 'flex-start',
    transition: 'all 0.2s ease-in-out',
    '& .MuiListItemIcon-root': {
      minWidth: 42,
    },
    '& .MuiListItemText-primary': {
      fontWeight: 600,
      fontSize: 18.5,
    },
  },

  compact: {
    px: 1.2,
    py: 1.4,
    justifyContent: 'center',
    '& .MuiListItemIcon-root': {
      minWidth: 0,
    },
  },

  active: {
    color: '#12d3b5',
    fontWeight: 700,
    '& .MuiListItemIcon-root': {
      color: '#12d3b5',
    },
    '&.Mui-selected': {
      backgroundColor: 'rgba(18, 211, 181, 0.18)',
    },
    '&.Mui-selected:hover': {
      backgroundColor: 'rgba(18, 211, 181, 0.22)',
    },
  },

  inactive: {
    color: '#97a7c1',
    '& .MuiListItemIcon-root': {
      color: '#5d6f90',
    },
    '&:hover': {
      backgroundColor: 'rgba(148, 163, 184, 0.1)',
    },
  },
};

// ============================================================================
// 4. COMPONENT TEMPLATES - Copy individual UI pieces
// ============================================================================

// --- DRAWER HEADER / BRAND SECTION ---
export const DrawerHeader = ({ compact, onMinimize, onExpand }) => `
<Toolbar sx={{ minHeight: '92px !important', borderBottom: '1px solid rgba(148, 163, 184, 0.12)' }}>
  <Stack 
    direction="row" 
    spacing={1.4} 
    alignItems="center" 
    sx={{ width: '100%', justifyContent: compact ? 'center' : 'space-between' }}
  >
    <Stack direction="row" spacing={1.4} alignItems="center" sx={{ minWidth: 0 }}>
      {/* Logo Icon */}
      <Box
        sx={{
          width: 48,
          height: 48,
          borderRadius: '16px',
          display: 'grid',
          placeItems: 'center',
          bgcolor: '#11b9a3',
        }}
      >
        <HandymanOutlinedIcon sx={{ color: '#e8fffb' }} />
      </Box>

      {/* Brand Text */}
      {!compact && (
        <Box>
          <Typography 
            variant="h5" 
            sx={{ fontWeight: 800, color: '#f8fafc', lineHeight: 1.1 }}
          >
            FixItPro
          </Typography>
          <Typography 
            sx={{ color: '#6f819f', fontSize: 14.5, mt: 0.2 }}
          >
            Service Provider
          </Typography>
        </Box>
      )}
    </Stack>

    {/* Minimize Button */}
    {!compact ? (
      <IconButton
        onClick={onMinimize}
        sx={{ color: '#8fa6c6' }}
        aria-label="Minimize drawer"
      >
        <ChevronLeftOutlinedIcon />
      </IconButton>
    ) : (
      <IconButton
        onClick={onExpand}
        sx={{ color: '#8fa6c6', position: 'absolute', right: 8 }}
        aria-label="Expand drawer"
      >
        <ChevronRightOutlinedIcon />
      </IconButton>
    )}
  </Stack>
</Toolbar>
`;

// --- MENU ITEM COMPONENT ---
export const MenuItemComponent = ({ item, active, compact, onClick }) => `
<ListItemButton
  selected={active}
  onClick={onClick}
  sx={{
    borderRadius: 2.5,
    mb: 0.8,
    px: compact ? 1.2 : 1.8,
    py: 1.4,
    justifyContent: compact ? 'center' : 'flex-start',
    color: active ? '#12d3b5' : '#97a7c1',
    transition: 'all 0.2s ease-in-out',
    
    '& .MuiListItemIcon-root': {
      color: active ? '#12d3b5' : '#5d6f90',
      minWidth: compact ? 0 : 42,
    },
    
    '& .MuiListItemText-primary': {
      fontWeight: active ? 700 : 600,
      fontSize: 18.5,
    },
    
    '&.Mui-selected': {
      backgroundColor: 'rgba(18, 211, 181, 0.18)',
    },
    
    '&.Mui-selected:hover': {
      backgroundColor: 'rgba(18, 211, 181, 0.22)',
    },
    
    '&:hover': {
      backgroundColor: 'rgba(148, 163, 184, 0.1)',
    },
  }}
>
  <ListItemIcon>{item.icon}</ListItemIcon>
  {!compact && <ListItemText primary={item.label} />}
  {active && !compact && (
    <Box
      sx={{
        width: 8,
        height: 8,
        borderRadius: '50%',
        bgcolor: '#12d3b5',
        boxShadow: '0 0 8px rgba(18, 211, 181, 0.45)',
      }}
    />
  )}
</ListItemButton>
`;

// --- STATUS CHIP (For Header) ---
export const StatusChipSnippet = ({ status }) => `
<Chip
  label={\`Status: \${status || 'INACTIVE'}\`}
  color={status === 'ACTIVE' ? 'success' : 'warning'}
  sx={{ mr: 2 }}
/>
`;

// --- PROFILE AVATAR (For Header) ---
export const ProfileAvatarSnippet = ({ profileImage, name, mobile, onClick }) => `
<Avatar
  onClick={onClick}
  sx={{ width: 34, height: 34, bgcolor: '#0ea5e9', mr: 1, fontSize: 14, cursor: 'pointer' }}
>
  {profileImage ? (
    <Box
      component="img"
      src={profileImage}
      alt="Profile"
      sx={{ width: '100%', height: '100%', objectFit: 'cover' }}
    />
  ) : (
    (name || mobile || 'P').slice(0, 1).toUpperCase()
  )}
</Avatar>
`;

// ============================================================================
// 5. RESPONSIVE LAYOUTS - Copy as needed
// ============================================================================

export const ResponsiveLayoutConfig = {
  // Mobile Drawer (temporary, shows on hamburger click)
  mobileSx: {
    display: { xs: 'block', sm: 'none' },
    '& .MuiDrawer-paper': {
      boxSizing: 'border-box',
      width: 286,
      borderRight: 'none',
    },
  },

  // Desktop Drawer (permanent, always visible)
  desktopSx: {
    display: { xs: 'none', sm: 'block' },
    '& .MuiDrawer-paper': {
      boxSizing: 'border-box',
      width: 286,     // Update: desktopDrawerWidth dynamic value
      borderRight: 'none',
      overflowX: 'hidden',
      transition: (theme) =>
        theme.transitions.create('width', {
          easing: theme.transitions.easing.sharp,
          duration: theme.transitions.duration.shorter,
        }),
    },
  },

  // AppBar responsive styling
  appBarSx: {
    width: { sm: `calc(100% - 286px)` },  // Update: desktopDrawerWidth
    ml: { sm: `286px` },  // Update: desktopDrawerWidth
    transition: (theme) =>
      theme.transitions.create(['width', 'margin'], {
        easing: theme.transitions.easing.sharp,
        duration: theme.transitions.duration.shorter,
      }),
    bgcolor: '#ffffff',
    color: '#0f172a',
    boxShadow: 'none',
    borderBottom: '1px solid #e2e8f0',
  },

  // Main content responsive
  mainSx: {
    flexGrow: 1,
    p: 3,
    width: { sm: `calc(100% - 286px)` },  // Update: desktopDrawerWidth
    transition: (theme) =>
      theme.transitions.create('width', {
        easing: theme.transitions.easing.sharp,
        duration: theme.transitions.duration.shorter,
      }),
  },
};

// ============================================================================
// 6. STATE MANAGEMENT PATTERNS
// ============================================================================

export const DrawerStateManagement = `
// State hooks needed
const [mobileOpen, setMobileOpen] = useState(false);
const [drawerMinimized, setDrawerMinimized] = useState(false);
const [notificationAnchor, setNotificationAnchor] = useState(null);
const [notificationFilter, setNotificationFilter] = useState('all');

// Router hooks
const navigate = useNavigate();
const location = useLocation();

// Context/Auth hooks (replace with your actual providers)
const { provider, logout } = useAuth();
const { notifications, unreadCount, loading } = useNotifications();

// Computed values
const openNotifications = Boolean(notificationAnchor);
const desktopDrawerWidth = drawerMinimized ? 92 : 286;
`;

// ============================================================================
// 7. UTILITY FUNCTIONS
// ============================================================================

export const Utils = {
  // Format notification timestamp
  formatDate: (value) => {
    if (!value) return '';
    try {
      return new Date(value).toLocaleString('en-IN', {
        day: '2-digit',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit',
      });
    } catch (_error) {
      return '';
    }
  },

  // Get user initials from name
  getInitials: (name, mobile) => {
    return (name || mobile || 'P').slice(0, 1).toUpperCase();
  },

  // Check if route is active
  isActiveRoute: (pathname, routePath) => {
    return pathname === routePath;
  },

  // Generate drawer width dynamic value
  getDrawerWidth: (isMinimized) => {
    return isMinimized ? 92 : 286;
  },
};

// ============================================================================
// 8. CUSTOMIZATION PRESETS - Different theme options
// ============================================================================

export const ThemePresets = {
  teal: {
    primary: '#12d3b5',
    primaryLight: 'rgba(18, 211, 181, 0.18)',
    primaryLighter: 'rgba(18, 211, 181, 0.22)',
    primaryGlow: 'rgba(18, 211, 181, 0.45)',
    drawerBg: 'linear-gradient(180deg, #111a2e 0%, #111d34 42%, #111a2f 100%)',
  },

  blue: {
    primary: '#3B82F6',
    primaryLight: 'rgba(59, 130, 246, 0.18)',
    primaryLighter: 'rgba(59, 130, 246, 0.22)',
    primaryGlow: 'rgba(59, 130, 246, 0.45)',
    drawerBg: 'linear-gradient(180deg, #0c1929 0%, #051e3e 100%)',
  },

  purple: {
    primary: '#a855f7',
    primaryLight: 'rgba(168, 85, 247, 0.18)',
    primaryLighter: 'rgba(168, 85, 247, 0.22)',
    primaryGlow: 'rgba(168, 85, 247, 0.45)',
    drawerBg: 'linear-gradient(180deg, #1e1b4b 0%, #2d1b69 100%)',
  },

  green: {
    primary: '#10b981',
    primaryLight: 'rgba(16, 185, 129, 0.18)',
    primaryLighter: 'rgba(16, 185, 129, 0.22)',
    primaryGlow: 'rgba(16, 185, 129, 0.45)',
    drawerBg: 'linear-gradient(180deg, #064e3b 0%, #022c1d 100%)',
  },

  orange: {
    primary: '#f97316',
    primaryLight: 'rgba(249, 115, 22, 0.18)',
    primaryLighter: 'rgba(249, 115, 22, 0.22)',
    primaryGlow: 'rgba(249, 115, 22, 0.45)',
    drawerBg: 'linear-gradient(180deg, #3f2413 0%, #1f1409 100%)',
  },
};

// ============================================================================
// 9. TESTING UTILITIES
// ============================================================================

export const TestingHelpers = {
  // Mock provider data for testing
  mockProvider: {
    name: 'John Service Provider',
    mobile: '9876543210',
    status: 'ACTIVE',
    profileImage: null,
  },

  // Mock notifications
  mockNotifications: [
    {
      _id: '1',
      title: 'New Booking',
      message: 'You have a new service booking',
      type: 'BOOKING_ASSIGNED',
      isRead: false,
      createdAt: new Date(),
    },
    {
      _id: '2',
      title: 'System Update',
      message: 'Check out our new features',
      type: 'GENERAL',
      isRead: true,
      createdAt: new Date(),
    },
  ],

  // Mock menu items for testing
  mockMenuItems: [
    { label: 'Dashboard', path: '/app/dashboard', icon: null },
    { label: 'Bookings', path: '/app/bookings', icon: null },
  ],
};

// ============================================================================
// 10. MIGRATION CHECKLIST
// ============================================================================

export const MigrationChecklist = \`
[ ] Copy all Material-UI imports
[ ] Copy Icon imports (MUI Icons)
[ ] Copy DrawerTheme colors constant
[ ] Copy menuConfig constant
[ ] Copy drawerContent function with proper typing
[ ] Copy ProviderLayout component
[ ] Replace mock provider with your useAuth hook
[ ] Replace mock notifications with your useNotifications hook
[ ] Update route paths to match your app routing
[ ] Update menu items as needed
[ ] Test desktop layout
[ ] Test mobile/tablet layout  
[ ] Test drawer collapse/expand on desktop
[ ] Test mobile hamburger menu
[ ] Test keyboard navigation (Tab, Enter, Escape)
[ ] Verify all icons render correctly
[ ] Test responsive width adjustments
[ ] Test notifications feature (if included)
[ ] Customize colors to match brand
[ ] Test on different screen sizes (480px, 768px, 1024px, 1440px)
[ ] Accessibility audit with axe DevTools
[ ] Performance check (React DevTools Profiler)
\`;

export default {
  DrawerTheme,
  menuConfig,
  menuItemStyles,
  Utils,
  ThemePresets,
  ResponsiveLayoutConfig,
};
