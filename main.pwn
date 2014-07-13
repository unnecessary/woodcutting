#include <a_samp>
#include <streamer>
#include <progress>
#include <zcmd>
#include <sscanf2>

#define MAX_TREES   100

enum TreeInfo
{
    ID,
    Obj, // store object in this

    Type,
    Model,
    Float: Health,

    Float: xPos,
    Float: yPos,
    Float: zPos,

    Float: rxPos,
    Float: ryPos,
    Float: rzPos,
}

new tInfo[MAX_TREES][TreeInfo];
new tCount;


// Tree System Variables:
new pChoppingTree[MAX_PLAYERS];
new ChoppingProgress[MAX_PLAYERS];
new PlayerBar:ChoppingBar[MAX_PLAYERS];
new TreeHealthUpdater[MAX_PLAYERS];
new pWood[MAX_PLAYERS];


main() LoadTrees();


public OnGameModeExit()
{
    SaveTrees();
    
    return true;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_YES)
    {
        return cmd_cuttree(playerid);
    }

    if(newkeys & KEY_NO)
    {
        ChoppingProgress[playerid] = 0;
        KillTimer(TreeHealthUpdater[playerid]);

        HidePlayerProgressBar(playerid, ChoppingBar[playerid]);
        TogglePlayerControllable(playerid, true);
    }

    return true;
}


// TREE SYSTEM

CMD:planttree(playerid, params[])
{
    new type, health, randobj, Float: X, Float: Y, Float: Z;
    GetPlayerPos(playerid, X, Y, Z);

    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xDEDEDEFF, "You're not an administrator!");
    if(sscanf(params, "ii", type, health)) return SendClientMessage(playerid, 0x783800FF, "/planttree [type] [health]");

    if(type == 1)
    {
        switch(random(5))
        {
            case 0: randobj = 661;
            case 1: randobj = 657;
            case 2: randobj = 654;
            case 3: randobj = 655;
            case 4: randobj = 656;
        }
    }

    else if(type == 2)
    {
        switch(random(5))
        {
            case 0: randobj = 615;
            case 1: randobj = 616;
            case 2: randobj = 617;
            case 3: randobj = 618;
            case 4: randobj = 700;
        }
    }

    tInfo[tCount][Obj] = CreateDynamicObject(randobj, X +1, Y +1, Z -1, 0.0, 0.0, 0.0);
    EditObject(playerid, tInfo[tCount][Obj]);

    new INI:File = INI_Open(TreePath(tCount));
    INI_SetTag(File, "Tree Data");

    INI_WriteInt(File, "Model", randobj);
    tInfo[tCount][Model] = randobj;

    INI_WriteInt(File, "Type", type);
    tInfo[tCount][Type] = type;

    INI_WriteFloat(File, "Health", health);
    tInfo[tCount][Health] = health;

    INI_WriteFloat(File, "xPos", X);
    tInfo[tCount][xPos] = X;

    INI_WriteFloat(File, "yPos", Y);
    tInfo[tCount][yPos] = Y;

    INI_WriteFloat(File, "zPos", Z);
    tInfo[tCount][zPos] = Z;

    INI_WriteFloat(File, "rxPos", 0.0);
    INI_WriteFloat(File, "ryPos", 0.0);
    INI_WriteFloat(File, "rzPos", 0.0);

    INI_Close(File);
    tCount ++;

    SendClientMessage(playerid, 0xA3A3A3FF, "Please move this tree to a realistic, appropiate position.");

    return true;
}

CMD:deletetree(playerid, params[])
{
    new tid, string[40];

    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "You need to be an admin in order to do this command!") ;
    if(sscanf(params, "i", tid)) return SendClientMessage(playerid, -1, "/deletetree [hid]");

    format(string, sizeof(string), "Trees/%d.ini", tid);

    if(!fexist(string)) return SendClientMessage(playerid, -1, "The tree ID you entered doesn't exist.");

    else if(fexist(string))
    {
        DestroyDynamicObject(tInfo[tid][Obj]);
        tCount --;
        
        fremove(string);
    }
    
    format(string, sizeof(string), "You have deleted tree ID: %d", tid);
    SendClientMessage(playerid, 0xA3A3A3FF, string);

    return true;
}

