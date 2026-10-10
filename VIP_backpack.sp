#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <vip_core> 

#pragma semicolon 1
#pragma newdecls required


char g_sBackpack[MAXPLAYERS + 1][32];


char g_sFeatureName[] = "VirtualBackpack";

public Plugin myinfo = 
{
    name = "[VIP] Virtual Backpack",
    author = "FameCSGO",
    description = "Виртуальный рюкзак для второго оружия под VIP Core",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_swap", Command_Swap, "Убрать/достать оружие из рюкзака");
    RegConsoleCmd("sm_pack", Command_Swap, "Альтернативная команда");
    
    HookEvent("player_spawn", Event_PlayerSpawn);
    

    if (VIP_IsVIPLoaded())
    {
        VIP_OnVIPLoaded();
    }
}


public void VIP_OnVIPLoaded()
{

    VIP_RegisterFeature(g_sFeatureName, BOOL, HIDE);
}


public void OnPluginEnd()
{
    if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
    {
        VIP_UnregisterFeature(g_sFeatureName);
    }
}

public void OnClientDisconnect(int client)
{
    g_sBackpack[client][0] = '\0';
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients)
    {
        g_sBackpack[client][0] = '\0';
    }
    return Plugin_Continue;
}

public Action Command_Swap(int client, int args)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return Plugin_Handled;
    }


    if (!VIP_IsClientVIP(client) || VIP_GetClientFeatureStatus(client, g_sFeatureName) == NO_ACCESS)
    {
        VIP_PrintToChatClient(client, "У вас нет доступа к \x04Виртуальному рюкзаку\x01.");
        return Plugin_Handled;
    }

    int primaryEnt = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
    bool hasPrimary = (primaryEnt != -1);
    bool hasBackpack = (g_sBackpack[client][0] != '\0');

    if (!hasPrimary && !hasBackpack)
    {
        VIP_PrintToChatClient(client, "У вас нет основного оружия, и ваш рюкзак пуст.");
        return Plugin_Handled;
    }

    char currentWep[32];
    char cleanWep[32]; 
    
    if (hasPrimary)
    {
        GetEdictClassname(primaryEnt, currentWep, sizeof(currentWep));
        

        strcopy(cleanWep, sizeof(cleanWep), currentWep);
        ReplaceString(cleanWep, sizeof(cleanWep), "weapon_", ""); 

        RemovePlayerItem(client, primaryEnt);
        AcceptEntityInput(primaryEnt, "Kill");
    }

    if (hasBackpack)
    {
        GivePlayerItem(client, g_sBackpack[client]);
        
        if (hasPrimary)
        {
            strcopy(g_sBackpack[client], sizeof(g_sBackpack[]), currentWep);
            VIP_PrintToChatClient(client, "Оружие изменено. В рюкзаке теперь: \x04%s", cleanWep);
        }
        else
        {
            g_sBackpack[client][0] = '\0';
            VIP_PrintToChatClient(client, "Вы достали оружие из рюкзака.");
        }
    }
    else if (hasPrimary)
    {
        strcopy(g_sBackpack[client], sizeof(g_sBackpack[]), currentWep);
        VIP_PrintToChatClient(client, "Оружие \x04%s\x01 убрано в рюкзак.", cleanWep);
    }

    return Plugin_Handled;
}