#include <a_samp>
#if defined ARENA_WITH_CEF
    #include <cef>
    #define ARENA_CEF_BROWSER 7120
#endif

#define D_MAIN 1000
#define D_MAP 1001
#define D_ARMOR 1002
#define D_WEAPON 1003
#define MAX_LOBBIES 50
#define INVALID_LOBBY -1

new gNpcActor;
new gPlayerLobby[MAX_PLAYERS];
new gLobbyOwner[MAX_LOBBIES], gLobbyOpponent[MAX_LOBBIES], gLobbyMap[MAX_LOBBIES], gLobbyArmor[MAX_LOBBIES], gLobbyWeapon[MAX_LOBBIES], gLobbyBots[MAX_LOBBIES], gLobbyState[MAX_LOBBIES];
new gBattleMap[MAX_PLAYERS];
new gBotActor[MAX_LOBBIES], gBotHealth[MAX_LOBBIES], gBotLastHit[MAX_LOBBIES];
#define MAX_ARENA_OBJECTS 16
new gArenaObjectCount[MAX_PLAYERS], gArenaObjects[MAX_PLAYERS][MAX_ARENA_OBJECTS];
new Text:gHudTitle, Text:gHudInfo, Text:gHudPanel;
new gWeapons[] = {24, 25, 29, 31, 34};
new gWeaponNames[][] = {"Desert Eagle", "Shotgun", "MP5", "M4", "Sniper Rifle"};
new gMapNames[][] = {"Terminal", "Container Yard", "Desert Ruins", "Rooftop", "Industrial Zone"};
new Float:gSpawnA[5][4] = {{1950.0,-2180.0,13.5,90.0},{2440.0,-2110.0,13.5,90.0},{414.0,2530.0,16.5,90.0},{2020.0,1400.0,10.8,90.0},{873.0,-1200.0,16.5,90.0}};
new Float:gSpawnB[5][4] = {{1976.0,-2180.0,13.5,270.0},{2466.0,-2110.0,13.5,270.0},{440.0,2530.0,16.5,270.0},{2046.0,1400.0,10.8,270.0},{899.0,-1200.0,16.5,270.0}};

main() {}

public OnGameModeInit()
{
    SetGameModeText("LS Arena | Duel Hub");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
    ShowNameTags(1);
    AddPlayerClass(7, 1754.1,-1894.2,13.6,90.0,0,0,0,0,0,0);
    Create3DTextLabel("ARENA\nНажми ALT / используй /arena", 0x43D9FFFF, 1754.1,-1894.2,14.6, 20.0, 0, 1);
    gNpcActor = CreateActor(29, 1754.1,-1894.2,13.6,270.0);
    SetActorInvulnerable(gNpcActor, true);
    gHudPanel = TextDrawCreate(15.0,19.0," ");
    TextDrawLetterSize(gHudPanel,0.1,0.1); TextDrawTextSize(gHudPanel,235.0,0.0); TextDrawUseBox(gHudPanel,1);
    TextDrawBoxColor(gHudPanel,0x08111DEE); TextDrawSetOutline(gHudPanel,0); TextDrawSetShadow(gHudPanel,0);
    gHudTitle = TextDrawCreate(22.0, 25.0, "~b~N E O N ~w~// ~y~ARENA");
    TextDrawLetterSize(gHudTitle, 0.34, 1.55); TextDrawSetOutline(gHudTitle, 1); TextDrawFont(gHudTitle, 1); TextDrawSetProportional(gHudTitle, 1);
    gHudInfo = TextDrawCreate(22.0, 47.0, "~w~UNITY STATION ~b~| ~w~/arena ~y~OPEN MENU");
    TextDrawLetterSize(gHudInfo, 0.20, 0.95); TextDrawSetOutline(gHudInfo, 1); TextDrawFont(gHudInfo, 1); TextDrawSetProportional(gHudInfo, 1);
    for(new i; i < MAX_LOBBIES; i++) { gLobbyOwner[i] = INVALID_PLAYER_ID; gLobbyOpponent[i] = INVALID_PLAYER_ID; gLobbyState[i] = 0; gBotActor[i] = INVALID_ACTOR_ID; }
    SetTimer("ArenaBotThink", 450, true);
    #if defined ARENA_WITH_CEF
        SetTimer("ArenaHudRefresh", 1000, true);
    #endif
    return 1;
}

