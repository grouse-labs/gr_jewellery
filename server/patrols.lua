return {
  main = {
    ['Data'] = {
      name = 'Jewellery_Store_Main',
      cooldown = 15,
      enabled = {guards = false, patrol = true, vehicle = false},
      distances = {spawn = 500.0, despawn = 1000.0},
      deaths = {percent = 80.0, resets = false},
      debug = false
    },
    ['Routes'] = {
      patrol = {
        {
          {coords = vector3(-591.9, -293.15, 50.32), heading = 296.69, time = 12500, scenario = 'WORLD_HUMAN_SMOKING'},
          {coords = vector3(-606.37, -243.15, 50.25), heading = 90.51, time = 12500, scenario = 'WORLD_HUMAN_INSPECT_STAND'},
          {coords = vector3(-618.35, -266.94, 52.3), heading = 118.73, time = 12500, scenario = 'WORLD_HUMAN_GUARD_PATROL'},
          {coords = vector3(-617.35, -254.86, 52.31), heading = 303.92, time = 12500, scenario = 'WORLD_HUMAN_GUARD_PATROL'},
          {coords = vector3(-589.83, -278.99, 50.32), heading = 261.16, time = 12500, scenario = 'WORLD_HUMAN_SMOKING'}
        }
      }
    },
    ['Peds'] = {
      patrol = {
        {
          ['Base'] = {
            model = 's_m_m_armoured_01',
            weapon = 'weapon_pistol',
            health = 250,
            armour = 50,
            ammo = nil,
            brandish = true,
            combat = {},
            config  = {},
            reset = {},
            Loot = false
          },
          ['Range'] = {
            lod = 150.0,
            id = 50.0,
            seeing = 50.0,
            peripheral = 50.0,
            hearing = 50.0,
            shout = 50.0
          }
        }
      }
    },
    ['Blips'] = {
      enabled = true,
      colour = 3,
      cone = true,
      forced = true
    },
    ['CombatAI'] = {
      ability = 80,
      accuracy = 60,
      alertness = 2,
      movement = 1,
      range = 2,
      target_response = 0
    },
    ['PedAI'] = {
      combat = {5, 14, 15, 22, 46},
      config = {2, 4, 132, 137, 392, 14, 16, 275, 152, 167, 433, 435, 72, 201, 456, 210, 213, 227, 287, 113, 372, 246, 315, 397}
    },
    ['PedProofs'] = {
      injured = true,
      bullet = false,
      fire = false,
      explosion = false,
      collision = false,
      melee = false,
      steam = false,
      water = false,
      invincible = false
    },
    ['Relationships'] = {
      [0] = {'security', 'police', 'LEO', 'ambulance', 'fire', 'ARMY'},
      [3] = {'PLAYER'},
    }
  },
}