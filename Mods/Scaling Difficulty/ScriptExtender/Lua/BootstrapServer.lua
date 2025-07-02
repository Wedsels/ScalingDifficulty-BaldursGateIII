local _V = require( "Server/Variables" )
local _F = require( "Server/Functions" )( _V )
local _H = require( "Server/Hooks" )( _V, _F )
local _J = require( "Server/Json" )

Ext.RegisterConsoleCommand( "BPSD", function() print( _J( _V ) ) end )
Ext.RegisterConsoleCommand( "SSD", function() print( _V.Seed ) end )

Ext.Vars.RegisterModVariable( ModuleUUID, "Seed", {} )