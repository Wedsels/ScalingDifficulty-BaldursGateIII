local _V = require( "Server/Variables" )
local _F = require( "Server/Functions" )( _V )
local _J = require( "Server/Json" )( _V )
local _H = require( "Server/Hooks" )( _V, _F )

Ext.RegisterConsoleCommand(
    "Blueprint",
    function()
        print( _J )
    end
)

local Settings = {}

local default = Ext.Json.Parse( Ext.IO.LoadFile( "Mods/Scaling Difficulty/MCM_blueprint.json", "data" ) )
for _,setting in pairs( default.Tabs[ 1 ].Settings ) do
    Settings[ setting.Id ] = setting.Default
end

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

SetSettings()

if MCM then
    for setting,_ in pairs( Settings ) do
        Settings[ setting ] = MCM.Get( setting )
    end
    SetSettings()

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