#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>
#define REQUIRE_PLUGIN 
#include <tf2attributes> // nosoop's Attributes ( https://github.com/nosoop/tf2attributes )
#include <tf2wearables> // use tf2 wearables API for getting weapon entity index ( https://github.com/nosoop/sourcemod-tf2wearables/ )
//#include <tf2utils>

#define TF_SPECIAL_ATTRIB_WEAPONS 10
#define TF_SENTRYGUN_AMMO_150 150
#define TF_SENTRYGUN_AMMO_200 200
#define TF_SENTRYGUN_AMMO_ROCKETS 20

ConVar tf_mvm_sentry_infammo;
ConVar tf_mvm_sentry_infammo_player;
ConVar tf_mvm_upgrades_player;

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

char weapons[ TF_SPECIAL_ATTRIB_WEAPONS ][ 64 ] = 
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

char attributes[ 10 ][ 2 ][ 64 ] =
{
	{ "Set DamageType Ignite", "clip size bonus upgrade" },                // TF_WEAPON_PARTICLE_CANNON
	{ "grenade launcher mortar mode", "" },                                // TF_WEAPON_CANNON
	{ "bleeding duration", "" },                                           // TF_WEAPON_COMPOUND_BOW
	{ "effect bar recharge rate increased", "" },                          // TF_WEAPON_LUNCHBOX_DRINK
	{ "increase buff duration", "" },                                      // TF_WEAPON_BUFF_ITEM
	{ "effect bar recharge rate increased", "applies snare effect" },      // TF_WEAPON_JAR
	{ "effect bar recharge rate increased", "applies snare effect" },      // TF_WEAPON_JAR_MILK
	{ "mult_item_meter_charge_rate", "weapon burn dmg increased" },        // TF_WEAPON_JAR_GAS
	{ "damage force reduction", "charge recharge rate increased" },        // TF_WEARABLE_DEMOSHIELD
	{ "effect bar recharge rate increased", "mark for death" }             // TF_WEAPON_BAT_WOOD
};

float attributeValues[ 10 ][ 2 ] =
{
	{ 1.0, 3.0 },    // TF_WEAPON_PARTICLE_CANNON
	{ 0.0 },         // TF_WEAPON_CANNON
	{ 5.0 },         // TF_WEAPON_COMPOUND_BOW
	{ 0.3 },         // TF_WEAPON_LUNCHBOX_DRINK
	{ 1.5 },         // TF_WEAPON_BUFF_ITEM
	{ 0.4, 0.65 },   // TF_WEAPON_JAR
	{ 0.4, 0.65 },   // TF_WEAPON_JAR_MILK
	{ 0.2, 4.0 },    // TF_WEAPON_JAR_GAS
	{ 0.2, 5.0 },    // TF_WEARABLE_DEMOSHIELD
	{ 0.2, 1.0 }     // TF_WEAPON_BAT_WOOD
};

int numAttributes[ 10 ] = 
{
	2,               // TF_WEAPON_PARTICLE_CANNON
	1,               // TF_WEAPON_CANNON
	1,               // TF_WEAPON_COMPOUND_BOW
	1,               // TF_WEAPON_LUNCHBOX_DRINK
	1,               // TF_WEAPON_BUFF_ITEM
	2,               // TF_WEAPON_JAR
	2,               // TF_WEAPON_JAR_MILK
	2,               // TF_WEAPON_JAR_GAS
	2,               // TF_WEARABLE_DEMOSHIELD
	2                // TF_WEAPON_BAT_WOOD
};

public Plugin myinfo = 
{
	name = "[TF2] MvM Bot Upgrades",
	author = "pongo1231 (Original) + Pyri (Edited) + Anonymous Player/caxanga334 (Edited)",
	description = "Give bots on Red team upgrades for Mann Vs Machine.",
	version = "1.2.7",
	url = "N/A",
};

