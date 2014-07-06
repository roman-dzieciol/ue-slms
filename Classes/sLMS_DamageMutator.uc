/* ============================================================================
:: sLMS_DamageMutator ::
:: ============================================================================
:: Copyright © 2002 Roman Dzieciol ::::::::::: Switch` switch@thieveryut.com ::
============================================================================ */
class sLMS_DamageMutator expands Mutator;

/* ============================================================================
:: MutatorTakeDamage ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function MutatorTakeDamage ( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, out Vector Momentum, name DamageType )
{
	local int ArmorDamage;

	if((InstigatedBy != None) && (Victim != None) && (InstigatedBy != Victim) && InstigatedBy.bIsPlayer  && Victim.bIsPlayer)
	{
		ArmorDamage = Max( 0, (GetPreDamage(Victim, ActualDamage) - GetArmorCharge( Victim, ActualDamage, DamageType, HitLocation )) );
		SetStatsDamage( InstigatedBy, ( Min(ActualDamage, Victim.Health) + ArmorDamage ) );
	}

	if( NextDamageMutator != None )
		NextDamageMutator.MutatorTakeDamage( ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType );
}

/* ============================================================================
:: GetArmorCharge :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function int GetArmorCharge( Pawn P, int Damage, name DamageType, vector HitLocation )
{
	local Inventory FirstArmor;
	local int TotalCharge;

	if( P.Inventory == None )
		return 0;

	FirstArmor = P.Inventory.PrioritizeArmor(Damage, DamageType, HitLocation);

	while( FirstArmor != None )
	{
		TotalCharge += FirstArmor.Charge;
		FirstArmor = FirstArmor.nextArmor;
	}

	return TotalCharge;
}

/* ============================================================================
:: GetPreDamage :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function int GetPreDamage( Pawn P, int ActualDamage )
{
	local sLMS_Stats Stats;

	sLMS_GRI(Level.Game.GameReplicationInfo).GetStats( P, Stats );
	if(Stats == None)	return 0;
	return (Stats.PreDamage - ActualDamage);
}

/* ============================================================================
:: SetStatsDamage :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
============================================================================ */
function SetStatsDamage( Pawn P, int StatsDamage )
{
	local sLMS_Stats Stats;

	sLMS_GRI(Level.Game.GameReplicationInfo).GetStats( P, Stats );
	if(Stats == None)	return;
	Stats.Damage += StatsDamage;
}

/*
:: End of sLMS_DamageMutator ::
============================================================================ */
defaultproperties
{
}
