--- @param _V _V
--- @param _F _F
return function( _V, _F )
    Ext.Events.GameStateChanged:Subscribe(
        function( e )
            if e.FromState ~= "LoadLevel" or e.ToState ~= "Sync" then return end

            for _,ent in pairs( Ext.Entity.GetAllEntities() ) do
                _F.AddNPC( ent )
            end
        end
    )

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

            Ext.Osiris.RegisterListener( "CombatStarted", 1, "after", function() _F.UpdateNPC() end )
            Ext.Osiris.RegisterListener( "LeveledUp", 1, "after", function( c ) if Osi.DB_Players:Get( _F.UUID( c ) )[ 1 ] then _F.UpdateNPC() end end )

            Ext.Osiris.RegisterListener( "TurnStarted", 1, "after", function( c ) if Osi.IsActive( _F.UUID( c ) ) ~= 1 then return end _F.UpdateNPC( _F.UUID( c ) ) end )

            Ext.Entity.OnCreate( "EocLevel", function( ent ) Ext.Timer.WaitFor( 500, function() if Osi.IsActive( _F.UUID( ent ) ) ~= 1 then return end _F.AddNPC( ent ) end ) end )

            Ext.Entity.OnChange( "Stats", function( ent, _, index ) if Osi.IsActive( _F.UUID( ent ) ) ~= 1 or index ~= 79 then return end _F.SetAbilities( ent ) end )
            Ext.Entity.OnChange( "Health", function( ent, _, index ) if Osi.IsActive( _F.UUID( ent ) ) ~= 1 then return end _F.SetHealth( ent, index ) end )
            Ext.Entity.OnChange( "EocLevel", function( ent, _, index ) if Osi.IsActive( _F.UUID( ent ) ) ~= 1 or index ~= 1 then return end _F.SetLevel( ent ) end )
            Ext.Entity.OnChange( "Resistances", function( ent, _, index ) if Osi.IsActive( _F.UUID( ent ) ) ~= 1 or index ~= 4 then return end _F.SetAC( ent ) end )
        end
    )
end