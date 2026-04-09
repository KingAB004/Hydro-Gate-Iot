// ===== Statistics & Analytics Logic (Per-Device) =====

let liveChart;
let historyChart;
let doughnutChart;
const maxDataPoints = 30;

// Per-device state
let selectedStatsDeviceId = null;
let waterLevelHistory = [];
let timeLabels = [];
let peakWaterLevel = 0;
let __statsRtdbRef = null;

const THRESHOLD_CAUTION = 15;
const THRESHOLD_WARNING = 16;
const THRESHOLD_CRITICAL = 18;
const DAM_WATER_LEVEL_MAX_M = 21;

function initStatistics() {
    console.log('Initializing Statistics...');
    initLiveChart();
    initHistoryChart();
    initDoughnutChart();
    setupTimeframeButtons();
    loadDeviceSelector();
}

// ── Device Selector ──────────────────────────────────────────────────────────

function loadDeviceSelector() {
    const selector = document.getElementById('stats-device-selector');
    if (!selector) return;

    if (!window.firestoreDb) {
        // Fallback: try to load from flood_monitoring RTDB keys
        if (window.db) {
            window.db.ref('flood_monitoring').once('value', (snapshot) => {
                const data = snapshot.val();
                if (!data) return;
                selector.innerHTML = '';
                Object.keys(data).forEach((deviceId, idx) => {
                    const opt = document.createElement('option');
                    opt.value = deviceId;
                    opt.textContent = formatDeviceName(deviceId);
                    selector.appendChild(opt);
                });
                if (selector.options.length > 0) {
                    selectStatsDevice(selector.options[0].value);
                }
            });
        }
        return;
    }

    // Load from Firestore devices collection
    window.firestoreDb.collection('devices').onSnapshot((snapshot) => {
        selector.innerHTML = '';
        const devices = [];

        snapshot.forEach((doc) => {
            const data = doc.data();
            devices.push({ id: doc.id, name: data.name || doc.id, location: data.location || '' });
        });

        // Also check flood_monitoring for devices not in Firestore
        if (window.db) {
            window.db.ref('flood_monitoring').once('value', (rtdbSnapshot) => {
                const rtdbData = rtdbSnapshot.val() || {};
                Object.keys(rtdbData).forEach(deviceId => {
                    if (!devices.find(d => d.id === deviceId)) {
                        devices.push({ id: deviceId, name: formatDeviceName(deviceId), location: '' });
                    }
                });

                populateSelector(selector, devices);
            });
        } else {
            populateSelector(selector, devices);
        }
    });

    selector.addEventListener('change', function() {
        selectStatsDevice(this.value);
    });
}

function populateSelector(selector, devices) {
    selector.innerHTML = '';
    devices.forEach((device, idx) => {
        const opt = document.createElement('option');
        opt.value = device.id;
        opt.textContent = device.name + (device.location ? ' — ' + device.location : '');
        selector.appendChild(opt);
    });

    if (devices.length > 0) {
        // Keep current selection if still valid
        if (selectedStatsDeviceId && devices.find(d => d.id === selectedStatsDeviceId)) {
            selector.value = selectedStatsDeviceId;
        } else {
            selectStatsDevice(devices[0].id);
        }
    }
}

function formatDeviceName(id) {
    // gate_hydrogate-marikina → HydroGate-Marikina
    return id.replace(/^gate_/i, '')
        .split(/[-_]/)
        .map(w => w.charAt(0).toUpperCase() + w.slice(1))
        .join('-');
}

function selectStatsDevice(deviceId) {
    if (!deviceId) return;
    selectedStatsDeviceId = deviceId;

    // Reset per-device data
    waterLevelHistory = [];
    timeLabels = [];
    peakWaterLevel = 0;

    if (liveChart) {
        liveChart.data.labels = timeLabels;
        liveChart.data.datasets[0].data = waterLevelHistory;
        liveChart.update();
    }

    // Detach old listener
    if (__statsRtdbRef) {
        try { __statsRtdbRef.off(); } catch (_) {}
    }

    // Start listening to selected device
    listenToDeviceWaterLevel(deviceId);
    listenToDeviceGateStatus(deviceId);
    loadDeviceGateEventsToday(deviceId);
    loadDeviceRecentGateEvents(deviceId);

    // Update historical chart
    const activeBtn = document.querySelector('.timeframe-btn.active');
    const timeframe = activeBtn ? activeBtn.dataset.timeframe : 'day';
    updateHistoricalData(timeframe);

    // Update selector UI
    const selector = document.getElementById('stats-device-selector');
    if (selector && selector.value !== deviceId) {
        selector.value = deviceId;
    }
}

