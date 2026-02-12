fx_version 'cerulean'
game 'gta5'

author 'Grouse Labs'
description 'Jewellery Heist for FiveM with Multiple Stores, New Hacks & Auto Door Lock Features'
version '2.0.0'
url 'https://github.com/grouse-labs/gr_jewellery'

shared_scripts {'@gr_lib/init.lua', '@bridge/init.lua'}

client_script 'client/main.lua'

server_script 'server/main.lua'

files {'shared/*.lua', 'client/config.lua', 'locales/*.lua'}

dependencies {'/onesync', 'gr_lib', 'gr_blips', 'bridge'}

lua54 'yes'
