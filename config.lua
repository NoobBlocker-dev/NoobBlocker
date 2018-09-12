local AceConfig = LibStub("AceConfig-3.0")

local defaults = {
    response = "This player is ignoring players from your realm.",
    blocklist = {
        QuelThalas = { blocked = true },
        Drakkari = { blocked = true },
        Ragnaros = { blocked = true },
        Goldrinn = { blocked = true },
        Gallywix = { blocked = true },
        Azralon = { blocked = true },
        Nemesis = { blocked = true },
        TolBarad = { blocked = true },
        AmanThul = { blocked = true },
        Caelestrasz = { blocked = true },
        DathRemar = { blocked = true },
        Khazgoroth = { blocked = true },
        Nagrand = { blocked = true },
        Saurfang = { blocked = true },
        Barthilas = { blocked = true },
        Dreadmaul = { blocked = true },
        Frostmourne = { blocked = true },
        Gundrak = { blocked = true },
        JubeiThos = { blocked = true },
        Thaurissan = { blocked = true },
    },
}

local optionsTable = {
    type = "group",
    childGroups = "tab",
    args = {
        defaultResponse = {
            order = 0,
            name = "Default Response",
            desc = "Fall back response if no custom one specified.",
            type = "input",
            width = "full",
            cmdHidden = true,
            get = function() return NoobBlocker_Options.response end,
            set = function(_, val) NoobBlocker_Options.response = val end
        },
        silentMode = {
            name = "Silent Mode",
            desc = "Prevent auto whispering, silently blocking players.",
            type = "toggle",
            cmdHidden = true,
            get = function() return NoobBlocker_Options.silent end,
            set = function(_, val) NoobBlocker_Options.silent = val end
        },
        addEntry = {
            name = "Add Entry",
            type = "group",
            cmdHidden = true,
            args = {
                caseSensitiveWarning = {
                    order = 0, 
                    name = "Case Sensitive",
                    type = "header",
                },
                realmEditBox = {
                    order = 1,
                    name = "Realm(*)",
                    desc = "Realm name to block. (Required)",
                    type = "input",
                    width = "normal",
                    cmdHidden = true,
                    get = function() return NoobBlocker_Options.tempRealm end,
                    set = function(_, val) NoobBlocker_Options.tempRealm = val end,
                },
                playerEditBox = {
                    order = 2,
                    name = "Player",
                    desc = "Player to block. Leave blank to only block a realm.",
                    type = "input",
                    width = "normal",
                    cmdHidden = true,
                    get = function() return NoobBlocker_Options.tempPlayer end,
                    set = function(_, val) NoobBlocker_Options.tempPlayer = val end,
                },
                submitButton = {
                    order = -1,
                    name = "Add Entry",
                    desc = "Adds the entry to the blocklist. Does nothing if entry exists.",
                    type = "execute",
                    func = function() 
                        local player = NoobBlocker_Options.tempPlayer
                        local realm = NoobBlocker_Options.tempRealm
                        local realmData
                        if realm and NoobBlocker:FormatRealm(realm) ~= "" then
                            
                            if not NoobBlocker:DB_RealmExists(realm) then
                                realmData = NoobBlocker:DB_GetRealm(realm)
                                
                            end

                            if player and NoobBlocker:FormatRealm(player) ~= "" then
                                if not NoobBlocker:DB_PlayerExists(realm, player) then
                                    local playerData = NoobBlocker:DB_GetPlayer(realm, player)
                                    playerData.blocked = true
                                end

                            else 
                                realmData.blocked = true
                            end
                        end
                        NoobBlocker_Options.tempPlayer = nil
                        NoobBlocker_Options.tempRealm = nil
                        NoobBlocker:RefreshBlocklist()
                    end,
                },
            },
        },
        blocklist = {
            order = 1,
            name = "Block list",
            type = "group",
            cmdHidden = true,
            args = { },
        },
        reset = {
            order = -1,
            name = "Reset to Defaults",
            desc = "Reset all options to default values. |credThis will flush the Database!",
            type = "execute",
            cmdHidden = true,
            confirm = function() return "Reset options?" end,
            func = function() NoobBlocker:ResetConfig() end
        },
    },
}

