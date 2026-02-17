# gr_jewellery — Free FiveM Jewellery Robbery Script

<a href="https://youtu.be/Gzq6njJgyhY" target="_blank">
  <img src="https://github.com/grouse-labs/.github/blob/main/profile/assets/jewellery_thumbnail.png?raw=true" style="width:640px;height:360px;" alt="Patrols Thumbnail">
</a>

---

**gr_jewellery** is a fully featured, performance-focused **Jewellery Heist system for FiveM**, designed with immersion, configurability, and server stability in mind.

Rob multiple stores, trigger dynamic alarm systems, disable power with thermite, hack security networks, and manage door locks with fully server-side control. Built to feel alive and reactive — without sacrificing performance.

---

## Key Features

- ⚡ **Highly Optimised**
  - 0.00ms idle  
  - 0.01–0.02ms during animations or lock state changes  
  - Designed for stable long-term server performance  

- 🏬 **Multiple Store Support**
  - 3 stores preconfigured (using [GigZ Jewel Store](https://forum.cfx.re/t/mlo-jewel-store-by-gigz/4857261))  
  - Easily expandable for additional locations  

- 🔐 **Advanced Lock & Alarm System**
  - Unique cooldowns for:
    - Individual display cases  
    - Store alarms  
    - Store door locks  
  - Fully server-side door control  
  - Automatic door locking at configurable times  

- 🚨 **Dynamic Alarm Behaviour**
  - Multiple alarms per store  
  - Synced sirens and emergency lighting  
  - 🔴 Map blips flash while alarms are active  
  - 🕒 Time-of-day based alert trigger chances  
  - 🗺️ Blips visually indicate store state (reduced opacity when closed)  
  - Configurable alert ranges  

- 🔥 **Thermite Power Sabotage**
  - Disable store power using thermite  
  - Unlocks the main locked entrance  
  - Disables the active alarm system  
  - Fully synced visual and particle effects  
  - Adds a high-risk, high-reward escalation option
  - Easily adaptable to custom minigames

- 💻 **Security System Hacking**
  - Hack the store computer for additional advantages  
  - Built-in `alarmdisable` functionality (default for LEO)  
  - Easily adaptable to custom minigames  

- 💎 **Immersive Glass Effects**
  - Destroyed display models  
  - Glass particle effects  
  - Native GTA sound effects  
  - Fully synced between all players at all times  

- 🧩 **Minigame Flexibility**
  - Pre-configured for [Glitch Minigames](https://github.com/Gl1tchStudios/glitch-minigames)  
  - Easily replaceable with any minigames resource via the client config  

- 📡 **Dispatch & Alert Integration**
  - Fully configurable dispatch alerts  
  - Customisable via client config and locale files

- 👮‍♂️ **Grouse Patrols Integration**
  - Includes a preconfigured patrol setup
  - Seamlessly escalates robberies with AI patrol units

## Table of Contents

- [gr\_jewellery — Free FiveM Jewellery Robbery Script](#gr_jewellery--free-fivem-jewellery-robbery-script)
  - [Key Features](#key-features)
  - [Table of Contents](#table-of-contents)
    - [Credits](#credits)
    - [Preview](#preview)
    - [Installation](#installation)
      - [Dependencies](#dependencies)
        - [Minigames](#minigames)
        - [Grouse](#grouse)
        - [Server Specific](#server-specific)
      - [Initial Setup](#initial-setup)
    - [Translations](#translations)
    - [Store MLO's](#store-mlos)
    - [Configuration](#configuration)
      - [Creating Stores](#creating-stores)
      - [Adding Cases](#adding-cases)
      - [Server Config](#server-config)
      - [Patrols](#patrols)
      - [Client Config](#client-config)
      - [Doorlock Presets](#doorlock-presets)
        - [qb-doorlock](#qb-doorlock)
        - [ox\_doorlock](#ox_doorlock)
    - [Support](#support)

### Credits

- [Holiday95](https://github.com/Holidayy95/qb-jewelery)
- [QBCore Framework](https://github.com/qbcore-framework)
- [MrNewb](https://github.com/MrNewb)

### Preview

- [YouTube Preview](https://youtu.be/Gzq6njJgyhY)

### Installation

#### Dependencies

**This script requires the following scripts to be installed:**

##### Minigames

**Minigame resources can be configured in [client config](#client-config), by default Glitch Minigames is configured.**

- [glitch_minigames](https://github.com/Gl1tchStudios/glitch-minigames/releases/tag/v2.0.0)

##### Grouse

- [gr_lib](https://github.com/grouse-labs/gr_lib/releases/latest)
- [bridge](https://github.com/grouse-labs/bridge/releases/latest)
- [gr_blips](https://github.com/grouse-labs/gr_blips/releases/latest)

##### Server Specific

*Please note, weather resources are optional dependencies.*

| Framework   | Callback | Target    | Notify      | Doorlock    | Weather             |
| ----------- | -------- | --------- | ----------- | ----------- | ------------------- |
| qb-core     | ox_lib   | ox_target | qb-core     | ox_doorlock | Renewed-Weathersync |
| es_extended | gr_lib   | qb-target | es_extended | qb-doorlock | qb-weathersync      |
| qbx_core    |          |           |             |             |                     |

| Resource                                                                      | Version |
| :---------------------------------------------------------------------------- | :-----: |
| [qb-core](https://github.com/qbcore-framework/qb-core)                        | 1.3.0   |
| [es_extended](https://github.com/esx-framework/esx_core)                      | 1.13.4  |
| [qbx_core](https://github.com/Qbox-project/qbx_core)                          | 1.23.0  |
| [ox_lib](https://github.com/CommunityOx/ox_lib)                               | 3.30.6  |
| [gr_lib](https://github.com/grouse-labs/gr_lib)                               | 1.1.3   |
| [ox_inventory](https://github.com/CommunityOx/ox_inventory)                   | 2.44.8  |
| [qb-inventory](https://github.com/qbcore-framework/qb-inventory)              | 2.0.0   |
| [ox_target](https://github.com/CommunityOx/ox_target)                         | 1.17.2  |
| [qb-target](https://github.com/qbcore-framework/qb-target)                    | 5.5.0   |
| [ox_doorlock](https://github.com/CommunityOx/ox_doorlock)                     | 1.21.0  |
| [qb-doorlock](https://github.com/qbcore-framework/qb-doorlock)                | 2.0.0   |
| [Renewed-Weathersync](https://github.com/Renewed-Scripts/Renewed-Weathersync) | 1.1.8   |
| [qb-weathersync](https://github.com/qbcore-framework/qb-weathersync)          | 2.1.1   |

**Note:** [TheOrderFiveM](https://github.com/TheOrderFivem)'s version of [ox_doorlock](https://github.com/TheOrderFivem/ox_doorlock) has been tested and is also **compatible**, regardless of version warnings.

#### Initial Setup

- Always use the reccomended FiveM artifacts, last tested on [23683](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/).
- Download the latest version from [releases](https://github.com/grouse-labs/gr_jewellery/releases/latest).
- Extract the contents of the zip file into your resources folder, into a folder which starts after your framework or;
- Ensure the script in your `server.cfg` after your framework.

### Translations

- Please open an issue for translations, I'll add them in a following update.

### Store MLO's

All store locations are for [GigZ Jewel Store](https://forum.cfx.re/t/mlo-jewel-store-by-gigz/4857261)' except for the base GTA one. It's a free map, but **MAKE SURE TO INSTALL THE HEIST VERSION**.

<!-- - If you're using these MLO's, place interiorproxies.meta in the gigz_jewel_free_heist folder and edit it's fxmanifest to the following:

```lua
files {"interiorproxies.meta"}
    
data_file 'INTERIOR_PROXY_ORDER_FILE' 'interiorproxies.meta'
``` -->

### Configuration

#### Creating Stores

- To create a new location, you need to add a table to the table in the [store_locations](shared\store_locations.lua) file.

```lua
main = {
  coords = vector3(-630.5, -237.13, 38.08),
  doors = {'jewellery-citymain', 'jewellery-citysec'},
  police = 0,
  interior_id = 82690,
  alarms = {
    coords = {vector3(-625.25, -237.57, 41.17), vector3(-629.52, -231.68, 41.17), vector3(-620.44, -225.08, 41.18), vector3(-616.16, -230.97, 41.18)},
    sound = {
      bank = 'ALARM_BELL_02',
      name = 'Bell_02',
      ref = 'ALARMS_SOUNDSET'
    },
    range = 100.0
  },
  thermite = {
    coords = vector3(-596.02, -283.7, 50.4),
    heading = 300.0,
    size = vector3(0.4, 0.8, 1.2)
  },
  hack = {
    coords = vector3(-631.04, -230.63, 38.06),
    heading = 37.0,
    size = vector3(0.4, 0.6, 1.0)
  }
}
```

**Note:** Each location table is declared as a named table, and there must be a corresonding table in the [jewellery_cases](shared\jewellery_cases.lua) file.

- `coords: vector3` - The coords for the store blip.
- `doors: string[]` - The doors to the store, where index 1 is the main and index 2 is the secondary.
- `police: integer` - How much police much be present to trigger the heist.
- `interior_id: integer` - The interior id of the store, used for the store closing warning.
- `alarms: {coords: vector3|vector3[], sound: {bank: string, name: string, ref: string}}` - Config for the sounds, locations and range.
- `thermite: {coords: vector3, heading: number, size: vector3}`- Config for the targets and animations.
- `hack: {coords: vector3, heading: number, size: vector3}`- Config for the targets and animations.

#### Adding Cases

```lua
main = {
  {
    coords = vector3(-627.21, -234.89, 37.65),
    heading = 36.0,
    start_prop = hash_case_start_3,
    end_prop = hash_case_end_3,
    cams = {44, 45}
  }
}
```

- `coords: vector3` - The coords of the cabinet.
- `heading: number`
- `start_prop: integer`
- `end_prop: integer`
- `cams: integer|integer[]` - Camera IDs (if used) for dispatch alerts.

#### Server Config

```lua
{
  cooldowns = {
    locks = 5,
    cases = 10,
    alarm = 5
  },
  autolock = true,
  patrols = {
    enable = false,
    name = 'gr_patrols'
  },
  hours = {
    open = 9,
    close = 17
  },
  rewards = {
    {item = 'rolex', amount = 1},
    {item = 'diamond_ring', amount = {min = 1, max = 4}},
    {item = 'goldchain', amount = {min = 1, max = 4}}
  }
}
```

- `cooldowns: {locks: integer, cases: integer, alarm: integer}` - Cooldown in minutes before reset.
- `autolock: boolean` - Disable/enable the serverside time locked functionality.
- `patrols: {enable: boolean, name: string}` - Enable patrols created from [Grouse Patrols](https://youtu.be/HnPzlaKyBp8?si=VXNGA_lXpBW0fuZz).
- `hours: {open: integer, close: integer}`- In 24 hour time.
- `rewards: {item: string, amount: integer|{min: integer, max: integer}}`- Possible rewards and amounts for a successful case smashed.

#### Patrols

**Please Refer to [Grouse Patrols README](https://github.com/grouse-labs/gr_patrols)**

#### Client Config

```lua
{
  minigames = {
    thermite = {
      resource = 'glitch-minigames',
      export = 'StartMemoryGame',
      settings = {5, 4, 3, 3000, 10}
    },
    hack = {
      resource = 'glitch-minigames',
      export = 'StartPipePressureGame',
      settings = {6, 30000}
    }
  },
  dispatch = {
    event = true,
    name = 'police:server:policeAlert', -- if event is false, it's uses the exports defined below from this resource. ie 'ps-dispatch'
    suss = {
      export = false -- 'SuspiciousActivity' for exports['ps-dispatch']:SuspiciousActivity()
    },
    case = {
      export = false
    },
    thermite = {
      export = false
    }
  },
  weapons = {
    'weapon_assaultrifle',
    'weapon_carbinerifle',
    'weapon_pumpshotgun',
    'weapon_sawnoffshotgun',
    'weapon_compactrifle',
    'weapon_autoshotgun',
    'weapon_crowbar',
    'weapon_pistol',
    'weapon_pistol_mk2',
    'weapon_combatpistol',
    'weapon_appistol',
    'weapon_pistol50',
    'weapon_microsmg',
  }
}
```

- `minigames: table`
  - `{thermite: {resource: string, export: string, settings: any[]}` - Please refer to your preferred minigames resource documentation.
    - `resource: string` - Resource name.
    - `export: string` - Export name.
    - `settings: any[]` - Parameters to pass to the above export, in the order they are defined in the exports documenation.
  - `{hack: {resource: string, export: string, settings: any[]}` - Please refer to your preferred minigames resource documentation.
    - `resource: string` - Resource name.
    - `export: string` - Export name.
    - `settings: any[]` - Parameters to pass to the above export, in the order they are defined in the exports documenation.
- `dispatch: table`
  - `event: boolean` - Whether your preferred dispatch script uses an event or exports.
  - `name: string` - Either the event name or export resource name.
  - `{suss: {export: boolean}}`
  - `{case: {export: boolean}}`
  - `{thermite: {export: boolean}}`
- `weapons: string[]` - Weapons allowed to smash a case.

#### Doorlock Presets

##### qb-doorlock

```lua
Config.DoorList['jewellery-citymain'] = {
  doorType = 'double',
  locked = true,
  cantUnlock = true,
  doorLabel = 'main',
  distance = 2,
  doors = {
    {objName = 9467943, objYaw = 306.00003051758, objCoords = vec3(-630.426514, -238.437546, 38.206532)},
    {objName = 1425919976, objYaw = 306.00003051758, objCoords = vec3(-631.955383, -236.333267, 38.206532)}
  },
  doorRate = 1.0,
}

Config.DoorList['jewellery-citysec'] = {
  objYaw = 36.000022888184,
  doorRate = 1.0,
  locked = true,
  fixText = false,
  pickable = true,
  authorizedJobs = { ['police'] = 0 },
  needsAllItems = false,
  objCoords = vec3(-629.133850, -230.151703, 38.206585),
  distance = 2.5,
  doorType = 'door',
  objName = 1335309163,
}

Config.DoorList['jewellery-grapemain'] = {
  doorType = 'double',
  locked = true,
  cantUnlock = true,
  doorLabel = 'main',
  distance = 2,
  doors = {
    {objName = 9467943, objYaw = 98.17839050293, objCoords = vec3(1653.285522, 4884.148438, 42.309845)},
    {objName = 1425919976, objYaw = 98.17839050293, objCoords = vec3(1653.655518, 4881.573730, 42.309845)}
  },
  doorRate = 1.0,
}

Config.DoorList['jewellery-grapesec'] = {
  pickable = true,
  objCoords = vec3(1648.274902, 4877.423340, 42.309898),
  objName = 1335309163,
  doorRate = 1.0,
  distance = 2.5,
  authorizedJobs = { ['police'] = 0 },
  doorType = 'door',
  objYaw = 188.17839050293,
  fixText = false,
  doorLabel = 'sec',
  locked = true,
}

Config.DoorList['jewellery-palmain'] = {
  doorType = 'double',
  locked = true,
  cantUnlock = true,
  doorLabel = 'main',
  distance = 2,
  doors = {
    {objName = 1425919976, objYaw = 314.90930175781, objCoords = vec3(-383.837921, 6044.059082, 31.658920)},
    {objName = 9467943, objYaw = 314.90930175781, objCoords = vec3(-382.001617, 6042.216797, 31.658920)}
  },
  doorRate = 1.0,
}

Config.DoorList['jewellery-palsec'] = {
  doorType = 'door',
  locked = true,
  doorRate = 1.0,
  pickable = true,
  distance = 2.5,
  objYaw = 44.909275054932,
  fixText = false,
  authorizedJobs = { ['police'] = 0 },
  objCoords = vec3(-382.007721, 6050.603027, 31.658974),
  objName = 1335309163,
}
```

##### ox_doorlock

If using a default Qbox server, the main Vangelico store door will already be configured as `vangelico_jewellery`, so you only need to add the other 5 doors. You can change the door names as you like, just make sure to update the store_locations file accordingly.

![ox_doorlock config example](https://github.com/grouse-labs/.github/blob/main/profile/assets/jewellery_ox_doorlock.png?raw=true)

Create a file in `ox_doorlock/convert/` with the following code:

```lua
Config.DoorList['jewellery-citysec'] = {
  objYaw = 36.000022888184,
  doorRate = 1.0,
  locked = true,
  fixText = false,
  pickable = true,
  authorizedJobs = { ['police'] = 0 },
  needsAllItems = false,
  objCoords = vec3(-629.133850, -230.151703, 38.206585),
  distance = 2.5,
  doorType = 'door',
  objName = 1335309163,
}

Config.DoorList['jewellery-grapemain'] = {
  doorType = 'double',
  locked = true,
  cantUnlock = true,
  doorLabel = 'main',
  distance = 2,
  doors = {
    {objName = 9467943, objYaw = 98.17839050293, objCoords = vec3(1653.285522, 4884.148438, 42.309845)},
    {objName = 1425919976, objYaw = 98.17839050293, objCoords = vec3(1653.655518, 4881.573730, 42.309845)}
  },
  doorRate = 1.0,
}

Config.DoorList['jewellery-grapesec'] = {
  pickable = true,
  objCoords = vec3(1648.274902, 4877.423340, 42.309898),
  objName = 1335309163,
  doorRate = 1.0,
  distance = 2.5,
  authorizedJobs = { ['police'] = 0 },
  doorType = 'door',
  objYaw = 188.17839050293,
  fixText = false,
  doorLabel = 'sec',
  locked = true,
}

Config.DoorList['jewellery-palmain'] = {
  doorType = 'double',
  locked = true,
  cantUnlock = true,
  doorLabel = 'main',
  distance = 2,
  doors = {
    {objName = 1425919976, objYaw = 314.90930175781, objCoords = vec3(-383.837921, 6044.059082, 31.658920)},
    {objName = 9467943, objYaw = 314.90930175781, objCoords = vec3(-382.001617, 6042.216797, 31.658920)}
  },
  doorRate = 1.0,
}

Config.DoorList['jewellery-palsec'] = {
  doorType = 'door',
  locked = true,
  doorRate = 1.0,
  pickable = true,
  distance = 2.5,
  objYaw = 44.909275054932,
  fixText = false,
  authorizedJobs = { ['police'] = 0 },
  objCoords = vec3(-382.007721, 6050.603027, 31.658974),
  objName = 1335309163,
}
```

### Support

- Join the [Grouse Labs 🐀 discord](https://discord.gg/pmywChNQ5m).
- Use the appropriate support forum!
