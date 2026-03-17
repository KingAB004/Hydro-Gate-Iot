// ===== Announcements & Messages (Firebase Integrated) =====

let announcements = [];
let hasShownAnnouncementPermissionWarning = false;

// Initialize Announcements
window.initAnnouncements = async function() {
    attachAnnouncementEventListeners();
    await fetchAnnouncements();
};

// Fetch Announcements from Firestore
async function fetchAnnouncements() {
    const firestoreDb = window.firestoreDb;
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
        renderAnnouncements();
        
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
    const scheduleCheckbox = document.getElementById('schedule-announcement');
    const scheduleTimeInput = document.getElementById('schedule-time');

    if (newAnnouncementBtn) newAnnouncementBtn.addEventListener('click', toggleAnnouncementForm);
    if (announcementForm) announcementForm.addEventListener('submit', handleAnnouncementSubmit);
    if (cancelAnnouncementBtn) cancelAnnouncementBtn.addEventListener('click', toggleAnnouncementForm);
    
    if (scheduleCheckbox) {
        scheduleCheckbox.addEventListener('change', () => {
            if (scheduleTimeInput) {
                scheduleTimeInput.style.display = scheduleCheckbox.checked ? 'block' : 'none';
            }
        });
    }
}

function toggleAnnouncementForm() {
    const formContainer = document.getElementById('announcement-form-container');
    if (formContainer) {
        formContainer.style.display = formContainer.style.display === 'none' ? 'block' : 'none';
        if (formContainer.style.display === 'block') {
            document.getElementById('announcement-form').reset();
            const scheduleTimeInput = document.getElementById('schedule-time');
            if (scheduleTimeInput) scheduleTimeInput.style.display = 'none';
        }
    }
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
    const audienceCheckboxes = document.querySelectorAll('#announcement-form .checkbox-group input');
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
        if (!firebase.firestore.FieldValue) {
            console.error("Firebase FieldValue is missing!");
        }
        
        const firestoreDb = window.firestoreDb;
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
        toggleAnnouncementForm();
        await fetchAnnouncements(); // Refresh list automatically
    } catch (error) {
        console.error("Error adding announcement: ", error);
        handleAnnouncementPermissionError(error);
        alert("Failed to send announcement: " + (error.message || 'Unknown error'));
    }
}

function renderAnnouncements() {
    const container = document.getElementById('announcements-list');
    if (!container) return;
    
    container.innerHTML = '';

    if (announcements.length === 0) {
        container.innerHTML = '<p>No announcements yet.</p>';
        return;
    }

    announcements.forEach(announcement => {
        const card = document.createElement('div');
        card.className = 'card announcement-card';
        
        let typeClass = '';
        switch(announcement.type.toLowerCase()) {
            case 'emergency': 
            case 'danger': typeClass = 'badge-danger'; break;
            case 'warning': typeClass = 'badge-warning'; break;
            case 'info': typeClass = 'badge-success'; break;
            default: typeClass = 'badge-success';
        }

        const dateStr = announcement.timestamp instanceof Date 
            ? announcement.timestamp.toLocaleString() 
            : new Date(announcement.timestamp).toLocaleString();

        const badgeHtml = announcement.status === 'Sent' ? '<span class="status-badge success">Sent</span>' : '<span class="status-badge warning">Scheduled</span>';

        let tagsHtml = '';
        announcement.audience.forEach(a => {
            tagsHtml += `<span class="tag">${a}</span>`;
        });

        card.innerHTML = `
            <div class="announcement-header">
                <div style="display: flex; align-items: center; gap: 10px;">
                    <h4>${announcement.title}</h4>
                    <span class="${typeClass}">${announcement.type}</span>
                </div>
                ${badgeHtml}
            </div>
            <p class="announcement-message">${announcement.message}</p>
            <div class="announcement-footer">
                <div class="audience-tags">
                    ${tagsHtml}
                </div>
                <div class="announcement-meta">
                    <span>Sent by: ${announcement.sender}</span>
                    <span>${dateStr}</span>
                </div>
            </div>
            <div class="announcement-actions">
                <button class="btn-delete-announcement" onclick="window.deleteAnnouncement('${announcement.id}', '${announcement.title.replace(/'/g, "\\'")}')">Delete</button>
            </div>
        `;
        container.appendChild(card);
    });
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
