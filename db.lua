function NoobBlocker:DB_RealmExists(realm)
  NoobBlocker:FormatRealm(realm)
  return NoobBlocker_DB[realm] 
end

function NoobBlocker:DB_PlayerExists(realm, player)
  NoobBlocker:FormatRealm(realm)
  return NoobBlocker_DB[realm] and NoobBlocker_DB[realm][player]
end

function NoobBlocker:GetResponse(realm, player)
  assert(realm)
  NoobBlocker:FormatRealm(realm)
  if player and NoobBlocker:DB_PlayerExists(realm, player) then
    return NoobBlocker_DB[realm][player].response or NoobBlocker_Options.response
  end

  if NoobBlocker:DB_RealmExists(realm) then
    return NoobBlocker_DB[realm].response or NoobBlocker_Options.response
  end

  return NoobBlocker_Options.response
end

function NoobBlocker:DB_GetRealm(realm)
  NoobBlocker:FormatRealm(realm)
  if not NoobBlocker:DB_RealmExists(realm) then
    local realmData = {}
    NoobBlocker_DB[realm] = realmData
  end

  return NoobBlocker_DB[realm]
end

function NoobBlocker:DB_GetPlayer(realm, player)
  NoobBlocker:FormatRealm(realm)
  local realmData = NoobBlocker:DB_GetRealm(realm)

  if not NoobBlocker:DB_PlayerExists(realm, player) then
    local playerData = {}
    realmData[player] = playerData
  end
  return realmData[player]
end

function NoobBlocker:DB_RemovePlayer(realm, player)
  NoobBlocker:FormatRealm(realm)
  if NoobBlocker:DB_PlayerExists(realm, player) then
    NoobBlocker_DB[realm][player] = nil
    NoobBlocker:RefreshBlocklist()
  end
end

function NoobBlocker:DB_RemoveRealm(realm)
  NoobBlocker:FormatRealm(realm)
  if NoobBlocker:DB_RealmExists(realm) then
    NoobBlocker_DB[realm] = nil
    NoobBlocker:RefreshBlocklist()
  end
end