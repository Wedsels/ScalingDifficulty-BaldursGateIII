local Key = "Scaling Difficulty"
local PartyLevel = 0

local function CheckMaxLevel()
    local high = 0
    for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
        local level = Osi.GetLevel( p[ 1 ] )
        if level > high then
            high = level
        end
    end

    if high > PartyLevel then
        PartyLevel = high

        for _,ent in pairs( Ext.Entity.GetAllEntities() ) do
            local eoc = ent:GetComponent( "EocLevel" )
            local id = ent:GetComponent( "Uuid" )
            if not eoc or not id then goto continue end

            local sch = ent:GetComponent( "ServerCharacter" )
            local player = sch and sch.PlayerData

            local uuid = id.EntityUuid
            if not player and eoc.Level < PartyLevel then
                local stats = ent:GetComponent( "Stats" )
                if not stats then goto continue end

                local change = PartyLevel - eoc.Level

                local phys = "Strength"
                if stats.Abilities[ 2 ] <= stats.Abilities[ 3 ] then
                    phys = "Dexterity"
                end

                local boost =
                    "ProficiencyBonusOverride( " .. math.ceil( eoc.Level / 4 ) + 1 .. " );" ..
                    "IncreaseMaxHP( " .. ( 8 + stats.AbilityModifiers[ 4 ] ) * change .. " );" ..
                    "Initiative( " .. change .. " );" ..
                    "Ability( " .. phys .. ", " .. change * 2 .. " );" ..
                    "Ability( " .. tostring( stats.SpellCastingAbility ) .. ", " .. change * 2 .. " )"

                Osi.AddBoosts( uuid, boost, Key, "" )

                eoc.Level = PartyLevel
                ent:Replicate( "EocLevel" )
            end

            :: continue ::
        end
    end
end

Ext.Osiris.RegisterListener( "LevelGameplayStarted", 2, "after", CheckMaxLevel )
Ext.Osiris.RegisterListener( "LeveledUp", 1, "after", CheckMaxLevel )