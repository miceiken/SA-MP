#include <a_samp>
#include <dini>
#include <dutils>
#include <sscanf2>

/*
	Defines
--------------------------------*/

#define VERSION						"0.1a"

#define INFINITY (Float:0x7F800000)

#define FOLDER_USERS                "users/"
#define FOLDER_PROPS                "props/"

#define dcmd(%1,%2,%3) if (!strcmp((%3)[1], #%1, true, (%2)) && ((((%3)[(%2) + 1] == '\0') && (dcmd_%1(playerid, ""))) || (((%3)[(%2) + 1] == ' ') && (dcmd_%1(playerid, (%3)[(%2) + 2]))))) return 1

#define DIALOG_REGISTER     		3001
#define DIALOG_CONFIRMREGISTER      3002
#define DIALOG_LOGIN        		3003
#define DIALOG_SHOP                 3004
#define DIALOG_BANK                 3005
#define DIALOG_BANK_WITHDRAW        3006
#define DIALOG_BANK_DEPOSIT         3007

#define COLOR_RED					0xFF4040FF
#define COLOR_GREEN					0x40FF40FF
#define COLOR_BLUE					0x4040FFFF
#define COLOR_CYAN					0x40FFFFFF
#define COLOR_PINK					0xFF40FFFF
#define COLOR_YELLOW				0xFFFF40FF
#define COLOR_WHITE					0xFFFFFFFF
#define COLOR_BLACK					0x000000FF
#define COLOR_NONE					0x00000000
#define COLOR_ACTION                0xEE66EEFF
#define COLOR_STATUS                0xFFFFFFAA
#define COLOR_GRAD1					0xB4B5B7FF
#define COLOR_GRAD2					0xBFC0C2FF
#define COLOR_GRAD3					0xCBCCCEFF
#define COLOR_GRAD4					0xD8D8D8FF
#define COLOR_GRAD5					0xE3E3E3FF
#define COLOR_GRAD6					0xF0F0F0FF

/*
	Global variables
--------------------------------*/
#define TEAM_NONE       0
#define TEAM_COPS   	1
#define TEAM_ROBBERS    2

new CopSkins[] = { 280, 281, 282, 283, 288, 284, 285, 286, 287 };

new RobberSkins[] =
{
	102, 103, 104, 100, 247, 248, 254, 121, 122, 123,
	105, 106, 107, 114, 115, 116, 108, 109, 110, 173,
	174, 175, 111, 112, 113, 124, 125, 126, 127, 117,
	118, 120
};

new IsOOCEnabled = true;

enum pInfo
{
	// Account
	// len 'users/' = 6
	pName[6 + MAX_PLAYER_NAME],
	// len 'users/' = 6, len '.ini' = 4
	pFName[6 + MAX_PLAYER_NAME + 4],
	pBanned,
	pAdmin,
	pLoggedIn,
	pLoginAttempts,
	pCallTicks,
	
	// RPG
	pHouse,
	pTeam,
	pSkin,
	pKills,
	pDeaths,
	pBank,
	pPhonenumber,
	
	// States
	pMuted,
	pCalling,
	pCalledBy,
	pSpectating
};
new PlayerInfo[MAX_PLAYERS][pInfo];

new EmptyPlayer[pInfo] =
{
	"",					/*pName*/
	"",					/*pFName*/
	0,					/*pBanned*/
	0,					/*pAdmin*/
	0,					/*pLoggedIn*/
	0,					/*pLoginAttempts*/
	0,					/*pCallTicks*/
	
	-1,					/*pHouse*/
	0,					/*pTeam*/
	0,					/*pSkin*/
	0,					/*pKills*/
	0,					/*pDeaths*/
	0,					/*pBank*/
	0,					/*pPhonenumber*/
	
	0,					/*pMuted*/
	INVALID_PLAYER_ID,	/*pCalling*/
	INVALID_PLAYER_ID,	/*pCalledBy*/
	INVALID_PLAYER_ID,	/*pSpectating*/
};

enum pInventory
{
	pCellphone,
	pPhonebook
}
new PlayerInventory[MAX_PLAYERS][pInventory];

new EmptyInventory[pInventory] = { 0, 0 };

new Float:SpectateInfo[MAX_PLAYERS][3];
new Text:PTextDraws[6];
new Text:PInfo[MAX_PLAYERS];

new Fuel[MAX_VEHICLES];

new Text:tSpeedo[MAX_PLAYERS];
new Text:tFuel[MAX_PLAYERS];
new Text:tClassSelect[MAX_PLAYERS];

new Text:tTimeDisplay;

new aVehicleNames[][] =
{
	"Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel",
	"Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus",
	"Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam",
	"Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection",
	"Hunter", "Premier", "Enforcer", "Securicar", "Banshee", "Predator", "Bus",
	"Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie",
	"Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral",
	"Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder",
	"Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair", "Berkley's RC Van",
	"Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale",
	"Oceanic","Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy",
	"Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX",
	"Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick", "News Chopper",
	"Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking",
	"Blista Compact", "Police Maverick", "Boxvillde", "Benson", "Mesa", "RC Goblin",
	"Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT",
	"Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster", "Stunt",
	"Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra",
	"FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune",
	"Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer",
	"Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex", "Vincent",
	"Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo",
	"Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite",
	"Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratium",
	"Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito",
	"Freight Flat", "Streak Carriage", "Kart", "Mower", "Dune", "Sweeper",
	"Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400",
	"News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
	"Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car",
	"Police Car", "Police Car", "Police Ranger", "Picador", "S.W.A.T", "Alpha",
	"Phoenix", "Glendale", "Sadler", "Luggage", "Luggage", "Stairs", "Boxville",
	"Tiller", "Utility Trailer"
};

/*
	Property stuff
--------------------------------*/

#define MAX_INTERIORS	146
#define MAX_PROPERTIES 1000

#define MAX_PTYPES		4
#define PTYPE_EMPTY		0
#define PTYPE_PROPERTY	1
#define PTYPE_BUSINESS	2
#define PTYPE_GOVERMENT	3

new PropertyFiles[MAX_PTYPES][64] =
{
	{ "blank" },
	{ "props/properties.ini" },
	{ "props/businesses.ini" },
	{ "props/goverment.ini" }
};

new PropertyPickups[MAX_PROPERTIES] = {-1};
new Text3D:PropertyInfo[MAX_PROPERTIES];

enum eProperties
{
	eInterior,
	ePickup,
	eIcon,
	eName[64],
	eType,
	eVWorld,
	eOwner[MAX_PLAYER_NAME],
	ePrice,
	eRent,
	Float:eEntX,
	Float:eEntY,
	Float:eEntZ,
	Float:eEntA,
	Float:eExitX,
	Float:eExitY,
	Float:eExitZ,
	Float:eExitA,
};
new Properties[MAX_PROPERTIES][eProperties];

new LastPickup[MAX_PLAYERS] = {-1};
new CurrentProperty[MAX_PLAYERS] = {-1};

stock ReadProperties(filename[], &idx)
{
	new File:pFile = fopen(filename);
	if (pFile)
	{
	    new buffer[256], props = 0;
	    while (fread(pFile, buffer) > 0)
	    {
	        if (sscanf(buffer, "p<,>e<iiis[64]iis[24]iiffffffff>", Properties[idx])) { printf("Property #%d has an invalid format", idx); }
	        else
			{
				printf("Cached property #%d: %s", idx, Properties[idx][eName]);
				props++;
			}
	        idx++;
	    }
	    printf("Read %d properties from %s", props, filename);
	}
	else { print("Could not open properties file"); }
	fclose(pFile);
}

stock LoadProperties()
{
	for (new i = 0; i < MAX_PROPERTIES; i++)
	{
		Properties[i][eType] = PTYPE_EMPTY;
	}
	
	new idx = 0;
	for (new i = 1; i < MAX_PTYPES; i++)
	{
	    ReadProperties(PropertyFiles[i], idx);
	}
	
	for (new i = 0; i < MAX_PROPERTIES; i++)
	{
        if (Properties[i][eType] != PTYPE_EMPTY)
        {
		    new id = CreatePickup(Properties[i][ePickup], 23, Properties[i][eEntX], Properties[i][eEntY], Properties[i][eEntZ], 0);
		    PropertyPickups[id] = i;

		    PropertyInfo[i] = Text3D:INVALID_3DTEXT_ID;
		    switch (Properties[i][eType]) // LabelText
		    {
		        case PTYPE_PROPERTY:
					PropertyInfo[i] = Create3DTextLabel("[Property]", 0x88EE88FF, Properties[i][eEntX], Properties[i][eEntY], Properties[i][eEntZ] + 0.75, 20.0, 0, 1);
					
		        case PTYPE_BUSINESS:
					PropertyInfo[i] = Create3DTextLabel("[Business]", 0xAAAAFFFF, Properties[i][eEntX], Properties[i][eEntY], Properties[i][eEntZ] + 0.75, 20.0, 0, 1);
					
		        case PTYPE_GOVERMENT:
		        {
		            new name[64];
		            format(name, sizeof(name), "[%s]", Properties[i][eName]);
					PropertyInfo[i] = Create3DTextLabel(name, 0xEEEE88FF, Properties[i][eEntX], Properties[i][eEntY], Properties[i][eEntZ] + 0.75, 20.0, 0, 1);
				}
		    }

			switch (Properties[i][eType]) // MapIcon
			{
			    case PTYPE_PROPERTY:
					Properties[i][eIcon] = 31;
			    case PTYPE_BUSINESS:
					Properties[i][eIcon] = 32;
		    }
	    }
	}
}

