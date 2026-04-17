/**
 * FixItPro Service Provider - Drawer Code & Theme
 * Complete Draw implementation with collapsible sidebar, navigation menu, status chip, and notifications
 * 
 * This code can be adapted for any React + Material-UI project
 */

// ============================================================================
// IMPORTS
// ============================================================================

import {
  AppBar,
  Box,
  Badge,
  CssBaseline,
  Drawer,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  Chip,
  Button,
  Avatar,
  Stack,
  Menu,
  MenuItem,
  Divider,
  CircularProgress,
  Snackbar,
  Alert,
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import DashboardOutlinedIcon from '@mui/icons-material/DashboardOutlined';
import AssignmentOutlinedIcon from '@mui/icons-material/AssignmentOutlined';
import PersonOutlineOutlinedIcon from '@mui/icons-material/PersonOutlineOutlined';
import BuildOutlinedIcon from '@mui/icons-material/BuildOutlined';
import ScheduleOutlinedIcon from '@mui/icons-material/ScheduleOutlined';
import HandymanOutlinedIcon from '@mui/icons-material/HandymanOutlined';
import SettingsOutlinedIcon from '@mui/icons-material/SettingsOutlined';
import HelpOutlineOutlinedIcon from '@mui/icons-material/HelpOutlineOutlined';
import NotificationsNoneOutlinedIcon from '@mui/icons-material/NotificationsNoneOutlined';
import NotificationsActiveOutlinedIcon from '@mui/icons-material/NotificationsActiveOutlined';
import ChevronLeftOutlinedIcon from '@mui/icons-material/ChevronLeftOutlined';
import ChevronRightOutlinedIcon from '@mui/icons-material/ChevronRightOutlined';
import { useEffect, useMemo, useState } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';

// ============================================================================
// CONSTANTS - DIMENSIONS
// ============================================================================

const drawerWidth = 286;      // Full drawer width
const miniDrawerWidth = 92;   // Minimized drawer width

// ============================================================================
// CONSTANTS - MENU CONFIGURATION
// ============================================================================

// Main navigation menu items (displayed at top)
const menu = [
  { label: 'Dashboard', path: '/app/dashboard', icon: <DashboardOutlinedIcon /> },
  { label: 'Bookings', path: '/app/bookings', icon: <AssignmentOutlinedIcon /> },
  { label: 'Availability', path: '/app/availability', icon: <ScheduleOutlinedIcon /> },
  { label: 'Services', path: '/app/skills', icon: <BuildOutlinedIcon /> },
  { label: 'Profile', path: '/app/profile', icon: <PersonOutlineOutlinedIcon /> },
  { label: 'Notifications', path: '/app/notifications', icon: <NotificationsActiveOutlinedIcon /> },
];

// Footer menu items (displayed at bottom)
const footerMenu = [
  { label: 'Settings', path: '/app/settings', icon: <SettingsOutlinedIcon /> },
  { label: 'Help', path: '/app/help', icon: <HelpOutlineOutlinedIcon /> },
];

// ============================================================================
// COLOR PALETTE - THEME COLORS
// ============================================================================

const COLORS = {
  // Drawer
  drawerBg: 'linear-gradient(180deg, #111a2e 0%, #111d34 42%, #111a2f 100%)',
  drawerText: '#cbd5e1',
  drawerBorder: 'rgba(148, 163, 184, 0.12)',
  
  // Accent colors
  primary: '#12d3b5',        // Teal/Turquoise
  primaryLight: 'rgba(18, 211, 181, 0.18)',
  primaryLighter: 'rgba(18, 211, 181, 0.22)',
  primaryGlow: 'rgba(18, 211, 181, 0.45)',
  
  // Text colors
  textPrimary: '#f8fafc',
  textSecondary: '#97a7c1',
  textMuted: '#6f819f',
  textDark: '#8fa6c6',
  
  // Icon colors
  iconDefault: '#5d6f90',
  iconFooter: '#7b89a1',
  
  // Hover state
  hoverBg: 'rgba(148, 163, 184, 0.1)',
  
  // Header
  headerBg: '#ffffff',
  headerText: '#0f172a',
  headerBorder: '#e2e8f0',
  
  // Logo bg
  logoBg: '#11b9a3',
  logoText: '#e8fffb',
};

// ============================================================================
// DRAWER CONTENT COMPONENT (RECURSIVE - Used for both mobile & desktop)
// ============================================================================

const drawerContent = (compact = false, locationPathname, navigate, setMobileOpen) => (
  <Box
    sx={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      color: COLORS.drawerText,
      background: COLORS.drawerBg,
    }}
  >
    {/* TOP SECTION - Brand + Logo + Collapse Button */}
    <Box>
      <Toolbar sx={{ minHeight: '92px !important', borderBottom: `1px solid ${COLORS.drawerBorder}` }}>
        <Stack 
          direction="row" 
          spacing={1.4} 
          alignItems="center" 
          sx={{ width: '100%', justifyContent: compact ? 'center' : 'space-between' }}
        >
          <Stack direction="row" spacing={1.4} alignItems="center" sx={{ minWidth: 0 }}>
            {/* Brand Icon */}
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: '16px',
                display: 'grid',
                placeItems: 'center',
                bgcolor: COLORS.logoBg,
              }}
            >
              <HandymanOutlinedIcon sx={{ color: COLORS.logoText }} />
            </Box>

            {/* Brand Text - Hidden in compact mode */}
            {!compact ? (
              <Box>
                <Typography 
                  variant="h5" 
                  sx={{ fontWeight: 800, color: COLORS.textPrimary, lineHeight: 1.1 }}
                >
                  FixItPro
                </Typography>
                <Typography 
                  sx={{ color: COLORS.textMuted, fontSize: 14.5, mt: 0.2 }}
                >
                  Service Provider
                </Typography>
              </Box>
            ) : null}
          </Stack>

          {/* Collapse/Expand Button */}
          {!compact ? (
            <IconButton
              onClick={() => setDrawerMinimized(true)}
              sx={{ color: COLORS.textDark }}
              aria-label="Minimize drawer"
            >
              <ChevronLeftOutlinedIcon />
            </IconButton>
          ) : (
            <IconButton
              onClick={() => setDrawerMinimized(false)}
              sx={{ color: COLORS.textDark, position: 'absolute', right: 8 }}
              aria-label="Expand drawer"
            >
              <ChevronRightOutlinedIcon />
            </IconButton>
          )}
        </Stack>
      </Toolbar>

      {/* MAIN MENU SECTION */}
      <List sx={{ p: compact ? 1 : 1.6, pt: 2.2 }}>
        {menu.map((item) => {
          const active = locationPathname === item.path;
          return (
            <ListItemButton
              key={item.path}
              selected={active}
              onClick={() => {
                navigate(item.path);
                setMobileOpen(false);
              }}
              sx={{
                borderRadius: 2.5,
                mb: 0.8,
                px: compact ? 1.2 : 1.8,
                py: 1.4,
                justifyContent: compact ? 'center' : 'flex-start',
                color: active ? COLORS.primary : COLORS.textSecondary,
                transition: 'all 0.2s ease-in-out',
                
                // Icon styling
                '& .MuiListItemIcon-root': {
                  color: active ? COLORS.primary : COLORS.iconDefault,
                  minWidth: compact ? 0 : 42,
                },
                
                // Text styling
                '& .MuiListItemText-primary': {
                  fontWeight: active ? 700 : 600,
                  fontSize: 18.5,
                },
                
                // Selected state
                '&.Mui-selected': {
                  backgroundColor: COLORS.primaryLight,
                },
                '&.Mui-selected:hover': {
                  backgroundColor: COLORS.primaryLighter,
                },
                
                // Hover state
                '&:hover': {
                  backgroundColor: COLORS.hoverBg,
                },
              }}
            >
              <ListItemIcon>{item.icon}</ListItemIcon>
              {!compact ? <ListItemText primary={item.label} /> : null}
              
              {/* Active indicator dot */}
              {active && !compact ? (
                <Box
                  sx={{
                    width: 8,
                    height: 8,
                    borderRadius: '50%',
                    bgcolor: COLORS.primary,
                    boxShadow: `0 0 8px ${COLORS.primaryGlow}`,
                  }}
                />
              ) : null}
            </ListItemButton>
          );
        })}
      </List>
    </Box>

    {/* FOOTER MENU SECTION */}
    <Box sx={{ p: compact ? 1 : 1.6, borderTop: `1px solid ${COLORS.drawerBorder}` }}>
      <List sx={{ p: 0 }}>
        {footerMenu.map((item) => {
          const active = locationPathname === item.path;
          return (
            <ListItemButton
              key={item.path}
              selected={active}
              onClick={() => {
                navigate(item.path);
                setMobileOpen(false);
              }}
              sx={{
                borderRadius: 2.2,
                mb: 0.6,
                px: compact ? 1.2 : 1.8,
                py: 1.1,
                justifyContent: compact ? 'center' : 'flex-start',
                color: active ? COLORS.primary : COLORS.textSecondary,
                transition: 'all 0.2s ease-in-out',
                
                // Icon styling
                '& .MuiListItemIcon-root': {
                  color: active ? COLORS.primary : COLORS.iconFooter,
                  minWidth: compact ? 0 : 42,
                },
                
                // Text styling
                '& .MuiListItemText-primary': {
                  fontWeight: active ? 700 : 500,
                  fontSize: 18,
                },
                
                // Selected state
                '&.Mui-selected': {
                  backgroundColor: COLORS.primaryLight,
                },
                '&.Mui-selected:hover': {
                  backgroundColor: COLORS.primaryLighter,
                },
                
                // Hover state
                '&:hover': {
                  backgroundColor: COLORS.hoverBg,
                },
              }}
            >
              <ListItemIcon>{item.icon}</ListItemIcon>
              {!compact ? <ListItemText primary={item.label} /> : null}
            </ListItemButton>
          );
        })}
      </List>
    </Box>
  </Box>
);

