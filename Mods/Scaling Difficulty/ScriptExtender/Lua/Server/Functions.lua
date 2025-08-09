--- @param _V _V
return function( _V )
    --- @class _F
    local _F = {}

    _F.Whole = function( n )
        if n < 0.0 then
            return math.ceil( n - 0.5 )
        end
        return math.floor( n + 0.5 )
    end

    _F.Split = function( str, splt )
        if type( str ) ~= "string" then return {} end

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

    _F.RNG = function( seed )
        local self = { seed = seed + _V.Seed }

        setmetatable(
            self,
            {
                __call = function( _, range, reroll )
                    local roll = 0
                    range = range or 1
                    reroll = reroll or 1

                    for _ = 1, reroll do
                        self.seed = ( 1103515245 * self.seed + 12345 ) % 0x80000000
                        local r = self.seed / 0x80000000
                        if r > roll then
                            roll = r
                        end
                    end
                    local t = type( range )

                    if t == "number" then
                        return roll * range
                    elseif t == "table" then
                        return range[ math.floor( roll * #range + 1 ) ]
                    end
                end
            }
        )

        return self
    end

    _F.Hash = function( str )
        local h = 5381

        for i = 1, #str do
            h = h * 32 + h + str:byte( i )
        end

        return h
    end

    _F.DefaultBlueprint = function()
        local ret = {}

        for _,setting in pairs( _V.JsonBlueprint.Tabs[ 1 ].Settings ) do
            ret[ setting.Id ] = setting.Default
        end

        return ret
    end

    _F.GetClass = function( ent )
        local class = {}
        local uuid = _F.UUID( ent )
        local book = ent.SpellBook and ent.SpellBook.Spells

        if uuid and book then
            for _,data in ipairs( book ) do
                local spell = data.Id.Prototype
                if _V.SpellLists[ spell ] then
                    table.insert( class, _V.SpellLists[ spell ] )
                end
            end
        end

        return class
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

        if ent.DisplayName and ent.DisplayName.Title.Handle.Handle ~= "ls::TranslatedStringRepository::s_HandleUnknown" then
            return true
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

    _F.IsPlayer = function( ent )
        local uuid = _F.UUID( ent )
        return not ent.Bound and ent.Stats or Osi.DB_Players:Get( uuid )[ 1 ]
    end

    _F.IsEnemy = function( uuid )
        for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
            if Osi.IsEnemy( uuid, p[ 1 ] ) == 1 then
                return true
            end
        end
    end

    _F.Archetype = function( ent, uuid )
        if _F.IsPlayer( ent ) then return "Player" end
        if _F.IsBoss( ent ) then return "Boss" end
        if Osi.IsSummon( uuid ) == 1 then return "Summon" end
        if _F.IsEnemy( uuid ) then return "Enemy" end
        return "Ally"
    end

    _F.GetEntity = function( ent )
        local uuid = _F.UUID( ent )
        if not uuid then return end

        local entity = _V.Entities[ uuid ]
        if not entity then return end

        return uuid, entity
    end

    _F.AddNPC = function( ent )
        local eoc = ent.EocLevel
        local uuid = _F.UUID( ent )
        if not eoc or not uuid then return end

        if not _V.Entities[ uuid ] then
            local stats = ent.Stats
            local health = ent.Health
            local visual = ent.GameObjectVisual
            local data = ent.Data
            if not stats or not health or not visual or not data then return end

            local type = _F.Archetype( ent, uuid )

            _V.Entities[ uuid ] = {
                Name = ent.ServerCharacter and ent.ServerCharacter.Template.Name or uuid,
                Scaled = false,
                Type = type,
                Hub = _V.Hub[ type ],
                LevelBase = eoc.Level,
                LevelChange = 0,
                Stats = _F.Default( "Stats" ),
                Skills = {},
                Constitution = stats.AbilityModifiers[ 4 ],
                Physical = stats.Abilities[ 2 ] <= stats.Abilities[ 3 ] and "Dexterity" or "Strength",
                Casting = tostring( stats.SpellCastingAbility ),
                Resource = _F.Default( "Resource", true ),
                OldStats = _F.Default( "Stats" ),
                OldResource = _F.Default( "Resource" ),
                OldSpells = 0,
                OldBlacklist = "",
                OldSize = visual.Scale,
                OldSkills = {},
                OldWeight = data.Weight,
                AC = {
                    Type = false,
                    ACBonus = 0,
                    ACModifier = 0
                },
                Health = {
                    Hp = health.Hp,
                    MaxHp = math.max( 1, health.MaxHp ),
                    Percent = health.Hp / math.max( 1, health.MaxHp ),
                    Transformed = false,
                    TransformedHp = 0,
                    TransformedMaxHp = 0,
                    TransformedPercent = 0
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
                CleanBoosts = true,
                Class = _F.GetClass( ent )
            }
        end

        _F.UpdateNPC( uuid )
    end

    _F.Default = function( type, string )
        local stat = {}
        for _,v in ipairs( _V[ type ] ) do
            stat[ v ] = string and "" or 0.0
        end
        return stat
    end

    _F.SetSpells = function( ent )
        local uuid, entity = _F.GetEntity( ent )
        if not entity or entity.Type == "Player" or not next( entity.Class ) then return end

        local num = entity.Hub.General.Enabled and _F.Whole( entity.Hub.General.Spells * ( entity.LevelBase + entity.LevelChange ) ) or 0
        num = math.min( num, 18 )
        if num == entity.OldSpells and entity.Hub.General.SpellBlacklist == entity.OldBlacklist then return end

        local seed = _F.Hash( uuid )
        local ran = _F.RNG( seed )

        local blacklist = {}
        for _,spell in ipairs( _F.Split( entity.Hub.General.SpellBlacklist, ';' ) ) do
            local tbl = _V.SpellNames[ spell:gsub( "[%s%p]", "" ):lower() ]
            if tbl then
                for _,name in ipairs( tbl ) do
                    blacklist[ name ] = true
                end
            end
        end

        local spells = {}
        local roll = ran( num, 2 )
        for _ = 1, roll do
            local spell = ran( ran( ran( entity.Class ) ) )
            if not blacklist[ spell ] then
                spells[ #spells + 1 ] = spell
            end
        end

        local oldspells = ent.Vars.ScalingDifficultySpellCache or {}

        for _,spell in ipairs( spells ) do
            local match = false
            for _,old in ipairs( oldspells ) do
                match = old == spell
                if match then break end
            end
            if not match then Osi.AddSpell( uuid, spell ) end
        end

        for _,old in ipairs( oldspells ) do
            local match = false
            for _,spell in ipairs( spells ) do
                match = spell == old
                if match then break end
            end
            if not match then Osi.RemoveSpell( uuid, old ) end
        end

        entity.OldSpells = num
        entity.OldBlacklist = entity.Hub.General.SpellBlacklist
        ent.Vars.ScalingDifficultySpellCache = spells
    end

    _F.SetAC = function( ent, index, type )
        local uuid, entity = _F.GetEntity( ent )
        if not entity or index == -1 then return end

        local clean = index ~= 4
        local res = ent.Resistances
        local ac = _F.Whole( entity.Stats.AC + ( clean and entity.Modifiers.Current.Dexterity - entity.Modifiers.Original.Dexterity or 0 ) )

        res.AC = res.AC + ac
        if clean then
            res.AC = res.AC - entity.OldStats.AC
        end

        entity.OldStats.AC = _F.Whole( entity.Stats.AC + entity.Modifiers.Current.Dexterity - entity.Modifiers.Original.Dexterity )

        ent:Replicate( "Resistances" )
    end

    _F.SetAbilities = function( ent, index )
        local uuid, entity = _F.GetEntity( ent )
        if not entity then return end

        local clean = index ~= 79
        local stats = ent.Stats

        for k,v in pairs( _V.Abilities ) do
            local stat = entity.Stats[ k ]
            if k == entity.Physical then stat = stat + entity.Stats.Physical end
            if k == entity.Casting then stat = stat + entity.Stats.Casting end
            stat = _F.Whole( stat )

            stats.Abilities[ v ] = stats.Abilities[ v ] + stat
            if clean then
                stats.Abilities[ v ] = stats.Abilities[ v ] - entity.OldStats[ k ]
            else
                entity.Modifiers.Original[ k ] = stats.AbilityModifiers[ v ]
            end

            stats.AbilityModifiers[ v ] = math.floor( ( stats.Abilities[ v ] - 10.0 ) / 2.0 )
            entity.Modifiers.Current[ k ] = stats.AbilityModifiers[ v ]

            entity.OldStats[ k ] = stat
        end

        for i,k in ipairs( {
            _V.Abilities.Charisma,
            _V.Abilities.Charisma,
            _V.Abilities.Charisma,
            _V.Abilities.Charisma,
            _V.Abilities.Dexterity,
            _V.Abilities.Dexterity,
            _V.Abilities.Dexterity,
            _V.Abilities.Intelligence,
            _V.Abilities.Intelligence,
            _V.Abilities.Intelligence,
            _V.Abilities.Intelligence,
            _V.Abilities.Intelligence,
            _V.Abilities.Strength,
            _V.Abilities.Wisdom,
            _V.Abilities.Wisdom,
            _V.Abilities.Wisdom,
            _V.Abilities.Wisdom,
            _V.Abilities.Wisdom
        } ) do
            if clean then
                entity.Skills[ i ] = entity.Skills[ i ] or stats.Skills[ i ]
            else
                entity.Skills[ i ] = stats.Skills[ i ];
            end

            if index == -1 then
                entity.Skills[ i ] = entity.Skills[ i ] + ( stats.Skills[ i ] - entity.OldSkills[ i ] )
            end

            stats.Skills[ i ] = entity.Skills[ i ] + stats.AbilityModifiers[ k ]
            entity.OldSkills[ i ] = stats.Skills[ i ]
        end

        stats.InitiativeBonus = _F.Whole( stats.InitiativeBonus + entity.Stats.Initiative - ( clean and entity.OldStats.Initiative or 0 ) )
        entity.OldStats.Initiative = entity.Stats.Initiative

        if entity.Type ~= "Player" then
            stats.ProficiencyBonus = 2 + math.floor( ( entity.LevelBase + entity.LevelChange - 1 ) / 4.0 )
        end

        if not clean then
            ent.Resistances.AC = ent.Resistances.AC + entity.Modifiers.Current.Dexterity - entity.Modifiers.Original.Dexterity
        end

        ent:Replicate( "Stats" )
    end

    _F.SetHealth = function( ent, index )
        local uuid, entity = _F.GetEntity( ent )
        if not entity then return end

        local health = ent.Health

        if index == 59 then
            _F.SetAbilities( ent, 79 )
            _F.SetAC( ent, 4 )

            if entity.Health.Transformed then
                entity.Health.Hp = entity.Health.TransformedHp
                entity.Health.MaxHp = entity.Health.TransformedMaxHp
                entity.Health.Percent = entity.Health.TransformedPercent
            else
                entity.Health.TransformedHp = entity.Health.Hp
                entity.Health.TransformedMaxHp = entity.Health.MaxHp
                entity.Health.TransformedPercent = entity.Health.Percent

                entity.Health.Hp = health.Hp
                entity.Health.Percent = health.Hp / math.max( 1, health.MaxHp )
            end

            entity.Health.Transformed = not entity.Health.Transformed
        elseif index == -1 or index == 1 or index == 5 or Osi.IsActive( uuid ) ~= 1 then
            if health.Hp ~= entity.Health.Hp then
                entity.Health.Percent = health.Hp / math.max( 1, health.MaxHp )
                entity.Health.Hp = health.Hp
            end
        elseif index ~= 1 and health.MaxHp ~= entity.Health.MaxHp then
            health.Hp = entity.Health.Hp
        end

        if index == 59 or index == 3 or index == 2 or not index then
            if index then
                entity.Health.MaxHp = health.MaxHp
            end

            local hp = entity.Health.MaxHp + entity.Stats.HP
            hp = hp + entity.Modifiers.Current.Constitution * entity.LevelChange
            hp = hp + ( entity.Modifiers.Current.Constitution - entity.Modifiers.Original.Constitution ) * entity.LevelBase
            hp = hp * ( 1.0 + entity.Stats.PercentHP + entity.Stats.Size )

            health.MaxHp = math.max( 1, _F.Whole( hp ) )

            health.Hp = math.min( health.MaxHp, math.ceil( health.MaxHp * entity.Health.Percent ) )
            entity.Health.Hp = health.Hp

            ent:Replicate( "Health" )
        end
    end

    _F.SetLevel = function( ent )
        local uuid, entity = _F.GetEntity( ent )
        if not entity or entity.Type == "Player" then return end

        ent.EocLevel.Level = entity.LevelBase + entity.LevelChange

        ent:Replicate( "EocLevel" )
    end

    _F.SetBoosts = function( ent, remove )
        local uuid, entity = _F.GetEntity( ent )
        if not entity then return end

        if remove or entity.CleanBoosts or entity.OldStats.DamageBonus ~= entity.Stats.DamageBonus then
            if remove or entity.OldStats.DamageBonus ~= 0 then
                Osi.RemoveBoosts( uuid, string.format( _V.Boosts.DamageBonus, entity.OldStats.DamageBonus ), 0, _V.Key, "" )
            end

            local stat = entity.CleanBoosts and 0 or _F.Whole( entity.Stats.DamageBonus )

            if entity.CleanBoosts or stat ~= 0 then
                Osi.AddBoosts( uuid, string.format( _V.Boosts.DamageBonus, stat ), _V.Key, "" )
            end

            entity.OldStats.DamageBonus = stat
        end

        if remove or entity.CleanBoosts or entity.OldStats.Attack ~= entity.Stats.Attack then
            if remove or entity.OldStats.Attack ~= 0 then
                Osi.RemoveBoosts( uuid, string.format( _V.Boosts.RollBonus, "Attack", entity.OldStats.Attack ), 0, _V.Key, "" )
            end

            local stat = entity.CleanBoosts and 0 or _F.Whole( entity.Stats.Attack )

            if entity.CleanBoosts or stat ~= 0 then
                Osi.AddBoosts( uuid, string.format( _V.Boosts.RollBonus, "Attack", stat ), _V.Key, "" )
            end

            entity.OldStats.Attack = stat
        end

        for _,resource in ipairs( _V.Resource ) do
            if type( entity.Resource[ resource ] ) == "string" then
                local amount = 0
                local elvl = entity.LevelBase + entity.LevelChange
                if not entity.CleanBoosts then
                    for _,v in ipairs( _F.Split( entity.Resource[ resource ], ',' ) ) do
                        if tonumber( v ) and elvl >= tonumber( v ) then
                            amount = amount + 1
                        end
                    end
                end

                if remove or entity.CleanBoosts or entity.OldResource[ resource ] ~= amount then
                    local level = resource:match( "Level([%d])" ) or 0
                    local boost = resource:gsub( "Level[%d]", "" )

                    if remove or entity.OldResource[ resource ] ~= 0 then
                        Osi.RemoveBoosts( uuid, string.format( _V.Boosts.Resource, boost, entity.OldResource[ resource ], level ), 0, _V.Key, "" )
                    end

                    if entity.CleanBoosts or amount ~= 0 then
                        Osi.AddBoosts( uuid, string.format( _V.Boosts.Resource, boost, amount, level ), _V.Key, "" )
                    end

                    entity.OldResource[ resource ] = amount
                end
            end
        end

        if entity.CleanBoosts then
            entity.CleanBoosts = false
            Ext.Timer.WaitFor( 500, function() _F.SetBoosts( ent, true ) end )
        end
    end

    _F.SetSize = function( ent, index )
        local uuid, entity = _F.GetEntity( ent )
        local visual = ent.GameObjectVisual
        if not entity or not visual or index == -1 then return end

        local size = entity.Stats.Size
        if index == 1 or index == 4 or index == 9 then
            entity.OldSize = visual.Scale
        end

        visual.Scale = math.max( 0.1, entity.OldSize * ( 1.0 + size ) )

        ent:Replicate( "GameObjectVisual" )
    end

    _F.SetWeight = function( ent, index )
        local uuid, entity = _F.GetEntity( ent )
        local data = ent.Data
        if not entity or not data or index == -1 then return end

        local weight = entity.Stats.Size
        if index == 1 or index == 5 then
            entity.OldWeight = data.Weight
        end

        data.Weight = math.max( 1, math.ceil( entity.OldWeight * ( 1.0 + weight ) ) )

        ent:Replicate( "Data" )
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

            local arch = _F.Archetype( ent, uuid )
            if Osi.HasActiveStatusWithGroup( uuid, "SG_Dominated" ) == 1 then
                if arch == "Enemy" then arch = "Ally"
                elseif arch == "Ally" then arch = "Enemy" end
            end
            entity.Type = arch
            entity.Hub = _V.Hub[ arch ]

            local party = 0
            for _,p in pairs( Osi.DB_Players:Get( nil ) ) do
                local level = Osi.GetLevel( p[ 1 ] )
                if level > party then
                    party = level
                end
            end

            local level = math.max( 0, party + ( entity.Hub.General.Enabled and entity.Hub.General.LevelBonus or 0 ) )
            if level < entity.LevelBase and ( not entity.Hub.General.Enabled or not entity.Hub.General.Downscaling ) then
                level = entity.LevelBase
            elseif arch == "Player" then
                entity.LevelBase = 1
                level = ent.EocLevel.Level
            end

            entity.LevelChange = not entity.Hub.Leveling.Enabled and 0 or level - entity.LevelBase

            local ran = _F.RNG( _F.Hash( uuid ) )

            for _,stat in ipairs( _V.Stats ) do
                if type( entity.Hub.Bonus[ stat ] ) == "number" then
                    local vari = ran( entity.Hub.Variation[ stat ] )
                    if ran() < 0.5 then
                        vari = vari * -1.0
                    end

                    entity.Stats[ stat ]
                        = ( not entity.Hub.Bonus.Enabled and 0 or entity.Hub.Bonus[ stat ] )
                        + entity.Hub.Leveling[ stat ] * entity.LevelChange
                        + ( not entity.Hub.Variation.Enabled and 0 or vari )
                end
            end

            for _,resource in ipairs( _V.Resource ) do
                if type( entity.Resource[ resource ] ) == "string" then
                    entity.Resource[ resource ] = not entity.Hub.Resource.Enabled and "" or entity.Hub.Resource[ resource ]
                end
            end

            _F.SetAbilities( ent )
            _F.SetAC( ent )
            _F.SetHealth( ent )
            _F.SetLevel( ent )
            _F.SetBoosts( ent )
            _F.SetSpells( ent )
            _F.SetSize( ent )
            _F.SetWeight( ent )
        end
    end

    return _F
end