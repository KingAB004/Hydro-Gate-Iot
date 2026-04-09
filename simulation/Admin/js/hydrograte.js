// ===== Hydrograte Status & Model =====
let hydrogrates = []; // Now populated from Firestore

let nextHydrograteId = 3;
let selectedHydrograteId = 1;
let hydrograteData = hydrogrates[0];

// Init Hydrograte Status
function initHydrograteStatus() {
    if (window.firestoreDb) {
        // Listen to Devices in Firestore
        window.firestoreDb.collection('devices').onSnapshot(function(snapshot) {
            hydrogrates = [];
            snapshot.forEach(function(doc) {
                const data = doc.data();
                hydrogrates.push({
                    id: doc.id,
                    name: data.name || 'Unnamed Device',
                    location: data.location || 'Unknown Location',
                    status: data.status || 'Online',
                    responseTime: data.responseTime || 0,
                    lastPing: data.updated_at || 'Never',
                    model: data.model || 'Unknown Model',
                    firmware: data.firmware || 'N/A',
                    serial: data.serial || doc.id,
                    sensors: data.sensors || 0,
                    waterLevel: 0.0, // Will be updated by RTDB
                    maxWaterLevel: data.maxWaterLevel || 1.5,
                    installationDate: data.installationDate || 'N/A',
                    lastCalibration: data.lastCalibration || 'N/A',
                    nextCalibration: data.nextCalibration || 'N/A',
                    errorLogs: data.errorLogs || []
                });
            });

            if (hydrogrates.length > 0 && !hydrogrates.find(h => h.id === selectedHydrograteId)) {
                selectedHydrograteId = hydrogrates[0].id;
            }
            
            renderHydrogratesList();
            syncWithRTDB();
        });
    }

    renderHydrogratesList();
    renderHydrograteStatus();
    attachHydrograteEventListeners();
}

// Sync selected device with Realtime Database
function syncWithRTDB() {
    if (window.db && selectedHydrograteId) {
        const floodRef = window.db.ref('flood_monitoring/' + selectedHydrograteId);
        floodRef.on('value', function(snapshot) {
            if (snapshot.exists()) {
                const data = snapshot.val();
                const current = hydrogrates.find(h => h.id === selectedHydrograteId);
                if (current) {
                    current.waterLevel = data.water_level_m || 0;
                    current.lastPing = data.last_updated || current.lastPing;
                    
                    const floodgateStatusEl = document.getElementById('remote-floodgate-status');
                    if (floodgateStatusEl && data.floodgate_status) {
                        floodgateStatusEl.textContent = data.floodgate_status.toUpperCase();
                        
                        // Update toggle button text based on current status
                        const toggleBtn = document.getElementById('toggle-floodgate-btn');
                        if (toggleBtn) {
                            toggleBtn.textContent = data.floodgate_status === 'open' ? 'Close Floodgate' : 'Open Floodgate';
                            toggleBtn.className = data.floodgate_status === 'open' ? 'btn btn-danger' : 'btn btn-primary';
                        }
                    }
                    
                    hydrograteData = current;
                    renderHydrograteStatus();
                    
                    if (typeof window.updateStats === 'function') {
                        window.updateStats();
                    }
                }
            }
        });
    }
}

