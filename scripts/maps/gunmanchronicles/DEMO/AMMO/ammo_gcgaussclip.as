#include "GC_ScriptBasePlayerAmmoEntity"

const int GC_URANIUM_GIVE		=	25;
const int GC_URANIUM_MAXCARRY	=	150;

class ammo_gcgaussclip : GC_ScriptBasePlayerAmmoEntity
{
	void Precache()
	{
		GC_ScriptBasePlayerAmmoEntity::Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/guassammo.mdl" );
	}
	
	void Spawn()
	{
		Precache();
		
		this.AmmoType			= "uranium";
		this.AmmoGiveAmount		= GC_URANIUM_GIVE;
		this.AmmoMaxCarry		= GC_URANIUM_MAXCARRY;
		
		g_EntityFuncs.SetModel( self, "models/gunmanchronicles/guassammo.mdl" );
		
		GC_ScriptBasePlayerAmmoEntity::Spawn();
	}
}

void RegisterEntity_AmmoGCGaussClip()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_gcgaussclip", "ammo_gcgaussclip" );
}