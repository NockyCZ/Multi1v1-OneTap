#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multi1v1>
#include <colors_csgo>

#pragma semicolon 1
#pragma newdecls required

bool g_Onetap[MAXPLAYERS + 1] = false;
char rifleweapon[WEAPON_NAME_LENGTH];

public Plugin myinfo = 
{
	name = "[CS:GO Multi 1v1] OneTap round addon", 
	author = "Nocky", 
	description = "Adds an onetap round-type", 
	version = "1.0", 
	url = "https://github.com/nockycz"
};

public void OnPluginStart()
{
	LoadTranslations("multi1v1-onetap.phrases");
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
}

public void Multi1v1_OnRoundTypesAdded()
{
	Multi1v1_AddRoundType("OneTap", "onetap", OnetapHandler, true, false, "", true);
}

public void OnetapHandler(int client)
{
	Multi1v1_GetRifleChoice(client, rifleweapon);
	GivePlayerItem(client, rifleweapon);
	
	g_Onetap[client] = true;
	
	PrintHintText(client, "%t", "OneTapRound");
	CPrintToChat(client, "%t", "OneTapRoundChat");
}

public Action Event_WeaponFire(Event event, const char[] name, bool dbc)
{
	char weapon[64];
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client))
	{
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		if (!(StrContains(weapon, "weapon_knife", false) != -1))
		{
			if (g_Onetap[client])
			{
				CreateTimer(0.1, OneShotTimer, client);
			}
		}
	}
	return Plugin_Continue;
}

public Action OneShotTimer(Handle timer, int client)
{
	StripWeapon(client);
	GiveWeapon(client);
}

void GiveWeapon(int client)
{
	Multi1v1_GetRifleChoice(client, rifleweapon);
	GivePlayerItem(client, rifleweapon);
	
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	SetAmmo(client, weapon, 1);
}

void SetAmmo(int client, int weapon, int ammo)
{
	if (IsValidEntity(weapon))
	{
		SetReserveAmmo(client, weapon, 0);
		SetClipAmmo(client, weapon, ammo);
	}
}

stock int SetReserveAmmo(int client, char weapon, int ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
	
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype == -1)
		return;
	SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}


stock int SetClipAmmo(int client, char weapon, int ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
	SetEntProp(weapon, Prop_Send, "m_iClip2", ammo);
}

void StripWeapon(int client)
{
	int weapon = -1;
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		weapon = -1;
		for (int slot = 5; slot >= 0; slot--)
		{
			while ((weapon = GetPlayerWeaponSlot(client, slot)) != -1)
			{
				if (IsValidEntity(weapon))
				{
					RemovePlayerItem(client, weapon);
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon, int & subtype, int & cmdnum, int & tickcount, int & seed, int mouse[2])
{
	if (!IsPlayerAlive(client) || !g_Onetap[client])
	{
		return Plugin_Continue;
	}
	if (g_Onetap[client])
	{
		if (buttons & IN_RELOAD)
		{
			PrintHintText(client, "%t", "ReloadDisabled");
			buttons &= ~IN_RELOAD;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if (g_Onetap[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			g_Onetap[client] = false;
		}
	}
}

bool IsValidClient(int client, bool botz = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsClientConnected(client) || botz && IsFakeClient(client) || IsClientSourceTV(client))
		return false;
	
	return true;
} 