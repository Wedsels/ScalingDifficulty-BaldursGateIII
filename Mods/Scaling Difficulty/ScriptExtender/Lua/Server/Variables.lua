--- @diagnostic disable: missing-fields

--- @class _V
local _V = {}

_V.Key = "Scaling Difficulty"
_V.Seed = 0
_V.Reset = false

--- @type Stats
_V.Stats = {}
--- @class Stats
--- @field Enabled boolean
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
--- @field Experience number
--- @field PercentExperience number
--- @field Size number

--- @type Resource
_V.Resource = {}
--- @class Resource
--- @field Enabled boolean
--- @field SpellSlotLevel1 string
--- @field SpellSlotLevel2 string
--- @field SpellSlotLevel3 string
--- @field SpellSlotLevel4 string
--- @field SpellSlotLevel5 string
--- @field SpellSlotLevel6 string
--- @field SpellSlotLevel7 string
--- @field SpellSlotLevel8 string
--- @field SpellSlotLevel9 string
--- @field Movement string
--- @field ActionPoint string
--- @field BonusActionPoint string
--- @field ReactionActionPoint string
--- @field Rage string
--- @field KiPoint string
--- @field WildShape string
--- @field ChannelOath string
--- @field SorceryPoint string
--- @field SuperiorityDie string
--- @field ChannelDivinity string
--- @field BardicInspiration string

--- @type General
_V.General = {}
--- @class General
--- @field Enabled boolean
--- @field LevelBonus number
--- @field Downscaling boolean
--- @field ExperienceLevel boolean
--- @field Spells number
--- @field SpellBlacklist string

--- @type Settings
_V.Settings = {}
--- @class Settings
--- @field General General
--- @field Bonus Stats
--- @field Leveling Stats
--- @field Variation Stats
--- @field Resource Resource

--- @type table< string, Settings >
_V.Hub = {}
_V.NPC = {
    Enemy = true,
    Ally = true,
    Summon = true,
    Boss = true,
    Player = true
}

--- @class Health
--- @field Hp number
--- @field MaxHp number
--- @field Percent number
--- @field Transformed boolean
--- @field TransformedHp number
--- @field TransformedMaxHp number
--- @field TransformedPercent number

--- @class Modifiers
--- @field Original Stats
--- @field Current Stats

--- @class Entity
--- @field Name string
--- @field Scaled boolean
--- @field Type string
--- @field Hub Settings
--- @field LevelBase number
--- @field LevelChange number
--- @field Experience table< number >
--- @field Constitution string
--- @field Physical string
--- @field Casting string
--- @field Stats Stats
--- @field Skills table< number >
--- @field Resource Resource
--- @field OldStats Stats
--- @field OldSkills table< number >
--- @field OldResource Resource
--- @field OldSpells number
--- @field OldBlacklist string
--- @field OldSize number
--- @field OldWeight number
--- @field Health Health
--- @field Modifiers Modifiers
--- @field CleanBoosts boolean
--- @field Class table< table< table< string > > >

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
    DamageBonus = "DamageBonus( %d )",
    Size = "ScaleMultiplier( %f );CarryCapacityMultiplier( %f );Weight( %d )"
}

--- @type table< string, table< string > >
_V.Classes = {}
for _,type in pairs( Ext.StaticData.GetAll( "Progression" ) ) do
    local data = Ext.StaticData.Get( type, "Progression" )
    if data.IsMulticlass then
        _V.Classes[ data.Name ] = {}
    end
end
local Blacklist = {
    Target_Shove = true,
    Target_Help = true,
    Target_Dip = true,
    Shout_Hide = true,
    Shout_Dash = true,
    Shout_Disengage = true,
    Throw_Throw = true,
    Throw_ImprovisedWeapon = true,
    Projectile_Jump = true,
}
--- @type table< string, table< table< string > > >
_V.SpellLists = {}
for _,uuid in ipairs( Ext.StaticData.GetAll( "SpellList" ) ) do
    local data = Ext.StaticData.Get( uuid, "SpellList" )
    local name = data.Name

    if name and name ~= "" and not Blacklist[ name ] then
        for class,list in pairs( _V.Classes ) do
            if name:find( class ) then
                for _,dsp in pairs( data.Spells ) do
                    local unique = true

                    for _,tsp in ipairs( list ) do
                        unique = dsp ~= tsp
                        if not unique then break end
                    end

                    if unique then
                        table.insert( list, dsp )
                        _V.SpellLists[ dsp ] = _V.SpellLists[ dsp ] or {}
                        table.insert( _V.SpellLists[ dsp ], list )
                    end
                end

                break
            end
        end
    end
end

_V.JsonBlueprint = Ext.Json.Parse( Ext.IO.LoadFile( "Mods/Scaling Difficulty/MCM_blueprint.json", "data" ) )

--- @type table< string, table< string > >
_V.SpellNames = {}
for _,spell in ipairs( Ext.Stats.GetStats( "SpellData" ) ) do
    local data = Ext.Stats.Get( spell )
    local name = Ext.Loca.GetTranslatedString( data.DisplayName ):gsub( "[%s%p]", "" ):lower()
    _V.SpellNames[ name ] = _V.SpellNames[ name ] or {}
    table.insert( _V.SpellNames[ name ], spell )
end

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