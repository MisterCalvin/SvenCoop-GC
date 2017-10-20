class gunman_cycler : ScriptBaseMonsterEntity
{
	int     m_animate;
	int[]   m_iBodygroup(3);

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "cyc_submodel1" )
		{
			m_iBodygroup[0] = atoi( szValue );
			return true;
		}
		else if ( szKey == "cyc_submodel2" )
		{
			m_iBodygroup[1] = atoi( szValue );
			return true;
		}
		else if ( szKey == "cyc_submodel3" )
		{
			m_iBodygroup[2] = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Spawn()
	{
		self.Precache();

		g_EntityFuncs.SetModel(self, self.pev.model);
		
		self.SetBodygroup( 1 , m_iBodygroup[0] );
		self.SetBodygroup( 2 , m_iBodygroup[1] );
		self.SetBodygroup( 3 , m_iBodygroup[2] );
		
		self.InitBoneControllers();
		self.pev.solid			= SOLID_SLIDEBOX;
		self.pev.movetype		= MOVETYPE_NONE;
		self.pev.takedamage		= DAMAGE_NO;
		self.pev.effects		= 0;
		self.pev.health			= 80000;// no cycler should die
		self.pev.yaw_speed		= 5;
		self.pev.ideal_yaw		= self.pev.angles.y;

		self.m_flFrameRate		= 75;
		self.m_flGroundSpeed	= 0;

		self.pev.nextthink		+= 1.0;

		self.ResetSequenceInfo();

		if( self.pev.sequence != 0 || self.pev.frame != 0 )
		{
			m_animate = 0;
			self.pev.framerate = 0;
		}
		else
		{
			m_animate = 1;
		}
	}
	
	void Think()
	{
		self.pev.nextthink = g_Engine.time + 0.1;

		if( m_animate > 0 )
		{
			self.StudioFrameAdvance();
		}
		if( self.m_fSequenceFinished && !self.m_fSequenceLoops )
		{
			// ResetSequenceInfo();
			// hack to avoid reloading model every frame
			self.pev.animtime = g_Engine.time;
			self.pev.framerate = 1.0;
			self.m_fSequenceFinished = false;
			self.m_flLastEventCheck = g_Engine.time;
			self.pev.frame = 0;
			if( m_animate <= 0 )
				self.pev.framerate = 0.0;	// FIX: don't reset framerate
		}
	}
}

void RegisterEntity_GunmanCycler()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "gunman_cycler", "gunman_cycler" );
}
