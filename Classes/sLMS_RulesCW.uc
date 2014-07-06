/* ============================================================================
:: sLMS_RulesCW ::
:: ============================================================================
:: Copyright © 2002 Roman Dzieciol ::::::::::: Switch` switch@thieveryut.com ::
============================================================================ */
class sLMS_RulesCW expands UTRulesCWindow;

/* ============================================================================
:: Variables ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */

//-----------------------------------------------------------------------------
// Usual UCopyPasteWindows ugly crap

// PenaltyTime
var UWindowEditControl PenaltyTimeEdit;
var localized string PenaltyTimeText;
var localized string PenaltyTimeHelp;

// StartupTime
var UWindowEditControl StartupTimeEdit;
var localized string StartupTimeText;
var localized string StartupTimeHelp;

/* ============================================================================
:: Functionality ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function Created()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, ButtonWidth, ButtonLeft;

	Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	ButtonWidth = WinWidth - 140;
	ButtonLeft = WinWidth - ButtonWidth - 40;

	// PenaltyTime
	PenaltyTimeEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlLeft, ControlOffset, ControlWidth, 1));
	PenaltyTimeEdit.SetText(PenaltyTimeText);
	PenaltyTimeEdit.SetHelpText(PenaltyTimeHelp);
	PenaltyTimeEdit.SetFont(F_Normal);
	PenaltyTimeEdit.SetNumericOnly(True);
	PenaltyTimeEdit.SetMaxLength(3);
	PenaltyTimeEdit.Align = TA_Right;
	ControlOffset += 25;

	// StartupTime
	StartupTimeEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlLeft, ControlOffset, ControlWidth, 1));
	StartupTimeEdit.SetText(StartupTimeText);
	StartupTimeEdit.SetHelpText(StartupTimeHelp);
	StartupTimeEdit.SetFont(F_Normal);
	StartupTimeEdit.SetNumericOnly(True);
	StartupTimeEdit.SetMaxLength(3);
	StartupTimeEdit.Align = TA_Right;
	ControlOffset += 25;
}

function LoadCurrentValues()
{
	Super.LoadCurrentValues();

	PenaltyTimeEdit.SetValue(string(Class'sLMS_RI'.Default.PenaltyTime));
	StartupTimeEdit.SetValue(string(Class'sLMS_RI'.Default.StartupTime));
}

function BeforePaint(Canvas C, float X, float Y)
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, ButtonWidth, ButtonLeft;

	Super.BeforePaint(C, X, Y);

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	PenaltyTimeEdit.SetSize(ControlWidth, 1);
	PenaltyTimeEdit.WinLeft = ControlLeft;
	PenaltyTimeEdit.EditBoxWidth = 25;

	StartupTimeEdit.SetSize(ControlWidth, 1);
	StartupTimeEdit.WinLeft = ControlLeft;
	StartupTimeEdit.EditBoxWidth = 25;
}

function Notify(UWindowDialogControl C, byte E)
{
	if (!Initialized)
		return;

	Super.Notify(C, E);

	switch(E)
	{
	case DE_Change:
		switch(C)
		{
			case PenaltyTimeEdit:
				PenaltyTimeChanged();
				break;
			case StartupTimeEdit:
				StartupTimeChanged();
				break;
		}
	}
}

function PenaltyTimeChanged()
{
	Class'sLMS_RI'.Default.PenaltyTime = int(PenaltyTimeEdit.GetValue());
}

function StartupTimeChanged()
{
	Class'sLMS_RI'.Default.StartupTime = int(StartupTimeEdit.GetValue());
}

function SaveConfigs()
{
	Super.SaveConfigs();
	Class'sLMS_RI'.static.StaticSaveConfig();
	GetPlayerOwner().SaveConfig();
}

/*
:: End of sLMS_RulesCW ::
============================================================================ */
defaultproperties
{
    PenaltyTimeText="Penalty Time"
    PenaltyTimeHelp="Penalty Time"
    StartupTimeText="Startup Time"
    StartupTimeHelp="Startup Time"
}
