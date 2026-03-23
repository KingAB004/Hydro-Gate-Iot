// ===== Statistics & Analytics Logic =====

let liveChart;
let historyChart;
const maxDataPoints = 20;
let waterLevelHistory = [];
let timeLabels = [];

function initStatistics() {
    console.log('Initializing Statistics...');
    initLiveChart();
    initHistoryChart();
    setupTimeframeButtons();
    listenToWaterLevelChanges();
}

function initLiveChart() {
    const ctx = document.getElementById('liveWaterLevelChart').getContext('2d');
    
    // Gradient for the line
    const gradient = ctx.createLinearGradient(0, 0, 0, 400);
    gradient.addColorStop(0, 'rgba(0, 126, 170, 0.4)');
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
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    max: 2.0,
                    grid: { color: 'rgba(0,0,0,0.05)' },
                    ticks: { callback: value => value + 'm' }
                },
                x: {
                    grid: { display: false }
                }
            },
            interaction: {
                intersect: false,
                mode: 'index',
            }
        }
    });
}

function initHistoryChart() {
    const ctx = document.getElementById('historicalWaterLevelChart').getContext('2d');
    historyChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            datasets: [{
                label: 'Avg Water Level',
                data: [0.4, 0.5, 0.8, 1.2, 0.6, 0.3, 0.4],
                backgroundColor: 'rgba(0, 126, 170, 0.8)',
                borderRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: { color: 'rgba(0,0,0,0.05)' }
                },
                x: {
                    grid: { display: false }
                }
            }
        }
    });
}

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

function updateHistoricalData(timeframe) {
    let data = [];
    let labels = [];
    
    if (timeframe === 'day') {
        labels = ['6am', '9am', '12pm', '3pm', '6pm', '9pm'];
        data = [0.2, 0.3, 0.5, 0.8, 0.4, 0.3];
    } else if (timeframe === 'week') {
        labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        data = [0.4, 0.5, 0.8, 1.2, 0.6, 0.3, 0.4];
    } else if (timeframe === 'month') {
        labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
        data = [0.5, 0.9, 0.4, 0.6];
    }

    historyChart.data.labels = labels;
    historyChart.data.datasets[0].data = data;
    historyChart.update();
}

function listenToWaterLevelChanges() {
    if (!window.db) return;

    window.db.ref('flood_monitoring').on('value', (snapshot) => {
        const data = snapshot.val();
        if (data && data.water_level_m !== undefined) {
            updateLiveChart(data.water_level_m);
        }
    });
}

function updateLiveChart(value) {
    const now = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    
    waterLevelHistory.push(value);
    timeLabels.push(now);

    if (waterLevelHistory.length > maxDataPoints) {
        waterLevelHistory.shift();
        timeLabels.shift();
    }

    if (liveChart) {
        liveChart.update('none'); // Update without animation for smoother real-time look
    }
}

window.initStatistics = initStatistics;
