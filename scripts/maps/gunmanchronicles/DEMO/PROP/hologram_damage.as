#include "CHologram"

//=========================================================
// Generic Monster - purely for scripted sequence work.
//=========================================================

enum hologramdamage_damagetype
{
	HOLOGRAMDAMAGE_DMG_GAUSS_PULSE = 0,
	HOLOGRAMDAMAGE_DMG_GAUSS_CHARGED,
	HOLOGRAMDAMAGE_DMG_GAUSS_RAPID,
	HOLOGRAMDAMAGE_DMG_GAUSS_SNIPER,
	HOLOGRAMDAMAGE_DMG_GENERIC_BULLET,
	HOLOGRAMDAMAGE_DMG_CHEMGUN_ACID,
	HOLOGRAMDAMAGE_DMG_CHEMGUN_BASE,
	HOLOGRAMDAMAGE_DMG_CHEMGUN_EXPLOSIVE,
	HOLOGRAMDAMAGE_DMG_CHEMGUN_SMOKE
}

//=========================================================
// Monster's Anim Events Go Here
//=========================================================

class hologram_damage : CHologram, HologramThink
{
	private string[] dmgEntityList = {
		"weapon_gausspistol",		// "gauss-pulse"
		"gauss_charged",			// "gauss-charged"
		"gauss_ball",				// "gauss-rapid"
		"cust_2GaussPistolSniper",	// "gauss-sniper"
		"GENERICBULLET",			// "generic-bullet"
		"chem_grenade",				// "chemgun acid damage"
		"chem_grenade",				// "chemgun base damage"
		"chem_grenade",				// "chemgun explosive damage"
		"chem_grenade"				// "chemgun smoke damage"
	};
	
	int		m_iDmgType;
	
	string[] DamageEntityList
	{
		get const { return dmgEntityList; }
	}
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "damagetype" )
		{
			m_iDmgType = atoi( szValue );
			return true;
		}
		else
			return CHologram::KeyValue( szKey, szValue );
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		int result = BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		
		if( result > 0 && flDamage > 0.0f )
		{
			switch( m_iDmgType )
			{
				case HOLOGRAMDAMAGE_DMG_GENERIC_BULLET:
				{
					if( bitsDamageType & DMG_GENERIC != 0 || bitsDamageType & DMG_BULLET != 0 )
						break;
				}
				default:
				{
					if( pevInflictor.ClassNameIs( dmgEntityList[m_iDmgType] ) == false )
					{
						// fire fail target
						FireFailTarget();
						
						return 0;
					}
				}
			}
			
			self.pev.solid	= SOLID_NOT;
			
			m_flNextFail	=	0.0f;
			
			CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );
			self.SUB_UseTargets( pAttacker, USE_TOGGLE, flDamage );
			
			if( pAttacker !is null) pevAttacker.frags += pAttacker.GetPointsForDamage( flDamage );
		}
		
		return result;
	}
	
	void Killed( entvars_t@ pevAtttacker, int iGibbed )
	{
		CHologram::Killed( pevAtttacker, iGibbed );
		
		// fire fail target
		FireFailTarget();
	}
	
}

void RegisterEntity_HologramDamage()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "hologram_damage", "hologram_damage" );
}