#if defined ARENA_WITH_CEF
public OnCefInitialize(player_id, success)
{
    if(success)
    {
        cef_create_browser(player_id,ARENA_CEF_BROWSER,"arena/index.html",false,false);
        SendClientMessage(player_id,0x66FFCCFF,"Chromium Arena HUD подключён.");
    }
    else SendClientMessage(player_id,0xFFCC66FF,"CEF не найден: установи клиентский пакет Chromium; игровая логика работает.");
    return 1;
}

public OnCefBrowserCreated(player_id, browser_id, status_code)
{
    if(browser_id == ARENA_CEF_BROWSER && status_code != 0) ArenaHudSend(player_id);
    return 1;
}

#endif

public OnPlayerConnect(playerid)
{
    #if defined ARENA_WITH_CEF
        new ip[16]; GetPlayerIp(playerid,ip,sizeof ip); cef_on_player_connect(playerid,ip);
    #endif
    gPlayerLobby[playerid] = INVALID_LOBBY;
    gBattleMap[playerid] = -1;
    gArenaObjectCount[playerid] = 0;
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerPos(playerid, 1754.1,-1894.2,13.6);
    SetPlayerFacingAngle(playerid,90.0);
    SetCameraBehindPlayer(playerid);
    TextDrawShowForPlayer(playerid,gHudPanel);
    TextDrawShowForPlayer(playerid,gHudTitle);
    TextDrawShowForPlayer(playerid,gHudInfo);
    return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if ((newkeys & KEY_WALK) && IsPlayerInRangeOfPoint(playerid, 3.0, 1754.1,-1894.2,13.6)) ShowMain(playerid);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext,"/arena",true)) { ShowMain(playerid); return 1; }
    if (!strcmp(cmdtext,"/join",true)) { JoinLobby(playerid); return 1; }
    if (!strcmp(cmdtext,"/leave",true)) { LeaveLobby(playerid); return 1; }
    return 0;
}

#if defined ARENA_WITH_CEF
forward ArenaHudRefresh();
public ArenaHudRefresh()
{
    for(new p; p < MAX_PLAYERS; p++) if(IsPlayerConnected(p) && cef_player_has_plugin(p)) ArenaHudSend(p);
    return 1;
}

ArenaHudSend(playerid)
{
    new lobby = gPlayerLobby[playerid];
    if(lobby == INVALID_LOBBY)
        cef_emit_event(playerid,"arena:hud",CEFSTR("UNITY STATION"),CEFSTR("HUB"),CEFSTR("—"),CEFINT(0),CEFINT(0));
    else
    {
        new stateName[16];
        if(gLobbyState[lobby] == 1) format(stateName,sizeof stateName,"WAITING");
        else if(gLobbyState[lobby] == 3) format(stateName,sizeof stateName,"VS AI");
        else format(stateName,sizeof stateName,"IN MATCH");
        cef_emit_event(playerid,"arena:hud",CEFSTR(gMapNames[gLobbyMap[lobby]]),CEFSTR(stateName),CEFSTR(gWeaponNames[gLobbyWeapon[lobby]]),CEFINT(gLobbyArmor[lobby]),CEFINT(gBotHealth[lobby]));
    }
}

#endif

