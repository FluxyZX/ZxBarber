fx_version "cerulean"

game 'gta5'

author 'FluxyZX'

-----------------------------------------------------------
--                       ZxBarber Leak                         --
-----------------------------------------------------------

shared_scripts {
    "config.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/server.lua"
}

client_scripts {
    "src/RageUI.lua",
    "src/Menu.lua",
    "src/MenuController.lua",
    "src/components/*.lua",
    "src/elements/*.lua",
    "src/items/*.lua",
    "src/panels/*.lua",
    "client/client.lua"
}

dependencies {
    "oxmysql",
    "esx_skin",
    "skinchanger"
}
