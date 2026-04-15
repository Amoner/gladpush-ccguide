local addonName, addon = ...

-- OFFENSIVE COOLDOWNS per class: { spellID, label, cooldownSec }
-- Only major PvP burst windows. Spec-specific in OFFENSIVE_EXTRA.
addon.OFFENSIVE_DATA = {
    DEATHKNIGHT = {
        { 47568,  "Empower Rune Weapon", 30 },
    },
    DEMONHUNTER = {},
    DRUID = {
        { 391528, "Convoke",      60 },
    },
    EVOKER = {
        { 357210, "Deep Breath",  120 },
    },
    HUNTER = {},
    MAGE = {},
    MONK = {
        { 322109, "Touch of Death", 180 },
    },
    PALADIN = {
        { 31884,  "Avenging Wrath", 120 },
        { 375576, "Divine Toll",    60 },
    },
    PRIEST = {
        { 10060,  "Power Infusion", 120 },
        -- Mindgames (375901) removed in 12.0
        { 34433,  "Shadowfiend",   180 },
    },
    ROGUE = {
        -- Cold Blood (382245) reworked to passive "Cold Blooded Killer" in 12.0
    },
    SHAMAN = {},
    WARLOCK = {},
    WARRIOR = {
        { 107574, "Avatar",        90 },
        { 376079, "Spear",         90 },
        -- Thunderous Roar (384318) removed in 12.0
    },
}

addon.OFFENSIVE_EXTRA = {
    -- Death Knight
    [251] = { -- Frost
        { 51271,   "Pillar of Frost",   60 },
        { 279302,  "Frostwyrm's Fury",  90 },
    },
    [252] = { -- Unholy
        { 207289,  "Unholy Assault",  90 },
        { 1247378, "Putrefy",         30 },
        -- Summon Gargoyle (49206) now passive modifier on Army of the Dead in 12.0
    },
    -- Demon Hunter
    [577] = { -- Havoc
        { 370965, "The Hunt",       90 },
        { 191427, "Metamorphosis",  120 },
        { 198013, "Eye Beam",        30 },
        { 258860, "Essence Break",   40 },
    },
    [1480] = { -- Devourer
        { 1246167, "The Hunt",           90 },
        { 1217605, "Void Metamorphosis",  0 }, -- resource-gated (50 Soul Fragments), no fixed CD
    },
    -- Druid
    [102] = { -- Balance
        { 194223, "Celestial Alignment", 90 },
    },
    [103] = { -- Feral
        { 106951, "Berserk",        180 },
        { 274837, "Feral Frenzy",    45 },
        { 5217,   "Tiger's Fury",    30 },
    },
    -- Evoker
    [1467] = { -- Devastation
        { 375087, "Dragonrage",  120 },
    },
    -- Hunter
    [253] = { -- Beast Mastery
        { 19574,  "Bestial Wrath",  30 },
    },
    [254] = { -- Marksmanship
        { 288613, "Trueshot",   60 },
    },
    [255] = { -- Survival
        { 1250646, "Takedown",  90 },
    },
    -- Mage
    [62] = { -- Arcane
        { 365350, "Arcane Surge", 90 },
    },
    [63] = { -- Fire
        { 190319, "Combustion",  120 },
    },
    [64] = { -- Frost
        { 12472,  "Icy Veins",  120 },
    },
    -- Monk
    [269] = { -- Windwalker
        { 137639, "Storm, Earth, and Fire", 90 },
        { 123904, "Invoke Xuen",            90 },
    },
    -- Paladin
    [70] = { -- Retribution
        { 343527, "Execution Sentence", 60 },
        { 255937, "Wake of Ashes",      30 },
    },
    -- Priest
    [258] = { -- Shadow
        { 228260, "Void Eruption",  120 },
        { 263165, "Void Torrent",    30 },
    },
    -- Rogue
    [259] = { -- Assassination
        { 360194, "Deathmark",  120 },
        { 385627, "Kingsbane",   60 },
    },
    [260] = { -- Outlaw
        { 13750,  "Adrenaline Rush", 180 },
        { 51690,  "Killing Spree",   180 },
    },
    [261] = { -- Subtlety
        { 185313, "Shadow Dance",  50 },
        { 121471, "Shadow Blades", 90 },
        -- Flagellation (384631) removed in 12.0
    },
    -- Shaman
    [262] = { -- Elemental
        { 114050, "Ascendance",   180 },
        { 191634, "Stormkeeper",   60 },
    },
    [263] = { -- Enhancement
        { 114051, "Ascendance",   120 },
        -- Feral Spirit (51533) now passive in 12.0
        -- Doom Winds now passive proc on Windfury Totem drop (60s ICD)
    },
    -- Warlock
    [265] = { -- Affliction
        { 442726, "Malevolence",      60 },
        { 205180, "Summon Darkglare", 120 },
        { 386997, "Soul Rot",         60 },
    },
    [266] = { -- Demonology
        { 265187, "Summon Demonic Tyrant", 60 },
    },
    [267] = { -- Destruction
        { 442726, "Malevolence",      60 },
        { 1122,   "Summon Infernal",  120 },
    },
    -- Warrior
    [71] = { -- Arms
        { 227847, "Bladestorm",    60 },
        { 262161, "Warbreaker",    45 },
    },
    [72] = { -- Fury
        { 1719,   "Recklessness",  90 },
        { 227847, "Bladestorm",    60 },
        { 385059, "Odyn's Fury",   45 },
    },
}