ShowMain(playerid)
{
    ShowPlayerDialog(playerid,D_MAIN,DIALOG_STYLE_LIST,"{37D7FF}LS ARENA {FFFFFF}| Диспетчер","Создать лобби\nНайти открытое лобби\nПокинуть лобби\nКак играть","Выбрать","Назад");
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (!response)
    {
        if(dialogid == D_MAP || dialogid == D_ARMOR || dialogid == D_WEAPON || dialogid == D_MAIN+4)
            if(gPlayerLobby[playerid] != INVALID_LOBBY) LeaveLobby(playerid);
        return 1;
    }
    if(dialogid == D_MAIN)
    {
        if(listitem == 0) { if(gPlayerLobby[playerid] != INVALID_LOBBY) LeaveLobby(playerid); ShowPlayerDialog(playerid,D_MAP,DIALOG_STYLE_LIST,"Выбор карты", "Terminal\nContainer Yard\nDesert Ruins\nRooftop\nIndustrial Zone","Далее","Отмена"); }
        else if(listitem == 1) JoinLobby(playerid);
        else if(listitem == 2) LeaveLobby(playerid);
        else SendClientMessage(playerid,0xB8DFFFff,"Создай лобби и дождись соперника. Настрой броню/оружие, затем бой стартует автоматически.");
        return 1;
    }
    if(dialogid == D_MAP)
    {
        new lobby = FindFreeLobby();
        if(lobby == INVALID_LOBBY) return SendClientMessage(playerid,0xFF5555FF,"Все слоты лобби заняты."),1;
        gLobbyOwner[lobby] = playerid; gLobbyMap[lobby] = listitem; gLobbyArmor[lobby] = 100; gLobbyWeapon[lobby] = 0; gLobbyBots[lobby] = 0; gLobbyState[lobby] = 1; gPlayerLobby[playerid] = lobby;
        ShowPlayerDialog(playerid,D_ARMOR,DIALOG_STYLE_LIST,"Броня","50%\n100%\n150%","Далее","Отмена"); return 1;
    }
    if(dialogid == D_ARMOR)
    {
        new lobby = gPlayerLobby[playerid]; if(lobby == INVALID_LOBBY) return 1;
        gLobbyArmor[lobby] = (listitem == 0) ? 50 : ((listitem == 1) ? 100 : 150);
        ShowPlayerDialog(playerid,D_WEAPON,DIALOG_STYLE_LIST,"Оружие","Desert Eagle\nShotgun\nMP5\nM4\nSniper Rifle","Далее","Отмена"); return 1;
    }
    if(dialogid == D_WEAPON)
    {
        new lobby = gPlayerLobby[playerid]; if(lobby == INVALID_LOBBY) return 1;
        gLobbyWeapon[lobby] = listitem;
        ShowPlayerDialog(playerid,D_MAIN+4,DIALOG_STYLE_LIST,"Противник","Человек (матчмейкинг)\nAI-бот (двигается и атакует)","Создать","Назад"); return 1;
    }
    if(dialogid == D_MAIN+4)
    {
        new lobby = gPlayerLobby[playerid]; if(lobby == INVALID_LOBBY) return 1;
        gLobbyBots[lobby] = listitem;
        new msg[144]; format(msg,sizeof msg,"Лобби создано: %s | броня %d%% | %s. Ищи соперника через /join.",gMapNames[gLobbyMap[lobby]],gLobbyArmor[lobby],gWeaponNames[gLobbyWeapon[lobby]]);
        SendClientMessage(playerid,0x43D9FFFF,msg);
        if(gLobbyBots[lobby]) StartBotBattle(playerid,lobby);
        return 1;
    }
    return 0;
}

FindFreeLobby()
{
    for(new i; i < MAX_LOBBIES; i++) if(gLobbyState[i] == 0) return i;
    return INVALID_LOBBY;
}

JoinLobby(playerid)
{
    if(gPlayerLobby[playerid] != INVALID_LOBBY) return SendClientMessage(playerid,0xFFAA55FF,"Сначала покинь текущее лобби: /leave"),1;
    for(new i; i < MAX_LOBBIES; i++)
    {
        if(gLobbyState[i] == 1 && !gLobbyBots[i] && gLobbyOwner[i] != playerid && IsPlayerConnected(gLobbyOwner[i]))
        {
            gPlayerLobby[playerid] = i; gLobbyOpponent[i] = playerid; gLobbyState[i] = 2;
            SendClientMessage(playerid,0x43D9FFFF,"Соперник найден. Бой начинается!");
            SendClientMessage(gLobbyOwner[i],0x43D9FFFF,"Соперник найден. Бой начинается!");
            StartBattle(gLobbyOwner[i],playerid,i); return 1;
        }
    }
    SendClientMessage(playerid,0xB8DFFFFF,"Открытых лобби нет. Создай своё через /arena."); return 1;
}

