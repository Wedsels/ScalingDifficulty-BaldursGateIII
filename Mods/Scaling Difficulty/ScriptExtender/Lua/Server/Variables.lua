--- @diagnostic disable: missing-fields

--- @class _V
local _V = {}

_V.Key = "Scaling Difficulty"

--- @type Stats
_V.Stats = {}
--- @class Stats
--- @field HP number
--- @field PercentHP number
--- @field AC number
--- @field Attack number
--- @field DamageBonus number
--- @field Initiative number
--- @field Physical number
--- @field Casting number
--- @field Strength number
--- @field Dexterity number
--- @field Constitution number
--- @field Intelligence number
--- @field Wisdom number
--- @field Charisma number

--- @type Resource
_V.Resource = {}
--- @class Resource
--- @field Movement number
--- @field ActionPoint number
--- @field BonusActionPoint number
--- @field ReactionActionPoint number
--- @field SpellSlotLevel1 string
--- @field SpellSlotLevel2 string
--- @field SpellSlotLevel3 string
--- @field SpellSlotLevel4 string
--- @field SpellSlotLevel5 string
--- @field SpellSlotLevel6 string
--- @field SpellSlotLevel7 string
--- @field SpellSlotLevel8 string
--- @field SpellSlotLevel9 string
--- @field Rage number
--- @field KiPoint number
--- @field WildShape number
--- @field ChannelOath number
--- @field SorceryPoint number
--- @field SuperiorityDie number
--- @field ChannelDivinity number
--- @field BardicInspiration number

--- @type General
_V.General = {}
--- @class General
--- @field LevelBonus number
--- @field Downscaling boolean

--- @type Settings
_V.Settings = {}
--- @class Settings
--- @field General General
--- @field Bonus Stats
--- @field Leveling Stats
--- @field Resource Resource

--- @type table< string, Settings >
_V.Hub = {}
_V.NPC = {
    Enemy = true,
    Ally = true,
    Summon = true,
    Boss = true,
}

--- @class AC
--- @field Type boolean
--- @field ACBonus number
--- @field ACModifier number

--- @class Health
--- @field Hp number
--- @field MaxHp number
--- @field Percent number

--- @class Modifiers
--- @field Original Stats
--- @field Current Stats

--- @class Entity
--- @field Scaled boolean
--- @field Type string
--- @field Hub Settings
--- @field LevelBase number
--- @field LevelChange number
--- @field Constitution string
--- @field Physical string
--- @field Casting string
--- @field Stats Stats
--- @field OldStats Stats
--- @field OldResource Resource
--- @field AC AC
--- @field Health Health
--- @field Modifiers Modifiers

--- @type table< string, Entity >
_V.Entities = {}

_V.Abilities = {
    Strength = 2,
    Dexterity = 3,
    Constitution = 4,
    Intelligence = 5,
    Wisdom = 6,
    Charisma = 7
}

_V.Boosts = {
    Resource = "ActionResource( %s, %d, %d )",
    RollBonus = "RollBonus( %s, %d )",
    DamageBonus = "DamageBonus( %d )"
}

local class
for line in Ext.IO.LoadFile( "Mods/Scaling Difficulty/ScriptExtender/Lua/Server/Variables.lua", "data" ):gmatch( "[^\r\n]+" ) do
    if class then
        local field = line:match( "^%s*---%s*@field%s+([%w_]+)" )
        if field then
            table.insert( _V[ class ], field )
        else
            class = nil
        end
    elseif line:find( "--- @class" ) then
        local l = line:match( "^%s*---%s*@class%s+([%w_]+)" )
        if _V[ l ] then
            class = l
        end
    end
end

return _V