NoobBlocker = LibStub("AceAddon-3.0"):NewAddon("NoobBlocker", "AceComm-3.0", "AceHook-3.0", "AceEvent-3.0")


function NoobBlocker:OnInitialize()
    self:SetupConfig()
    self:SetupHooks()
    self:RegisterChatEvents()
end