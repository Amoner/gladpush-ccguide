local addonName, addon = ...

local SPELL_SIZE = 22
local TYPE_SIZE = 18
local HEADER_SIZE = 26
local GRID_SIZE = 24
local GAP = 2
local FRAME_WIDTH = 620
local LEFT = 10
local CLASS_GAP = 10
local SLOT_START_X = 100
local COL_DIVIDER = 8
local COL_WIDTH = 0 -- calculated at runtime
local ROW_HEIGHT = SPELL_SIZE + 4

local userHidden = false
local isPreviewMode = false
local previewTeam = {}
local previewOpponents = {}
local activeTab = "cc" -- "cc", "offensive", "defensive", "immunity"

-------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------
local CLASS_ID = {
    WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,DEATHKNIGHT=6,
    SHAMAN=7,MAGE=8,WARLOCK=9,MONK=10,DRUID=11,DEMONHUNTER=12,EVOKER=13,
}

local function GetSpellIcon(id)
    if C_Spell and C_Spell.GetSpellTexture then
        local t = C_Spell.GetSpellTexture(id); if t then return t end
    end
    if GetSpellTexture then
        local t = GetSpellTexture(id); if t then return t end
    end
    return 134400
end

local function GetSpecIcon(id)
    if id then local _,_,_,icon = GetSpecializationInfoByID(id); if icon then return icon end end
    return 134400
end

local function GetSpecLabel(specID, cls)
    if specID and specID > 0 then
        local _,n = GetSpecializationInfoByID(specID)
        if n then return n end
    end
    local info = C_CreatureInfo.GetClassInfo(CLASS_ID[cls] or 0)
    return info and info.className or cls
end

local function SpellExists(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID) ~= nil
    end
    return GetSpellInfo(spellID) ~= nil
end

