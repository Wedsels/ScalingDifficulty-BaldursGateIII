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

    _F.Delay = function( ms, func, ... )
        local args = { ... }
        local start = Ext.Utils.MonotonicTime()
        local handler
        handler = Ext.Events.Tick:Subscribe(
            function()
                if Ext.Utils.MonotonicTime() - start > ms then
                    Ext.Events.Tick:Unsubscribe( handler )
                    func( table.unpack( args ) )
                end
            end
        )
    end

    _F.AddNPC = function( ent )
        local origins = {}
        for _,p in pairs( Osi.DB_Origins:Get( nil ) ) do
            origins[ string.sub( p[ 1 ], -36 ) ] = true
        end
        for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
            origins[ string.sub( p[ 1 ], -36 ) ] = true
        end

        local eoc = ent.EocLevel
        local id = ent.Uuid
        if not eoc or not id or origins[ id.EntityUuid ] then return end

        local uuid = id.EntityUuid

        if not _V.Entities[ uuid ] then
            local stats = ent.Stats
            local health = ent.Health
            if not stats or not health then return end

            local type = "Enemy"
            if Osi.IsBoss( uuid ) == 1 then
                type = "Boss"
            elseif Osi.IsAlly( uuid, Osi.GetHostCharacter() ) == 1 then
                type = "Ally"
            end

            _V.Entities[ uuid ] = {
                Scaled = false,
                Hub = _V.Hub[ type ],
                LevelBase = eoc.Level,
                LevelChange = 0,
                Stats = _F.DefaultStat(),
                Constitution = stats.AbilityModifiers[ 4 ],
                Physical = stats.Abilities[ 2 ] <= stats.Abilities[ 3 ] and "Dexterity" or "Strength",
                Casting = tostring( stats.SpellCastingAbility ),
                OldStats = _F.DefaultStat(),
                Health = {
                    Hp = health.Hp,
                    MaxHp = health.MaxHp,
                    Percent = health.Hp / health.MaxHp
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
                    Current = _F.DefaultModifier()
                }
            }

            _F.UpdateNPC( uuid )
        end
    end

    _F.DefaultStat = function()
        local stat = {}
        for _,v in ipairs( _V.Stats ) do
            stat[ v ] = 0.0
        end
        return stat
    end

    _F.DefaultModifier = function()
        local ability = {}
        for k,_ in pairs( _V.Abilities ) do
            ability[ k ] = 0.0
        end
        return ability
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

        stats.ProficiencyBonus = 1 + math.floor( ( entity.LevelBase + entity.LevelChange ) / 2 )

        ent:Replicate( "Stats" )
    end

    _F.SetHealth = function( ent, index, clean )
        local health = ent.Health
        local uuid = ent.Uuid.EntityUuid
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        if index ~= 1 and entity.Health and health.MaxHp ~= entity.Health.MaxHp then
            health.Hp = entity.Health.Hp
        elseif index == 1 then
            entity.Health.Percent = health.Hp / health.MaxHp
            entity.Health.Hp = health.Hp

            return
        end

        if index == 3 or index == 2 then
            local hp = _F.Whole( entity.Stats.HP + entity.Modifiers.Current.Constitution * entity.LevelChange ) + ( entity.Modifiers.Current.Constitution - entity.Modifiers.Original.Constitution ) * entity.LevelBase

            health.MaxHp = health.MaxHp + hp
            if clean then health.MaxHp = health.MaxHp - entity.OldStats.HP end
            health.MaxHp = math.max( 1, health.MaxHp )

            entity.Health.MaxHp = health.MaxHp

            health.Hp = math.ceil( entity.Health.MaxHp * entity.Health.Percent )
            entity.Health.Hp = health.Hp

            entity.OldStats.HP = hp
            ent:Replicate( "Health" )
        end
    end

    _F.SetAC = function( ent, clean )
        local uuid = ent.Uuid.EntityUuid
        local res = ent.Resistances
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        local ac = _F.Whole( entity.Stats.AC + entity.Modifiers.Current.Dexterity - entity.Modifiers.Original.Dexterity )

        res.AC = res.AC + ac
        if clean then res.AC = res.AC - entity.OldStats.AC end

        entity.OldStats.AC = ac
        ent:Replicate( "Resistances" )
    end

    _F.SetLevel = function( ent )
        local eoc = ent.EocLevel
        local uuid = ent.Uuid.EntityUuid
        local entity = _V.Entities[ uuid ]
        if not entity then return end

        eoc.Level = entity.LevelBase + entity.LevelChange

        ent:Replicate( "EocLevel" )
    end

    _F.UpdateNPC = function( uuid )
        if not uuid then
            for id,_ in pairs( _V.Entities ) do
                _F.UpdateNPC( id )
            end
        else
            local party = 0
            for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
                local level = Osi.GetLevel( p[ 1 ] )
                if level > party then
                    party = level
                end
            end

            local entity = _V.Entities[ uuid ]

            local level = math.max( 0, party + entity.Hub.General.LevelBonus )
            if level < entity.LevelBase and not entity.Hub.General.Downscaling then
                level = entity.LevelBase
            end

            entity.LevelChange = level - entity.LevelBase

            for stat,_ in pairs( entity.Stats ) do
                entity.Stats[ stat ] = entity.Hub.Bonus[ stat ] + entity.Hub.Leveling[ stat ] * entity.LevelChange
            end

            local ent = Ext.Entity.Get( uuid )
            _F.SetAbilities( ent, true )
            _F.SetHealth( ent, 3, true )
            _F.SetAC( ent, true )
            _F.SetLevel( ent )
        end
    end

    return _F
end