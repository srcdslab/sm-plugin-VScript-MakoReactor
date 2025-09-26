#include <cstrike>
#include <multicolors>
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#undef REQUIRE_PLUGIN
#include <zombiereloaded>
#define REQUIRE_PLUGIN

int g_iModelIndex;

bool g_bValidMap;
bool g_bRaceEnabled;
bool g_bRaceAutoBhop;
bool g_bRaceBlockInfect;
bool g_bRaceBlockRespawn;

public Plugin myinfo =
{
	name        = "VScript_ze_ffvii_mako_reactor_v5_3",
	author	    = "Neon, maxime1907, .Rushaway, Zombieden, zaCade",
	description = "VScript related to the Stripper + MakoVote",
	version     = "2.1.0",
	url         = "https://github.com/Rushaway/sm-plugin-VScript-MakoReactor"
}

#define DEFAULTSTAGES 4 // Normal, Hard, Ex, Ex2 (we dont count warmup)
#define NUMBEROFSTAGES 8

ConVar g_cDelay, g_cRtd, g_cRtd_Percent, g_cZMStageMenu, g_cCDNumber;

bool g_bIsRevote = false;
bool g_bPlayedZM = false;
bool g_bVoteFinished = true;
bool bStartVoteNextRound = false;

ArrayList g_CooldownQueue = null; // FIFO queue of stages on cooldown
static char g_sStageName[NUMBEROFSTAGES][512] = {"Extreme 2", "Extreme 2 (Heal + Ultima)", "Extreme 3 (ZED)", "Extreme 3 (Hellz)", "Race Mode", "Zombie Mode", "Extreme 3 (NiDE)", "Extreme 3 (RMZS)"};

int g_Winnerstage;

Handle g_VoteMenu = null;
ArrayList g_StageList = null;
Handle g_CountdownTimer = null;

