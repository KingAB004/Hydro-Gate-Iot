// ===== Announcements & Messages (Firebase Integrated) =====

let announcements = [];
let hasShownAnnouncementPermissionWarning = false;
let hasShownAnnouncementInitWarning = false;

function getAnnouncementFilterState() {
    const search = (document.getElementById('announcement-search')?.value || '').trim().toLowerCase();
    const audience = (document.getElementById('announcement-audience-filter')?.value || '').trim();
    const status = (document.getElementById('announcement-status-filter')?.value || '').trim();
    return { search, audience, status };
}

function filterAnnouncements(list) {
    const { search, audience, status } = getAnnouncementFilterState();
    return (list || []).filter(a => {
        if (audience) {
            const roles = Array.isArray(a.audience) ? a.audience : [];
            if (!roles.includes(audience)) return false;
        }
        if (status) {
            if ((a.status || '') !== status) return false;
        }
        if (search) {
            const haystack = `${a.title || ''} ${a.message || ''} ${a.sender || ''}`.toLowerCase();
            if (!haystack.includes(search)) return false;
        }
        return true;
    });
}

function applyAnnouncementFilters() {
    renderAnnouncements(filterAnnouncements(announcements));
}

// Initialize Announcements
window.initAnnouncements = async function() {
    attachAnnouncementEventListeners();
    await fetchAnnouncements();
};

// Fetch Announcements from Firestore
async function fetchAnnouncements() {
    const firestoreDb = window.firestoreDb;
    if (!firestoreDb) {
        if (!hasShownAnnouncementInitWarning) {
            hasShownAnnouncementInitWarning = true;
            alert('Firestore is not initialized. Please reload the page.');
        }
        console.error('Firestore is not initialized (window.firestoreDb missing).');
        return;
    }
    try {
        const snapshot = await firestoreDb.collection('announcements').orderBy('timestamp', 'desc').get();
        announcements = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            announcements.push({
                id: doc.id,
                title: data.title || 'No Title',
                message: data.message || '',
                type: data.type || 'Info',
                audience: data.audience || [],
                timestamp: data.timestamp ? data.timestamp.toDate() : new Date(),
                status: data.status || 'Sent',
                sender: data.sender || 'Admin'
            });
        });
        applyAnnouncementFilters();
        
        // Try to update stats on overview if function exists
        if (typeof updateStats === 'function') {
            updateStats();
        }
    } catch (e) {
        console.error("Error fetching announcements:", e);
        handleAnnouncementPermissionError(e);
    }
}

function handleAnnouncementPermissionError(error) {
    if (!error || !error.code) return;
    const isPermissionError = error.code === 'permission-denied' || error.code === 'PERMISSION_DENIED';
    if (isPermissionError && !hasShownAnnouncementPermissionWarning) {
        hasShownAnnouncementPermissionWarning = true;
        alert('Firestore permission denied for announcements collection.');
    }
}

function attachAnnouncementEventListeners() {
    const newAnnouncementBtn = document.getElementById('new-announcement-btn');
    const announcementForm = document.getElementById('announcement-form');
    const cancelAnnouncementBtn = document.getElementById('cancel-announcement');
    const closeAnnouncementModalBtn = document.getElementById('close-announcement-modal');
    const announcementModal = document.getElementById('announcement-modal');
    const scheduleCheckbox = document.getElementById('schedule-announcement');
    const scheduleTimeInput = document.getElementById('schedule-time');

    const announcementSearch = document.getElementById('announcement-search');
    const announcementAudienceFilter = document.getElementById('announcement-audience-filter');
    const announcementStatusFilter = document.getElementById('announcement-status-filter');

    if (newAnnouncementBtn) newAnnouncementBtn.addEventListener('click', openAnnouncementModal);
    if (announcementForm) announcementForm.addEventListener('submit', handleAnnouncementSubmit);
    if (cancelAnnouncementBtn) cancelAnnouncementBtn.addEventListener('click', closeAnnouncementModal);
    if (closeAnnouncementModalBtn) closeAnnouncementModalBtn.addEventListener('click', closeAnnouncementModal);

    if (announcementModal) {
        announcementModal.addEventListener('click', function(event) {
            if (event.target === announcementModal) {
                closeAnnouncementModal();
            }
        });
    }
    
    if (scheduleCheckbox) {
        scheduleCheckbox.addEventListener('change', () => {
            if (scheduleTimeInput) {
                scheduleTimeInput.style.display = scheduleCheckbox.checked ? 'block' : 'none';
            }
        });
    }

    if (announcementSearch) announcementSearch.addEventListener('input', applyAnnouncementFilters);
    if (announcementAudienceFilter) announcementAudienceFilter.addEventListener('change', applyAnnouncementFilters);
    if (announcementStatusFilter) announcementStatusFilter.addEventListener('change', applyAnnouncementFilters);
}

function openAnnouncementModal() {
    const modal = document.getElementById('announcement-modal');
    if (!modal) return;
    modal.classList.add('active');

    if (window.lucide) window.lucide.createIcons();

    const form = document.getElementById('announcement-form');
    if (form) form.reset();
    const scheduleTimeInput = document.getElementById('schedule-time');
    if (scheduleTimeInput) scheduleTimeInput.style.display = 'none';
}

function closeAnnouncementModal() {
    const modal = document.getElementById('announcement-modal');
    if (!modal) return;
    modal.classList.remove('active');
}

