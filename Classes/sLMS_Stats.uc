/* ============================================================================
:: sLMS_Stats ::
:: ============================================================================
:: Copyright © 2002 Roman Dzieciol ::::::::::: Switch` switch@thieveryut.com ::
============================================================================ */
class sLMS_Stats expands ReplicationInfo;

/* ============================================================================
:: Variables ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */

// Player Stats
var PlayerReplicationInfo PRI;
var PlayerPawn PP;

var() sLMS_Token Token;

var bool bIsPlayer;
var() int Frags, Damage;
var() int Ping, PacketLoss;
var() int TimeCached, TimeStart, TimeEnd;
var() int TimeRespawn, PreDamage;

/* ============================================================================
:: Replication ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
replication
{
	// Things the server should send to the client.
	reliable if ( Role == ROLE_Authority )
		Frags, Damage, TimeCached, TimeStart, TimeEnd, Ping, PacketLoss, bIsPlayer;
}

/* ============================================================================
:: PostBeginPlay ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function PostBeginPlay()
{
	Timer();
	SetTimer(2.0, true);
}

/* ============================================================================
:: Timer ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function Timer()
{
	// Update Pawn Stats
	if (PlayerPawn(Owner) != None)
	{
		// Ping & PacketLoss
		if ( FRand() < 0.65 )	return;
		Ping = 0.8 * int(PlayerPawn(Owner).ConsoleCommand("GETPING"));
		PacketLoss = int(PlayerPawn(Owner).ConsoleCommand("GETLOSS"));
	}
}

/*
:: End of sLMS_Stats ::
============================================================================ */
defaultproperties
{
    TimeStart=-1
    TimeEnd=-1
    NetUpdateFrequency=2.00
}