stock SaveProperties()
{
	new total = 0;
	for (new x = 1; x < MAX_PTYPES; x++)
	{
		new File:pFile = fopen(PropertyFiles[x], io_write);
		if (pFile)
		{
			new props = 0, output[512];
			for (new i = 0; i < MAX_PROPERTIES; i++)
			{
			    if (Properties[i][eType] == x)
			    {
			        format(output, sizeof(output), "%d, %d, %d, %s, %d, %d, %s, %d, %d, %f, %f, %f, %f, %f, %f, %f, %f\r\n",
			            Properties[i][eInterior], Properties[i][ePickup], Properties[i][eIcon], Properties[i][eName], Properties[i][eType], Properties[i][eVWorld], Properties[i][eOwner], Properties[i][ePrice], Properties[i][eRent],
			            Properties[i][eEntX], Properties[i][eEntY], Properties[i][eEntZ], Properties[i][eEntA], Properties[i][eExitX], Properties[i][eExitY], Properties[i][eExitZ], Properties[i][eExitA]);
					fwrite(pFile, output);
			        props++;
			    }
			}
			fclose(pFile);
			total += props;
			printf("Wrote %d properties to %s", props, PropertyFiles[x]);
		}
		else { print("Can't open properties file"); }
	}
	printf("Saved %d properties", total);
}

stock PutPlayerInProperty(playerid, propid, vworld = 1)
{
	CurrentProperty[playerid] = propid;
	if (vworld) { SetPlayerVirtualWorld(playerid, propid); }
	SetPlayerInterior(playerid, Properties[propid][eInterior]);
	SetPlayerPos(playerid, Properties[propid][eExitX], Properties[propid][eExitY], Properties[propid][eExitZ]);
	SetPlayerFacingAngle(playerid, Properties[propid][eExitA]);
	if (!strcmp(Properties[propid][eName], "Ammunation")) SetPlayerShopName(playerid, "AMMUN1");
	new msg[128];
	format(msg, sizeof(msg),"* You have entered %s.", Properties[propid][eName]);
	SendClientMessage(playerid, COLOR_YELLOW, msg);
}

stock RemovePlayerFromProperty(playerid, propid = -1)
{
	if (propid != -1)
	{
	    propid = CurrentProperty[playerid];
	    if (!IsPlayerInRangeOfPoint(playerid, 4.5, Properties[propid][eExitX], Properties[propid][eExitY], Properties[propid][eExitZ]))
	    {
	        SendClientMessage(playerid, COLOR_RED, "* You need to be near the property exit.");
	        return;
	    }
	}
	
	SetPlayerVirtualWorld(playerid, 0);
	SetPlayerInterior(playerid, 0);
	SetPlayerPos(playerid, Properties[propid][eEntX], Properties[propid][eEntY], Properties[propid][eEntZ]);
	SetPlayerFacingAngle(playerid, Properties[propid][eEntA]);
	CurrentProperty[playerid] = -1;
}

stock LoadMapicons()
{
	for (new i = 0; i < sizeof(Properties); i++)
	{
	    if (Properties[i][eType] == PTYPE_GOVERMENT)
	    {
	    	CreateMapIcon(Properties[i][eIcon], 0, Properties[i][eEntX], Properties[i][eEntY], Properties[i][eEntZ]);
	    }
	}
	
	CreateMapIcon(5, 0, 1678.84, 1447.49, 10.77); // Airport
	
	InitMapIconStreaming();
}

/*
	Vehicle system
--------------------------------*/

#define MAX_VTYPES          11
#define VTYPE_EMPTY     	0
#define VTYPE_LV_GENERAL    1
#define VTYPE_LV_LAW        2
#define VTYPE_LV_AIRPORT    3
#define VTYPE_LS_GENERAL    4
#define VTYPE_LS_LAW        5
#define VTYPE_LS_AIPORT     6
#define VTYPE_SF_GENERAL    7
#define VTYPE_SF_LAW        8
#define VTYPE_SF_AIRPORT    9
#define VTYPE_OTHER         10

enum eVehicles
{
	eModelId,
	Float:eX,
	Float:eY,
	Float:eZ,
	Float:eA,
	eColor1,
	eColor2,
};
new Vehicles[MAX_VEHICLES][eVehicles];
new VehicleType[MAX_VEHICLES];

new VehiclesFiles[MAX_VTYPES][64] =
{
	{ "blank" },
	{ "vehs/lv/general.ini" },
	{ "vehs/lv/law.ini" },
	{ "vehs/lv/airport.ini" },
	{ "vehs/ls/general.ini" },
	{ "vehs/ls/law.ini" },
	{ "vehs/ls/airport.ini" },
	{ "vehs/sf/general.ini" },
	{ "vehs/sf/law.ini" },
	{ "vehs/sf/airport.ini" },
	{ "vehs/other.ini" }
};

stock LoadVehicles()
{
	for (new i = 0; i < MAX_VEHICLES; i++)
	{
		DestroyVehicle(i);
	}
	
	new idx = 0;
	for (new i = 1; i < MAX_VTYPES; i++)
	{
		new File:pFile = fopen(VehiclesFiles[i]);
		if (pFile)
		{
		    new buffer[256], vehs = 0;
		    while (fread(pFile, buffer) > 0)
		    {
		        if (sscanf(buffer, "p<,>e<iffffii>", Vehicles[idx])) { printf("Vehicle #%d has an invalid format", idx); }
		        else
				{
				    VehicleType[idx] = i;
					printf("Cached vehicle #%d: %s", idx, aVehicleNames[Vehicles[idx][eModelId] - 400]);
					vehs++;
				}
				idx++;
		    }
		    printf("Read %d vehicles from %s", vehs, VehiclesFiles[i]);
			fclose(pFile);
		}
		else { printf("Could not open %s", VehiclesFiles[i]); }
	}
	
	for (new x = 0; x < idx; x++)
	{
	    CreateVehicle(Vehicles[x][eModelId], Vehicles[x][eX], Vehicles[x][eY], Vehicles[x][eZ], Vehicles[x][eA], Vehicles[x][eColor1], Vehicles[x][eColor2], (30 * 60));
	}
}

stock SaveVehicles()
{
	for (new i = 1; i < MAX_VTYPES; i++)
	{
		new File:pFile = fopen(VehiclesFiles[i], io_write);
		if (pFile)
		{
			new output[512], vehs = 0;
			for (new x = 0; x < MAX_VEHICLES; x++)
			{
			    if (VehicleType[x] == i)
			    {
					format(output, sizeof(output), "%d, %f, %f, %f, %f, %d, %d\r\n",
					    Vehicles[x][eModelId], Vehicles[x][eX], Vehicles[x][eY], Vehicles[x][eZ], Vehicles[x][eA], Vehicles[x][eColor1], Vehicles[x][eColor2]);
					fwrite(pFile, output);
					vehs++;
				}
			}
			fclose(pFile);
			printf("Wrote %d vehicles to %s", vehs, VehiclesFiles[i]);
		}
		else { printf("Could not open %s", VehiclesFiles[i]); }
	}
}

/*
	Streaming stuff
--------------------------------*/

forward CheckpointStream();
public CheckpointStream()
{
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
	    if (IsPlayerConnected(i))
	    {
		    new closest = -1;
		    new Float:cdis = -1;
		    for (new x = 0; x < MAX_PROPERTIES; x++)
		    {
				new Float:X, Float:Y, Float:Z;
				GetPlayerPos(i, X, Y, Z);
		        new Float:distance = floatadd(floatadd(floatsqroot(floatpower(floatsub(X, Properties[x][eEntX]), 2)), floatsqroot(floatpower(floatsub(Y, Properties[x][eEntY]), 2))), floatsqroot(floatpower(floatsub(Z, Properties[x][eEntZ]), 2)));
		        if (closest == -1 || cdis < distance)
				{
					closest = x;
					cdis = distance;
				}
		    }
		    if (closest != -1) { SetPlayerCheckpoint(i, Properties[closest][eEntX], Properties[closest][eEntY], Properties[closest][eEntZ], 2.0); }
	    }
	}
}

#define MAX_ICONS 500
#define MAX_SLOTS 32
#define INVALID_SLOT -1
#define INVALID_ICON_ID -1
#define DISTANCE 400

new SlotIconID[MAX_PLAYERS][MAX_SLOTS];
new IconSlot[MAX_PLAYERS][MAX_ICONS];

enum iInfo
{
	Float:iPosX,
	Float:iPosY,
	Float:iPosZ,
	iModel,
	iColor,
	iActive
}
new IconInfo[MAX_ICONS][iInfo];

forward InitMapIconStreaming();
public InitMapIconStreaming()
{
 	for(new i=0;i<MAX_PLAYERS;i++)
 	{
	    for(new j=0;j<MAX_SLOTS;j++)
	        SlotIconID[i][j]=INVALID_ICON_ID;

		for(new j=0;j<MAX_ICONS;j++)
	        IconSlot[i][j]=INVALID_SLOT;
	}

	SetTimer("MapIconUpdate", 2000, true);
	return 1;
}

forward CreateMapIcon(modelid, color, Float:x, Float:y, Float:z);
public CreateMapIcon(modelid, color, Float:x, Float:y, Float:z)
{
	for(new i=0;i<MAX_ICONS;i++)
	{
		if(!IconInfo[i][iActive])
		{
			IconInfo[i][iPosX] = x;
			IconInfo[i][iPosY] = y;
			IconInfo[i][iPosZ] = z;
			IconInfo[i][iModel] = modelid;
			IconInfo[i][iColor] = color;
			IconInfo[i][iActive] = true;
			return i;
		}
	}
	print("[mapicon] Could not create map-icon!");
	return INVALID_ICON_ID;
}

forward DestroyMapIcon(id);
public DestroyMapIcon(id)
{
	if(!IconInfo[id][iActive]) return 0;

	new slot;
	IconInfo[id][iActive] = false;
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i))
	    {
	        slot = IconSlot[i][id];
			if(slot != INVALID_SLOT)
			{
			    RemovePlayerMapIcon(i, slot);
				SlotIconID[i][slot] = INVALID_ICON_ID;
			    IconSlot[i][id] = INVALID_SLOT;
			}
		}
	}
	return 1;
}

