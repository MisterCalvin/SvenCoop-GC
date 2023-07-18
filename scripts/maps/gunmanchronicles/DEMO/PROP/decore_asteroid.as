#include "gunman_cycler"

enum decore_asteroid_size {
		ASTEROID_SIZE_BIG		= 0,
		ASTEROID_SIZE_MEDIUM,
		ASTEROID_SIZE_SMALL
};

class decore_asteroid : gunman_cycler
{
	int     m_iAsteroidSize			= ASTEROID_SIZE_SMALL;
	float	m_flMaxRotation			= 0.5f;
	float	m_flMinRotation			= 0.1f;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "asteroidsize" )
		{
			m_iAsteroidSize = Math.clamp( ASTEROID_SIZE_BIG, ASTEROID_SIZE_SMALL, atoi( szValue ) );
			return true;
		}
		/*else if ( szKey == "size" )
		{
			self.pev.scale = atof( szValue );
			return true;
		}*/
		else if ( szKey == "maxrotation" )
		{
			m_flMaxRotation = Math.clamp( 0.0, 360.0f, atof( szValue ) );
			return true;
		}
		else if ( szKey == "minrotation" )
		{
			m_flMinRotation = Math.clamp( 0.0, 360.0f, atof( szValue ) );
			return true;
		}
		else
			return gunman_cycler::KeyValue( szKey, szValue );
	}
	
	void Spawn()
	{
		gunman_cycler::Spawn();
		
		//uint findd = self.pev.model.opImplConv().Find( "Asteroid.mdl" ); // KCM - Removed
        uint findd = string( self.pev.model ).Find( "Asteroid.mdl" );
        
		//if( findd > 7 && findd < self.pev.model.opImplConv().Length() ) // KCM - Removed
        if( findd > 7 && findd < string( self.pev.model ).Length() )
		{
			float flScale = 1.0f;
			int   iBody   = 0;
			
			flScale = 3.0f;
			
			switch( m_iAsteroidSize )
			{
				case ASTEROID_SIZE_BIG:
				{
					iBody	=	1;
					flScale	=	5.0f;
					break;
				}
				case ASTEROID_SIZE_MEDIUM:
				{
					iBody	=	1;
					flScale	=	5.0f;
					break;
				}
				case ASTEROID_SIZE_SMALL:
				{
					iBody	=	0;
					flScale	=	5.0f;
					break;
				}
			}
			
			self.pev.body  = iBody;
			self.pev.scale = flScale;
		}
		
		self.pev.movetype		= MOVETYPE_FLY;
	}
	
	void Think()
	{
		gunman_cycler::Think();
		
		float flRotate     = Math.RandomFloat( m_flMinRotation, m_flMaxRotation );
		self.pev.angles.x += flRotate;
		self.pev.angles.y += flRotate;
		self.pev.angles.z += flRotate;
		
		if( self.pev.angles.x >= 360.0 )
			self.pev.angles.x = 0.0;
		
		if( self.pev.angles.y >= 360.0 )
			self.pev.angles.y = 0.0;
		
		if( self.pev.angles.z >= 360.0 )
			self.pev.angles.z = 0.0;
	}
}

void RegisterEntity_DecoreAsteroid()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "decore_asteroid", "decore_asteroid" );
}