CMD:gototree(playerid, params[])
{
    new treeid, string[60];

    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xDEDEDEFF, "You're not an administrator!");
    if(sscanf(params, "i", treeid)) return SendClientMessage(playerid, 0xDEDEDEFF, "/gototree [id]");
    if(!IsValidDynamicObject(treeid)) return SendClientMessage(playerid, 0xDEDEDEFF, "That tree doesn't exist!");

    format(string, sizeof(string), "You have been warped near tree ID %d.", treeid);
    SendClientMessage(playerid, 0xA3A3A3FF, string);

    SetPlayerPos(playerid, tInfo[treeid][xPos] +1, tInfo[treeid][yPos] +1, tInfo[treeid][zPos]);

    return true;
}

CMD:neartree(playerid, params[])
{
    new string[30];

    format(string, sizeof(string), "You're not near a tree!");

    for(new i; i < MAX_TREES; i ++)
    {
        if(IsPlayerInRangeOfPoint(playerid, 3.0, tInfo[i][xPos], tInfo[i][yPos], tInfo[i][zPos]))
        {
            format(string, sizeof(string), "You're near tree ID %d.", i);
        }
    }

    SendClientMessage(playerid, 0xA3A3A3FF, string);

    return true;
}

CMD:deathtrees(playerid, params[])
{
    new string[80];

    SendClientMessage(playerid, 0xDEDEDEFF, "Damaged Trees");

    for(new i; i < MAX_TREES; i ++)
    {
        if(tInfo[i][Health] < 10.0)
        {
            format(string, sizeof(string), "Tree ID: %d, health: %f", i, tInfo[i][Health]);
            SendClientMessage(playerid, 0xA3A3A3FF, string);
        }
    }

    return true;
}

CMD:cuttree(playerid)
{
    new string[90];

    format(string, sizeof(string), "You're not near a tree!");

    for(new i; i < MAX_TREES; i ++)
    {
        if(IsPlayerInRangeOfPoint(playerid, 1.0, tInfo[i][xPos], tInfo[i][yPos], tInfo[i][zPos]))
        {
            if(tInfo[i][Health] <= 0) return SendClientMessage(playerid, 0xA3A3A3FF, "This tree has already been cut down!");

            pChoppingTree[playerid] = i;

            ChoppingBar[playerid] = CreatePlayerProgressBar(playerid, 220.0, 350.0, 90.0, 6.0, 0x783800FF, 100.0);
            ShowPlayerProgressBar(playerid, ChoppingBar[playerid]);

            SetPlayerProgressBarMaxValue(playerid, ChoppingBar[playerid], 100);
            TreeHealthUpdater[playerid] = SetTimerEx("TreeCutDownBar", 1000, true, "i", playerid);

            format(string, sizeof(string), "You have started to chop down tree ID %d. Press ~k~~CONVERSATION_NO~ to cancel!", i);
            TogglePlayerControllable(playerid, false);

            break;
        }
    }

    SendClientMessage(playerid, 0xA3A3A3FF, string);

    return true;
}

stock ResetTree(treeid)
{
    DestroyDynamicObject(tInfo[treeid][Obj]);
    tInfo[treeid][Obj] = CreateDynamicObject(832, tInfo[treeid][xPos], tInfo[treeid][yPos], tInfo[treeid][zPos], tInfo[treeid][rxPos], tInfo[treeid][ryPos], tInfo[treeid][rzPos]);

    SetTimerEx("RegrowDeadTrees", 1200000, false, "i", treeid);

    printf("Tree %d has been replaced with a stump.", treeid);

    return true;
}

forward RegrowDeadTrees(treeid);
public RegrowDeadTrees(treeid)
{
    if(tInfo[treeid][Health] == 0)
    {
        DestroyDynamicObject(tInfo[treeid][Obj]);
        tInfo[treeid][Obj] = CreateDynamicObject(tInfo[treeid][Model], tInfo[treeid][xPos], tInfo[treeid][yPos], tInfo[treeid][zPos], tInfo[treeid][rxPos], tInfo[treeid][ryPos], tInfo[treeid][rzPos]);

        printf("Tree %d has regrown and set to 100.0 health.", treeid);
        tInfo[treeid][Health] = 100;
    }

    return true;
}