// ── Live Water Level Line Chart ──────────────────────────────────────────────

function initLiveChart() {
    const ctx = document.getElementById('liveWaterLevelChart');
    if (!ctx) return;

    const gradient = ctx.getContext('2d').createLinearGradient(0, 0, 0, 350);
    gradient.addColorStop(0, 'rgba(0, 126, 170, 0.35)');
    gradient.addColorStop(1, 'rgba(0, 126, 170, 0)');

    liveChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: timeLabels,
            datasets: [{
                label: 'Water Level (m)',
                data: waterLevelHistory,
                borderColor: '#007EAA',
                backgroundColor: gradient,
                borderWidth: 3,
                fill: true,
                tension: 0.4,
                pointRadius: 0,
                pointHoverRadius: 6,
                pointBackgroundColor: '#007EAA',
                pointBorderColor: '#fff',
                pointBorderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: {
                    beginAtZero: true, min: 0, max: DAM_WATER_LEVEL_MAX_M,
                    grid: { color: 'rgba(0,0,0,0.04)' },
                    ticks: { stepSize: 3, callback: value => value + 'm', font: { weight: 600 } }
                },
                x: { grid: { display: false }, ticks: { font: { size: 10 } } }
            },
            interaction: { intersect: false, mode: 'index' }
        },
        plugins: [{
            id: 'thresholdLines',
            beforeDraw(chart) {
                const { ctx, chartArea, scales } = chart;
                if (!chartArea) return;
                const lines = [
                    { value: THRESHOLD_CAUTION, color: '#F59E0B', label: 'Caution 15m' },
                    { value: THRESHOLD_WARNING, color: '#F97316', label: 'Warning 16m' },
                    { value: THRESHOLD_CRITICAL, color: '#EF4444', label: 'Critical 18m' },
                ];
                lines.forEach(line => {
                    const y = scales.y.getPixelForValue(line.value);
                    if (y < chartArea.top || y > chartArea.bottom) return;
                    ctx.save();
                    ctx.beginPath();
                    ctx.setLineDash([6, 4]);
                    ctx.strokeStyle = line.color;
                    ctx.lineWidth = 1.5;
                    ctx.moveTo(chartArea.left, y);
                    ctx.lineTo(chartArea.right, y);
                    ctx.stroke();
                    ctx.fillStyle = line.color;
                    ctx.font = '600 10px Manrope, sans-serif';
                    ctx.textAlign = 'right';
                    ctx.fillText(line.label, chartArea.right - 4, y - 6);
                    ctx.restore();
                });
            }
        }]
    });
}

// ── Gate Activity Doughnut Chart ─────────────────────────────────────────────

function initDoughnutChart() {
    const ctx = document.getElementById('gateActivityDoughnut');
    if (!ctx) return;

    doughnutChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Gate Opened', 'Gate Closed'],
            datasets: [{ data: [0, 0], backgroundColor: ['#10B981', '#EF4444'], borderWidth: 0, hoverOffset: 8 }]
        },
        options: {
            responsive: true, maintainAspectRatio: false, cutout: '65%',
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { padding: 20, font: { size: 13, weight: 600, family: 'Manrope' }, usePointStyle: true, pointStyle: 'circle' }
                }
            }
        }
    });
}

// ── Historical Bar Chart ─────────────────────────────────────────────────────

function initHistoryChart() {
    const ctx = document.getElementById('historicalWaterLevelChart');
    if (!ctx) return;

    historyChart = new Chart(ctx, {
        type: 'bar',
        data: { labels: [], datasets: [{ label: 'Gate Events', data: [], backgroundColor: 'rgba(0, 126, 170, 0.75)', borderRadius: 8, barPercentage: 0.6 }] },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.04)' }, ticks: { stepSize: 1, font: { weight: 600 } } },
                x: { grid: { display: false }, ticks: { font: { size: 11, weight: 600 } } }
            }
        }
    });
}

