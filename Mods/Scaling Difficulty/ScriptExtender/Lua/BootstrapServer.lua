local Key = "Scaling Difficulty"
local Started = false
local Downscaling = false
local PartyLevel = 0

local function DCCPY( org )
    local copy = {}
    for k,v in pairs( org ) do
        if type( v ) == "table" then
            copy[ k ] = DCCPY( v )
        else
            copy[ k ] = v
        end
    end
    return copy
end

local function Whole( n )
    if n < 0.0 then
        return math.floor( n )
    end
    return math.ceil( n )
end

--- @class Boost
--- @field Proficiency number
--- @field HP number
--- @field Initiative number
--- @field Physical number
--- @field Casting number
--- @field Strength number
--- @field Dexterity number
--- @field Constitution number
--- @field Intelligence number
--- @field Wisdom number
--- @field Charisma number

--- @class Entity
--- @field Level number
--- @field Constitution string
--- @field Physical string
--- @field Casting string
--- @field Boost Boost

--- @type table< string, Entity >
local Scalers = {}

local Scaling = {
    HP = 8.0,
    Initiative = 1.0,
    Physical = 1.5,
    Casting = 1.5,
    Strength = 0,
    Dexterity = 0,
    Constitution = 0,
    Intelligence = 0,
    Wisdom = 0,
    Charisma = 0
}

local function DefaultBoost()
    local ret = { Proficiency = 0.0 }
    for k,v in pairs( Scaling ) do
        ret[ k ] = 0.0
    end
    return ret
end

local function CheckMaxLevel( force )
    if not Started then return end

    local high = 0
    for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
        local level = Osi.GetLevel( p[ 1 ] )
        if level > high then
            high = level
        end
    end

    if force or high > PartyLevel then
        PartyLevel = high

        for _,ent in pairs( Ext.Entity.GetAllEntities() ) do
            local eoc = ent:GetComponent( "EocLevel" )
            local id = ent:GetComponent( "Uuid" )
            if not eoc or not id then goto continue end

            local sch = ent:GetComponent( "ServerCharacter" )
            if sch and sch.PlayerData then goto continue end

            local uuid = id.EntityUuid

            if not Scalers[ uuid ] then
                local stats = ent:GetComponent( "Stats" )
                if not stats then goto continue end

                Scalers[ uuid ] = {
                    Level = eoc.Level,
                    Boost = DefaultBoost(),
                    Constitution = stats.AbilityModifiers[ 4 ],
                    Physical = stats.Abilities[ 2 ] <= stats.Abilities[ 3 ] and "Dexterity" or "Strength",
                    Casting = tostring( stats.SpellCastingAbility )
                }
            end

            local scale = Scalers[ uuid ]

            local undown = not Downscaling and Scalers[ uuid ].Boost.HP ~= 0 and scale.Level > PartyLevel

            if scale.Level < PartyLevel or Downscaling and scale.Level > PartyLevel or undown then
                local change = PartyLevel - scale.Level

                local prev = DCCPY( scale.Boost )
                if undown then
                    scale.Boost = DefaultBoost()
                else
                    for k,v in pairs( Scaling ) do
                        if k == "HP" then
                            scale.Boost[ k ] = Whole( ( v + scale.Constitution ) * change )
                        else
                            scale.Boost[ k ] = Whole( v * change )
                        end
                    end
                    scale.Boost.Proficiency = Whole( PartyLevel / 4.0 + 1.0 )
                end

                local once = false

                local remove = ""
                local add = ""
                for k,v in pairs( scale.Boost ) do
                    if ( v ~= 0.0 or prev[ k ] ~= 0.0 ) and v ~= prev[ k ] then
                        local fun = ""
                        if k == "Proficiency" then
                            fun = "ProficiencyBonusOverride( "
                        elseif k == "HP" then
                            fun = "IncreaseMaxHP( "
                        elseif k == "Initiative" then
                            fun = "Initiative( "
                        elseif k == "Physical" then
                            fun = "Ability( " .. scale.Physical .. ", "
                        elseif k == "Casting" then
                            fun = "Ability( " .. scale.Casting .. ", "
                        else
                            fun = "Ability( " .. k .. ", "
                        end

                        if prev[ k ] then
                            remove = remove .. fun .. prev[ k ] .. " );"
                        end
                        add = add .. fun .. v .. " );"

                        once = true
                    end
                end

                if once then
                    Osi.RemoveBoosts( uuid, remove, 0, Key, "" )
                    Osi.AddBoosts( uuid, add, Key, "" )

                    if undown then
                        eoc.Level = scale.Level
                    else
                        eoc.Level = PartyLevel
                    end
                    ent:Replicate( "EocLevel" )
                end
            end

            :: continue ::
        end
    end
end

if MCM then
    local function SetValues()
        for k,v in pairs( Scaling ) do
            Scaling[ k ] = MCM.Get( k )
        end

        Downscaling = MCM.Get( "Downscaling" )
    end

    SetValues()

    Ext.ModEvents.BG3MCM[ "MCM_Setting_Saved" ]:Subscribe(
        function( payload )
            if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
                return
            end

            SetValues()
            CheckMaxLevel( true )
        end
    )
end

Ext.Osiris.RegisterListener(
    "LevelGameplayReady",
    2,
    "after",
    function ( ... )
        Ext.Osiris.RegisterListener( "LeveledUp", 1, "after", CheckMaxLevel )
        Started = true
        CheckMaxLevel()
    end
)