/* ============================================================================
:: sLMS_RulesSC ::
:: ============================================================================
:: Copyright © 2002 Roman Dzieciol ::::::::::: Switch` switch@thieveryut.com ::
============================================================================ */
class sLMS_RulesSC expands UWindowScrollingDialogClient;

function Created()
{
	ClientClass = class'sLMS_RulesCW';
	FixedAreaClass = None;
	Super.Created();
}

/*
:: End of sLMS_RulesSC ::
============================================================================ */
defaultproperties
{
}