// Attach event listeners
function attachHydrograteEventListeners() {
    const refreshBtn = document.getElementById('refresh-hydrograte');
    const calibrateBtn = document.getElementById('calibrate-btn');
    const restartBtn = document.getElementById('restart-btn');
    const addHydrograteBtn = document.getElementById('add-hydrograte-btn');
    const hydrograteForm = document.getElementById('hydrograte-form');
    const closeHydrograteModalBtn = document.getElementById('close-hydrograte-modal');
    const closeHydrograteFormBtn = document.getElementById('close-hydrograte-form-btn');

    // Toggle Floodgate Button
    const toggleFloodgateBtn = document.getElementById('toggle-floodgate-btn');
    if (toggleFloodgateBtn) {
        toggleFloodgateBtn.addEventListener('click', function() {
            if (window.db && selectedHydrograteId) {
                const floodRef = window.db.ref('flood_monitoring/' + selectedHydrograteId);
                floodRef.once('value').then(function(snapshot) {
                    if (snapshot.exists()) {
                        const currentStatus = snapshot.val().floodgate_status;
                        const newStatus = currentStatus === 'open' ? 'closed' : 'open';
                        floodRef.update({ floodgate_status: newStatus }).then(function() {
                            if (typeof window.writeAuditLog === 'function') {
                                window.writeAuditLog(
                                    'admin_floodgate_toggle',
                                    'warning',
                                    'Floodgate (Device: ' + selectedHydrograteId + ') set to ' + newStatus
                                );
                            }
                        });
                    } else {
                        // For a new device, initialize the data for the first time
                        floodRef.set({
                            floodgate_status: 'open',
                            last_updated: new Date().toLocaleTimeString(),
                            sensor_warning: false,
                            water_level: 'safe',
                            water_level_m: 0.1
                        }).then(function() {
                            alert('RTDB entry initialized for device: ' + selectedHydrograteId);
                        });
                    }
                });
            }
        });
    }

    if (refreshBtn) refreshBtn.addEventListener('click', refreshHydrograteData);
    if (calibrateBtn) calibrateBtn.addEventListener('click', calibrateDevice);
    if (restartBtn) restartBtn.addEventListener('click', restartDevice);
    if (addHydrograteBtn) addHydrograteBtn.addEventListener('click', openAddHydrograteModal);
    if (hydrograteForm) hydrograteForm.addEventListener('submit', handleHydrograteFormSubmit);
    if (closeHydrograteModalBtn) closeHydrograteModalBtn.addEventListener('click', closeHydrograteModal);
    if (closeHydrograteFormBtn) closeHydrograteFormBtn.addEventListener('click', closeHydrograteModal);
}

// Render Hydrogrates List
function renderHydrogratesList() {
    const container = document.getElementById('hydrogrates-list');
    if (!container) return;

    container.innerHTML = '';

    hydrogrates.forEach(function(device) {
        const waterPercent = (device.waterLevel / device.maxWaterLevel) * 100;
        let statusClass = 'badge-success';
        if (device.status === 'Offline') statusClass = 'badge-danger';
        if (device.status === 'Maintenance') statusClass = 'badge-warning';

        const card = document.createElement('div');
        card.className = 'hydrograte-device-card';
        card.innerHTML =
            '<div class="device-card-header">' +
                '<div>' +
                    '<h5>' + device.name + '</h5>' +
                    '<p class="device-location">' +
                        '<i data-lucide="map-pin" class="device-location-icon"></i>' +
                        '<span>' + device.location + '</span>' +
                    '</p>' +
                '</div>' +
                '<span class="badge ' + statusClass + '">' + device.status + '</span>' +
            '</div>' +
            '<div class="device-card-body">' +
                '<div class="device-metric">' +
                    '<span class="metric-label">Water Level</span>' +
                    '<span class="metric-value">' + Math.round(waterPercent) + '%</span>' +
                '</div>' +
                '<div class="device-metric">' +
                    '<span class="metric-label">Response</span>' +
                    '<span class="metric-value">' + device.responseTime + 'ms</span>' +
                '</div>' +
                '<div class="device-metric">' +
                    '<span class="metric-label">Sensors</span>' +
                    '<span class="metric-value">' + device.sensors + '</span>' +
                '</div>' +
            '</div>' +
            '<div class="device-card-footer">' +
                '<button class="btn-device-view" onclick="selectHydrograte(\'' + device.id + '\')">View Details</button>' +
                '<button class="btn-device-edit" onclick="editHydrograte(\'' + device.id + '\')">Edit</button>' +
                '<button class="btn-device-delete" onclick="deleteHydrograte(\'' + device.id + '\')">Delete</button>' +
            '</div>';
        container.appendChild(card);
    });

    // Re-render Lucide icons for dynamically injected markup.
    if (window.lucide && typeof window.lucide.createIcons === 'function') {
        window.lucide.createIcons();
    }
}

