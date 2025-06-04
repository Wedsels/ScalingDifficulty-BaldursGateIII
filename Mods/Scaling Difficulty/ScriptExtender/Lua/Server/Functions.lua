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

    _F.UUID = function( target )
        if type( target ) == "userdata" and target.Uuid then
            return string.sub( target.Uuid.EntityUuid, -36 )
        elseif type( target ) == "string" then
            return string.sub( target, -36 )
        end
    end

    _F.IsBoss = function( ent )
        local uuid = _F.UUID( ent )

        if not uuid then
            return false
        end

        if Osi.IsBoss( uuid ) == 1 then
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

    _F.IsPlayer = function( ent, uuid )
        return Osi.DB_Players:Get( uuid )[ 1 ] or Osi.DB_Origins:Get( uuid )[ 1 ] or ent and ent.Classes and ent.Classes.Classes[ 1 ] and ent.Classes.Classes[ 1 ].ClassUUID ~= "00000000-0000-0000-0000-000000000000"
    end

    _F.IsEnemy = function( uuid )
        for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
            if Osi.IsEnemy( uuid, p[ 1 ] ) == 1 then
                return true
            end
        end
        return false
    end

    _F.AddNPC = function( ent )
        local eoc = ent.EocLevel
        local uuid = _F.UUID( ent )
        if not eoc or not uuid then return end

        if not _V.Entities[ uuid ] then
            local stats = ent.Stats
            local health = ent.Health
            if not stats or not health then return end

            local type = "Enemy"
            if _F.IsBoss( uuid ) == 1 then
                type = "Boss"
            elseif Osi.IsSummon( uuid ) == 1 then
                type = "Summon"
            elseif _F.IsEnemy( uuid ) then
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
                Resource = _F.Default( "Resource" ),
                OldResource = _F.Default( "Resource" ),
                Spell = _F.Default( "Spell", true ),
                OldSpell = _F.Default( "Spell" ),
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
                },
                CleanBoosts = true
            }

            _F.UpdateNPC( uuid )
        end
    end

    _F.Default = function( type, string )
        local stat = {}
        for _,v in ipairs( _V[ type ] ) do
            stat[ v ] = string and "" or 0.0
        end
        return stat
    end

    _F.SetAC = function( ent, clean, type )
        local uuid = _F.UUID( ent )
        if not uuid then return end

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
        local uuid = _F.UUID( ent )
        if not uuid then return end

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

        stats.InitiativeBonus = _F.Whole( stats.InitiativeBonus + entity.Stats.Initiative - ( clean and entity.OldStats.Initiative or 0 ) )
        entity.OldStats.Initiative = entity.Stats.Initiative

        stats.ProficiencyBonus = 1 + math.floor( ( entity.LevelBase + entity.LevelChange ) / 2.0 )

        ent:Replicate( "Stats" )
        _F.SetAC( ent, clean, true )
    end

    _F.SetHealth = function( ent, index, clean )
        local uuid = _F.UUID( ent )
        if not uuid then return end

        local health = ent.Health
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
        local uuid = _F.UUID( ent )
        if not uuid then return end

        local eoc = ent.EocLevel
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        eoc.Level = entity.LevelBase + entity.LevelChange

        ent:Replicate( "EocLevel" )
    end

    _F.SetBoosts = function( uuid )
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        if entity.CleanBoosts or entity.OldStats.DamageBonus ~= entity.Stats.DamageBonus then
            if entity.OldStats.DamageBonus ~= 0 then
                Osi.RemoveBoosts( uuid, string.format( _V.Boosts.DamageBonus, entity.OldStats.DamageBonus ), 0, _V.Key, "" )
            end

            if entity.CleanBoosts or entity.Stats.DamageBonus ~= 0 then
                Osi.AddBoosts( uuid, string.format( _V.Boosts.DamageBonus, entity.Stats.DamageBonus ), _V.Key, "" )
            end

            entity.OldStats.DamageBonus = entity.Stats.DamageBonus
        end

        if entity.CleanBoosts or entity.OldStats.Attack ~= entity.Stats.Attack then
            if entity.OldStats.Attack ~= 0 then
                Osi.RemoveBoosts( uuid, string.format( _V.Boosts.RollBonus, "Attack", entity.OldStats.Attack ), 0, _V.Key, "" )
            end

            if entity.CleanBoosts or entity.Stats.Attack ~= 0 then
                Osi.AddBoosts( uuid, string.format( _V.Boosts.RollBonus, "Attack", entity.Stats.Attack ), _V.Key, "" )
            end

            entity.OldStats.Attack = entity.Stats.Attack
        end

        for _,resource in ipairs( _V.Resource ) do
            local amount = entity.Resource[ resource ]

            if entity.CleanBoosts or entity.OldResource[ resource ] ~= amount then
                if entity.OldResource[ resource ] ~= 0 then
                    Osi.RemoveBoosts( uuid, string.format( _V.Boosts.Resource, resource, entity.OldResource[ resource ], 0 ), 0, _V.Key, "" )
                end

                if entity.CleanBoosts or amount ~= 0 then
                    Osi.AddBoosts( uuid, string.format( _V.Boosts.Resource, resource, amount, 0 ), _V.Key, "" )
                end

                entity.OldResource[ resource ] = amount
            end
        end

        for _,spell in ipairs( _V.Spell ) do
            local amount = 0
            local elvl = entity.LevelBase + entity.LevelChange
            for _,v in ipairs( _F.Split( entity.Spell[ spell ], ',' ) ) do
                if tonumber( v ) and elvl >= tonumber( v ) then
                    amount = amount + 1
                end
            end

            if entity.CleanBoosts or entity.OldSpell[ spell ] ~= amount then
                local level = spell:match( "Level([%d])" ) or 0
                local boost = spell:gsub( "Level[%d]", "" )

                if entity.OldSpell[ spell ] ~= 0 then
                    Osi.RemoveBoosts( uuid, string.format( _V.Boosts.Resource, boost, entity.OldSpell[ spell ], level ), 0, _V.Key, "" )
                end

                if entity.CleanBoosts or amount ~= 0 then
                    Osi.AddBoosts( uuid, string.format( _V.Boosts.Resource, boost, amount, level ), _V.Key, "" )
                end

                entity.OldSpell[ spell ] = amount
            end
        end

        entity.CleanBoosts = false
    end

    _F.UpdateNPC = function( uuid )
        uuid = _F.UUID( uuid )

        if not uuid then
            for id,_ in pairs( _V.Entities ) do
                _F.UpdateNPC( id )
            end
        else
            local ent = Ext.Entity.Get( uuid )
            if not ent then _V.Entities[ uuid ] = nil return end

            local entity = _V.Entities[ uuid ]
            if not entity or not entity.Hub then _F.AddNPC( ent ) return end

            local undo = _F.IsPlayer( ent, uuid )

            if entity.Type ~= "Summon" then
                local enemy = _F.IsEnemy( uuid )
                if entity.Type ~= "Ally" and not enemy then
                    entity.Type = "Ally"
                    entity.Hub = _V.Hub[ entity.Type ]
                elseif entity.Type == "Ally" and enemy then
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

            for _,stat in ipairs( _V.Stats ) do
                entity.Stats[ stat ] = undo and 0 or entity.Hub.Bonus[ stat ] + entity.Hub.Leveling[ stat ] * entity.LevelChange
            end

            for _,resource in ipairs( _V.Resource ) do
                entity.Resource[ resource ] = undo and 0 or entity.Hub.Resource[ resource ]
            end

            for _,spell in ipairs( _V.Spell ) do
                entity.Spell[ spell ] = undo and "" or entity.Hub.Spell[ spell ]
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