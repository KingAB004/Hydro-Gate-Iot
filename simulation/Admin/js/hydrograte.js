// ===== Hydrograte Status & Model =====
let hydrogrates = [
    {
        id: 1,
        name: 'Main Station - Downtown',
        location: 'Downtown Area, Sector A',
        status: 'Online',
        responseTime: 125,
        lastPing: 'Just now',
        model: 'Hydrograte-Pro-X1',
        firmware: 'v2.4.1',
        serial: 'HGP-2024-001',
        sensors: 3,
        waterLevel: 0.65,
        maxWaterLevel: 50,
        lastCalibration: '2026-03-01',
        nextCalibration: '2026-04-01',
        installationDate: '2024-01-15',
        errorLogs: [
            { timestamp: '2026-03-07 09:15', message: 'Sensor 2 calibration drift detected', type: 'warning' },
            { timestamp: '2026-03-07 08:30', message: 'Water level exceeded 60%', type: 'warning' },
            { timestamp: '2026-03-07 07:45', message: 'System health check passed', type: 'success' },
        ]
    },
    {
        id: 2,
        name: 'Residential Zone Monitor',
        location: 'Residential Area, Zone B',
        status: 'Online',
        responseTime: 142,
        lastPing: '2 min ago',
        model: 'Hydrograte-Lite-V2',
        firmware: 'v2.3.5',
        serial: 'HGP-2024-002',
        sensors: 2,
        waterLevel: 0.45,
        maxWaterLevel: 1.2,
        lastCalibration: '2026-02-28',
        nextCalibration: '2026-03-28',
        installationDate: '2024-03-10',
        errorLogs: [
            { timestamp: '2026-03-07 08:00', message: 'Routine check completed', type: 'success' },
        ]
    }
];

let nextHydrograteId = 3;
let selectedHydrograteId = 1;
let hydrograteData = hydrogrates[0];

