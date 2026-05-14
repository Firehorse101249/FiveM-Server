const els = document.getElementById('els');
const closeButton = document.getElementById('close');
const vehicleStatus = document.getElementById('vehicleStatus');
const focusStatus = document.getElementById('focusStatus');
const lightStages = document.getElementById('lightStages');
const tones = document.getElementById('tones');
const sirenToggle = document.getElementById('sirenToggle');
const nextTone = document.getElementById('nextTone');
const manual = document.getElementById('manual');
const airhorn = document.getElementById('airhorn');

let resourceName = 'fivem_els';
let state = {
    lights: 1,
    siren: false,
    tone: 1,
    manual: false,
    airhorn: false
};
let available = false;
let toneCount = 0;

if (typeof GetParentResourceName === 'function') {
    resourceName = GetParentResourceName();
}

function post(action, body = {}) {
    return fetch(`https://${resourceName}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(body)
    });
}

function setDisabled() {
    const controls = els.querySelectorAll('button:not(#close)');

    controls.forEach((control) => {
        control.disabled = !available;
    });
}

function renderStages(stages = []) {
    lightStages.innerHTML = '';

    stages.forEach((stage, index) => {
        const button = document.createElement('button');
        button.className = 'stage';
        button.type = 'button';
        button.textContent = stage.label || `Stage ${index}`;
        button.addEventListener('click', () => post('setLights', { stage: index + 1 }));
        lightStages.appendChild(button);
    });
}

function renderTones(items = []) {
    toneCount = items.length;
    tones.innerHTML = '';

    items.forEach((tone, index) => {
        const button = document.createElement('button');
        button.className = 'tone';
        button.type = 'button';
        button.textContent = tone.label || `Tone ${index + 1}`;
        button.addEventListener('click', () => post('setTone', { tone: index + 1 }));
        tones.appendChild(button);
    });
}

function updateState(nextState) {
    state = { ...state, ...nextState };

    lightStages.querySelectorAll('.stage').forEach((button, index) => {
        button.classList.toggle('is-active', state.lights === index + 1);
    });

    tones.querySelectorAll('.tone').forEach((button, index) => {
        button.classList.toggle('is-active', state.tone === index + 1);
    });

    sirenToggle.classList.toggle('is-active', state.siren);
    sirenToggle.textContent = state.siren ? 'Siren On' : 'Siren Off';
    manual.classList.toggle('is-active', state.manual);
    airhorn.classList.toggle('is-active', state.airhorn);
}

function setMomentary(button, key, enabled) {
    button.classList.toggle('is-active', enabled);
    post('setMomentary', { key, enabled });
}

closeButton.addEventListener('click', () => post('close'));

sirenToggle.addEventListener('click', () => {
    post('toggleSiren', { enabled: !state.siren });
});

nextTone.addEventListener('click', () => {
    const nextToneIndex = state.tone + 1 > toneCount ? 1 : state.tone + 1;
    post('setTone', { tone: nextToneIndex });
});

[
    [manual, 'manual'],
    [airhorn, 'airhorn']
].forEach(([button, key]) => {
    button.addEventListener('pointerdown', () => setMomentary(button, key, true));
    button.addEventListener('pointerup', () => setMomentary(button, key, false));
    button.addEventListener('pointerleave', () => setMomentary(button, key, false));
});

window.addEventListener('keyup', (event) => {
    if (event.key === 'Escape') {
        post('close');
    }
});

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === 'visible') {
        els.classList.toggle('is-visible', data.visible);
    }

    if (data.type === 'state') {
        available = data.available === true;
        els.classList.toggle('is-visible', data.visible);
        vehicleStatus.textContent = available ? 'Emergency vehicle ready' : 'No emergency vehicle';
        focusStatus.textContent = data.focused ? 'Mouse active' : 'F7 mouse';

        if (data.lightStages) {
            renderStages(data.lightStages);
        }

        if (data.tones) {
            renderTones(data.tones);
        }

        updateState(data.state || {});
        setDisabled();
    }
});
