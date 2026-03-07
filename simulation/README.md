# AFWMS Dashboard System

## Overview

This folder contains HTML/CSS/JavaScript dashboards for the Advanced Flood Warning & Water Management System (AFWMS). The project includes comprehensive admin and LGU (Local Government Unit) dashboards for managing water resources, user accounts, and emergency communications.

## 📁 Folder Structure

```
simulation/
├── dashboard-hub.html          # Main entry point with dashboard selection
├── Admin/
│   ├── dashboard.html          # Admin dashboard main page
│   ├── css/
│   │   └── styles.css          # Global styling for all dashboards
│   └── js/
│       ├── app.js              # Main app logic and tab navigation
│       ├── users.js            # User management functionality
│       ├── hydrograte.js       # Water level monitoring
│       └── announcements.js   # Announcement management
└── lgu/
    └── dashboard.html          # LGU dashboard main page
```

## 🚀 Getting Started

1. **Open the Dashboard Hub**: Open `dashboard-hub.html` in a web browser
2. **Select Your Role**:
   - Click "Admin Dashboard" for full system management
   - Click "LGU Dashboard" for municipal-level management

## 📊 Features

### Admin Dashboard Features

#### 1. **User Management** 👥
- **CRUD Operations**: Create, Read, Update, Delete user accounts
- **Role-Based Access**: Assign roles (Admin, LGU, Homeowner)
- **User Filtering**: Search by name, email, role, or status
- **Account Status**: Activate/Deactivate user accounts
- **User List**: View all users with joining date and email

#### 2. **Hydrograte Status & Model** 💧
- **Multiple Device Management**: Add, edit, and delete hydrograte devices
- **Device List View**: Overview cards showing all registered devices
- **Real-Time Monitoring**: Current water level with percentage gauge
- **Device Status**: Online/Offline status and response time
- **Model Information**: Device specifications, firmware version, location
- **Maintenance Schedule**: Calibration history and next due date
- **Device Control**: 
  - Calibrate device
  - Restart device
  - View error logs
  - Add new devices with detailed specifications
- **Error Logs**: Track system warnings and errors with timestamps
- **Device Details**: Name, location, serial number, installation date, max water level, sensors

#### 3. **Announcements & Messages** 📢
- **Create Announcements**: Send system-wide messages
- **Message Types**: 
  - Information
  - Alert
  - Warning
  - Emergency
- **Target Audience**: Select recipient roles (Admin, LGU, Homeowners)
- **Scheduling**: Schedule announcements for later
- **Message History**: View all sent messages with status

### LGU Dashboard Features

#### 1. **Water Level Monitoring** 💧
- **Current Status**: Real-time water level gauge with safe thresholds
- **Level Assessment**: Status (Safe, Warning, Critical)
- **Trend Analysis**: Stable/Rising/Falling trends
- **Device Information**: Last update time and response status
- **Recommended Actions**: Context-aware safety recommendations
- **24-Hour History**: Water level trends and patterns

#### 2. **Resident Management** 👥
- **View Residents**: List of registered homeowners
- **Search Functionality**: Find residents by name
- **Area Filtering**: Filter by district/area
- **Status Tracking**: Active/Inactive status
- **Contact Information**: Email and registration date

#### 3. **Messages & Announcements** 📢
- **Send Messages**: Broadcast messages to residents
- **Message Types**: Advisory, Warning, Emergency
- **Priority Levels**: Normal, High, Urgent
- **Message History**: View sent messages
- **Delivery Status**: Track delivery status

## 💻 Technical Stackets on refresh)
- **Styling**: CSS Grid, Flexbox, CSS Variables
- **Typography**: Poppins font family (Google Fonts)
- **Design**: Minimalistic black & white with accent color
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Architecture**: Single Page Application (SPA)
- **Data Storage**: In-memory (sample data ressets on refresh)
- **Styling**: CSS Grid, Flexbox, CSS Variables
- **Responsiveness**: Mobile-first responsive design

## 🎨 UI Features

- **Minimalistic Design**: Clean, modern interface using Poppins font
- **Black & White Color Scheme**: Professional monochrome palette with accent colors
- **Real-Time Statistics**: KPI cards for key metrics
- **Interactive Tables**: Sortable, searchable user lists
- **Charts & Gauges**: Water level visualization with circular gauge
- **Modal Forms**: Create/Edit users, hydrograte devices, and announcements
- **Status Badges**: Color-coded status indicators
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Multiple Device Management**: Add, edit, and monitor multiple hydrograte devices

## 📝 Sample Data

The dashboards come pre-populated with sample data:

### Users
- john_admin (Admin)
- maria_lgu (LGU)
- home_user1 (Homeowner)
- home_user2 (Homeowner)
- lgu_officer (LGU)