forward MapIconUpdate();
public MapIconUpdate()
{
	new id, oldid;
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		if (IsPlayerConnected(i))
		{
			for (new j = 0; j < MAX_SLOTS; j++)
			{
				oldid = SlotIconID[i][j];
				if (oldid != INVALID_ICON_ID)
				{
					if (GetDistanceToPoint(i, IconInfo[oldid][iPosX], IconInfo[oldid][iPosY], IconInfo[oldid][iPosZ]) > DISTANCE)
					{
						id = GetClosestUnusedMapIcon(i);
						if (id != INVALID_ICON_ID)
						{
							RemovePlayerMapIcon(i, j);
							IconSlot[i][oldid] = INVALID_SLOT;
							if (GetDistanceToPoint(i, IconInfo[id][iPosX], IconInfo[id][iPosY], IconInfo[id][iPosZ]) < DISTANCE)
							{
								SetPlayerMapIcon(i, j, IconInfo[id][iPosX], IconInfo[id][iPosY], IconInfo[id][iPosZ], IconInfo[id][iModel], IconInfo[id][iColor]);
								SlotIconID[i][j] = id;
								IconSlot[i][id] = j;
							}
							else SlotIconID[i][j] = INVALID_ICON_ID;
						}
					}
				}
				else
				{
					id = GetClosestUnusedMapIcon(i);
					if (id != INVALID_ICON_ID)
					{
						if (GetDistanceToPoint(i, IconInfo[id][iPosX], IconInfo[id][iPosY], IconInfo[id][iPosZ]) < DISTANCE)
						{
							SetPlayerMapIcon(i, j, IconInfo[id][iPosX], IconInfo[id][iPosY], IconInfo[id][iPosZ], IconInfo[id][iModel], IconInfo[id][iColor]);
							SlotIconID[i][j] = id;
							IconSlot[i][id] = j;
						}
					}
				}
			}
		}
	}
	return 1;
}

stock ResetMapIcons(playerid)
{
	new id;
	for(new i = 0; i < MAX_SLOTS; i++)
	{
		id = SlotIconID[playerid][i];
		if(id != INVALID_ICON_ID)
		{
		    RemovePlayerMapIcon(playerid, i);
		    SlotIconID[playerid][i] = INVALID_ICON_ID;
		    IconSlot[playerid][id] = INVALID_SLOT;
		}
	}
	return playerid;
}

stock GetClosestUnusedMapIcon(playerid)
{
	new dis = 50000, tmpdis, id = INVALID_ICON_ID;
	for(new i = 0;i < MAX_ICONS; i++)
	{
	    if(IconInfo[i][iActive] && IconSlot[playerid][i] == INVALID_SLOT)
		{
		    tmpdis = GetDistanceToPoint(playerid, IconInfo[i][iPosX], IconInfo[i][iPosY], IconInfo[i][iPosZ]);
		    if(tmpdis < dis)
		    {
		        id = i;
				dis = tmpdis;
		    }
		}
	}
	return id;
}

stock GetDistanceToPoint(playerid, Float:x, Float:y, Float:z)
{
	new Float:dis;
	new Float:x1, Float:y1, Float:z1;
	GetPlayerPos(playerid, x1, y1, z1);
	dis = floatsqroot(floatpower(floatabs(floatsub(x,x1)),2)+floatpower(floatabs(floatsub(y,y1)),2)+floatpower(floatabs(floatsub(z,z1)),2));
	return floatround(dis);
}

stock IsACopCar(vehicleid)
{
	switch(GetVehicleModel(vehicleid))
	{
		case 596..599, 427, 497, 523:
			return 1;
	}
	return 0;
}

/*
	main()
--------------------------------*/

main()
{
	print("\n\n-----------------------------------------");
	print("Sons of Anarchy - the battle of outlaws");
	printf("Loaded version %s", VERSION);
	print("-----------------------------------------\n\n");
}

//--------------------------------------------------

/*
	Custom functions
--------------------------------*/
forward MiscTimer();
public MiscTimer()
{
	new msg[128];
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
	    if (IsPlayerConnected(i))
	    {
	        if (PlayerInfo[i][pCalledBy] != INVALID_PLAYER_ID && PlayerInfo[i][pCalling] == INVALID_PLAYER_ID)
	        {
			    if (PlayerInfo[i][pCallTicks] > 0)
			    {
					if (PlayerInfo[i][pCallTicks] % 2)
					{
					    format(msg, sizeof(msg), "* %s's cellphone rings.", PlayerInfo[i][pName]);
					    ProxDetectorEx(20.0, i, msg, COLOR_ACTION);
					}
			        PlayerInfo[i][pCallTicks]--;
			    }
			    else
			    {
			        SendClientMessage(i, COLOR_ACTION, "Phone call timed out");
			        SendClientMessage(PlayerInfo[i][pCalledBy], COLOR_CYAN, "TELEPHONE COMPANY: The person you are calling cannot be reached right now, please try again later");
			        PlayerInfo[PlayerInfo[i][pCalledBy]][pCalling] = INVALID_PLAYER_ID;
			        PlayerInfo[i][pCalledBy] = INVALID_PLAYER_ID;
			        PlayerInfo[i][pCallTicks] = 0;
			    }
			}
		}
	}
}

forward FuelTimer();
public FuelTimer()
{
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		if (IsPlayerConnected(i) && GetPlayerState(i) == PLAYER_STATE_DRIVER)
		{
		    new vehicleid = GetPlayerVehicleID(i);
		    if (Fuel[vehicleid] > 0)
		    {
		        if (Fuel[vehicleid] <= 10) { PlayerPlaySound(i, 1085, 0.0, 0.0, 0.0); }
		        Fuel[vehicleid]--;
		    }
		}
	}
}

forward UpdateTime();
public UpdateTime()
{
	new hour, minute;
	new timestr[32];
    gettime(hour, minute);
   	format(timestr, 32, "%02d:%02d", hour, minute);
   	TextDrawSetString(tTimeDisplay, timestr);

   	SetWorldTime(hour);

	for (new i = 0; i < GetMaxPlayers(); i++)
	{
	    if (IsPlayerConnected(i) && GetPlayerState(i) != PLAYER_STATE_NONE)
	    {
	        SetPlayerTime(i, hour, minute);
	    }
	}
}

//--------------------------------------------------

forward UpdateVehicleHUD();
public UpdateVehicleHUD()
{
    new msg[24], Float:PSpeed;
	for (new i = 0; i < GetMaxPlayers(); i++)
	{
		if (IsPlayerConnected(i) && GetPlayerState(i) == PLAYER_STATE_DRIVER)
		{
		    PSpeed = GetPlayerSpeed(i, true);
			format(msg, sizeof(msg), "%0.0f KMH", PSpeed);
			TextDrawSetString(tSpeedo[i], msg);
			new vid = GetPlayerVehicleID(i), perc[2] = "%";
			format(msg, sizeof(msg), "%d%s fuel", Fuel[vid], perc);
			TextDrawSetString(tFuel[i], msg);
			//aVehicleNames[GetFuelModel(GetPlayerVehicleID(i)) - 400]
		}
	}
}

//--------------------------------------------------

stock ShowDialog(playerid, dialogid)
{
	switch (dialogid)
	{
		case DIALOG_REGISTER:
			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "Please register an account by filling in\nyour password below:", "Next", "Cancel");

		case DIALOG_CONFIRMREGISTER:
		    ShowPlayerDialog(playerid, DIALOG_CONFIRMREGISTER, DIALOG_STYLE_INPUT, "Register", "Please confirm your registration by\n filling in your password below:", "Confirm", "Cancel");

		case DIALOG_LOGIN:
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Login", "Please login by filling in your password below:", "Login", "Cancel");
			
		case DIALOG_SHOP:
		    ShowPlayerDialog(playerid, DIALOG_SHOP, DIALOG_STYLE_LIST, "24/7 Shop", "Cellphone\t\t1250$\nPhonebook\t\t200$\nKnife\t\t\t500$\n", "Buy", "Cancel");
		    
		case DIALOG_BANK:
		    ShowPlayerDialog(playerid, DIALOG_BANK, DIALOG_STYLE_LIST, "Bank", "Withdraw\nDeposit\n", "Select", "Cancel");
		    
		case DIALOG_BANK_WITHDRAW:
		{
		    new msg[128];
		    format(msg, sizeof(msg), "Please fill in the amount of money you would like to withdraw.\n%s available.", FormatMoney(PlayerInfo[playerid][pBank]));
		    ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "Bank", msg, "Withdraw", "Cancel");
		}
		case DIALOG_BANK_DEPOSIT:
		{
		    new msg[128];
		    format(msg, sizeof(msg), "Please fill in the amount of money you would like to deposit.\n%s available.", FormatMoney(GetPlayerMoney(playerid)));
		    ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "Bank", msg, "Deposit", "Cancel");
		}
	}
}

//--------------------------------------------------

stock Encrypt(string[])
{
	for(new x = 0; x < strlen(string); x++)
	{
		string[x] += (3^x) * (x % 15);
		if(string[x] > (0xff))
		{
			string[x] -= 64;
		}
	}
	return 1;
}

//--------------------------------------------------

stock ProxDetector(Float:radi, playerid, string[], col1, col2, col3, col4, col5)
{
	if(IsPlayerConnected(playerid))
	{
		new Float:posx, Float:posy, Float:posz;
		new Float:oldposx, Float:oldposy, Float:oldposz;
		new Float:tempposx, Float:tempposy, Float:tempposz;
		GetPlayerPos(playerid, oldposx, oldposy, oldposz);
		new plvw, ivw;
		plvw = GetPlayerVirtualWorld(playerid);
		for(new i = 0; i < MAX_PLAYERS; i++)
		{
			if(IsPlayerConnected(i))
			{
				ivw = GetPlayerVirtualWorld(i);

				if (ivw == plvw)
				{
					GetPlayerPos(i, posx, posy, posz);
					tempposx = (oldposx -posx);
					tempposy = (oldposy -posy);
					tempposz = (oldposz -posz);
					if (((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16)))
					{
						SendClientMessage(i, col1, string);
					}
					else if (((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8)))
					{
						SendClientMessage(i, col2, string);
					}
					else if (((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4)))
					{
						SendClientMessage(i, col3, string);
					}
					else if (((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2)))
					{
						SendClientMessage(i, col4, string);
					}
					else if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)))
					{
						SendClientMessage(i, col5, string);
					}
				}
			}
		}
	}
}