// ============================================================================
// MAIN LAYOUT COMPONENT
// ============================================================================

export default function ProviderLayout() {
  // State management
  const [mobileOpen, setMobileOpen] = useState(false);
  const [drawerMinimized, setDrawerMinimized] = useState(false);
  const [notificationAnchor, setNotificationAnchor] = useState(null);
  const [notificationFilter, setNotificationFilter] = useState('all');
  
  // Hooks
  const navigate = useNavigate();
  const location = useLocation();
  
  // Assumed context providers (replace with your actual data sources)
  const provider = {
    name: 'John Doe',
    mobile: '9876543210',
    status: 'ACTIVE',
    profileImage: null,
  };
  
  const notifications = [];
  const unreadCount = 0;
  const loading = false;
  const latestNotification = null;

  // Computed values
  const openNotifications = Boolean(notificationAnchor);
  const profileImageUrl = provider?.profileImage || '';
  const desktopDrawerWidth = drawerMinimized ? miniDrawerWidth : drawerWidth;

  // Format date helper
  const formatDate = (value) => {
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
  };

  // ============================================================================
  // RENDER
  // ============================================================================

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: 'background.default' }}>
      <CssBaseline />

      {/* ======================== APP BAR / HEADER ======================== */}
      <AppBar
        position="fixed"
        sx={{
          width: { sm: `calc(100% - ${desktopDrawerWidth}px)` },
          ml: { sm: `${desktopDrawerWidth}px` },
          transition: (theme) =>
            theme.transitions.create(['width', 'margin'], {
              easing: theme.transitions.easing.sharp,
              duration: theme.transitions.duration.shorter,
            }),
          bgcolor: COLORS.headerBg,
          color: COLORS.headerText,
          boxShadow: 'none',
          borderBottom: `1px solid ${COLORS.headerBorder}`,
        }}
      >
        <Toolbar>
          {/* Mobile menu toggle */}
          <IconButton
            color="inherit"
            edge="start"
            onClick={() => setMobileOpen(!mobileOpen)}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>

          {/* Welcome text */}
          <Box sx={{ flexGrow: 1 }}>
            <Typography variant="h6" noWrap>
              Welcome, {provider?.name || provider?.mobile}
            </Typography>
          </Box>

          {/* Status chip */}
          <Chip
            label={`Status: ${provider?.status || 'INACTIVE'}`}
            color={provider?.status === 'ACTIVE' ? 'success' : 'warning'}
            sx={{ mr: 2 }}
          />

          {/* Notifications bell */}
          <IconButton
            color="inherit"
            onClick={(event) => setNotificationAnchor(event.currentTarget)}
            sx={{ mr: 1.2 }}
          >
            <Badge badgeContent={unreadCount} color="error" max={99}>
              <NotificationsNoneOutlinedIcon />
            </Badge>
          </IconButton>

          {/* Profile avatar */}
          <Avatar
            onClick={() => navigate('/app/profile')}
            sx={{ width: 34, height: 34, bgcolor: '#0ea5e9', mr: 1, fontSize: 14, cursor: 'pointer' }}
          >
            {profileImageUrl ? (
              <Box
                component="img"
                src={profileImageUrl}
                alt="Profile"
                sx={{ width: '100%', height: '100%', objectFit: 'cover' }}
              />
            ) : (
              (provider?.name || provider?.mobile || 'P').slice(0, 1).toUpperCase()
            )}
          </Avatar>

          {/* Logout button */}
          <Button color="inherit" onClick={() => navigate('/login')}>
            Logout
          </Button>

          {/* Notifications menu */}
          <Menu
            anchorEl={notificationAnchor}
            open={openNotifications}
            onClose={() => setNotificationAnchor(null)}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: 'right' }}
            PaperProps={{ sx: { width: 360, maxHeight: 460, borderRadius: 2 } }}
          >
            {/* Notification menu items here */}
            <Box sx={{ px: 1.8, py: 1.2 }}>
              <Typography sx={{ fontWeight: 700 }}>Notifications</Typography>
            </Box>
          </Menu>
        </Toolbar>
      </AppBar>

      {/* ======================== DRAWER SECTION ======================== */}
      <Box component="nav" sx={{ width: { sm: desktopDrawerWidth }, flexShrink: { sm: 0 } }}>
        {/* Mobile drawer (temporary) */}
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={() => setMobileOpen(false)}
          ModalProps={{ keepMounted: true }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { 
              boxSizing: 'border-box', 
              width: drawerWidth, 
              borderRight: 'none' 
            },
          }}
        >
          {drawerContent(false, location.pathname, navigate, setMobileOpen)}
        </Drawer>

        {/* Desktop drawer (permanent) */}
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: desktopDrawerWidth,
              borderRight: 'none',
              overflowX: 'hidden',
              transition: (theme) =>
                theme.transitions.create('width', {
                  easing: theme.transitions.easing.sharp,
                  duration: theme.transitions.duration.shorter,
                }),
            },
          }}
          open
        >
          {drawerContent(drawerMinimized, location.pathname, navigate, setMobileOpen)}
        </Drawer>
      </Box>

      {/* ======================== MAIN CONTENT ======================== */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${desktopDrawerWidth}px)` },
          transition: (theme) =>
            theme.transitions.create('width', {
              easing: theme.transitions.easing.sharp,
              duration: theme.transitions.duration.shorter,
            }),
        }}
      >
        <Toolbar />
        <Outlet /> {/* Route content renders here */}
      </Box>
    </Box>
  );
}

// ============================================================================
// COLOR CUSTOMIZATION GUIDE
// ============================================================================

/**
 * TO CUSTOMIZE COLORS:
 * 
 * 1. Primary Accent Color (currently Teal #12d3b5):
 *    - Change COLORS.primary = '#YOUR_HEX_CODE'
 *    - Update COLORS.primaryLight, primaryLighter, primaryGlow accordingly
 *    - Example: For Blue theme, use #0EA5E9 (cyan) or #3B82F6 (blue)
 * 
 * 2. Drawer Background:
 *    - Change COLORS.drawerBg gradient
 *    - Example: 'linear-gradient(180deg, #1e293b 0%, #0f172a 100%)' for darker
 * 
 * 3. Text Colors:
 *    - Change COLORS.textPrimary, textSecondary, etc.
 *    - Maintain contrast for accessibility (AA standard: 4.5:1)
 * 
 * 4. Logo Background:
 *    - Change COLORS.logoBg = '#YOUR_COLOR'
 * 
 * Usage example:
 *   const COLORS = {
 *     primary: '#3B82F6', // Blue
 *     drawerBg: 'linear-gradient(180deg, #1e3a8a 0%, #1e293b 100%)',
 *     // ... rest of colors
 *   };
 */

// ============================================================================
// RESPONSIVE BREAKPOINTS
// ============================================================================

/**
 * MUI Breakpoints used:
 * - xs: 0px (mobile)
 * - sm: 600px (tablet & up)
 * - md: 960px
 * - lg: 1280px
 * - xl: 1920px
 * 
 * Key Responsive Behaviors:
 * 1. Mobile (xs): Temporary drawer, hamburger menu visible
 * 2. Desktop (sm+): Permanent drawer, hamburger hidden
 * 3. Minimize/Expand: Available on both mobile & desktop
 */

// ============================================================================
// ANIMATION SPECIFICATIONS
// ============================================================================

/**
 * Transitions used:
 * - Drawer width: 225ms easing.sharp
 * - Menu items: 0.2s ease-in-out (custom CSS)
 * - All state colors: smooth gradient transitions
 * 
 * To adjust animation speed, modify transition duration in easing config
 */