StartBattle(p1,p2,lobby)
{
    new m = gLobbyMap[lobby], Float:armor = float(gLobbyArmor[lobby]);
    gBattleMap[p1] = m; gBattleMap[p2] = m;
    SetPlayerInterior(p1,0); SetPlayerInterior(p2,0);
    SetPlayerVirtualWorld(p1, lobby+1); SetPlayerVirtualWorld(p2,lobby+1);
    SetPlayerPos(p1,gSpawnA[m][0],gSpawnA[m][1],gSpawnA[m][2]); SetPlayerFacingAngle(p1,gSpawnA[m][3]);
    SetPlayerPos(p2,gSpawnB[m][0],gSpawnB[m][1],gSpawnB[m][2]); SetPlayerFacingAngle(p2,gSpawnB[m][3]);
    ResetPlayerWeapons(p1); ResetPlayerWeapons(p2);
    GivePlayerWeapon(p1,gWeapons[gLobbyWeapon[lobby]],250); GivePlayerWeapon(p2,gWeapons[gLobbyWeapon[lobby]],250);
    SetPlayerArmour(p1,armor); SetPlayerArmour(p2,armor);
    CreateArenaMap(m,p1,p2);
    TogglePlayerControllable(p1,0); TogglePlayerControllable(p2,0);
    GameTextForPlayer(p1,"~b~3",1000,3); GameTextForPlayer(p2,"~b~3",1000,3);
    SetTimerEx("UnlockBattle",3000,false,"iii",p1,p2,lobby);
}

forward UnlockBattle(p1,p2,lobby);
public UnlockBattle(p1,p2,lobby)
{
    if(IsPlayerConnected(p1)) { TogglePlayerControllable(p1,1); GameTextForPlayer(p1,"~g~FIGHT!",1500,3); }
    if(IsPlayerConnected(p2)) { TogglePlayerControllable(p2,1); GameTextForPlayer(p2,"~g~FIGHT!",1500,3); }
    return 1;
}

StartBotBattle(playerid,lobby)
{
    new m = gLobbyMap[lobby];
    gLobbyState[lobby] = 3;
    gBattleMap[playerid] = m;
    SetPlayerInterior(playerid,0); SetPlayerVirtualWorld(playerid,lobby+1);
    SetPlayerPos(playerid,gSpawnA[m][0],gSpawnA[m][1],gSpawnA[m][2]);
    SetPlayerFacingAngle(playerid,gSpawnA[m][3]);
    ResetPlayerWeapons(playerid); GivePlayerWeapon(playerid,gWeapons[gLobbyWeapon[lobby]],250);
    SetPlayerArmour(playerid,float(gLobbyArmor[lobby]));
    gBotActor[lobby] = CreateActor(29,gSpawnB[m][0],gSpawnB[m][1],gSpawnB[m][2],gSpawnB[m][3]);
    SetActorVirtualWorld(gBotActor[lobby],lobby+1);
    SetActorHealth(gBotActor[lobby],100.0); SetActorInvulnerable(gBotActor[lobby],false);
    ApplyActorAnimation(gBotActor[lobby],"PED","WALK_civi",4.0,1,1,1,0,0);
    gBotHealth[lobby] = 100; gBotLastHit[lobby] = GetTickCount();
    CreateArenaMap(m,playerid,playerid);
    TogglePlayerControllable(playerid,0);
    GameTextForPlayer(playerid,"~b~AI CHALLENGER ~w~| ~y~3",1800,3);
    SetTimerEx("UnlockSoloBattle",3000,false,"ii",playerid,lobby);
}

forward UnlockSoloBattle(playerid,lobby);
public UnlockSoloBattle(playerid,lobby)
{
    if(IsPlayerConnected(playerid) && gLobbyState[lobby] == 3)
    { TogglePlayerControllable(playerid,1); GameTextForPlayer(playerid,"~g~FIGHT!",1500,3); }
    return 1;
}

