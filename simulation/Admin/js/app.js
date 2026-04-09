// ===== Main App Logic =====

// Initialize App
document.addEventListener('DOMContentLoaded', function() {
    initApp();
});

// Reusable confirm-delete modal (used by Users, Hydrograte, Announcements, etc.)
// Avoids browser confirm() for a consistent centered UX.
let __confirmDeleteOnConfirm = null;

// Reusable confirm-action modal (used for non-delete confirmations like Logout)
let __confirmActionOnConfirm = null;

function setupConfirmDeleteModal() {
    const modal = document.getElementById('confirm-delete-modal');
    if (!modal) return;

    const closeBtn = document.getElementById('close-confirm-delete-modal');
    const cancelBtn = document.getElementById('cancel-confirm-delete');
    const confirmBtn = document.getElementById('confirm-confirm-delete');

    const close = function() {
        modal.classList.remove('active');
        modal.setAttribute('aria-hidden', 'true');
        __confirmDeleteOnConfirm = null;
        if (confirmBtn) {
            confirmBtn.classList.remove('is-loading');
            confirmBtn.disabled = false;
        }
        if (cancelBtn) cancelBtn.disabled = false;
    };

    if (closeBtn) closeBtn.addEventListener('click', close);
    if (cancelBtn) cancelBtn.addEventListener('click', close);

    modal.addEventListener('click', function(event) {
        if (event.target === modal) close();
    });

    if (confirmBtn) {
        confirmBtn.addEventListener('click', async function() {
            if (typeof __confirmDeleteOnConfirm !== 'function') {
                close();
                return;
            }

            confirmBtn.disabled = true;
            confirmBtn.classList.add('is-loading');
            if (cancelBtn) cancelBtn.disabled = true;

            try {
                const result = __confirmDeleteOnConfirm();
                if (result && typeof result.then === 'function') {
                    await result;
                }
                close();
            } catch (err) {
                console.error('Confirm delete action failed:', err);
                close();
            }
        });
    }

    window.openConfirmDeleteModal = function(options) {
        const titleEl = document.getElementById('confirm-delete-title');
        const messageEl = document.getElementById('confirm-delete-message');
        const confirmBtnEl = document.getElementById('confirm-confirm-delete');

        const title = (options && options.title) ? String(options.title) : 'Confirm Delete';
        const message = (options && options.message) ? String(options.message) : 'This action cannot be undone.';
        const confirmText = (options && options.confirmText) ? String(options.confirmText) : 'Delete';
        const onConfirm = options && options.onConfirm;

        if (titleEl) titleEl.textContent = title;
        if (messageEl) messageEl.textContent = message;
        __confirmDeleteOnConfirm = (typeof onConfirm === 'function') ? onConfirm : null;

        if (confirmBtnEl) {
            confirmBtnEl.innerHTML = '<i data-lucide="trash-2"></i> ' + confirmText;
            confirmBtnEl.classList.remove('is-loading');
            confirmBtnEl.disabled = false;
        }

        modal.classList.add('active');
        modal.setAttribute('aria-hidden', 'false');
        if (window.lucide) window.lucide.createIcons();
    };
}