// Select a device and show its details
function selectHydrograte(id) {
    selectedHydrograteId = id;
    hydrograteData = hydrogrates.find(function(h) { return h.id === id; });
    if (hydrograteData) {
        renderHydrograteStatus();
        syncWithRTDB(); // Start listening to this device's live data
        const detailsEl = document.getElementById('selected-device-details');
        if (detailsEl) detailsEl.scrollIntoView({ behavior: 'smooth' });
    }
}

// Render selected device detail panel
function renderHydrograteStatus() {
    if (!hydrograteData) return;

    const deviceHeader = document.getElementById('selected-device-name');
    if (deviceHeader) deviceHeader.textContent = hydrograteData.name;

    const deviceStatusEl = document.getElementById('device-status');
    if (deviceStatusEl) deviceStatusEl.textContent = hydrograteData.status;

    const responseTimeEl = document.getElementById('response-time');
    if (responseTimeEl) responseTimeEl.textContent = hydrograteData.responseTime + 'ms';

    const lastPingEl = document.getElementById('last-ping');
    if (lastPingEl) lastPingEl.textContent = hydrograteData.lastPing;

    const waterLevelPercent = (hydrograteData.waterLevel / hydrograteData.maxWaterLevel) * 100;

    const gaugeFill = document.getElementById('gauge-fill');
    if (gaugeFill) gaugeFill.style.setProperty('--gauge-rotation', (waterLevelPercent * 3.6) + 'deg');

    const gaugeText = document.getElementById('gauge-text');
    if (gaugeText) gaugeText.textContent = Math.round(waterLevelPercent) + '%';

    const waterLevelValueEl = document.getElementById('water-level-value');
    if (waterLevelValueEl) waterLevelValueEl.textContent = hydrograteData.waterLevel.toFixed(2);

    const waterLevelMaxEl = document.getElementById('water-level-max');
    if (waterLevelMaxEl) waterLevelMaxEl.textContent = hydrograteData.maxWaterLevel.toFixed(2);

    const modelNameEl = document.getElementById('model-name');
    if (modelNameEl) modelNameEl.textContent = hydrograteData.model;

    const firmwareEl = document.getElementById('firmware-version');
    if (firmwareEl) firmwareEl.textContent = hydrograteData.firmware;

    const serialEl = document.getElementById('serial-number');
    if (serialEl) serialEl.textContent = hydrograteData.serial;

    const sensorsEl = document.getElementById('sensors-count');
    if (sensorsEl) sensorsEl.textContent = hydrograteData.sensors;

    const locationEl = document.getElementById('device-location');
    if (locationEl) locationEl.textContent = hydrograteData.location;

    const installDateEl = document.getElementById('installation-date');
    if (installDateEl) installDateEl.textContent = hydrograteData.installationDate;

    const lastCalEl = document.getElementById('last-calibration');
    if (lastCalEl) lastCalEl.textContent = hydrograteData.lastCalibration;

    const nextCalEl = document.getElementById('next-calibration');
    if (nextCalEl) nextCalEl.textContent = hydrograteData.nextCalibration;

    // Overview stat card (null-safe — only present when overview tab is active)
    const statusHydroEl = document.getElementById('status-hydrograte');
    if (statusHydroEl) statusHydroEl.textContent = hydrograteData.status;

    const statusUpdatedEl = document.getElementById('status-updated');
    if (statusUpdatedEl) statusUpdatedEl.textContent = new Date().toLocaleTimeString();

    renderErrorLogs();
}