local function SetupBlockedPlayerOptions(realm)
    realm = NoobBlocker:FormatRealm(realm)
    local blockedPlayers = {}
    blockedPlayers.name = "Blocked Players"
    blockedPlayers.type = "group"

    local blockedPlayersArgs = {}
    blockedPlayers.args = blockedPlayersArgs

    for player in pairs(NoobBlocker_DB[realm]) do
        if player ~= "response" and player ~= "blocked" and player ~= "silent" then -- filter tags
            local playerGroup = {}
            blockedPlayersArgs[tostring(player)] = playerGroup
            playerGroup.name = tostring(player)
            playerGroup.type = "group"

            local playerArgs = {}
            playerGroup.args = playerArgs

            local silentMode = {}
            playerArgs.silentMode = silentMode

            silentMode.name = "Silent Mode"
            silentMode.desc = "Silently block this player from groups. Prevents auto reply."
            silentMode.type = "toggle"
            silentMode.cmdHidden = true
            silentMode.get = function() return NoobBlocker:DB_GetPlayer(realm, player).silent or false end
            silentMode.set = function(_, val) NoobBlocker:DB_GetPlayer(realm, player).silent = val end

            local blocked = {}
            playerArgs.blocked = blocked

            blocked.name = "Block Player"
            blocked.desc = "Enables or disables blocking this player"
            blocked.type = "toggle"
            blocked.cmdHidden = true
            blocked.get = function() return NoobBlocker:DB_GetPlayer(realm, player).blocked or false end
            blocked.set = function(_, val) NoobBlocker:DB_GetPlayer(realm, player).blocked = val end

            local response = {}
            playerArgs.response = response

            response.name = "Response"
            response.desc = "Response for this specific player"
            response.type = "input"
            response.width = "full"
            response.cmdHidden = true
            response.get = function() return NoobBlocker:GetResponse(realm, player) end
            response.set = function(_, val) NoobBlocker:DB_GetPlayer(realm, player).response = val end

            local removeButton = {}
            playerArgs.removeButton = removeButton

            removeButton.name = "Remove"
            removeButton.desc = "Remove this player from the blocklist"
            removeButton.order = -1
            removeButton.type = "execute"
            removeButton.confirm = function() return "Remove this player from the blocklist?" end
            removeButton.func = function() NoobBlocker:DB_RemovePlayer(realm, player) end
        end
    end
    return blockedPlayers
end  

function NoobBlocker:RefreshBlocklist()
    wipe(optionsTable.args.blocklist.args)
    for realm in pairs(NoobBlocker_DB) do
        realm = NoobBlocker:FormatRealm(realm)
        local realmGroup = {}
        realmGroup.name = tostring(realm)
        realmGroup.type = "group"
        realmGroup.childGroups = "tab"
        local realmArgs = {}
        realmGroup.args = realmArgs

        local realmHeader = {}
        realmArgs.realmHeader = realmHeader

        realmHeader.name = tostring(realm)
        realmHeader.type = "header"
        realmHeader.order = 0

        local silentMode = {}
        realmArgs.silentMode = silentMode

        silentMode.name = "Silent Mode"
        silentMode.desc = "Silently block this realm from groups. Prevents auto reply."
        silentMode.type = "toggle"
        silentMode.cmdHidden = true
        silentMode.get = function() return NoobBlocker:DB_GetRealm(realm).silent or false end
        silentMode.set = function(_, val) NoobBlocker:DB_GetRealm(realm).silent = val end

        local blocked = {}
        realmArgs.blocked = blocked

        blocked.name = "Block Realm"
        blocked.desc = "Enables or disables blocking this realm"
        blocked.type = "toggle"
        blocked.cmdHidden = true
        blocked.get = function() return NoobBlocker:DB_GetRealm(realm).blocked end
        blocked.set = function(_, val) NoobBlocker:DB_GetRealm(realm).blocked = val end
        
        local response = {}
        realmArgs.response = response

        response.name = "Response"
        response.desc = "Response for this specific realm"
        response.type = "input"
        response.width = "full"
        response.cmdHidden = true
        response.get = function() return NoobBlocker:GetResponse(realm) end
        response.set = function(_, val) NoobBlocker:DB_GetRealm(realm).response = val end

        local removeButton = {}
        realmArgs.removeButton = removeButton

        removeButton.name = "Remove"
        removeButton.desc = "Remove this realm from the blocklist"
        removeButton.order = -1
        removeButton.type = "execute"
        removeButton.cmdHidden = true
        removeButton.confirm = function() return "Unblock this realm? This will unblock all players as well!" end
        removeButton.func = function() NoobBlocker:DB_RemoveRealm(realm) end

        local players = SetupBlockedPlayerOptions(realm)
        realmArgs.players = players

        optionsTable.args.blocklist.args[tostring(realm)] = realmGroup
    end
end



function NoobBlocker:ResetConfig()
    local function deepcopy(orig) -- from lua-users.org/wiki/CopyTable
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key)] = deepcopy(orig_value)
            end
            setmetatable(copy, deepcopy(getmetatable(orig)))
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end -- end lua-users copy paste

    NoobBlocker_Options = {}
    NoobBlocker_DB = {}
    NoobBlocker_Options.response = defaults.response
    NoobBlocker_DB = deepcopy(defaults.blocklist)
    self:RefreshBlocklist()
end

function NoobBlocker:SetupConfig()
    if not NoobBlocker_Options or not NoobBlocker_DB then
        self:ResetConfig()
    end
    self:RefreshBlocklist()
    AceConfig:RegisterOptionsTable("NoobBlocker", optionsTable)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NoobBlocker", "Noob Blocker")
end