stock ProxDetectorEx(Float:radius, playerid, string[], color)
{
	ProxDetector(radius, playerid, string, color, color, color, color, color);
}

stock GetPlayerSpeed(playerid, bool:kmh)
{
    new Float:Vx, Float:Vy, Float:Vz, Float:rtn;
    if(IsPlayerInAnyVehicle(playerid)) GetVehicleVelocity(GetPlayerVehicleID(playerid),Vx,Vy,Vz);
	else GetPlayerVelocity(playerid,Vx,Vy,Vz);
    rtn = floatsqroot(floatabs(floatpower(Vx + Vy + Vz,2)));
    return kmh ? floatround(rtn * 100 * 1.61) : floatround(rtn * 100);
}

stock VehicleLights(vehicleid, bool:status)
{
	new panels, doors, lights, tires;
	GetFuelDamageStatus(vehicleid, panels, doors, lights, tires);
	status ? lights = encode_lights(1, 1, 1, 1); : lights = encode_lights(0, 0, 0, 0);
	UpdateVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
	return 1;
}

stock encode_lights(light1, light2, light3, light4) {
	return light1 | (light2 << 1) | (light3 << 2) | (light4 << 3);
}

stock FormatMoney(Float:amount, delimiter[2]=",")
{
	#define MAX_MONEY_STRING 16
	new txt[MAX_MONEY_STRING];
	format(txt, MAX_MONEY_STRING, "$%d", floatround(amount));
	new l = strlen(txt);
	if (amount < 0) // -
	{
	    if (l > 5) strins(txt, delimiter, l-3);
		if (l > 8) strins(txt, delimiter, l-6);
		if (l > 11) strins(txt, delimiter, l-9);
	}
	else
	{
		if (l > 4) strins(txt, delimiter, l-3);
		if (l > 7) strins(txt, delimiter, l-6);
		if (l > 10) strins(txt, delimiter, l-9);
	}
	return txt;
}
/*
	Default functions
--------------------------------*/

public OnGameModeInit()
{
	SetGameModeText("Sons of Anarchy");
	DisableInteriorEnterExits();
	EnableStuntBonusForAll(false);
	AllowInteriorWeapons(true);
	SetNameTagDrawDistance(20.0);
	//ShowNameTags(false);
	//ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
	EnableZoneNames(true);
	
	// Game classes
	for (new i = 0; i < sizeof(CopSkins); i++)
	{
	    AddPlayerClassEx(TEAM_COPS, CopSkins[i], 2251.27, 2490.40, 10.99, 90.37, 0, 0, 0, 0, 0, 0);
	}
	for (new i = 0; i < sizeof(RobberSkins); i++)
	{
	    AddPlayerClassEx(TEAM_ROBBERS, RobberSkins[i], 2193.68, 2006.91, 12.28, 357.53, 0, 0, 0, 0, 0, 0);
	}

	// Textdraws
	tTimeDisplay = TextDrawCreate(605.0, 25.0, "00:00");
	TextDrawUseBox(tTimeDisplay, 0);
	TextDrawFont(tTimeDisplay, 3);
	TextDrawSetShadow(tTimeDisplay, 0);
    TextDrawSetOutline(tTimeDisplay, 2);
    TextDrawBackgroundColor(tTimeDisplay, 0x000000FF);
    TextDrawColor(tTimeDisplay, 0xFFFFFFFF);
    TextDrawAlignment(tTimeDisplay, 3);
	TextDrawLetterSize(tTimeDisplay, 0.5, 1.5);
	
	PTextDraws[0] = TextDrawCreate(610.00, 375.00, "_");
	TextDrawUseBox(PTextDraws[0], 1);
	TextDrawBoxColor(PTextDraws[0], 0x00000033);
	TextDrawTextSize(PTextDraws[0], 530.00, 0.00);
	TextDrawAlignment(PTextDraws[0], 0);
	TextDrawBackgroundColor(PTextDraws[0], 0x000000ff);
	TextDrawFont(PTextDraws[0], 1);
	TextDrawLetterSize(PTextDraws[0], -3.70, 5.10);
	TextDrawColor(PTextDraws[0], 0xffffffff);
	TextDrawSetProportional(PTextDraws[0], 1);
	TextDrawSetShadow(PTextDraws[0], 1);

	PTextDraws[1] = TextDrawCreate(610.00, 375.00, "_");
	TextDrawUseBox(PTextDraws[1], 1);
	TextDrawBoxColor(PTextDraws[1], 0x000000ff);
	TextDrawTextSize(PTextDraws[1], 530.00, 185.00);
	TextDrawAlignment(PTextDraws[1], 0);
	TextDrawBackgroundColor(PTextDraws[1], 0x000000ff);
	TextDrawFont(PTextDraws[1], 3);
	TextDrawLetterSize(PTextDraws[1], 2.80, -0.20);
	TextDrawColor(PTextDraws[1], 0xffffffff);
	TextDrawSetOutline(PTextDraws[1], 1);
	TextDrawSetProportional(PTextDraws[1], 1);
	TextDrawSetShadow(PTextDraws[1], 1);

	PTextDraws[2] = TextDrawCreate(530.00, 375.00, "_");
	TextDrawUseBox(PTextDraws[2], 1);
	TextDrawBoxColor(PTextDraws[2], 0x000000ff);
	TextDrawTextSize(PTextDraws[2], 530.00, 32.00);
	TextDrawAlignment(PTextDraws[2], 0);
	TextDrawBackgroundColor(PTextDraws[2], 0x000000ff);
	TextDrawFont(PTextDraws[2], 3);
	TextDrawLetterSize(PTextDraws[2], 1.00, 5.30);
	TextDrawColor(PTextDraws[2], 0xffffffff);
	TextDrawSetOutline(PTextDraws[2], 1);
	TextDrawSetProportional(PTextDraws[2], 1);
	TextDrawSetShadow(PTextDraws[2], 1);

	PTextDraws[3] = TextDrawCreate(530.00, 425.00, "_");
	TextDrawUseBox(PTextDraws[3], 1);
	TextDrawBoxColor(PTextDraws[3], 0x000000ff);
	TextDrawTextSize(PTextDraws[3], 610.00, 80.00);
	TextDrawAlignment(PTextDraws[3], 0);
	TextDrawBackgroundColor(PTextDraws[3], 0x000000ff);
	TextDrawFont(PTextDraws[3],3);
	TextDrawLetterSize(PTextDraws[3], 1.50, -0.20);
	TextDrawColor(PTextDraws[3],0xffffffff);
	TextDrawSetOutline(PTextDraws[3], 1);
	TextDrawSetProportional(PTextDraws[3], 1);
	TextDrawSetShadow(PTextDraws[3], 1);

	PTextDraws[4] = TextDrawCreate(610.00, 375.00, "_");
	TextDrawUseBox(PTextDraws[4], 1);
	TextDrawBoxColor(PTextDraws[4], 0x000000ff);
	TextDrawTextSize(PTextDraws[4], 610.00, -1.00);
	TextDrawAlignment(PTextDraws[4], 0);
	TextDrawBackgroundColor(PTextDraws[4], 0x000000ff);
	TextDrawLetterSize(PTextDraws[4], 0.20, 5.40);
	TextDrawFont(PTextDraws[4], 3);
	TextDrawColor(PTextDraws[4], 0xffffffff);
	TextDrawSetOutline(PTextDraws[4], 1);
	TextDrawSetProportional(PTextDraws[4], 1);
	TextDrawSetShadow(PTextDraws[4], 1);

	PTextDraws[5] = TextDrawCreate(555.00, 420.00, "_");
	TextDrawUseBox(PTextDraws[5], 1);
	TextDrawBoxColor(PTextDraws[5], 0xffffffff);
	TextDrawTextSize(PTextDraws[5], 550.00, 0.00);
	TextDrawAlignment(PTextDraws[5], 0);
	TextDrawBackgroundColor(PTextDraws[5], 0x000000ff);
	TextDrawFont(PTextDraws[5], 3);
	TextDrawLetterSize(PTextDraws[5], 0.20, -0.00);
	TextDrawColor(PTextDraws[5], 0xffffffff);
	TextDrawSetOutline(PTextDraws[5], 1);
	TextDrawSetProportional(PTextDraws[5], 1);
	TextDrawSetShadow(PTextDraws[5], 1);
	
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		PInfo[i] = TextDrawCreate(535.00, 376.00, " ");
    	TextDrawAlignment(PInfo[i], 0);
     	TextDrawBackgroundColor(PInfo[i], 0x000000ff);
      	TextDrawFont(PInfo[i], 1);
		TextDrawLetterSize(PInfo[i], 0.20, 0.90);
  		TextDrawSetProportional(PInfo[i], 1);
    	TextDrawSetShadow(PInfo[i], 1);
     	TextDrawColor(PInfo[i], 0xffff00ff);
		
		tClassSelect[i] = TextDrawCreate(325.00, 425.00, "Cops");
		TextDrawAlignment(tClassSelect[i], 2);
		TextDrawBackgroundColor(tClassSelect[i], 255);
		TextDrawFont(tClassSelect[i], 1);
		TextDrawLetterSize(tClassSelect[i], 0.63, 2.00);
		TextDrawColor(tClassSelect[i], -1);
		TextDrawSetOutline(tClassSelect[i], 1);
		TextDrawSetProportional(tClassSelect[i], 1);
		
		tSpeedo[i] = TextDrawCreate(635.0, 210.0, "- KPH");
		TextDrawAlignment(tSpeedo[i], 3);
		TextDrawBackgroundColor(tSpeedo[i], 255);
		TextDrawFont(tSpeedo[i], 1);
		TextDrawLetterSize(tSpeedo[i], 0.14, 1.0);
		TextDrawColor(tSpeedo[i], -1);
		TextDrawSetOutline(tSpeedo[i], 1);
		TextDrawSetProportional(tSpeedo[i], 1);

		tFuel[i] = TextDrawCreate(635.0, 220.0, "-");
		TextDrawAlignment(tFuel[i], 3);
		TextDrawBackgroundColor(tFuel[i], 255);
		TextDrawFont(tFuel[i], 1);
		TextDrawLetterSize(tFuel[i], 0.14, 1.0);
		TextDrawColor(tFuel[i], -1);
		TextDrawSetOutline(tFuel[i], 1);
		TextDrawSetProportional(tFuel[i], 1);
	}

	// Timers
	UpdateTime();
	SetTimer("UpdateTime", 30000, true);
	SetTimer("UpdateVehicleHUD", 250, true);
	SetTimer("MapIconPulse", 500, true);
	SetTimer("CheckpointStream", 750, true);
	SetTimer("FuelTimer", 35000, true);
	SetTimer("MiscTimer", 1000, true);
	
	// NPCS
	ConnectNPC("Pilot", "at400_lv");
	ConnectNPC("TrainDriver", "train_lv");
	ConnectNPC("BusDriver", "CityBus");
	
	LoadProperties();
	LoadMapicons();
	LoadVehicles();
	
	for (new i = 0; i < MAX_VEHICLES; i++) { Fuel[i] = 100; }
	
	return 1;
}