local function GetMergedCC(specID, cls)
    local r = {}
    for _, cc in ipairs(addon.CC_DATA[cls] or {}) do
        if SpellExists(cc[1]) then r[#r+1] = cc end
    end
    if specID and addon.SPEC_EXTRA[specID] then
        for _, cc in ipairs(addon.SPEC_EXTRA[specID]) do
            if SpellExists(cc[1]) then r[#r+1] = cc end
        end
    end
    return r
end

local function GetMergedCooldowns(specID, cls, cdType)
    local baseData, extraData
    if cdType == "offensive" then
        baseData = addon.OFFENSIVE_DATA; extraData = addon.OFFENSIVE_EXTRA
    elseif cdType == "defensive" then
        baseData = addon.DEFENSIVE_DATA; extraData = addon.DEFENSIVE_EXTRA
    elseif cdType == "immunity" then
        baseData = addon.IMMUNITY_DATA; extraData = addon.IMMUNITY_EXTRA
    end
    local r = {}
    for _, cd in ipairs(baseData and baseData[cls] or {}) do
        if SpellExists(cd[1]) then r[#r+1] = cd end
    end
    if specID and extraData and extraData[specID] then
        for _, cd in ipairs(extraData[specID]) do
            if SpellExists(cd[1]) then r[#r+1] = cd end
        end
    end
    return r
end

-------------------------------------------------------------------
-- Frame
-------------------------------------------------------------------
local frame = CreateFrame("Frame", "GladPushCCFrame", UIParent, "BackdropTemplate")
frame:SetSize(FRAME_WIDTH, 100); frame:SetPoint("CENTER")
frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p,_,rp,x,y = self:GetPoint()
    GladPushCCDB = GladPushCCDB or {}
    GladPushCCDB.point,GladPushCCDB.relPoint,GladPushCCDB.x,GladPushCCDB.y = p,rp,x,y
end)
frame:SetBackdrop({
    bgFile="Interface/Tooltips/UI-Tooltip-Background",
    edgeFile="Interface/Tooltips/UI-Tooltip-Border",
    tile=true, tileSize=16, edgeSize=16,
    insets={left=4,right=4,top=4,bottom=4},
})
frame:SetBackdropColor(0.02,0.02,0.03,1)
frame:SetBackdropBorderColor(0.3,0.3,0.3,1)
frame:SetFrameStrata("HIGH"); frame:SetFrameLevel(50)
frame:SetClampedToScreen(true); frame:Hide()

local titleText = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
titleText:SetPoint("TOP",frame,"TOP",0,-8)
titleText:SetText("|cFF00FF00GladPush|r.GG CD Guide")

local closeBtn = CreateFrame("Button",nil,frame,"UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT",-2,-2); closeBtn:SetSize(20,20)
closeBtn:SetScript("OnClick", function()
    frame:Hide(); userHidden=true; isPreviewMode=false
end)

-- Tab buttons
local tabButtons = {}
local function UpdateTabHighlights()
    for _, tb in ipairs(tabButtons) do
        if tb.tabKey == activeTab then
            tb:SetBackdropColor(0.2, 0.6, 0.2, 0.6)
            tb:SetBackdropBorderColor(0.3, 0.8, 0.3, 0.8)
            tb.text:SetTextColor(1, 1, 1)
        else
            tb:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            tb:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6)
            tb.text:SetTextColor(0.6, 0.6, 0.6)
        end
    end
end

local tabDefs = {
    { key = "cc",        label = "CC" },
    { key = "offensive", label = "Offensives" },
    { key = "defensive", label = "Defensives" },
    { key = "immunity",  label = "Immunities" },
}
for i, def in ipairs(tabDefs) do
    local tb = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    local tabW = math.floor((FRAME_WIDTH - LEFT*2 - 12) / #tabDefs)
    tb:SetSize(tabW, 20)
    tb:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", LEFT + (i-1)*(tabW+4), -2)
    tb:SetBackdrop({
        bgFile="Interface/BUTTONS/WHITE8X8", edgeFile="Interface/BUTTONS/WHITE8X8",
        edgeSize=1, insets={left=1,right=1,top=1,bottom=1},
    })
    tb.tabKey = def.key
    tb.text = tb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    tb.text:SetPoint("CENTER")
    tb.text:SetText(def.label)
    tb:EnableMouse(true)
    tb:SetScript("OnMouseDown", function()
        activeTab = def.key
        UpdateTabHighlights()
        UpdateDisplay()
    end)
    tabButtons[#tabButtons+1] = tb
end
UpdateTabHighlights()

-------------------------------------------------------------------
-- Dividers & Backgrounds
-------------------------------------------------------------------
local dividerPool, activeDividers = {}, {}
local function AcquireDivider()
    local d = tremove(dividerPool)
    if not d then
        d = frame:CreateTexture(nil,"ARTWORK")
        d:SetHeight(1); d:SetColorTexture(0.35,0.35,0.35,0.5)
    end
    d:ClearAllPoints(); d:Show()
    activeDividers[#activeDividers+1] = d; return d
end

local bgPool, activeBGs = {}, {}
local function AcquireBG()
    local bg = tremove(bgPool)
    if not bg then
        bg = frame:CreateTexture(nil,"BACKGROUND",nil,1)
    end
    bg:ClearAllPoints(); bg:Show()
    activeBGs[#activeBGs+1] = bg; return bg
end

-------------------------------------------------------------------
-- Pools
-------------------------------------------------------------------
local pools = { spell={}, type={}, header={}, label={} }
local active = { spell={}, type={}, header={}, label={} }

local function ReleaseAll()
    for kind, list in pairs(active) do
        for i=#list,1,-1 do list[i]:Hide(); list[i]:ClearAllPoints(); pools[kind][#pools[kind]+1]=list[i]; list[i]=nil end
    end
    for i=#activeDividers,1,-1 do activeDividers[i]:Hide(); activeDividers[i]:ClearAllPoints(); dividerPool[#dividerPool+1]=activeDividers[i]; activeDividers[i]=nil end
    for i=#activeBGs,1,-1 do activeBGs[i]:Hide(); activeBGs[i]:ClearAllPoints(); bgPool[#bgPool+1]=activeBGs[i]; activeBGs[i]=nil end
end

local function AcquireLabel()
    local l = tremove(pools.label)
    if not l then
        l = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        l:SetJustifyH("LEFT")
    end
    l:ClearAllPoints(); l:SetTextColor(1,1,1,1)
    if GameFontNormalSmall then l:SetFontObject(GameFontNormalSmall) end
    l:SetJustifyH("LEFT"); l:Show()
    active.label[#active.label+1] = l; return l
end

local function AcquireSpellIcon()
    local icon = tremove(pools.spell)
    if not icon then
        icon = CreateFrame("Frame",nil,frame,"BackdropTemplate")
        icon:SetSize(SPELL_SIZE,SPELL_SIZE)
        icon:SetBackdrop({
            bgFile="Interface/BUTTONS/WHITE8X8", edgeFile="Interface/BUTTONS/WHITE8X8",
            edgeSize=1, insets={left=1,right=1,top=1,bottom=1},
        })
        icon:SetBackdropColor(0,0,0,0.8); icon:SetBackdropBorderColor(0.25,0.25,0.25,1)
        icon.tex = icon:CreateTexture(nil,"ARTWORK")
        icon.tex:SetPoint("TOPLEFT",1,-1); icon.tex:SetPoint("BOTTOMRIGHT",-1,1)
        icon.tex:SetTexCoord(0.08,0.92,0.08,0.92)
        icon.castMark = icon:CreateTexture(nil,"OVERLAY")
        icon.castMark:SetSize(6,6); icon.castMark:SetPoint("TOPRIGHT",0,0)
        icon.castMark:SetColorTexture(1,0.82,0,1); icon.castMark:Hide()
        icon:EnableMouse(true)
        icon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            if self.spellID then
                GameTooltip:SetSpellByID(self.spellID)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("DR Category:", self.ccType or "?", 0.6,0.6,0.6,1,1,1)
                if self.isCast then
                    GameTooltip:AddLine("Has cast time — can be interrupted",1,0.82,0)
                else
                    GameTooltip:AddLine("Instant cast",0.5,0.5,0.5)
                end
            end
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    icon:ClearAllPoints(); icon:Show()
    active.spell[#active.spell+1] = icon; return icon
end

local function AcquireTypeIcon()
    local icon = tremove(pools.type)
    if not icon then
        icon = CreateFrame("Frame",nil,frame)
        icon:SetSize(TYPE_SIZE,TYPE_SIZE)
        icon.tex = icon:CreateTexture(nil,"ARTWORK")
        icon.tex:SetAllPoints(); icon.tex:SetTexCoord(0.08,0.92,0.08,0.92)
        icon:EnableMouse(true)
        icon:SetScript("OnEnter", function(self)
            if self.ccType then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:SetText(self.ccType)
                GameTooltip:AddLine("Diminishing Returns category",0.7,0.7,0.7)
                GameTooltip:Show()
            end
        end)
        icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    icon:ClearAllPoints(); icon:Show()
    active.type[#active.type+1] = icon; return icon
end

local function AcquireHeader()
    local h = tremove(pools.header)
    if not h then
        h = CreateFrame("Frame",nil,frame,"BackdropTemplate")
        h:SetSize(HEADER_SIZE,HEADER_SIZE)
        h:SetBackdrop({
            bgFile="Interface/BUTTONS/WHITE8X8", edgeFile="Interface/BUTTONS/WHITE8X8",
            edgeSize=1, insets={left=1,right=1,top=1,bottom=1},
        })
        h:SetBackdropColor(0,0,0,0.6)
        h.tex = h:CreateTexture(nil,"ARTWORK")
        h.tex:SetPoint("TOPLEFT",1,-1); h.tex:SetPoint("BOTTOMRIGHT",-1,1)
        h.tex:SetTexCoord(0.08,0.92,0.08,0.92)
        h:EnableMouse(true)
        h:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    h:ClearAllPoints(); h:Show()
    active.header[#active.header+1] = h; return h
end

-------------------------------------------------------------------
-- Build one player's CC section in a column
-- player = { specID (or nil), classToken, name (or nil) }
-- colX = left edge of this column, colW = column width
-------------------------------------------------------------------
local function AddPlayerBlock(player, startY, colX, colW)
    local specID, cls, name = player[1], player[2], player[3]

    -- Get data based on active tab
    local items
    if activeTab == "cc" then
        items = GetMergedCC(specID, cls)
    else
        items = GetMergedCooldowns(specID, cls, activeTab)
    end
    if #items == 0 then return startY end

    -- For CC tab: group by DR type. For cooldown tabs: show flat list.
    local rows = {}
    if activeTab == "cc" then
        local byType, typeOrder, typeSeen = {}, {}, {}
        for _, cc in ipairs(items) do
            local t = cc[2]
            if not typeSeen[t] then typeSeen[t]=true; typeOrder[#typeOrder+1]=t end
            if not byType[t] then byType[t]={} end
            byType[t][#byType[t]+1] = cc
        end
        local ord = {}
        for i,t in ipairs(addon.CC_ORDER) do ord[t]=i end
        table.sort(typeOrder, function(a,b) return (ord[a] or 99) < (ord[b] or 99) end)
        for _, t in ipairs(typeOrder) do
            rows[#rows+1] = { label = t, icon = addon.CC_TYPE_ICONS[t], spells = byType[t], isCC = true }
        end
    elseif activeTab == "immunity" then
        -- Immunities: spell + name + immune type + description
        for _, cd in ipairs(items) do
            rows[#rows+1] = { spellID = cd[1], label = cd[2], cooldown = cd[3], immuneType = cd[4], description = cd[5], isImmunity = true }
        end
    else
        -- Offensive/Defensive: each spell is its own row with name + cooldown
        for _, cd in ipairs(items) do
            rows[#rows+1] = { spellID = cd[1], label = cd[2], cooldown = cd[3] }
        end
    end

    -- Player header: class-colored bar + spec icon + name
    local classColor = RAID_CLASS_COLORS[cls]
    local hex = classColor and classColor:GenerateHexColor() or "ffffffff"
    local specLabel = GetSpecLabel(specID, cls)
    local displayName = name and (name .. " - " .. specLabel) or specLabel

    local nameBG = AcquireBG()
    nameBG:SetPoint("TOPLEFT", frame, "TOPLEFT", colX, startY + 2)
    nameBG:SetSize(colW, HEADER_SIZE + 2)
    if classColor then
        nameBG:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.15)
    else
        nameBG:SetColorTexture(0.3, 0.3, 0.3, 0.15)
    end

    local hi = AcquireHeader()
    hi:SetPoint("TOPLEFT", frame, "TOPLEFT", colX + 2, startY)
    hi.tex:SetTexture(specID and GetSpecIcon(specID) or 134400)
    hi:SetBackdropBorderColor(
        classColor and classColor.r or 0.3,
        classColor and classColor.g or 0.3,
        classColor and classColor.b or 0.3, 0.8)
    hi:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText(displayName)
        GameTooltip:Show()
    end)

    local nl = AcquireLabel()
    nl:SetPoint("LEFT", hi, "RIGHT", 6, 0)
    nl:SetText("|c" .. hex .. displayName .. "|r")

    startY = startY - (HEADER_SIZE + 4)

    local rowIdx = 0
    for _, row in ipairs(rows) do
        local thisRowH = (row.isCC) and (SPELL_SIZE + 14) or ROW_HEIGHT
        local rowBG = AcquireBG()
        rowBG:SetPoint("TOPLEFT", frame, "TOPLEFT", colX, startY + 1)
        rowBG:SetSize(colW, thisRowH)
        if rowIdx % 2 == 0 then
            rowBG:SetColorTexture(1, 1, 1, 0.04)
        else
            rowBG:SetColorTexture(0, 0, 0, 0.1)
        end
        rowIdx = rowIdx + 1

        if row.isCC then
            -- CC row: type icon + spell icons with duration/cd labels
            local ti = AcquireTypeIcon()
            ti:SetPoint("TOPLEFT", frame, "TOPLEFT", colX + 4, startY - (SPELL_SIZE - TYPE_SIZE)/2)
            ti.tex:SetTexture(GetSpellIcon(row.icon or 0))
            ti.ccType = row.label

            local xOff = colX + TYPE_SIZE + 8
            for _, spell in ipairs(row.spells) do
                local si = AcquireSpellIcon()
                si:SetPoint("TOPLEFT", frame, "TOPLEFT", xOff, startY)
                si.tex:SetTexture(GetSpellIcon(spell[1]))
                si.spellID = spell[1]; si.ccType = row.label; si.isCast = spell[3]
                if spell[3] then si.castMark:Show() else si.castMark:Hide() end

                -- Duration/CD label below or beside icon
                local dur = spell[4] or 0
                local cd = spell[5] or 0
                local infoText = ""
                if dur > 0 then infoText = dur .. "s" end
                if cd > 0 then
                    infoText = infoText .. (infoText ~= "" and "/" or "") .. cd
                end
                local infoLabel = AcquireLabel()
                infoLabel:SetPoint("TOP", si, "BOTTOM", 0, 0)
                infoLabel:SetJustifyH("CENTER")
                infoLabel:SetTextColor(0.5,0.5,0.5)
                local fontPath = infoLabel:GetFont()
                if fontPath then infoLabel:SetFont(fontPath, 7, "OUTLINE") end
                infoLabel:SetText(infoText)

                xOff = xOff + SPELL_SIZE + GAP + 8
            end
        elseif row.isImmunity then
            -- Immunity row: spell icon + name + immune type tag
            local si = AcquireSpellIcon()
            si:SetPoint("TOPLEFT", frame, "TOPLEFT", colX + 4, startY)
            si.tex:SetTexture(GetSpellIcon(row.spellID))
            si.spellID = row.spellID; si.ccType = nil; si.isCast = false
            si.castMark:Hide()
            si:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                if self.spellID then GameTooltip:SetSpellByID(self.spellID) end
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Immune to:", row.immuneType or "?", 0.6,0.6,0.6, 1,0.4,0.4)
                GameTooltip:AddLine(row.description or "", 1, 0.82, 0, true)
                GameTooltip:AddDoubleLine("Cooldown:", row.cooldown .. "s", 0.6,0.6,0.6, 1,1,1)
                GameTooltip:Show()
            end)

            local cdName = AcquireLabel()
            cdName:SetPoint("LEFT", si, "RIGHT", 4, 0)
            cdName:SetTextColor(0.85,0.85,0.85)
            cdName:SetText(row.label)

            local immTag = AcquireLabel()
            immTag:SetPoint("RIGHT", frame, "TOPLEFT", colX + colW - 4, startY - SPELL_SIZE/2)
            immTag:SetJustifyH("RIGHT")
            immTag:SetTextColor(1, 0.4, 0.4)
            immTag:SetText(row.immuneType or "")
        else
            -- Cooldown row: spell icon + name + cooldown duration
            local si = AcquireSpellIcon()
            si:SetPoint("TOPLEFT", frame, "TOPLEFT", colX + 4, startY)
            si.tex:SetTexture(GetSpellIcon(row.spellID))
            si.spellID = row.spellID; si.ccType = nil; si.isCast = false
            si.castMark:Hide()

            local cdName = AcquireLabel()
            cdName:SetPoint("LEFT", si, "RIGHT", 4, 0)
            cdName:SetTextColor(0.85,0.85,0.85)
            cdName:SetText(row.label)

            local cdTime = AcquireLabel()
            cdTime:SetPoint("RIGHT", frame, "TOPLEFT", colX + colW - 4, startY - SPELL_SIZE/2)
            cdTime:SetJustifyH("RIGHT")
            cdTime:SetTextColor(0.55,0.55,0.55)
            cdTime:SetText(row.cooldown .. "s")
        end
        local thisRowH = (row.isCC) and (SPELL_SIZE + 14) or ROW_HEIGHT
        startY = startY - thisRowH
    end
    return startY - 2
end

-------------------------------------------------------------------
-- Build a team column
-------------------------------------------------------------------
local function BuildTeamColumn(players, startY, colX, colW, title, isOpponent)
    if #players == 0 then return startY end

    local hdrBG = AcquireBG()
    local hdr = AcquireLabel()
    hdr:SetPoint("TOPLEFT", frame, "TOPLEFT", colX + 2, startY)
    hdr:SetText(title)
    hdrBG:SetPoint("TOPLEFT", frame, "TOPLEFT", colX, startY + 3)
    hdrBG:SetSize(colW, 16)
    if isOpponent then
        hdrBG:SetColorTexture(0.4, 0.08, 0.08, 0.35)
    else
        hdrBG:SetColorTexture(0.08, 0.3, 0.08, 0.35)
    end
    startY = startY - 16

    for _, player in ipairs(players) do
        startY = AddPlayerBlock(player, startY, colX, colW)
    end
    return startY - 2
end

-------------------------------------------------------------------
-- Gather arena players: returns { {specID, classToken, name}, ... }
-------------------------------------------------------------------
local function GatherTeam()
    local players = {}
    -- Self
    local myIdx = GetSpecialization()
    if myIdx then
        local sid = GetSpecializationInfo(myIdx)
        local _, myClass = UnitClass("player")
        if sid and myClass then
            players[#players+1] = { sid, myClass, UnitName("player") }
        end
    end
    -- Party
    for i = 1, 4 do
        local unit = "party"..i
        if UnitExists(unit) then
            local _, classToken = UnitClass(unit)
            if classToken then
                local sid = GetInspectSpecialization(unit)
                if not sid or sid == 0 then sid = nil end
                players[#players+1] = { sid, classToken, UnitName(unit) }
            end
        end
    end
    return players
end

local function GatherOpponents()
    local players = {}
    for i = 1, 5 do
        local sid = GetArenaOpponentSpec(i)
        if sid and sid > 0 then
            local cls = addon.SPEC_TO_CLASS[sid]
            if cls then
                players[#players+1] = { sid, cls, nil }
            end
        end
    end
    return players
end

local function SpecIDsToPlayers(specIDs)
    local players = {}
    for _, sid in ipairs(specIDs) do
        local cls = addon.SPEC_TO_CLASS[sid]
        if cls then players[#players+1] = { sid, cls, nil } end
    end
    return players
end

-------------------------------------------------------------------
-- Spec picker
-------------------------------------------------------------------
local pickerFrame = CreateFrame("Frame",nil,frame)
pickerFrame:SetPoint("TOPLEFT",0,0); pickerFrame:SetPoint("RIGHT",0,0); pickerFrame:Hide()

local teamLabel = pickerFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
local oppLabel = pickerFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")

local teamSlots, oppSlots = {}, {}
local function MakeSlot(parent, list, idx)
    local btn = CreateFrame("Button",nil,parent,"BackdropTemplate")
    btn:SetSize(HEADER_SIZE,HEADER_SIZE)
    btn:SetBackdrop({
        bgFile="Interface/BUTTONS/WHITE8X8", edgeFile="Interface/BUTTONS/WHITE8X8",
        edgeSize=1, insets={left=1,right=1,top=1,bottom=1},
    })
    btn:SetBackdropColor(0,0,0,0.5); btn:SetBackdropBorderColor(0.4,0.4,0.4,0.6)
    btn.tex = btn:CreateTexture(nil,"ARTWORK")
    btn.tex:SetPoint("TOPLEFT",1,-1); btn.tex:SetPoint("BOTTOMRIGHT",-1,1)
    btn.tex:SetTexCoord(0.08,0.92,0.08,0.92)
    btn:SetScript("OnClick", function() table.remove(list,idx); UpdateDisplay() end)
    btn:SetScript("OnEnter", function(self)
        if self.specID then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            local _,n = GetSpecializationInfoByID(self.specID)
            GameTooltip:SetText(n or "?"); GameTooltip:AddLine("Click to remove",1,0.3,0.3)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:Hide(); return btn
end
for i=1,3 do
    teamSlots[i] = MakeSlot(pickerFrame, previewTeam, i)
    oppSlots[i] = MakeSlot(pickerFrame, previewOpponents, i)
end

local clearTeam = CreateFrame("Button",nil,pickerFrame,"UIPanelButtonTemplate")
clearTeam:SetSize(44,18); clearTeam:SetText("Clear"); clearTeam:SetNormalFontObject("GameFontNormalSmall")
clearTeam:SetScript("OnClick", function() wipe(previewTeam); UpdateDisplay() end)
local clearOpp = CreateFrame("Button",nil,pickerFrame,"UIPanelButtonTemplate")
clearOpp:SetSize(44,18); clearOpp:SetText("Clear"); clearOpp:SetNormalFontObject("GameFontNormalSmall")
clearOpp:SetScript("OnClick", function() wipe(previewOpponents); UpdateDisplay() end)

local gridIcons = {}
local gridBuilt = false
local function BuildSpecGrid(yStart)
    if gridBuilt then return end
    gridBuilt = true
    local x, y = LEFT, yStart
    for _, classInfo in ipairs(addon.CLASS_SPECS) do
        local classToken, specs = classInfo[1], classInfo[2]
        local cc = RAID_CLASS_COLORS[classToken]
        local groupWidth = #specs * (GRID_SIZE + GAP)
        if x > LEFT and x + groupWidth > FRAME_WIDTH - LEFT then
            x = LEFT; y = y - (GRID_SIZE + 6)
        end
        for _, specID in ipairs(specs) do
            local btn = CreateFrame("Button",nil,pickerFrame,"BackdropTemplate")
            btn:SetSize(GRID_SIZE,GRID_SIZE); btn.specID=specID; btn.classToken=classToken
            btn:SetBackdrop({
                bgFile="Interface/BUTTONS/WHITE8X8", edgeFile="Interface/BUTTONS/WHITE8X8",
                edgeSize=1, insets={left=1,right=1,top=1,bottom=1},
            })
            btn:SetBackdropColor(0,0,0,0.4)
            if cc then btn:SetBackdropBorderColor(cc.r,cc.g,cc.b,0.7)
            else btn:SetBackdropBorderColor(0.4,0.4,0.4,0.6) end
            local tex = btn:CreateTexture(nil,"ARTWORK")
            tex:SetPoint("TOPLEFT",1,-1); tex:SetPoint("BOTTOMRIGHT",-1,1)
            tex:SetTexture(GetSpecIcon(specID)); tex:SetTexCoord(0.08,0.92,0.08,0.92)
            btn:RegisterForClicks("AnyUp")
            btn:SetScript("OnClick", function(self, button)
                local list = button=="RightButton" and previewOpponents or previewTeam
                if #list < 3 then list[#list+1]=self.specID; UpdateDisplay() end
            end)
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                local _,n = GetSpecializationInfoByID(self.specID)
                GameTooltip:SetText(n or "?")
                GameTooltip:AddLine("Left-click: Team",0,1,0)
                GameTooltip:AddLine("Right-click: Opponents",1,0.3,0.3)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            gridIcons[#gridIcons+1] = btn
            x = x + GRID_SIZE + GAP
        end
        x = x + CLASS_GAP
    end
end

local function PositionGrid(yStart)
    local x, y = LEFT, yStart
    for idx, btn in ipairs(gridIcons) do
        if idx > 1 and gridIcons[idx-1].classToken ~= btn.classToken then
            local groupCount = 0
            for j = idx, #gridIcons do
                if gridIcons[j].classToken == btn.classToken then groupCount=groupCount+1
                else break end
            end
            if x + groupCount*(GRID_SIZE+GAP) > FRAME_WIDTH - LEFT then
                x = LEFT; y = y - (GRID_SIZE + 6)
            end
        end
        btn:ClearAllPoints(); btn:SetPoint("TOPLEFT",pickerFrame,"TOPLEFT",x,y)
        x = x + GRID_SIZE + GAP
        local nextBtn = gridIcons[idx+1]
        if nextBtn and nextBtn.classToken ~= btn.classToken then x = x + CLASS_GAP end
    end
    return y - (GRID_SIZE + 6)
end

-------------------------------------------------------------------
-- Update display
-------------------------------------------------------------------
function UpdateDisplay()
    addon:DiscoverSpecs()
    ReleaseAll()

    if isPreviewMode then
        local py = -28

        -- Team slots
        teamLabel:ClearAllPoints(); teamLabel:SetPoint("TOPLEFT",pickerFrame,"TOPLEFT",LEFT,py)
        teamLabel:SetText("|cFF00FF00TEAM:|r"); teamLabel:Show()
        for i=1,3 do
            teamSlots[i]:ClearAllPoints()
            if previewTeam[i] then
                teamSlots[i]:SetPoint("TOPLEFT",pickerFrame,"TOPLEFT",SLOT_START_X+(i-1)*(HEADER_SIZE+4),py+1)
                teamSlots[i].tex:SetTexture(GetSpecIcon(previewTeam[i]))
                teamSlots[i].specID=previewTeam[i]; teamSlots[i]:Show()
            else teamSlots[i]:Hide() end
        end
        clearTeam:ClearAllPoints()
        clearTeam:SetPoint("TOPLEFT",pickerFrame,"TOPLEFT",SLOT_START_X+3*(HEADER_SIZE+4)+6,py+4)
        clearTeam:Show()
        py = py - (HEADER_SIZE + 8)

        oppLabel:ClearAllPoints(); oppLabel:SetPoint("TOPLEFT",pickerFrame,"TOPLEFT",LEFT,py)
        oppLabel:SetText("|cFFFF4040OPPONENTS:|r"); oppLabel:Show()
        for i=1,3 do
            oppSlots[i]:ClearAllPoints()
            if previewOpponents[i] then
                oppSlots[i]:SetPoint("TOPLEFT",pickerFrame,"TOPLEFT",SLOT_START_X+(i-1)*(HEADER_SIZE+4),py+1)
                oppSlots[i].tex:SetTexture(GetSpecIcon(previewOpponents[i]))
                oppSlots[i].specID=previewOpponents[i]; oppSlots[i]:Show()
            else oppSlots[i]:Hide() end
        end
        clearOpp:ClearAllPoints()
        clearOpp:SetPoint("TOPLEFT",pickerFrame,"TOPLEFT",SLOT_START_X+3*(HEADER_SIZE+4)+6,py+4)
        clearOpp:Show()
        py = py - (HEADER_SIZE + 8)

        -- Divider
        local d1 = AcquireDivider()
        d1:SetPoint("LEFT",frame,"LEFT",LEFT,0); d1:SetPoint("RIGHT",frame,"RIGHT",-LEFT,0)
        d1:SetPoint("TOP",frame,"TOP",0,py+3); py = py - 4

        -- Hint
        local hint = AcquireLabel()
        hint:SetPoint("TOP",frame,"TOP",0,py); hint:SetJustifyH("CENTER")
        hint:SetTextColor(0.45,0.45,0.45)
        hint:SetText("Left-click = Team  ·  Right-click = Opponents")
        py = py - 14

        -- Spec grid
        BuildSpecGrid(py)
        local gridBottom = PositionGrid(py)
        pickerFrame:SetHeight(-gridBottom+30); pickerFrame:Show()

        -- Divider
        local d2 = AcquireDivider()
        d2:SetPoint("LEFT",frame,"LEFT",LEFT,0); d2:SetPoint("RIGHT",frame,"RIGHT",-LEFT,0)
        d2:SetPoint("TOP",frame,"TOP",0,gridBottom+2)

        -- CC breakdown side by side
        COL_WIDTH = math.floor((FRAME_WIDTH - LEFT*2 - COL_DIVIDER) / 2)
        local col1X = LEFT
        local col2X = LEFT + COL_WIDTH + COL_DIVIDER
        local ccStartY = gridBottom - 4

        local teamY = BuildTeamColumn(SpecIDsToPlayers(previewTeam), ccStartY, col1X, COL_WIDTH, "|cFF00FF00TEAM|r")
        local oppY = BuildTeamColumn(SpecIDsToPlayers(previewOpponents), ccStartY, col2X, COL_WIDTH, "|cFFFF4040OPPONENTS|r", true)

        -- Vertical divider
        if #previewTeam > 0 or #previewOpponents > 0 then
            local vdiv = AcquireBG()
            vdiv:SetPoint("TOPLEFT", frame, "TOPLEFT", col2X - math.floor(COL_DIVIDER/2), ccStartY + 3)
            vdiv:SetSize(1, math.abs(math.min(teamY, oppY) - ccStartY) + 4)
            vdiv:SetColorTexture(0.35, 0.35, 0.35, 0.5)
        end

        local y = math.min(teamY, oppY) - 2
        local leg = AcquireLabel(); leg:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT,y)
        leg:SetTextColor(0.4,0.4,0.4)
        leg:SetText("Hover icons for spell details")
        y = y - 14
        frame:SetHeight(-y+6); frame:Show()
    else
        -- LIVE ARENA
        local _, inst = IsInInstance()
        if inst ~= "arena" then frame:Hide(); return end
        if userHidden then return end
        pickerFrame:Hide()

        local teamPlayers = GatherTeam()
        local oppPlayers = GatherOpponents()

        COL_WIDTH = math.floor((FRAME_WIDTH - LEFT*2 - COL_DIVIDER) / 2)
        local col1X = LEFT
        local col2X = LEFT + COL_WIDTH + COL_DIVIDER
        local startY = -28

        local teamY = BuildTeamColumn(teamPlayers, startY, col1X, COL_WIDTH, "|cFF00FF00YOUR TEAM|r")
        local oppY = BuildTeamColumn(oppPlayers, startY, col2X, COL_WIDTH, "|cFFFF4040OPPONENTS|r", true)

        -- Vertical divider between columns
        local vdiv = AcquireBG()
        vdiv:SetPoint("TOPLEFT", frame, "TOPLEFT", col2X - math.floor(COL_DIVIDER/2), startY + 3)
        vdiv:SetSize(1, math.abs(math.min(teamY, oppY) - startY) + 4)
        vdiv:SetColorTexture(0.35, 0.35, 0.35, 0.5)

        local y = math.min(teamY, oppY) - 2
        local leg = AcquireLabel(); leg:SetPoint("TOPLEFT",frame,"TOPLEFT",LEFT,y)
        leg:SetTextColor(0.4,0.4,0.4)
        leg:SetText("Hover icons for spell details")
        y = y - 14
        frame:SetHeight(-y+6); frame:Show()
    end
end

-------------------------------------------------------------------
-- Events
-------------------------------------------------------------------
local function InspectPartyMembers()
    for i=1,4 do
        local unit = "party"..i
        if UnitExists(unit) and UnitIsConnected(unit) then
            C_Timer.After(i*0.3, function()
                if UnitExists(unit) then NotifyInspect(unit) end
            end)
        end
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
frame:RegisterEvent("ARENA_OPPONENT_UPDATE")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("INSPECT_READY")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        GladPushCCDB = GladPushCCDB or {}
        if GladPushCCDB.point then
            frame:ClearAllPoints()
            frame:SetPoint(GladPushCCDB.point,UIParent,GladPushCCDB.relPoint,GladPushCCDB.x,GladPushCCDB.y)
        end
        local _, inst = IsInInstance()
        if inst == "arena" then
            isPreviewMode=false; userHidden=false
            InspectPartyMembers()
            UpdateDisplay()
        elseif not isPreviewMode then frame:Hide() end
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        isPreviewMode=false; userHidden=false
        InspectPartyMembers()
        UpdateDisplay()
    elseif event == "INSPECT_READY" then
        if not isPreviewMode then UpdateDisplay() end
    elseif event == "ARENA_OPPONENT_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
        if not isPreviewMode then
            InspectPartyMembers()
            UpdateDisplay()
        end
    end
end)

SLASH_GLADPUSHCC1 = "/gpcc"
SlashCmdList["GLADPUSHCC"] = function(input)
    input = strtrim(input or "")
    if input == "" then
        if frame:IsShown() and not isPreviewMode then
            frame:Hide(); userHidden=true
        else
            isPreviewMode=true; userHidden=false; UpdateDisplay()
        end
    elseif input:lower() == "audit" then
        addon:DiscoverSpecs()
        local _, myClass = UnitClass("player")
        local mySpecIdx = GetSpecialization()
        local mySpecID = mySpecIdx and GetSpecializationInfo(mySpecIdx)
        local _, specName = mySpecID and GetSpecializationInfoByID(mySpecID) or nil, "Unknown"
        print("|cFF00FF00GladPush CC Audit|r — " .. (specName or "") .. " " .. (myClass or ""))
        for _, cc in ipairs(addon.CC_DATA[myClass] or {}) do
            local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(cc[1]) or GetSpellInfo(cc[1]) or "?"
            local known = IsPlayerSpell(cc[1]) or IsSpellKnown(cc[1])
            if known then print("  |cFF00FF00OK|r "..name.." ("..cc[1]..") — "..cc[2])
            else print("  |cFFFF0000MISSING|r "..name.." ("..cc[1]..") — "..cc[2]) end
        end
        if mySpecID and addon.SPEC_EXTRA[mySpecID] then
            for _, cc in ipairs(addon.SPEC_EXTRA[mySpecID]) do
                local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(cc[1]) or GetSpellInfo(cc[1]) or "?"
                local known = IsPlayerSpell(cc[1]) or IsSpellKnown(cc[1])
                if known then print("  |cFF00FF00OK|r "..name.." ("..cc[1]..") — "..cc[2])
                else print("  |cFFFF0000MISSING|r "..name.." ("..cc[1]..") — "..cc[2]) end
            end
        end
    else
        print("|cFF00FF00GladPush CC|r — /gpcc to toggle, /gpcc audit to check data")
    end
end