public void OnPluginStart() 
{
	//Come up with better ConVar names....
	tf_mvm_sentry_infammo = CreateConVar( "sm_tf_mvm_sentry_infammo", "1", "Should we enable Infinite Ammo for BOT/Player Engineer Sentryguns?", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	tf_mvm_sentry_infammo_player = CreateConVar( "sm_tf_mvm_sentry_infammo_player", "1", "Should Player Engineers be affected with Infinite Ammo?", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	tf_mvm_upgrades_player = CreateConVar( "sm_tf_tf_mvm_upgrades_playerr", "1", "Should Players get upgrades as well?", FCVAR_NOTIFY, true, 0.0, true, 1.0 );

	//HookEvent( "post_inventory_application", Event_PostInventory, EventHookMode_Post );
	HookEvent( "mvm_begin_wave", Event_WaveStart, EventHookMode_Post );
	HookEvent( "player_spawn", Event_PlayerSpawn, EventHookMode_Post );
}

public void OnMapStart() 
{
	bIsMvMMap = GameRules_GetProp( "m_bPlayingMannVsMachine" ) ? true : false;
}

public Action OnPlayerRunCmd( int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2] )
{
	// Checks if the client is In-Game
	if (!IsValidClientIndex( client ) || !IsPlayerAlive( client ) || IsRobot( client ) || TF2_GetClientTeam( client ) != TFTeam_Red || !bIsMvMMap)
		return Plugin_Continue;

	if ( tf_mvm_sentry_infammo.BoolValue )
		if (TF2_GetPlayerClass( client ) == TFClass_Engineer && ( IsFakeClient( client ) || tf_mvm_sentry_infammo_player.BoolValue ) )
			InfiniteSentryAmmo( client );

	return Plugin_Continue;
}


/** 
* Apply attributes to bots when post_inventory_application event fires.
* This event is fired every time the client's loadout is reloading
* For example: when respawning, when changing classes, using a resupply locker, etc
**/
public Action Event_PostInventory( Event event, const char[] name, bool dontBroadcast )
{
	//Disabled for now, clients with robot models will still get attributes
	int client = GetClientOfUserId( event.GetInt("userid" ) );

	ApplyAttributesToClient( client );

	return Plugin_Continue;
}

/** 
* Reapply upgrades when the wave starts
**/
public Action Event_WaveStart( Event event, const char[] name, bool dontBroadcast )
{
	for( int i = 1; i <= MaxClients; i++ )
		ApplyAttributesToClient( i ); // this function already validate clients

	return Plugin_Continue;
}

/** 
* Reapply upgrades when the player spawns with a delay
**/
public Action Event_PlayerSpawn( Event event, const char[] name, bool dontBroadcast )
{
	CreateTimer(1.0, Timer_PlayerSpawn, event.GetInt( "userid" ), TIMER_FLAG_NO_MAPCHANGE );
	return Plugin_Continue;
}

public Action Timer_PlayerSpawn( Handle timer, int userid )
{
	int client = GetClientOfUserId( userid );

	if ( !client )
		return Plugin_Stop;

	ApplyAttributesToClient( client );

	return Plugin_Stop;
}

// Check to see if the Client's model is a robot model, if true, we will disable them from getting attributes.
stock bool IsRobot( int client )
{
	if (IsValidClientIndex( client ) && IsPlayerAlive( client ) )
	{
		char model[PLATFORM_MAX_PATH]; GetClientModel( client, model, sizeof( model ) );
		
		for ( int i = 0; i < sizeof( botModels ); i++ )
			if ( StrEqual( model, botModels[ i ], true ) )
				return true;
		
		return false;
	}

	return false;
}

stock bool IsValidClientIndex( int client )
{
	if ( client > 0 && client <= MaxClients && IsClientInGame( client ) )
		return true;

	return false;
}

stock void InfiniteSentryAmmo( int client )
{
	if ( !IsValidClientIndex( client ) )
		return;

	int sentrygun = -1;
	while ( ( sentrygun = FindEntityByClassname( sentrygun, "obj_sentrygun" ) ) != -1 )
	{
		if( !IsValidEntity( sentrygun ) || client != GetEntPropEnt( sentrygun, Prop_Send, "m_hBuilder" ) )
			continue;

		int isMini = GetEntProp( sentrygun, Prop_Send, "m_bMiniBuilding" );
		int upgradeLevel = GetEntProp( sentrygun, Prop_Send, "m_iUpgradeLevel" );

		if( isMini )
			SetEntProp( sentrygun, Prop_Send, "m_iAmmoShells", TF_SENTRYGUN_AMMO_150 );

		else //not a mini
		{
			switch (upgradeLevel)
			{
				case 1: SetEntProp( sentrygun, Prop_Send, "m_iAmmoShells", TF_SENTRYGUN_AMMO_150 );
				case 2:	SetEntProp( sentrygun, Prop_Send, "m_iAmmoShells", TF_SENTRYGUN_AMMO_200 );
				case 3:
				{
					SetEntProp( sentrygun, Prop_Send, "m_iAmmoShells", TF_SENTRYGUN_AMMO_200 );
					SetEntProp( sentrygun, Prop_Send, "m_iAmmoRockets", TF_SENTRYGUN_AMMO_ROCKETS );
				}
			}
		}
	}
}

// This function will apply the attributes to the bots
void ApplyAttributesToClient( int client )
{
	// Checks if the client is In-Game
	if (!IsValidClientIndex( client ) || IsRobot( client ) || TF2_GetClientTeam( client ) != TFTeam_Red || !bIsMvMMap )
		return;

	int iPrimary = TF2_GetPlayerLoadoutSlot( client, TF2LoadoutSlot_Primary, true );
	int iSecondary = TF2_GetPlayerLoadoutSlot( client, TF2LoadoutSlot_Secondary, true );
	int iMelee = TF2_GetPlayerLoadoutSlot( client, TF2LoadoutSlot_Melee, true);
	int iPDA = TF2_GetPlayerLoadoutSlot( client, TF2LoadoutSlot_Unknown2 );
	int iSapper = TF2_GetPlayerLoadoutSlot( client, TF2LoadoutSlot_Building );

	if ( IsFakeClient( client ) || ( tf_mvm_upgrades_player.BoolValue ) )
	{
		// Weapon attributes gets erased when changing weapons, only clear attributes from clients
		TF2Attrib_RemoveAll( client );

		if ( iMelee != -1 )
		{
			TF2Attrib_SetByName( iMelee, "critboost on kill", 4.0 );
			TF2Attrib_SetByName( iMelee, "melee attack rate bonus", 0.6 );
			TF2Attrib_SetByName( iMelee, "heal on kill", 100.0 );
			TF2Attrib_SetByName( iMelee, "damage bonus", 1.3 );
		}

		TF2Attrib_SetByName( client, "health regen", 2.0 );
		TF2Attrib_SetByName( client, "move speed bonus", 1.3 );
		TF2Attrib_SetByName( client, "increased jump height", 1.4 );
		TF2Attrib_SetByName( client, "dmg taken from bullets reduced", 0.25 );
		TF2Attrib_SetByName( client, "dmg taken from fire reduced", 0.5 );
		TF2Attrib_SetByName( client, "dmg taken from crit reduced", 0.2 );
		TF2Attrib_SetByName( client, "dmg taken from blast reduced", 0.25 );
		TF2Attrib_SetByName( client, "max health additive bonus", 25.0 );
		TF2Attrib_SetByName( client, "ammo regen", 0.1 );
		TF2Attrib_SetByName( client, "increase player capture value", 1.0 ); // For custom maps that allows recaptureable gates

		switch (TF2_GetPlayerClass(client)) 
		{
			case TFClass_Scout: 
			{
				if ( iPrimary != -1 )
				{
					TF2Attrib_SetByName( iPrimary, "damage bonus", 2.0 );
					TF2Attrib_SetByName( iPrimary, "clip size bonus upgrade", 2.0 );
					TF2Attrib_SetByName( iPrimary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iPrimary, "faster reload rate", 0.4 );
					TF2Attrib_SetByName( iPrimary, "heal on kill", 25.0 );
					TF2Attrib_SetByName( iPrimary, "maxammo primary increased", 2.5 );
					TF2Attrib_SetByName( iPrimary, "projectile penetration", 1.0 );
				}
				
				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "damage bonus", 1.25 );
					TF2Attrib_SetByName( iSecondary, "clip size bonus upgrade", 2.0 );
					TF2Attrib_SetByName( iSecondary, "maxammo secondary increased", 2.5 );
					TF2Attrib_SetByName( iSecondary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iSecondary, "heal on kill", 100.0 );
					TF2Attrib_SetByName( iSecondary, "fire rate bonus", 0.6 );
				}
			}
			case TFClass_Soldier: 
			{
				if ( iPrimary != -1 )
				{
					TF2Attrib_SetByName( iPrimary, "damage bonus", 2.0 );
					TF2Attrib_SetByName( iPrimary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iPrimary, "faster reload rate", 0.4 );
					TF2Attrib_SetByName( iPrimary, "heal on kill", 50.0 );
					TF2Attrib_SetByName( iPrimary, "maxammo primary increased", 2.5 );
					TF2Attrib_SetByName( iPrimary, "rocket specialist", 2.0 );
					TF2Attrib_SetByName( iPrimary, "clip size upgrade atomic", 8.0 );
					TF2Attrib_SetByName( iPrimary, "Projectile speed increased", 1.2 );
				}

				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "damage bonus", 1.25 );
					TF2Attrib_SetByName( iSecondary, "clip size bonus upgrade", 2.0 );
					TF2Attrib_SetByName( iSecondary, "maxammo secondary increased", 2.5 );
					TF2Attrib_SetByName( iSecondary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iSecondary, "heal on kill", 100.0 );
					TF2Attrib_SetByName( iSecondary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iSecondary, "faster reload rate", 0.4 );
				}
			}
			case TFClass_Pyro: 
			{
				if ( iPrimary != -1 )
				{
					TF2Attrib_SetByName( iPrimary, "damage bonus", 2.0 );
					TF2Attrib_SetByName( iPrimary, "heal on kill", 50.0 );
					TF2Attrib_SetByName( iPrimary, "maxammo primary increased", 2.5 );
					TF2Attrib_SetByName( iPrimary, "airblast pushback scale", 1.5 );
					TF2Attrib_SetByName( iPrimary, "mult airblast refire time", 0.8 );
				}

				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "damage bonus", 1.25 );
					TF2Attrib_SetByName( iSecondary, "clip size bonus upgrade", 2.0 );
					TF2Attrib_SetByName( iSecondary, "maxammo secondary increased", 2.5 );
					TF2Attrib_SetByName( iSecondary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iSecondary, "heal on kill", 100.0 );
					TF2Attrib_SetByName( iSecondary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iSecondary, "faster reload rate", 0.4 );
				}
			}
			case TFClass_DemoMan: 
			{
				if ( iPrimary != -1 )
				{
					TF2Attrib_SetByName( iPrimary, "damage bonus", 1.8 );
					TF2Attrib_SetByName( iPrimary, "heal on kill", 50.0 );
					TF2Attrib_SetByName( iPrimary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iPrimary, "faster reload rate", 0.4 );
					TF2Attrib_SetByName( iPrimary, "maxammo primary increased", 2.5 );
					TF2Attrib_SetByName( iPrimary, "clip size upgrade atomic", 8.0 );
					//AI will overshoot their pills if PSI is over 10%
					TF2Attrib_SetByName( iPrimary, "Projectile speed increased", 1.1 );
				}

				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "max pipebombs increased", 4.0 );
					TF2Attrib_SetByName( iSecondary, "damage bonus", 2.0 );
					TF2Attrib_SetByName( iSecondary, "clip size bonus upgrade", 2.0 );
					TF2Attrib_SetByName( iSecondary, "maxammo secondary increased", 2.5 );
					TF2Attrib_SetByName( iSecondary, "heal on kill", 100.0 );
					TF2Attrib_SetByName( iSecondary, "fire rate bonus", 0.7 );
					TF2Attrib_SetByName( iSecondary, "faster reload rate", 0.4 );
				}	
			}
			case TFClass_Heavy: 
			{
				if ( iPrimary != -1 )
				{
					TF2Attrib_SetByName( iPrimary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iPrimary, "heal on kill", 50.0 );
					TF2Attrib_SetByName( iPrimary, "maxammo primary increased", 2.5 );
					TF2Attrib_SetByName( iPrimary, "attack projectiles", 2.0 );
					TF2Attrib_SetByName( iPrimary, "projectile penetration heavy", 2.0 );
					TF2Attrib_SetByName( iPrimary, "minigun spinup time decreased", 0.8 );
				}

				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "damage bonus", 1.25 );
					TF2Attrib_SetByName( iSecondary, "clip size bonus upgrade", 2.0 );
					TF2Attrib_SetByName( iSecondary, "maxammo secondary increased", 2.5 );
					TF2Attrib_SetByName( iSecondary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iSecondary, "heal on kill", 100.0 );
					TF2Attrib_SetByName( iSecondary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iSecondary, "faster reload rate", 0.4 );
				}
			}
			case TFClass_Engineer: 
			{
				TF2Attrib_SetByName( client, "metal regen", 30.0 );
				
				if ( iPrimary != -1 )
				{
					TF2Attrib_SetByName( iPrimary, "damage bonus", 1.5 );
					TF2Attrib_SetByName( iPrimary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iPrimary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iPrimary, "faster reload rate", 0.4 );
					TF2Attrib_SetByName( iPrimary, "heal on kill", 50.0 );
					TF2Attrib_SetByName( iPrimary, "clip size bonus upgrade", 2.0 );
					TF2Attrib_SetByName( iPrimary, "maxammo primary increased", 2.5 );
				}

				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "damage bonus", 1.25 );
					TF2Attrib_SetByName( iSecondary, "clip size bonus upgrade", 2.0 );
					TF2Attrib_SetByName( iSecondary, "maxammo secondary increased", 2.5 );
					TF2Attrib_SetByName( iSecondary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iSecondary, "heal on kill", 100.0 );
					TF2Attrib_SetByName( iSecondary, "fire rate bonus", 0.6 );
				}

				if ( iPDA != -1 )
				{
					TF2Attrib_SetByName( iPDA, "engy sentry fire rate increased", 0.7 );
					TF2Attrib_SetByName( iPDA, "engy building health bonus", 4.0 );
					TF2Attrib_SetByName( iPDA, "engineer sentry build rate multiplier", 1.2 );
					TF2Attrib_SetByName( iPDA, "engy dispenser radius increased", 4.0 );
					TF2Attrib_SetByName( iPDA, "maxammo metal increased", 3.0 );
					TF2Attrib_SetByName( iPDA, "bidirectional teleport", 1.0 );
				}
			}
			case TFClass_Medic: 
			{
				if ( iPrimary != -1 )
				{
					TF2Attrib_SetByName( iPrimary, "damage bonus", 1.25 );
					TF2Attrib_SetByName( iPrimary, "clip size bonus upgrade", 3.0 );
					TF2Attrib_SetByName( iPrimary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iPrimary, "faster reload rate", 0.4 );
					TF2Attrib_SetByName( iPrimary, "heal on kill", 50.0 );
					TF2Attrib_SetByName( iPrimary, "maxammo primary increased", 2.5 );
					TF2Attrib_SetByName( iPrimary, "mad milk syringes", 1.0 );
				}

				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "generate rage on heal", 2.0 );		
					TF2Attrib_SetByName( iSecondary, "increase buff duration", 1.25 );	
					TF2Attrib_SetByName( iSecondary, "ubercharge rate bonus", 2.0 );
					TF2Attrib_SetByName( iSecondary, "heal rate bonus", 1.5 );
					TF2Attrib_SetByName( iSecondary, "overheal expert", 3.0 );
					TF2Attrib_SetByName( iSecondary, "healing mastery", 3.0 );
					TF2Attrib_SetByName( iSecondary, "uber duration bonus", 4.0 );
				}
			}
			case TFClass_Sniper: 
			{
				if ( iPrimary != -1 )
				{
					TF2Attrib_SetByName( iPrimary, "damage bonus", 1.75 );
					TF2Attrib_SetByName( iPrimary, "heal on kill", 50.0 );
					TF2Attrib_SetByName( iPrimary, "maxammo primary increased", 2.5 );
					TF2Attrib_SetByName( iPrimary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iPrimary, "faster reload rate", 0.4 );
					TF2Attrib_SetByName( iPrimary, "explosive sniper shot", 3.0 );
					TF2Attrib_SetByName( iPrimary, "SRifle Charge rate increased", 1.5 );
				}

				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "damage bonus", 1.25 );
					TF2Attrib_SetByName( iSecondary, "maxammo secondary increased", 2.5 );
					TF2Attrib_SetByName( iSecondary, "clip size bonus upgrade", 3.0 );
					TF2Attrib_SetByName( iSecondary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iSecondary, "heal on kill", 100.0 );
					TF2Attrib_SetByName( iSecondary, "fire rate bonus", 0.6 );
				}
			}
			case TFClass_Spy: 
			{
				TF2Attrib_SetByName( client, "cloak consume rate decreased", 0.3 );
				TF2Attrib_SetByName( iMelee, "armor piercing", 100.0 );

				/**
				* Notes about TF2 spy:
				* The Primary slot (slot 0) is EMPTY!
				* The revolver is a iSecondary weapon.
				**/
				if ( iSecondary != -1 )
				{
					TF2Attrib_SetByName( iSecondary, "damage bonus", 1.25 );
					TF2Attrib_SetByName( iSecondary, "fire rate bonus", 0.6 );
					TF2Attrib_SetByName( iSecondary, "projectile penetration", 1.0 );
					TF2Attrib_SetByName( iSecondary, "heal on kill", 50.0 );
					TF2Attrib_SetByName( iSecondary, "maxammo secondary increased", 2.5 );
					TF2Attrib_SetByName( iSecondary, "clip size bonus upgrade", 2.0 );
				}

				if ( iSapper != -1 )
				{
					TF2Attrib_SetByName( iSapper, "robo sapper", 3.0 );
					TF2Attrib_SetByName( iSapper, "effect bar recharge rate increased", 0.6 );
				}
			}
		}

		for (int i = 0; i < TF_SPECIAL_ATTRIB_WEAPONS; i++) 
		{
			int iWeapon = -1;
			while ( ( iWeapon = FindEntityByClassname( iWeapon, weapons[ i ] ) ) != -1 ) 
			{
				if ( client == GetEntPropEnt( iWeapon, Prop_Data, "m_hOwnerEntity" ) ) 
				{
					for ( int j = 0; j < numAttributes[ i ]; j++ )
					{
						// Skip if the attribute is an empty string or if the client is not a fake client and the attribute is "grenade launcher mortar mode"
						if ( StrEqual( attributes[ i ][ j ], "") || ( StrEqual( attributes[ i ][ j ], "grenade launcher mortar mode" ) && !IsFakeClient( client )) )
							continue;
							
						TF2Attrib_SetByName( iWeapon, attributes[ i ][ j ], attributeValues[ i ][ j ] );
					}
				}
			}
		}
	}
}