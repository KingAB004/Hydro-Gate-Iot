// ===== Announcements & Messages =====
let announcements = [
    {
        id: 1,
        title: 'High Water Alert',
        message: 'Water level has exceeded 70%. Residents in flood-prone areas are advised to take precautions.',
        type: 'Alert',
        audience: ['Admin', 'LGU', 'Homeowner'],
        timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toLocaleString(),
        status: 'Sent'
    },
    {
        id: 2,
        title: 'System Maintenance Scheduled',
        message: 'Scheduled maintenance will occur on March 10, 2026 from 2:00 AM to 4:00 AM. System will be temporarily unavailable.',
        type: 'Info',
        audience: ['Admin', 'LGU'],
        timestamp: new Date(Date.now() - 5 * 60 * 60 * 1000).toLocaleString(),
        status: 'Sent'
    },
    {
        id: 3,
        title: 'Flood Warning - URGENT',
        message: 'EMERGENCY ALERT: Severe flooding expected in the next 2-3 hours. Evacuate areas as instructed by local authorities.',
        type: 'Emergency',
        audience: ['Admin', 'LGU', 'Homeowner'],
        timestamp: new Date(Date.now() - 1 * 60 * 60 * 1000).toLocaleString(),
        status: 'Sent'
    },
    {
        id: 4,
        title: 'Temperature Warning',
        message: 'Unusually high water temperature detected. This may indicate different water sources or system anomalies.',
        type: 'Warning',
        audience: ['Admin', 'LGU'],
        timestamp: new Date(Date.now() - 30 * 60 * 1000).toLocaleString(),
        status: 'Sent'
    }
];

let nextAnnouncementId = 5;

// Init Announcements
function initAnnouncements() {
    renderAnnouncements();
    attachAnnouncementEventListeners();
}

// Attach event listeners
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

// Toggle Announcement Form
function toggleAnnouncementForm() {
    const formContainer = document.getElementById('announcement-form-container');
    formContainer.style.display = formContainer.style.display === 'none' ? 'block' : 'none';

    if (formContainer.style.display === 'block') {
        document.getElementById('announcement-form').reset();
    }
}

// Handle Announcement Submit
function handleAnnouncementSubmit(e) {
    e.preventDefault();

    const title = document.getElementById('announcement-title').value;
    const message = document.getElementById('announcement-message').value;
    const type = document.getElementById('announcement-type').value;
    const schedule = document.getElementById('schedule-announcement').checked;
    const scheduleTime = document.getElementById('schedule-time').value;

    // Get audience
    const audienceCheckboxes = document.querySelectorAll('#announcement-form .checkbox-group input');
    const audience = [];
    audienceCheckboxes.forEach(checkbox => {
        if (checkbox.checked) {
            audience.push(checkbox.value);
        }
    });

    // Create announcement
    const newAnnouncement = {
        id: nextAnnouncementId++,
        title,
        message,
        type,
        audience,
        timestamp: schedule ? new Date(scheduleTime).toLocaleString() : new Date().toLocaleString(),
        status: schedule ? 'Scheduled' : 'Sent'
    };

    announcements.unshift(newAnnouncement);

    // Clear form and hide
    toggleAnnouncementForm();
    renderAnnouncements();
    updateStats();

    alert(`Announcement ${schedule ? 'scheduled' : 'sent'} successfully!`);
}

// Render Announcements
function renderAnnouncements() {
    const container = document.getElementById('announcements-list');
    container.innerHTML = '';

    if (announcements.length === 0) {
        container.innerHTML = '<p>No announcements yet.</p>';
        return;
    }

    announcements.forEach(announcement => {
        const card = document.createElement('div');
        card.className = `announcement-card ${announcement.type.toLowerCase()}`;
        
        const typeColors = {
            'Info': 'badge-info info',
            'Alert': 'badge-info alert',
            'Warning': 'badge-info warning',
            'Emergency': 'badge-info emergency'
        };

        card.innerHTML = `
            <div class="announcement-header">
                <div>
                    <h4 class="announcement-title">${announcement.title}</h4>
                    <div class="announcement-meta">
                        <span class="badge-info ${typeColors[announcement.type]}"> ${announcement.type}</span>
                        <span class="badge-info">${announcement.status}</span>
                    </div>
                </div>
            </div>
            <p class="announcement-message">${announcement.message}</p>
            <div class="announcement-meta">
                <span class="announcement-time">📅 ${announcement.timestamp}</span>
                <span class="announcement-audience">👥 ${announcement.audience.join(', ')}</span>
            </div>
            <div class="announcement-actions">
                <button class="btn-edit-announcement" onclick="editAnnouncement(${announcement.id})">Edit</button>
                <button class="btn-delete-announcement" onclick="deleteAnnouncement(${announcement.id})">Delete</button>
            </div>
        `;

        container.appendChild(card);
    });
}

// Edit Announcement
function editAnnouncement(id) {
    const announcement = announcements.find(a => a.id === id);
    if (!announcement) return;

    // Populate form
    document.getElementById('announcement-title').value = announcement.title;
    document.getElementById('announcement-message').value = announcement.message;
    document.getElementById('announcement-type').value = announcement.type;

    // Set audience
    const audienceCheckboxes = document.querySelectorAll('#announcement-form .checkbox-group input');
    audienceCheckboxes.forEach(checkbox => {
        checkbox.checked = announcement.audience.includes(checkbox.value);
    });

    // Show form
    document.getElementById('announcement-form-container').style.display = 'block';

    // Store ID for update
    document.getElementById('announcement-form').dataset.editId = id;
}

// Delete Announcement
function deleteAnnouncement(id) {
    if (confirm('Are you sure you want to delete this announcement?')) {
        announcements = announcements.filter(a => a.id !== id);
        renderAnnouncements();
        updateStats();
    }
}

// Update announcement stats
function updatePendingMessages() {
    const pending = announcements.filter(a => a.status === 'Scheduled').length;
    document.getElementById('pending-messages').textContent = pending;
}

// Export functions for access from other files
window.announcements = announcements;
