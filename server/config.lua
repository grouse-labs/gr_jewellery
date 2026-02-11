---@type {cooldowns: {locks: integer, cases: integer, alarm: integer}, autolock: boolean, patrols: {enable: boolean, name: string}, hours: {open: integer, close: integer}, rewards: table}
return {
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