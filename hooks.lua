local allowedDropdownTypes = {
    PARTY = true,
    PLAYER = true,
    RAID_PLAYER = true,
    RAID = true,
    FRIEND = true,
    GUILD = true,
    GUILD_OFFLINE = true,
    CHAT_ROSTER = true,
    TARGET = true,
    ARENAENEMY = true,
    FOCUS = true,
    WORLD_STATE_SCORE = true,
    COMMUNITIES_WOW_MEMBER = true,
    COMMUNITIES_GUILD_MEMBER = true,
}

function NoobBlocker:SetupHooks()
    NoobBlocker:HookScript(DropDownList1, "OnShow", "DropDownList_OnShow")
    NoobBlocker:HookScript(self.optionsFrame, "OnShow", "OptionsFrame_OnShow")
end

function NoobBlocker:DropDownList_OnShow(frame)
    local dropdown = frame.dropdown
    if not dropdown then -- shouldn't be necessary?
        return
    end

    if dropdown.unit then -- check if we're trying to noob block ourselves
        if dropdown.unit == "player" or not UnitIsPlayer(dropdown.unit) then
            return
        end
    end

    local shouldDisplayButton, playerName, playerRealm

    -- maybe some day we'll care about bnet friends but its stupid right now.
    if dropdown.bnetIDAccount then 
        return -- exit since we shouldn't care about bnet friends.

    -- handle lfg window
    elseif dropdown.Button == _G.LFGListFrameDropDownButton then 
        shouldDisplayButton = true
        playerName, playerRealm = ("-"):split(dropdown.menuList[2].arg1)

    -- handle everything else
    elseif dropdown.which and allowedDropdownTypes[dropdown.which] then
        shouldDisplayButton = true

        if not dropdown.name:find('-') then
            playerName = dropdown.name
            playerRealm = dropdown.server
        else
            playerName, playerRealm = ("-"):split(dropdown.name)
        end
    end
    


    if not playerRealm then 
        playerRealm = GetRealmName() -- assume same realm
    end

    playerRealm = NoobBlocker:FormatRealm(playerRealm)

    if playerRealm == "" then
        return
    end

    if playerName == UnitName("player") then
        return -- exit if we found a way to locate ourselves anyways.
    end
    
    if shouldDisplayButton then 
        local info
        if NoobBlocker:DB_PlayerExists(playerRealm, playerName) then
            info = {
                text = "Unblock Noob",
                func = function() NoobBlocker:DB_RemovePlayer(playerRealm, playerName) end, 
                notCheckable = true,
            }
        else
            info = {
                text = "Block Noob",
                func = function() NoobBlocker:ShowDialog(playerRealm, playerName) end,
                notCheckable = true,
            }
        end
        UIDropDownMenu_AddButton(info)
    end
end


function NoobBlocker:ShowDialog(realm, name)
    realm = NoobBlocker:FormatRealm(realm)
    local dialog  = StaticPopup_Show("NOOBBLOCKER_ADD_USER",
                                    "Enter Response for "..name.."-"..realm,
                                    NoobBlocker_Options.response)
    dialog.data = realm
    dialog.data2 = name
end

function NoobBlocker:OptionsFrame_OnShow()
    NoobBlocker:RefreshBlocklist()
end