// ===== User Management (Firebase Integrated Compat) =====

let users = [];
let filteredUsers = [];
let usersUnsubscribe = null;
let hasShownPermissionWarning = false;
window.users = users;

function normalizeRole(role) {
    const value = (role || '').toString().trim().toLowerCase();
    if (value === 'admin') return 'Admin';
    if (value === 'lgu') return 'LGU';
    if (value === 'homeowner') return 'Homeowner';
    return 'Homeowner';
}

function normalizeStatus(status) {
    const value = (status || '').toString().trim().toLowerCase();
    return value === 'inactive' ? 'Inactive' : 'Active';
}

function normalizeUserDoc(id, data) {
    const username = (data.username || data.name || '').toString().trim();
    const email = (data.email || '').toString().trim();
    const phone = (data.phone || '').toString().trim();

    return {
        id: id,
        username: username || (email ? email.split('@')[0] : 'Unknown User'),
        email: email || 'N/A',
        phone: phone,
        role: normalizeRole(data.role),
        status: normalizeStatus(data.status),
        joined: data.joined || 'N/A',
        pushNotificationsEnabled: Boolean(data.pushNotificationsEnabled),
        smsNotificationsEnabled: Boolean(data.smsNotificationsEnabled),
        assigned_gate_id: data.assigned_gate_id || ''
    };
}

// Init Users Management
window.initUsersManagement = async function() {
    attachUserEventListeners();
    await fetchUsers();
    subscribeUsersRealtime();
};

async function fetchUsers() {
    const firestoreDb = window.firestoreDb;
    if (!firestoreDb) {
        console.error('Firestore is not initialized.');
        return;
    }

    try {
        const snapshot = await firestoreDb.collection('users').get();
        applyUsersSnapshot(snapshot);
    } catch (e) {
        console.error("Error fetching users: ", e);
        handleUsersPermissionError(e);
    }
}

function subscribeUsersRealtime() {
    const firestoreDb = window.firestoreDb;
    if (!firestoreDb) return;

    if (typeof usersUnsubscribe === 'function') {
        usersUnsubscribe();
    }

    usersUnsubscribe = firestoreDb.collection('users').onSnapshot(function(snapshot) {
        applyUsersSnapshot(snapshot);
    }, function(error) {
        console.error('Realtime users listener failed:', error);
        handleUsersPermissionError(error);
    });
}

function applyUsersSnapshot(snapshot) {
    users = [];
    snapshot.forEach(function(doc) {
        users.push(normalizeUserDoc(doc.id, doc.data() || {}));
    });
    window.users = users;
    filteredUsers = [...users];
    renderUsersTable();
    if (typeof window.updateStats === 'function') {
        window.updateStats();
    }
}

function handleUsersPermissionError(error) {
    if (!error || !error.code) return;
    const isPermissionError = error.code === 'permission-denied' || error.code === 'PERMISSION_DENIED';
    if (isPermissionError && !hasShownPermissionWarning) {
        hasShownPermissionWarning = true;
        alert('Firestore permission denied for users collection. Check Firestore rules/auth for /users.');
    }
}

// Attach event listeners
function attachUserEventListeners() {
    const addUserBtn = document.getElementById('add-user-btn');
    const userForm = document.getElementById('user-form');
    const closeUserModalBtn = document.getElementById('close-user-modal');
    const closeFormBtn = document.getElementById('close-form-btn');
    const searchUsers = document.getElementById('search-users');
    const roleFilter = document.getElementById('role-filter');
    const statusFilter = document.getElementById('status-filter');

    if (addUserBtn) addUserBtn.addEventListener('click', openAddUserModal);
    if (userForm) userForm.addEventListener('submit', handleUserFormSubmit);
    if (closeUserModalBtn) closeUserModalBtn.addEventListener('click', closeUserModal);
    if (closeFormBtn) closeFormBtn.addEventListener('click', closeUserModal);
    if (searchUsers) searchUsers.addEventListener('input', filterUsers);
    if (roleFilter) roleFilter.addEventListener('change', filterUsers);
    if (statusFilter) statusFilter.addEventListener('change', filterUsers);
}

