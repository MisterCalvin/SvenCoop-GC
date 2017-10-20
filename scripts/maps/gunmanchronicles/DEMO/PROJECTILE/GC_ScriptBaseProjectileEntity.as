#include "../GC_CommonFunctions"

enum projectile_killtype_e
{
	PROJECTILE_KILL_IMPACT = 0,
	PROJECTILE_KILL_TIMED,
	PROJECTILE_KILL_MANUAL
};

class GC_BaseProjectile : ScriptBaseEntity
{
	private	string	W_MODEL;
	private string	TRAIL_MODEL;
	private projectile_killtype_e PROJ_KILL;
	
			float	m_timedKill;
			float	m_maxFrame;
			float	m_lastTime;
			bool	m_bUseTrail		=	false;
			uint8	m_uiTrailLife	=	5;
			uint8	m_uiTrailWidth	=	8;
			Color	m_cTrailColor	=	AQUAMARINE;
	
	string WorldModel
	{
		get const	{ return W_MODEL;  }
		set			{ W_MODEL = value; }
	}
	string TrailModel
	{
		get const	{ return TRAIL_MODEL;  }
		set			{ TRAIL_MODEL = value; }
	}
	projectile_killtype_e ProjectileDetonation
	{
		get const	{ return PROJ_KILL;  }
		set			{ PROJ_KILL = value; }
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		g_Game.PrecacheModel( self, W_MODEL );
		g_Game.PrecacheModel( self, TRAIL_MODEL );
	}
	
	void Spawn()
	{
		Precache();
		
		if( self.pev.movetype == MOVETYPE_NONE )
			self.pev.movetype	= MOVETYPE_FLY;
		
		if( self.pev.solid == SOLID_NOT )
			self.pev.solid		= SOLID_BBOX;
		
		//self.pev.effects	= 0;
		self.pev.frame		= 0;
		
		if( self.pev.framerate <= 0.0f )
			self.pev.framerate = 1.0f;
		
		if( string(self.pev.model).IsEmpty() )
			self.pev.model = W_MODEL;
		
		g_EntityFuncs.SetModel( self, self.pev.model );

		m_maxFrame = g_EngineFuncs.ModelFrames( self.pev.modelindex ) - 1;

		// Worldcraft only sets y rotation, copy to Z
		//if( self.pev.angles.y != 0 && self.pev.angles.z == 0 )
		//{
		//	self.pev.angles.z = self.pev.angles.y;
		//	self.pev.angles.y = 0;
		//}
		
		m_timedKill = g_Engine.time + self.pev.dmgtime;
		
		self.pev.nextthink = g_Engine.time + 0.1;
	}
	
	void Think()
	{
		Animate( self.pev.framerate * ( g_Engine.time - m_lastTime ) );

		self.pev.nextthink = g_Engine.time + 0.1;
		m_lastTime = g_Engine.time;
		
		if( m_bUseTrail )
		{
			CreateTempEnt_BeamFollow( self, TRAIL_MODEL, m_uiTrailLife, m_uiTrailWidth, m_cTrailColor );
		}
		
		switch( PROJ_KILL )
		{
			case PROJECTILE_KILL_TIMED:
			{
				if( m_timedKill > 0.0f && m_timedKill <= g_Engine.time )
				{
					m_timedKill = 0.0f;
					DetonateOnTimed();
				}
				break;
			}
		}
	}

	void Animate( float frames )
	{ 
		self.pev.frame += frames;
		if( self.pev.frame > m_maxFrame )
		{
			if( m_maxFrame > 0 )
				self.pev.frame = self.pev.frame % m_maxFrame;
		}
	}

	void Touch(CBaseEntity@ pOther)
	{
		switch( PROJ_KILL )
		{
			case PROJECTILE_KILL_IMPACT:
				DetonateOnImpact(@pOther);
				break;
			default :
				BaseClass.Touch(@pOther);
				break;
		}
	}
	
	void MoveForward()
	{
		Math.MakeVectors( self.pev.angles );
		self.pev.velocity = g_Engine.v_forward.opMul( self.pev.speed );
	}
	
	void DetonateOnImpact(CBaseEntity@ pOther)
	{
		BaseClass.Touch(@pOther);
		self.Killed( self.pev, GIB_NORMAL );
	}
	
	void DetonateOnTimed()
	{
		m_timedKill = 0.0f;
		self.Killed( self.pev, GIB_NORMAL );
	}
	
	void DetonateOnManual()
	{
		self.Killed( self.pev, GIB_NORMAL );
	}
	
	void DetonateNow()
	{
		switch( PROJ_KILL )
		{
			case PROJECTILE_KILL_IMPACT:
				DetonateOnImpact(self);
				return;
			case PROJECTILE_KILL_TIMED:
				DetonateOnTimed();
				return;
			case PROJECTILE_KILL_MANUAL:
			default :
				DetonateOnManual();
				return;
		}
	}
	
	void SetTransparency( int rendermode, int r, int g, int b, int a, int fx )
	{
		self.pev.rendermode = rendermode;
		self.pev.rendercolor.x = r;
		self.pev.rendercolor.y = g;
		self.pev.rendercolor.z = b;
		self.pev.renderamt = a;
		self.pev.renderfx = fx;
	}
	
	void EmitSoundDyn( string soundFile, SOUND_CHANNEL channel = CHAN_AUTO, float flVolume = VOL_NORM, float flAttenuation = ATTN_NORM, int iFlags = 0, int iPitch = PITCH_NORM )
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), channel, soundFile, flVolume, flAttenuation, iFlags, iPitch );
	}
}