// Render error logs for selected device
function renderErrorLogs() {
    const logsContainer = document.getElementById('error-logs');
    if (!logsContainer || !hydrograteData) return;

    logsContainer.innerHTML = '';

    hydrograteData.errorLogs.forEach(function(log) {
        const logEntry = document.createElement('div');
        logEntry.className = 'log-entry ' + log.type;
        logEntry.innerHTML =
            '<div><strong>' + log.message + '</strong></div>' +
            '<div class="log-timestamp">' + log.timestamp + '</div>';
        logsContainer.appendChild(logEntry);
    });
}

// Open Add Hydrograte Modal
function openAddHydrograteModal() {
    document.getElementById('hydrograte-id').value = '';
    document.getElementById('hydrograte-form').reset();
    const titleEl = document.getElementById('hydrograte-modal-title');
    if (titleEl) titleEl.textContent = 'Add New Hydrograte Device';
    document.getElementById('hydrograte-modal').classList.add('active');
}

// Close Hydrograte Modal
function closeHydrograteModal() {
    document.getElementById('hydrograte-modal').classList.remove('active');
}

// Slugify helper to create URL/ID friendly strings
function slugify(text) {
    if (!text) return '';
    return text.toString().toLowerCase()
        .replace(/\s+/g, '_')           // Replace spaces with _
        .replace(/[^\w-]+/g, '')       // Remove all non-word chars
        .replace(/\-\-+/g, '_')         // Replace multiple - with single _
        .replace(/^-+/, '')             // Trim - from start of text
        .replace(/-+$/, '');            // Trim - from end of text
}

// Handle Hydrograte Form Submit
async function handleHydrograteFormSubmit(e) {
    e.preventDefault();

    const oldDeviceId = document.getElementById('hydrograte-id').value;
    const name = document.getElementById('device-name').value;
    const location = document.getElementById('device-loc').value;
    const maxWaterLevel = parseFloat(document.getElementById('device-max-water').value);
    const installationDate = document.getElementById('device-install-date').value;

    // Generate new ID from name
    const slug = slugify(name);
    const newDeviceId = slug ? 'gate_' + slug : 'gate_' + Date.now();
    
    // Check if we are creating a new device or editing an existing one
    const isNewDevice = !oldDeviceId;
    const finalDeviceId = isNewDevice ? newDeviceId : oldDeviceId;

    const deviceData = {
        name: name,
        location: location,
        maxWaterLevel: maxWaterLevel,
        installationDate: installationDate,
        updated_at: new Date().toISOString()
    };

    if (window.firestoreDb) {
        try {
            // Case 1: New Device
            if (isNewDevice) {
                // Ensure ID uniqueness for new devices
                let uniqueId = finalDeviceId;
                let counter = 1;
                let doc = await window.firestoreDb.collection('devices').doc(uniqueId).get();
                while (doc.exists) {
                    uniqueId = finalDeviceId + '_' + counter;
                    doc = await window.firestoreDb.collection('devices').doc(uniqueId).get();
                    counter++;
                }
                
                await window.firestoreDb.collection('devices').doc(uniqueId).set(deviceData);
                alert('New Hydrograte device created with ID: ' + uniqueId);
            } 
            // Case 2: Editing Existing Device
            else {
                // Check if user wants to migrate the ID (if name changed and it's an old-style ID)
                const isOldStyleId = oldDeviceId.match(/^gate_\d+$/);
                const shouldMigrate = isOldStyleId && oldDeviceId !== newDeviceId && 
                                    confirm(`This device has an old numeric ID (${oldDeviceId}). Would you like to migrate it to a name-based ID (${newDeviceId})? \n\nThis will update all database records and user assignments.`);

                if (shouldMigrate) {
                    await migrateDeviceId(oldDeviceId, newDeviceId, deviceData);
                } else {
                    // Just update existing document
                    await window.firestoreDb.collection('devices').doc(oldDeviceId).set(deviceData, { merge: true });
                    alert('Hydrograte device updated successfully!');
                }
            }

            closeHydrograteModal();
            if (typeof updateStats === 'function') updateStats();
        } catch (error) {
            console.error('Error saving device:', error);
            alert('Failed to save device: ' + error.message);
        }
    }
}

