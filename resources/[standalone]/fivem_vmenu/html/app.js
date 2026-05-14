const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'fivem_vmenu';
const menu = document.querySelector('#menu');
const tabs = document.querySelectorAll('.tab');
const panels = document.querySelectorAll('.panel');

const post = (eventName, data = {}) => fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
});

const makeButton = (label, handler, className = '') => {
    const button = document.createElement('button');
    button.textContent = label;
    button.className = className;
    button.addEventListener('click', handler);
    return button;
};

const clear = (node) => {
    while (node.firstChild) {
        node.removeChild(node.firstChild);
    }
};

const renderConfig = (config) => {
    const playerModels = document.querySelector('#playerModels');
    const outfits = document.querySelector('#outfits');
    const components = document.querySelector('#components');
    const vehicleCategories = document.querySelector('#vehicleCategories');
    const colors = document.querySelector('#colors');
    const extras = document.querySelector('#extras');

    clear(playerModels);
    clear(outfits);
    clear(components);
    clear(vehicleCategories);
    clear(colors);
    clear(extras);

    config.playerModels.forEach((item) => {
        playerModels.appendChild(makeButton(item.label, () => post('setPlayerModel', { model: item.model })));
    });

    config.outfits.forEach((item, index) => {
        outfits.appendChild(makeButton(item.label, () => post('applyOutfit', { index: index + 1 })));
    });

    config.components.forEach((item) => {
        const row = document.createElement('div');
        row.className = 'component-row';

        const label = document.createElement('span');
        label.textContent = item.label;

        row.appendChild(label);
        row.appendChild(makeButton('-', () => post('cycleComponent', { component: item.id, direction: -1 })));
        row.appendChild(makeButton('+', () => post('cycleComponent', { component: item.id, direction: 1 })));
        components.appendChild(row);
    });

    config.vehicles.forEach((category) => {
        const heading = document.createElement('h3');
        const grid = document.createElement('div');

        heading.textContent = category.label;
        grid.className = 'grid';

        category.vehicles.forEach((vehicle) => {
            grid.appendChild(makeButton(vehicle.label, () => post('spawnVehicle', { model: vehicle.model })));
        });

        vehicleCategories.appendChild(heading);
        vehicleCategories.appendChild(grid);
    });

    config.colors.forEach((item) => {
        const button = makeButton(item.label, () => post('setVehicleColor', {
            primary: item.primary,
            secondary: item.secondary
        }), 'swatch');

        button.style.background = colorForLabel(item.label);
        colors.appendChild(button);
    });

    for (let extra = 1; extra <= 12; extra += 1) {
        extras.appendChild(makeButton(`Extra ${extra}`, () => post('toggleExtra', { extra })));
    }
};

const colorForLabel = (label) => {
    const colors = {
        Black: '#101418',
        White: '#dfe8ee',
        Red: '#b9272f',
        Blue: '#285ea8',
        Yellow: '#c89a22',
        Green: '#2c8b57'
    };

    return colors[label] || '#26343c';
};

tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
        tabs.forEach((item) => item.classList.remove('active'));
        panels.forEach((item) => item.classList.remove('active'));

        tab.classList.add('active');
        document.querySelector(`#${tab.dataset.tab}`).classList.add('active');
    });
});

document.querySelector('#close').addEventListener('click', () => post('close'));

document.querySelectorAll('[data-player-action]').forEach((button) => {
    button.addEventListener('click', () => post('playerAction', { action: button.dataset.playerAction }));
});

document.querySelectorAll('[data-vehicle-action]').forEach((button) => {
    button.addEventListener('click', () => post('vehicleAction', { action: button.dataset.vehicleAction }));
});

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.type === 'visible') {
        menu.classList.toggle('hidden', !data.visible);
    }

    if (data.type === 'config') {
        renderConfig(data);
    }
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('close');
    }
});

post('ready');
