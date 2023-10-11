#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>
#define REQUIRE_PLUGIN 
#include <tf2attributes> // nosoop's Attributes ( https://github.com/nosoop/tf2attributes )
#include <tf2wearables> // use tf2 wearables API for getting weapon entity index ( https://github.com/nosoop/sourcemod-tf2wearables/ )

bool bIsMvMMap = false;

char botModels[][] =
{
	"models/bots/scout/bot_scout.mdl",
	"models/bots/sniper/bot_sniper.mdl",
	"models/bots/soldier/bot_soldier.mdl",
	"models/bots/demo/bot_demo.mdl",
	"models/bots/medic/bot_medic.mdl",
	"models/bots/heavy/bot_heavy.mdl",
	"models/bots/pyro/bot_pyro.mdl",
	"models/bots/spy/bot_spy.mdl",
	"models/bots/engineer/bot_engineer.mdl",
	"models/bots/scout_boss/bot_scout_boss.mdl",
	"models/bots/soldier_boss/bot_soldier_boss.mdl",
	"models/bots/demo_boss/bot_demo_boss.mdl",
	"models/bots/heavy_boss/bot_heavy_boss.mdl",
	"models/bots/pyro_boss/bot_pyro_boss.mdl"
};

public Plugin myinfo = 
{
	name = "[TF2] MvM Bot Upgrades",
	author = "pongo1231 (Original) + Pyri (Edited) + Anonymous Player/caxanga334 (Edited)",
	description = "Give bots on Red team upgrades for Mann Vs Machine.",
	version = "1.2.6",
	url = "N/A",
};

public void OnPluginStart() 
{
	//HookEvent("post_inventory_application", Event_PostInventory, EventHookMode_Post);
	HookEvent("mvm_begin_wave", Event_WaveStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void OnMapStart() 
{
	bIsMvMMap = GameRules_GetProp("m_bPlayingMannVsMachine") ? true : false;
}

/** 
* Apply attributes to bots when post_inventory_application event fires.
* This event is fired every time the client's loadout is reloading
* For example: when respawning, when changing classes, using a resupply locker, etc
**/
public Action Event_PostInventory(Event event, const char[] name, bool dontBroadcast)
{
	//Disabled for now, clients with robot models will still get attributes
	int client = GetClientOfUserId(event.GetInt("userid"));

	ApplyAttributesToClient(client);

	return Plugin_Continue;
}

/** 
* Reapply upgrades when the wave starts
**/
public Action Event_WaveStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
		ApplyAttributesToClient(i); // this function already validate clients

	return Plugin_Continue;
}

/** 
* Reapply upgrades when the player spawns with a delay
**/
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, Timer_PlayerSpawn, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_PlayerSpawn(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!client)
		return Plugin_Stop;

	ApplyAttributesToClient(client);

	return Plugin_Stop;
}

// Check to see if the Client's model is a robot model, if true, we will disable them from getting attributes.
stock bool IsRobot(int client)
{
	if (IsValidClientIndex(client) && IsPlayerAlive(client))
	{
		char model[PLATFORM_MAX_PATH]; GetClientModel(client, model, sizeof(model));
		
		for (int i = 0; i < sizeof(botModels); i++)
			if (StrEqual(model, botModels[i], true))
				return true;
		
		return false;
	}

	return false;
}

stock bool IsValidClientIndex(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;

	return false;
}

