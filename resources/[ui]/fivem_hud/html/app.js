const hud = document.getElementById('hud');

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === 'setVisible') {
        hud.style.display = data.visible ? 'flex' : 'none';
    }
});