//--------------------------------------------------

public OnGameModeExit()
{
	SaveProperties();
	SaveVehicles();
	return 1;
}

//--------------------------------------------------

public OnPlayerRequestClass(playerid, classid)
{
	if (!IsPlayerNPC(playerid))
	{
		SetPlayerInterior(playerid, 3);
		SetPlayerPos(playerid, 349.0453, 193.2271, 1014.1797);
		SetPlayerFacingAngle(playerid, 286.25);
		SetPlayerCameraPos(playerid, 352.9164, 194.5702, 1014.1875);
		SetPlayerCameraLookAt(playerid, 349.0453, 193.2271, 1014.1797);
		TextDrawShowForPlayer(playerid, tClassSelect[playerid]);
		if (classid > (sizeof(CopSkins) - 1)) { TextDrawSetString(tClassSelect[playerid], "~r~Robber"); }
		else { TextDrawSetString(tClassSelect[playerid], "~w~~b~Cop"); }
	}
	else
	{
	    new plrName[MAX_PLAYER_NAME];
	    GetPlayerName(playerid, plrName, sizeof(plrName));
	    if (!strcmp(plrName, "Pilot", true)) { SetSpawnInfo(playerid, 69, 61, 0.0, 0.0, 0.0, 0.0, -1, -1, -1, -1, -1, -1); }
	    if (!strcmp(plrName, "TrainDriver", true)) { SetSpawnInfo(playerid, 69, 255, 1462.0745, 2630.8787, 10.8203, 0.0, -1, -1, -1, -1, -1, -1); }
	    if (!strcmp(plrName, "BusDriver", true)) { SetSpawnInfo(playerid, 69, 61, 0.0, 0.0, 0.0, 0.0, -1, -1, -1, -1, -1, -1); }
	}
	return 1;
}

//--------------------------------------------------

public OnPlayerConnect(playerid)
{
	if (IsPlayerNPC(playerid)) return 1;
	
	PlayerInfo[playerid] = EmptyPlayer;
	PlayerInventory[playerid] = EmptyInventory;

	new name[6 + MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof(name));
	PlayerInfo[playerid][pName] = name;
	
	new fname[6 + MAX_PLAYER_NAME + 4];
	format(fname, sizeof(fname), "%s/%s.ini", FOLDER_USERS, name);
	PlayerInfo[playerid][pFName] = fname;
	new msg[128];
	
	format(msg, sizeof(msg), "* %s has connected.", name);
	SendClientMessageToAll(COLOR_STATUS, msg);
	
	if (!dini_Exists(fname))
	{
		format(msg, sizeof(msg), "Welcome %s. You can register by filling out the dialog", name);
		SendClientMessage(playerid, COLOR_WHITE, msg);
		ShowDialog(playerid, DIALOG_REGISTER);
	}
	else
	{
		format(msg, sizeof(msg), "Welcome back %s. You can log in by filling out the dialog", name);
		SendClientMessage(playerid, COLOR_WHITE, msg);
        ShowDialog(playerid, DIALOG_LOGIN);
	}

	return 1;
}

//--------------------------------------------------

public OnPlayerDisconnect(playerid, reason)
{
	if (IsPlayerNPC(playerid)) return 1;
	
	new msg[128];
	
	switch (reason)
	{
		case 0: format(msg, sizeof(msg),"* %s disconnected. (Timed out)", PlayerInfo[playerid][pName]);
		case 1: format(msg, sizeof(msg),"* %s disconnected. (Leaving)", PlayerInfo[playerid][pName]);
		case 2: format(msg, sizeof(msg),"* %s disconnected. (Kicked/Banned)", PlayerInfo[playerid][pName]);
	}
	
	SendClientMessageToAll(COLOR_STATUS, msg);
	
	if (PlayerInfo[playerid][pLoggedIn])
	{
		dini_IntSet(PlayerInfo[playerid][pFName], "Admin", PlayerInfo[playerid][pAdmin]);
		dini_IntSet(PlayerInfo[playerid][pFName], "Money", GetPlayerMoney(playerid));
		dini_IntSet(PlayerInfo[playerid][pFName], "Bank", PlayerInfo[playerid][pBank]);
		dini_IntSet(PlayerInfo[playerid][pFName], "Phonenumber", PlayerInfo[playerid][pPhonenumber]);
		dini_IntSet(PlayerInfo[playerid][pFName], "Team", PlayerInfo[playerid][pTeam]);
		dini_IntSet(PlayerInfo[playerid][pFName], "Skin", PlayerInfo[playerid][pSkin]);
		
		dini_IntSet(PlayerInfo[playerid][pFName], "Cellphone", PlayerInventory[playerid][pCellphone]);
		dini_IntSet(PlayerInfo[playerid][pFName], "Phonebook", PlayerInventory[playerid][pPhonebook]);
	}
	
	return 1;
}

//--------------------------------------------------

public OnPlayerSpawn(playerid)
{
	if (!IsPlayerNPC(playerid)) { TextDrawHideForPlayer(playerid, tClassSelect[playerid]); }
	SetPlayerInterior(playerid, 0);

	new hour, minute;
	gettime(hour, minute);
	SetPlayerTime(playerid, hour, minute);
	TextDrawShowForPlayer(playerid, tTimeDisplay);

	SetPlayerSkillLevel(playerid, WEAPONSKILL_PISTOL, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_PISTOL_SILENCED, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_DESERT_EAGLE, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SHOTGUN, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SPAS12_SHOTGUN, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_MICRO_UZI, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_MP5, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_AK47, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_M4, 200);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SNIPERRIFLE, 200);
	
	if (IsPlayerNPC(playerid))
	{
		new plrName[MAX_PLAYER_NAME];
		GetPlayerName(playerid, plrName, sizeof(plrName));
		
		if (!strcmp(plrName, "Pilot", true))
		{
			PutPlayerInVehicle(playerid, CreateVehicle(577, 0.0, 0.0, 0.0, 0.0, -1, -1, 60), 0);
			Attach3DTextLabelToVehicle(Create3DTextLabel("City2City Plane", COLOR_YELLOW, 0.0, 0.0, 0.0, 50.0, 1), GetPlayerVehicleID(playerid), 0.0, 0.0, 2.5);
		}
		if (!strcmp(plrName, "TrainDriver", true))
		{
			PutPlayerInVehicle(playerid, CreateVehicle(449, 1412.69, 2632.25, 11.24, 89.99, 0, 0, 60), 0);
			Attach3DTextLabelToVehicle(Create3DTextLabel("City2City Train", COLOR_YELLOW, 0.0, 0.0, 0.0, 50.0, 1), GetPlayerVehicleID(playerid), 0.0, 0.0, 2.5);
		}
		if (!strcmp(plrName, "BusDriver", true))
		{
			PutPlayerInVehicle(playerid, CreateVehicle(437, 0.0, 0.0, 0.0, 0.0, 0, 0, 60), 0);
			Attach3DTextLabelToVehicle(Create3DTextLabel("City Bus", COLOR_YELLOW, 0.0, 0.0, 0.0, 50.0, 1), GetPlayerVehicleID(playerid), 0.0, 0.0, 2.5);
		}
	}
	
	SetPlayerColor(playerid, COLOR_WHITE);
	
	return 1;
}

//--------------------------------------------------

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

//--------------------------------------------------

public OnVehicleSpawn(vehicleid)
{
	Fuel[vehicleid] = 100;
	return 1;
}

//--------------------------------------------------

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerText(playerid, text[])
{
	new msg[128];
	if (!PlayerInfo[playerid][pMuted])
	{
	    if (PlayerInfo[playerid][pCalling] == INVALID_PLAYER_ID)
	    {
	        format(msg, sizeof(msg), "%s says: %s", PlayerInfo[playerid][pName], text);
	    }
	    else
	    {
	        new call = PlayerInfo[playerid][pCalling];
	    	format(msg, sizeof(msg), "%s says (cellphone): %s", PlayerInfo[playerid][pName], text);
	    	if (IsPlayerConnected(call) && PlayerInfo[call][pCalling] == playerid)
	    	{
	    	    SendClientMessage(playerid, COLOR_GRAD1, msg);
	    	}
	    }
	    ProxDetector(20.0, playerid, msg, COLOR_GRAD1, COLOR_GRAD2, COLOR_GRAD3, COLOR_GRAD4, COLOR_GRAD5);
	} else { SendClientMessage(playerid, COLOR_RED, "You are muted and can't speak."); }
	
	return 0;
}