// Migration logic to safely rename a device ID across platforms
async function migrateDeviceId(oldId, newId, deviceData) {
    console.log(`Starting migration from ${oldId} to ${newId}...`);
    
    // 1. Check if newId already exists
    const existingDoc = await window.firestoreDb.collection('devices').doc(newId).get();
    if (existingDoc.exists) {
        newId = newId + '_' + Math.floor(Math.random() * 1000);
    }

    // 2. Copy Firestore Data
    await window.firestoreDb.collection('devices').doc(newId).set(deviceData);
    
    // 3. Copy Realtime Database Data
    if (window.db) {
        const oldRtdbRef = window.db.ref('flood_monitoring/' + oldId);
        const newRtdbRef = window.db.ref('flood_monitoring/' + newId);
        const snapshot = await oldRtdbRef.once('value');
        if (snapshot.exists()) {
            await newRtdbRef.set(snapshot.val());
        } else {
            // Initialize if it doesn't exist
            await newRtdbRef.set({
                floodgate_status: 'open',
                last_updated: new Date().toLocaleTimeString(),
                sensor_warning: false,
                water_level: 'safe',
                water_level_m: 0.1
            });
        }
    }

    // 4. Update User Assignments in Firestore
    const userSnapshot = await window.firestoreDb.collection('users')
        .where('assigned_gate_id', '==', oldId).get();
    
    const branchPromises = [];
    userSnapshot.forEach(doc => {
        branchPromises.push(doc.ref.update({ assigned_gate_id: newId }));
    });
    await Promise.all(branchPromises);

    // 5. Delete Old Records
    await window.firestoreDb.collection('devices').doc(oldId).delete();
    if (window.db) {
        await window.db.ref('flood_monitoring/' + oldId).remove();
    }

    alert(`Successfully migrated device to new ID: ${newId}. \n${userSnapshot.size} user(s) updated.`);
}

// Edit Hydrograte
function editHydrograte(id) {
    const device = hydrogrates.find(function(h) { return h.id === id; });
    if (!device) return;

    document.getElementById('hydrograte-id').value = device.id;
    document.getElementById('device-name').value = device.name;
    document.getElementById('device-loc').value = device.location;
    document.getElementById('device-max-water').value = device.maxWaterLevel;
    document.getElementById('device-install-date').value = device.installationDate;

    const titleEl = document.getElementById('hydrograte-modal-title');
    if (titleEl) titleEl.textContent = 'Edit Hydrograte Device';
    document.getElementById('hydrograte-modal').classList.add('active');
}

// Delete Hydrograte
function deleteHydrograte(id) {
    const device = hydrogrates.find(function(h) { return h.id === id; });
    const label = device ? (device.name + (device.location ? ' (' + device.location + ')' : '')) : id;

    const runDelete = async function() {
        if (!window.firestoreDb) {
            alert('Firestore is not initialized. Please reload the page.');
            return;
        }

        try {
            await window.firestoreDb.collection('devices').doc(id).delete();
            alert('Device deleted successfully.');
            if (typeof updateStats === 'function') updateStats();
        } catch (error) {
            console.error('Error deleting device:', error);
            alert('Failed to delete device: ' + (error.message || 'Unknown error'));
        }
    };

    if (typeof window.openConfirmDeleteModal === 'function') {
        window.openConfirmDeleteModal({
            title: 'Delete Device',
            message: `Delete device "${label}"? This will remove its database record.`,
            confirmText: 'Delete',
            onConfirm: runDelete
        });
        return;
    }

    if (confirm('Are you sure you want to delete this hydrograte device? This will also remove its database record.')) {
        runDelete();
    }
}

