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
}

-- DR categories in retail 12.0 (Fear/Horror merged into Disorient)
-- Source: DRList-1.0 v82 (github.com/wardz/DRList-1.0)
addon.CC_ORDER = { "Stun", "Incapacitate", "Disorient", "Root", "Silence", "Interrupt" }

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
        { 1234195, "Stun",         false, 4,  60 }, -- Void Nova
        { 183752,  "Interrupt",    false, 3,  15 }, -- Disrupt
    },
    DRUID = {
        { 33786,  "Disorient",    true,  6,  30 }, -- Cyclone
        { 339,    "Root",         true,  8,   0 }, -- Entangling Roots
        { 5211,   "Stun",         false, 4,  60 }, -- Mighty Bash
        { 2637,   "Incapacitate", true,  8,  30 }, -- Hibernate
        { 99,     "Incapacitate", false, 3,  30 }, -- Incapacitating Roar
        { 106839, "Interrupt",    false, 4,  15 }, -- Skull Bash
    },
    EVOKER = {
        { 360806, "Disorient",    true,  6,  15 }, -- Sleep Walk
        { 351338, "Interrupt",    false, 4,  40 }, -- Quell
    },
    HUNTER = {
        { 187650, "Incapacitate", false, 8,  25 }, -- Freezing Trap
        { 19577,  "Stun",         false, 5,  60 }, -- Intimidation
        { 117526, "Stun",         false, 3,  45 }, -- Binding Shot
        { 147362, "Interrupt",    false, 3,  24 }, -- Counter Shot
    },
    MAGE = {
        { 118,    "Incapacitate", true,  8,   0 }, -- Polymorph
        { 113724, "Incapacitate", true,  6,  45 }, -- Ring of Frost
        { 2139,   "Interrupt",    false, 6,  24 }, -- Counterspell
    },
    MONK = {
        { 115078, "Incapacitate", false, 4,  45 }, -- Paralysis
        { 119381, "Stun",         false, 3,  60 }, -- Leg Sweep
        { 116705, "Interrupt",    false, 4,  15 }, -- Spear Hand Strike
    },
    PALADIN = {
        { 853,    "Stun",         false, 6,  60 }, -- Hammer of Justice
        { 115750, "Disorient",    false, 4,  90 }, -- Blinding Light
        { 10326,  "Disorient",    true,  8,  15 }, -- Turn Evil
    },
    PRIEST = {
        { 8122,   "Disorient",    false, 8,  60 }, -- Psychic Scream
        { 605,    "Disorient",    true,  0,  30 }, -- Mind Control (channeled)
        { 9484,   "Incapacitate", true,  8,   0 }, -- Shackle Undead
    },
    ROGUE = {
        { 6770,   "Incapacitate", false, 8,   0 }, -- Sap
        { 2094,   "Disorient",    false, 8, 120 }, -- Blind
        { 408,    "Stun",         false, 6,  20 }, -- Kidney Shot
        { 1833,   "Stun",         false, 4,   0 }, -- Cheap Shot
        { 1776,   "Incapacitate", false, 4,  20 }, -- Gouge
        { 1766,   "Interrupt",    false, 5,  15 }, -- Kick
    },
    SHAMAN = {
        { 51514,  "Incapacitate", true,  8,  30 }, -- Hex
        { 192058, "Stun",         false, 3,  60 }, -- Capacitor Totem
        { 57994,  "Interrupt",    false, 2,  12 }, -- Wind Shear
    },
    WARLOCK = {
        { 5782,   "Disorient",    true,  8,   0 }, -- Fear
        { 6789,   "Incapacitate", false, 3,  45 }, -- Mortal Coil
        { 30283,  "Stun",         true,  3,  60 }, -- Shadowfury
        { 710,    "Incapacitate", true,  8,  30 }, -- Banish
        { 19647,  "Interrupt",    false, 6,  24 }, -- Spell Lock
    },
    WARRIOR = {
        { 5246,   "Disorient", false, 8, 90 }, -- Intimidating Shout
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
        { 207685, "Disorient", false, 8, 90 }, -- Sigil of Misery
    },

    -- Druid
    [103] = { -- Feral
        { 203123, "Stun", false, 5, 20 }, -- Maim
    },

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
    [265] = { -- Affliction
        { 5484, "Disorient", true, 8, 40 }, -- Howl of Terror
    },
}
