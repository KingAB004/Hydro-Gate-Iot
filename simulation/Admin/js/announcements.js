// ===== Announcements & Messages (Firebase Integrated) =====

let announcements = [];

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

    const title = document.getElementById('announcement-title').value;
    const message = document.getElementById('announcement-message').value;
    const type = document.getElementById('announcement-type').value;
    const schedule = document.getElementById('schedule-announcement')?.checked;
    
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
        
        alert(`Announcement ${schedule ? 'scheduled' : 'sent'} successfully!`);
        toggleAnnouncementForm();
        await fetchAnnouncements(); // Refresh list automatically
    } catch (error) {
        console.error("Error adding announcement: ", error);
        alert("Failed to send announcement.");
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
        `;
        container.appendChild(card);
    });
}
