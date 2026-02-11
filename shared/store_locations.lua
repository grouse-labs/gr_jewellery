---@type {[string]: {coords: vector3, doors: string[], police: integer, alarms: {coords: vector3|vector3[], sound: {bank: string, name: string, ref: string}, range: number}?, thermite: {coords: vector3, heading: number, size: vector3, item: string}, hack: {coords: vector3, heading: number, size: vector3, item: string}?}}
return {
  main = {
    coords = vector3(-630.5, -237.13, 38.08),
    doors = {'jewellery-citymain', 'jewellery-citysec'},
    police = 0,
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
      size = vector3(0.4, 0.8, 1.2),
      item = 'thermite'
    },
    hack = {
      coords = vector3(-631.04, -230.63, 38.06),
      heading = 37.0,
      size = vector3(0.4, 0.6, 1.0),
      item = 'phone'
    }
  },
  grape = {
    coords = vector3(1649.78, 4882.32, 42.16),
    doors = {'jewellery-grapemain', 'jewellery-grapesec'},
    police = 0,
    alarms = {
      coords = {vector3(1648.3, 4885.79, 45.27), vector3(1649.33, 4878.59, 45.27)},
      sound = {
        bank = 'ALARM_BELL_02',
        name = 'Bell_02',
        ref = 'ALARMS_SOUNDSET'
      },
      range = 100.0
    },
    thermite = {
      coords = vector3(1645.07, 4867.87, 42.03),
      heading = 8.0,
      size = vector3(0.4, 0.8, 1.2),
      item = 'thermite'
    }
  },
  paleto = {
    coords = vector3(-378.45, 6047.68, 32.69),
    doors = {'jewellery-palmain', 'jewellery-palsec'},
    police = 0,
    alarms = {
      coords = {vector3(-377.02, 6043.88, 34.62), vector3(-382.16, 6049.03, 34.62)},
      sound = {
        bank = 'ALARM_BELL_02',
        name = 'Bell_02',
        ref = 'ALARMS_SOUNDSET'
      },
      range = 100.0
    },
    thermite = {
      coords = vector3(-368.35, 6055.36, 31.5),
      heading = 135.0,
      size = vector3(0.4, 0.8, 1.2),
      item = 'thermite'
    }
  }
}