//--------------------------------------------------

public OnPlayerCommandText(playerid, cmdtext[])
{
	if (!PlayerInfo[playerid][pLoggedIn]) return 0;
	// Level 0+ commands
	dcmd(o, 1, cmdtext);
	dcmd(call, 4, cmdtext);
	dcmd(enter, 5, cmdtext);
	dcmd(exit, 4, cmdtext);
	dcmd(shop, 4, cmdtext);
	dcmd(bank, 4, cmdtext);
	
	//if (!PlayerInfo[playerid][pAdmin]) return 0;
	// Level 1+ commands
	dcmd(color, 5, cmdtext);
	dcmd(fix, 3, cmdtext);
	dcmd(flip, 4, cmdtext);
	dcmd(nos, 3, cmdtext);
	dcmd(explode, 7, cmdtext);
	dcmd(heal, 4, cmdtext);
	dcmd(kill, 4, cmdtext);
	dcmd(entprop, 7, cmdtext);
	dcmd(goto, 4, cmdtext);
	dcmd(gethere, 7, cmdtext);
	dcmd(spectate, 8, cmdtext);
	
	if (PlayerInfo[playerid][pAdmin] < 2) return 0;
	// Level 2+ commands
	dcmd(pos, 3, cmdtext);
	dcmd(kick, 4, cmdtext);
	dcmd(ban, 3, cmdtext);
	
	return 0;
}

//--------------------------------------------------

/*
	Level 0+ commands
--------------------------------*/

dcmd_o(playerid, params[])
{
	if (!PlayerInfo[playerid][pMuted] && IsOOCEnabled)
	{
	    SendPlayerMessageToAll(playerid, params);
	}
	
	return 1;
}

dcmd_call(playerid, params[])
{
	if (PlayerInventory[playerid][pCellphone])
	{
		new num;
		if (sscanf(params, "i", num)) { SendClientMessage(playerid, COLOR_RED, "* /call: You need to specify a number"); }
		else
		{
		    new msg[128];
			format(msg, sizeof(msg), "* %s picks up his phone.", PlayerInfo[playerid][pName]);
			ProxDetectorEx(20.0, playerid, msg, COLOR_ACTION);
		    for (new i = 0; i < MAX_PLAYERS; i++)
		    {
		        if (IsPlayerConnected(i) && PlayerInventory[i][pCellphone] && PlayerInfo[i][pPhonenumber] == num)
		        {
		            format(msg, sizeof(msg), "* %s is calling you, hold TAB to pickup", PlayerInfo[playerid][pName]);
		            SendClientMessage(i, COLOR_CYAN, msg);
		            PlayerInfo[playerid][pCalling] = i;
		            PlayerInfo[i][pCalledBy] = playerid;
		            PlayerInfo[i][pCallTicks] = 15;
		            break;
		        }
		    }
		    SendClientMessage(playerid, COLOR_CYAN, "TELEPHONE COMPANY: The person you are calling can not be reached at the moment, please try again later.");
		}
	}
	else { SendClientMessage(playerid, COLOR_RED, "* /call: You don't have a cellphone"); }
	
	return 1;
}

dcmd_enter(playerid, params[])
{
	#pragma unused params
	if (LastPickup[playerid] != -1 || Properties[LastPickup[playerid]][eType] > PTYPE_EMPTY)
	{
	    new id = LastPickup[playerid];
	    if (IsPlayerInRangeOfPoint(playerid, 3.0, Properties[id][eEntX], Properties[id][eEntY], Properties[id][eEntZ]))
	    {
	        PutPlayerInProperty(playerid, id, Properties[id][eVWorld]);
	    }
	}

	return 1;
}

dcmd_exit(playerid, params[])
{
	#pragma unused params
    if (CurrentProperty[playerid] != -1)
    {
        RemovePlayerFromProperty(playerid, CurrentProperty[playerid]);
    }
    else { SendClientMessage(playerid, COLOR_RED, "* You aren't in a property."); }
    
	return 1;
}

dcmd_shop(playerid, params[])
{
	#pragma unused params
	new id = CurrentProperty[playerid];
	if (id != 0)
	{
		if (Properties[id][eType] == PTYPE_BUSINESS && !strcmp(Properties[id][eName], "24/7", false))
		{
			ShowDialog(playerid, DIALOG_SHOP);
		}
		else { SendClientMessage(playerid, COLOR_RED, "* You are not in a 24/7 shop."); }
	}

	return 1;
}

dcmd_bank(playerid, params[])
{
	#pragma unused params
	new id = CurrentProperty[playerid];
	if (id != 0)
	{
		if (Properties[id][eType] == PTYPE_GOVERMENT && !strcmp(Properties[id][eName], "Bank", false))
		{
			ShowDialog(playerid, DIALOG_BANK);
		}
		else { SendClientMessage(playerid, COLOR_RED, "* You are not in a bank."); }
	}

	return 1;
}

/*
	Level 1+ commands
--------------------------------*/

dcmd_entprop(playerid, params[])
{
	new propid;
	if (sscanf(params, "d", propid)) { SendClientMessage(playerid, COLOR_RED, "* /entprop: /entprop <propertyid>"); }
	else
	{
	    PutPlayerInProperty(playerid, propid);
	}
	
	return 1;
}

dcmd_goto(playerid, params[])
{
	new id;
	if (sscanf(params, "u", id)) { SendClientMessage(playerid, COLOR_RED, "* /goto: Syntax: /goto <playername/id>"); }
	else if (id == INVALID_PLAYER_ID) { SendClientMessage(playerid, COLOR_RED, "* /goto: Invalid player"); }
	else
	{
		new Float:X, Float:Y, Float:Z;
		GetPlayerPos(id, X, Y, Z);
		new veh = GetPlayerVehicleID(playerid);
		if (veh) { SetVehiclePos(veh, X + 2.0, Y + 2.0, Z + 2.0); }
		else { SetPlayerPos(playerid, X + 2.0, Y + 2.0, Z + 2.0); }
		new msg[128];
		format(msg, sizeof(msg), "* %s [ID: %d] has gone to you", PlayerInfo[playerid][pName], playerid);
		SendClientMessage(id, COLOR_GREEN, msg);
		format(msg, sizeof(msg), "* You have gone to %s [ID: %d]", PlayerInfo[id][pName], id);
		SendClientMessage(playerid, COLOR_GREEN, msg);
	}
	
	return 1;
}

dcmd_gethere(playerid, params[])
{
	new id;
	if (sscanf(params, "u", id)) { SendClientMessage(playerid, COLOR_RED, "* /gethere: Syntax: /gethere <playername/id>"); }
	else if (id == INVALID_PLAYER_ID) { SendClientMessage(playerid, COLOR_RED, "* /gethere: Invalid player"); }
	else
	{
		new Float:X, Float:Y, Float:Z;
		GetPlayerPos(playerid, X, Y, Z);
		new veh = GetPlayerVehicleID(id);
		if (veh) { SetVehiclePos(veh, X + 2.0, Y + 2.0, Z + 2.0); }
		else { SetPlayerPos(id, X + 2.0, Y + 2.0, Z + 2.0); }
		new msg[128];
		format(msg, sizeof(msg), "* %s [ID: %d] has brought you to him", PlayerInfo[playerid][pName], playerid);
		SendClientMessage(id, COLOR_YELLOW, msg);
		format(msg, sizeof(msg), "* You have brought %s [ID: %d] to you", PlayerInfo[id][pName], id);
		SendClientMessage(playerid, COLOR_YELLOW, msg);
	}
	
	return 1;
}

dcmd_flip(playerid, params[])
{
	new id;
	if (sscanf(params, "u", id)) { id = playerid; }
	
	new v = GetPlayerVehicleID(id);
	if (v)
	{
	    new Float:A;
	    GetVehicleZAngle(v, A);
	    SetVehicleZAngle(v, A);
	    if (id != playerid) { SendClientMessage(id, COLOR_GREEN, "Your vehicle was flipped."); }
	    SendClientMessage(playerid, COLOR_GREEN, "Flipped vehicle");
	}
	else { SendClientMessage(playerid, COLOR_RED, "* /flip: No vehicle found"); }
	
	return 1;
}

dcmd_fix(playerid, params[])
{
	new id;
	if (sscanf(params, "u", id)) { id = playerid; }
	
	if (id == INVALID_PLAYER_ID) { SendClientMessage(playerid, COLOR_RED, "* /repair: Invalid player"); }
	else
	{
		new veh = GetPlayerVehicleID(id);
		if (veh)
		{
		    RepairVehicle(veh);
		    if (playerid != id) { SendClientMessage(playerid, COLOR_GREEN, "Repaired vehicle"); }
		    SendClientMessage(id, COLOR_GREEN, "Your vehicle was repaired");
		}
		else { SendClientMessage(playerid, COLOR_RED, "That player is currently not in a vehicle"); }
	}
	return 1;
}

dcmd_nos(playerid, params[])
{
	new id;
	if (sscanf(params, "u", id)) { id = playerid; }

	if (id == INVALID_PLAYER_ID) { SendClientMessage(playerid, COLOR_RED, "* /nos: Invalid player"); }
	else
	{
		new veh = GetPlayerVehicleID(id);
		if (veh)
		{
		    AddVehicleComponent(veh, 1010);
		    if (playerid != id) { SendClientMessage(playerid, COLOR_GREEN, "Added nos to vehicle"); }
		    SendClientMessage(id, COLOR_GREEN, "Added nos to vehicle");
		}
		else { SendClientMessage(playerid, COLOR_RED, "That player is currently not in a vehicle"); }
	}
	return 1;
}

dcmd_color(playerid, params[])
{
	new c1, c2;
	if (sscanf(params, "uu", c1, c2)) { c1 = 0; c2 = 0; }
	new veh = GetPlayerVehicleID(playerid);
	if (veh)
	{
	    ChangeVehicleColor(veh, c1, c2);
	    SendClientMessage(playerid, COLOR_GREEN, "Your vehicle has changed color");
	}
	else { SendClientMessage(playerid, COLOR_RED, "That player is currently not in a vehicle"); }
	
	return 1;
}

