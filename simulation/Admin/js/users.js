// ===== User Management =====
let users = [
    { id: 1, username: 'john_admin', email: 'john@afwms.com', role: 'Admin', status: 'Active', joined: '2025-01-15' },
    { id: 2, username: 'maria_lgu', email: 'maria@lgu.gov.ph', role: 'LGU', status: 'Active', joined: '2025-02-01' },
    { id: 3, username: 'home_user1', email: 'homeowner1@email.com', role: 'Homeowner', status: 'Active', joined: '2025-02-15' },
    { id: 4, username: 'home_user2', email: 'homeowner2@email.com', role: 'Homeowner', status: 'Inactive', joined: '2025-01-20' },
    { id: 5, username: 'lgu_officer', email: 'officer@lgu.gov.ph', role: 'LGU', status: 'Active', joined: '2025-02-10' },
];

let nextUserId = 6;
let filteredUsers = [...users];

// Init Users Management
function initUsersManagement() {
    renderUsersTable();
    attachUserEventListeners();
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
    document.getElementById('modal-title').textContent = 'Add New User';
    document.getElementById('user-modal').classList.add('active');
}

// Close User Modal
function closeUserModal() {
    document.getElementById('user-modal').classList.remove('active');
}

// Handle User Form Submit
function handleUserFormSubmit(e) {
    e.preventDefault();

    const userId = document.getElementById('user-id').value;
    const username = document.getElementById('username').value;
    const email = document.getElementById('email').value;
    const role = document.getElementById('role').value;
    const password = document.getElementById('password').value;
    const status = document.getElementById('status').value;

    if (userId) {
        // Update existing user
        const user = users.find(u => u.id == userId);
        if (user) {
            user.username = username;
            user.email = email;
            user.role = role;
            user.status = status;
        }
    } else {
        // Add new user
        users.push({
            id: nextUserId++,
            username,
            email,
            role,
            status,
            joined: new Date().toISOString().split('T')[0]
        });
    }

    renderUsersTable();
    closeUserModal();
    updateStats();
}

// Filter Users
function filterUsers() {
    const searchTerm = document.getElementById('search-users').value.toLowerCase();
    const roleFilter = document.getElementById('role-filter').value;
    const statusFilter = document.getElementById('status-filter').value;

    filteredUsers = users.filter(user => {
        const matchesSearch = user.username.toLowerCase().includes(searchTerm) || 
                            user.email.toLowerCase().includes(searchTerm);
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
        row.innerHTML = `
            <td>#${user.id}</td>
            <td><strong>${user.username}</strong></td>
            <td>${user.email}</td>
            <td><span class="badge">${user.role}</span></td>
            <td><span class="badge ${statusBadge}">${user.status}</span></td>
            <td>${user.joined}</td>
            <td>
                <div class="action-buttons">
                    <button class="btn-edit" onclick="editUser(${user.id})">Edit</button>
                    <button class="btn-delete" onclick="deleteUser(${user.id})">Delete</button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Edit User
function editUser(id) {
    const user = users.find(u => u.id === id);
    if (!user) return;

    document.getElementById('user-id').value = user.id;
    document.getElementById('username').value = user.username;
    document.getElementById('email').value = user.email;
    document.getElementById('role').value = user.role;
    document.getElementById('status').value = user.status;
    document.getElementById('password').value = '••••••••';
    document.getElementById('modal-title').textContent = 'Edit User';
    document.getElementById('user-modal').classList.add('active');
}

// Delete User
function deleteUser(id) {
    if (confirm('Are you sure you want to delete this user?')) {
        users = users.filter(u => u.id !== id);
        renderUsersTable();
        updateStats();
    }
}

// Update user stats
function updateStats() {
    document.getElementById('total-users').textContent = users.length;
}

// Export function for access from other files
window.users = users;
