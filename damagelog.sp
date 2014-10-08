#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define SAVEROUNDS 3

new damageTaken[SAVEROUNDS][MAXPLAYERS+1][MAXPLAYERS+1];
new killedBy[SAVEROUNDS][MAXPLAYERS+1];
new String:playerNames[MAXPLAYERS+1][MAX_NAME_LENGTH];
new currentround = 0;
new targetChosen[MAXPLAYERS+1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_damagelog", Command_LogDamage, ADMFLAG_SLAY);
	RegAdminCmd("sm_dl", Command_LogDamage, ADMFLAG_SLAY);
	RegAdminCmd("sm_hurtlog", Command_LogDamage, ADMFLAG_SLAY);
	RegAdminCmd("sm_hl", Command_LogDamage, ADMFLAG_SLAY);
	RegAdminCmd("sm_killlog", Command_KillLog, ADMFLAG_SLAY);
	RegAdminCmd("sm_kl", Command_KillLog, ADMFLAG_SLAY);
	RegAdminCmd("sm_deathlog", Command_DeathLog, ADMFLAG_SLAY);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	playerNames[0] = "World";
	
	for (new round = 0; round < SAVEROUNDS; round++)
	{
		for (new client = 1; client <= MAXPLAYERS; client++)
		{
			killedBy[round][client] = -1;
		}
	}
}

public Action:Command_LogDamage(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, " \x07[SM]\x01 Usage: !damagelog\x03 <player/@all/@ct/@t>");
		return Plugin_Handled;
	}
   
	decl String:arg1[32];
	GetCmdArg(1, arg1, 32);
   
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
   
	target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);
   
	if (target_count < 1)
	{
		ReplyToCommand(client, " \x07[SM]\x01 No matching client was found.");
		return Plugin_Handled;
	}
   
	if (target_count > 1) {
		new Handle:menu = CreateMenu(MenuHandler_DamageNameChoice);
		SetMenuTitle(menu, "What player did you mean?");
		for (new i = 0; i < target_count; i++)
		{
			decl String:name[32], String:targetid[3];
			GetClientName(target_list[i], name, sizeof(name));
			IntToString(target_list[i], targetid, sizeof(targetid));
			AddMenuItem(menu, targetid, name);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		targetChosen[client] = target_list[0];
		ShowRoundMenu(client, MenuHandler_DamageShow);
	}

	return Plugin_Handled;
}
 
public Action:Command_DeathLog(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, " \x07[SM]\x01 Usage: !deathlog\x03 <player/@all/@ct/@t>");
		return Plugin_Handled;
	}
   
	decl String:arg1[32];
	GetCmdArg(1, arg1, 32);
   
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
   
	target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);
   
	if (target_count < 1)
	{
		ReplyToCommand(client, " \x07[SM]\x01 No matching client was found.");
		return Plugin_Handled;
	}
	
	if (target_count > 1) {
		new Handle:menu = CreateMenu(MenuHandler_DeathNameChoice);
		SetMenuTitle(menu, "What player did you mean?");
		for (new i = 0; i < target_count; i++)
		{
			decl String:name[32], String:targetid[3];
			GetClientName(target_list[i], name, sizeof(name));
			IntToString(target_list[i], targetid, sizeof(targetid));
			AddMenuItem(menu, targetid, name);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		targetChosen[client] = target_list[0];
		ShowRoundMenu(client, MenuHandler_DeathShow);
	}
	return Plugin_Handled;
}

public Action:Command_KillLog(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, " \x07[SM]\x01 Usage: !killlog\x03 <player/@all/@ct/@t>");
		return Plugin_Handled;
	}
   
	decl String:arg1[32];
	GetCmdArg(1, arg1, 32);
   
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
   
	target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);
   
	if (target_count < 1)
	{
		if (StrEqual(arg1, "world", false))
		{
			targetChosen[client] = 0;
			ShowRoundMenu(client, MenuHandler_KillShow);
		}
		else ReplyToCommand(client, " \x07[SM]\x01 No matching client was found.");
		return Plugin_Handled;
	}
	
	if (target_count > 1) {
		new Handle:menu = CreateMenu(MenuHandler_KillNameChoice);
		SetMenuTitle(menu, "What player did you mean?");
		for (new i = 0; i < target_count; i++)
		{
			decl String:name[32], String:targetid[3];
			GetClientName(target_list[i], name, sizeof(name));
			IntToString(target_list[i], targetid, sizeof(targetid));
			AddMenuItem(menu, targetid, name);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
		targetChosen[client] = target_list[0];
		ShowRoundMenu(client, MenuHandler_KillShow);
	}
	
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	killedBy[currentround][victimId] = attackerId;
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	
	damageTaken[currentround][victimId][attackerId] += damage;
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientName(client, playerNames[client], MAX_NAME_LENGTH);
	
	for (new i = 0; i <= MaxClients; i++)
	{
		damageTaken[currentround][client][i] = 0;
	}
	killedBy[currentround][client] = -1;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	currentround = (currentround + 1) % SAVEROUNDS;
	return Plugin_Continue;
}