dcmd_heal(playerid, params[])
{
	new id;
	if (sscanf(params, "u", id)) { id = playerid; }
	
	SetPlayerHealth(id, 100.0);
	if (playerid != id) { SendClientMessage(playerid, COLOR_GREEN, "Healed player"); }
	SendClientMessage(id, COLOR_GREEN, "You were healed");
	return 1;
}

dcmd_kill(playerid, params[])
{
	new id;
	if (sscanf(params, "u", id)) { id = playerid; }

	SetPlayerHealth(id, 0.0);
	if (playerid != id) { SendClientMessage(playerid, COLOR_GREEN, "Killed player"); }
	SendClientMessage(id, COLOR_GREEN, "You were killed");
	return 1;
}

dcmd_explode(playerid, params[])
{
	new id, type[3];
	new Float:X, Float:Y, Float:Z;
	
	if (sscanf(params, "uz", id, type)) { id = playerid; }
	
	GetPlayerPos(id, X, Y, Z);
	if (!strlen(type)) { type = "1"; }
	CreateExplosion(X, Y, Z, strval(type), 15.0);
	SendClientMessage(id, COLOR_GREEN, "You tapped that ass");
	return 1;
}

dcmd_spectate(playerid, params[])
{
	if (PlayerInfo[playerid][pSpectating] == INVALID_PLAYER_ID)
	{
		new id;
		if (sscanf(params, "u", id)) { SendClientMessage(playerid, COLOR_RED, "* /spectate: Syntax: /spectate <id/playername>"); }
		else
		{
		    GetPlayerPos(playerid, SpectateInfo[playerid][0], SpectateInfo[playerid][1], SpectateInfo[playerid][2]);
		    TogglePlayerSpectating(playerid, 1);
		    if (IsPlayerInAnyVehicle(id)){ PlayerSpectateVehicle(playerid, GetPlayerVehicleID(id)); }
		    else { PlayerSpectatePlayer(playerid, id); }
		    PlayerInfo[playerid][pSpectating] = id;
		}
	}
	else
	{
	    TogglePlayerSpectating(playerid, 0);
	    PlayerInfo[playerid][pSpectating] = INVALID_PLAYER_ID;
	    SetPlayerPos(playerid, SpectateInfo[playerid][0], SpectateInfo[playerid][1], SpectateInfo[playerid][2]);
	}
	return 1;
}

/*
	Level 2+ commands
--------------------------------*/

dcmd_pos(playerid, params[])
{
	new File:log = fopen("POSITIONS.txt", io_append);
	if (log)
	{
		new Float:X, Float:Y, Float:Z, Float:A;
		new output[128], comment[128];
		if (sscanf(params, "S(No comment)[128]", comment)) { }
		GetPlayerPos(playerid, X, Y, Z);
		GetPlayerFacingAngle(playerid, A);
		format(output, sizeof(output), "%0.2f, %0.2f, %0.2f, %0.2f, %d // %s\r\n", X, Y, Z, A, GetPlayerInterior(playerid), comment);
		fwrite(log, output);
		fclose(log);
		print(output);
		SendClientMessage(playerid, COLOR_GREEN, output);
	}
	return 1;
}

dcmd_kick(playerid, params[])
{
	new id, reason[128];
	if (sscanf(params, "uz", id, reason)) { SendClientMessage(playerid, 0xFF0000AA, "Usage: /kick <playerid/name> [reason]"); }
	else if (id == INVALID_PLAYER_ID) { SendClientMessage(playerid, 0xFF0000AA, "* /kick: Invalid player"); }
	else
	{
	    format(reason, sizeof(reason), "You have been kicked%s%s", reason[0] ? (".\nReason: ") : (""), reason);
	    SendClientMessage(id, COLOR_RED, reason);
	    format(reason, sizeof(reason), "You have kicked %s", PlayerInfo[id][pName]);
	    SendClientMessage(playerid, COLOR_GREEN, reason);
	    Kick(id);
	}

	return 1;
}

dcmd_ban(playerid, params[])
{
	new id, reason[128];
	if (sscanf(params, "uz", id, reason)) { SendClientMessage(playerid, COLOR_RED, "Usage: /ban <playerid/name> [reason]"); }
	else if (id == INVALID_PLAYER_ID) { SendClientMessage(playerid, COLOR_RED, "* /ban: Invalid player"); }
	else
	{
		format(reason, sizeof(reason), "You have been banned%s%s", reason[0] ? (".\nReason: ") : (""), reason);
		SendClientMessage(id, COLOR_RED, reason);
		BanEx(id, reason);
		format(reason, sizeof(reason), "You have banned %s.", PlayerInfo[id][pName]);
		SendClientMessage(playerid, COLOR_GREEN, reason);
	}

	return 1;
}

//--------------------------------------------------

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if (newstate == PLAYER_STATE_DRIVER)
	{
	    TextDrawShowForPlayer(playerid, tSpeedo[playerid]);
	    TextDrawShowForPlayer(playerid, tFuel[playerid]);
	}
	
	if (oldstate == PLAYER_STATE_DRIVER)
	{
		TextDrawHideForPlayer(playerid, tSpeedo[playerid]);
		TextDrawHideForPlayer(playerid, tFuel[playerid]);
	}
	
	return 1;
}

//--------------------------------------------------

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

//--------------------------------------------------

public OnRconCommand(cmd[])
{
	return 1;
}

//--------------------------------------------------

public OnPlayerRequestSpawn(playerid)
{
	PlayerInfo[playerid][pTeam] = GetPlayerTeam(playerid);
	PlayerInfo[playerid][pSkin] = GetPlayerSkin(playerid);
	return 1;
}

//--------------------------------------------------

public OnObjectMoved(objectid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerPickUpPickup(playerid, pickupid)
{
	new id = PropertyPickups[pickupid];
	new msg[128];
	new textdraw[1048];
	
	if (Properties[id][eType] > PTYPE_EMPTY)
	{
	    if (LastPickup[playerid] != id)
	    {
	        switch (Properties[id][eType])
	        {
	            case PTYPE_PROPERTY:
	            {
	                format(msg, sizeof(msg), "%s: Enter this property by typing /enter", Properties[id][eName]);
	                SendClientMessage(playerid, COLOR_GREEN, msg);
	            }
	            
	            case PTYPE_BUSINESS:
	            {
	                format(msg, sizeof(msg), "%s: Enter this property by typing /enter", Properties[id][eName]);
	                SendClientMessage(playerid, COLOR_CYAN, msg);
	            }
	            
	            case PTYPE_GOVERMENT:
	            {
	                format(msg, sizeof(msg), "%s: Enter this property by typing /enter", Properties[id][eName]);
	                SendClientMessage(playerid, COLOR_YELLOW, msg);
	            }
	        }
	        
        	new name[MAX_PLAYER_NAME];
            if (!strcmp(Properties[id][eOwner], "", true)) { name = "-"; }
			else { name = Properties[id][eOwner]; }
            format(textdraw, sizeof(textdraw), "~b~Name: ~w~%s~n~~b~Owner: ~w~%s~n~~b~Price: ~w~%s", Properties[id][eName], name, Properties[id][ePrice]);
            TextDrawSetString(PInfo[playerid], textdraw);
            for (new i = 0; i < sizeof(PTextDraws); i++) { TextDrawShowForPlayer(playerid, PTextDraws[i]); }
            TextDrawShowForPlayer(playerid, PInfo[playerid]);
	    }
	    LastPickup[playerid] = id;
	}
	
	return 1;
}

//--------------------------------------------------

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

//--------------------------------------------------

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

//--------------------------------------------------

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

//--------------------------------------------------

#define PRESSED(%0) \
	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
	
#define RELEASED(%0) \
	(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))

#define HOLDING(%0) \
	((newkeys & (%0)) == (%0))
	
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if (HOLDING(KEY_ACTION))
	{
	    new CalledBy = PlayerInfo[playerid][pCalledBy];
	    if (CalledBy != INVALID_PLAYER_ID && PlayerInfo[CalledBy][pCalling] == INVALID_PLAYER_ID)
	    {
	        PlayerInfo[playerid][pCalling] = CalledBy;
	        new msg[128];
			format(msg, sizeof(msg), "* %s picks up his phone.", PlayerInfo[playerid][pName]);
			ProxDetectorEx(20.0, playerid, msg, COLOR_ACTION);
			PlayerInfo[playerid][pCallTicks] = 0;
			format(msg, sizeof(msg), "* %s answers the call.", PlayerInfo[playerid][pName]);
			SendClientMessage(CalledBy, COLOR_ACTION, msg);
	    }
	}
	return 1;
}

//--------------------------------------------------

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerUpdate(playerid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

//--------------------------------------------------

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

//--------------------------------------------------

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	if (IsACopCar(vehicleid))
	{
	    if (PlayerInfo[forplayerid][pTeam] == TEAM_COPS)
	    {
	        SetVehicleParamsForPlayer(vehicleid, forplayerid, 0, 0);
	    }
	    else
	    {
	        SetVehicleParamsForPlayer(vehicleid, forplayerid, 0, 1);
	    }
    }
	return 1;
}

//--------------------------------------------------

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

