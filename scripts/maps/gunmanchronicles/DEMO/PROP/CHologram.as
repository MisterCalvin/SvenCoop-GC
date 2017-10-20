#include "../GC_CommonFunctions"

//=========================================================
// Generic Monster - purely for scripted sequence work.
//=========================================================

const int SF_HOLOGRAM_STARTON = 1024;

enum hologrambeak_creatures
{
	HOLOGRAM_CREATURE_BEAK = 0,
	HOLOGRAM_CREATURE_TUBE,
	HOLOGRAM_CREATURE_RAPTOR
}

enum hologrambeak_thinktype
{
	HOLOGRAM_THINK_NULL = 0,
	HOLOGRAM_THINK_NORMAL,
	HOLOGRAM_THINK_FADEOUT,
	HOLOGRAM_THINK_PRERESPAWN,
	HOLOGRAM_THINK_RESPAWN
}

//=========================================================
// Monster's Anim Events Go Here
//=========================================================

abstract class CHologram : ScriptBaseMonsterEntity
{
	int		m_iCreature;
	string	m_szTargetFail;
	float	m_flNextFail;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "creaturetype" )
		{
			m_iCreature = atoi( szValue );
			return true;
		}
		else if ( szKey == "targetfail" )
		{
			m_szTargetFail = szValue;
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
		return CLASS_INSECT;
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

		if( self.pev.oldorigin == g_vecZero )
			self.pev.oldorigin = self.pev.origin;
		
		string szModel = self.pev.model.opImplConv();
		
		if( szModel.IsEmpty() )
		{
			switch( m_iCreature )
			{
				case HOLOGRAM_CREATURE_TUBE:
				{
					szModel = "models/gunmanchronicles/tube.mdl";
					break;
				}
				case HOLOGRAM_CREATURE_RAPTOR:
				{
					szModel = "models/gunmanchronicles/Raptor.mdl";
					break;
				}
				default:
				{
					szModel = "models/gunmanchronicles/Beak.mdl";
				}
			}
		}
		g_EntityFuncs.SetModel(self, szModel);
		
		self.pev.sequence = 0;
		
		// Get sequence bbox
		Vector mins, maxs;
		if( self.ExtractBbox( self.pev.sequence, mins, maxs ) == false )
		{
			mins = self.pev.mins;
			maxs = self.pev.maxs;
		}
		
		//if( maxs.z < VEC_HULL_MAX.z )
		//	maxs.z = VEC_HULL_MAX.z;
		
		g_EntityFuncs.SetSize( self.pev, mins, maxs );

		m_flNextFail = 0.0f;
		
		if( self.pev.max_health <= 0.0 )
			self.pev.max_health = 1000;
		
		if( self.pev.health <= 0.0 )
			self.pev.health = self.pev.max_health;
		
		self.pev.solid			= SOLID_BBOX;
		self.pev.movetype		= MOVETYPE_FLY;
		self.m_bloodColor		= DONT_BLEED;
		
		g_EntityFuncs.SetOrigin( self, self.pev.oldorigin );
		
		self.pev.view_ofs		= VEC_VIEW;// position of the eyes relative to monster's origin.
		self.m_flFieldOfView	= 0.5;// indicates the width of this monster's forward view cone ( as a dotproduct result )
		self.m_MonsterState		= MONSTERSTATE_NONE;
		
		self.m_afCapability		= bits_CAP_HEAR;

		self.MonsterInit();
		
		if( self.pev.netname.opImplConv().IsEmpty() )
			self.pev.netname		=	"Shooting Target Hologram";
		
		if( self.m_FormattedName.opImplConv().IsEmpty() )
			self.m_FormattedName	=	self.pev.netname;
		
		if( self.pev.renderfx == 0 )
			self.pev.renderfx = 255;
		
		if( self.pev.renderamt == 0 )
			self.pev.renderamt = 255;
		
		if( self.pev.rendermode == kRenderNormal )
			self.pev.rendermode = kRenderTransAdd;
		
		if( self.pev.SpawnFlagBitSet( SF_HOLOGRAM_STARTON ) == false )
			Use( self, self, USE_OFF );
	}

	//=========================================================
	// Precache - precaches all resources this monster needs
	//=========================================================
	void Precache()
	{
		BaseClass.Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/Beak.mdl" );
		g_Game.PrecacheModel( "models/gunmanchronicles/tube.mdl" );
		g_Game.PrecacheModel( "models/gunmanchronicles/Raptor.mdl" );
	}

	/*
	============
	TakeDamage

	The damage is coming from inflictor, but get mad at attacker
	This should be the only function that ever reduces health.
	bitsDamageType indicates the type of damage sustained, ie: DMG_SHOCK

	Time-based damage: only occurs while the monster is within the trigger_hurt.
	When a monster is poisoned via an arrow etc it takes all the poison damage at once.

	GLOBALS ASSUMED SET:  g_iSkillLevel
	============
	*/
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		int result = BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		
		if( result > 0 )
		{
			CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );
			self.SUB_UseTargets( pAttacker, USE_SET, flDamage );
			
			if( pAttacker !is null) pevAttacker.frags += pAttacker.GetPointsForDamage( flDamage );
			
			m_flNextFail	=	g_Engine.time + 4.0f;
		}
		
		return result;
	}
	
	void Think()
	{
		// Don't Move!
		if( self.IsMoving() )
		{
			self.m_iRouteIndex		= 0;
			self.m_vecMoveGoal		= g_vecZero;
			self.m_movementGoal 	= MOVEGOAL_NONE;
			self.Forget(bits_MEMORY_MOVE_FAILED);
			
			int randomizer = Math.RandomLong( 0,3 );
			switch( randomizer )
			{
				case 1:
				{
					//self.m_IdealActivity    = ACT_WALK ;
					self.m_movementActivity = ACT_WALK ;
					break;
				}
				case 2:
				{
					//self.m_IdealActivity    = ACT_RUN ;
					self.m_movementActivity = ACT_RUN ;
					break;
				}
				case 3:
				{
					//self.m_IdealActivity    = ACT_MELEE_ATTACK1 ;
					self.m_movementActivity = ACT_MELEE_ATTACK1 ;
					break;
				}
				default:
				{
					//self.m_IdealActivity    = ACT_IDLE ;
					self.m_movementActivity = ACT_IDLE ;
				}
			}
			//self.m_movementActivity = ACT_IDLE;
		}
		
		BaseClass.Think();
		
		// Don't Move!!
		/*if( self.pev.movetype != MOVETYPE_FLY )
		{
			self.pev.movetype		= MOVETYPE_FLY;
			g_EntityFuncs.SetOrigin( self, self.pev.oldorigin );
		}*/
		
		// fire fail target
		if( m_flNextFail > 0.0 && g_Engine.time > m_flNextFail )
		{
			 // fire fail target and respawn
			FireFailTarget();
			Killed( null, -1 );
		}
	}
	
	void FireFailTarget()
	{
		m_flNextFail = 0.0;
		
		CBaseEntity@ pEnt = g_EntityFuncs.Create( "trigger_auto", self.pev.origin, Vector(0, 0, 0), true );
		
		if( pEnt is null )
			return;
		
		g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "target",		m_szTargetFail );
		g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "spawnflags",	"1" );
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
	}
	
	/*
	============
	Killed
	============
	*/
	void Killed( entvars_t@ pevAtttacker, int iGibbed )
	{
		SetEntityThink( HOLOGRAM_THINK_NULL );
		
		self.pev.takedamage	=	DAMAGE_NO;
		self.pev.deadflag	=	DEAD_DEAD;
		
		//if( Math.RandomLong( 0,1 ) == 0 ) 
			self.SetActivity( ACT_DIESIMPLE );
		//else
		//	self.SetActivity( ACT_TWITCH );
		
		self.Remember( bits_MEMORY_KILLED );
		
		self.m_IdealMonsterState = MONSTERSTATE_DEAD;
		// Make sure this condition is fired too (TakeDamage breaks out before this happens on death)
		self.SetConditions( bits_COND_LIGHT_DAMAGE );
		self.m_IdealMonsterState = MONSTERSTATE_DEAD;
		
		// fire fail target
		//if( m_flNextFail > 0.0 )
		//{
		//	FireFailTarget();
		//}
		
		self.pev.health = 0.0f;
		FadeMonster();
	}
	
	void FadeMonster()
	{
		//g_EntityFuncs.SetSize(self.pev, Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) );
		self.pev.velocity	= g_vecZero;
		self.pev.avelocity	= g_vecZero;
		//self.pev.solid		= SOLID_NOT;
		self.pev.movetype	= MOVETYPE_FLY;
		self.pev.effects	|= EF_NOINTERP;
		SUB_StartFadeOut();
	}
	
	//
	// fade out - slowly fades a entity out, then removes it.
	//
	// DON'T USE ME FOR GIBS AND STUFF IN MULTIPLAYER! 
	// SET A FUTURE THINK AND A RENDERMODE!!
	void SUB_StartFadeOut()
	{
		if( self.pev.rendermode == kRenderNormal )
		{
			self.pev.renderamt = 255;
			self.pev.rendermode = kRenderTransTexture;
		}
		
		SetEntityThink( HOLOGRAM_THINK_FADEOUT );
		self.pev.nextthink = g_Engine.time + 0.1;
	}

	void SUB_FadeOut()
	{
		float flInterval = self.StudioFrameAdvance(); // animate
		self.DispatchAnimEvents( flInterval );
		
		if( self.pev.renderamt > 7 )
		{
			self.pev.renderamt -= 7;
			self.pev.nextthink = g_Engine.time + 0.1;
		}
		else 
		{
			self.pev.renderamt = 0;
			
			SetEntityThink( HOLOGRAM_THINK_PRERESPAWN );
			self.pev.nextthink = g_Engine.time + 0.2;
		}
	}
	
	void PreRespawnThink()
	{
		uint8 life = 3;
		
		NetworkMessage m( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, self.pev.oldorigin );
			m.WriteByte(TE_IMPLOSION);
			m.WriteCoord( self.pev.oldorigin.x );
			m.WriteCoord( self.pev.oldorigin.y );
			m.WriteCoord( self.pev.oldorigin.z );
			m.WriteByte( 100 );			// radius
			m.WriteByte( 100 );			// count
			m.WriteByte( life*10 );		// life
		m.End();
		
		SetEntityThink( HOLOGRAM_THINK_RESPAWN );
		self.pev.nextthink = g_Engine.time + life;
	}
	
	void RespawnThink()
	{
		//if( self.pev.SpawnFlagBitSet( SF_HOLOGRAM_STARTON ) == false )
		//	self.pev.spawnflags |= SF_HOLOGRAM_STARTON;
		
		//Spawn();
		g_EntityFuncs.DispatchSpawn( self.edict() );
		
		Use( self, self, USE_ON );
		SetEntityThink( HOLOGRAM_THINK_NORMAL );
	}

	//=========================================================
	// AI Schedules Specific to this monster
	//=========================================================
	Schedule@ GetSchedule()
	{
		// so we don't keep calling through the EHANDLE stuff
		/*CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();
		
		if( pEnemy !is null )
		{
			self.m_hEnemy = null;
			@pEnemy   = null;
		}*/
		
		if( self.HasConditions( bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE ) )
		{
			// flinch if hurt
			int schedType = Math.RandomLong( 0, 1 ) == 0 ? SCHED_SMALL_FLINCH : SCHED_SMALL_FLINCH_SPECIAL;
			return BaseClass.GetScheduleOfType( schedType );
		}
		
		return BaseClass.GetSchedule();
	}
	void StartTask( Task@ pTask )
	{
		if( isNotMovementTask( pTask.iTask ) )
			BaseClass.StartTask( pTask );
	}
	
	void RunTask( Task@ pTask )
	{
		if( isNotMovementTask( pTask.iTask ) )
			BaseClass.RunTask( pTask );
	}
	
	bool isNotMovementTask( int iTask )
	{
		switch( iTask )
		{
		case TASK_WALK_PATH:
		case TASK_RUN_PATH:
		case TASK_TURN_LEFT	:
		case TASK_TURN_RIGHT :
		case TASK_FACE_ROUTE:
		case TASK_FACE_ENEMY:
		case TASK_FACE_HINTNODE:
		case TASK_FACE_TARGET:
			{
				self.TaskComplete();
				return false;
			}
		}
		return true;
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
	{
		bool isActive = IsActive();

		// isActive is TRUE only if an announcement is pending

		if( useType != USE_TOGGLE )
		{
			// ignore if we're just turning something on that's already on, or
			// turning something off that's already off.
			if( ( isActive && useType == USE_ON ) || ( !isActive && useType == USE_OFF ) )
				return;
		}

		if( useType == USE_ON )
		{
			// turn on announcements
			Enable();
			
			self.pev.nextthink = g_Engine.time + 0.1;
			return;
		}

		if( useType == USE_OFF )
		{
			// turn off announcements
			Disable();
			
			self.pev.nextthink = 0.0;
			return;
		}

		// Toggle announcements
		if( isActive )
		{
			// turn off announcements
			Disable();
			
			self.pev.nextthink = 0.0;
		}
		else 
		{
			// turn on announcements
			Enable();
			
			self.pev.nextthink = g_Engine.time + 0.1;
		}
		
		//BaseClass.Use( @pActivator, @pCaller, useType, flValue );
	}
	
	bool IsActive()
	{
		return ( self.pev.effects & EF_NODRAW ) == 0;
	}
	
	void Disable()
	{
		self.pev.effects		|= EF_NODRAW;
		self.pev.takedamage		=  DAMAGE_NO;
		self.pev.solid			=  SOLID_NOT;
	}
	
	void Enable()
	{
		self.pev.effects		&= ~EF_NODRAW;
		self.pev.takedamage		=  DAMAGE_YES;
		self.pev.solid			=  SOLID_BBOX;
		
		// Get sequence bbox
		Vector mins, maxs;
		if( self.ExtractBbox( 0, mins, maxs ) == false )
		{
			mins = self.pev.mins;
			maxs = self.pev.maxs;
		}
		g_EntityFuncs.SetSize( self.pev, mins, maxs );
		
		//self.ChangeSchedule( BaseClass.GetScheduleOfType( SCHED_IDLE_STAND ) );
	}
	
	void SetEntityThink( hologrambeak_thinktype thtype )
	{
		switch( thtype ) 
		{
			case HOLOGRAM_THINK_NULL       :
			{
				SetThink( null );
				break;
			}
			case HOLOGRAM_THINK_FADEOUT    :
			{
				SetThink( ThinkFunction( this.SUB_FadeOut ) );
				break;
			}
			case HOLOGRAM_THINK_PRERESPAWN :
			{
				SetThink( ThinkFunction( this.PreRespawnThink ) );
				break;
			}
			case HOLOGRAM_THINK_RESPAWN    :
			{
				SetThink( ThinkFunction( this.RespawnThink ) );
				break;
			}
			case HOLOGRAM_THINK_NORMAL :
			default:
			{
				SetThink( ThinkFunction( this.Think ) );
			}
		}
	}
}

mixin class HologramThink
{
	void SetEntityThink( hologrambeak_thinktype thtype )
	{
		switch( thtype ) 
		{
			case HOLOGRAM_THINK_NULL       :
			{
				SetThink( null );
				break;
			}
			case HOLOGRAM_THINK_FADEOUT    :
			{
				SetThink( ThinkFunction( this.Child_SUB_FadeOut ) );
				break;
			}
			case HOLOGRAM_THINK_PRERESPAWN :
			{
				SetThink( ThinkFunction( this.Child_PreRespawnThink ) );
				break;
			}
			case HOLOGRAM_THINK_RESPAWN    :
			{
				SetThink( ThinkFunction( this.Child_RespawnThink ) );
				break;
			}
			case HOLOGRAM_THINK_NORMAL :
			default:
			{
				SetThink( ThinkFunction( this.Child_NormalThink ) );
			}
		}
	}
	
	void Child_NormalThink()
	{
		CHologram::Think();
	}
	void Child_SUB_FadeOut()
	{
		CHologram::SUB_FadeOut();
	}
	void Child_PreRespawnThink()
	{
		CHologram::PreRespawnThink();
	}
	void Child_RespawnThink()
	{
		CHologram::RespawnThink();
	}
}
