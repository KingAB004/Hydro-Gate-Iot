// ===== Main App Logic =====

// Initialize App
document.addEventListener('DOMContentLoaded', function() {
    initApp();
});

function initApp() {
    // Initialize all sections
    initUsersManagement();
    initHydrograteStatus();
    initAnnouncements();
    
    // Setup tab navigation
    setupTabNavigation();
    
    // Update stats
    updateStats();
    
    // Setup refresh button
    document.getElementById('refresh-btn').addEventListener('click', refreshAllData);
}

// Setup Tab Navigation
function setupTabNavigation() {
    const navButtons = document.querySelectorAll('.nav-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    navButtons.forEach(button => {
        button.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');

            // Remove active class from all buttons and contents
            navButtons.forEach(btn => btn.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('active'));

            // Add active class to clicked button and corresponding content
            this.classList.add('active');
            document.getElementById(tabName).classList.add('active');

            // Update page title
            const titles = {
                'overview': 'Dashboard Overview',
                'users': 'User Management',
                'hydrograte': 'Hydrograte Status & Model',
                'announcements': 'Announcements & Messages'
            };
            document.getElementById('page-title').textContent = titles[tabName];
        });
    });
}

// Update All Stats
function updateStats() {
    // Check if data is loaded
    if (typeof users === 'undefined' || typeof hydrograteData === 'undefined') {
        console.log('Waiting for data to load...');
        return;
    }

    // Users count
    const totalUsersElem = document.getElementById('total-users');
    if (totalUsersElem) totalUsersElem.textContent = users.length;

    // Water level
    if (hydrograteData && hydrograteData.waterLevel !== undefined) {
        const waterLevelPercent = (hydrograteData.waterLevel / hydrograteData.maxWaterLevel) * 100;
        const waterLevelElem = document.getElementById('water-level');
        if (waterLevelElem) waterLevelElem.textContent = Math.round(waterLevelPercent) + '%';
    }

    // Active alerts
    if (typeof announcements !== 'undefined') {
        const activeAlerts = announcements.filter(a => a.type === 'Alert' || a.type === 'Warning' || a.type === 'Emergency').length;
        const activeAlertsElem = document.getElementById('active-alerts');
        if (activeAlertsElem) activeAlertsElem.textContent = activeAlerts;

        // Pending messages
        const pendingMessages = announcements.filter(a => a.status === 'Scheduled').length;
        const pendingMessagesElem = document.getElementById('pending-messages');
        if (pendingMessagesElem) pendingMessagesElem.textContent = pendingMessages;
    }

    // Status health
    if (hydrograteData) {
        const isSystemHealthy = hydrograteData.status === 'Online' && users.length > 0;
        const healthBadge = document.getElementById('status-health');
        if (healthBadge) {
            healthBadge.textContent = isSystemHealthy ? 'Healthy' : 'Warning';
            healthBadge.className = isSystemHealthy ? 'badge-success' : 'badge-warning';
        }
    }
}

// Refresh All Data
function refreshAllData() {
    if (typeof refreshHydrograteData !== 'undefined') {
        refreshHydrograteData();
    }
    updateStats();

    // Visual feedback
    const btn = document.getElementById('refresh-btn');
    if (btn) {
        btn.textContent = '✓';
        setTimeout(() => {
            btn.textContent = '🔄';
        }, 1000);
    }
}

// Global error handler
window.addEventListener('error', function(event) {
    console.error('Global Error:', event.error);
});

// Utility: Format time
function formatTime(date) {
    return new Date(date).toLocaleTimeString();
}

// Utility: Format date
function formatDate(date) {
    return new Date(date).toLocaleDateString();
}

// Utility: Get time ago
function getTimeAgo(date) {
    const seconds = Math.floor((new Date() - new Date(date)) / 1000);
    
    if (seconds < 60) return seconds + 's ago';
    if (seconds < 3600) return Math.floor(seconds / 60) + 'm ago';
    if (seconds < 86400) return Math.floor(seconds / 3600) + 'h ago';
    return Math.floor(seconds / 86400) + 'd ago';
}

// Export functions for global access
window.updateStats = updateStats;