// ── Timeframe Buttons ────────────────────────────────────────────────────────

function setupTimeframeButtons() {
    const buttons = document.querySelectorAll('.timeframe-btn');
    buttons.forEach(btn => {
        btn.addEventListener('click', function() {
            buttons.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            updateHistoricalData(this.dataset.timeframe);
        });
    });
}

// ── Per-Device Water Level Listener ──────────────────────────────────────────

function listenToDeviceWaterLevel(deviceId) {
    if (!window.db || !deviceId) return;

    const ref = window.db.ref('flood_monitoring/' + deviceId + '/water_level_m');
    __statsRtdbRef = ref;

    ref.on('value', (snapshot) => {
        const value = snapshot.val();
        if (value === null || value === undefined) return;
        const numVal = Number(value);
        if (isNaN(numVal)) return;

        // Update live chart
        const now = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
        waterLevelHistory.push(numVal);
        timeLabels.push(now);
        if (waterLevelHistory.length > maxDataPoints) {
            waterLevelHistory.shift();
            timeLabels.shift();
        }
        if (liveChart) {
            liveChart.data.labels = timeLabels;
            liveChart.data.datasets[0].data = waterLevelHistory;
            liveChart.update('none');
        }

        // Update stat cards
        updateStatCards(numVal);
    });
}

// ── Per-Device Gate Status Listener ──────────────────────────────────────────

function listenToDeviceGateStatus(deviceId) {
    if (!window.db || !deviceId) return;

    window.db.ref('flood_monitoring/' + deviceId + '/floodgate_status').on('value', (snapshot) => {
        const status = snapshot.val();
        const statusEl = document.getElementById('stat-gate-status');
        const iconEl = document.getElementById('stat-gate-icon');

        if (statusEl && status) {
            const isClosed = status.toString().toLowerCase() === 'closed';
            statusEl.textContent = isClosed ? 'CLOSED' : 'OPEN';
            statusEl.style.color = isClosed ? '#EF4444' : '#10B981';
            if (iconEl) {
                iconEl.style.backgroundColor = isClosed ? '#fee2e2' : '#dcfce7';
                iconEl.style.color = isClosed ? '#EF4444' : '#10B981';
            }
        }
    });
}

// ── Stat Cards ───────────────────────────────────────────────────────────────

function updateStatCards(waterLevel) {
    const currentEl = document.getElementById('stat-current-level');
    if (currentEl) currentEl.textContent = waterLevel.toFixed(1) + 'm';

    if (waterLevel > peakWaterLevel) peakWaterLevel = waterLevel;
    const peakEl = document.getElementById('stat-peak-level');
    if (peakEl) peakEl.textContent = peakWaterLevel.toFixed(1) + 'm';

    const levelIcon = document.getElementById('stat-level-icon');
    if (levelIcon) {
        if (waterLevel >= THRESHOLD_CRITICAL) {
            levelIcon.style.backgroundColor = '#fee2e2'; levelIcon.style.color = '#EF4444';
        } else if (waterLevel >= THRESHOLD_CAUTION) {
            levelIcon.style.backgroundColor = '#fef3c7'; levelIcon.style.color = '#F59E0B';
        } else {
            levelIcon.style.backgroundColor = '#dcfce7'; levelIcon.style.color = '#10B981';
        }
    }
}

// ── Per-Device Gate Events Today ─────────────────────────────────────────────

function loadDeviceGateEventsToday(deviceId) {
    if (!window.db || !deviceId) return;

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    window.db.ref('audit_logs').orderByChild('timestamp').startAt(todayStart.getTime()).on('value', (snapshot) => {
        let count = 0;
        if (snapshot.exists()) {
            snapshot.forEach(child => {
                const log = child.val();
                const action = (log.action || '').toLowerCase();
                const desc = (log.description || '').toLowerCase();
                // Only count events for this specific device
                if ((action.includes('gate') || action.includes('flood')) && desc.includes(deviceId.toLowerCase())) {
                    count++;
                }
            });
        }
        const el = document.getElementById('stat-gate-events');
        if (el) el.textContent = count;
    });
}

// ── Per-Device Historical Data ───────────────────────────────────────────────

