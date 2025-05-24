local Key = "Scaling Difficulty"

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
--- @field Scaled boolean
--- @field Level number
--- @field Constitution string
--- @field Physical string
--- @field Casting string
--- @field Boost Boost

--- @type table< string, table< string, Entity > >
local Scalers = {}

local Scaling = {}

local function DefaultBoost()
    local ret = {}
    for k,v in pairs( Scaling.Enemy ) do
        if k ~= "Level" and k ~= "Downscaling" then
            ret[ k ] = 0.0
        end
    end
    return ret
end

local function Scale( uuid, scale, default, level, undo )
    local change = level - scale.Level

    local prev = DCCPY( scale.Boost )
    if undo then
        scale.Boost = DefaultBoost()
    else
        for k,_ in pairs( scale.Boost ) do
            if k == "Proficiency" then
                scale.Boost[ k ] = Whole( level / 4.0 + 1.0 )
            elseif k == "HP" then
                scale.Boost[ k ] = Whole( ( default[ k ] + scale.Constitution ) * change )
            else
                scale.Boost[ k ] = Whole( default[ k ] * change )
            end
        end
    end

    local once = false

    local remove = ""
    local add = ""
    for k,v in pairs( scale.Boost ) do
        if ( v ~= 0.0 or prev[ k ] ~= 0.0 ) and v ~= prev[ k ] then
            local fun = ""
            once = true

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
        end
    end

    if once then
        Osi.RemoveBoosts( uuid, remove, 0, Key, "" )
        Osi.AddBoosts( uuid, add, Key, "" )

        local ent = Ext.Entity.Get( uuid )
        if not ent then return end
        local eoc = ent:GetComponent( "EocLevel" )
        if not eoc then return end

        if undo then
            scale.Scaled = false
            eoc.Level = scale.Level
        else
            scale.Scaled = true
            eoc.Level = level
        end
        ent:Replicate( "EocLevel" )
    end
end

local function CheckMaxLevel()
    local PartyLevel = 0
    for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
        local level = Osi.GetLevel( p[ 1 ] )
        if level > PartyLevel then
            PartyLevel = level
        end
    end

    for k,v in pairs( Scaling ) do
        for e,d in pairs( Scalers[ k ] ) do
            local level = math.max( 0, PartyLevel + v.Level )
            if level < PartyLevel and not v.Downscaling then
                level = PartyLevel
            end

            local undo = not v.Downscaling and d.Scaled and d.Level > level

            if d.Level < level or v.Downscaling and d.Level > level or undo then
                Scale( e, d, v, level, undo )
            end
        end
    end
end

Ext.Osiris.RegisterListener(
    "LevelGameplayReady",
    2,
    "after",
    function ( ... )
        local default = Ext.Json.Parse( Ext.IO.LoadFile( "Mods/Scaling Difficulty/MCM_blueprint.json", "data" ) )
        for _,v in pairs( default.Tabs ) do
            Scaling[ v.TabId ] = {}
            for _,s in pairs( v.Settings ) do
                Scaling[ v.TabId ][ string.gsub( s.Id, v.TabId, "" ) ] = s.Default
            end
        end

        local host = Osi.GetHostCharacter()

        for _,ent in pairs( Ext.Entity.GetAllEntities() ) do
            local eoc = ent:GetComponent( "EocLevel" )
            local id = ent:GetComponent( "Uuid" )
            local sch = ent:GetComponent( "ServerCharacter" )
            if not eoc or not id or sch and sch.PlayerData then goto continue end

            local uuid = id.EntityUuid

            local type = "Enemy"
            if Osi.IsBoss( uuid ) == 1 then
                type = "Boss"
            elseif Osi.IsAlly( uuid, host ) == 1 then
                type = "Ally"
            end

            if not Scalers[ type ] then
                Scalers[ type ] = {}
            end

            if not Scalers[ type ][ uuid ] then
                local stats = ent:GetComponent( "Stats" )
                if not stats then goto continue end

                Scalers[ type ][ uuid ] = {
                    Scaled = false,
                    Level = eoc.Level,
                    Boost = DefaultBoost(),
                    Constitution = stats.AbilityModifiers[ 4 ],
                    Physical = stats.Abilities[ 2 ] <= stats.Abilities[ 3 ] and "Dexterity" or "Strength",
                    Casting = tostring( stats.SpellCastingAbility )
                }
            end

            :: continue ::
        end

        if MCM then
            local function SetValues()
                for t,v in pairs( Scaling ) do
                    for k,_ in pairs( v ) do
                        v[ k ] = MCM.Get( t .. k )
                    end
                end
            end

            SetValues()

            Ext.ModEvents.BG3MCM[ "MCM_Setting_Saved" ]:Subscribe(
                function( payload )
                    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
                        return
                    end

                    SetValues()
                    CheckMaxLevel()
                end
            )
        end

        Ext.Osiris.RegisterListener( "LeveledUp", 1, "after", CheckMaxLevel )

        CheckMaxLevel()
    end
)