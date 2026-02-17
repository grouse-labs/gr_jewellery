return {
  error = {
    minimum_police = 'Mindestens %{value} Polizisten erforderlich',
    wrong_weapon = 'Deine Waffe ist nicht stark genug..',
    too_much = 'Deine Taschen sind voll..',
    fail_therm = 'Thermit konnte nicht angebracht werden..',
    fail_hack = 'Sicherheitssystem konnte nicht gehackt werden..',
    skill_fail = 'Dein %{value}-Skill ist nicht hoch genug..'
  },
  success = {
    thermite = 'Sicherungen durchgebrannt, die Türen sollten sich gleich öffnen..',
    hacked = 'Hack erfolgreich, Sicherheit ist deaktiviert..'
  },
  info = {
    hacking_attempt = 'Verbindung zum Sicherheitssystem wird hergestellt..',
    close_warning = 'Beeil dich! Der Laden schließt in 1 Minute',
    suss_dispatch = 'Verdächtige Aktivität',
    case_dispatch = 'Raubüberfall im Gange',
    thermite_dispatch = 'Explosion gemeldet'
  },
  general = {
    store_label = 'Vangelico Juweliere', -- Auskommentieren, wenn individuelle Labels genutzt werden sollen
    -- store_labels = { -- Auskommentieren, wenn für alle Läden dasselbe Label genutzt werden soll
    --   main = 'Little Portola Vangelico',
    --   grape = 'Grapeseed Vangelico',
    --   paleto = 'Paleto Vangelico'
    -- },
    target_label = 'Vitrine einschlagen',
    thermite_label = 'Sicherungskasten sprengen',
    hack_label = 'Alarmsystem deaktivieren'
  },
  debug = {
    enable = '%{version} - Debug-Modus %{state}!^7',
    no_doors = 'Keine Türen für Standort %{location} gesetzt',
    no_door_i = 'Keine Tür #%<index>.d für Standort %{location}'
  }
}