function updateHistoricalData(timeframe) {
    if (!window.db || !selectedStatsDeviceId) return;

    const now = Date.now();
    let startTime, bucketFn, labels;

    if (timeframe === 'day') {
        startTime = now - 24 * 60 * 60 * 1000;
        labels = [];
        for (let h = 0; h < 24; h += 4) {
            const d = new Date(now - (23 - h) * 60 * 60 * 1000);
            labels.push(d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
        }
        bucketFn = (ts) => {
            const hoursAgo = Math.floor((now - ts) / (60 * 60 * 1000));
            return Math.floor((23 - hoursAgo) / 4);
        };
    } else if (timeframe === 'week') {
        startTime = now - 7 * 24 * 60 * 60 * 1000;
        labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        bucketFn = (ts) => (new Date(ts).getDay() === 0 ? 6 : new Date(ts).getDay() - 1);
    } else {
        startTime = now - 28 * 24 * 60 * 60 * 1000;
        labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
        bucketFn = (ts) => 3 - Math.min(3, Math.floor((now - ts) / (7 * 24 * 60 * 60 * 1000)));
    }

    const deviceId = selectedStatsDeviceId;

    window.db.ref('audit_logs').orderByChild('timestamp').startAt(startTime).once('value', (snapshot) => {
        const buckets = new Array(labels.length).fill(0);
        let openCount = 0;
        let closeCount = 0;

        if (snapshot.exists()) {
            snapshot.forEach(child => {
                const log = child.val();
                const action = (log.action || '').toLowerCase();
                const desc = (log.description || '').toLowerCase();

                // Only count events for this specific device
                if ((action.includes('gate') || action.includes('flood')) && desc.includes(deviceId.toLowerCase())) {
                    const ts = log.timestamp || 0;
                    const idx = bucketFn(ts);
                    if (idx >= 0 && idx < buckets.length) {
                        buckets[idx]++;
                    }
                    if (desc.includes('opened') || desc.includes('open')) openCount++;
                    else if (desc.includes('closed') || desc.includes('close')) closeCount++;
                }
            });
        }

        if (historyChart) {
            historyChart.data.labels = labels;
            historyChart.data.datasets[0].data = buckets;
            historyChart.update();
        }

        if (doughnutChart) {
            doughnutChart.data.datasets[0].data = [openCount || 0, closeCount || 0];
            doughnutChart.update();
        }
    });
}

// ── Per-Device Recent Gate Events Table ───────────────────────────────────────

function loadDeviceRecentGateEvents(deviceId) {
    if (!window.db || !deviceId) return;

    window.db.ref('audit_logs').orderByChild('timestamp').limitToLast(100).on('value', (snapshot) => {
        const tbody = document.getElementById('recent-gate-events-tbody');
        if (!tbody) return;

        const events = [];
        if (snapshot.exists()) {
            snapshot.forEach(child => {
                const log = child.val();
                const action = (log.action || '').toLowerCase();
                const desc = (log.description || '').toLowerCase();
                // Only show events for this specific device
                if ((action.includes('gate') || action.includes('flood')) && desc.includes(deviceId.toLowerCase())) {
                    events.push(log);
                }
            });
        }

        events.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0));
        const recent = events.slice(0, 10);

        if (recent.length === 0) {
            tbody.innerHTML = '<tr><td colspan="3" class="empty-row">No gate events for this device</td></tr>';
            return;
        }

        tbody.innerHTML = recent.map(log => {
            const dt = new Date(log.timestamp || 0);
            const time = dt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            const date = `${dt.getMonth() + 1}/${dt.getDate()}`;
            const desc = (log.description || log.action || '').replace(/gate_hydrogate[-_]marikina/gi, 'HydroGate-Marikina');
            const user = log.email || log.user || 'System';
            const isClose = desc.toLowerCase().includes('closed');
            const badge = isClose
                ? '<span class="badge-danger" style="font-size:10px; padding:4px 8px;">CLOSED</span>'
                : '<span class="badge-success" style="font-size:10px; padding:4px 8px;">OPENED</span>';

            return `<tr>
                <td style="white-space:nowrap;">${time}<br><span style="font-size:11px;color:var(--text-secondary)">${date}</span></td>
                <td>${badge}</td>
                <td style="font-size:12px; max-width:150px; overflow:hidden; text-overflow:ellipsis;">${user}</td>
            </tr>`;
        }).join('');
    });
}

window.initStatistics = initStatistics;