function setupConfirmActionModal() {
    const modal = document.getElementById('confirm-action-modal');
    if (!modal) return;

    const closeBtn = document.getElementById('close-confirm-action-modal');
    const cancelBtn = document.getElementById('cancel-confirm-action');
    const confirmBtn = document.getElementById('confirm-confirm-action');

    const close = function() {
        modal.classList.remove('active');
        modal.setAttribute('aria-hidden', 'true');
        __confirmActionOnConfirm = null;
        if (confirmBtn) {
            confirmBtn.classList.remove('is-loading');
            confirmBtn.disabled = false;
        }
        if (cancelBtn) cancelBtn.disabled = false;
    };

    if (closeBtn) closeBtn.addEventListener('click', close);
    if (cancelBtn) cancelBtn.addEventListener('click', close);

    modal.addEventListener('click', function(event) {
        if (event.target === modal) close();
    });

    if (confirmBtn) {
        confirmBtn.addEventListener('click', async function() {
            if (typeof __confirmActionOnConfirm !== 'function') {
                close();
                return;
            }

            confirmBtn.disabled = true;
            confirmBtn.classList.add('is-loading');
            if (cancelBtn) cancelBtn.disabled = true;

            try {
                const result = __confirmActionOnConfirm();
                if (result && typeof result.then === 'function') {
                    await result;
                }
                close();
            } catch (err) {
                console.error('Confirm action failed:', err);
                close();
            }
        });
    }

    window.openConfirmActionModal = function(options) {
        const titleEl = document.getElementById('confirm-action-title');
        const messageEl = document.getElementById('confirm-action-message');
        const confirmBtnEl = document.getElementById('confirm-confirm-action');

        const title = (options && options.title) ? String(options.title) : 'Confirm';
        const message = (options && options.message) ? String(options.message) : 'Are you sure you want to continue?';
        const confirmText = (options && options.confirmText) ? String(options.confirmText) : 'Confirm';
        const confirmIcon = (options && options.confirmIcon) ? String(options.confirmIcon) : 'check';
        const confirmVariant = (options && options.confirmVariant) ? String(options.confirmVariant) : 'primary';
        const onConfirm = options && options.onConfirm;

        if (titleEl) titleEl.textContent = title;
        if (messageEl) messageEl.textContent = message;
        __confirmActionOnConfirm = (typeof onConfirm === 'function') ? onConfirm : null;

        if (confirmBtnEl) {
            confirmBtnEl.classList.remove('is-loading');
            confirmBtnEl.disabled = false;

            confirmBtnEl.classList.remove('btn-primary', 'btn-secondary', 'btn-danger');
            if (confirmVariant === 'danger') confirmBtnEl.classList.add('btn-danger');
            else if (confirmVariant === 'secondary') confirmBtnEl.classList.add('btn-secondary');
            else confirmBtnEl.classList.add('btn-primary');

            confirmBtnEl.innerHTML = '<i data-lucide="' + confirmIcon + '"></i> ' + confirmText;
        }

        modal.classList.add('active');
        modal.setAttribute('aria-hidden', 'false');
        if (window.lucide) window.lucide.createIcons();
    };
}

function initApp() {
    // Setup tab navigation first so sidebar works even if other modules fail.
    setupTabNavigation();

    // Global reusable modal utilities
    setupConfirmDeleteModal();
    setupConfirmActionModal();

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

    // Admin logout
    const logoutBtn = document.getElementById('admin-logout-btn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', function() {
            if (typeof window.openConfirmActionModal !== 'function') {
                window.location.replace('login.html');
                return;
            }

            window.openConfirmActionModal({
                title: 'Confirm Logout',
                message: 'Are you sure you want to logout?',
                confirmText: 'Logout',
                confirmIcon: 'log-out',
                confirmVariant: 'primary',
                onConfirm: async function() {
                    try {
                        if (window.auth && typeof window.auth.signOut === 'function') {
                            await window.auth.signOut();
                        }
                    } catch (e) {
                        console.error('Logout failed:', e);
                    } finally {
                        window.location.replace('login.html');
                    }
                }
            });
        });
    }
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
        const waterLevelElem = document.getElementById('water-level');
        if (waterLevelElem) waterLevelElem.textContent = (Number(hydrograteData.waterLevel) || 0).toFixed(2) + 'm';

        const branchLabelEl = document.getElementById('water-branch-label');
        if (branchLabelEl) {
            const branch = (hydrograteData.branch || '').toString().trim();
            branchLabelEl.textContent = '(Branch: ' + (branch || '--') + ')';
        }
    }

    // Active alerts (prefer water-level smart alerts if available)
    const activeAlertsElem = document.getElementById('active-alerts');
    if (activeAlertsElem) {
        if (typeof window.__activeWaterAlertsCount === 'number') {
            activeAlertsElem.textContent = String(window.__activeWaterAlertsCount);
        } else if (typeof announcements !== 'undefined') {
            const activeAlerts = announcements.filter(a => a.type === 'Alert' || a.type === 'Warning' || a.type === 'Emergency').length;
            activeAlertsElem.textContent = String(activeAlerts);
        }
    }

    // Pending messages (announcements)
    if (typeof announcements !== 'undefined') {
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
