local addonName, addon = ...

-- Dynamically discover all specs from game API
local CLASS_TOKENS = {
    "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT",
    "SHAMAN","MAGE","WARLOCK","MONK","DRUID","DEMONHUNTER","EVOKER",
}
addon.SPEC_TO_CLASS = {}
addon.CLASS_SPECS = {}
local specsDiscovered = false
function addon:DiscoverSpecs()
    if specsDiscovered then return end
    wipe(self.SPEC_TO_CLASS); wipe(self.CLASS_SPECS)
    for classID = 1, #CLASS_TOKENS do
        local classToken = CLASS_TOKENS[classID]
        local specs = {}
        local numSpecs = GetNumSpecializationsForClassID(classID)
        for specIdx = 1, numSpecs do
            local specID = GetSpecializationInfoForClassID(classID, specIdx)
            if specID then
                self.SPEC_TO_CLASS[specID] = classToken
                specs[#specs+1] = specID
            end
        end
        if #specs > 0 then
            self.CLASS_SPECS[#self.CLASS_SPECS+1] = { classToken, specs }
        end
    end
    specsDiscovered = true
end

-- Representative icon per DR category
addon.CC_TYPE_ICONS = {
    Stun         = 853,    -- Hammer of Justice
    Incapacitate = 118,    -- Polymorph
    Disorient    = 33786,  -- Cyclone
    Root         = 339,    -- Entangling Roots
    Silence      = 15487,  -- Silence
    Interrupt    = 1766,   -- Kick
    Disarm       = 236077, -- Disarm
}

-- DR categories in retail 12.0 (Fear/Horror merged into Disorient)
-- DR now triggers full immunity after 2 applications (was 3), reset timer 16s (was 18s)
-- Source: DRList-1.0 v82 (github.com/wardz/DRList-1.0)
addon.CC_ORDER = { "Stun", "Incapacitate", "Disorient", "Root", "Silence", "Interrupt", "Disarm" }

-- CC data per class: { spellID, drCategory, isCast, durationSec, cooldownSec }
-- Only baseline/commonly available abilities. Spec-specific in SPEC_EXTRA below.
addon.CC_DATA = {
    DEATHKNIGHT = {
        { 221562, "Stun",      false, 4,  45 }, -- Asphyxiate
        { 207167, "Disorient", false, 5,  60 }, -- Blinding Sleet
        { 47476,  "Silence",   false, 4,  60 }, -- Strangulate
        { 47528,  "Interrupt", false, 3,  15 }, -- Mind Freeze
    },
    DEMONHUNTER = {
        { 217832,  "Incapacitate", true,  4,  45 }, -- Imprison
        { 183752,  "Interrupt",    false, 3,  15 }, -- Disrupt
    },
    DRUID = {
        { 33786,  "Disorient",    true,  6,  30 }, -- Cyclone
        { 339,    "Root",         true,  6,   0 }, -- Entangling Roots
        { 5211,   "Stun",         false, 4,  60 }, -- Mighty Bash
        { 2637,   "Incapacitate", true,  6,  30 }, -- Hibernate
        { 99,     "Incapacitate", false, 3,  30 }, -- Incapacitating Roar
        -- Skull Bash is DPS/tank-only (Balance/Feral/Guardian) — see SPEC_EXTRA. Resto lost it.
    },
    EVOKER = {
        { 360806, "Disorient",    true,  6,  15 }, -- Sleep Walk
        { 351338, "Interrupt",    false, 4,  20 }, -- Quell
    },
    HUNTER = {
        { 187650, "Incapacitate", false, 6,  25 }, -- Freezing Trap
        { 19577,  "Stun",         false, 5,  60 }, -- Intimidation
        { 117526, "Stun",         false, 3,  45 }, -- Binding Shot
        { 147362, "Interrupt",    false, 3,  24 }, -- Counter Shot
    },
    MAGE = {
        { 118,    "Incapacitate", true,  6,   0 }, -- Polymorph
        { 113724, "Incapacitate", true,  6,  45 }, -- Ring of Frost
        { 2139,   "Interrupt",    false, 6,  24 }, -- Counterspell
    },
    MONK = {
        { 115078, "Incapacitate", false, 4,  45 }, -- Paralysis
        { 119381, "Stun",         false, 3,  60 }, -- Leg Sweep
        -- Spear Hand Strike is DPS/tank-only (Brewmaster/Windwalker) — see SPEC_EXTRA. Mistweaver lost it.
    },
    PALADIN = {
        { 853,    "Stun",         false, 6,  60 }, -- Hammer of Justice
        { 115750, "Disorient",    false, 4,  90 }, -- Blinding Light
        { 10326,  "Disorient",    true,  6,  15 }, -- Turn Evil
    },
    PRIEST = {
        { 8122,   "Disorient",    false, 6,  60 }, -- Psychic Scream
        { 605,    "Disorient",    true,  0,  30 }, -- Mind Control (channeled)
        { 9484,   "Incapacitate", true,  6,   0 }, -- Shackle Undead
    },
    ROGUE = {
        { 6770,   "Incapacitate", false, 6,   0 }, -- Sap
        { 2094,   "Disorient",    false, 6, 120 }, -- Blind
        { 408,    "Stun",         false, 6,  20 }, -- Kidney Shot
        { 1833,   "Stun",         false, 4,  12 }, -- Cheap Shot
        { 1776,   "Incapacitate", false, 4,  20 }, -- Gouge
        { 1766,   "Interrupt",    false, 5,  15 }, -- Kick
    },
    SHAMAN = {
        { 51514,  "Incapacitate", true,  6,  30 }, -- Hex
        { 192058, "Stun",         false, 3,  60 }, -- Capacitor Totem
        { 57994,  "Interrupt",    false, 2,  12 }, -- Wind Shear
    },
    WARLOCK = {
        { 5782,   "Disorient",    true,  6,   0 }, -- Fear
        { 6789,   "Incapacitate", false, 3,  45 }, -- Mortal Coil
        { 30283,  "Stun",         true,  3,  60 }, -- Shadowfury
        { 5484,   "Disorient",    true,  6,  40 }, -- Howl of Terror (choice node w/ Shadowfury, all specs in 12.0)
        { 710,    "Incapacitate", true,  6,  30 }, -- Banish
        { 19647,  "Interrupt",    false, 6,  24 }, -- Spell Lock
    },
    WARRIOR = {
        { 5246,   "Disorient", false, 6, 90 }, -- Intimidating Shout
        { 107570, "Stun",      false, 4, 30 }, -- Storm Bolt
        { 6552,   "Interrupt", false, 4, 15 }, -- Pummel
    },
}

-- Spec-specific CC (added on top of class baseline)
addon.SPEC_EXTRA = {
    -- Demon Hunter
    [577] = { -- Havoc
        { 179057, "Stun", false, 3, 60 }, -- Chaos Nova
    },
    [581] = { -- Vengeance
        { 207685, "Disorient", false, 6, 90 }, -- Sigil of Misery
    },
    [1480] = { -- Devourer
        { 1234195, "Stun", false, 2, 45 }, -- Void Nova (Devourer-unique, 30yd ranged stun)
    },

    -- Druid
    [102] = { -- Balance
        { 106839, "Interrupt", false, 4, 15 }, -- Skull Bash
    },
    [103] = { -- Feral
        { 106839, "Interrupt", false, 4, 15 }, -- Skull Bash
        { 203123, "Stun",      false, 5, 20 }, -- Maim
    },
    [104] = { -- Guardian
        { 106839, "Interrupt", false, 4, 15 }, -- Skull Bash
    },
    -- Resto Druid (105): no interrupt in 12.0

    -- Monk
    [268] = { -- Brewmaster
        { 116705, "Interrupt", false, 4, 15 }, -- Spear Hand Strike
    },
    [269] = { -- Windwalker
        { 116705, "Interrupt", false, 4, 15 }, -- Spear Hand Strike
    },
    -- Mistweaver Monk (270): no interrupt in 12.0 (loses Spear Hand Strike; see below for Song of Chi-Ji incap)

    -- Mage
    [63] = { -- Fire
        { 31661, "Disorient", false, 4, 20 }, -- Dragon's Breath
    },

    -- Monk
    [270] = { -- Mistweaver
        { 198909, "Incapacitate", true, 4, 30 }, -- Song of Chi-Ji
    },

    -- Paladin
    [70] = { -- Retribution
        { 96231,  "Interrupt", false, 4, 15 }, -- Rebuke
        { 255941, "Stun",      false, 3, 30 }, -- Wake of Ashes
    },
    [66] = { -- Protection
        { 96231,  "Interrupt", false, 4, 15 }, -- Rebuke
    },

    -- Priest
    [258] = { -- Shadow
        { 15487, "Silence", false, 4, 45 }, -- Silence
        { 64044, "Stun",    false, 4, 45 }, -- Psychic Horror
    },
    [257] = { -- Holy
        { 200196, "Incapacitate", false, 4, 60 }, -- Holy Word: Chastise
    },

    -- Rogue
    [259] = { -- Assassination
        { 1330, "Silence", false, 3, 15 }, -- Garrote
    },

    -- Shaman
    [262] = { -- Elemental
        { 305485, "Stun", true, 5, 30 }, -- Lightning Lasso
    },

    -- Warlock
    -- Howl of Terror moved to baseline WARLOCK CC_DATA (choice node for all specs in 12.0)
}

-------------------------------------------------------------------
-- PvP Talent CC abilities (shown in CC tab + PvP Talents tab)
-- Same format: { spellID, drCategory, isCast, durationSec, cooldownSec }
-------------------------------------------------------------------
addon.PVP_CC_DATA = {
    WARRIOR = {
        { 236077,  "Disarm",   false, 5, 45 }, -- Disarm
    },
    ROGUE = {
        { 207777,  "Disarm",   false, 5, 45 }, -- Dismantle
    },
    HUNTER = {
        { 356719,  "Silence",  false, 3, 45 }, -- Chimaeral Sting (silence phase)
    },
}

addon.PVP_CC_EXTRA = {
    [64] = { -- Frost Mage
        { 389794,  "Stun",         false, 4, 60 }, -- Snowdrift
    },
    [65] = { -- Holy Paladin
        { 410126,  "Incapacitate", true,  4, 45 }, -- Searing Glare
    },
    [70] = { -- Ret Paladin
        { 410126,  "Incapacitate", true,  4, 45 }, -- Searing Glare
    },
}

-------------------------------------------------------------------
-- Kill target % (first blood rate) per spec
-- Source: wowarenalogs.com — Rated Solo Shuffle, 1800-2099
-- Snapshot: 2026-04-15 (12.0.1 Midnight). Re-audit on balance patches.
-------------------------------------------------------------------
addon.KILL_TARGET_PCT = {
    -- DPS
    [267]  = 78.0, -- Destruction Warlock
    [102]  = 72.9, -- Balance Druid
    [251]  = 70.0, -- Frost DK
    [254]  = 65.6, -- Marksmanship Hunter
    [63]   = 65.3, -- Fire Mage
    [64]   = 61.8, -- Arcane Mage
    [1480] = 53.7, -- Devourer DH (12.0 addition)
    [62]   = 50.0, -- Arcane Mage
    [265]  = 50.0, -- Affliction Warlock
    [269]  = 48.9, -- Windwalker Monk
    [72]   = 48.6, -- Fury Warrior
    [253]  = 48.4, -- Beast Mastery Hunter
    [1467] = 47.7, -- Devastation Evoker
    [266]  = 47.2, -- Demonology Warlock
    [263]  = 47.1, -- Enhancement Shaman
    [258]  = 45.6, -- Shadow Priest
    [261]  = 43.5, -- Subtlety Rogue
    [71]   = 40.2, -- Arms Warrior
    [262]  = 40.0, -- Elemental Shaman
    [252]  = 38.6, -- Unholy DK
    [259]  = 37.5, -- Assassination Rogue
    [103]  = 36.6, -- Feral Druid
    [70]   = 33.8, -- Retribution Paladin
    [255]  = 33.3, -- Survival Hunter
    [577]  = 22.6, -- Havoc DH
    -- Tanks
    [66]   = 18.2, -- Protection Paladin
    -- Healers
    [105]  = 10.7, -- Restoration Druid
    [65]   = 9.9,  -- Holy Paladin
    [264]  = 6.7,  -- Restoration Shaman
    [1468] = 4.7,  -- Preservation Evoker
    [270]  = 4.1,  -- Mistweaver Monk
    [256]  = 1.8,  -- Discipline Priest
    [257]  = 0.0,  -- Holy Priest
}
