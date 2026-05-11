fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'FiveM Server Team'
description 'Custom V menu for player customization, vehicle spawning, and vehicle modification'
version '0.1.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/**/*.lua'
}

server_scripts {
    'server/**/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/app.js'
}