forward TreeCutDownBar(playerid);
public TreeCutDownBar(playerid)
{
    if(GetPlayerProgressBarValue(playerid, ChoppingBar[playerid]) == 100)
    {
        ChoppingProgress[playerid] = 0;
        tInfo[pChoppingTree[playerid]][Health] = 0;

        HidePlayerProgressBar(playerid, ChoppingBar[playerid]);
        TogglePlayerControllable(playerid, true);

        KillTimer(TreeHealthUpdater[playerid]);
        ResetTree(pChoppingTree[playerid]);
        
        RandomTreeLoot(playerid);

        return true; // close loop
    }

    ChoppingProgress[playerid] += 10;
    tInfo[pChoppingTree[playerid]][Health] -= 10;

    SetPlayerProgressBarValue(playerid, ChoppingBar[playerid], ChoppingProgress[playerid]);
    UpdatePlayerProgressBar(playerid, ChoppingBar[playerid]);

    return true;
}

stock TreePath(treeid)
{
    new tree[64];

    format(tree, 30, "Trees/%d.ini", treeid);
    tInfo[treeid][ID] ++; // multiplying

    return tree;
}

forward LoadTreeData(i, name[], value[]);
public LoadTreeData(i, name[], value[])
{
    INI_Int("Type", tInfo[i][Type]);
    INI_Int("Model", tInfo[i][Model]);
    INI_Float("Health", tInfo[i][Health]);

    INI_Float("xPos", tInfo[i][xPos]);
    INI_Float("yPos", tInfo[i][yPos]);
    INI_Float("zPos", tInfo[i][zPos]);

    INI_Float("rxPos", tInfo[i][rxPos]);
    INI_Float("ryPos", tInfo[i][ryPos]);
    INI_Float("rzPos", tInfo[i][rzPos]);

    return true;
}

stock SaveTrees()
{
    new file[64];

    for(new i; i < MAX_TREES; i ++)
    {
        format(file, sizeof(file), "Trees/%d.ini", i);

        if(fexist(file))
        {
            new INI:File = INI_Open(file);

            INI_SetTag(File, "Tree Data");

            INI_WriteInt(File, "Type", tInfo[i][Type]);
            INI_WriteInt(File, "Model", tInfo[i][Model]);
            INI_WriteFloat(File, "Health", tInfo[i][Health]);

            INI_WriteFloat(File, "xPos", tInfo[i][xPos]);
            INI_WriteFloat(File, "yPos", tInfo[i][yPos]);
            INI_WriteFloat(File, "zPos", tInfo[i][zPos]);

            INI_WriteFloat(File, "rxPos", tInfo[i][rxPos]);
            INI_WriteFloat(File, "ryPos", tInfo[i][ryPos]);
            INI_WriteFloat(File, "rzPos", tInfo[i][rzPos]);

            INI_Close(File);
        }
    }

    return true;
}

stock LoadTrees()
{
    new string[128], file[64];

    print("\n  Loading Trees: \n");

    for(new i; i < MAX_TREES; i ++)
    {
        format(file, sizeof(file), "Trees/%d.ini", i);

        if(fexist(file))
        {
            INI_ParseFile(TreePath(i), "LoadTreeData", false, true, i, true, false);

            tInfo[i][Obj] = CreateDynamicObject(tInfo[i][Model], tInfo[i][xPos], tInfo[i][yPos], tInfo[i][zPos] -1, tInfo[i][rxPos], tInfo[i][ryPos], tInfo[i][rzPos]);
            format(string, sizeof(string), "  Loaded tree ID: %d at %f %f %f with rot: %f %f %f", i, tInfo[i][xPos], tInfo[i][yPos], tInfo[i][zPos], tInfo[i][rxPos], tInfo[i][ryPos], tInfo[i][rzPos]);

            if(tInfo[i][Health] == 0)
            {
                ResetTree(i);
                printf("Tree ID %d was loaded with %f health, and has been reset.\n", i, tInfo[i][Health]);
            }

            print(string);
            tCount ++;
        }
    }

    printf("\n  %d trees loaded!", tCount);

    return true;
}

public OnPlayerEditObject(playerid, playerobject, objectid, response, Float: fX, Float: fY, Float: fZ, Float: fRotX, Float: fRotY, Float: fRotZ)
{
    if(response == EDIT_RESPONSE_FINAL)
    {
        SetObjectPos(objectid, fX, fY, fZ);
        SetObjectRot(objectid, fRotX, fRotY, fRotZ);

        tInfo[objectid][xPos] = fX;
        tInfo[objectid][yPos] = fY;
        tInfo[objectid][zPos] = fZ;

        tInfo[objectid][rxPos] = fRotX;
        tInfo[objectid][ryPos] = fRotY;
        tInfo[objectid][rzPos] = fRotZ;
    }

    return true;
}