// Init Hydrograte Status
function initHydrograteStatus() {
    if (window.db) {
        const floodRef = window.db.ref('flood_monitoring');
        floodRef.on('value', function(snapshot) {
            if (snapshot.exists()) {
                const data = snapshot.val();
                if (hydrogrates && hydrogrates.length > 0) {
                    const mainStation = hydrogrates[0];
                    if (data.water_height_cm !== undefined) {
                        mainStation.waterLevel = data.water_height_cm;
                    }
                    if (data.last_updated) {
                        mainStation.lastPing = data.last_updated;
                    }
                    let activeSensors = 0;
                    if (data.sensor_safe) activeSensors++;
                    if (data.sensor_warning) activeSensors++;
                    if (data.sensor_danger) activeSensors++;
                    mainStation.sensors = activeSensors || 3;
                    
                    renderHydrogratesList();
                    if (selectedHydrograteId === mainStation.id) {
                        hydrograteData = mainStation;
                        
                        // ADD FLOODGATE STATUS UPDATE HERE
                        const floodgateStatusEl = document.getElementById('remote-floodgate-status');
                        if (floodgateStatusEl && data.floodgate_status) {
                            floodgateStatusEl.textContent = data.floodgate_status.toUpperCase();
                        }
                        
                        renderHydrograteStatus();
                    }
                    if (typeof window.updateStats === 'function') {
                        window.updateStats();
                    }
                }
            }
        });
    }

    renderHydrogratesList();
    renderHydrograteStatus();
    attachHydrograteEventListeners();
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
            if (window.db) {
                const floodRef = window.db.ref('flood_monitoring');
                floodRef.once('value').then(function(snapshot) {
                    if (snapshot.exists()) {
                        const currentStatus = snapshot.val().floodgate_status;
                        const newStatus = currentStatus === 'open' ? 'closed' : 'open';
                        floodRef.update({ floodgate_status: newStatus }).then(function() {
                            if (typeof window.writeAuditLog === 'function') {
                                window.writeAuditLog(
                                    'admin_floodgate_toggle',
                                    'warning',
                                    'Floodgate set to ' + newStatus
                                );
                            }
                        }).catch(function(error) {
                            console.error('Floodgate update failed:', error);
                            if (typeof window.writeAuditLog === 'function') {
                                window.writeAuditLog(
                                    'admin_floodgate_toggle_failed',
                                    'danger',
                                    'Floodgate toggle failed: ' + error.message
                                );
                            }
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
                    '<p class="device-location">?? ' + device.location + '</p>' +
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
                '<button class="btn-device-view" onclick="selectHydrograte(' + device.id + ')">View Details</button>' +
                '<button class="btn-device-edit" onclick="editHydrograte(' + device.id + ')">Edit</button>' +
                '<button class="btn-device-delete" onclick="deleteHydrograte(' + device.id + ')">Delete</button>' +
            '</div>';
        container.appendChild(card);
    });
}

// Select a device and show its details
function selectHydrograte(id) {
    selectedHydrograteId = id;
    hydrograteData = hydrogrates.find(function(h) { return h.id === id; });
    if (hydrograteData) {
        renderHydrograteStatus();
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

// Handle Hydrograte Form Submit
function handleHydrograteFormSubmit(e) {
    e.preventDefault();

    const deviceId = document.getElementById('hydrograte-id').value;
    const name = document.getElementById('device-name').value;
    const location = document.getElementById('device-loc').value;
    const model = document.getElementById('device-model').value;
    const serial = document.getElementById('device-serial').value;
    const firmware = document.getElementById('device-firmware').value;
    const sensors = parseInt(document.getElementById('device-sensors').value);
    const maxWaterLevel = parseFloat(document.getElementById('device-max-water').value);
    const installationDate = document.getElementById('device-install-date').value;

    if (deviceId) {
        const device = hydrogrates.find(function(h) { return h.id == deviceId; });
        if (device) {
            device.name = name;
            device.location = location;
            device.model = model;
            device.serial = serial;
            device.firmware = firmware;
            device.sensors = sensors;
            device.maxWaterLevel = maxWaterLevel;
            device.installationDate = installationDate;
        }
    } else {
        hydrogrates.push({
            id: nextHydrograteId++,
            name: name,
            location: location,
            model: model,
            serial: serial,
            firmware: firmware,
            sensors: sensors,
            maxWaterLevel: maxWaterLevel,
            installationDate: installationDate,
            status: 'Online',
            responseTime: Math.floor(Math.random() * 100) + 80,
            lastPing: 'Just now',
            waterLevel: 0,
            lastCalibration: new Date().toISOString().split('T')[0],
            nextCalibration: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
            errorLogs: []
        });
    }

    renderHydrogratesList();
    closeHydrograteModal();
    if (typeof updateStats === 'function') updateStats();
    alert('Hydrograte device saved successfully!');
}

// Edit Hydrograte
function editHydrograte(id) {
    const device = hydrogrates.find(function(h) { return h.id === id; });
    if (!device) return;

    document.getElementById('hydrograte-id').value = device.id;
    document.getElementById('device-name').value = device.name;
    document.getElementById('device-loc').value = device.location;
    document.getElementById('device-model').value = device.model;
    document.getElementById('device-serial').value = device.serial;
    document.getElementById('device-firmware').value = device.firmware;
    document.getElementById('device-sensors').value = device.sensors;
    document.getElementById('device-max-water').value = device.maxWaterLevel;
    document.getElementById('device-install-date').value = device.installationDate;

    const titleEl = document.getElementById('hydrograte-modal-title');
    if (titleEl) titleEl.textContent = 'Edit Hydrograte Device';
    document.getElementById('hydrograte-modal').classList.add('active');
}

// Delete Hydrograte
function deleteHydrograte(id) {
    if (hydrogrates.length <= 1) {
        alert('Cannot delete the last hydrograte device!');
        return;
    }

    if (confirm('Are you sure you want to delete this hydrograte device?')) {
        hydrogrates = hydrogrates.filter(function(h) { return h.id !== id; });

        if (selectedHydrograteId === id) {
            selectedHydrograteId = hydrogrates[0].id;
            hydrograteData = hydrogrates[0];
        }

        renderHydrogratesList();
        renderHydrograteStatus();
        if (typeof updateStats === 'function') updateStats();
    }
}

// Refresh Hydrograte Data
function refreshHydrograteData() {
    if (!hydrograteData) return;

    hydrograteData.responseTime = Math.floor(Math.random() * 200) + 50;
    hydrograteData.lastPing = 'Just now';
    hydrograteData.waterLevel = parseFloat((Math.random() * hydrograteData.maxWaterLevel).toFixed(2));

    renderHydrograteStatus();

    const btn = document.getElementById('refresh-hydrograte');
    if (btn) {
        const originalText = btn.textContent;
        btn.textContent = '? Refreshed';
        setTimeout(function() { btn.textContent = originalText; }, 2000);
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

