fx_version 'cerulean'
game 'gta5'

name 'srp_medical'
author 'Serious RP Medical System'
description 'Standalone advanced medical MVP for QBCore-first serious roleplay servers.'
version '0.1.0'
lua54 'yes'

ui_page 'nui/index.html'

shared_scripts {
    'config/config.lua',
    'shared/constants.lua',
    'shared/utils.lua',
    'shared/injuries.lua',
    'shared/treatments.lua'
}

client_scripts {
    'client/framework.lua',
    'client/main.lua',
    'client/ui.lua',
    'client/commands.lua'
}

server_scripts {
    'server/database.lua',
    'server/framework.lua',
    'server/inventory.lua',
    'server/permissions.lua',
    'server/state.lua',
    'server/reports.lua',
    'server/main.lua'
}

files {
    'nui/index.html',
    'nui/style.css',
    'nui/app.js'
}

provide 'srp_medical'
