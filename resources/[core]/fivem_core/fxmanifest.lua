fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'FiveM Server Team'
description 'Main custom server core'
version '0.1.0'

shared_scripts {
    'config.lua',
    'shared/**/*.lua'
}

client_scripts {
    'client/**/*.lua'
}

server_scripts {
    'server/**/*.lua'
}
