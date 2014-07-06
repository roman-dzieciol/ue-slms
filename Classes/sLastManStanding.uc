/* ============================================================================
:: sLastManStanding ::
:: ============================================================================
:: Copyright © 2002 Roman Dzieciol ::::::::::: Switch` switch@thieveryut.com ::
============================================================================ */
class sLastManStanding expands LastManStanding;

//-----------------------------------------------------------------------------
// Variables

var bool bGameIsLocked;
var bool bGameStarted;
var string ServerIP;

var int IPC;
var sLMS_Token	IPCache[2048];
var sLMS_GRI 	GRI;

// Events /////////////////////////////////////////////////////////////////////

/* ============================================================================
:: PreBeginPlay :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
event PreBeginPlay()
{
	Super.PreBeginPlay();

	// Create Damage Mutator
	RegisterDamageMutator(Spawn(Class'sLMS.sLMS_DamageMutator'));
}

/* ============================================================================
:: AcceptInventory ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
event AcceptInventory(pawn PlayerPawn)
{
	local inventory Inv;
	local LadderInventory LadderObj;

	// DeathMatchPlus accepts LadderInventory
	for( Inv=PlayerPawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		if (Inv.IsA('LadderInventory'))	LadderObj = LadderInventory(Inv);
		else							Inv.Destroy();
	}

	PlayerPawn.Weapon = None;
	PlayerPawn.SelectedItem = None;
}

/* ============================================================================
:: Login ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
event playerpawn Login( string Portal, string Options, out string Error, class<playerpawn> SpawnClass )
{
	LMS_SpawnClass( SpawnClass );
	return Super(DeathMatchPlus).Login(Portal, Options, Error, SpawnClass);
}

/* ============================================================================
:: PostLogin ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
event PostLogin( playerpawn NewPlayer )
{
	local sLMS_Stats S;

	Super(DeathMatchPlus).PostLogin(NewPlayer);

	if( LMS_IsPlayer(NewPlayer) )
	{
		Log("## GI # Found LMS Player :: "$NewPlayer.PlayerReplicationInfo.PlayerName, 'sLMS');
		S.bIsPlayer = true;

		// Should start as spectator
		NewPlayer.PlayerRestartState = 'PlayerSpectating';
		NewPlayer.bHidden = true;

		// Create Stats for this player
		S = LMS_CreateStats( NewPlayer, true );

		// Create RI object
		LMS_CreateRI( NewPlayer, S );
	}
	else
	{
		// Create Stats for this spectator
		S = LMS_CreateStats( NewPlayer, false );
	}

	// EndStats Fix
	if( NewPlayer.Player != None && Viewport(NewPlayer.Player) != None)	LocalPlayer = NewPlayer;
}

// Standard Functions /////////////////////////////////////////////////////////

/* ============================================================================
:: AdminLogout ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function AdminLogout( PlayerPawn P )
{
	if (P.bAdmin)
	{
		P.bAdmin = False;
		P.PlayerReplicationInfo.bAdmin = P.bAdmin;
		BroadcastMessage( P.PlayerReplicationInfo.PlayerName@"gave up administrator abilities." );
		Log("Administrator logged out.");
	}
}

/* ============================================================================
:: EndGame ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function EndGame( string Reason )
{
	if( (Reason == "lastmanstanding") && !bGameIsLocked )	return;
	else Super.EndGame( Reason );
}

/* ============================================================================
:: EndGame ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function InitGameReplicationInfo()
{
	Super.InitGameReplicationInfo();
	GRI = sLMS_GRI(GameReplicationInfo);
}

/* ============================================================================
:: Logout :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function Logout( pawn Exiting )
{
	LMS_UpdateCache( Exiting );
	Super.Logout( Exiting );
	GRI.DestroyStats( Exiting );
}

/* ============================================================================
:: NeedPlayers ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function bool NeedPlayers()
{
	if( bGameEnded || bGameIsLocked )	return false;
	return (NumPlayers + NumBots < MinPlayers);
}

/* ============================================================================
:: ReduceDamage :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function int ReduceDamage( int Damage, name DamageType, pawn Injured, pawn instigatedBy )
{
    local sLMS_Stats Stats;

	GRI.GetStats( Injured, Stats );
	Damage = Super.ReduceDamage(Damage, DamageType, Injured, instigatedBy);

	if((InstigatedBy != None) && (Injured != None) && (Stats != None) && InstigatedBy.bIsPlayer && Injured.bIsPlayer)
	{
		if( InstigatedBy != Injured )			Stats.PreDamage = LMS_ArmorCharge(Injured, Damage, DamageType, Injured.Location);
		else if( LMS_JustRespawned(Stats) )		Damage = 0;
	}

	return Damage;
}

/* ============================================================================
:: RestartPlayer ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function bool RestartPlayer( pawn aPlayer )
{
	local NavigationPoint startSpot;
	local bool foundStart;
	local Pawn P;
	local sLMS_Stats Stats;
	local PlayerReplicationInfo PRI;

	// Log this event
//	if( aPlayer.IsA('PlayerPawn'))	Log("## GI # RestartPlayer :: "$PlayerPawn(aPlayer).PlayerReplicationInfo.PlayerName, 'sLastManStanding');

	if( bRestartLevel && (Level.NetMode != NM_DedicatedServer) && (Level.NetMode != NM_ListenServer) )	return true;

	// Get required objects
	GRI.GetStats( aPlayer, Stats );
	PRI = aPlayer.PlayerReplicationInfo;

	if( Stats != None ) Stats.TimeRespawn = LMS_GetTime();

	if( (PRI.Score < 1) && (aPlayer.PlayerRestartState != 'PlayerSpectating') )
	{
		// Announce player's death
		BroadcastLocalizedMessage(class'LMSOutMessage', 0, PRI);

		// Update death time
		if( (Stats != None) && (Stats.TimeEnd == -1) )	Stats.TimeEnd = LMS_GetTime();

		// Scoreboard
		For( P=Level.PawnList; P!=None; P=P.NextPawn )
			if ( P.bIsPlayer && (PRI.Score >= 1) )
				PRI.Score += 0.00001;

		// bots don't respawn when ghosts
		if( aPlayer.IsA('Bot') )
		{
			PRI.bIsSpectator = true;
			PRI.bWaitingPlayer = true;
			aPlayer.GotoState('GameEnded');
			return false;
		}
	}

	startSpot = FindPlayerStart(None, 255);
	if( startSpot == None )
		return false;

	foundStart = aPlayer.SetLocation(startSpot.Location);
	if( foundStart )
	{
		startSpot.PlayTeleportEffect( aPlayer, true );
		aPlayer.SetRotation( startSpot.Rotation );
		aPlayer.ViewRotation = aPlayer.Rotation;
		aPlayer.Acceleration = vect(0,0,0);
		aPlayer.Velocity = vect(0,0,0);
		aPlayer.Health = aPlayer.Default.Health;
		aPlayer.ClientSetRotation( startSpot.Rotation );
		aPlayer.bHidden = false;
		aPlayer.SoundDampening = aPlayer.Default.SoundDampening;

		if( PRI.Score < 1 )
		{
			aPlayer.PlayerRestartState = 'PlayerSpectating';

			// This guy is a ghost.  Add a visual effect.
			if( bHighDetailGhosts )
			{
				aPlayer.Style = STY_Translucent;
				aPlayer.ScaleGlow = 0.5;
			}
			else
				aPlayer.bHidden = true;
		}
		else
		{
			aPlayer.SetCollision( true, true, true );
			AddDefaultInventory( aPlayer );
		}
	}

	return foundStart;
}

/* ============================================================================
:: ScoreKill ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function ScoreKill(pawn Killer, pawn Other)
{
    local sLMS_Stats Stats;

	GRI.GetStats( Killer, Stats );
	Other.DieCount++;

	if( Other.PlayerReplicationInfo.Score > 0 )
		Other.PlayerReplicationInfo.Score -= 1;

	if((killer != Other) && (killer != None) )
	{
		if( Stats != None ) Stats.Frags++;
		killer.killCount++;
	}

	if( (LMS_IsPlayer(Other)) && (Other.PlayerReplicationInfo.Score < 1) ) bGameIsLocked = True;
	BaseMutator.ScoreKill(Killer, Other);
}

/* ============================================================================
:: SpawnBot :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function Bot SpawnBot(out NavigationPoint StartSpot)
{
	local bot NewBot;

	NewBot = Super.SpawnBot( StartSpot );

	if( NewBot != None )
		LMS_CreateStats( NewBot, true );

	return NewBot;
}
/* ============================================================================
:: StartMatch :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function StartMatch()
{
	local Pawn P;
	local TimedTrigger T;

	// Log Stats
	if (LocalLog != None)	LocalLog.LogGameStart();
	if (WorldLog != None)	WorldLog.LogGameStart();

	// Init objects
	ForEach AllActors(class'TimedTrigger', T)	T.SetTimer(T.DelaySeconds, T.bRepeating);
	if ( Level.NetMode != NM_Standalone )		RemainingBots = 0;
	GRI.RemainingMinute = RemainingTime;

	bStartMatch = true;

	// Dont start playerpawns, send only the message
	for( P = Level.PawnList; P!=None; P=P.nextPawn )
	{
		if( P.bIsPlayer && P.IsA('PlayerPawn') )	SendStartMessage(PlayerPawn(P));
	}

	// Start non-playerpawns
	for( P = Level.PawnList; P!=None; P=P.nextPawn )
	{
		if( P.bIsPlayer && !P.IsA('PlayerPawn') )
		{
			P.RestartPlayer();
			if( P.IsA('Bot') )	Bot(P).StartMatch();
		}
	}

	bStartMatch = false;
	bGameStarted = true;
}

// sLMS Functions /////////////////////////////////////////////////////////////

/* ============================================================================
:: LMS_CreateRI :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function LMS_CreateRI( PlayerPawn P, sLMS_Stats S )
{
	local sLMS_RI RI;

	// Create RI object
	RI = Spawn(class 'sLMS_RI',P,,P.Location);
	RI.GI = Self;
	RI.Stats = S;

	// Retrieve info from the client
	RI.RetrieveInfo(ServerIP);
}

/* ============================================================================
:: LMS_CreateStats ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function sLMS_Stats LMS_CreateStats( Pawn P, bool bIsPlayer )
{
	local sLMS_Stats Stats;

	// Create Stats object
	Stats = Spawn(class 'sLMS_Stats',P,,P.Location);
	Stats.PRI = P.PlayerReplicationInfo;
	Stats.bIsPlayer = bIsPlayer;
	Stats.PP = PlayerPawn(P);

	return Stats;
}

/* ============================================================================
:: LMS_UpdateCache ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function LMS_UpdateCache( pawn Exiting )
{
	local sLMS_Token T;
	local PlayerPawn PP;
	local PlayerReplicationInfo PRI;
	local sLMS_Stats Stats;

	PP = PlayerPawn(Exiting);			if(PP == None)		return;
	PRI = PP.PlayerReplicationInfo; 	if(PRI == None)		return;
	GRI.GetStats( Exiting, Stats );		if(Stats == None)	return;

	if( LMS_IsPlayer(PP) )
	{
		T.Score		= PRI.Score;
		T.Frags		= Stats.Frags;
		T.Damage	= Stats.Damage;
		T.ExitTime	= LMS_GetTime();
		if(Stats.TimeEnd == -1)	Stats.TimeEnd = LMS_GetTime();
		T.Time 		+= Stats.TimeEnd - Stats.TimeStart;

		// Log("## GI # Saving Player Info :: "$PRI.PlayerName, 'sLMS');
//		T.DumpInfo();
	}
}

/* ============================================================================
:: LMS_FindPlayer :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function LMS_FindPlayer( string IPAddr, int Idx, PlayerPawn PP, PlayerReplicationInfo PRI, sLMS_Stats Stats, sLMS_RI RI )
{
	local sLMS_Token T;

	// Load cached token
	T = IPCache[Idx];

	Log("## GI # Cached Token = "$T$" :: Idx = "$Idx, 'sLMS');

	if((T != None) && (T.IPAddr == IPAddr))
	{
		// Get Cached Info
		PRI.Score		= T.Score - LMS_PenaltyScore(T);
		Stats.Token		= T;
		Stats.Frags		= T.Frags;
		Stats.Damage	= T.Damage;
		Stats.TimeCached = T.Time;

		Log("## GI # Found Player = "$PRI.PlayerName$" :: Score = "$T.Score, 'sLMS');
	}
	else
	{
		// Cached Info not found, Create New Token
		T = New(None) class'sLMS_Token';

		T.IPAddr = int(RandRange(128,217))$"."$int(RandRange(2,254))$"."$int(RandRange(2,254))$"."$int(RandRange(2,254))$":7777";

		// Store pointer to cache
		Stats.Token = T;

		// Save it on client
		RI.ClientSetInfo( ServerIP, T.IPAddr, IPC);

		// Add token to cache
		IPCache[IPC] = T;
		IPC++;

		// During the first x seconds defined in StartupTime, players should get full amount of lives
		if(LMS_GetTime() < Class'sLMS_RI'.default.StartupTime)	PRI.Score = Lives;
		else													PRI.Score = LMS_AverageScore( Stats.PP, Stats );

		Log("## GI # New Player = "$PRI.PlayerName$" :: Score = "$T.Score, 'sLMS');
	}

	LMS_StartPlayer(PP, PRI, Stats);
}

/* ============================================================================
:: RI_StartPlayer :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function LMS_StartPlayer( PlayerPawn PP, PlayerReplicationInfo PRI, sLMS_Stats Stats )
{
	Log("## GI # Start Player :: "$PRI.PlayerName, 'sLMS');

    bStartMatch = true;
	if( Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer || !bRestartLevel )
	{
		Stats.TimeStart = LMS_GetTime();

		if(PRI.Score < 0)
		{
			PRI.Score = 0;
			PP.PlayerRestartState = 'PlayerSpectating';
			Stats.TimeEnd = LMS_GetTime();
		}
		else
		{
			PP.PlayerRestartState = PP.Default.PlayerRestartState;
		}

		if( (LMS_IsPlayer(PP)) && (PRI.Score < 1) )
		{
			bGameIsLocked = True;
			CheckEndGame();
		}

		if( RestartPlayer(PP) )		StartPlayer(PP);
		else						PP.GotoState('Dying');

	}
	else
		PP.ClientTravel( "?restart", TRAVEL_Relative, false );

	bStartMatch = false;
}

/* ============================================================================
:: LMS_ArmorCharge ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function int LMS_ArmorCharge( Pawn P, int Damage, name DamageType, vector HitLocation )
{
	local Inventory FirstArmor;
	local int TotalCharge;

	if( P.Inventory == None ) return 0;
	FirstArmor = P.Inventory.PrioritizeArmor(Damage, DamageType, HitLocation);

	while( FirstArmor != None )
	{
		TotalCharge += FirstArmor.Charge;
		FirstArmor = FirstArmor.nextArmor;
	}

	return TotalCharge;
}

/* ============================================================================
:: LMS_JustRespawned ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function bool LMS_JustRespawned( sLMS_Stats Stats )
{
	if( (LMS_GetTime() - Stats.TimeRespawn) < 3 )	return true;
	else											return false;
}

/* ============================================================================
:: LMS_IsPlayer :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function bool LMS_IsPlayer(Pawn P, optional Pawn NewPlayer)
{
	if((P == None) || ((NewPlayer != None) && (P == NewPlayer)))	return false;
//	if(P.PlayerReplicationInfo.bWaitingPlayer)						return false;
	if(!P.IsA('TournamentPlayer'))									return false;
	return true;
}

/* ============================================================================
:: LMS_PenaltyScore :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function int LMS_PenaltyScore( sLMS_Token T )
{
	local float ElapsedPenaltyTime, PenaltyScore, Result;

	ElapsedPenaltyTime	= LMS_GetTime() - T.ExitTime;
	PenaltyScore		= ElapsedPenaltyTime/Class'sLMS_RI'.default.PenaltyTime;
	Result				= int(PenaltyScore);

	if( Result < PenaltyScore ) Result += 1;

	return Result;
}

/* ============================================================================
:: LMS_AverageScore :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function int LMS_AverageScore( PlayerPawn NewPlayer, sLMS_Stats Stats )
{
	local Pawn P;
	local PlayerPawn PP;
	local float AvgScore;
	local int TotalScore, PlayerCount;

	For ( P=Level.PawnList; P!=None; P=P.NextPawn )
	{
		PP = PlayerPawn(P);
		if( (PP != None) && LMS_IsPlayer(PP, NewPlayer) && (Stats.TimeStart != -1))
		{
			TotalScore += PP.PlayerReplicationInfo.Score;
			PlayerCount++;
		}
	}

	AvgScore = (TotalScore/PlayerCount);
	if(PlayerCount == 0) AvgScore = Lives;

	return int(AvgScore);
}

/* ============================================================================
:: LMS_GetTime ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function int LMS_GetTime()
{
	if( (GRI.TimeLimit > 0) && (GRI.RemainingTime > 0) )	return (GRI.TimeLimit * 60) - GRI.RemainingTime;
	else													return GRI.ElapsedTime;
}

/* ============================================================================
:: LMS_SpawnClass :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function LMS_SpawnClass( out class<playerpawn> SpawnClass )
{
	if(bGameIsLocked)
	{
		bDisallowOverride = true;
		SpawnClass = class'CHSpectator';
		Log("## GI # Forcing Spectator SpawnClass :: "$SpawnClass, 'sLMS');
		if( (NumSpectators >= MaxSpectators) && ((Level.NetMode != NM_ListenServer) || (NumPlayers > 0)) )
			MaxSpectators++;
	}
}


/*
:: End of sLMS ::
============================================================================ */
defaultproperties
{
    StartUpMessage="Last Man Standing. How long can you live?"
    ScoreBoardType=Class'sLMS_ScoreBoard'
    RulesMenuType="sLMS.sLMS_RulesSC"
    GameName="sLast Man Standing - BETA 4"
    GameReplicationInfoClass=Class'sLMS_GRI'
}
