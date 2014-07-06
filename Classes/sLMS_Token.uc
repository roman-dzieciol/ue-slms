/* ============================================================================
:: sLMS_Token ::
:: ============================================================================
:: Copyright © 2002 Roman Dzieciol ::::::::::: Switch` switch@thieveryut.com ::
============================================================================ */
class sLMS_Token expands Object;

var string	IPAddr;
var int		Score;
var int		Frags;
var int		Damage;
var int		ExitTime;
var int		Time;

function DumpInfo()
{
	Log("## Token ##############################", 'sLMS');
	Log("## Token # IPAddr	 = "$IPAddr, 'sLMS');
	Log("## Token # Score    = "$Score, 'sLMS');
	Log("## Token # Frags    = "$Frags, 'sLMS');
	Log("## Token # Damage   = "$Damage, 'sLMS');
	Log("## Token # ExitTime = "$ExitTime, 'sLMS');
	Log("## Token # Time     = "$Time, 'sLMS');
	Log("## Token ##############################", 'sLMS');
}

/*
:: End of sLMS_Token ::
============================================================================ */
defaultproperties
{
}
