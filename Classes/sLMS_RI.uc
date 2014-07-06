/* ============================================================================
:: sLMS_RI ::
:: ============================================================================
:: Copyright © 2002 Roman Dzieciol ::::::::::: Switch` switch@thieveryut.com ::
============================================================================ */
class sLMS_RI expands ReplicationInfo;

struct IPCache
{
	var string IPAddr;
	var string IP;
	var int Idx;
};

enum ECVAction
{
	CVA_kick,
	CVA_kickban,
	CVA_coach,
	CVA_referee,
	CVA_captain,
};

var config ECVAction ECVTEST;

var private config IPCache IPC;
var config int PenaltyTime;
var config int StartupTime;

var bool bIsReady;
var sLMS_Stats Stats;
var sLastManStanding GI;

/* ============================================================================
:: Replication ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
replication
{
	// Functions the client calls on the server.
	reliable if ( ROLE < ROLE_Authority)
		ServerSetInfo;

	// Functions the server calls on the client.
	reliable if ( ROLE == ROLE_Authority)
		ClientGetInfo, ClientSetInfo;
}

// Functions the server calls on the client ///////////////////////////////////


/* ============================================================================
:: ClientGetInfo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
simulated function ClientGetInfo(string IP)
{
	ServerSetInfo( IPC.IPAddr , IPC.Idx);
}

/* ============================================================================
:: ClientSetInfo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
simulated function ClientSetInfo( string IP, string IPAddr, int Idx )
{
	IPC.IP = IP;
	IPC.IPAddr = IPAddr;
	IPC.Idx = Idx;
	ECVTEST = CVA_coach;
	SaveConfig();
}

// Functions the client calls on the server ///////////////////////////////////

/* ============================================================================
:: ServerSetInfo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
simulated function ServerSetInfo( string IPAddr, int Idx )
{
	bIsReady = True;
	IPC.Idx = Idx;
	IPC.IPAddr = IPAddr;
}

// Server-side Functions ////////////////////////////////////////////////////////////

/* ============================================================================
:: RetrieveInfo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function RetrieveInfo(string IP)
{
	ClientGetInfo( IP );
}

/* ============================================================================
:: PostBeginPlay ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
event PostBeginPlay()
{
	SetTimer(1, true);
}

/* ============================================================================
:: Timer ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function Timer()
{
	if(bIsReady && GI.bGameStarted)
	{
		GI.LMS_FindPlayer( IPC.IPAddr, IPC.Idx, Stats.PP, Stats.PRI, Stats, self );
		bIsReady = false;
		Destroy();
	}
}

/*
:: End of sLMS_RI ::
============================================================================ */
defaultproperties
{
    PenaltyTime=30
    StartupTime=60
    NetUpdateFrequency=1.00
}