-- DEFENSIVE COOLDOWNS per class
addon.DEFENSIVE_DATA = {
    DEATHKNIGHT = {
        { 48707,  "Anti-Magic Shell",  40 },
        { 48792,  "Icebound Fortitude", 120 },
        { 49039,  "Lichborne",        120 },
        { 51052,  "Anti-Magic Zone",  180 },
    },
    DEMONHUNTER = {
        { 196718, "Darkness",     180 },
        -- Netherwalk (196555) removed in 12.0
    },
    DRUID = {
        { 22812,  "Barkskin",    60 },
    },
    EVOKER = {
        { 363916, "Obsidian Scales", 90 },
        { 374227, "Zephyr",         120 },
        -- Renewing Blaze (374348) now passive on Obsidian Scales in 12.0
    },
    HUNTER = {
        { 186265, "Aspect of the Turtle", 150 },
        { 109304, "Exhilaration",         120 },
        { 264735, "Survival of the Fittest", 90 },
    },
    MAGE = {
        { 45438,  "Ice Block",          180 },
        { 342245, "Alter Time",          50 },
        { 110959, "Greater Invisibility", 120 },
    },
    MONK = {
        { 115203, "Fortifying Brew",   90 },
        -- Diffuse Magic (122783) now passive on Fortifying Brew in 12.0
    },
    PALADIN = {
        { 642,    "Divine Shield",       210 },
        { 1022,   "Blessing of Protection", 240 },
        { 633,    "Lay on Hands",        420 },
        { 6940,   "Blessing of Sacrifice", 60 },
    },
    PRIEST = {
        { 19236,  "Desperate Prayer",  70 },
        { 586,    "Fade",              20 },
    },
    ROGUE = {
        { 31224,  "Cloak of Shadows", 120 },
        { 5277,   "Evasion",          120 },
        { 1856,   "Vanish",           120 },
    },
    SHAMAN = {
        { 108271, "Astral Shift",    90 },
        { 204336, "Grounding Totem", 24 },
    },
    WARLOCK = {
        { 104773, "Unending Resolve", 180 },
        { 108416, "Dark Pact",         45 },
    },
    WARRIOR = {
        { 97462,  "Rallying Cry",      180 },
        { 23920,  "Spell Reflection",   24 },
    },
}

