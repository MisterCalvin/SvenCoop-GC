#include "GC_ScriptBasePlayerAmmoEntity"

const int GCMINIGUN_GIVE			=	30;
const int GCMINIGUN_MAXCARRY		=	200;

class ammo_gcminigunclip : GC_ScriptBasePlayerAmmoEntity
{
	void Precache()
	{
		GC_ScriptBasePlayerAmmoEntity::Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/mechammo.mdl" );
	}
	
	void Spawn()
	{
		Precache();
		
		this.AmmoType			= "9mm";
		this.AmmoGiveAmount		= GCMINIGUN_GIVE;
		this.AmmoMaxCarry		= GCMINIGUN_MAXCARRY;
		
		g_EntityFuncs.SetModel( self, "models/gunmanchronicles/mechammo.mdl" );
		
		GC_ScriptBasePlayerAmmoEntity::Spawn();
	}
}

void RegisterEntity_AmmoGCMinigunClip()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_gcminigunclip", "ammo_gcminigunclip" );
}