public void OnPluginStart()
{
	g_cDelay = CreateConVar("sm_makovote_delay", "3.0", "Time in seconds for firing the vote from admin command", FCVAR_NOTIFY, true, 1.0, true, 10.0);
	g_cRtd = CreateConVar("sm_makovote_rtd", "0", "Enable Roll The Dice", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cRtd_Percent = CreateConVar("sm_makovote_rtd_percent", "15", "Percentage chance value to trigger ZM mod with RTD", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_cZMStageMenu = CreateConVar("sm_makovote_zmstage_menu", "1", "Enable/Disable the ZM stage in the menu [dependency: sm_makovote_rtd 0]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cCDNumber = CreateConVar("sm_makovote_cd_maxstages", "3", "Number of stages to be on cooldown before reset", FCVAR_NOTIFY, true, 0.0, true, float(NUMBEROFSTAGES));

	RegAdminCmd("sm_makovote", Command_AdminStartVote, ADMFLAG_CONVARS, "sm_makovote");
	RegAdminCmd("sm_makovote_debug", Command_DebugCooldown, ADMFLAG_ROOT, "Show current cooldown queue");
	RegAdminCmd("sm_racebhop", Command_RaceBhop, ADMFLAG_ROOT);

	RegServerCmd("sm_makovote", Command_StartVote);
	RegServerCmd("sm_cancelrace", Command_CancelRace);
	RegServerCmd("sm_startrace", Command_StartRace);
	RegServerCmd("sm_endrace", Command_EndRace);

	HookEvent("round_start", OnRoundStart);
	AutoExecConfig(true);
}

public void OnMapStart()
{
	g_bValidMap = VerifyMap();

	if (!g_bValidMap)
		return;

	g_bVoteFinished = true;
	bStartVoteNextRound = false;
	g_bPlayedZM = false;

	g_CooldownQueue = new ArrayList();

	LogCooldownDebug();
}

public void OnMapEnd()
{
	if (!g_bValidMap)
		return;

	delete g_StageList;
	delete g_CooldownQueue;
}

stock bool VerifyMap()
{
	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if (!StrEqual(currentMap, "ze_FFVII_Mako_Reactor_v5_3", false))
		return false;

	PrecacheSound("#makovote/Pendulum - Witchcraft.mp3", true);
	AddFileToDownloadsTable("sound/makovote/Pendulum - Witchcraft.mp3");

	g_iModelIndex = PrecacheModel("models/mapeadores/kaem/sephiroth3/sephiroth.mdl");

	AddFileToDownloadsTable("models/mapeadores/kaem/sephiroth3/sephiroth.mdl");
	AddFileToDownloadsTable("models/mapeadores/kaem/sephiroth3/sephiroth.phy");
	AddFileToDownloadsTable("models/mapeadores/kaem/sephiroth3/sephiroth.vvd");
	AddFileToDownloadsTable("models/mapeadores/kaem/sephiroth3/sephiroth.dx80.vtx");
	AddFileToDownloadsTable("models/mapeadores/kaem/sephiroth3/sephiroth.dx90.vtx");
	AddFileToDownloadsTable("models/mapeadores/kaem/sephiroth3/sephiroth.xbox.vtx");
	AddFileToDownloadsTable("models/mapeadores/kaem/sephiroth3/sephiroth.sw.vtx");

	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part1.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part1.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part2.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part2.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part3.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part3.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part4.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part4.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part5.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part5.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part6.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part6.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part7.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part7.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part8.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part8.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part9.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part9.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part10.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part10.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part11.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part11.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part12.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part12.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part13.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part13.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part14.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part14.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part15.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part15.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part16.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part16.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part17.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part17.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part18.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part18.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part19.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part19.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part20.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/sephiroth3/part20.vtf");

	PrecacheSound("#zombieden/custommusic/advent2.mp3", true);
	PrecacheSound("#zombieden/custommusic/m2fix.mp3", true);
	PrecacheSound("#zombieden/custommusic/m3fix.mp3", true);
	PrecacheSound("#zombieden/custommusic/m4fix.mp3", true);
	PrecacheSound("#zombieden/custommusic/m5fix.mp3", true);
	PrecacheSound("#zombieden/custommusic/m6.mp3", true);

	AddFileToDownloadsTable("sound/zombieden/custommusic/advent2.mp3");
	AddFileToDownloadsTable("sound/zombieden/custommusic/m2fix.mp3");
	AddFileToDownloadsTable("sound/zombieden/custommusic/m3fix.mp3");
	AddFileToDownloadsTable("sound/zombieden/custommusic/m4fix.mp3");
	AddFileToDownloadsTable("sound/zombieden/custommusic/m5fix.mp3");
	AddFileToDownloadsTable("sound/zombieden/custommusic/m6.mp3");

	PrecacheSound("#jaek/ze_music/mako_reactor/muzzy_endgame.mp3", true);
	PrecacheSound("#jaek/ze_music/mako_reactor/muzzy_mix.mp3", true);
	PrecacheSound("#jaek/ze_music/mako_reactor/muzzy_play.mp3", true);
	PrecacheSound("#jaek/ze_music/mako_reactor/muzzy_play2.mp3", true);

	AddFileToDownloadsTable("sound/jaek/ze_music/mako_reactor/muzzy_endgame.mp3");
	AddFileToDownloadsTable("sound/jaek/ze_music/mako_reactor/muzzy_mix.mp3");
	AddFileToDownloadsTable("sound/jaek/ze_music/mako_reactor/muzzy_play.mp3");
	AddFileToDownloadsTable("sound/jaek/ze_music/mako_reactor/muzzy_play2.mp3");

	return true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!g_bValidMap || !g_bRaceEnabled || !g_bRaceAutoBhop || !IsClientInGame(client))
		return Plugin_Continue;

	if (!IsPlayerAlive(client) || !(buttons & IN_JUMP))
		return Plugin_Continue;

	if (GetEntityMoveType(client) & MOVETYPE_LADDER || GetEntityFlags(client) & FL_ONGROUND)
		return Plugin_Continue;

	buttons &= ~IN_JUMP;

	return Plugin_Continue;
}

public void OnEntitySpawned(int entity, const char[] sClassname)
{
	if (!g_bValidMap || g_bVoteFinished || !IsValidEntity(entity) || !IsValidEdict(entity))
		return;

	char sTargetname[128];
	GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

	if ((strcmp(sTargetname, "espad") != 0) && (strcmp(sTargetname, "ss_slow") != 0) && (strcmp(sClassname, "ambient_generic") == 0))
		AcceptEntityInput(entity, "Kill");

	if (!strncmp(sTargetname, "EX3SephirothWeapon", 18, false))
	{
		char sVariant[512];
		Format(sVariant, sizeof(sVariant), "OnPlayerPickup !activator:AddOutput:modelindex %d:0:1", g_iModelIndex);

		SetVariantString(sVariant);
		AcceptEntityInput(entity, "AddOutput");
	}
	else if (!strncmp(sTargetname, "EX3EndingRelay", 14, false))
	{
		SetVariantString("OnUser1 cancion_2:Kill::0:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnUser1 cancion_1:AddOutput:message #zombieden/custommusic/m5fix.mp3:0:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnUser1 cancion_1:PlaySound::0.02:1");
		AcceptEntityInput(entity, "AddOutput");
	}
	else if (!strncmp(sTargetname, "LevelRelayExtreme3Zombieden", 27, false))
	{
		SetVariantString("OnTrigger cancion_1:AddOutput:message #zombieden/custommusic/advent2.mp3:1:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger cancion_2:AddOutput:message #zombieden/custommusic/m2fix.mp3:1:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger cancion_3:AddOutput:message #zombieden/custommusic/m3fix.mp3:1:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger cancion_3_extra:AddOutput:message #zombieden/custommusic/m4fix.mp3:1:1");
		AcceptEntityInput(entity, "AddOutput");
	}
	else if (!strncmp(sTargetname, "LevelRelayRaceZombieden", 23, false))
	{
		SetVariantString("OnTrigger mus_zm2:Kill::0:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger ss_howd:AddOutput:message #zombieden/custommusic/m6.mp3:0:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger ss_howd:PlaySound::0.02:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger ss_howd:PlaySound::190.02:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger ss_howd:PlaySound::380.02:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger ss_howd:PlaySound::570.02:1");
		AcceptEntityInput(entity, "AddOutput");

		SetVariantString("OnTrigger ss_howd:PlaySound::760.02:1");
		AcceptEntityInput(entity, "AddOutput");
	}
}

public void OnRoundStart(Event hEvent, const char[] sEvent, bool bDontBroadcast)
{
	if (!g_bValidMap)
		return;

	if (bStartVoteNextRound)
	{
		delete g_CountdownTimer;
		if (!g_bPlayedZM && g_cRtd.BoolValue)
		{
			CPrintToChatAll("{green}[Mako Vote] {white}ZM has not been played yet. Rolling the dice...");
			if (GetRandomInt(1, 100) <= g_cRtd_Percent.IntValue)
			{
				CPrintToChatAll("{green}[Mako Vote] {white}Result: ZM, restarting round.");
				ServerCommand("sm_stage zm");
				g_bVoteFinished = true;
				bStartVoteNextRound = false;
				g_bPlayedZM = true;
				CS_TerminateRound(1.0, CSRoundEnd_GameStart, false);
				return;
			}
			CPrintToChatAll("{green}[Mako Vote] {white}Result: Normal Mako Vote");
		}
		if (g_bPlayedZM && g_cRtd.BoolValue)
			CPrintToChatAll("{green}[Mako Vote] {white}ZM already has been played. Starting normal vote.");

		g_CountdownTimer = CreateTimer(1.0, StartVote, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		bStartVoteNextRound = false;
	}

	if (!g_bVoteFinished)
	{
		int iStrip = FindEntityByTargetname(INVALID_ENT_REFERENCE, "RaceZone", "game_zone_player");
		if (iStrip != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iStrip, "FireUser1");

		int iButton1 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "boton", "func_button");
		if (iButton1 != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iButton1, "Lock");

		int iButton2 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "RaceMapButton1", "func_button");
		if (iButton2 != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iButton2, "Lock");

		int iButton3 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "RaceMapButton2", "func_button");
		if (iButton3 != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iButton3, "Lock");

		int iButton4 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "RaceMapButton3", "func_button");
		if (iButton4 != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iButton4, "Lock");

		int iButton5 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "RaceMapButton4", "func_button");
		if (iButton5 != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iButton5, "Lock");

		int iCounter = FindEntityByTargetname(INVALID_ENT_REFERENCE, "LevelCase", "logic_case");
		if (iCounter != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iCounter, "Kill");

		int iDestination = FindEntityByTargetname(INVALID_ENT_REFERENCE, "arriba2ex", "info_teleport_destination");
		if (iDestination != INVALID_ENT_REFERENCE)
		{
			SetVariantString("origin -9350 4550 100");
			AcceptEntityInput(iDestination, "AddOutput");

			SetVariantString("angles 0 -90 0");
			AcceptEntityInput(iDestination, "AddOutput");
		}

		int iTeleport = FindEntityByTargetname(INVALID_ENT_REFERENCE, "teleporte_extreme", "trigger_teleport");
		if (iTeleport != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iTeleport, "Enable");

		int iBarrerasfinal2 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "barrerasfinal2", "func_breakable");
		if (iBarrerasfinal2 != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iBarrerasfinal2, "Break");

		int iBarrerasfinal = FindEntityByTargetname(INVALID_ENT_REFERENCE, "barrerasfinal", "prop_dynamic");
		if (iBarrerasfinal != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iBarrerasfinal, "Kill");

		int iFilter = FindEntityByTargetname(INVALID_ENT_REFERENCE, "humanos", "filter_activator_team");
		if (iFilter != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iFilter, "Kill");

		int iTemp1 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "EX2Laser1Temp", "point_template");
		if (iTemp1 != INVALID_ENT_REFERENCE)
		{
			DispatchKeyValue(iTemp1, "OnEntitySpawned", "EX2Laser1Hurt,SetDamage,0,0,-1");
			DispatchKeyValue(iTemp1, "OnEntitySpawned", "EX2Laser1Hurt,AddOutput,OnStartTouch !activator:AddOutput:origin -7000 -1000 100:0:-1,0,-1");
		}

		int iTemp2 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "EX2Laser2Temp", "point_template");
		if (iTemp2 != INVALID_ENT_REFERENCE)
		{
			DispatchKeyValue(iTemp2, "OnEntitySpawned", "EX2Laser2Hurt,SetDamage,0,0,-1");
			DispatchKeyValue(iTemp2, "OnEntitySpawned", "EX2Laser2Hurt,AddOutput,OnStartTouch !activator:AddOutput:origin -7000 -1000 100:0:-1,0,-1");
		}

		int iTemp3 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "EX2Laser3Temp", "point_template");
		if (iTemp3 != INVALID_ENT_REFERENCE)
		{
			DispatchKeyValue(iTemp3, "OnEntitySpawned", "EX2Laser3Hurt,SetDamage,0,0,-1");
			DispatchKeyValue(iTemp3, "OnEntitySpawned", "EX2Laser3Hurt,AddOutput,OnStartTouch !activator:AddOutput:origin -7000 -1000 100:0:-1,0,-1");
		}

		int iTemp4 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "EX2Laser4Temp", "point_template");
		if (iTemp4 != INVALID_ENT_REFERENCE)
		{
			DispatchKeyValue(iTemp4, "OnEntitySpawned", "EX2Laser4Hurt,SetDamage,0,0,-1");
			DispatchKeyValue(iTemp4, "OnEntitySpawned", "EX2Laser4Hurt,AddOutput,OnStartTouch !activator:AddOutput:origin -7000 -1000 100:0:-1,0,-1");
		}

		int iLaserTimer = FindEntityByTargetname(INVALID_ENT_REFERENCE, "cortes2", "logic_timer");
		if (iLaserTimer != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iLaserTimer, "Enable");

		int iLevelText = FindEntityByTargetname(INVALID_ENT_REFERENCE, "LevelText", "game_text");
		if (iLevelText != INVALID_ENT_REFERENCE)
		{
			SetVariantString("message > INTERMISSION ROUND <");
			AcceptEntityInput(iLevelText, "AddOutput");
		}

		int iMusic = FindEntityByTargetname(INVALID_ENT_REFERENCE, "ss_slow", "ambient_generic");
		if (iMusic != INVALID_ENT_REFERENCE)
		{
			SetVariantString("message #makovote/Pendulum - Witchcraft.mp3");
			AcceptEntityInput(iMusic, "AddOutput");
			AcceptEntityInput(iMusic, "PlaySound");
		}
	}
}