//--------------------------------------------------

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	// Register
	if (dialogid == DIALOG_REGISTER)
	{
	    if (response)
	    {
			if (strlen(inputtext) < 5 || strlen(inputtext) > 12)
	        {
	            SendClientMessage(playerid, COLOR_RED, "Please input an password between 5 and 12 characters.");
	            ShowDialog(playerid, DIALOG_REGISTER);
	            return 0;
	        }
	        
	        SendClientMessage(playerid, COLOR_WHITE, "Thanks, now please confirm your registration by filling in your password once more");
	        ShowDialog(playerid, DIALOG_CONFIRMREGISTER);
	    }
		else { Kick(playerid); }
		
		return 1;
	}
	
	// Confirm register
	if (dialogid == DIALOG_CONFIRMREGISTER)
	{
	    if (response)
	    {
			if (strlen(inputtext) < 5 || strlen(inputtext) > 12)
	        {
	            SendClientMessage(playerid, COLOR_RED, "Please input a password between 5 and 12 characters.");
	            ShowDialog(playerid, DIALOG_REGISTER);
	            return 0;
	        }

	        Encrypt(inputtext);
	        
	        dini_Create(PlayerInfo[playerid][pFName]);
	        dini_Set(PlayerInfo[playerid][pFName], "Password", inputtext);
	        dini_IntSet(PlayerInfo[playerid][pFName], "Admin", 0);
	        
	        dini_IntSet(PlayerInfo[playerid][pFName], "Money", 2750);
	        dini_IntSet(PlayerInfo[playerid][pFName], "Bank", 250);
	        dini_IntSet(PlayerInfo[playerid][pFName], "Phonenumber", 0);
	        dini_IntSet(PlayerInfo[playerid][pFName], "Team", 0);
	        dini_IntSet(PlayerInfo[playerid][pFName], "Skin", 0);
	        
	        dini_IntSet(PlayerInfo[playerid][pFName], "Cellphone", 0);
	        dini_IntSet(PlayerInfo[playerid][pFName], "Phonebook", 0);
	        
	        SendClientMessage(playerid, COLOR_GREEN, "Your account has been registered, please login by filling out the dialog.");
	        ShowDialog(playerid, DIALOG_LOGIN);
	    }
		else { Kick(playerid); }

		return 1;
	}
	
	// Login
	if (dialogid == DIALOG_LOGIN)
	{
		if (response)
		{
			Encrypt(inputtext);
			if (!strlen(inputtext) || strcmp(dini_Get(PlayerInfo[playerid][pFName], "Password"), inputtext))
			{
			    PlayerInfo[playerid][pLoginAttempts]++;
			    if (PlayerInfo[playerid][pLoginAttempts] > 5)
			    {
			        SendClientMessage(playerid, COLOR_RED, "Too many login attempts!");
			        Kick(playerid);
			        return 0;
			    }
			    
			    SendClientMessage(playerid, COLOR_RED, "Wrong password, please try again.");
			    ShowDialog(playerid, DIALOG_LOGIN);
			    return 0;
			}

			PlayerInfo[playerid][pLoggedIn] = 1;

			ResetPlayerMoney(playerid);
			GivePlayerMoney(playerid, dini_Int(PlayerInfo[playerid][pFName], "Money"));
			PlayerInfo[playerid][pBank] = dini_Int(PlayerInfo[playerid][pFName], "Bank");
			PlayerInfo[playerid][pPhonenumber] = dini_Int(PlayerInfo[playerid][pFName], "Phonenumber");
			PlayerInfo[playerid][pAdmin] = dini_Int(PlayerInfo[playerid][pFName], "Admin");
			PlayerInfo[playerid][pTeam] = dini_Int(PlayerInfo[playerid][pFName], "Team");
			PlayerInfo[playerid][pSkin] = dini_Int(PlayerInfo[playerid][pFName], "Skin");
			
			PlayerInventory[playerid][pCellphone] = dini_Int(PlayerInfo[playerid][pFName], "Cellphone");
			PlayerInventory[playerid][pPhonebook] = dini_Int(PlayerInfo[playerid][pFName], "Phonebook");
			
			if (PlayerInfo[playerid][pTeam] != TEAM_NONE && PlayerInfo[playerid][pSkin] != 0)
		    {
				switch (PlayerInfo[playerid][pTeam])
				{
					case TEAM_COPS:
					{
					    SetSpawnInfo(playerid, PlayerInfo[playerid][pTeam], PlayerInfo[playerid][pSkin], 2251.27, 2490.40, 10.99, 90.37, 0, 0, 0, 0, 0, 0);
					    SetPlayerColor(playerid, COLOR_BLUE);
					}

					case TEAM_ROBBERS:
					{
						SetSpawnInfo(playerid, PlayerInfo[playerid][pTeam], PlayerInfo[playerid][pSkin], 2193.68, 2006.91, 12.28, 357.53, 0, 0, 0, 0, 0, 0);
						SetPlayerColor(playerid, COLOR_WHITE);
					}
				}
				SpawnPlayer(playerid);
			}
			SendClientMessage(playerid, COLOR_GREEN, "You have successfully logged in and all your data has been restored.");
		}
		else { Kick(playerid); }

		return 1;
	}

	// 24/7 Shop
	if (dialogid == DIALOG_SHOP)
	{
		if (response)
		{
		    switch (listitem)
		    {
				case 0: // Cellphone
				{
					if (GetPlayerMoney(playerid) >= 1250)
					{
					    if (!PlayerInventory[playerid][pCellphone])
					    {
							GivePlayerMoney(playerid, -1250);
							PlayerInventory[playerid][pCellphone] = 1;
							PlayerInfo[playerid][pPhonenumber] = random(8999) + 1000;
							SendClientMessage(playerid, COLOR_GREEN, "* You have bought a cellphone.");
							new msg[128];
							format(msg, sizeof(msg), "Your new phonenumber is: %d", PlayerInfo[playerid][pPhonenumber]);
							SendClientMessage(playerid, COLOR_YELLOW, msg);
						}
						else { SendClientMessage(playerid, COLOR_RED, "* You already have a cellphone."); ShowDialog(playerid, DIALOG_SHOP); }
					}
					else { SendClientMessage(playerid, COLOR_RED, "* You cannot afford a cellphone."); ShowDialog(playerid, DIALOG_SHOP); }
					
					return 1;
				}

				case 1: // Phonebook
				{
					if (GetPlayerMoney(playerid) >= 200)
					{
					    if (!PlayerInventory[playerid][pPhonebook])
					    {
							GivePlayerMoney(playerid, -200);
							PlayerInventory[playerid][pPhonebook] = 1;
							SendClientMessage(playerid, COLOR_GREEN, "* You have bought a phonebook.");
						}
						else { SendClientMessage(playerid, COLOR_RED, "* You already have a phonebook."); ShowDialog(playerid, DIALOG_SHOP); }
					}
					else { SendClientMessage(playerid, COLOR_RED, "* You cannot afford a phonebook."); ShowDialog(playerid, DIALOG_SHOP); }
					
					return 1;
				}

				case 2: // Knife
				{
					if (GetPlayerMoney(playerid) >= 500)
					{
						GivePlayerMoney(playerid, -500);
						GivePlayerWeapon(playerid, 4, 1);
						SendClientMessage(playerid, COLOR_GREEN, "* You have bought a knife.");
					}
					else { SendClientMessage(playerid, COLOR_RED, "You cannot afford a knife."); ShowDialog(playerid, DIALOG_SHOP); }
					
					return 1;
				}
			}
		}
	}
	
	if (dialogid == DIALOG_BANK)
	{
	    if (response)
	    {
	    	switch (listitem)
	        {
	            case 0:
	                ShowDialog(playerid, DIALOG_BANK_WITHDRAW);

				case 1:
				    ShowDialog(playerid, DIALOG_BANK_DEPOSIT);
	        }
	        
	        return 1;
	    }
	}
	
	if (dialogid == DIALOG_BANK_WITHDRAW)
	{
	    if (response)
	    {
	        new amount;
	        if (sscanf(inputtext, "d", amount)) { SendClientMessage(playerid, COLOR_RED, "Bank: Invalid input."); }
	        else
	        {
	            new msg[128];
	            if (amount < 1)
				{
					SendClientMessage(playerid, COLOR_RED, "You can't withdraw anything less than $1");
					ShowDialog(playerid, DIALOG_BANK_WITHDRAW);
					return 1;
				}
	            else if (amount > PlayerInfo[playerid][pBank])
	            {
					format(msg, sizeof(msg), "You only have %s available", FormatMoney(PlayerInfo[playerid][pBank]));
					SendClientMessage(playerid, COLOR_RED, msg);
					ShowDialog(playerid, DIALOG_BANK_WITHDRAW);
					return 1;
	            }

	            GivePlayerMoney(playerid, amount);
	            PlayerInfo[playerid][pBank] -= amount;
	            format(msg, sizeof(msg), "You have withdrawn %s. Current bank balance: %s", FormatMoney(amount), FormatMoney(PlayerInfo[playerid][pBank]));
	            SendClientMessage(playerid, COLOR_GREEN, msg);
	            
	            return 1;
	        }
	    }
	}
	
	if (dialogid == DIALOG_BANK_DEPOSIT)
	{
	    if (response)
	    {
	    	new amount;
	        if (sscanf(inputtext, "d", amount)) { SendClientMessage(playerid, COLOR_RED, "Bank: Invalid input."); }
	        else
	        {
	            new msg[128];
	            if (amount < 1)
				{
					SendClientMessage(playerid, COLOR_RED, "You can't deposit anything less than $1");
					ShowDialog(playerid, DIALOG_BANK_DEPOSIT);
					return 1;
				}
	            else if (amount > GetPlayerMoney(playerid))
	            {
					format(msg, sizeof(msg), "You only have %s available", FormatMoney(GetPlayerMoney(playerid)));
					SendClientMessage(playerid, COLOR_RED, msg);
					ShowDialog(playerid, DIALOG_BANK_DEPOSIT);
					return 1;
	            }

	            GivePlayerMoney(playerid, -amount);
	            PlayerInfo[playerid][pBank] += amount;
	            format(msg, sizeof(msg), "You have deposited %s. Current bank balance: %s", FormatMoney(amount), FormatMoney(PlayerInfo[playerid][pBank]));
	            SendClientMessage(playerid, COLOR_GREEN, msg);

	            return 1;
	        }
	    }
	}
	return 1;
}

//--------------------------------------------------

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

//--------------------------------------------------
