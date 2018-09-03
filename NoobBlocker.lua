----todo: raiderIO filtering.
----todo: friend channels to share blocklists. 

function NoobBlocker:FormatRealm(realm)
    return realm:gsub('[%p%c%s]', '')
end

_G.StaticPopupDialogs["NOOBBLOCKER_ADD_USER"] = {
    text = "%s",
    button1 = ACCEPT,
    button2 = CLOSE,
    hasEditBox = true,
    hasWideEditBox = true,
    editBoxWidth = 500,
    preferredIndex = 3,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnShow = function(self)
        self:SetWidth(1200)
        local editBox = self.wideEditBox or self.editBox
        editBox:SetText(self.text.text_arg2)
        editBox:SetFocus()
        editBox:HighlightText(false)
        local accept = self.button1
        local close = self.button2
        
        accept:ClearAllPoints()
        accept:SetWidth(150)
        accept:SetPoint("CENTER", editBox, "CENTER", -87, -30)
        close:ClearAllPoints()
        close:SetWidth(150)
        close:SetPoint("CENTER", editBox, "CENTER", 87, -30)
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    OnHide = nil,
    OnAccept = function(self, realm, name)
        realm = NoobBlocker:FormatRealm(realm)
        local editBox = self.wideEditBox or self.editBox
        local response = editBox:GetText()
        local entry = NoobBlocker:DB_GetPlayer(realm, name)
        if entry then
            entry.response = response
            entry.blocked = true
        end
    end,
    OnCancel = nil
}

_G.StaticPopupDialogs["NOOBBLOCKER_DECLINE_USER"] = {
    text = "%s",
    button1 = ACCEPT,
    button2 = CLOSE,
    hasEditBox = false,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    OnShow = function(self)
        self:SetWidth(400)
        local decline = self.button1
        
        decline:ClearAllPoints()
        decline:SetWidth(185)
        decline:SetPoint("CENTER", self, "CENTER", 0, -10)

        local close = self.button2

        close:ClearAllPoints()
        close:SetWidth(50)
        close:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -5, 5)
    end,
    OnHide = nil,
    OnAccept = function(self, id)
        C_LFGList.DeclineApplicant(id)
        if not NoobBlocker_Options.silent and not NoobBlocker:DB_GetPlayer(self.realm, self.player).silent then
            SendChatMessage("[NoobBlocker]: " ..NoobBlocker:GetResponse(self.realm, self.player), "WHISPER", nil, self.fullName)
        end
    end,
    OnCancel = nil,        
}

function NoobBlocker:CHAT_MSG_WHISPER(event, msg, author)
    player, realm = ("-"):split(author)
    realm = self:FormatRealm(realm)

    -- if the player is blocked reply and exit
    if self:DB_PlayerExists(realm, player) then
        local playerData = self:DB_GetPlayer(realm, player)

        if playerData.blocked then 
            local response = self:GetResponse(realm, player)
            if not playerData.silent and not NoobBlocker_Options.silent then
                SendChatMessage("[NoobBlocker]: " ..response, "WHISPER", nil, author)
            end
            return -- exit early since we already blocked via player.
        end
    end

    -- if the realm is blocked reply
    if self:DB_RealmExists(realm) then
        local realmData = self:DB_GetRealm(realm)

        if realmData.blocked then
            local response = self:GetResponse(realm)
            if not realmData.silent and not NoobBlocker_Options.silent then 
                SendChatMessage("[NoobBlocker]: " ..response, "WHISPER", nil, author)
            end
        end
    end
end
-- do we really need to block bnet players?

-- function NoobBlocker:CHAT_MSG_BN_WHISPER(event, msg, author, ...)
--     local bnetID = select(11, ...)
--     local player, realm
--     local index = BNGetFriendIndex(bnetID)
--     if index then 
--         local numGameAccounts = BNGetNumFriendGameAccounts(index)

--         for i = 1, numGameAccounts do
--             local _, bnPlayer, client, bnRealm = BNGetFriendGameAccountInfo(index, i)

--             if client == BNET_CLIENT_WOW then
--                 player = bnPlayer
--                 realm = bnRealm
--             end
--         end
--     end

--     if player and realm then
--         realm = NoobBlocker:FormatRealm(realm)
--         if NoobBlocker:DB_PlayerExists(realm, player) then
--             local playerData = self:DB_GetPlayer(realm, player)
--             if playerData.blocked then 
--                 BNSendWhisper(bnetID, "[NoobBlocker]: " ..self:GetResponse(realm, player))
--             end
--         end
--     end
-- end

function NoobBlocker:LFG_LIST_APPLICANT_LIST_UPDATED(event, hasPending, hasPendingData)
    if not UnitIsGroupLeader("Player", LE_PARTY_CATEGORY_HOME) then
        return
    end
    StaticPopup_Hide("NOOBBLOCKER_DECLINE_USER") -- hide to prevent edge case where the player leaves before button was clicked.
    if hasPending and hasPendingData then
        local applicants = C_LFGList.GetApplicants()

        for i=1, #applicants do 
            local id, status, pendingStatus, numMembers, isNew = C_LFGList.GetApplicantInfo(applicants[i]);

            for i=1, numMembers do 
                local fullName = C_LFGList.GetApplicantMemberInfo(id, i)
                local player, realm = ("-"):split(fullName)
                if not realm then
                    realm = GetRealmName()
                end
                realm = self:FormatRealm(realm)

                if (self:DB_PlayerExists(realm, player) and self:DB_GetPlayer(realm, player).blocked)
                    or (self:DB_RealmExists(realm) and self:DB_GetRealm(realm).blocked) then

                    local dialog = StaticPopup_Show("NOOBBLOCKER_DECLINE_USER", "Decline "..fullName)
                    dialog.data = id
                    dialog.player = player
                    dialog.realm = realm
                    dialog.fullName = fullName
                end
            end
        end
    end
end

function NoobBlocker:RegisterChatEvents()
    NoobBlocker:RegisterEvent("CHAT_MSG_WHISPER")
    --self:RegisterEvent("CHAT_MSG_BN_WHISPER")
    NoobBlocker:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
end