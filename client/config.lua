return {
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