public void GenerateArray()
{
	int iBlockSize = ByteCountToCells(PLATFORM_MAX_PATH);

	delete g_StageList;
	g_StageList = new ArrayList(iBlockSize);

	for (int i = 0; i <= (NUMBEROFSTAGES - 1); i++)
		g_StageList.PushString(g_sStageName[i]);

	int iArraySize = GetArraySize(g_StageList);

	for (int i = 0; i <= (iArraySize - 1); i++)
	{
		int iRandom = GetRandomInt(0, iArraySize - 1);
		char sTemp1[128];
		g_StageList.GetString(iRandom, sTemp1, sizeof(sTemp1));

		char sTemp2[128];
		g_StageList.GetString(i, sTemp2, sizeof(sTemp2));

		g_StageList.SetString(i, sTemp1);
		g_StageList.SetString(iRandom, sTemp2);
	}
}

public Action Command_RaceBhop(int client, int args)
{
	if (!g_bValidMap)
		return Plugin_Handled;

	g_bRaceAutoBhop = !g_bRaceAutoBhop;

	if (g_bRaceAutoBhop)
	{
		ServerCommand("sm plugins unload anticheats/AntiBhopCheat");
		ServerCommand("sm plugins reload adminmenu");
		ServerCommand("sv_airaccelerate 150");
	}
	else
	{
		ServerCommand("sm plugins load anticheats/AntiBhopCheat");
		ServerCommand("sm plugins reload adminmenu");
		ServerCommand("sv_airaccelerate 10");
	}

	return Plugin_Handled;
}

