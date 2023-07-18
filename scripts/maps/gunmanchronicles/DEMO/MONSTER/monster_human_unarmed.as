//=========================================================
// Generic Monster - purely for scripted sequence work.
//=========================================================

// For holograms, make them not solid so the player can walk through them
const int	SF_HUMANUNARMED_NOTSOLID			=		4;

enum humanunarmed_bg {
	GROUP_WEAPON = 1,
	GROUP_DECORE
};

//=========================================================
// Monster's Anim Events Go Here
//=========================================================

class monster_human_unarmed : ScriptBaseMonsterEntity
{
	string	m_szIdleSentences;
	string	m_szStareSentences;
	string	m_szPainSentences;
	string	m_szUseSentences;
	string	m_szUnuseSentences;
	int[]	m_iBodygroup(2);
	int     m_animate;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "gn_idle" )
		{
			m_szIdleSentences = szValue;
			return true;
		}
		else if ( szKey == "gn_stare" )
		{
			m_szStareSentences = szValue;
			return true;
		}
		else if ( szKey == "gn_noshoot" )
		{
			m_szPainSentences = szValue;
			return true;
		}
		else if ( szKey == "gn_use" )
		{
			m_szUseSentences = szValue;
			return true;
		}
		else if ( szKey == "gn_unuse" )
		{
			m_szUnuseSentences = szValue;
			return true;
		}
		else if ( szKey == "gunstate" )
		{
			m_iBodygroup[0] = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	//=========================================================
	// Classify - indicates this monster's place in the 
	// relationship table.
	//=========================================================
	int Classify()
	{
		return CLASS_PLAYER_ALLY;
	}
	
	//=========================================================
	// SetYawSpeed - allows each sequence to have a different
	// turn rate associated with it.
	//=========================================================
	void SetYawSpeed()
	{
		int ys;

		switch( self.m_Activity )
		{
			case ACT_IDLE:
			default:
				ys = 90;
		}

		self.pev.yaw_speed = ys;
	}
    
	//=========================================================
	// Spawn
	//=========================================================
	void Spawn()
	{
		self.Precache();

        if( string( self.pev.model ).IsEmpty() )
		self.pev.model = "models/gunmanchronicles/gunmantrooper_ng.mdl";
		
		g_EntityFuncs.SetModel(self, self.pev.model);
		
		self.SetBodygroup( GROUP_WEAPON , m_iBodygroup[0] );

		g_EntityFuncs.SetSize(self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );

		self.pev.solid			= SOLID_SLIDEBOX;
		self.pev.movetype		= MOVETYPE_STEP;
		self.m_bloodColor		= BLOOD_COLOR_RED;
		self.pev.health			= 100;
		self.pev.view_ofs		= Vector( 0, 0, 50 );// position of the eyes relative to monster's origin.
		self.m_flFieldOfView	= VIEW_FIELD_FULL;// indicates the width of this monster's forward view cone ( as a dotproduct result )
		self.m_MonsterState		= MONSTERSTATE_NONE;
		
		self.m_afCapability = bits_CAP_TURN_HEAD | bits_CAP_DOORS_GROUP;

		self.MonsterInit();

		if( self.pev.spawnflags & SF_HUMANUNARMED_NOTSOLID != 0 )
		{
			self.pev.solid 		= SOLID_NOT;
			self.pev.takedamage = DAMAGE_NO;
		}
        
        if( string( self.pev.netname ).IsEmpty() )
			self.pev.netname = "Unarmed Gunman";
		
        if( string( self.m_FormattedName ).IsEmpty() )
			self.m_FormattedName	=	self.pev.netname;

		if( self.pev.sequence != 0 || self.pev.frame != 0 )
		{
			m_animate = 0;
			self.pev.framerate = 0;
		}
		else
		{
			m_animate = 1;
		}
		
		//SetUse( UseFunction( this.Use ) );
	}

	//=========================================================
	// Precache - precaches all resources this monster needs
	//=========================================================
	void Precache()
	{
		BaseClass.Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/gunmantrooper_ng.mdl" );

        if( string( self.pev.model ).IsEmpty() == false )
			g_Game.PrecacheModel( self.pev.model );
	}

	//=========================================================
	// AI Schedules Specific to this monster
	//=========================================================
	Schedule@ GetSchedule()
	{
		// so we don't keep calling through the EHANDLE stuff
		CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();

		if( self.HasConditions( bits_COND_HEAR_SOUND ) )
		{
			CSound@ pSound;
			@pSound = @self.PBestSound();

			if( pSound !is null && ( pSound.m_iType & bits_SOUND_DANGER ) != 0 )
				return BaseClass.GetScheduleOfType( SCHED_TAKE_COVER_FROM_BEST_SOUND );
		}

		switch( self.m_MonsterState )
		{
		case MONSTERSTATE_ALERT:
		case MONSTERSTATE_IDLE:
		{
			if( pEnemy !is null )
			{
				self.m_hEnemy = null;
				@pEnemy   = null;
			}

			if( self.HasConditions( bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE ) )
			{
				// flinch if hurt
				return BaseClass.GetScheduleOfType( SCHED_SMALL_FLINCH );
			}

			// Cower when you hear something scary
			if( self.HasConditions( bits_COND_HEAR_SOUND ) )
			{
				CSound@ pSound;
				@pSound = @self.PBestSound();

				if( pSound !is null )
				{
					if( pSound.m_iType & ( bits_SOUND_DANGER | bits_SOUND_COMBAT ) != 0 )
					{
						return BaseClass.GetScheduleOfType( SCHED_IDLE_STAND );	// This will just duck for a second
					}
				}
			}

			break;
		}
		case MONSTERSTATE_COMBAT:
		{
			/*if( self.HasConditions( bits_COND_NEW_ENEMY ) )
				return BaseClass.GetScheduleOfType( SCHED_IDLE_STAND );	// This will just duck for a second
			if( self.HasConditions( bits_COND_SEE_ENEMY ) )
				return BaseClass.GetScheduleOfType( SCHED_IDLE_STAND );	// This will just duck for a second

			if( self.HasConditions( bits_COND_HEAR_SOUND ) )
				return BaseClass.GetScheduleOfType( SCHED_IDLE_STAND );	// This will just duck for a second
			*/
			
			return BaseClass.GetScheduleOfType( SCHED_IDLE_STAND );	// This will just duck for a second
		}
		default:
			break;
		}
		
		return BaseClass.GetSchedule();
	}
    
    //=========================================================
	// AI Schedules Specific to this monster
	//=========================================================
	
	/*	void Think()
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
	}*/
	
    /*void IdleThink()
	{
		self.StudioFrameAdvance();
		self.pev.nextthink	= g_Engine.time + 0.1;
	}*/
    
	void IdleSound()
	{
		self.PlaySentence( m_szStareSentences, Math.RandomFloat(5.0, 7.5), VOL_NORM, ATTN_IDLE );
	}
	
	void PainSound()
	{
		self.PlaySentence( m_szPainSentences, 2.0, VOL_NORM, ATTN_IDLE );
	}
	
	int ObjectCaps()
	{
		return BaseClass.ObjectCaps() | FCAP_IMPULSE_USE;
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
	{
		// Don't allow use during a scripted_sentence
		if( self.m_useTime > g_Engine.time )
			return;
			
		if( pCaller !is null && pCaller.IsPlayer() && self.CanPlaySentence( false ) )
		{
			self.PlaySentence( m_szUseSentences, 10.0, VOL_NORM, ATTN_IDLE );
		}
	}
    
    /*void HandleAnimEvent( MonsterEvent@ pEvent )
    {                    
        switch ( pEvent.event ) 
        {
        	case 1:
            	break;
            default:
                BaseClass.HandleAnimEvent( pEvent );
                break; 
        }
    }*/
};

void RegisterEntity_MonsterHumanUnarmed()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_human_unarmed", "monster_human_unarmed" );
}