forward ArenaBotThink();
public ArenaBotThink()
{
    new Float:px,Float:py,Float:pz,Float:bx,Float:by,Float:bz,Float:dx,Float:dy,Float:dist,Float:step;
    for(new l; l < MAX_LOBBIES; l++)
    {
        if(gLobbyState[l] != 3 || gBotActor[l] == INVALID_ACTOR_ID) continue;
        new playerid = gLobbyOwner[l];
        if(!IsPlayerConnected(playerid)) { DestroyActor(gBotActor[l]); gBotActor[l]=INVALID_ACTOR_ID; gLobbyState[l]=0; continue; }
        GetPlayerPos(playerid,px,py,pz); GetActorPos(gBotActor[l],bx,by,bz);
        dx=px-bx; dy=py-by; dist=floatsqroot(dx*dx+dy*dy);
        if(dist > 1.9)
        {
            step = (dist > 6.0) ? 0.85 : 0.35;
            SetActorPos(gBotActor[l],bx+(dx/dist)*step,by+(dy/dist)*step,bz);
            SetActorFacingAngle(gBotActor[l],atan2(-dx,dy)*57.2957795);
            if(GetTickCount()-gBotLastHit[l] > 500) ApplyActorAnimation(gBotActor[l],"PED","WALK_civi",4.0,1,1,1,0,0);
        }
        if(dist < 9.0 && GetTickCount()-gBotLastHit[l] > 1150)
        {
            new Float:hp,Float:armour,Float:dmg=7.0;
            GetPlayerHealth(playerid,hp); GetPlayerArmour(playerid,armour);
            if(armour > 0.0) SetPlayerArmour(playerid,(armour > dmg) ? armour-dmg : 0.0);
            else SetPlayerHealth(playerid,(hp > dmg) ? hp-dmg : 0.0);
            gBotLastHit[l]=GetTickCount();
            ApplyActorAnimation(gBotActor[l],"PED","FIGHTA_1",4.0,0,0,0,0,350);
        }
    }
    return 1;
}

public OnPlayerGiveDamageActor(playerid,damaged_actorid,Float:amount,weaponid,bodypart)
{
    for(new l; l < MAX_LOBBIES; l++)
    {
        if(gLobbyState[l] == 3 && gBotActor[l] == damaged_actorid && gLobbyOwner[l] == playerid)
        {
            gBotHealth[l] -= floatround(amount);
            if(gBotHealth[l] <= 0)
            {
                SendClientMessage(playerid,0x66FFCCFF,"AI повержен! Победа за тобой.");
                DestroyActor(gBotActor[l]); gBotActor[l]=INVALID_ACTOR_ID; gLobbyState[l]=0;
                gPlayerLobby[playerid]=INVALID_LOBBY; gBattleMap[playerid]=-1; ClearArenaObjects(playerid);
                SetPlayerVirtualWorld(playerid,0); SetPlayerPos(playerid,1754.1,-1894.2,13.6); ResetPlayerWeapons(playerid);
            }
            break;
        }
    }
    return 1;
}

CreateArenaMap(map,p1,p2)
{
    // Player-objects ограничены участниками конкретного virtual world/боя.
    new Float:x = gSpawnA[map][0], Float:y = gSpawnA[map][1], Float:z = gSpawnA[map][2];
    for(new side; side < ((p1 == p2) ? 1 : 2); side++)
    {
        new p = (side == 0) ? p1 : p2;
        ClearArenaObjects(p);
        ArenaCreateObject(p,19446,x+12.0,y,z+1.0,0.0,0.0,0.0,220.0);
        ArenaCreateObject(p,19446,x-12.0,y,z+1.0,0.0,0.0,0.0,220.0);
        ArenaCreateObject(p,19446,x,y+12.0,z+1.0,0.0,0.0,90.0,220.0);
        ArenaCreateObject(p,19446,x,y-12.0,z+1.0,0.0,0.0,90.0,220.0);
        ArenaCreateObject(p,1459,x+4.0,y+2.0,z,0.0,0.0,20.0,220.0);
        ArenaCreateObject(p,1459,x-4.0,y-2.0,z,0.0,0.0,160.0,220.0);
        ArenaCreateObject(p,3374,x+1.0,y+5.0,z,0.0,0.0,0.0,220.0);
        ArenaCreateObject(p,3374,x-1.0,y-5.0,z,0.0,0.0,0.0,220.0);
        if(map == 0) {
            ArenaCreateObject(p,1459,x+7.0,y-4.0,z,0.0,0.0,90.0,220.0);
            ArenaCreateObject(p,1459,x-7.0,y+4.0,z,0.0,0.0,90.0,220.0);
        } else if(map == 1) {
            ArenaCreateObject(p,3374,x+7.0,y+7.0,z,0.0,0.0,45.0,220.0);
            ArenaCreateObject(p,3374,x-7.0,y-7.0,z,0.0,0.0,45.0,220.0);
        } else if(map == 2) {
            ArenaCreateObject(p,1459,x+7.0,y+7.0,z,0.0,0.0,0.0,220.0);
            ArenaCreateObject(p,3374,x-7.0,y+7.0,z,0.0,0.0,0.0,220.0);
        } else if(map == 3) {
            ArenaCreateObject(p,3374,x+7.0,y-7.0,z,0.0,0.0,0.0,220.0);
            ArenaCreateObject(p,1459,x-7.0,y-7.0,z,0.0,0.0,0.0,220.0);
        } else {
            ArenaCreateObject(p,1459,x+7.0,y,z,0.0,0.0,45.0,220.0);
            ArenaCreateObject(p,3374,x-7.0,y,z,0.0,0.0,45.0,220.0);
        }
    }
}

