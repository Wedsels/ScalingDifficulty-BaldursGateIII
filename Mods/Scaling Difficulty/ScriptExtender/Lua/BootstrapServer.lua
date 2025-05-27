local _V = require( "Server/Variables" )
local _F = require( "Server/Functions" )( _V )
local _H = require( "Server/Hooks" )( _V, _F )

local class
for line in Ext.IO.LoadFile( "Mods/Scaling Difficulty/ScriptExtender/Lua/Server/Variables.lua", "data" ):gmatch( "[^\r\n]+" ) do
    if class then
        local field = line:match( "^%s*---%s*@field%s+([%w_]+)" )
        if field then
            table.insert( _V[ class ], field )
        else
            class = nil
        end
    elseif line:find( "--- @class" ) then
        local l = line:match( "^%s*---%s*@class%s+([%w_]+)" )
        if _V[ l ] then
            class = l
        end
    end
end

local default = Ext.Json.Parse( Ext.IO.LoadFile( "Mods/Scaling Difficulty/MCM_blueprint.json", "data" ) )
for _,tab in pairs( default.Tabs ) do
    _V.Hub[ tab.TabId ] = _V.Hub[ tab.TabId ] or {}
    _V.Hub[ tab.TabId ] = _V.Hub[ tab.TabId ] or {}

    for _,s in pairs( tab.Sections ) do
        _V.Hub[ tab.TabId ][ s.SectionName ] = _V.Hub[ tab.TabId ][ s.SectionName ] or {}
        for _,g in pairs( s.Settings ) do
            _V.Hub[ tab.TabId ][ s.SectionName ][ g.Name ] = g.Default
        end
    end
end

if MCM then
    local function SetValues()
        for npc,hub in pairs( _V.Hub ) do
            for type,settings in pairs( hub ) do
                for setting,_ in pairs( settings ) do
                    hub[ type ][ setting ] = MCM.Get( type .. npc .. setting )
                end
            end
        end
    end

    SetValues()

    Ext.ModEvents.BG3MCM[ "MCM_Setting_Saved" ]:Subscribe(
        function( payload )
            if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
                return
            end

            SetValues()
            _F.UpdateNPC()
        end
    )
end