// This function will apply the attributes to the bots
void ApplyAttributesToClient(int client)
{
	// Checks if the client is In-Game
	if (!IsValidClientIndex(client))
		return;
		
	// If players should get attributes, comment this out.
	if (!IsFakeClient(client))
		return;

	if (IsRobot(client))
		return;

	// Checks if client is not on RED/MannCo team
	if (TF2_GetClientTeam(client) != TFTeam_Red)
		return;

	if (!bIsMvMMap)
		return;

	int Primary = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Primary, true);
	int Secondary = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary, true);
	int Melee = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Melee, true);

	// Weapon attributes gets erased when changing weapons, only clear attributes from clients
	TF2Attrib_RemoveAll(client);

	if (Melee != -1)
	{
		TF2Attrib_SetByName(Melee, "critboost on kill", 4.0);
		TF2Attrib_SetByName(Melee, "melee attack rate bonus", 0.6);
		TF2Attrib_SetByName(Melee, "heal on kill", 100.0);
		TF2Attrib_SetByName(Melee, "damage bonus", 1.3);
	}

	TF2Attrib_SetByName(client, "health regen", 2.0);
	TF2Attrib_SetByName(client, "move speed bonus", 1.3);
	TF2Attrib_SetByName(client, "increased jump height", 1.4);
	TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.25);
	TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.2);
	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.25);
	TF2Attrib_SetByName(client, "max health additive bonus", 25.0);
	TF2Attrib_SetByName(client, "ammo regen", 0.1);
	TF2Attrib_SetByName(client, "increase player capture value", 1.0); // For custom maps that allows recaptureable gates

	switch (TF2_GetPlayerClass(client)) 
	{
		case TFClass_Scout: 
		{
			if (Primary != -1)
			{
				TF2Attrib_SetByName(Primary, "damage bonus", 2.0);
				TF2Attrib_SetByName(Primary, "clip size bonus upgrade", 2.0);
				TF2Attrib_SetByName(Primary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Primary, "faster reload rate", 0.4);
				TF2Attrib_SetByName(Primary, "heal on kill", 25.0);
				TF2Attrib_SetByName(Primary, "maxammo primary increased", 2.5);
				TF2Attrib_SetByName(Primary, "projectile penetration", 1.0);
			}
			
			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "damage bonus", 1.25);
				TF2Attrib_SetByName(Secondary, "clip size bonus upgrade", 2.0);
				TF2Attrib_SetByName(Secondary, "maxammo secondary increased", 2.5);
				TF2Attrib_SetByName(Secondary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Secondary, "heal on kill", 100.0);
				TF2Attrib_SetByName(Secondary, "fire rate bonus", 0.6);
			}
		}
		case TFClass_Soldier: 
		{
			if (Primary != -1)
			{
				TF2Attrib_SetByName(Primary, "damage bonus", 2.0);
				TF2Attrib_SetByName(Primary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Primary, "faster reload rate", 0.4);
				TF2Attrib_SetByName(Primary, "heal on kill", 50.0);
				TF2Attrib_SetByName(Primary, "maxammo primary increased", 2.5);
				TF2Attrib_SetByName(Primary, "rocket specialist", 2.0);
				TF2Attrib_SetByName(Primary, "clip size upgrade atomic", 8.0);
				TF2Attrib_SetByName(Primary, "Projectile speed increased", 1.2);
			}

			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "damage bonus", 1.25);
				TF2Attrib_SetByName(Secondary, "clip size bonus upgrade", 2.0);
				TF2Attrib_SetByName(Secondary, "maxammo secondary increased", 2.5);
				TF2Attrib_SetByName(Secondary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Secondary, "heal on kill", 100.0);
				TF2Attrib_SetByName(Secondary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Secondary, "faster reload rate", 0.4);
			}
		}
		case TFClass_Pyro: 
		{
			if (Primary != -1)
			{
				TF2Attrib_SetByName(Primary, "damage bonus", 2.0);
				TF2Attrib_SetByName(Primary, "heal on kill", 50.0);
				TF2Attrib_SetByName(Primary, "maxammo primary increased", 2.5);
				TF2Attrib_SetByName(Primary, "airblast pushback scale", 1.5);
				TF2Attrib_SetByName(Primary, "mult airblast refire time", 0.8);
			}

			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "damage bonus", 1.25);
				TF2Attrib_SetByName(Secondary, "clip size bonus upgrade", 2.0);
				TF2Attrib_SetByName(Secondary, "maxammo secondary increased", 2.5);
				TF2Attrib_SetByName(Secondary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Secondary, "heal on kill", 100.0);
				TF2Attrib_SetByName(Secondary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Secondary, "faster reload rate", 0.4);
			}
		}
		case TFClass_DemoMan: 
		{
			if(Primary != -1)
			{
				TF2Attrib_SetByName(Primary, "damage bonus", 1.8);
				TF2Attrib_SetByName(Primary, "heal on kill", 50.0);
				TF2Attrib_SetByName(Primary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Primary, "faster reload rate", 0.4);
				TF2Attrib_SetByName(Primary, "maxammo primary increased", 2.5);
				TF2Attrib_SetByName(Primary, "clip size upgrade atomic", 8.0);

				//AI will overshoot their pills if PSI is over 10%
				//Don't go over it.
				TF2Attrib_SetByName(Primary, "Projectile speed increased", 1.1);
			}

			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "max pipebombs increased", 4.0);
				TF2Attrib_SetByName(Secondary, "damage bonus", 2.0);
				TF2Attrib_SetByName(Secondary, "clip size bonus upgrade", 2.0);
				TF2Attrib_SetByName(Secondary, "maxammo secondary increased", 2.5);
				TF2Attrib_SetByName(Secondary, "heal on kill", 100.0);
				TF2Attrib_SetByName(Secondary, "fire rate bonus", 0.7);
				TF2Attrib_SetByName(Secondary, "faster reload rate", 0.4);
			}
		}
		case TFClass_Heavy: 
		{
			if (Primary != -1)
			{
				TF2Attrib_SetByName(Primary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Primary, "heal on kill", 50.0);
				TF2Attrib_SetByName(Primary, "maxammo primary increased", 2.5);
				TF2Attrib_SetByName(Primary, "attack projectiles", 2.0);
				TF2Attrib_SetByName(Primary, "projectile penetration heavy", 2.0);
				TF2Attrib_SetByName(Primary, "minigun spinup time decreased", 0.8);
			}

			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "damage bonus", 1.25);
				TF2Attrib_SetByName(Secondary, "clip size bonus upgrade", 2.0);
				TF2Attrib_SetByName(Secondary, "maxammo secondary increased", 2.5);
				TF2Attrib_SetByName(Secondary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Secondary, "heal on kill", 100.0);
				TF2Attrib_SetByName(Secondary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Secondary, "faster reload rate", 0.4);
			}
		}
		case TFClass_Engineer: 
		{
			int iPDA = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Unknown2, true);
			TF2Attrib_SetByName(client, "metal regen", 30.0);
			
			if (Primary != -1)
			{
				//Valve should've gave the Shotgun a dmg bonus
				TF2Attrib_SetByName(Primary, "damage bonus", 1.5);
				TF2Attrib_SetByName(Primary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Primary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Primary, "faster reload rate", 0.4);
				TF2Attrib_SetByName(Primary, "heal on kill", 50.0);
				TF2Attrib_SetByName(Primary, "clip size bonus upgrade", 2.0);
				TF2Attrib_SetByName(Primary, "maxammo primary increased", 2.5);
			}

			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "damage bonus", 1.25);
				TF2Attrib_SetByName(Secondary, "clip size bonus upgrade", 2.0);
				TF2Attrib_SetByName(Secondary, "maxammo secondary increased", 2.5);
				TF2Attrib_SetByName(Secondary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Secondary, "heal on kill", 100.0);
				TF2Attrib_SetByName(Secondary, "fire rate bonus", 0.6);
			}

			if (iPDA != -1)
			{
				TF2Attrib_SetByName(iPDA, "engy sentry fire rate increased", 0.7);
				TF2Attrib_SetByName(iPDA, "engy building health bonus", 4.0);
				TF2Attrib_SetByName(iPDA, "engineer sentry build rate multiplier", 1.2);
				TF2Attrib_SetByName(iPDA, "engy dispenser radius increased", 4.0);
				TF2Attrib_SetByName(iPDA, "maxammo metal increased", 3.0);
				TF2Attrib_SetByName(iPDA, "bidirectional teleport", 1.0);
			}
		}
		case TFClass_Medic: 
		{
			if (Primary != -1)
			{
				TF2Attrib_SetByName(Primary, "damage bonus", 1.25);
				TF2Attrib_SetByName(Primary, "clip size bonus upgrade", 3.0);
				TF2Attrib_SetByName(Primary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Primary, "faster reload rate", 0.4);
				TF2Attrib_SetByName(Primary, "heal on kill", 50.0);
				TF2Attrib_SetByName(Primary, "maxammo primary increased", 2.5);
				TF2Attrib_SetByName(Primary, "mad milk syringes", 1.0);
			}

			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "generate rage on heal", 2.0);		
				TF2Attrib_SetByName(Secondary, "increase buff duration", 1.25);	
				TF2Attrib_SetByName(Secondary, "ubercharge rate bonus", 2.0);
				TF2Attrib_SetByName(Secondary, "heal rate bonus", 1.5);
				TF2Attrib_SetByName(Secondary, "overheal expert", 3.0);
				TF2Attrib_SetByName(Secondary, "healing mastery", 3.0);
				TF2Attrib_SetByName(Secondary, "uber duration bonus", 4.0);
			}
		}
		case TFClass_Sniper: 
		{
			if (Primary != -1)
			{
				TF2Attrib_SetByName(Primary, "damage bonus", 1.75);
				TF2Attrib_SetByName(Primary, "heal on kill", 50.0);
				TF2Attrib_SetByName(Primary, "maxammo primary increased", 2.5);
				TF2Attrib_SetByName(Primary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Primary, "faster reload rate", 0.4);
				TF2Attrib_SetByName(Primary, "explosive sniper shot", 3.0);
				TF2Attrib_SetByName(Primary, "SRifle Charge rate increased", 1.5);
			}

			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "damage bonus", 1.25);
				TF2Attrib_SetByName(Secondary, "maxammo secondary increased", 2.5);
				TF2Attrib_SetByName(Secondary, "clip size bonus upgrade", 3.0);
				TF2Attrib_SetByName(Secondary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Secondary, "heal on kill", 100.0);
				TF2Attrib_SetByName(Secondary, "fire rate bonus", 0.6);
			}
		}
		case TFClass_Spy: 
		{
			int iSapper = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Building, true);
			TF2Attrib_SetByName(client, "cloak consume rate decreased", 0.3);
			TF2Attrib_SetByName(Melee, "armor piercing", 100.0);

			/**
			* Notes about TF2 spy:
			* The primary slot (slot 0) is EMPTY!
			* The revolver is a secondary weapon.
			**/
			if (Secondary != -1)
			{
				TF2Attrib_SetByName(Secondary, "damage bonus", 1.25);
				TF2Attrib_SetByName(Secondary, "fire rate bonus", 0.6);
				TF2Attrib_SetByName(Secondary, "projectile penetration", 1.0);
				TF2Attrib_SetByName(Secondary, "heal on kill", 50.0);
				TF2Attrib_SetByName(Secondary, "maxammo secondary increased", 2.5);
				TF2Attrib_SetByName(Secondary, "clip size bonus upgrade", 2.0);
			}

			if (iSapper != -1)
			{
				TF2Attrib_SetByName(iSapper, "robo sapper", 3.0);
				TF2Attrib_SetByName(iSapper, "effect bar recharge rate increased", 0.6);
			}
		}
	}

	// While it's somewhat better, it could still be polished
	// by not having some of the secondary attributes be applied
	// i.e, having Mad Milk get the Damage bonus and others from
	// the scout's secondary attributes being applied

	char weapons[10][64] = 
	{
		"TF_WEAPON_PARTICLE_CANNON", 
		"TF_WEAPON_CANNON", 
		"TF_WEAPON_COMPOUND_BOW", 
		"TF_WEAPON_LUNCHBOX_DRINK", 
		"TF_WEAPON_BUFF_ITEM", 
		"TF_WEAPON_JAR", 
		"TF_WEAPON_JAR_MILK", 
		"TF_WEAPON_JAR_GAS", 
		"TF_WEARABLE_DEMOSHIELD", 
		"TF_WEAPON_BAT_WOOD"
	};

	for (int i = 0; i < 10; i++)
	{
		int weapon = -1;
		while ((weapon = FindEntityByClassname(weapon, weapons[i])) != -1)
		{
			if (client == GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity"))
			{
				if (StrEqual(weapons[i], "TF_WEAPON_PARTICLE_CANNON"))
				{
					TF2Attrib_SetByName(weapon, "Set DamageType Ignite", 1.0);
					TF2Attrib_SetByName(weapon, "clip size bonus upgrade", 3.0);
				}
				else if (StrEqual(weapons[i], "TF_WEAPON_CANNON"))
				{
					// Bots need this, or they cannot fire it
					// Players don't.
					if (IsFakeClient(client))
						TF2Attrib_SetByName(weapon, "grenade launcher mortar mode", 0.0);
				}
				else if (StrEqual(weapons[i], "TF_WEAPON_COMPOUND_BOW"))
				{
					TF2Attrib_SetByName(weapon, "bleeding duration", 5.0);
				}
				else if (StrEqual(weapons[i], "TF_WEAPON_LUNCHBOX_DRINK"))
				{
					TF2Attrib_SetByName(weapon, "effect bar recharge rate increased", 0.3);
				}
				else if (StrEqual(weapons[i], "TF_WEAPON_BUFF_ITEM"))
				{
					TF2Attrib_SetByName(weapon, "increase buff duration", 1.5);
				}
				else if (StrEqual(weapons[i], "TF_WEAPON_JAR"))
				{
					TF2Attrib_SetByName(weapon, "effect bar recharge rate increased", 0.4);
					TF2Attrib_SetByName(weapon, "applies snare effect", 0.65);
				}
				else if (StrEqual(weapons[i], "TF_WEAPON_JAR_MILK"))
				{
					TF2Attrib_SetByName(weapon, "effect bar recharge rate increased", 0.4);
					TF2Attrib_SetByName(weapon, "applies snare effect", 0.65);
				}
				else if (StrEqual(weapons[i], "TF_WEAPON_JAR_GAS"))
				{
					TF2Attrib_SetByName(weapon, "mult_item_meter_charge_rate", 0.2);
					TF2Attrib_SetByName(weapon, "weapon burn dmg increased", 4.0);
				}
				else if (StrEqual(weapons[i], "TF_WEARABLE_DEMOSHIELD"))
				{
					TF2Attrib_SetByName(weapon, "damage force reduction", 0.2);
					TF2Attrib_SetByName(weapon, "charge recharge rate increased", 5.0);
				}
				else if (StrEqual(weapons[i], "TF_WEAPON_BAT_WOOD"))
				{
					TF2Attrib_SetByName(weapon, "effect bar recharge rate increased", 0.2);
					TF2Attrib_SetByName(weapon, "mark for death", 1.0);
				}
			}
		}
	}
}