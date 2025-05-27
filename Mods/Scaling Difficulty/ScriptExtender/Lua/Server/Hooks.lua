--- @param _V _V
--- @param _F _F
return function( _V, _F )
    Ext.Events.GameStateChanged:Subscribe(
        function( e )
            if e.FromState ~= "LoadLevel" then return end

            Ext.Osiris.RegisterListener( "LeveledUp", 1, "after", function() _F.UpdateNPC() end )

            for _,ent in pairs( Ext.Entity.GetAllEntities() ) do
                _F.AddNPC( ent )
            end

            Ext.Osiris.RegisterListener(
                "LevelGameplayStarted",
                2,
                "after",
                function()
                    for _,ent in pairs( Ext.Entity.GetAllEntities() ) do
                        if ent.Uuid then
                            Osi.AddBoosts( ent.Uuid.EntityUuid, "IncreaseMaxHP( 0 )", "", "" )
                        end
                    end
                end
            )

            Ext.Entity.OnCreate(
                "EocLevel",
                function( ent, component, index )
                    _F.Delay( 500, _F.AddNPC, ent )
                end
            )

            Ext.Entity.OnChange(
                "Resistances",
                function( ent, component, index )
                    if index ~= 4 then return end

                    _F.SetAC( ent )
                end
            )

            Ext.Entity.OnChange(
                "Stats",
                function( ent, component, index )
                    if index ~= 79 then return end

                    _F.SetAbilities( ent )
                end
            )

            Ext.Entity.OnChange(
                "Health",
                function( ent, component, index )
                    _F.SetHealth( ent, index )
                end
            )

            Ext.Entity.OnChange(
                "EocLevel",
                function( ent, component, index )
                    if index ~= 1 then return end

                    _F.SetLevel( ent )
                end
            )
        end
    )
end