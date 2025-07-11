local _V = require( "Server/Variables" )
local _F = require( "Server/Functions" )( _V )
local _H = require( "Server/Hooks" )( _V, _F )
local _J = require( "Server/Json" )

Ext.RegisterConsoleCommand( "BPSD", function() print( _J( _V ) ) end )
Ext.RegisterConsoleCommand( "SSD", function() print( _V.Seed ) end )

Ext.Vars.RegisterModVariable( ModuleUUID, "Seed", {} )
Ext.Vars.RegisterUserVariable( "ScalingDifficultySpellCache", {} )

if MCM then
    local function split( str )
        local ret = {}

        for s in str:gmatch( "[A-Z][^A-Z]*" ) do
            if not ret[ 3 ] then
                table.insert( ret, s )
            else
                ret[ 3 ] = ret[ 3 ] .. s
            end
        end

        return ret
    end

    Ext.ModEvents.BG3MCM[ "MCM_Setting_Saved" ]:Subscribe(
        function( payload )
            if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
                return
            end

            local s = split( payload.settingId )

            if _V.Hub[ s[ 2 ] ] and _V.Hub[ s[ 2 ] ][ s[ 1 ] ] then
                _V.Hub[ s[ 2 ] ][ s[ 1 ] ][ s[ 3 ] ] = payload.value
                _F.UpdateNPC()
            end
        end
    )
end