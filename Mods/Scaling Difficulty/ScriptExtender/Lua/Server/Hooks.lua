--- @param _V _V
--- @param _F _F
return function( _V, _F )
    Ext.Events.GameStateChanged:Subscribe(
        function( e )
            if e.FromState ~= "LoadLevel" or e.ToState ~= "Sync" then return end

            local modvar = Ext.Vars.GetModVariables( ModuleUUID )
            if not modvar.Seed then
                modvar.Seed = math.random( math.maxinteger )
            end
            _V.Seed = modvar.Seed

            local Settings = _F.DefaultBlueprint()

            local function SetSettings()
                for npc,_ in pairs( _V.NPC ) do
                    _V.Hub[ npc ] = _V.Hub[ npc ] or {}
                    for _,setting in ipairs( _V.Settings ) do
                        _V.Hub[ npc ][ setting ] = _V.Hub[ npc ][ setting ] or {}

                        for _,stat in ipairs( _V[ setting ] or _V.Stats ) do
                            _V.Hub[ npc ][ setting ][ stat ] = Settings[ setting .. npc .. stat ]
                        end
                    end
                end
            end

            if MCM then
                for setting,_ in pairs( Settings ) do
                    local val = MCM.Get( setting )
                    if val ~= nil then
                        Settings[ setting ] = val
                    end
                end
            end

            SetSettings()

            for _,ent in pairs( Ext.Entity.GetAllEntities() ) do
                _F.AddNPC( ent )
            end
        end
    )

    local function Dispatch( func, e, index )
        local uuid, entity, ent = _F.GetEntity( e )
        func( uuid, entity, ent, index )
    end

    Ext.Osiris.RegisterListener(
        "LevelGameplayStarted",
        2,
        "after",
        function()
            for _,ent in pairs( Ext.Entity.GetAllEntities() ) do
                local uuid = _F.UUID( ent )
                if uuid then
                    Osi.AddBoosts( uuid, "IncreaseMaxHP( 0 )", _V.Key, "" )
                    Ext.Timer.WaitFor( 500, function() Osi.RemoveBoosts( uuid, "IncreaseMaxHP( 0 )", 0, _V.Key, "" ) end )
                end
            end

            Ext.Entity.OnCreate( "EocLevel", function( ent ) Ext.Timer.WaitFor( 500, function() _F.AddNPC( ent ) end ) end )

            Ext.Osiris.RegisterListener( "CombatStarted", 1, "after", function() _V.Reset = true end )
            Ext.Osiris.RegisterListener( "CombatEnded", 1, "after", function() _V.Reset = true end )
            Ext.Osiris.RegisterListener( "LeveledUp", 1, "after", function( c ) if Osi.DB_Players:Get( _F.UUID( c ) )[ 1 ] then _V.Reset = true end end )

            Ext.Osiris.RegisterListener( "TurnStarted", 1, "after", function( c ) if Osi.IsActive( _F.UUID( c ) ) ~= 1 then return end _F.UpdateNPC( _F.UUID( c ) ) end )

            Ext.Entity.OnChange( "Stats", function( ent, _, index ) Dispatch( _F.SetAbilities, ent, index ) end )
            Ext.Entity.OnChange( "Health", function( ent, _, index ) Dispatch( _F.SetHealth, ent, index ) end )
            Ext.Entity.OnChange( "EocLevel", function( ent, _, index ) Dispatch( _F.SetLevel, ent ) end )
            Ext.Entity.OnChange( "Resistances", function( ent, _, index ) Dispatch( _F.SetAC, ent, index ) end )
        end
    )

    local reset = -1
    Ext.Events.Tick:Subscribe(
        function()
            if _V.Reset then
                reset = Ext.Utils.MonotonicTime()
                _V.Reset = false
            elseif reset > 0 and Ext.Utils.MonotonicTime() - reset > 50 then
                reset = -1
                _F.UpdateNPC()
            end
        end
    )
end