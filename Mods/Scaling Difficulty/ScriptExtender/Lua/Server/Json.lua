--- @param _V _V
return function( _V )
    local json = {
        ModName = "Scaling Difficulty",
        ModDescription = "",
        Optional = true,
        SchemaVersion = 1,
        Tabs = {
            {
                TabId = "General",
                TabName = "General",
                Settings = {
                    {
                        Id = "NPC",
                        Name = "NPC",
                        Tooltip = "Choose which NPC to display.",
                        Type = "radio",
                        Default = "Enemy",
                        Options = {
                            Choices = {
                                "Enemy",
                                "Ally",
                                "Summon",
                                "Boss"
                            }
                        }
                    },
                    {
                        Id = "Page",
                        Name = "Page",
                        Tooltip = "Choose which options page to display.",
                        Type = "radio",
                        Default = "General",
                        Options = {
                            Choices = {
                                "General",
                                "Leveling",
                                "Bonus",
                                "Resource"
                            }
                        }
                    }
                }
            }
        }
    }

    local tips = {
        Downscaling = { "Downlevel NPC's which are above the Party Level.", "checkbox" },
        LevelBonus = { "Scale NPC's to Party Level + X.\nSet to a large negative with 'Downscaling' disabled to stop level scaling.", "int" },
        HP = { "Increase HP by X." },
        PercentHP = { "Increase HP by X%.\n0.05 means each enemy recieves a 5% max health bonus.", "float" },
        AC = { "Increase AC by X." },
        Attack = { "Increase Attack Rolls by X." },
        DamageBonus = { "Increase Damage by X." },
        Initiative = { "Increase Initiative by X." },
        Physical = { "Increase Physical Ability Score by X, based on its highest physical stat.\n( Strength or Dexterity )" },
        Casting = { "Increase Casting Ability Score by X, based on its spellcasting stat.\n( Intelligence, Charisma, or Wisdom )" },
        Strength = { "Increase Strength Ability Score by X." },
        Dexterity = { "Increase Dexterity Ability Score by X." },
        Constitution = { "Increase Constitution Ability Score by X." },
        Intelligence = { "Increase Intelligence Ability Score by X." },
        Wisdom = { "Increase Wisdom Ability Score by X." },
        Charisma = { "Increase Charisma Ability Score by X." },
        LevelingHP = { "Increase HP by X + Constitution Modifier each scaled level." },
        LevelingPercentHP = { "Increase HP by X% each scaled level.\n0.05 means each enemy recieves a 5% max health bonus.", "float" },
        LevelingAC = { "Increase AC by X each scaled level." },
        LevelingAttack = { "Increase Attack Rolls by X each scaled level." },
        LevelingDamageBonus = { "Increase Damage by X each scaled level." },
        LevelingInitiative = { "Increase Initiative by X each scaled level." },
        LevelingPhysical = { "Increase Physical Ability Score by X each scaled level, based on its highest physical stat.\n( Strength or Dexterity )" },
        LevelingCasting = { "Increase Casting Ability Score by X each scaled level, based on its spellcasting stat.\n( Intelligence, Charisma, or Wisdom )" },
        LevelingStrength = { "Increase Strength Ability Score by X each scaled level." },
        LevelingDexterity = { "Increase Dexterity Ability Score by X each scaled level." },
        LevelingConstitution = { "Increase Constitution Ability Score by X each scaled level." },
        LevelingIntelligence = { "Increase Intelligence Ability Score by X each scaled level." },
        LevelingWisdom = { "Increase Wisdom Ability Score by X each scaled level." },
        LevelingCharisma = { "Increase Charisma Ability Score by X each scaled level." },
        Movement = { Ext.Loca.GetTranslatedString( "hc76c8721g97e6g4d63gb106g1ab1dba11266" ) },
        ActionPoint = { Ext.Loca.GetTranslatedString( "hfcd95fc3g4707g4262g80f7gacb371aa8e92" ) },
        BonusActionPoint = { Ext.Loca.GetTranslatedString( "he0e99cd2g0e0dg4e68ga411g1ddbb114a19b" ) },
        ReactionActionPoint = { Ext.Loca.GetTranslatedString( "hb8abe274g41c8g481dgbd39g8a1c1c692457" ) },
        SpellSlotLevel1 = { "The levels at which this spell slot will be given, separated by ','.", "text" },
        SpellSlotLevel2 = { "The levels at which this spell slot will be given, separated by ','", "text" },
        SpellSlotLevel3 = { "The levels at which this spell slot will be given, separated by ','", "text" },
        SpellSlotLevel4 = { "The levels at which this spell slot will be given, separated by ','", "text" },
        SpellSlotLevel5 = { "The levels at which this spell slot will be given, separated by ','", "text" },
        SpellSlotLevel6 = { "The levels at which this spell slot will be given, separated by ','", "text" },
        SpellSlotLevel7 = { "The levels at which this spell slot will be given, separated by ','", "text" },
        SpellSlotLevel8 = { "The levels at which this spell slot will be given, separated by ','", "text" },
        SpellSlotLevel9 = { "The levels at which this spell slot will be given, separated by ','", "text" },
        Rage = { Ext.Loca.GetTranslatedString( "h7c96e7d6gdce7g41bagaaf0g832519ac3a5f" ) },
        KiPoint = { Ext.Loca.GetTranslatedString( "h8ab829e5g69d0g4319g95c5g93128aa37f69" ) },
        WildShape = { Ext.Loca.GetTranslatedString( "ha585d015g08f6g4c58ga0cdg5770377eb7e8" ) },
        ChannelOath = { Ext.Loca.GetTranslatedString( "he6aacd07g6f67g4579ga565g05ee25f8199f" ) },
        SorceryPoint = { Ext.Loca.GetTranslatedString( "hc3cb9a24g2714g46f1gb026g3cf7426738b5" ) },
        SuperiorityDie = { Ext.Loca.GetTranslatedString( "h1d06df95g7f0ag4a3eg996ag2f7c94531a0f" ) },
        ChannelDivinity = { Ext.Loca.GetTranslatedString( "hdfa5c2e4ge64ag4e66g8c04gd211d1e1762f" ) },
        BardicInspiration = { Ext.Loca.GetTranslatedString( "he1b259deg721cg4656g9c2fged20baed2a48" ) }
    }

    local default = {
        LevelingHP = 8.0,
        LevelingInitiative = 1.0,
        LevelingCasting = 1.25,
        LevelingPhysical = 1.25,
        LevelingBossHP = 12.0,
        LevelingBossCasting = 1.6,
        LevelingBossPhysical = 1.6,
        SpellSlotLevel1 = "1,1,2,3",
        SpellSlotLevel2 = "3,3,4",
        SpellSlotLevel3 = "5,5,6",
        SpellSlotLevel4 = "7,8,9",
        SpellSlotLevel5 = "9,10",
        SpellSlotLevel6 = "11"
    }

    local settings = json.Tabs[ 1 ].Settings

    local index = #json.Tabs + 1
    for npc,_ in pairs( _V.NPC ) do
        for _,setting in ipairs( _V.Settings ) do
            for _,stat in ipairs( _V[ setting ] or _V.Stats ) do
                index = index + 1
                table.insert( settings, {} )
                local edit = settings[ index ]

                edit.Id = setting .. npc .. stat
                edit.Name = stat
                edit.Tooltip = tips[ setting .. stat ] and tips[ setting .. stat ][ 1 ] or tips[ stat ][ 1 ]
                edit.Type = tips[ stat ][ 2 ] or ( setting ~= "Leveling" and "int" or "float" )

                local fallback
                if tips[ stat ][ 2 ] == "int" then
                    fallback = 0
                elseif tips[ stat ][ 2 ] == "checkbox" then
                    fallback = false
                elseif tips[ stat ][ 2 ] == "text" then
                    fallback = ""
                else
                    fallback = 0.0
                end

                edit.Default =
                    default[ setting .. npc .. stat ] or
                    default[ setting .. stat ] or
                    default[ npc .. stat ] or
                    default[ stat ] or
                    fallback

                edit.VisibleIf = {
                    Conditions = {
                        { SettingId = "NPC", Operator = "==", ExpectedValue = npc },
                        { SettingId = "Page", Operator = "==", ExpectedValue = setting }
                    }
                }
            end
        end
    end

    local out = Ext.Json.Stringify( json )

    local i = 0
    local string = {}
    local inside = false
    local loca = false

    local remove = {
        [ '\t' ] = true,
        [ '\n' ] = true,
        [ '\r' ] = true
    }

    while i <= #out do
        i = i + 1
        local c = out:sub( i, i )

        if c == '<' then
            loca = true
        end

        if c == '"' then
            inside = not inside
        end

        if not loca and not remove[ c ] and ( inside or c ~= ' ' ) then
            table.insert( string, c )
        end

        if c == '>' then
            loca = false
        end
    end

    print( table.concat( string ) )
end