### Hydrograte Status
- Current water level: 65% (0.65m / 1.5m)
- Status: Online
- Two pre-configured devices with different locations

### Hydrograte Devices
1. **Main Station - Downtown**
   - Location: Downtown Area, Sector A
   - Model: Hydrograte-Pro-X1
   - Serial: HGP-2024-001
   - Sensors: 3
   - Max Water Level: 1.5m

2. **Residential Zone Monitor**
   - Location: Residential Area, Zone B
   - Model: Hydrograte-Lite-V2
   - Serial: HGP-2024-002
   - Sensors: 2
   - Max Water Level: 1.2m
- Model: Hydrograte-Pro-X1
- Firmware: v2.4.1

### Announcements
- High water alerts
- System maintenance notices
- Flood warnings
- Temperature anomalies

## 🔧 Key Functions

### User Management (`js/users.js`)
```javascript
openAddUserModal()      // Open user creation form
editUser(id)            // Edit existing user
deleteUser(id)          // Delete user
filterUsers()           // Filter by name, role, status
renderUsersTable()      // Display users in table
```

### Hydrograte MsList()     // Display all devices
selectHydrograte(id)        // Select device for detailed view
renderHydrograteStatus()    // Update water level display
refreshHydrograteData()     // Fetch latest data
calibrateDevice()           // Initiate calibration
restartDevice()             // Restart device
openAddHydrograteM (Minimalistic Black & White)

- **Primary**: #000000 (Black)
- **Secondary**: #333333 (Dark Gray)
- **Success**: #00C853 (Green)
- **Warning**: #FFB300 (Amber)
- **Danger**: #FF5252 (Red)
- **Background**: #FAFAFA (Off White)
- **Border**: #E0E0E0 (Light Gray)
- **Text Primary**: #1A1A1A (Near Black)
- **Text Secondary**: #757575 (Medium Gray)
### Announcements (`js/announcements.js`)
```javascript
toggleAnnouncementForm()   // Show/hide form
handleAnnouncementSubmit() // Create new announcement
editAnnouncement(id)       // Edit existing announcement
deleteAnnouncement(id)     // Delete announcement
```

## 📱 Responsive Breakpoints

- **Desktop**: 1024px and above
- **Tablet**: 768px - 1023px
- **Mobile**: Below 768px

## 🎯 Color Scheme

- **Primary**: #2563eb (Blue)
- **Success**: #10b981 (Green)
- **Warning**: #f59e0b (Amber)
- **Danger**: #ef4444 (Red)
- **Dark Background**: #111827
- **Light Background**: #f9fafb

## 🔐 Security Notes

**Important**: This is a simulation dashboard for demonstration purposes only. For production use:

1. Implement proper authentication (OAuth, JWT)
2. Use HTTPS for all communications
3. Implement proper authorization checks
4. Encrypt sensitive data
5. Use a backend database instead of in-memory storage
6. Implement proper input validation and sanitization
7. Add rate limiting and DDoS protection
8. Use secure session management

## 📚 File Descriptions

### HTML Files
- **dashboard-hub.html**: Landing page with dashboard selection
- **Admin/dashboard.html**: Admin interface with all features
- **lgu/dashboard.html**: LGU-specific interface

### CSS Files
- **styles.css**: Global styling, layout, and responsive design

### JavaScript Files
- **app.js**: Main application logic and tab navigation
- **users.js**: User management functionality (CRUD)
- **hydrograte.js**: Water level and device monitoring
- **announcements.js**: Message and announcement system

## 🚀 Enhancements for Production

### Suggested Features to Add
1. **Real-time Data Integration**: Connect to Firebase or backend API
2. **Analytics Dashboard**: Charts for historical data analysis
3. **Advanced Filtering**: Multi-criteria search and filtering
4. **User Roles & Permissions**: Granular access control
5. **Audit Logs**: Track all user actions
6. **Notifications**: Real-time alerts and push notifications
7. **Export Reports**: PDF/CSV export functionality
8. **Dark Mode**: Theme switching
9. **Localization**: Multi-language support
10. **Mobile App**: Native mobile applications

### Backend Integration
- Replace sample data with API calls to backend
- Implement user authentication
- Add database connectivity
- Set up real-time data synchronization
- Implement WebSocket for live updates

## 📞 Support

For questions or issues with the dashboard:
1. Check the browser console for errors
2. Verify all files are in correct folders
3. Ensure JavaScript is enabled
4. Try clearing browser cache

## 📄 License

This is part of the AFWMS project. All rights reserved.

---

**Last Updated**: March 2026

**Status**: Simulation/Prototype - Ready for UI/UX Testing