// Open Add User Modal
function openAddUserModal() {
    document.getElementById('user-id').value = '';
    document.getElementById('user-form').reset();
    
    // Make sure email is editable when adding a new user
    const emailInput = document.getElementById('email');
    emailInput.removeAttribute('readonly');
    emailInput.style.backgroundColor = '';
    emailInput.title = "";

    document.getElementById('password').closest('.form-group').style.display = 'block';
    document.getElementById('password').required = true;
    document.getElementById('modal-title').textContent = 'Add New User';
    
    // Populate device dropdown
    populateDeviceDropdown();
    
    document.getElementById('user-modal').classList.add('active');
}

// Populate Device Dropdown
async function populateDeviceDropdown(selectedId = '') {
    const gateSelect = document.getElementById('assigned-gate');
    if (!gateSelect) return;

    const firestoreDb = window.firestoreDb;
    if (!firestoreDb) return;

    try {
        const snapshot = await firestoreDb.collection('devices').get();
        
        // Keep the "None" option
        gateSelect.innerHTML = '<option value="">None (No Device Assigned)</option>';
        
        snapshot.forEach(doc => {
            const device = doc.data();
            const option = document.createElement('option');
            option.value = doc.id;
            option.textContent = `${device.name || 'Unnamed'} (${device.location || 'No Location'})`;
            gateSelect.appendChild(option);
        });

        // Set selected value if provided
        if (selectedId) {
            gateSelect.value = selectedId;
        }
    } catch (error) {
        console.error("Error populating device dropdown:", error);
    }
}

// Close User Modal
function closeUserModal() {
    document.getElementById('user-modal').classList.remove('active');
}

// Handle User Form Submit
async function handleUserFormSubmit(e) {
    e.preventDefault();

    const userId = document.getElementById('user-id').value;
    const username = document.getElementById('username').value.trim();
    const email = document.getElementById('email').value.trim();
    const role = normalizeRole(document.getElementById('role').value);
    const password = document.getElementById('password').value;
    const status = normalizeStatus(document.getElementById('status').value);

    const firestoreDb = window.firestoreDb;
    if (!firestoreDb) {
        alert('Firestore is not initialized. Please reload the page.');
        return;
    }

    if (userId) {
        // Update existing user
        try {
            const userDoc = firestoreDb.collection('users').doc(userId);
            await userDoc.update({
                username,
                email,
                role,
                status,
                assigned_gate_id: document.getElementById('assigned-gate').value,
                updatedAt: new Date().toISOString()
            });
            if (typeof window.writeAuditLog === 'function') {
                await window.writeAuditLog(
                    'admin_user_update',
                    'safe',
                    'Updated user: ' + email
                );
            }
            alert('User updated successfully!');
        } catch (error) {
            console.error("Error updating user: ", error);
            handleUsersPermissionError(error);
            alert('Error updating user: ' + error.message);
        }
    } else {
        // Add new user
        const secondaryAuth = window.secondaryAuth;
        try {
            // Create user in secondary auth (doesn't log current user out)
            const userCredential = await secondaryAuth.createUserWithEmailAndPassword(email, password);
            const newUid = userCredential.user.uid;

            // Add user details to Firestore Database
            const userDoc = firestoreDb.collection('users').doc(newUid);
            await userDoc.set({
                username,
                email,
                role,
                status,
                assigned_gate_id: document.getElementById('assigned-gate').value,
                joined: new Date().toISOString().split('T')[0],
                phone: '',
                pushNotificationsEnabled: true,
                smsNotificationsEnabled: true,
                updatedAt: new Date().toISOString()
            });

            if (typeof window.writeAuditLog === 'function') {
                await window.writeAuditLog(
                    'admin_user_create',
                    'safe',
                    'Created user: ' + email
                );
            }
            
            // Sign out the secondary app instance
            await secondaryAuth.signOut();

            alert('User created successfully!');
        } catch (error) {
            console.error("Error creating user: ", error);
            handleUsersPermissionError(error);
            alert('Error creating user: ' + error.message);
            return;
        }
    }

    // Listener will auto-refresh list, fetch is fallback if listener is not active.
    if (typeof usersUnsubscribe !== 'function') {
        await fetchUsers();
    }
    closeUserModal();
}

