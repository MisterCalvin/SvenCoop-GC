#include "GC_ScriptBasePlayerAmmoEntity"

const int GC_BUCKSHOT_GIVE		=	16;
const int GC_BUCKSHOT_MAXCARRY	=	90;

class ammo_gcbuckshot : GC_ScriptBasePlayerAmmoEntity
{
	void Precache()
	{
		GC_ScriptBasePlayerAmmoEntity::Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/shotgunammo.mdl" );
	}
	
	void Spawn()
	{
		Precache();
		
		this.AmmoType			= "buckshot";
		this.AmmoGiveAmount		= GC_BUCKSHOT_GIVE;
		this.AmmoMaxCarry		= GC_BUCKSHOT_MAXCARRY;
		
		g_EntityFuncs.SetModel( self, "models/gunmanchronicles/shotgunammo.mdl" );
		
		GC_ScriptBasePlayerAmmoEntity::Spawn();
	}
}

void RegisterEntity_AmmoGCShotgun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_gcbuckshot", "ammo_gcbuckshot" );
}