addon.DEFENSIVE_EXTRA = {
    -- Demon Hunter
    [577] = { -- Havoc
        { 198589, "Blur", 60 },
    },
    [1480] = { -- Devourer
        { 198589, "Blur", 60 },
    },
    -- Druid
    [103] = { -- Feral
        { 61336,  "Survival Instincts", 180 },
    },
    [104] = { -- Guardian
        { 61336,  "Survival Instincts", 120 },
    },
    [105] = { -- Restoration
        { 102342, "Ironbark", 90 },
    },
    -- Monk
    [269] = { -- Windwalker
        { 122470, "Touch of Karma", 90 },
    },
    [270] = { -- Mistweaver
        { 116849, "Life Cocoon", 75 },
    },
    -- Paladin
    [70] = { -- Retribution
        -- Shield of Vengeance (184662) now passive modifier on Divine Protection in 12.0
        { 498, "Divine Protection", 60 },
    },
    [66] = { -- Protection
        { 31850,  "Ardent Defender",         84 },
        { 86659,  "Guardian of Ancient Kings", 300 },
    },
    -- Priest
    [258] = { -- Shadow
        { 47585,  "Dispersion", 90 },
    },
    [256] = { -- Discipline
        { 33206,  "Pain Suppression", 180 },
    },
    [257] = { -- Holy
        { 47788,  "Guardian Spirit", 180 },
    },
    -- Rogue
    [259] = { -- Assassination
        { 212182, "Smoke Bomb", 180 },
    },
    [261] = { -- Subtlety
        { 359053, "Smoke Bomb", 120 },
    },
    -- Shaman
    [264] = { -- Restoration
        { 98008,  "Spirit Link Totem",  174 },
        { 108280, "Healing Tide Totem", 129 },
    },
    -- Warrior
    [71] = { -- Arms
        { 118038, "Die by the Sword", 85 },
    },
    [72] = { -- Fury
        { 184364, "Enraged Regeneration", 114 },
    },
    [73] = { -- Protection
        { 871,    "Shield Wall", 120 },
        { 12975,  "Last Stand",  180 },
    },
}

