// ===== Audit Logs (Firebase Integrated) =====

let auditLogs = [];
let filteredAuditLogs = [];
let hasShownAuditPermissionWarning = false;

window.initAuditLogs = async function() {
    attachAuditLogListeners();
    await fetchAuditLogs();
    subscribeAuditLogsRealtime();
};

function attachAuditLogListeners() {
    const searchInput = document.getElementById('audit-log-search');
    const severityFilter = document.getElementById('audit-log-severity');
    const refreshBtn = document.getElementById('refresh-audit-logs');

    if (searchInput) searchInput.addEventListener('input', filterAuditLogs);
    if (severityFilter) severityFilter.addEventListener('change', filterAuditLogs);
    if (refreshBtn) refreshBtn.addEventListener('click', fetchAuditLogs);
}

async function fetchAuditLogs() {
    const db = window.db;
    if (!db) {
        console.error('Realtime Database is not initialized.');
        return;
    }

    try {
        const snapshot = await db
            .ref('audit_logs')
            .orderByChild('timestamp')
            .limitToLast(200)
            .once('value');
        applyAuditSnapshot(snapshot);
    } catch (e) {
        console.error('Error fetching audit logs:', e);
        handleAuditPermissionError(e);
    }
}

function subscribeAuditLogsRealtime() {
    const db = window.db;
    if (!db) return;

    db.ref('audit_logs')
        .orderByChild('timestamp')
        .limitToLast(200)
        .on('value', function(snapshot) {
            applyAuditSnapshot(snapshot);
        }, function(error) {
            console.error('Realtime audit logs listener failed:', error);
            handleAuditPermissionError(error);
        });
}

function applyAuditSnapshot(snapshot) {
    auditLogs = [];
    const data = snapshot.val() || {};
    Object.keys(data).forEach(function(key) {
        auditLogs.push(normalizeAuditDoc(key, data[key] || {}));
    });
    auditLogs.sort(function(a, b) {
        const at = a.timestamp ? a.timestamp.getTime() : 0;
        const bt = b.timestamp ? b.timestamp.getTime() : 0;
        return bt - at;
    });
    filteredAuditLogs = [...auditLogs];
    renderAuditLogs();
}

function normalizeAuditDoc(id, data) {
    return {
        id: id,
        action: (data.action || 'unknown').toString(),
        severity: (data.severity || 'safe').toString().toLowerCase(),
        email: (data.email || 'Unknown').toString(),
        role: (data.role || 'Unknown').toString(),
        description: (data.description || '').toString(),
        timestamp: normalizeTimestamp(data.timestamp)
    };
}

function normalizeTimestamp(timestamp) {
    if (!timestamp) return null;
    if (timestamp instanceof Date) return timestamp;
    if (typeof timestamp === 'number') return new Date(timestamp);
    return new Date(timestamp);
}

function renderAuditLogs() {
    const tbody = document.getElementById('audit-logs-tbody');
    if (!tbody) return;

    tbody.innerHTML = '';

    if (filteredAuditLogs.length === 0) {
        const row = document.createElement('tr');
        row.innerHTML = '<td class="empty-row" colspan="6">No audit logs found.</td>';
        tbody.appendChild(row);
        return;
    }

    filteredAuditLogs.forEach(function(log) {
        const row = document.createElement('tr');
        const timeText = log.timestamp ? log.timestamp.toLocaleString() : 'Unknown';
        const severityBadge = getSeverityBadge(log.severity);
        const actionText = log.action.replace(/_/g, ' ');

        row.innerHTML = `
            <td>${timeText}</td>
            <td>${actionText}</td>
            <td><span class="badge ${severityBadge}">${log.severity.toUpperCase()}</span></td>
            <td>${log.email}</td>
            <td>${log.role}</td>
            <td>${log.description}</td>
        `;
        tbody.appendChild(row);
    });
}

function getSeverityBadge(severity) {
    if (severity === 'danger') return 'badge-danger';
    if (severity === 'warning') return 'badge-warning';
    return 'badge-success';
}

function filterAuditLogs() {
    const searchValue = (document.getElementById('audit-log-search')?.value || '').toLowerCase();
    const severityValue = (document.getElementById('audit-log-severity')?.value || '').toLowerCase();

    filteredAuditLogs = auditLogs.filter(function(log) {
        const matchesSearch =
            log.action.toLowerCase().includes(searchValue) ||
            log.email.toLowerCase().includes(searchValue) ||
            log.role.toLowerCase().includes(searchValue) ||
            log.description.toLowerCase().includes(searchValue);

        const matchesSeverity = !severityValue || log.severity === severityValue;
        return matchesSearch && matchesSeverity;
    });

    renderAuditLogs();
}

function handleAuditPermissionError(error) {
    if (!error || !error.code) return;
    const isPermissionError = error.code === 'permission-denied' || error.code === 'PERMISSION_DENIED';
    if (isPermissionError && !hasShownAuditPermissionWarning) {
        hasShownAuditPermissionWarning = true;
        alert('Realtime Database permission denied for /audit_logs. Check RTDB rules/auth.');
    }
}
