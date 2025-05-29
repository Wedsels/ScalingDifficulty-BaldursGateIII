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
--- @field Initiative number
--- @field Physical number
--- @field Casting number
--- @field Strength number
--- @field Dexterity number
--- @field Constitution number
--- @field Intelligence number
--- @field Wisdom number
--- @field Charisma number

--- @type General
_V.General = {}
--- @class General
--- @field LevelBonus number
--- @field Downscaling boolean

--- @type Core
_V.Core = {}
--- @class Core
--- @field Bonus Stats
--- @field Leveling Stats
--- @field General General

--- @type table< "Enemy" | "Ally" | "Summon" | "Boss", Core >
_V.Hub = {}

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
--- @field Hub Core
--- @field LevelBase number
--- @field LevelChange number
--- @field Constitution string
--- @field Physical string
--- @field Casting string
--- @field Stats Stats
--- @field OldStats Stats
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

return _V