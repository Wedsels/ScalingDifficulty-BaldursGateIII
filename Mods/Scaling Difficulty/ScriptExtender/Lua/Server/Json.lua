--- @param _V _V
return function( _V )
    local json = {
        ModName = "Scaling Difficulty",
        ModDescription = "",
        Optional = true,
        SchemaVersion = 1,
        Tabs = {
            {
                TabId = "Scaling",
                TabName = "Scaling",
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
                                "Boss",
                                "Player"
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
                                "Variation",
                                "Resource"
                            }
                        },
                        VisibleIf = { Conditions = { { SettingId = "NPC", Operator = "!=", ExpectedValue = "Player" } } }
                    },
                    {
                        Id = "PlayerPage",
                        Name = "Page",
                        Tooltip = "Choose which options page to display.",
                        Type = "radio",
                        Default = "Leveling",
                        Options = {
                            Choices = {
                                "Leveling",
                                "Bonus",
                                "Variation",
                                "Resource"
                            }
                        },
                        VisibleIf = { Conditions = { { SettingId = "NPC", Operator = "==", ExpectedValue = "Player" } } }
                    }
                }
            },
            {
                TabId = "General",
                TabName = "General",
                Settings = {
                    {
                        Id = "Default",
                        Name = "Default",
                        Tooltip = "Reset all options to default.",
                        Type = "event_button",
                        Options = { Label = "Default" }
                    },
                    {
                        Id = "Disable",
                        Name = "Disable",
                        Tooltip = "Disable all pages and effects.",
                        Type = "event_button",
                        Options = { Label = "Disable" }
                    },
                    {
                        Id = "Enable",
                        Name = "Enable",
                        Tooltip = "Enable all pages and effects.",
                        Type = "event_button",
                        Options = { Label = "Enable" }
                    },
                    {
                        Id = "Seed",
                        Name = "Seed",
                        Tooltip = "Randomize the savegame seed for all random/variation effects.",
                        Type = "event_button",
                        Options = { Label = "Seed" }
                    }
                }
            }
        }
    }

    local tips = {
        Enabled = { "", "checkbox" },
        LevelBonus = { "Level the NPC to the Party Level + X.", "int" },
        Downscaling = { "Downlevel the NPC to the Party Level.", "checkbox" },
        ExperienceLevel = { "Whether the NPC's base Experience Reward will match their scaled Level.", "checkbox" },
        Spells = { "Give NPC casters a random number of spells up to X * Level.\n\nThe given spells match the NPC archetype from a custom dynamic class-based system.\nWorks with any modded spells.", "float" },
        SpellBlacklist = { "The names of spells to not give through NPC Spells sepearated by ';'\n\nSuch as:\nLighting Arrow;True Strike", "text" },
        HP = { "Increase NPC HP by X." },
        PercentHP = { "Increase NPC HP by X%.\n0.05 means each NPC recieves a 5% max health bonus.", "float" },
        AC = { "Increase NPC AC by X." },
        Attack = { "Increase NPC Attack Rolls by X." },
        DamageBonus = { "Increase NPC Damage by X." },
        Initiative = { "Increase NPC Initiative by X." },
        Physical = { "Increase NPC Physical Ability Score by X, based on its highest physical stat.\n( Strength or Dexterity )" },
        Casting = { "Increase NPC Casting Ability Score by X, based on its spellcasting stat.\n( Intelligence, Charisma, or Wisdom )" },
        Strength = { "Increase NPC Strength Ability Score by X." },
        Dexterity = { "Increase NPC Dexterity Ability Score by X." },
        Constitution = { "Increase NPC Constitution Ability Score by X." },
        Intelligence = { "Increase NPC Intelligence Ability Score by X." },
        Wisdom = { "Increase NPC Wisdom Ability Score by X." },
        Charisma = { "Increase NPC Charisma Ability Score by X." },
        Experience = { "Increase Experience awarded by the NPC by X." },
        PercentExperience = { "Increase Experience awarded by the NPC by X%.\n0.05 means each NPC recieves a 5% experience bonus.", "float" },
        Size = { "Increase NPC Size by X%.\n0.05 means each NPC recieves a 5% Size bonus.\nSize influences Weight and maximum HP.", "float" },
        LevelingHP = { "Increase NPC HP by X + Constitution Modifier each scaled level.", "float" },
        LevelingPercentHP = { "Increase NPC HP by X% each scaled level.\n0.05 means each NPC recieves a 5% max health bonus.", "float" },
        LevelingAC = { "Increase NPC AC by X each scaled level.", "float" },
        LevelingAttack = { "Increase NPC Attack Rolls by X each scaled level.", "float" },
        LevelingDamageBonus = { "Increase NPC Damage by X each scaled level.", "float" },
        LevelingInitiative = { "Increase NPC Initiative by X each scaled level.", "float" },
        LevelingPhysical = { "Increase NPC Physical Ability Score by X each scaled level, based on its highest physical stat.\n( Strength or Dexterity )", "float" },
        LevelingCasting = { "Increase NPC Casting Ability Score by X each scaled level, based on its spellcasting stat.\n( Intelligence, Charisma, or Wisdom )", "float" },
        LevelingStrength = { "Increase NPC Strength Ability Score by X each scaled level.", "float" },
        LevelingDexterity = { "Increase NPC Dexterity Ability Score by X each scaled level.", "float" },
        LevelingConstitution = { "Increase NPC Constitution Ability Score by X each scaled level.", "float" },
        LevelingIntelligence = { "Increase NPC Intelligence Ability Score by X each scaled level.", "float" },
        LevelingWisdom = { "Increase NPC Wisdom Ability Score by X each scaled level.", "float" },
        LevelingCharisma = { "Increase NPC Charisma Ability Score by X each scaled level.", "float" },
        LevelingSize = { "Increase NPC size by X% each scaled level.\n0.05 means each NPC recieves a 5% size bonus.\nSize influences weight and maximum HP.", "float" },
        VariationHP = { "Increase NPC HP by a random amount up to X.", "float" },
        VariationPercentHP = { "Increase NPC HP by a random amount up to X%.\n0.05 means each NPC recieves a 5% max health bonus.", "float" },
        VariationAC = { "Increase NPC AC by a random amount up to X.", "float" },
        VariationAttack = { "Increase NPC Attack Rolls by a random amount up to X.", "float" },
        VariationDamageBonus = { "Increase NPC Damage by a random amount up to X.", "float" },
        VariationInitiative = { "Increase NPC Initiative by a random amount up to X.", "float" },
        VariationPhysical = { "Increase NPC Physical Ability Score by a random amount up to X, based on its highest physical stat.\n( Strength or Dexterity )", "float" },
        VariationCasting = { "Increase NPC Casting Ability Score by a random amount up to X, based on its spellcasting stat.\n( Intelligence, Charisma, or Wisdom )", "float" },
        VariationStrength = { "Increase NPC Strength Ability Score by a random amount up to X.", "float" },
        VariationDexterity = { "Increase NPC Dexterity Ability Score by a random amount up to X.", "float" },
        VariationConstitution = { "Increase NPC Constitution Ability Score by a random amount up to X.", "float" },
        VariationIntelligence = { "Increase NPC Intelligence Ability Score by a random amount up to X.", "float" },
        VariationWisdom = { "Increase NPC Wisdom Ability Score by a random amount up to X.", "float" },
        VariationCharisma = { "Increase NPC Charisma Ability Score by a random amount up to X.", "float" },
        VariationSize = { "Increase NPC size by a random amount up to X%.\n0.05 means each NPC recieves a 5% size bonus.\nSize influences weight and maximum HP.", "float" },
        SpellSlotLevel1 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        SpellSlotLevel2 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        SpellSlotLevel3 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        SpellSlotLevel4 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        SpellSlotLevel5 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        SpellSlotLevel6 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        SpellSlotLevel7 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        SpellSlotLevel8 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        SpellSlotLevel9 = { "The levels at which this spell slot will be given to the NPC, separated by ','", "text" },
        Movement = { Ext.Loca.GetTranslatedString( "hc76c8721g97e6g4d63gb106g1ab1dba11266" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        ActionPoint = { Ext.Loca.GetTranslatedString( "hfcd95fc3g4707g4262g80f7gacb371aa8e92" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        BonusActionPoint = { Ext.Loca.GetTranslatedString( "he0e99cd2g0e0dg4e68ga411g1ddbb114a19b" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        ReactionActionPoint = { Ext.Loca.GetTranslatedString( "hb8abe274g41c8g481dgbd39g8a1c1c692457" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        Rage = { Ext.Loca.GetTranslatedString( "h7c96e7d6gdce7g41bagaaf0g832519ac3a5f" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        KiPoint = { Ext.Loca.GetTranslatedString( "h8ab829e5g69d0g4319g95c5g93128aa37f69" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        WildShape = { Ext.Loca.GetTranslatedString( "ha585d015g08f6g4c58ga0cdg5770377eb7e8" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        ChannelOath = { Ext.Loca.GetTranslatedString( "he6aacd07g6f67g4579ga565g05ee25f8199f" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        SorceryPoint = { Ext.Loca.GetTranslatedString( "hc3cb9a24g2714g46f1gb026g3cf7426738b5" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        SuperiorityDie = { Ext.Loca.GetTranslatedString( "h1d06df95g7f0ag4a3eg996ag2f7c94531a0f" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        ChannelDivinity = { Ext.Loca.GetTranslatedString( "hdfa5c2e4ge64ag4e66g8c04gd211d1e1762f" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" },
        BardicInspiration = { Ext.Loca.GetTranslatedString( "he1b259deg721cg4656g9c2fged20baed2a48" ) .. "\nThe levels at which this resource will be given to the NPC, separated by ','", "text" }
    }

    local default = {
        Enabled = true,
        Spells = 0.75,
        LevelingBossHP = 10.0,
        LevelingHP = 6.0,
        LevelingInitiative = 0.5,
        LevelingCasting = 0.5,
        LevelingPhysical = 0.5,
        LevelingStrength = 0.33,
        LevelingDexterity = 0.33,
        LevelingConstitution = 0.25,
        LevelingIntelligence = 0.33,
        LevelingWisdom = 0.33,
        LevelingCharisma = 0.33,
        SpellSlotLevel1 = "1,1,2,3",
        SpellSlotLevel2 = "3,3,4",
        SpellSlotLevel3 = "5,5,6",
        SpellSlotLevel4 = "7,8,9",
        SpellSlotLevel5 = "9,10",
        SpellSlotLevel6 = "11",
        VariationSize = 0.2
    }

    local settings = json.Tabs[ 1 ].Settings

    for npc,_ in pairs( _V.NPC ) do
        for _,setting in ipairs( _V.Settings ) do
            for _,stat in ipairs( _V[ setting ] or _V.Stats ) do
                settings[ #settings + 1 ] = {}
                local edit = settings[ #settings ]
                local tip = tips[ setting .. stat ] or tips[ stat ]
                local enabler = stat == "Enabled"

                edit.Id = setting .. npc .. stat
                edit.Name = stat
                edit.Type = tip[ 2 ] or "int"

                local fallback
                if tip[ 2 ] == "int" then
                    fallback = 0
                elseif tip[ 2 ] == "checkbox" then
                    fallback = false
                elseif tip[ 2 ] == "text" then
                    fallback = ""
                else
                    fallback = 0.0
                end

                edit.Default =
                    npc == "Player" and fallback or
                    default[ setting .. npc .. stat ] or
                    default[ setting .. stat ] or
                    default[ npc .. setting ] or
                    default[ npc .. stat ] or
                    default[ setting ] or
                    default[ stat ] or
                    default[ npc ] or
                    fallback

                edit.VisibleIf = {
                    Conditions = {
                        { SettingId = "NPC", Operator = "==", ExpectedValue = npc },
                        { SettingId = ( npc == "Player" and npc or "" ) .. "Page", Operator = "==", ExpectedValue = setting }
                    }
                }

                if enabler then
                    edit.Tooltip = "Enable or disable " .. npc .. " " .. setting .. "."
                else
                    edit.Tooltip = tip[ 1 ]:gsub( "NPC", npc )
                    edit.VisibleIf.Conditions[ #edit.VisibleIf.Conditions + 1 ] = { SettingId = setting .. npc .. "Enabled", Operator = "==", ExpectedValue = true }
                end
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

    return table.concat( string )
end