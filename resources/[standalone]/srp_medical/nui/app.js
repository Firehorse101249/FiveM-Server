const app = document.getElementById('app');
const toast = document.getElementById('toast');

const state = {
    patient: null,
    provider: null,
    config: {},
    selectedBody: 'chest',
    selectedInjury: null
};

function resourceName() {
    if (typeof GetParentResourceName === 'function') return GetParentResourceName();
    return 'srp_medical';
}

async function nui(name, payload = {}) {
    const response = await fetch(`https://${resourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    });
    return response.json();
}

function showToast(message) {
    toast.textContent = message || 'Done';
    toast.classList.remove('hidden');
    setTimeout(() => toast.classList.add('hidden'), 3200);
}

function pretty(value) {
    return String(value || '').replaceAll('_', ' ');
}

function bodyLabel(part) {
    return state.config.bodyParts?.[part]?.label || pretty(part);
}

function injuryArray() {
    if (!state.patient?.injuries) return [];
    return Object.values(state.patient.injuries);
}

function activeInjuries() {
    return injuryArray().filter(injury => injury.treatmentStatus !== 'resolved');
}

function renderHeader() {
    const patient = state.patient || {};
    const vitals = patient.vitals || {};
    const injuries = activeInjuries();
    const bleeding = injuries.reduce((total, injury) => total + Number(injury.bleeding || 0), 0);

    document.getElementById('patientName').textContent = patient.name || 'Unknown Patient';
    document.getElementById('stage').textContent = pretty(patient.stage || 'healthy');
    document.getElementById('pain').textContent = vitals.pain ?? 0;
    document.getElementById('bleeding').textContent = bleeding;
    document.getElementById('oxygen').textContent = `${vitals.oxygen ?? 98}%`;
    document.getElementById('providerRole').textContent = state.provider?.role?.label || 'Provider';
}

function renderVitals() {
    const vitals = state.patient?.vitals || {};
    document.getElementById('vHr').textContent = vitals.heartRate ?? 78;
    document.getElementById('vBp').textContent = `${vitals.systolic ?? 122}/${vitals.diastolic ?? 78}`;
    document.getElementById('vSpo2').textContent = vitals.oxygen ?? 98;
    document.getElementById('vBlood').textContent = vitals.bloodVolume ?? 100;
    document.getElementById('vLoc').textContent = vitals.consciousness ?? 100;
    document.getElementById('vGlucose').textContent = vitals.glucose ?? 96;
}

function injuryCard(injury) {
    const item = document.createElement('button');
    item.className = 'list-item';
    item.dataset.injury = injury.id;
    item.innerHTML = `
        <strong>${injury.label || pretty(injury.type)} - ${pretty(injury.severity)}</strong>
        <span>${bodyLabel(injury.bodyPart)} | bleed ${injury.bleeding || 0} | pain ${injury.pain || 0} | ${pretty(injury.treatmentStatus || 'untreated')}</span>
    `;
    item.addEventListener('click', () => {
        state.selectedInjury = injury.id;
        state.selectedBody = injury.bodyPart;
        switchTab('treatment');
        render();
    });
    return item;
}

function renderInjuries() {
    const list = document.getElementById('injuryList');
    list.innerHTML = '';
    const injuries = activeInjuries();
    if (!injuries.length) {
        list.innerHTML = '<div class="list-item"><strong>No active injuries</strong><span>Patient currently appears stable.</span></div>';
        return;
    }
    injuries.forEach(injury => list.appendChild(injuryCard(injury)));
}

function renderLogs() {
    const list = document.getElementById('logList');
    const logs = state.patient?.treatmentLog || [];
    list.innerHTML = '';
    if (!logs.length) {
        list.innerHTML = '<div class="list-item"><strong>No treatment log</strong><span>Assessments and treatments will appear here.</span></div>';
        return;
    }
    logs.slice(-20).reverse().forEach(log => {
        const item = document.createElement('div');
        item.className = 'list-item';
        const time = log.createdAt ? new Date(log.createdAt * 1000).toLocaleTimeString() : '';
        item.innerHTML = `<strong>${pretty(log.treatment)} - ${pretty(log.result)}</strong><span>${time} ${log.providerName || ''}<br>${log.notes || ''}</span>`;
        list.appendChild(item);
    });
}

function renderAssessments() {
    const wrap = document.getElementById('assessmentTools');
    wrap.innerHTML = '';
    Object.entries(state.config.assessments || {}).forEach(([id, tool]) => {
        const btn = document.createElement('button');
        btn.innerHTML = `<strong>${tool.label}</strong><small>${tool.cert ? `Cert: ${pretty(tool.cert)}` : 'No cert required'}</small>`;
        btn.addEventListener('click', () => performAssessment(id));
        wrap.appendChild(btn);
    });
}

function renderBody() {
    document.querySelectorAll('.region').forEach(btn => {
        const part = btn.dataset.body;
        btn.classList.toggle('selected', part === state.selectedBody);
        btn.classList.toggle('has-injury', activeInjuries().some(injury => injury.bodyPart === part));
    });

    document.getElementById('selectedBodyTitle').textContent = bodyLabel(state.selectedBody);
    const list = document.getElementById('bodyInjuries');
    list.innerHTML = '';
    const matches = activeInjuries().filter(injury => injury.bodyPart === state.selectedBody);
    if (!matches.length) {
        list.innerHTML = '<div class="list-item"><strong>No visible injury</strong><span>Use full body scan or trauma assessment if needed.</span></div>';
        return;
    }
    matches.forEach(injury => list.appendChild(injuryCard(injury)));
}

function renderTreatmentSelect() {
    const select = document.getElementById('injurySelect');
    const current = state.selectedInjury;
    select.innerHTML = '<option value="">Select active injury</option>';
    activeInjuries().forEach(injury => {
        const option = document.createElement('option');
        option.value = injury.id;
        option.textContent = `${injury.label} - ${bodyLabel(injury.bodyPart)} - ${pretty(injury.severity)}`;
        select.appendChild(option);
    });
    select.value = current || '';
}

function treatmentMatches(treatment, injury) {
    if (!injury) return true;
    if (treatment.bodyParts !== 'all' && Array.isArray(treatment.bodyParts) && !treatment.bodyParts.includes(injury.bodyPart)) return false;
    if (Array.isArray(treatment.treats) && (treatment.treats.includes('all') || treatment.treats.includes(injury.type))) return true;
    if (Array.isArray(treatment.treats) && treatment.treats.includes('pain') && Number(injury.pain || 0) > 25) return true;
    return false;
}

function renderTreatments() {
    const selected = activeInjuries().find(injury => injury.id === state.selectedInjury);
    const recommended = document.getElementById('recommendedActions');
    const tools = document.getElementById('treatmentTools');
    recommended.innerHTML = '';
    tools.innerHTML = '';

    const matches = Object.entries(state.config.treatments || {}).filter(([, treatment]) => treatmentMatches(treatment, selected));
    matches.slice(0, 4).forEach(([id, treatment]) => {
        const item = document.createElement('div');
        item.className = 'recommendation';
        item.textContent = selected ? `${treatment.label} may help ${selected.label} on ${bodyLabel(selected.bodyPart)}.` : `${treatment.label} available.`;
        recommended.appendChild(item);
    });

    Object.entries(state.config.treatments || {}).forEach(([id, treatment]) => {
        const btn = document.createElement('button');
        const match = treatmentMatches(treatment, selected);
        btn.innerHTML = `<strong>${treatment.label}</strong><small>${treatment.item ? `Item: ${treatment.item}` : 'No item'} | ${treatment.requiredCert ? pretty(treatment.requiredCert) : 'open'}</small>`;
        btn.disabled = !match && Boolean(selected);
        btn.addEventListener('click', () => performTreatment(id));
        tools.appendChild(btn);
    });
}

function renderCerts() {
    const role = state.provider?.role || {};
    document.getElementById('providerSummary').innerHTML = `<strong>${state.provider?.name || 'Provider'}</strong><span>${role.label || role.role || 'Civilian'}</span>`;
    const list = document.getElementById('certList');
    list.innerHTML = '';
    const certs = state.provider?.certifications || {};
    const allCerts = new Set([...Object.keys(state.config.treatments || {}).flatMap(id => {
        const cert = state.config.treatments[id].requiredCert;
        return cert ? [cert] : [];
    }), ...Object.keys(certs)]);

    allCerts.forEach(cert => {
        const item = document.createElement('div');
        item.className = 'cert';
        item.innerHTML = `<strong>${pretty(cert)}</strong><span>${certs[cert] ? `Level ${certs[cert]}` : 'Not certified'}</span>`;
        list.appendChild(item);
    });
}

async function performAssessment(id) {
    const response = await nui('performAssessment', { target: state.patient?.source, assessment: id });
    if (response.ok) {
        state.patient = response.patient || state.patient;
        showToast(response.message);
        render();
    } else {
        showToast(response.message || 'Assessment failed.');
    }
}

async function performTreatment(id) {
    const selected = activeInjuries().find(injury => injury.id === state.selectedInjury);
    const response = await nui('performTreatment', {
        target: state.patient?.source,
        treatment: id,
        injuryId: selected?.id,
        bodyPart: selected?.bodyPart || state.selectedBody
    });
    if (response.ok) {
        state.patient = response.patient || state.patient;
        showToast(response.message || 'Treatment complete.');
        render();
    } else {
        showToast(response.message || 'Treatment failed.');
    }
}

async function refreshPatient() {
    const response = await nui('refreshPatient', { target: state.patient?.source });
    if (response.ok) {
        state.patient = response.patient;
        state.provider = response.provider || state.provider;
        render();
    }
}

async function loadHistory() {
    const response = await nui('getHistory', { target: state.patient?.source });
    const list = document.getElementById('historyList');
    list.innerHTML = '';
    if (!response.ok || !response.history?.length) {
        list.innerHTML = '<div class="list-item"><strong>No medical history</strong><span>No SQL reports were found.</span></div>';
        return;
    }
    response.history.forEach(row => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `<strong>${row.created_at || ''} - ${row.outcome || 'Report'}</strong><span>${row.provider_name || ''} | ${row.department || ''}<br>${row.narrative || ''}</span>`;
        list.appendChild(item);
    });
}

async function saveReport() {
    const response = await nui('createReport', {
        target: state.patient?.source,
        destination: document.getElementById('reportDestination').value,
        outcome: document.getElementById('reportOutcome').value,
        medications: document.getElementById('reportMeds').value.split(',').map(v => v.trim()).filter(Boolean),
        narrative: document.getElementById('reportNarrative').value
    });
    showToast(response.message || (response.ok ? 'Report saved.' : 'Unable to save report.'));
}

async function automatedRecovery() {
    const response = await nui('automatedRecovery', { target: state.patient?.source });
    showToast(response.message || 'Recovery request sent.');
    if (response.patient) {
        state.patient = response.patient;
        render();
    }
}

function switchTab(tabId) {
    document.querySelectorAll('.tab').forEach(btn => btn.classList.toggle('active', btn.dataset.tab === tabId));
    document.querySelectorAll('.panel').forEach(panel => panel.classList.toggle('active', panel.id === tabId));
}

function render() {
    renderHeader();
    renderVitals();
    renderInjuries();
    renderLogs();
    renderAssessments();
    renderBody();
    renderTreatmentSelect();
    renderTreatments();
    renderCerts();
}

document.querySelectorAll('.tab').forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

document.querySelectorAll('.region').forEach(btn => {
    btn.addEventListener('click', () => {
        state.selectedBody = btn.dataset.body;
        state.selectedInjury = activeInjuries().find(injury => injury.bodyPart === state.selectedBody)?.id || null;
        render();
    });
});

document.getElementById('injurySelect').addEventListener('change', event => {
    state.selectedInjury = event.target.value || null;
    const injury = activeInjuries().find(item => item.id === state.selectedInjury);
    if (injury) state.selectedBody = injury.bodyPart;
    render();
});

document.getElementById('closeBtn').addEventListener('click', () => nui('close'));
document.getElementById('refreshBtn').addEventListener('click', refreshPatient);
document.getElementById('loadHistoryBtn').addEventListener('click', loadHistory);
document.getElementById('saveReportBtn').addEventListener('click', saveReport);
document.getElementById('automatedRecoveryBtn').addEventListener('click', automatedRecovery);

document.querySelectorAll('[data-hospital-action]').forEach(btn => {
    btn.addEventListener('click', () => showToast(`${pretty(btn.dataset.hospitalAction)} logged locally. Use treatments or automated recovery to change patient state.`));
});

window.addEventListener('message', event => {
    const data = event.data || {};
    if (data.action === 'open') app.classList.remove('hidden');
    if (data.action === 'close') app.classList.add('hidden');
    if (data.action === 'tab') switchTab(data.tab);
    if (data.action === 'hydrate') {
        state.patient = data.patient;
        state.provider = data.provider;
        state.config = data.config || {};
        state.selectedInjury = activeInjuries()[0]?.id || null;
        state.selectedBody = activeInjuries()[0]?.bodyPart || 'chest';
        app.classList.remove('hidden');
        render();
    }
    if (data.action === 'stateUpdated' && state.patient && data.state?.source === state.patient.source) {
        state.patient = data.state;
        render();
    }
});

document.addEventListener('keydown', event => {
    if (event.key === 'Escape') nui('close');
});