-- IMMUNITIES per class: { spellID, label, cooldownSec, immuneType, description }
-- immuneType: what it grants immunity to
addon.IMMUNITY_DATA = {
    DEATHKNIGHT = {
        { 48707,  "Anti-Magic Shell", 40,  "Magic Dmg + Debuffs", "Absorbs magic damage and immune to magic debuff applications for 5s" },
        { 48792,  "Icebound Fortitude", 120, "Stun Immune", "Immune to stuns, -30% damage taken for 8s" },
        { 49039,  "Lichborne", 120, "Charm/Fear/Sleep", "Immune to Charm, Fear, and Sleep effects for 10s" },
        { 212552, "Wraith Walk", 60, "Root Immune", "Removes and immune to roots, +70% speed for 4s" },
    },
    DEMONHUNTER = {
        -- Netherwalk (196555) removed in 12.0
        { 206803, "Rain from Above", 90, "Untargetable", "Launch into air, briefly untargetable from ground" },
    },
    DRUID = {
        -- Shapeshift root break is passive, not trackable
    },
    EVOKER = {
        { 378441, "Time Stop", 45, "Everything (Ally)", "Places ally in stasis — invulnerable, cannot act for 5s" },
        { 378444, "Obsidian Mettle", 0, "Interrupt/Silence", "While Obsidian Scales active, immune to interrupt, silence, pushback" },
    },
    HUNTER = {
        { 186265, "Aspect of the Turtle", 150, "All Damage", "Immune to ALL damage, deflects attacks/spells, cannot attack for 8s" },
        { 5384,   "Feign Death", 30, "Drops Target", "Feign death — drops target, enemies stop attacking" },
    },
    MAGE = {
        { 45438,  "Ice Block", 180, "Everything", "Immune to ALL damage/effects, cannot act for 10s. Dispellable by Mass Dispel/Shattering Throw" },
        { 414658, "Ice Cold", 240, "70% DR + Act", "70% damage reduction for 6s, CAN still move and cast. NOT true immunity" },
        { 110959, "Greater Invisibility", 120, "Untargetable", "Invisible/untargetable for 20s, 60% DR while invisible and 3s after" },
    },
    MONK = {
        -- Diffuse Magic (122783) now passive on Fortifying Brew in 12.0
    },
    PALADIN = {
        { 642,    "Divine Shield", 210, "Everything", "Immune to ALL damage/effects, CAN attack/heal for 8s. Shattering Throw/Mass Dispel removes" },
        { 1022,   "Blessing of Protection", 240, "Physical", "Target immune to physical damage/effects, cannot auto-attack. Dispellable" },
        { 204018, "Blessing of Spellwarding", 240, "Magic", "Target immune to magic damage/effects for 6s — replaces BoP if talented" },
        { 1044,   "Blessing of Freedom", 25, "Movement Impair", "Target immune to movement impairing effects for 8s" },
    },
    PRIEST = {
        { 47585,  "Dispersion", 90, "Silence/Int + 75% DR", "75-90% damage reduction, immune to silence/interrupt, cannot attack for 6s" },
        { 408557, "Phase Shift", 30, "All (1 sec)", "Fade upgrade — avoid ALL attacks and spells for 1s (PvP talent)" },
        -- Holy Ward (213610) removed in 12.0
    },
    ROGUE = {
        { 31224,  "Cloak of Shadows", 120, "Magic Spells", "Removes magic debuffs, immune to magic spells for 5s" },
        { 5277,   "Evasion", 120, "Physical (Dodge)", "Near 100% dodge chance — immune to melee/ranged physical for 10s" },
        { 1856,   "Vanish", 120, "Untargetable", "Enter stealth, drops target — untargetable until broken" },
    },
    SHAMAN = {
        { 409293, "Burrow", 120, "Everything", "Burrow underground — unattackable, removes snares, +50% speed for 5s" },
        { 204336, "Grounding Totem", 24, "Next Spell (Party)", "Redirects next harmful spell to the totem — party spell immunity" },
    },
    WARLOCK = {
        { 104773, "Unending Resolve", 180, "Silence/Int + 25% DR", "Immune to interrupt/silence/pushback, -25% damage for 8s" },
        { 212295, "Nether Ward", 45, "Spell Reflect", "Reflects harmful spells for 3s, also prevents interrupts (PvP)" },
    },
    WARRIOR = {
        { 23920,  "Spell Reflection", 24, "Next Spell", "Reflects the next spell cast on you back to the caster" },
        { 46924,  "Bladestorm", 60, "CC Immune", "Immune to ALL crowd control while Bladestorming" },
    },
}

addon.IMMUNITY_EXTRA = {
    -- Demon Hunter
    [577] = { -- Havoc
        { 198589, "Blur", 60, "Dodge + 25% DR", "50% dodge, -25% damage for 10s. In PvP dodges spells/ranged for 3s" },
    },
    [1480] = { -- Devourer
        { 198589, "Blur", 60, "Dodge + 25% DR", "50% dodge, -25% damage for 10s. In PvP dodges spells/ranged for 3s" },
        { 196555, "Netherwalk", 60, "All Damage (2.5s)", "Blur talent: immune to ALL damage, +100% speed for 2.5s on Blur activation" },
    },
    -- Druid
    [103] = { -- Feral
        { 61336,  "Survival Instincts", 180, "All Damage (50%)", "Reduces all damage taken by 50% for 6s" },
    },
    [104] = { -- Guardian
        { 61336,  "Survival Instincts", 120, "All Damage (50%)", "Reduces all damage taken by 50% for 6s" },
    },
    -- Monk
    [269] = { -- Windwalker
        { 122470, "Touch of Karma", 90, "Absorb + Redirect", "Absorbs ALL damage for 10s (80% HP cap), redirects 70% to attacker" },
    },
    [270] = { -- Mistweaver
        { 116849, "Life Cocoon", 75, "Absorb Shield", "Massive absorb shield on target, increases healing received by 50%" },
    },
    -- Paladin
    [65] = { -- Holy
        { 498,    "Divine Protection", 42, "Magic (50%)", "Reduces magic damage taken by 50% for 8s" },
    },
    -- Priest
    [257] = { -- Holy
        { 47788,  "Guardian Spirit", 180, "Prevent Death", "Prevents target from dying — heals to 40% instead of lethal damage" },
    },
    [256] = { -- Discipline
        { 33206,  "Pain Suppression", 180, "40% DR (External)", "Reduces target's damage taken by 40% for 8s" },
    },
    -- Rogue
    [259] = { -- Assassination
        { 212182, "Smoke Bomb", 180, "Zone Untargetable", "Zone where enemies outside cannot target players inside for 5s" },
    },
    [261] = { -- Subtlety
        { 359053, "Smoke Bomb", 120, "Zone Untargetable", "Zone where enemies outside cannot target players inside for 5s" },
    },
    -- Warrior
    [71] = { -- Arms
        { 118038, "Die by the Sword", 85, "Parry + 30% DR", "Near 100% parry chance, -30% damage taken for 8s" },
    },
    [72] = { -- Fury
        { 184364, "Enraged Regeneration", 114, "30% DR + Heal", "Reduces damage taken by 30% and heals over 8s" },
    },
}

