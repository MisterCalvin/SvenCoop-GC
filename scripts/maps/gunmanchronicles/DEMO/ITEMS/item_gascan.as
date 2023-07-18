#include "../AMMO/GC_ScriptBasePlayerAmmoEntity"

//const int GC_URANIUM_GIVE		=	25;
//const int GC_URANIUM_MAXCARRY	=	150;
//string gascan_model = "models/gunmanchronicles/gastank.mdl"

class item_gascan : GC_ScriptBasePlayerAmmoEntity
{
	void Precache()
	{
		GC_ScriptBasePlayerAmmoEntity::Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/gastank.mdl" );
        //g_Game.PrecacheModel( gascan_model );
	}
	
	void Spawn()
	{
		Precache();
		
		this.AmmoType			= "uranium";
		this.AmmoGiveAmount		= GC_URANIUM_GIVE;
		this.AmmoMaxCarry		= GC_URANIUM_MAXCARRY;
		
		g_EntityFuncs.SetModel( self, "models/gunmanchronicles/gastank.mdl" );
        //g_Game.PrecacheModel( gascan_model );
		
		GC_ScriptBasePlayerAmmoEntity::Spawn();
	}
}

void RegisterEntity_GasCan()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "item_gascan", "item_gascan" );
}