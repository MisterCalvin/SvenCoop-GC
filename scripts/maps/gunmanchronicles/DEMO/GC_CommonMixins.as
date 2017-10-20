mixin class WallHitEffect
{
	private string	m_szWallSpark	= "sprites/gunmanchronicles/gausspark.spr";
	private string	m_szWallBlast	= "sprites/gunmanchronicles/gausspoof.spr";
	private string	m_szWallPuff	= "sprites/gunmanchronicles/gausspuff.spr";
	
	private string	m_szWallHitSound= "gunmanchronicles/weapons/gauss_spritesmall.wav";
	
	void PrecacheWallHitEffect()
	{
		g_Game.PrecacheModel(  m_szWallSpark );
		g_Game.PrecacheModel(  m_szWallBlast );
		g_Game.PrecacheModel(  m_szWallPuff  );
		
		PrecacheGenericSound( m_szWallHitSound );
	}
	
	void CreateWallHitSound( const Vector &in vecPos )
	{
		g_SoundSystem.EmitAmbientSound( g_EntityFuncs.Instance(0).edict(), vecPos, m_szWallHitSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void CreateWallHitEffect( const Vector &in vecPos, const uint8 blastScale=5, const uint8 puffScale=2 )
	{
		CreateTempEnt_SpriteTrail( vecPos, vecPos, m_szWallSpark, Math.RandomLong( 3, 8 ) );
		CreateTempEnt_Sprite( vecPos, m_szWallBlast, blastScale );
		CreateTempEnt_Sprite( vecPos, m_szWallPuff,  puffScale );
	}
	
	void CreateWallHitEffectBig( const Vector &in vecPos )
	{
		CreateWallHitEffect( vecPos, 10, 10 );
	}
}

mixin class ItemGlowEffect
{
	void GlowThink()
	{
		bool isRendered = self.pev.renderfx == kRenderFxGlowShell;
		
		//turn off
		if( isRendered )
		{
			self.pev.renderfx = kRenderFxNone;
			
			self.pev.nextthink = g_Engine.time + 5.0f;
		}
		//turn on
		else
		{
			self.pev.renderfx		=	kRenderFxGlowShell;
			self.pev.renderamt		=	2;
			self.pev.rendercolor	=	Vector( 127,255,212 );
			self.pev.rendermode		=	kRenderNormal;
			
			self.pev.nextthink = g_Engine.time + 3.0f;
		}
	}
}

mixin class LaserEffect
{
	private string					m_szLaserBeam			= "sprites/gunmanchronicles/gaussbeam2.spr";
	private string					m_szRailBeam			= "sprites/xbeam1.spr";
	
	private CBeam@					m_pRailBeam				= null;
	
	void PrecacheLaserEffect()
	{
		g_Game.PrecacheModel( m_szLaserBeam );
		g_Game.PrecacheModel( m_szRailBeam );
	}
	
	void DrawSinusShapeLaser( const Vector &in vecStart, const Vector &in vecEnd, float flLiveTime = 1.0f, uint width = 20, Color cColor = GREEN )
	{
		@m_pRailBeam = g_EntityFuncs.CreateBeam( m_szRailBeam, width );
		m_pRailBeam.PointsInit( vecStart, vecEnd );
		m_pRailBeam.SetFlags( BEAM_FSINE | BEAM_FSHADEOUT );
		m_pRailBeam.LiveForTime( flLiveTime );
		
		m_pRailBeam.SetColor( cColor.r, cColor.g, cColor.b);
		m_pRailBeam.SetBrightness( cColor.a );
		
		m_pRailBeam.pev.spawnflags	|= SF_BEAM_TEMPORARY | SF_BEAM_RING | SF_BEAM_SHADEOUT;	// Flag these to be destroyed on save/restore or level transition
		m_pRailBeam.pev.flags		|= FL_SKIPLOCALHOST;

		m_pRailBeam.SetScrollRate( 50 );
		m_pRailBeam.SetNoise( 20 );
	}
}