-------------------------------------------------------------------
-- PvP Talent Cooldowns (shown in category tabs + PvP Talents tab)
-- Same format as their category: offensive { spellID, label, cd }
-------------------------------------------------------------------

-- PVP OFFENSIVE
addon.PVP_OFFENSIVE_DATA = {
    DEATHKNIGHT = {
        { 77606,  "Dark Simulacrum (PvP)", 25 },
    },
}

addon.PVP_OFFENSIVE_EXTRA = {
    [71] = { -- Arms Warrior
        { 1219165, "Sharpen Blade (PvP)", 25 },
    },
    [258] = { -- Shadow Priest
        { 211522, "Psyfiend (PvP)", 45 },
    },
    [262] = { -- Elemental Shaman
        { 193876, "Shamanism (PvP)", 60 },
    },
}

-- PVP DEFENSIVE
addon.PVP_DEFENSIVE_DATA = {
    DEMONHUNTER = {
        { 205604, "Reverse Magic (PvP)", 60 },
    },
    WARRIOR = {
        { 1227751, "Berserker Roar (PvP)", 60 },
    },
}

addon.PVP_DEFENSIVE_EXTRA = {
    [70] = { -- Ret Paladin
        { 210256, "Blessing of Sanctuary (PvP)", 60 },
    },
    [270] = { -- Mistweaver Monk
        { 353584, "Eminence (PvP)", 20 },
    },
}

-- PVP IMMUNITY
addon.PVP_IMMUNITY_DATA = {
    HUNTER = {
        { 202746, "Survival Tactics (PvP)", 30, "90% DR (2s)", "Feign Death reduces damage taken by 90% for 2s" },
    },
}

addon.PVP_IMMUNITY_EXTRA = {
    [62] = { -- Arcane Mage
        { 1221106, "Overpowered Barrier (PvP)", 0, "All Damage (3s)", "Blink grants 3s full damage immunity after barrier consumed" },
    },
    [63] = { -- Fire Mage
        { 1221106, "Overpowered Barrier (PvP)", 0, "All Damage (3s)", "Blink grants 3s full damage immunity after barrier consumed" },
    },
    [64] = { -- Frost Mage
        { 1221106, "Overpowered Barrier (PvP)", 0, "All Damage (3s)", "Blink grants 3s full damage immunity after barrier consumed" },
    },
    [577] = { -- Havoc DH
        { 354489, "Glimpse (PvP)", 20, "LoC + 35% DR", "Vengeful Retreat grants LoC immunity and 35% DR" },
    },
    [1480] = { -- Devourer DH
        { 354489, "Glimpse (PvP)", 20, "LoC + 35% DR", "Vengeful Retreat grants LoC immunity and 35% DR" },
    },
    [270] = { -- Mistweaver Monk
        { 468430, "Zen Focus Tea (PvP)", 45, "Silence/Interrupt", "Immune to silence and interrupt for 5s" },
    },
}
