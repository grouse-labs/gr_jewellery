---@type {[string]: {coords: vector3, doors: string[], police: integer, thermite: {coords: vector3, heading: number, size: vector3}, hack: {coords: vector3, heading: number, size: vector3}?}}
return {
  main = {
    coords = vector3(-630.5, -237.13, 38.08),
    doors = {'jewellery-citymain', 'jewellery-citysec'},
    police = 0,
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
  },
  grape = {
    coords = vector3(1649.78, 4882.32, 42.16),
    doors = {'jewellery-grapemain', 'jewellery-grapesec'},
    police = 0,
    thermite = {
      coords = vector3(1645.07, 4867.87, 42.03),
      heading = 8.0,
      size = vector3(0.4, 0.8, 1.2)
    }
  },
  paleto = {
    coords = vector3(-378.45, 6047.68, 32.69),
    doors = {'jewellery-palmain', 'jewellery-palsec'},
    police = 0,
    thermite = {
      coords = vector3(-368.35, 6055.36, 31.5),
      heading = 135.0,
      size = vector3(0.4, 0.8, 1.2)
    }
  }
}