// Refresh Hydrograte Data
function refreshHydrograteData() {
    if (!hydrograteData) return;

    hydrograteData.responseTime = Math.floor(Math.random() * 200) + 50;
    hydrograteData.lastPing = 'Just now';
    
    // Generate a random unit between 0 and 25 (simulated meters)
    const newWaterLevel = Math.floor(Math.random() * 26); 
    hydrograteData.waterLevel = newWaterLevel;

    // Determine status string based on 18m critical and 15m caution
    let waterStatus = 'safe';
    if (newWaterLevel >= 18) {
        waterStatus = 'critical';
    } else if (newWaterLevel >= 15) {
        waterStatus = 'caution';
    }

    // Push to Firebase RTDB (direct mapping 1:1)
    if (window.db && selectedHydrograteId) {
        const floodRef = window.db.ref('flood_monitoring/' + selectedHydrograteId);
        floodRef.update({
            water_level_m: newWaterLevel,
            water_level: waterStatus,
            last_updated: new Date().toLocaleTimeString(),
            sensor_warning: newWaterLevel >= 24 // Warning if near max 25
        }).then(() => {
            console.log('RTDB updated with new water level:', newWaterLevel);
        }).catch(err => {
            console.error('Error updating RTDB:', err);
        });
    }

    renderHydrograteStatus();

    const btn = document.getElementById('refresh-hydrograte');
    if (btn) {
        btn.disabled = true;
        btn.classList.add('is-loading');
        window.setTimeout(function() {
            btn.classList.remove('is-loading');
            btn.disabled = false;
        }, 900);
    }
}

// Calibrate Device
function calibrateDevice() {
    if (confirm('Proceed with device calibration? This may take 2-3 minutes.')) {
        const btn = document.getElementById('calibrate-btn');
        if (btn) { btn.disabled = true; btn.textContent = 'Calibrating...'; }

        setTimeout(function() {
            hydrograteData.lastCalibration = new Date().toISOString().split('T')[0];
            const nextDate = new Date();
            nextDate.setMonth(nextDate.getMonth() + 1);
            hydrograteData.nextCalibration = nextDate.toISOString().split('T')[0];

            hydrograteData.errorLogs.unshift({
                timestamp: new Date().toLocaleString(),
                message: 'Device calibration completed successfully',
                type: 'success'
            });

            renderHydrograteStatus();
            if (btn) { btn.disabled = false; btn.textContent = 'Calibrate Now'; }
            if (typeof window.writeAuditLog === 'function') {
                window.writeAuditLog(
                    'admin_hydrograte_calibrate',
                    'safe',
                    'Calibrated device: ' + (hydrograteData?.name || 'Unknown')
                );
            }
            alert('Device calibration completed successfully!');
        }, 3000);
    }
}

// Restart Device
function restartDevice() {
    if (confirm('Restart the device? System will be offline for 1-2 minutes.')) {
        const btn = document.getElementById('restart-btn');
        if (btn) { btn.disabled = true; btn.textContent = 'Restarting...'; }

        const statusEl = document.getElementById('device-status');
        if (statusEl) statusEl.textContent = 'Offline';

        setTimeout(function() {
            hydrograteData.status = 'Online';
            hydrograteData.lastPing = 'Just now';

            hydrograteData.errorLogs.unshift({
                timestamp: new Date().toLocaleString(),
                message: 'Device restart completed',
                type: 'success'
            });

            renderHydrograteStatus();
            if (btn) { btn.disabled = false; btn.textContent = 'Restart Device'; }
            if (typeof window.writeAuditLog === 'function') {
                window.writeAuditLog(
                    'admin_hydrograte_restart',
                    'warning',
                    'Restarted device: ' + (hydrograteData?.name || 'Unknown')
                );
            }
            alert('Device restarted successfully!');
        }, 2000);
    }
}