public Action Command_CancelRace(int args)
{
	if (!g_bValidMap)
		return Plugin_Handled;

	if (g_bRaceAutoBhop)
	{
		ServerCommand("sm plugins load anticheats/AntiBhopCheat");
		ServerCommand("sm plugins reload adminmenu");
		ServerCommand("sv_airaccelerate 10");
	}

	g_bRaceEnabled = false;
	g_bRaceAutoBhop = false;
	g_bRaceBlockInfect = false;
	g_bRaceBlockRespawn = false;

	return Plugin_Handled;
}

public Action Command_StartRace(int args)
{
	if (!g_bValidMap)
		return Plugin_Handled;

	g_bRaceEnabled = true;
	g_bRaceBlockInfect = true;
	g_bRaceBlockRespawn = true;

	return Plugin_Handled;
}

public Action Command_EndRace(int args)
{
	if (!g_bValidMap)
		return Plugin_Handled;

	g_bRaceBlockInfect = false;

	char sTargetname[128];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		GetEntPropString(client, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

		if (StrEqual(sTargetname, "player_racewinner", false))
			continue;

		ZR_InfectClient(client);
	}

	int entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(entity))
			continue;

		GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

		if (!StrEqual(sTargetname, "RaceRelayEnd", false))
			continue;

		AcceptEntityInput(entity, "CancelPending");
	}

	return Plugin_Handled;
}