async function handleAnnouncementSubmit(e) {
    e.preventDefault();

    const title = document.getElementById('announcement-title').value.trim();
    const message = document.getElementById('announcement-message').value.trim();
    const type = document.getElementById('announcement-type').value;
    const schedule = document.getElementById('schedule-announcement')?.checked;

    if (!title || !message) {
        alert('Title and message are required.');
        return;
    }
    
    // Get audience
    const audienceCheckboxes = document.querySelectorAll('.checkbox-stack input');
    const audience = [];
    audienceCheckboxes.forEach(checkbox => {
        if (checkbox.checked) {
            audience.push(checkbox.value);
        }
    });

    const newAnnouncementData = {
        title: title,
        message: message,
        type: type,
        audience: audience,
        timestamp: new Date(),  // Using standard JS Date which Firestore automatically converts to a Timestamp
        status: schedule ? 'Scheduled' : 'Sent',
        sender: 'Admin'
    };

    try {
        console.log("Submitting announcement: ", newAnnouncementData);
        const firestoreDb = window.firestoreDb;
        if (!firestoreDb) {
            alert('Firestore is not initialized. Please reload the page.');
            console.error('Firestore is not initialized (window.firestoreDb missing).');
            return;
        }
        const docRef = await firestoreDb.collection('announcements').add(newAnnouncementData);
        console.log("Announcement added with ID: ", docRef.id);

        if (typeof window.writeAuditLog === 'function') {
            await window.writeAuditLog(
                'admin_announcement_create',
                'safe',
                'Created announcement: ' + title + ' (' + type + ')'
            );
        }
        
        alert(`Announcement ${schedule ? 'scheduled' : 'sent'} successfully!`);
        closeAnnouncementModal();
        await fetchAnnouncements(); // Refresh list automatically
    } catch (error) {
        console.error("Error adding announcement: ", error);
        handleAnnouncementPermissionError(error);
        alert("Failed to send announcement: " + (error.message || 'Unknown error'));
    }
}

function renderAnnouncements(list) {
    const container = document.getElementById('announcements-list');
    if (!container) return;
    
    container.innerHTML = '';

    const items = Array.isArray(list) ? list : announcements;

    if (items.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i data-lucide="message-square-off"></i>
                <p>No communications match your filters.</p>
            </div>
        `;
        if (window.lucide) window.lucide.createIcons();
        return;
    }

    items.forEach(announcement => {
        const card = document.createElement('div');
        card.className = 'announcement-card fade-in ' + announcement.type.toLowerCase();
        
        const dateStr = announcement.timestamp instanceof Date 
            ? announcement.timestamp.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
            : new Date(announcement.timestamp).toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });

        const isToday = new Date().toDateString() === (announcement.timestamp instanceof Date ? announcement.timestamp.toDateString() : new Date(announcement.timestamp).toDateString());
        const timeDisplay = isToday ? 'Today, ' + dateStr.split(', ')[1] : dateStr;

        const getAudienceIcon = function(role) {
            if (role === 'Admin') return 'shield-check';
            if (role === 'LGU') return 'landmark';
            if (role === 'Homeowner') return 'home';
            return 'users';
        };

        const audienceTags = (announcement.audience || []).map(function(role) {
            const safeRole = (role || '').toString();
            const label = safeRole.toUpperCase();
            const icon = getAudienceIcon(safeRole);
            return `
                <span class="audience-chip" data-role="${safeRole}">
                    <i data-lucide="${icon}" class="pill-icon"></i>
                    <span class="pill-text">${label}</span>
                </span>
            `;
        }).join('');

        card.innerHTML = `
            <div class="announcement-status-line"></div>
            <div class="announcement-header">
                <div class="header-main">
                    <h4 class="announcement-title">${announcement.title}</h4>
                    <div class="announcement-meta">
                        <span class="meta-sender">${announcement.sender}</span>
                        <div class="meta-dot"></div>
                        <span class="meta-time">${timeDisplay}</span>
                    </div>
                </div>
                <div class="announcement-badges">
                    <span class="badge ${announcement.status === 'Sent' ? 'badge-success' : 'badge-warning'}">${announcement.status}</span>
                </div>
            </div>
            <p class="announcement-message">${announcement.message}</p>
            <div class="announcement-footer">
                <div class="audience-list">
                    ${audienceTags}
                </div>
                <div class="announcement-actions">
                    <button class="btn btn-ghost" onclick="alert('Feature coming soon')">
                        <i data-lucide="edit-3"></i>
                    </button>
                    <button class="btn btn-ghost btn-ghost-danger" onclick="window.deleteAnnouncement('${announcement.id}', '${announcement.title.replace(/'/g, "\\'")}')">
                        <i data-lucide="trash-2"></i>
                    </button>
                </div>
            </div>
        `;
        container.appendChild(card);
    });

    if (window.lucide) window.lucide.createIcons();
}

window.deleteAnnouncement = async function(id, title) {
    if (!confirm('Delete this announcement? This action cannot be undone.')) {
        return;
    }

    const firestoreDb = window.firestoreDb;
    if (!firestoreDb) {
        alert('Firestore is not initialized. Please reload the page.');
        return;
    }

    try {
        await firestoreDb.collection('announcements').doc(id).delete();
        if (typeof window.writeAuditLog === 'function') {
            await window.writeAuditLog(
                'admin_announcement_delete',
                'warning',
                'Deleted announcement: ' + title
            );
        }
        await fetchAnnouncements();
    } catch (error) {
        console.error('Error deleting announcement:', error);
        handleAnnouncementPermissionError(error);
        alert('Failed to delete announcement: ' + (error.message || 'Unknown error'));
    }
};
