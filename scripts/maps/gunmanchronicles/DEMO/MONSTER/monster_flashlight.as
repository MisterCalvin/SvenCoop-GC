//=========================================================
// Generic Monster - purely for scripted sequence work.
//=========================================================
const int	SF_FLASHLIGHT_POINT			=		32;

#include "monster_human_unarmed"
class monster_flashlight : monster_human_unarmed
{
	void Spawn()
	{
		g_EntityFuncs.DispatchKeyValue( self.edict(), "gunstate", "2" );
		
		monster_human_unarmed::Spawn();
		
		self.SetBodygroup( GROUP_DECORE , 1 );
		
		if( self.pev.spawnflags & SF_FLASHLIGHT_POINT != 0 )
		{
			self.pev.movetype 		= MOVETYPE_FLY;
		}
	}
}

void RegisterEntity_MonsterFlashlight()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_flashlight", "monster_flashlight" );
}