public Action ZR_OnClientInfect()
{
	if (!g_bValidMap)
		return Plugin_Continue;

	if (g_bRaceEnabled && g_bRaceBlockInfect)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action ZR_OnClientRespawn()
{
	if (!g_bValidMap)
		return Plugin_Continue;

	if (g_bRaceEnabled && g_bRaceBlockRespawn)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action Command_AdminStartVote(int client, int argc)
{
	if (!g_bValidMap)
		return Plugin_Handled;

	char name[64];

	if (client == 0)
		name = "The server";
	else if (!GetClientName(client, name, sizeof(name)))
		Format(name, sizeof(name), "Disconnected (uid:%d)", client);

	if (client != 0)
	{
		CPrintToChatAll("{green}[SM] {cyan}%s {white}has initiated a mako vote round (In %d seconds)", name, g_cDelay.IntValue);
		CreateTimer(g_cDelay.FloatValue, AdminStartVote_Timer);
	}
	else
		CPrintToChatAll("{green}[SM] {cyan}%s {white}has initiated a mako vote round (Next round)", name);

	Cmd_StartVote();

	return Plugin_Handled;
}

public Action Command_DebugCooldown(int client, int argc)
{
	if (!g_bValidMap)
		return Plugin_Handled;

	ReplyToCommand(client, "=== MakoVote Cooldown Debug ===");
	ReplyToCommand(client, "Max cooldown stages: %d", g_cCDNumber.IntValue);
	ReplyToCommand(client, "Current cooldown queue length: %d", g_CooldownQueue.Length);
	ReplyToCommand(client, "");

	if (g_CooldownQueue.Length == 0)
	{
		ReplyToCommand(client, "No stages currently on cooldown.");
	}
	else
	{
		ReplyToCommand(client, "Cooldown queue (FIFO order - oldest first):");
		for (int i = 0; i < g_CooldownQueue.Length; i++)
		{
			int stageIndex = g_CooldownQueue.Get(i);
			ReplyToCommand(client, "  [%d] Stage %d: %s", i+1, stageIndex, g_sStageName[stageIndex]);
		}
	}

	ReplyToCommand(client, "");
	ReplyToCommand(client, "Available stages:");
	int availableCount = 0;
	for (int i = 0; i < NUMBEROFSTAGES; i++)
	{
		if (!IsStageOnCooldown(i))
		{
			ReplyToCommand(client, "  Stage %d: %s", i, g_sStageName[i]);
			availableCount++;
		}
	}

	if (availableCount == 0)
		ReplyToCommand(client, "  None (all stages on cooldown!)");

	ReplyToCommand(client, "");
	ReplyToCommand(client, "=== End Debug ===");

	return Plugin_Handled;
}

stock Action AdminStartVote_Timer(Handle hTimer)
{
	CPrintToChatAll("{green}[MakoVote] {white}Restarting round, be ready to vote.");
	TerminateRound();

	return Plugin_Stop;
}

public Action Command_StartVote(int args)
{
	if (!g_bValidMap)
		return Plugin_Handled;

	Cmd_StartVote();
	return Plugin_Handled;
}

public void Cmd_StartVote()
{
	int iCurrentStage = GetCurrentStage();

	AddStageToCooldown(g_Winnerstage);

	if (iCurrentStage == 5)
		g_bPlayedZM = true;

	g_bVoteFinished = false;
	GenerateArray();
	bStartVoteNextRound = true;
}

public Action StartVote(Handle timer)
{
	static int iCountDown = 3;
	PrintCenterTextAll("[MakoVote] Starting Vote in %ds", iCountDown);

	if (iCountDown-- <= 0)
	{
		iCountDown = 3;
		g_CountdownTimer = null;
		InitiateVote();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void InitiateVote()
{
	if (IsVoteInProgress())
	{
		CPrintToChatAll("{green}[Mako Vote] {white}Another vote is currently in progress, retrying again in 3s.");
		delete g_CountdownTimer;
		g_CountdownTimer = CreateTimer(3.0, StartVote, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	LogCooldownDebug();

	Handle menuStyle = GetMenuStyleHandle(view_as<MenuStyle>(0));
	g_VoteMenu = CreateMenuEx(menuStyle, Handler_MakoVoteMenu, MenuAction_End | MenuAction_Display | MenuAction_DisplayItem | MenuAction_VoteCancel);

	int iArraySize = g_StageList.Length;
	for (int i = 0; i <= (iArraySize - 1); i++)
	{
		char sBuffer[128];
		g_StageList.GetString(i, sBuffer, sizeof(sBuffer));

		bool isZombieMode = strcmp(sBuffer, "Zombie Mode") == 0;
		bool bSkipZMStage = isZombieMode && (g_cRtd.BoolValue || g_bPlayedZM || !g_cZMStageMenu.BoolValue);

		for (int j = 0; j <= (NUMBEROFSTAGES - 1); j++)
		{
			if (strcmp(sBuffer, g_sStageName[j]) == 0)
			{
				// Skip ZM stage completely if RTD is enabled or other conditions
				if (bSkipZMStage)
					continue;

				bool disableItem = IsStageOnCooldown(j);
				AddMenuItem(g_VoteMenu, sBuffer, sBuffer, disableItem ? ITEMDRAW_DISABLED : 0);
			}
		}
	}

	SetMenuOptionFlags(g_VoteMenu, MENU_NO_PAGINATION);
	SetMenuTitle(g_VoteMenu, "What stage to play next?");
	SetVoteResultCallback(g_VoteMenu, Handler_SettingsVoteFinished);
	VoteMenuToAll(g_VoteMenu, 15);
}

public int Handler_MakoVoteMenu(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);

			if (param1 != -1)
			{
				g_bVoteFinished = true;
				TerminateRound();
			}
		}
	}
	return 0;
}

public void Handler_SettingsVoteFinished(Handle menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	int highest_votes = item_info[0][VOTEINFO_ITEM_VOTES];
	int required_percent = 60;
	int required_votes = RoundToCeil(float(num_votes) * float(required_percent) / 100);

	if ((highest_votes < required_votes) && (!g_bIsRevote))
	{
		CPrintToChatAll("{green}[MakoVote] {white}A revote is needed!");
		char sFirst[128];
		char sSecond[128];
		GetMenuItem(menu, item_info[0][VOTEINFO_ITEM_INDEX], sFirst, sizeof(sFirst));
		GetMenuItem(menu, item_info[1][VOTEINFO_ITEM_INDEX], sSecond, sizeof(sSecond));
		g_StageList.Clear();
		g_StageList.PushString(sFirst);
		g_StageList.PushString(sSecond);
		g_bIsRevote = true;

		delete g_CountdownTimer;
		g_CountdownTimer = CreateTimer(1.0, StartVote, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		return;
	}

	// No revote needed, continue as normal.
	g_bIsRevote = false;
	Handler_VoteFinishedGeneric(menu, num_votes, num_clients, client_info, num_items, item_info);
}

public void Handler_VoteFinishedGeneric(Handle menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	g_bVoteFinished = true;
	char sWinner[128];
	GetMenuItem(menu, item_info[0][VOTEINFO_ITEM_INDEX], sWinner, sizeof(sWinner));
	float fPercentage = float(item_info[0][VOTEINFO_ITEM_VOTES] * 100) / float(num_votes);

	CPrintToChatAll("{green}[MakoVote] {white}Vote Finished! Winner: {red}%s{white} with %d%% of %d votes!", sWinner, RoundToFloor(fPercentage), num_votes);

	for (int i = 0; i <= (NUMBEROFSTAGES - 1); i++)
	{
		if (strcmp(sWinner, g_sStageName[i]) == 0)
			g_Winnerstage = i;
	}

	AddStageToCooldown(g_Winnerstage);

	ServerCommand("sm_stage %d", (g_Winnerstage + DEFAULTSTAGES));
	TerminateRound();
}

public int GetCurrentStage()
{
	// Spwaned as math_counter, but get changed as info_target
	// "OnUser1" "LevelCounter,AddOutput,classname info_target,0.03,1"

	int iLevelCounterEnt = FindEntityByTargetname(INVALID_ENT_REFERENCE, "LevelCounter", "math_counter");
	if (iLevelCounterEnt == INVALID_ENT_REFERENCE)
		iLevelCounterEnt = FindEntityByTargetname(INVALID_ENT_REFERENCE, "LevelCounter", "info_target");

	int offset = FindDataMapInfo(iLevelCounterEnt, "m_OutValue");
	int iCounterVal = RoundFloat(GetEntDataFloat(iLevelCounterEnt, offset));

	int iCurrentStage;
	// Note: iCurrentStage is the index as "triggers" related to the stage in the adminroom config.

	if (iCounterVal == 5) // Extreme 2
		iCurrentStage = 0;
	else if (iCounterVal == 7) // Extreme 2 (Heal + Ultima)
		iCurrentStage = 1;
	else if (iCounterVal == 9) // Extreme 3 (Hellz)
		iCurrentStage = 3;
	else if (iCounterVal == 10) // Extreme 3 (ZED)
		iCurrentStage = 2;
	else if (iCounterVal == 11) // Race Mode
		iCurrentStage = 4;
	else if (iCounterVal == 6) // Zombie Mode
		iCurrentStage = 5;
	else if (iCounterVal == 13) // Extreme 3 (NiDE)
		iCurrentStage = 6;
	else if (iCounterVal == 14) // Extreme 3 (RMZS)
		iCurrentStage = 7;
	else
		iCurrentStage = -1;

	return iCurrentStage;
}

stock bool IsStageOnCooldown(int stageIndex)
{
	return g_CooldownQueue.FindValue(stageIndex) != -1;
}

stock void AddStageToCooldown(int stageIndex)
{
	// Add the winning stage to cooldown queue
	if (!IsStageOnCooldown(stageIndex))
	{
		g_CooldownQueue.Push(stageIndex);
		LogMessage("Added stage %d (%s) to cooldown queue. New length: %d", stageIndex, g_sStageName[stageIndex], g_CooldownQueue.Length);
	}

	// If the limit is reached, remove the oldest stage from cooldown
	if (g_CooldownQueue.Length > g_cCDNumber.IntValue)
	{
		LogMessage("Cooldown limit reached! Length: %d, Limit: %d - Removing oldest stage", g_CooldownQueue.Length, g_cCDNumber.IntValue);
		g_CooldownQueue.Erase(0);
	}
}

stock void LogCooldownDebug()
{
	LogMessage("=== MakoVote Cooldown Debug ===");
	LogMessage("Max cooldown stages: %d", g_cCDNumber.IntValue);
	LogMessage("Current cooldown queue length: %d", g_CooldownQueue.Length);

	if (g_CooldownQueue.Length == 0)
	{
		LogMessage("No stages currently on cooldown.");
	}
	else
	{
		LogMessage("Cooldown queue (FIFO order - oldest first):");
		for (int i = 0; i < g_CooldownQueue.Length; i++)
		{
			int stageIndex = g_CooldownQueue.Get(i);
			LogMessage("  [%d] Stage %d: %s", i+1, stageIndex, g_sStageName[stageIndex]);
		}
	}

	LogMessage("Available stages:");
	int availableCount = 0;
	for (int i = 0; i < NUMBEROFSTAGES; i++)
	{
		if (!IsStageOnCooldown(i))
		{
			LogMessage("  Stage %d: %s", i, g_sStageName[i]);
			availableCount++;
		}
	}

	if (availableCount == 0)
		LogMessage("  None (all stages on cooldown!)");

	LogMessage("=== End Debug ===");
}

public int FindEntityByTargetname(int entity, const char[] sTargetname, const char[] sClassname)
{
	if (sTargetname[0] == '#') // HammerID
	{
		int HammerID = StringToInt(sTargetname[1]);

		while((entity = FindEntityByClassname(entity, sClassname)) != INVALID_ENT_REFERENCE)
		{
			if (GetEntProp(entity, Prop_Data, "m_iHammerID") == HammerID)
				return entity;
		}
	}
	else // Targetname
	{
		int Wildcard = FindCharInString(sTargetname, '*');
		char sTargetnameBuf[64];

		while((entity = FindEntityByClassname(entity, sClassname)) != INVALID_ENT_REFERENCE)
		{
			if (GetEntPropString(entity, Prop_Data, "m_iName", sTargetnameBuf, sizeof(sTargetnameBuf)) <= 0)
				continue;

			if (strncmp(sTargetnameBuf, sTargetname, Wildcard) == 0)
				return entity;
		}
	}
	return INVALID_ENT_REFERENCE;
}

void TerminateRound()
{
	CS_TerminateRound(1.5, CSRoundEnd_Draw, false);

	// Fix the score - Round Draw give 1 point to CT Team
	int score = GetTeamScore(CS_TEAM_CT);
	if (score > 0) SetTeamScore(CS_TEAM_CT, (score - 1));
}
