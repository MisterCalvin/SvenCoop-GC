//=========================================================
// Generic Monster - purely for scripted sequence work.
//=========================================================

// For holograms, make them not solid so the player can walk through them
const int	SF_TRAININGBOT_NOTSOLID				=	4;
const int	SF_TRAININGBOT_NORINGS				=	1024;


enum trainingbot_atchmnt {
	TRAININGBOT_ATTACHMENT_BODYSPIKE = 1,
	TRAININGBOT_ATTACHMENT_LEG1,
	TRAININGBOT_ATTACHMENT_LEG2,
	TRAININGBOT_ATTACHMENT_LEG3
};
const int	TRAININGBOT_BEAM_PARENTATTACHMENT	=	TRAININGBOT_ATTACHMENT_BODYSPIKE;

//=========================================================
// Monster's Anim Events Go Here
//=========================================================

class monster_trainingbot : ScriptBaseMonsterEntity
{
	string[] szArrayIdleSound = {
		"gunmanchronicles/drone/drone_idle.wav"
	};
	
	string[] szArrayPainSound = {
		"buttons/spark5.wav",
		"buttons/spark6.wav"
	};

	string[] szArrayDeathSound = {
		"gunmanchronicles/drone/drone_flinch1.wav",
		"gunmanchronicles/drone/drone_flinch2.wav"
	};

	private int				m_iGibModelindex;
	private int				m_iExplModelindex;
	private int				m_iSmokeModelIndex;
	private EHandle			m_hGoalEnt;
	private uint			m_uiBeams;
	private EHandle[]		m_hBeams;
	private EHandle			m_hSparkBall;
	
	private bool			m_isUsingOspreyMovement;
	
	private Vector			m_vecFinalDest;
	
