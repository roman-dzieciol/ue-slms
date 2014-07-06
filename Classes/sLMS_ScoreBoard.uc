/* ============================================================================
:: sLMS_ScoreBoard ::
:: ============================================================================
:: Copyright © 2002 Roman Dzieciol ::::::::::: Switch` switch@thieveryut.com ::
============================================================================ */
class sLMS_ScoreBoard expands LMSScoreboard;

var localized string LivesString, DmgString, PLString, TPString;

struct sLMS_Player
{
	var PlayerReplicationInfo PRI;
	var sLMS_Stats Stats;
};

var sLMS_GRI GRI;
var sLMS_Player Players[32];

/* ============================================================================
:: ShowScores :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function ShowScores( canvas Canvas )
{
	local int PlayerCount, i;
	local float XL, YL, Scale;
	local float YOffset, YStart;
	local font CanvasFont;

	Canvas.Style = ERenderStyle.STY_Normal;	// SETUP :: Global
	Canvas.SetPos(0, 0);					// SETUP :: Header
	DrawHeader(Canvas);						// DRAW :: Header

	GRI = sLMS_GRI(PlayerPawn(Owner).GameReplicationInfo);	// Get GameReplicationInfo
	LMS_GetPlayers( GRI, PlayerCount );						// Fill Players Array
	LMS_SortScores( PlayerCount );							// Sort Players Array

	// SETUP :: Category Header
	CanvasFont = Canvas.Font;
	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	Canvas.SetPos(0, 160.0/768.0 * Canvas.ClipY);

	// DRAW :: Category Header
	DrawCategoryHeaders( Canvas );

	// SETUP :: Name and Ping
	Canvas.StrLen( "TEST", XL, YL );
	YStart = Canvas.CurY;
	YOffset = YStart;
	if ( PlayerCount > 15 )
		PlayerCount = FMin(PlayerCount, (Canvas.ClipY - YStart)/YL - 1);

	Canvas.SetPos(0, 0);
	for ( i=0; i<PlayerCount; i++ )
	{
		YOffset = YStart + I * YL;

		// DRAW :: Name and Ping
		LMS_DrawNameAndPing( Canvas, Players[I], 0, YOffset, false );

		// SETUP :: next Name and Ping
		if((Players[I+1].PRI != None)
		&& (Players[I+1].PRI.bIsSpectator)
		&& (Players[I].PRI.bIsSpectator))
			Canvas.Font = MyFonts.GetSmallFont(Canvas.ClipX);
		else
			Canvas.Font = MyFonts.GetMediumFont(Canvas.ClipX);
	}

	// SETUP :: Trailer
	Canvas.DrawColor = WhiteColor;
	Canvas.Font = CanvasFont;

	// Trailer
	if ( !Level.bLowRes )
	{
		Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
		DrawTrailer(Canvas);
	}
	Canvas.DrawColor = WhiteColor;
	Canvas.Font = CanvasFont;
}

/* ============================================================================
:: DrawCategoryHeaders ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function DrawCategoryHeaders( Canvas Canvas )
{
	local float Offset, XL, YL;

	Offset = Canvas.CurY;
	Canvas.DrawColor = WhiteColor;

	Canvas.StrLen(PlayerString, XL, YL);	Canvas.SetPos((Canvas.ClipX / 18) * 1, Offset);		Canvas.DrawText(PlayerString);
	Canvas.StrLen(LivesString, XL, YL); 	Canvas.SetPos((Canvas.ClipX / 9)*3 - XL/2, Offset);	Canvas.DrawText(LivesString);

	Canvas.Font = MyFonts.GetSmallFont(Canvas.ClipX);

	Canvas.StrLen(FragsString, XL, YL);		Canvas.SetPos((Canvas.ClipX / 9)*4 - XL/2, Offset);	Canvas.DrawText(FragsString);
	Canvas.StrLen(DmgString, XL, YL);		Canvas.SetPos((Canvas.ClipX / 9)*5 - XL/2, Offset);	Canvas.DrawText(DmgString);
	Canvas.StrLen(TPString, XL, YL);		Canvas.SetPos((Canvas.ClipX / 9)*6 - XL/2, Offset);	Canvas.DrawText(TPString);

	if (Level.NetMode != NM_StandAlone)
	{
		Canvas.StrLen(PingString, XL, YL);	Canvas.SetPos((Canvas.ClipX / 9)*7 - XL/2, Offset);	Canvas.DrawText(PingString);
		Canvas.StrLen(PLString, XL, YL);	Canvas.SetPos((Canvas.ClipX / 9)*8 - XL/2, Offset);	Canvas.DrawText(PLString);
	}

	Canvas.Font = MyFonts.GetMediumFont(Canvas.ClipX);
}

/* ============================================================================
:: DrawNameAndPing ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function DrawNameAndPing(Canvas Canvas, PlayerReplicationInfo PRI, float XOffset, float YOffset, bool bCompressed)
{
}

/* ============================================================================
:: LMS_GetPlayers ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function LMS_GetPlayers( sLMS_GRI GRI, out int PlayerCount )
{
	local int i;
	local sLMS_Stats Stats;
	local PlayerReplicationInfo PRI;

	// Wipe everything.
	for ( i=0; i<ArrayCount(Players); i++ )
	{
		Players[i].PRI = None;
		Players[i].Stats = None;
	}
	// Add Normal Players
	for ( i=0; i<32; i++ )
	{
		if (GRI.Stats[i] != None)
		{
			Stats = GRI.Stats[i];
			PRI = Stats.PRI;

   			if((PRI.PlayerName == "Player") && (PRI.Ping == 0))
            	continue;

			Players[PlayerCount].PRI = PRI;
			Players[PlayerCount].Stats = Stats;

			PlayerCount++;
			if ( PlayerCount == ArrayCount(Players) )
				break;
		}
	}
}

/* ============================================================================
:: LMS_DrawNameAndPing ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function LMS_DrawNameAndPing(Canvas Canvas, sLMS_Player P, float XOffset, float YOffset, bool bCompressed)
{
	local float XL, YL, XL2;
	local Font CanvasFont, MainFont, CurFont;
	local int TimePlayed, inTimeCached, inTimeStart, inTimeEnd;
	local string TM, TS;
	local string inName, inTime;
	local string inLives, inFrags, inDamage, inPing, inPL;
	local sLMS_Stats Stats;
	local PlayerReplicationInfo PRI;

	PRI = P.PRI;
	Stats = P.Stats;

	// FIXME :: Setup scoreboard layout for spectators
	if( PRI.bIsSpectator )
	{
		Canvas.Style = 3;
		MainFont = MyFonts.GetSmallFont(Canvas.ClipX);
	}
	else
	{
		Canvas.Style = 1;
		MainFont = MyFonts.GetMediumFont(Canvas.ClipX);
	}

	inName = PRI.PlayerName;
	inPing = string(Stats.Ping);
	inPL = string(Stats.PacketLoss);

	// Get Stats info
	if( Stats.bIsPlayer  )
	{
		if( PRI.bIsABot )
		{
			inDamage = string(Stats.Damage);
			inFrags = string(Stats.Frags);
		}
		else if( Stats.TimeStart != -1 )
		{
			inLives = string(int(PRI.Score));
			inDamage = string(Stats.Damage);
			inFrags = string(Stats.Frags);

			inTimeCached = Stats.TimeCached;
			inTimeStart = Stats.TimeStart;

			if(Stats.TimeEnd == -1) 	inTimeEnd = LMS_GetTime();
			else						inTimeEnd = Stats.TimeEnd;

			TimePlayed = (inTimeEnd - inTimeStart) + inTimeCached;

			TM = string(TimePlayed / 60);
			TS = string(int(TimePlayed % 60));

			while(Len(TM) < 2)	TM = "0"$TM;
			while(Len(TS) < 2)	TS = "0"$TS;

			inTime = TM$":"$TS;
		}
	}
	else
	{
		inLives="-";
		inDamage="-";
		inFrags="-";
		inTime="--:--";
	}

	// Draw Name
	if( PRI.bAdmin )													Canvas.DrawColor = WhiteColor;
	else if(inName == Pawn(Owner).PlayerReplicationInfo.PlayerName)		Canvas.DrawColor = GoldColor;
	else																Canvas.DrawColor = CyanColor;

	Canvas.Font = MainFont;

	// Player Name
	Canvas.SetPos((Canvas.ClipX / 18) * 1, YOffset);	Canvas.DrawText(inName, False);

	// Keep the gap betwen items
	Canvas.Font = MyFonts.GetMediumFont(Canvas.ClipX);
	Canvas.StrLen( "0000", XL, YL );
	Canvas.Font = MainFont;

	// Draw Lives
	if ( PRI.Score < 1 )	Canvas.DrawColor = LightCyanColor;
	else					Canvas.DrawColor = GoldColor;
	Canvas.StrLen( inLives, XL2, YL );		Canvas.SetPos( (Canvas.ClipX / 9) * 3 + XL/2 - XL2, YOffset );	Canvas.DrawText( inLives, false );

	// Draw the rest with smaller font
	Canvas.DrawColor = LightCyanColor;
	Canvas.Font = MyFonts.GetSmallFont(Canvas.ClipX);

	// Frags, Damage
	Canvas.StrLen( inFrags, XL2, YL );	Canvas.SetPos( (Canvas.ClipX / 9) * 4 + XL/2 - XL2, YOffset );	Canvas.DrawText( inFrags, false );
	Canvas.StrLen( inDamage, XL2, YL );	Canvas.SetPos( (Canvas.ClipX / 9) * 5 + XL/2 - XL2, YOffset );	Canvas.DrawText( inDamage, false );
	Canvas.StrLen( inTime, XL2, YL );	Canvas.SetPos( (Canvas.ClipX / 9) * 6 + XL/2 - XL2, YOffset );	Canvas.DrawText( inTime, false );

	if (Level.NetMode != NM_Standalone)
	{
		Canvas.StrLen( inPing, XL2, YL );	Canvas.SetPos( (Canvas.ClipX / 9) * 7 + XL/2 - XL2, YOffset );	Canvas.DrawText( inPing, false );
		Canvas.StrLen( inPL, XL2, YL );		Canvas.SetPos( (Canvas.ClipX / 9) * 8 + XL/2 - XL2, YOffset );	Canvas.DrawText( inPL, false );
	}
	Canvas.Font = MyFonts.GetMediumFont(Canvas.ClipX);
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
:: LMS_SortScores :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function LMS_SortScores(int N)
{
	local int I, J, Max;
	local sLMS_Player TempPlayer;

	for ( I=0; I<N-1; I++ )
	{
		Max = I;

		for ( J=I+1; J<N; J++ )
		{
			if ( Players[J].PRI.Score > Players[Max].PRI.Score )
			{
				Max = J;
			}
			else if((Players[J].PRI.Score == Players[Max].PRI.Score)
				&& (Players[J].PRI.Deaths < Players[Max].PRI.Deaths))
			{
				Max = J;
			}
			else if((Players[J].PRI.Score == Players[Max].PRI.Score)
				 && (Players[J].PRI.Deaths == Players[Max].PRI.Deaths)
				 && (Players[J].PRI.PlayerID < Players[Max].PRI.Score))
			{
				Max = J;
			}
		}

		TempPlayer = Players[Max];
		Players[Max] = Players[I];
		Players[I] = TempPlayer;
	}
}

/*
:: End of sLMS_ScoreBoard ::
============================================================================ */
defaultproperties
{
    LivesString="Lives"
    DmgString="Damage"
    PLString="Packet Loss"
    TPString="Time Played"
    FragsString="Frags"
}
