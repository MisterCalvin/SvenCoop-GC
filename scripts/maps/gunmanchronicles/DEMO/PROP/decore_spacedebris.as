#include "gunman_cycler"

class decore_spacedebris : gunman_cycler
{
	bool	m_blRotate				= false;
	float	m_flAnglespeed			= 3.0f;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "dirx" )
		{
			self.pev.movedir.x = atof( szValue );
			return true;
		}
		else if ( szKey == "diry" )
		{
			self.pev.movedir.y = atof( szValue );
			return true;
		}
		else if ( szKey == "dirz" )
		{
			self.pev.movedir.z = atof( szValue );
			return true;
		}
		else if ( szKey == "forwardspeed" )
		{
			self.pev.speed = atof( szValue );
			return true;
		}
		else if ( szKey == "anglespeed" )
		{
			m_flAnglespeed = atof( szValue );
			return true;
		}
		else if ( szKey == "modelname" )
		{
			self.pev.model = szValue;
			return true;
		}
		else
			return gunman_cycler::KeyValue( szKey, szValue );
	}
	
	void Spawn()
	{
		gunman_cycler::Spawn();
		
		self.pev.body = Math.RandomLong( 0, 3 );
		
		self.pev.solid			=	SOLID_NOT;
		self.pev.movetype		=	MOVETYPE_NONE;
		self.pev.effects		|=	EF_NODRAW;
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
	{
		self.pev.effects		&=	~EF_NODRAW;
		self.pev.solid			=	SOLID_BBOX;
		self.pev.movetype		=	MOVETYPE_BOUNCEMISSILE;
		
		// This stores pev->angles into 3 vectors, v_forward, v_up, and v_right, so we can use them in offsets. 
		Vector vecAngles = Math.VecToAngles( self.pev.movedir );
		vecAngles.x = -vecAngles.x;
		vecAngles.y += 90.0f;
		g_EngineFuncs.MakeVectors( vecAngles );
		Vector vecMoar			=	g_Engine.v_forward.opMul( self.pev.speed );
		
		self.pev.velocity		=	self.pev.velocity + vecMoar; //g_Engine.v_forward * -self.pev.speed;
		
		m_blRotate				=	true;
	}
	
	void Think()
	{
		gunman_cycler::Think();
		
		if( m_blRotate )
		{
			self.pev.angles.x += m_flAnglespeed * 0.1;
			self.pev.angles.y += m_flAnglespeed * 0.1;
			self.pev.angles.z += m_flAnglespeed * 0.1;
			
			if( self.pev.angles.x >= 360.0 )
				self.pev.angles.x = 0.0;
			
			if( self.pev.angles.y >= 360.0 )
				self.pev.angles.y = 0.0;
			
			if( self.pev.angles.z >= 360.0 )
				self.pev.angles.z = 0.0;
		}
	}
}

void RegisterEntity_DecoreSpaceDebris()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "decore_spacedebris", "decore_spacedebris" );
}