ArenaCreateObject(playerid,modelid,Float:x,Float:y,Float:z,Float:rx,Float:ry,Float:rz,Float:drawdistance)
{
    new objectid = CreatePlayerObject(playerid,modelid,x,y,z,rx,ry,rz,drawdistance);
    if(gArenaObjectCount[playerid] < MAX_ARENA_OBJECTS)
        gArenaObjects[playerid][gArenaObjectCount[playerid]++] = objectid;
    else DestroyPlayerObject(playerid,objectid);
    return objectid;
}

ClearArenaObjects(playerid)
{
    for(new i; i < gArenaObjectCount[playerid]; i++) DestroyPlayerObject(playerid,gArenaObjects[playerid][i]);
    gArenaObjectCount[playerid] = 0;
}

LeaveLobby(playerid)
{
    new l = gPlayerLobby[playerid]; if(l == INVALID_LOBBY) return SendClientMessage(playerid,0xB8DFFFFF,"Ты не в лобби."),1;
    if(gLobbyState[l] == 3)
    {
        if(gBotActor[l] != INVALID_ACTOR_ID) DestroyActor(gBotActor[l]);
        gBotActor[l] = INVALID_ACTOR_ID; gLobbyState[l] = 0; gLobbyOwner[l] = INVALID_PLAYER_ID;
    }
    if(gLobbyState[l] == 2)
    {
        new other = (gLobbyOwner[l] == playerid) ? gLobbyOpponent[l] : gLobbyOwner[l];
        if(IsPlayerConnected(other)) { gPlayerLobby[other] = INVALID_LOBBY; ClearArenaObjects(other); SetPlayerVirtualWorld(other,0); SetPlayerPos(other,1754.1,-1894.2,13.6); ResetPlayerWeapons(other); SendClientMessage(other,0xFFAA55FF,"Соперник покинул бой."); }
    }
    if(gLobbyOwner[l] == playerid || gLobbyState[l] == 2) { gLobbyState[l] = 0; gLobbyOwner[l] = INVALID_PLAYER_ID; gLobbyOpponent[l] = INVALID_PLAYER_ID; }
    gPlayerLobby[playerid] = INVALID_LOBBY; gBattleMap[playerid] = -1; ClearArenaObjects(playerid); SetPlayerVirtualWorld(playerid,0); SetPlayerPos(playerid,1754.1,-1894.2,13.6); ResetPlayerWeapons(playerid); SendClientMessage(playerid,0x43D9FFFF,"Ты вышел из лобби и возвращён на вокзал."); return 1;
}

public OnPlayerDeath(playerid,killerid,reason)
{
    new l = gPlayerLobby[playerid];
    if(l != INVALID_LOBBY && gLobbyState[l] == 3)
    {
        SendClientMessage(playerid,0xFFAA55FF,"AI победил. Попробуй ещё раз через /arena.");
        LeaveLobby(playerid);
    }
    else if(l != INVALID_LOBBY && gLobbyState[l] == 2)
    {
        new winner = (killerid != INVALID_PLAYER_ID) ? killerid : gLobbyOpponent[l];
        if(winner == playerid) winner = gLobbyOwner[l];
        if(IsPlayerConnected(winner)) SendClientMessage(winner,0x43D9FFFF,"Победа! Используй /arena для нового боя.");
        LeaveLobby(playerid);
    }
    return 1;
}

public OnPlayerDisconnect(playerid,reason)
{
    #if defined ARENA_WITH_CEF
        cef_on_player_disconnect(playerid);
    #endif
    if(gPlayerLobby[playerid] != INVALID_LOBBY) LeaveLobby(playerid);
    return 1;
}