	private Vector			m_vel1;
	private Vector			m_vel2;
	private Vector			m_pos1;
	private Vector			m_pos2;
	private Vector			m_ang1;
	private Vector			m_ang2;
	private float			m_startTime;
	private float			m_dTime;
	private Vector			m_velocity;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "isUsingOspreyMovement" )
		{
			m_isUsingOspreyMovement = atoi( szValue ) > 0;
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
		return CLASS_MACHINE;
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
				ys = 45;
		}

		self.pev.yaw_speed = ys;
	}
	
	//=========================================================
	// Spawn
	//=========================================================
	void Spawn()
	{
		self.Precache();

		if( self.pev.model.opImplConv().IsEmpty() )
			self.pev.model = "models/gunmanchronicles/batterybot.mdl";
		
		g_EntityFuncs.SetModel(self, self.pev.model);
		m_hBeams.resize( self.GetAttachmentCount() );
		g_EntityFuncs.SetOrigin(self, self.pev.origin);
		g_EntityFuncs.SetSize(self.pev, Vector( -32, -32, 0 ), Vector( 32, 32, 64 ) );

		self.pev.solid			= SOLID_BBOX;
		self.pev.movetype		= MOVETYPE_NOCLIP;
		self.pev.flags			|= FL_MONSTER;
		self.pev.spawnflags		|= FL_FLY;
		self.m_bloodColor		= DONT_BLEED;
		self.pev.health			= 200;
		self.pev.takedamage		= DAMAGE_AIM;
		self.pev.view_ofs		= VEC_VIEW;// position of the eyes relative to monster's origin.
		self.m_flFieldOfView	= 0.5;// indicates the width of this monster's forward view cone ( as a dotproduct result )
		self.m_MonsterState		= MONSTERSTATE_NONE;
		
		self.m_afCapability		= bits_CAP_DOORS_GROUP;

		m_pos2 = self.pev.origin;
		m_ang2 = self.pev.angles;
		m_vel2 = self.pev.velocity;
		m_startTime = g_Engine.time;
		
		self.MonsterInit();

		if( self.pev.spawnflags & SF_TRAININGBOT_NOTSOLID != 0 )
		{
			self.pev.solid 		= SOLID_NOT;
			self.pev.takedamage = DAMAGE_NO;
		}
		
		if( self.pev.netname.opImplConv().IsEmpty() )
			self.pev.netname = "Training Bot";
		
		if( self.m_FormattedName.opImplConv().IsEmpty() )
			self.m_FormattedName	=	self.pev.netname;
		
		if( self.pev.speed <= 0.0 )
		{
			self.pev.speed = 150.0f;
		}
		
		//SetUse( UseFunction( this.Use ) );
		
		self.pev.sequence = 0;
		self.ResetSequenceInfo();
		self.pev.frame = Math.RandomLong( 0, 0xFF );

		self.InitBoneControllers();
		
		IdleSound();
		CreateBeams();
		CreateSparkBall( TRAININGBOT_BEAM_PARENTATTACHMENT );
	}

	//=========================================================
	// Precache - precaches all resources this monster needs
	//=========================================================
	void Precache()
	{
		BaseClass.Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/batterybot.mdl" );
		m_iGibModelindex   = g_Game.PrecacheModel( "models/gunmanchronicles/battgib.mdl" );
		m_iExplModelindex  = g_Game.PrecacheModel( "sprites/zerogxplode.spr" );
		m_iSmokeModelIndex = g_Game.PrecacheModel( "sprites/steam1.spr" );// smoke
		g_Game.PrecacheModel( "sprites/lgtning.spr" );
		g_Game.PrecacheModel( "sprites/gunmanchronicles/ballspark.spr" );
		
		if( self.pev.model.opImplConv().IsEmpty() == false )
			g_Game.PrecacheModel( self.pev.model );
		
		for( uint i = 0; i < szArrayIdleSound.length(); i++ )
			g_SoundSystem.PrecacheSound( szArrayIdleSound[i] );
		
		for( uint i = 0; i < szArrayPainSound.length(); i++ )
			g_SoundSystem.PrecacheSound( szArrayPainSound[i] );
		
		for( uint i = 0; i < szArrayDeathSound.length(); i++ )
			g_SoundSystem.PrecacheSound( szArrayDeathSound[i] );
	}

	//=========================================================
	// AI Schedules Specific to this monster
	//=========================================================
	
	void Think()
	{
		self.StudioFrameAdvance();
		
		if( m_isUsingOspreyMovement )
		{
			SetThink( ThinkFunction( this.FlyThink ) );
		}
		else
		{
			SetThink( ThinkFunction( this.LinearMove ) );
		}
		
		self.pev.nextthink	= g_Engine.time + 0.1;
	}
	
	/*
	=============
	LinearMove

	calculate self.pev.velocity and self.pev.nextthink to reach vecDest from
	self.pev.origin traveling at flSpeed
	===============
	*/
	void LinearMove()
	{
		self.StudioFrameAdvance();
		
		if( m_hGoalEnt.GetEntity() is null && self.pev.target.opImplConv().IsEmpty() == false )// this monster has a target
		{
			m_hGoalEnt = EHandle( g_EntityFuncs.FindEntityByTargetname( null, self.pev.target ) );
		}
		
		if( m_hGoalEnt.GetEntity() !is null && self.pev.speed > 0.0 )
		{
			//g_Game.AlertMessage(at_console, "%1 started to reaching new destination.\n", self.pev.targetname );
			
			m_vecFinalDest = m_hGoalEnt.GetEntity().pev.origin;

			// Already there?
			if( m_vecFinalDest == self.pev.origin )
			{
				LinearMoveDone();
				return;
			}

			// set destdelta to the vector needed to move
			Vector vecDestDelta = m_vecFinalDest.opSub( self.pev.origin );

			// divide vector length by speed to get time to reach dest
			float flTravelTime = vecDestDelta.Length() / self.pev.speed;

			// set nextthink to trigger a call to LinearMoveDone when dest is reached
			SetThink( ThinkFunction( this.LinearMoveDone ) );
			self.pev.nextthink	= g_Engine.time + flTravelTime;

			// scale the destdelta vector by the time spent traveling to get velocity
			self.pev.velocity = vecDestDelta / flTravelTime;
		}
		else
		{
			//ALERT( at_console, "osprey missing target" );
		}
	}
	
	/*
	============
	After moving, set origin to exact final destination, call "move done" function
	============
	*/
	void LinearMoveDone()
	{
		//g_Game.AlertMessage(at_console, "%1 arrived at destination.\n", self.pev.targetname );
		SetThink( null );
		
		g_EntityFuncs.SetOrigin( self, m_vecFinalDest );
		self.pev.velocity = g_vecZero;
		self.pev.nextthink = -1;
		
		m_hGoalEnt = EHandle( g_EntityFuncs.FindEntityByTargetname( null, m_hGoalEnt.GetEntity().pev.target ) );
		Think();
	}

	void UpdateGoal()
	{
		if( m_hGoalEnt.GetEntity() !is null )
		{
			m_pos1 = m_pos2;
			m_ang1 = m_ang2;
			m_vel1 = m_vel2;
			m_pos2 = m_hGoalEnt.GetEntity().pev.origin;
			m_ang2 = m_hGoalEnt.GetEntity().pev.angles;
			Math.MakeAimVectors( Vector( 0, m_ang2.y, 0 ) );
			m_vel2 = g_Engine.v_forward * self.pev.speed;

			m_startTime = m_startTime + m_dTime;
			m_dTime = 2.0 * ( m_pos1 - m_pos2 ).Length() / ( m_vel1.Length() + self.pev.speed );

			if( m_ang1.y - m_ang2.y < -180 )
			{
				m_ang1.y += 360;
			}
			else if( m_ang1.y - m_ang2.y > 180 )
			{
				m_ang1.y -= 360;
			}
		}
		else
		{
			//ALERT( at_console, "osprey missing target" );
		}
	}

	void FlyThink()
	{
		self.StudioFrameAdvance();
		self.pev.nextthink	= g_Engine.time + 0.1;

		if( m_hGoalEnt.GetEntity() is null && self.pev.target.opImplConv().IsEmpty() == false )// this monster has a target
		{
			m_hGoalEnt = EHandle( g_EntityFuncs.FindEntityByTargetname( null, self.pev.target ) );
			UpdateGoal();
		}

		if( g_Engine.time > m_startTime + m_dTime )
		{
			if( m_hGoalEnt.GetEntity().pev.speed == 0 )
			{
				//SetThink( &COsprey::DeployThink );
			}
			//do{
				m_hGoalEnt = EHandle( g_EntityFuncs.FindEntityByTargetname( null, m_hGoalEnt.GetEntity().pev.target ) );
			//} while( m_hGoalEnt.GetEntity().pev.speed < 400 );
			UpdateGoal();
		}

		Flight();
	}

	void Flight()
	{
		float t = ( g_Engine.time - m_startTime );
		float scale = 1.0 / m_dTime;

		float f = UTIL_SplineFraction( t * scale, 1.0 );

		Vector pos = ( m_pos1 + m_vel1 * t ) * ( 1.0 - f ) + ( m_pos2 - m_vel2 * ( m_dTime - t ) ) * f;
		Vector ang = ( m_ang1 ) * ( 1.0 - f ) + ( m_ang2 ) * f;
		m_velocity = m_vel1 * ( 1.0 - f ) + m_vel2 * f;

		g_EntityFuncs.SetOrigin(self, pos);
		self.pev.angles = ang;
		Math.MakeAimVectors( self.pev.angles );
		float flSpeed = DotProduct( g_Engine.v_forward, m_velocity );

		// float flSpeed = DotProduct( g_Engine.v_forward, self.pev.velocity );
		
	}

	//=========================================================
	// IdleSound 
	//=========================================================
	void IdleSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_STATIC, szArrayIdleSound[ Math.RandomLong( 0, szArrayIdleSound.length()-1 ) ], 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
	
	//=========================================================
	// PainSound 
	//=========================================================
	void PainSound()
	{
		float flVolume = Math.RandomFloat( 0.7 , 1.0 );//random volume range
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, szArrayPainSound[ Math.RandomLong( 0, szArrayPainSound.length()-1 ) ], flVolume, ATTN_NORM, 0, PITCH_NORM );
	}
	
	//=========================================================
	// DeathSound 
	//=========================================================
	void DeathSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, szArrayDeathSound[ Math.RandomLong( 0, szArrayDeathSound.length()-1 ) ], 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void TraceAttack(entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in traceResult, int bitsDamageType)
	{
		BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, traceResult, bitsDamageType );
		
		g_Utility.Sparks( traceResult.vecEndPos );
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		//g_Game.AlertMessage(at_console, "bitsDamageType %1\n", bitsDamageType );
		
		// Always-Gib
		if( ( bitsDamageType & DMG_CRUSH ) != 0 || ( bitsDamageType & DMG_FALL ) != 0 || ( bitsDamageType & DMG_BLAST ) != 0
		    || ( bitsDamageType & DMG_ENERGYBEAM ) != 0 || ( bitsDamageType & DMG_ACID ) != 0 || ( bitsDamageType & DMG_SLOWBURN ) != 0
			|| ( bitsDamageType & DMG_MORTAR ) != 0 )
		{
			if( ( bitsDamageType & DMG_NEVERGIB ) != 0  ) bitsDamageType &= ~DMG_NEVERGIB;
			if( ( bitsDamageType & DMG_ALWAYSGIB ) == 0 ) bitsDamageType |= DMG_ALWAYSGIB;
		}
		else
		// Never Gib
		{
			if( ( bitsDamageType & DMG_ALWAYSGIB ) != 0 ) bitsDamageType &= ~DMG_ALWAYSGIB;
			if( ( bitsDamageType & DMG_NEVERGIB ) == 0  ) bitsDamageType |= DMG_NEVERGIB;
		}
		
		//g_Game.AlertMessage(at_console, "new bitsDamageType %1\n", bitsDamageType );
		
		int result = BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		
		if( result > 0 )
			self.GetDamagePoints( pevAttacker, pevInflictor, flDamage );
		
		return result;
	}
	
	void Killed(entvars_t@ pevAtttacker, int iGibbed)
	{
		SetThink( null );
		
		ClearBeams();
		ClearSparkBall();
		
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_STATIC, szArrayIdleSound[ 0 ], 0.0, 0.0, SND_STOP, 100 );
		DeathSound();
		
		if( iGibbed != GIB_NEVER )
		{
			ExplodeDie();
		}
		else
		{
			self.pev.deadflag = DEAD_DEAD;

			self.pev.framerate = 0;
			self.pev.effects = EF_NOINTERP;

			//UTIL_SetSize( pev, Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) );
			self.pev.movetype = MOVETYPE_TOSS;

			self.pev.gravity 	= 0.3;
			self.pev.avelocity = Vector( Math.RandomFloat( -20, 20 ), 0, Math.RandomFloat( -50, 50 ) );

			g_EntityFuncs.SetSize( self.pev, Vector( -32, -32, -16 ), Vector( 32, 32, 0 ) );
			
			SetTouch( TouchFunction( this.CrashTouch ) );
			SetThink( ThinkFunction( this.DyingThink ) );
			self.pev.nextthink = g_Engine.time + 0.1;
			
			m_startTime = g_Engine.time + 6.0f;
		}
		
		BaseClass.Killed( pevAtttacker, iGibbed );
	}
	
	void DyingThink()
	{
		self.StudioFrameAdvance();
		//self.pev.nextthink = g_Engine.time + 0.1;

		if( self.pev.angles.x < 180.0f )
			self.pev.angles.x += 6.0f;
		
		// still falling?
		if( m_startTime > g_Engine.time )
		{
			// lots of smoke
			NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, self.pev.origin );
				m.WriteByte( TE_SMOKE );
				m.WriteCoord( self.pev.origin.x );
				m.WriteCoord( self.pev.origin.y );
				m.WriteCoord( self.pev.origin.z );
				m.WriteShort( m_iSmokeModelIndex );
				m.WriteByte( 25 ); // scale * 10
				m.WriteByte( 10 ); // framerate
			m.End();
			
			g_Utility.Sparks( self.pev.origin.opAdd( Vector( Math.RandomFloat( -150, 150 ), Math.RandomFloat( -150, 150 ), Math.RandomFloat( -150, -50 ) ) ) );
			
			// don't stop it we touch a entity
			self.pev.flags		&=	~FL_ONGROUND;
			self.pev.nextthink	=	g_Engine.time + 0.1;
		}
		// falling time is out
		else
		{
			SetTouch( null );
			m_startTime = g_Engine.time;
			ExplodeDie();
		}
	}

	void CrashTouch( CBaseEntity@ pOther )
	{
		// only crash if we hit something solid
		if( pOther.pev.solid == SOLID_BSP )
		{
			SetTouch( null );
			m_startTime = g_Engine.time;
			ExplodeDie();
		}
	}
	
	void ExplodeDie()
	{
		NetworkMessage expl(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
		expl.WriteByte(TE_EXPLOSION);
		expl.WriteCoord(self.pev.origin.x);
		expl.WriteCoord(self.pev.origin.y);
		expl.WriteCoord(self.pev.origin.z);
		expl.WriteShort( m_iExplModelindex );
		expl.WriteByte( 10 );
		expl.WriteByte( 15 );
		expl.WriteByte(  0 );
		expl.End();
		
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
		m.WriteByte(TE_EXPLODEMODEL);
		m.WriteCoord(self.pev.origin.x);
		m.WriteCoord(self.pev.origin.y);
		m.WriteCoord(self.pev.origin.z + 16.0f );
		m.WriteCoord( 300.0 );
		m.WriteShort( m_iGibModelindex );
		m.WriteShort( 4 );
		m.WriteByte(  200 );
		m.End();
		
		if( self !is null )
			g_EntityFuncs.Remove( self );
	}
	
	/*int ObjectCaps()
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
	}*/
	
	void CreateBeams()
	{
		//while( m_uiBeams < m_hBeams.length() )
		{
			CreateBeam( TRAININGBOT_ATTACHMENT_LEG1 );
			CreateBeam( TRAININGBOT_ATTACHMENT_LEG2 );
			CreateBeam( TRAININGBOT_ATTACHMENT_LEG3 );
		}
	}
	
	void CreateBeam( int attachment )
	{
		if( m_uiBeams >= m_hBeams.length()-1 )
			return;

		CBeam@ pBeam = g_EntityFuncs.CreateBeam( "sprites/lgtning.spr", 30 );
		
		if( pBeam is null )
			return;

		pBeam.EntsInit( self, self );
		//pBeam.PointEntInit( self.pev.origin, self );
		pBeam.SetStartAttachment( attachment );
		pBeam.SetEndAttachment(   TRAININGBOT_BEAM_PARENTATTACHMENT );
		pBeam.SetColor( 127,255,212 );
		pBeam.SetBrightness( 255 );
		pBeam.SetNoise( 80 );
		
		m_hBeams.insertLast( EHandle(pBeam) );
		
		m_uiBeams++;
	}
	
	//=========================================================
	// ClearBeams - remove all beams
	//=========================================================
	void ClearBeams()
	{
		for( uint i = 0; i < m_hBeams.length(); i++ )
		{
			if( m_hBeams[i].IsValid() )
			{
				g_EntityFuncs.Remove( m_hBeams[i].GetEntity() );
				m_hBeams[i] = null;
			}
		}
		m_uiBeams = 0;
	}
	
	void CreateSparkBall( int attachment )
	{
		if( m_hSparkBall.GetEntity() !is null )
			return;

		CSprite@ pSprite = g_EntityFuncs.CreateSprite( "sprites/gunmanchronicles/ballspark.spr", self.pev.origin, true );
		
		if( pSprite is null )
			return;
		
		pSprite.SetTransparency( kRenderTransAdd, 255, 255, 255, 255, kRenderFxNone );
		pSprite.SetAttachment( self.edict(), attachment );
		
		m_hSparkBall = EHandle(pSprite);
	}
	
	void ClearSparkBall()
	{
		if( m_hSparkBall.IsValid() )
		{
			g_EntityFuncs.Remove( m_hSparkBall.GetEntity() );
			m_hSparkBall = null;
		}
	}
};

float UTIL_SplineFraction( float value, float scale )
{
	value = scale * value;
	float valueSquared = value * value;

	// Nice little ease-in, ease-out spline-like curve
	return 3 * valueSquared - 2 * valueSquared * value;
}

void RegisterEntity_MonsterTrainingBot()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_trainingbot", "monster_trainingbot" );
}