public MenuHandler_KillNameChoice(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[3];
		GetMenuItem(menu, param2, info, sizeof(info));
		targetChosen[param1] = StringToInt(info);
		ShowRoundMenu(param1, MenuHandler_KillShow);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ShowRoundMenu(param1, MenuHandler_KillShow);
	}
}

ShowKillMenu(client, round)
{
	new Handle:menu = CreateMenu(MenuHandler_KillNameChoice);
	SetMenuTitle(menu, "%N killed", targetChosen[client]);
	new count;
	for (new j = 1; j <= MaxClients; j++)
	{
		if (IsClientInGame(j) && killedBy[round][j] == targetChosen[client]) {
			decl String:name[32];
			GetClientName(j, name, sizeof(name));
			AddMenuItem(menu, "", name, ITEMDRAW_DISABLED);
			count++;
		}
	}
	if (count == 0) AddMenuItem(menu, "", "DIDN'T KILL", ITEMDRAW_DISABLED);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_DamageNameChoice(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[3];
		GetMenuItem(menu, param2, info, sizeof(info));
		targetChosen[param1] = StringToInt(info);
		ShowRoundMenu(param1, MenuHandler_DamageShow);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ShowRoundMenu(param1, MenuHandler_DamageShow);
	}
}

ShowDamageMenu(client, round)
{
	new Handle:menu = CreateMenu(MenuHandler_DamageNameChoice);
	SetMenuTitle(menu, "%N damaged by", targetChosen[client]);
	new count;
	for (new i = 0; i <= MaxClients; i++)
	{
		if (damageTaken[round][targetChosen[client]][i] != 0)
		{
			decl String:damagelog[40];
			Format(damagelog, sizeof(damagelog), "%s - %d", playerNames[i], damageTaken[round][targetChosen[client]][i]);
			AddMenuItem(menu, "", damagelog, ITEMDRAW_DISABLED);
			count++;
		}
	}
	if (count == 0) AddMenuItem(menu, "", "NOT DAMAGED", ITEMDRAW_DISABLED);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

GetPreviousRound(round)
{
	new newround = round - 1;
	if (newround < 0) newround = SAVEROUNDS-1;
	return newround;
}

ShowRoundMenu(client, MenuHandler:handler)
{
	new Handle:menu = CreateMenu(handler);
	SetMenuTitle(menu, "What round?");
	decl String:round[3];
	IntToString(currentround, round, sizeof(round));
	AddMenuItem(menu, round, "Current round");
	new previousround = currentround;
	new roundsAgo;
	decl String:display[18];
	while((previousround = GetPreviousRound(previousround)) != currentround)
	{
		Format(display, sizeof(display), "%d round(s) ago", ++roundsAgo);
		IntToString(previousround, round, sizeof(round));
		AddMenuItem(menu, round, display);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_DamageShow(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[3];
		GetMenuItem(menu, param2, info, sizeof(info));
		new round = StringToInt(info);
		ShowDamageMenu(param1, round);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_KillShow(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[3];
		GetMenuItem(menu, param2, info, sizeof(info));
		new round = StringToInt(info);
		ShowKillMenu(param1, round);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_DeathNameChoice(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[3];
		GetMenuItem(menu, param2, info, sizeof(info));
		targetChosen[param1] = StringToInt(info);
		ShowRoundMenu(param1, MenuHandler_DeathShow);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ShowRoundMenu(param1, MenuHandler_DeathShow);
	}
}

public MenuHandler_DeathShow(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[3];
		GetMenuItem(menu, param2, info, sizeof(info));
		new round = StringToInt(info);
		ShowDeathMenu(param1, round);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowDeathMenu(client, round)
{
	new Handle:menu = CreateMenu(MenuHandler_DeathNameChoice);
	SetMenuTitle(menu, "%N killed by", targetChosen[client]);
	if (killedBy[round][targetChosen[client]] < 0)
	{
		AddMenuItem(menu, "", "DIDN'T DIE", ITEMDRAW_DISABLED);
	}
	else
	{
		decl String:deathlog[40];
		Format(deathlog, sizeof(deathlog), "%s - %d", playerNames[killedBy[round][targetChosen[client]]], damageTaken[round][targetChosen[client]][killedBy[round][targetChosen[client]]]);
		AddMenuItem(menu, "", deathlog, ITEMDRAW_DISABLED);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}