#include "CHologram"

//=========================================================
// Generic Monster - purely for scripted sequence work.
//=========================================================


//=========================================================
// Monster's Anim Events Go Here
//=========================================================

class hologram_beak : CHologram, HologramThink
{
	// default hologram implementation
	
	void Enable()
	{
		CHologram::Enable();
		
		// Get sequence bbox
		self.pev.mins = Vector( -16, -16, 0 );
		self.pev.maxs = Vector(  16,  16, 48 );
		g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
		
		//self.ChangeSchedule( BaseClass.GetScheduleOfType( SCHED_IDLE_STAND ) );
	}
	
	void Child_RespawnThink()
	{
		CHologram::RespawnThink();
		
		self.SUB_UseTargets( self, USE_SET, -1000 );
		
		g_Game.AlertMessage( at_console, "NOTICES ME, SENPAI! \n" );
	}
}

void RegisterEntity_HologramBeak()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "hologram_beak", "hologram_beak" );
}

