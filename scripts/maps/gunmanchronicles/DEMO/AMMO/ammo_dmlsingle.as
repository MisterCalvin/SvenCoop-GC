#include "GC_ScriptBasePlayerAmmoEntity"

const int DML_GIVE			=	2;
const int DML_MAXCARRY		=	8;

class ammo_dmlsingle : GC_ScriptBasePlayerAmmoEntity
{
	void Precache()
	{
		GC_ScriptBasePlayerAmmoEntity::Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/dmlrocket.mdl" );
	}
	
	void Spawn()
	{
		Precache();
		
		this.AmmoType			= "rocket";
		this.AmmoGiveAmount		= DML_GIVE;
		this.AmmoMaxCarry		= DML_MAXCARRY;
		
		g_EntityFuncs.SetModel( self, "models/gunmanchronicles/dmlrocket.mdl" );
		
		GC_ScriptBasePlayerAmmoEntity::Spawn();
	}
}

void RegisterEntity_AmmoDMLSingle()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dmlsingle", "ammo_dmlsingle" );
}