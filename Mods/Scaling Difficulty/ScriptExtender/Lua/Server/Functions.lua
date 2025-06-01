--- @param _V _V
return function( _V )
    --- @class _F
    local _F = {}

    _F.Whole = function( n )
        if n < 0.0 then
            return math.floor( n )
        end
        return math.ceil( n )
    end

    _F.Split = function( str, splt )
        local ret = {}
        if str == "" then
            return ret
        end
        for match in ( str .. splt ):gmatch( "(.-)" .. splt ) do
            table.insert( ret, match )
        end
        return ret
    end

    _F.IsBoss = function( ent )
        if not ent.Uuid then
            return false
        end

        if Osi.IsBoss( ent.Uuid.EntityUuid ) == 1 then
            return true
        end

        if ent.ServerCharacter and ent.ServerCharacter.Template and ent.ServerCharacter.Template.CombatComponent and ent.ServerCharacter.Template.CombatComponent.IsBoss then
            return true
        end

        if ent.ServerPassiveBase then
            for _,t in ipairs( ent.ServerPassiveBase.Passives ) do
                if t:find( "Legendary" ) then
                    return true
                end
            end
        end

        if ent.ActionResources and ent.ActionResources.Resources and
            (
                ent.ActionResources.Resources[ "732e23a8-bb1d-4bec-a4df-1dd0e03b56c4" ] or
                ent.ActionResources.Resources[ "4ebba3a3-f42e-42a6-87af-d36592ba8d49" ] or
                ent.ActionResources.Resources[ "67581067-020c-4e0d-814f-963714479f8a" ]
            )
        then return true end

        return false
    end

    _F.AddNPC = function( ent )
        local eoc = ent.EocLevel
        local id = ent.Uuid
        if not eoc or not id then return end

        local uuid = id.EntityUuid
        if Osi.DB_Players:Get( uuid )[ 1 ] or Osi.DB_Origins:Get( uuid )[ 1 ] then return end

        if not _V.Entities[ uuid ] then
            local stats = ent.Stats
            local health = ent.Health
            if not stats or not health then return end

            local type = "Enemy"
            if _F.IsBoss( uuid ) == 1 then
                type = "Boss"
            elseif Osi.IsSummon( uuid ) == 1 then
                type = "Summon"
            elseif Osi.IsEnemy( uuid, Osi.GetHostCharacter() ) == 0 then
                type = "Ally"
            end

            _V.Entities[ uuid ] = {
                Scaled = false,
                Type = type,
                Hub = _V.Hub[ type ],
                LevelBase = eoc.Level,
                LevelChange = 0,
                Stats = _F.Default( "Stats" ),
                Constitution = stats.AbilityModifiers[ 4 ],
                Physical = stats.Abilities[ 2 ] <= stats.Abilities[ 3 ] and "Dexterity" or "Strength",
                Casting = tostring( stats.SpellCastingAbility ),
                OldStats = _F.Default( "Stats" ),
                OldResource = _F.Default( "Resource" ),
                AC = {
                    Type = false,
                    ACBonus = 0,
                    ACModifier = 0
                },
                Health = {
                    Hp = health.Hp,
                    MaxHp = math.max( 1, health.MaxHp ),
                    Percent = health.Hp / math.max( 1, health.MaxHp )
                },
                Modifiers = {
                    Original = (
                        function()
                            local original = {}
                            for k,v in pairs( _V.Abilities ) do
                                original[ k ] = stats.AbilityModifiers[ v ]
                            end
                            return original
                        end
                    )(),
                    Current = _F.Default( "Abilities" )
                }
            }

            _F.UpdateNPC( uuid )
        end
    end

    _F.Default = function( type )
        local stat = {}
        for _,v in ipairs( _V[ type ] ) do
            stat[ v ] = 0.0
        end
        return stat
    end

    _F.SetAC = function( ent, clean, type )
        local uuid = ent.Uuid.EntityUuid
        local res = ent.Resistances
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        local mod = entity.Modifiers.Current.Dexterity - entity.Modifiers.Original.Dexterity

        local ac = 0
        if type then
            ac = clean and entity.Stats.AC + mod or mod
        else
            ac = entity.Stats.AC
        end
        ac = _F.Whole( ac )

        res.AC = res.AC + ac
        if clean then
            res.AC = res.AC - _F.Whole( type and entity.AC.ACBonus + entity.AC.ACModifier or entity.AC.ACBonus )
        end

        entity.AC.Type = type
        entity.AC.ACBonus = entity.Stats.AC
        entity.AC.ACModifier = entity.Modifiers.Current.Dexterity - entity.Modifiers.Original.Dexterity
        ent:Replicate( "Resistances" )
    end

    _F.SetAbilities = function( ent, clean )
        local uuid = ent.Uuid.EntityUuid
        local stats = ent.Stats
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        for k,v in pairs( _V.Abilities ) do
            local stat = entity.Stats[ k ]
            if k == entity.Physical then stat = stat + entity.Stats.Physical end
            if k == entity.Casting then stat = stat + entity.Stats.Casting end
            stat = _F.Whole( stat )

            stats.Abilities[ v ] = stats.Abilities[ v ] + stat
            if clean then stats.Abilities[ v ] = stats.Abilities[ v ] - entity.OldStats[ k ] end

            stats.AbilityModifiers[ v ] = math.floor( ( stats.Abilities[ v ] - 10.0 ) / 2.0 )
            entity.Modifiers.Current[ k ] = stats.AbilityModifiers[ v ]

            entity.OldStats[ k ] = stat
        end

        stats.InitiativeBonus = stats.InitiativeBonus + entity.Stats.Initiative
        if clean then stats.InitiativeBonus = stats.InitiativeBonus - entity.OldStats.Initiative end
        entity.OldStats.Initiative = entity.Stats.Initiative

        stats.ProficiencyBonus = 1 + math.floor( ( entity.LevelBase + entity.LevelChange ) / 2.0 )

        ent:Replicate( "Stats" )
        _F.SetAC( ent, clean, true )
    end

    _F.SetHealth = function( ent, index, clean )
        local health = ent.Health
        local uuid = ent.Uuid.EntityUuid
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        if index ~= 1 and entity.Health and health.MaxHp ~= entity.Health.MaxHp then
            health.Hp = entity.Health.Hp
        elseif index == 1 then
            entity.Health.Percent = health.Hp / math.max( 1, health.MaxHp )
            entity.Health.Hp = health.Hp

            return
        end

        if index == 59 or index == 3 or index == 2 then
            if index == 59 or not clean then
                entity.Health.MaxHp = health.MaxHp
            end

            health.MaxHp = math.max( 1, _F.Whole( ( entity.Health.MaxHp + entity.Stats.HP + entity.Modifiers.Current.Constitution * entity.LevelChange + ( entity.Modifiers.Current.Constitution - entity.Modifiers.Original.Constitution ) * entity.LevelBase ) * ( 1.0 + entity.Stats.PercentHP ) ) )

            health.Hp = math.min( health.MaxHp, math.ceil( health.MaxHp * entity.Health.Percent ) )
            entity.Health.Hp = health.Hp

            ent:Replicate( "Health" )
        end
    end

    _F.SetLevel = function( ent )
        local eoc = ent.EocLevel
        local uuid = ent.Uuid.EntityUuid
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        eoc.Level = entity.LevelBase + entity.LevelChange

        ent:Replicate( "EocLevel" )
    end

    _F.SetBoosts = function( uuid )
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        if entity.OldStats.DamageBonus ~= entity.Stats.DamageBonus then
            if entity.OldStats.DamageBonus ~= 0 then
                Osi.RemoveBoosts( uuid, string.format( _V.Boosts.DamageBonus, entity.OldStats.DamageBonus ), 0, _V.Key, "" )
            end

            if entity.Stats.DamageBonus ~= 0 then
                Osi.AddBoosts( uuid, string.format( _V.Boosts.DamageBonus, entity.Stats.DamageBonus ), _V.Key, "" )
            end

            entity.OldStats.DamageBonus = entity.Stats.DamageBonus
        end

        if entity.OldStats.Attack ~= entity.Stats.Attack then
            if entity.OldStats.Attack ~= 0 then
                Osi.RemoveBoosts( uuid, string.format( _V.Boosts.RollBonus, "Attack", entity.OldStats.Attack ), 0, _V.Key, "" )
            end

            if entity.Stats.Attack ~= 0 then
                Osi.AddBoosts( uuid, string.format( _V.Boosts.RollBonus, "Attack", entity.Stats.Attack ), _V.Key, "" )
            end

            entity.OldStats.Attack = entity.Stats.Attack
        end

        for _,resource in ipairs( _V.Resource ) do
            local amount = 0
            if resource:find( "SpellSlot" ) then
                local elvl = entity.LevelBase + entity.LevelChange
                for _,v in ipairs( _F.Split( entity.Hub.Resource[ resource ], ',' ) ) do
                    if tonumber( v ) and elvl >= tonumber( v ) then
                        amount = amount + 1
                    end
                end
            else
                amount = entity.Hub.Resource[ resource ]
            end

            if entity.OldResource[ resource ] ~= amount then
                local level = resource:match( "Level([%d])" ) or 0
                local boost = resource:gsub( "Level[%d]", "" )

                if entity.OldResource[ resource ] ~= 0 then
                    Osi.RemoveBoosts( uuid, string.format( _V.Boosts.Resource, boost, entity.OldResource[ resource ], level ), 0, _V.Key, "" )
                end

                if amount ~= 0 then
                    Osi.AddBoosts( uuid, string.format( _V.Boosts.Resource, boost, amount, level ), _V.Key, "" )
                end

                entity.OldResource[ resource ] = amount
            end
        end
    end

    _F.UpdateNPC = function( uuid )
        if not uuid then
            for id,_ in pairs( _V.Entities ) do
                _F.UpdateNPC( id )
            end
        else
            local entity = _V.Entities[ uuid ]
            if not entity then _F.AddNPC( uuid ) return end

            local ent = Ext.Entity.Get( uuid )
            if not ent or not entity.Hub then _V.Entities[ uuid ] = nil return end

            local undo = Osi.DB_Players:Get( uuid )[ 1 ] or Osi.DB_Origins:Get( uuid )[ 1 ]

            if entity.Type ~= "Summon" then
                local enemy = Osi.IsEnemy( uuid, Osi.GetHostCharacter() )
                if entity.Type ~= "Ally" and enemy == 0 then
                    entity.Type = "Ally"
                    entity.Hub = _V.Hub[ entity.Type ]
                elseif entity.Type == "Ally" and enemy == 1 then
                    entity.Type = _F.IsBoss( uuid ) == 1 and "Boss" or "Enemy"
                    entity.Hub = _V.Hub[ entity.Type ]
                end
            end

            local party = 0
            for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
                local level = Osi.GetLevel( p[ 1 ] )
                if level > party then
                    party = level
                end
            end

            local level = math.max( 0, party + entity.Hub.General.LevelBonus )
            if level < entity.LevelBase and not entity.Hub.General.Downscaling then
                level = entity.LevelBase
            end

            entity.LevelChange = undo and 0 or level - entity.LevelBase

            for stat,_ in pairs( entity.Stats ) do
                entity.Stats[ stat ] = undo and 0 or entity.Hub.Bonus[ stat ] + entity.Hub.Leveling[ stat ] * entity.LevelChange
            end

            _F.SetAbilities( ent, true )
            _F.SetHealth( ent, 3, true )
            _F.SetLevel( ent )
            _F.SetBoosts( uuid )

            if undo then _V.Entities[ uuid ] = nil end
        end
    end

    return _F
end