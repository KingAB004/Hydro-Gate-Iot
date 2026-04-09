// ===== Main App Logic =====

// Initialize App
document.addEventListener('DOMContentLoaded', function() {
    initApp();
});

function initApp() {
    // Setup tab navigation first so sidebar works even if other modules fail.
    setupTabNavigation();

    const safeCall = function(label, fn) {
        try {
            if (typeof fn !== 'function') return;
            const result = fn();
            if (result && typeof result.then === 'function') {
                result.catch(function(err) {
                    console.error(label + ' failed:', err);
                });
            }
        } catch (err) {
            console.error(label + ' failed:', err);
        }
    };

    // Initialize all sections (guarded so one error doesn't break everything)
    safeCall('initAdminProfile', (typeof initAdminProfile === 'function' ? initAdminProfile : null));
    safeCall('initUsersManagement', window.initUsersManagement || (typeof initUsersManagement === 'function' ? initUsersManagement : null));
    safeCall('initHydrograteStatus', (typeof initHydrograteStatus === 'function' ? initHydrograteStatus : null));
    safeCall('initAnnouncements', (typeof initAnnouncements === 'function' ? initAnnouncements : null));
    safeCall('initAuditLogs', (typeof initAuditLogs === 'function' ? initAuditLogs : null));
    safeCall('initStatistics', (typeof initStatistics === 'function' ? initStatistics : null));
    safeCall('setupAdminAuditLogging', (typeof setupAdminAuditLogging === 'function' ? setupAdminAuditLogging : null));

    safeCall('updateStats', (typeof updateStats === 'function' ? updateStats : null));

    // Setup refresh button
    const refreshBtn = document.getElementById('refresh-btn');
    if (refreshBtn) refreshBtn.addEventListener('click', refreshAllData);
}

function initAdminProfile() {
    const nameEl = document.getElementById('admin-name');
    const roleEl = document.getElementById('admin-role');

    const auth = window.auth;
    if (!auth) return;

    auth.onAuthStateChanged(function(user) {
        if (!user) return;

        const displayName = (user.displayName || '').toString().trim();
        const email = (user.email || '').toString().trim();
        if (nameEl) nameEl.textContent = displayName || email || 'Admin User';
        if (roleEl) roleEl.style.display = '';
    });
}

function setupAdminAuditLogging() {
    const auth = window.auth;
    if (!auth) return;

    let lastAuthUid = null;

    auth.onAuthStateChanged(function(user) {
        const currentUid = user ? user.uid : null;
        if (currentUid && currentUid !== lastAuthUid) {
            writeAuditLog('admin_login', 'safe', 'Admin signed in', user);
        }
        if (!currentUid && lastAuthUid) {
            writeAuditLog('admin_logout', 'safe', 'Admin signed out', { uid: lastAuthUid });
        }
        lastAuthUid = currentUid;
    });
}

async function writeAuditLog(action, severity, description, userOverride) {
    const db = window.db;
    if (!db) return;

    const user = userOverride || window.auth?.currentUser;
    const email = user?.email || 'Unknown';
    const userId = user?.uid || '';

    try {
        await db.ref('audit_logs').push().set({
            action: action,
            severity: severity,
            description: description || '',
            email: email,
            role: 'Admin',
            userId: userId,
            timestamp: Date.now()
        });
    } catch (e) {
        console.error('Audit log write failed:', e);
    }
}

window.writeAuditLog = writeAuditLog;

// Setup Tab Navigation
function setupTabNavigation() {
    const navButtons = document.querySelectorAll('.nav-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    navButtons.forEach(button => {
        button.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');

            if (!tabName) return;
            const targetTab = document.getElementById(tabName);
            if (!targetTab) {
                console.warn('Tab content not found for:', tabName);
                return;
            }

            // Remove active class from all buttons and contents
            navButtons.forEach(btn => btn.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('active'));

            // Add active class to clicked button and corresponding content
            this.classList.add('active');
            targetTab.classList.add('active');

            // Update page title
            const titles = {
                'overview': 'Dashboard Overview',
                'users': 'User Management',
                'hydrograte': 'Hydrograte Status & Model',
                'announcements': 'Communications',
                'audit-logs': 'Audit Logs',
                'statistics': 'System Statistics'
            };
            const pageTitle = document.getElementById('page-title');
            if (pageTitle) pageTitle.textContent = titles[tabName] || 'Dashboard';
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
    const btn = document.getElementById('refresh-btn');
    if (btn) {
        btn.disabled = true;
        btn.classList.add('is-loading');
    }

    if (typeof refreshHydrograteData !== 'undefined') {
        refreshHydrograteData();
    }
    updateStats();

    // Visual feedback (keep icon consistent)
    window.setTimeout(function() {
        if (!btn) return;
        btn.classList.remove('is-loading');
        btn.disabled = false;
    }, 900);
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