// Filter Users
function filterUsers() {
    const searchTerm = document.getElementById('search-users').value.toLowerCase();
    const roleFilter = document.getElementById('role-filter').value;
    const statusFilter = document.getElementById('status-filter').value;

    filteredUsers = users.filter(user => {
        const username = (user.username || '').toLowerCase();
        const email = (user.email || '').toLowerCase();
        const phone = (user.phone || '').toLowerCase();
        const matchesSearch = username.includes(searchTerm) || email.includes(searchTerm) || phone.includes(searchTerm);
        const matchesRole = !roleFilter || user.role === roleFilter;
        const matchesStatus = !statusFilter || user.status === statusFilter;

        return matchesSearch && matchesRole && matchesStatus;
    });

    renderUsersTable();
}

// Render Users Table
function renderUsersTable() {
    const tbody = document.getElementById('users-tbody');
    tbody.innerHTML = '';

    filteredUsers.forEach(user => {
        const statusBadge = user.status === 'Active' ? 'badge-success' : 'badge-danger';
        const row = document.createElement('tr');
        // Truncate long IDs to show in the table
        const shortId = user.id.substring(0, 8) + '...';
        row.innerHTML = `
            <td title="${user.id}">${shortId}</td>
            <td><strong>${user.username}</strong></td>
            <td>${user.email}</td>
            <td><span class="badge">${user.role}</span></td>
            <td><span class="badge ${statusBadge}">${user.status}</span></td>
            <td>${user.joined || 'N/A'}</td>
            <td>
                <div class="action-buttons">
                    <button class="btn-edit" onclick="window.editUser('${user.id}')">Edit</button>
                    <button class="btn-delete" onclick="window.deleteUser('${user.id}')">Delete</button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Edit User
window.editUser = function(id) {
    const user = users.find(u => u.id === id);
    if (!user) return;

    document.getElementById('user-id').value = user.id;
    document.getElementById('username').value = user.username;
    
    // Set email and make it disabled/readonly so admin can't change it and break auth mappings
    const emailInput = document.getElementById('email');
    emailInput.value = user.email;
    emailInput.setAttribute('readonly', 'true');
    emailInput.style.backgroundColor = '#f0f0f0';
    emailInput.title = "Email cannot be changed after creation for security reasons.";

    document.getElementById('role').value = user.role;
    document.getElementById('status').value = user.status;
    
    // Hide password field when editing as we don't handle auth update here
    const pwdInput = document.getElementById('password');
    pwdInput.value = '';
    pwdInput.required = false;
    pwdInput.closest('.form-group').style.display = 'none';

    document.getElementById('modal-title').textContent = 'Edit User';

    // Populate device dropdown and set selected value
    populateDeviceDropdown(user.assigned_gate_id);

    document.getElementById('user-modal').classList.add('active');
};

// Delete User
window.deleteUser = async function(id) {
    const user = users.find(u => u.id === id);
    const label = (user?.email || user?.username || id).toString();

    const runDelete = async function() {
        const firestoreDb = window.firestoreDb;
        try {
            await firestoreDb.collection('users').doc(id).delete();
            if (typeof window.writeAuditLog === 'function') {
                await window.writeAuditLog(
                    'admin_user_delete',
                    'warning',
                    'Deleted user profile: ' + label
                );
            }
            if (typeof usersUnsubscribe !== 'function') {
                await fetchUsers();
            }
        } catch (error) {
            console.error('Error deleting user: ', error);
            handleUsersPermissionError(error);
            alert('Error deleting user: ' + (error.message || 'Unknown error'));
        }
    };

    if (typeof window.openConfirmDeleteModal === 'function') {
        window.openConfirmDeleteModal({
            title: 'Delete User',
            message: `Delete user "${label}"? This deletes the Firestore profile only (it cannot delete the Firebase Auth account from the client).`,
            confirmText: 'Delete',
            onConfirm: runDelete
        });
        return;
    }

    if (confirm('Are you sure you want to delete this user from the dashboard list? Note: This deletes the Firestore profile, but cannot delete the Firebase Auth account directly from the client.')) {
        await runDelete();
    }
};

// Update user stats
function updateStats() {
    const totalUsersElem = document.getElementById('total-users');
    if (totalUsersElem) {
        totalUsersElem.textContent = users.length;
    }
}
window.updateStats = updateStats;
