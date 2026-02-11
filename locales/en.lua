return {
  error = {
    minimum_police = 'Minimum of %{value} police needed',
    wrong_weapon = 'Your weapon is not strong enough..',
    too_much = 'You\'re pockets are full..',
    fail_therm = 'You failed to apply the thermite..',
    fail_hack = 'You failed to hack the security system..',
    skill_fail = 'Your %{value} skill is not high enough..'
  },
  success = {
    thermite = 'Fuses blown, the doors should open soon..',
    hacked = 'Hack successful, security is disabled..'
  },
  info = {
    hacking_attempt = 'Connecting to the security system..',
    close_warning = 'Hurry! The store will close in 1 minute'
  },
  general = {
    store_label = 'Vangelico Jewellers', -- Comment out if you want to use unique labels for each store
    -- store_labels = { -- Comment out if you want to use the same label for each store
    --   main = 'Little Portola Vangelico',
    --   grape = 'Grapeseed Vangelico',
    --   paleto = 'Paleto Vangelico'
    -- },
    target_label = 'Smash Display Case',
    thermite_label = 'Blow Fuse Box',
    hack_label = 'Disable Alarm System'
  },
  debug = {
    enable = '%{version} - Debug Mode %{state}!^7',
    no_doors = 'No doors set for location %{location}',
    no_door_i = 'No door #%<index>.d set for location %{location}'
  }
}