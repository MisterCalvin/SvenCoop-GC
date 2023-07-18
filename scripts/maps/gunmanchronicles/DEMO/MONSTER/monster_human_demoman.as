namespace MonsterHumanDemoman
{

//const int DEMOMAN_AE_LAUNCHROCKET	= 1;
const int DEMOMAN_AE_THROWGRENADE	= 2;
const int DEMOMAN_AE_DROPMINE		= 3;
const int DEMOMAN_AE_KICK			= 4;
const int DEMOMAN_AE_SHOOTSHOTGUN	= 1;

const int DEMOMAN_BODY_WEAPON		= 0;
const int DEMOMAN_BODY_GUNGONE		= 1;

enum demoman_bg_e
{
	BODY = 0,
	WEAPON,
	HEAD,
	ARM
};

enum demoman_skins_e
{
	BLACK = 0,
	WHITE
};

class CMonsterHumanDemoman : ScriptBaseMonsterEntity
{
	private float	m_painTime;
	private int		m_iBrassShell;
	private int		m_cClipSize;
	private	float	m_flPainTime;

	private string	m_szShootSound			= "gunmanchronicles/weapons/sbarrel1.wav";
	
	CMonsterHumanDemoman()
	{
		@this.m_Schedules = @monster_human_demoman_schedules;
	}
	
	int ObjectCaps()
	{
			return BaseClass.ObjectCaps();
	}
	
	void RunTask( Task@ pTask )
	{
		switch ( pTask.iTask )
		{
		case TASK_RANGE_ATTACK1:

			self.pev.framerate = 1.5f;
			BaseClass.RunTask( pTask );
			break;

		case ACT_SPECIAL_ATTACK1:
			self.pev.framerate = 1.5f;
			BaseClass.RunTask( pTask );
			break;

		case TASK_RELOAD:
			{
				self.MakeIdealYaw ( self.m_vecEnemyLKP );
				self.ChangeYaw ( int(self.pev.yaw_speed) );

				if( self.m_fSequenceFinished )
				{
					self.m_cAmmoLoaded = m_cClipSize;
					self.ClearConditions(bits_COND_NO_AMMO_LOADED);
					//m_Activity = ACT_RESET;

					self.TaskComplete();
				}
				break;
			}
		default:
			BaseClass.RunTask( pTask );
			break;
		}
	}
	
	int ISoundMask()
	{
		return	bits_SOUND_WORLD	|
				bits_SOUND_COMBAT	|
				bits_SOUND_BULLETHIT|
				bits_SOUND_CARCASS	|
				bits_SOUND_MEAT		|
				bits_SOUND_GARBAGE	|
				bits_SOUND_DANGER	|
				bits_SOUND_PLAYER;
	}
	
	int	Classify()
	{
		return self.GetClassification( CLASS_HUMAN_MILITARY );
	}
	
	void SetYawSpeed()
	{
		int ys = 0;

		ys = 360; //270 seems to be an ideal speed, which matches most animations

		self.pev.yaw_speed = ys;
	}
	
	bool CheckRangeAttack1( float flDot, float flDist )
	{	
		if( flDist <= 2048 && flDot >= 0.5 && self.NoFriendlyFire())
		{
			CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();
			TraceResult tr;
			Vector shootOrigin = self.pev.origin + Vector( 0, 0, 55 );
			Vector shootTarget = (pEnemy.BodyTarget( shootOrigin ) - pEnemy.Center()) + self.m_vecEnemyLKP;
			g_Utility.TraceLine( shootOrigin, shootTarget, dont_ignore_monsters, self.edict(), tr );
						
			if( tr.flFraction == 1.0 || tr.pHit is pEnemy.edict() )
				return true;
		}

		return false;
	}

		bool CheckSpecialAttack1( float flDot, float flDist )
	{	
		if( flDist <= 2048 && flDot >= 0.5 && self.NoFriendlyFire())
		{
			CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();
			TraceResult tr;
			Vector shootOrigin = self.pev.origin + Vector( 0, 0, 55 );
			Vector shootTarget = (pEnemy.BodyTarget( shootOrigin ) - pEnemy.Center()) + self.m_vecEnemyLKP;
			g_Utility.TraceLine( shootOrigin, shootTarget, dont_ignore_monsters, self.edict(), tr );
						
			if( tr.flFraction == 1.0 || tr.pHit is pEnemy.edict() )
				return true;
		}

		return false;
	}
	
	void FireShotgun()
	{
		Math.MakeVectors( self.pev.angles );
		Vector vecShootOrigin = self.pev.origin + Vector( 0, 0, 55 );
		Vector vecShootDir	= self.ShootAtEnemy( vecShootOrigin );
		Vector angDir		  	= Math.VecToAngles( vecShootDir );

		self.FireBullets(1, vecShootOrigin, vecShootDir, VECTOR_CONE_2DEGREES, 1024, BULLET_MONSTER_BUCKSHOT );
		Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40,90) + g_Engine.v_up * Math.RandomFloat(75,200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
		g_EntityFuncs.EjectBrass( vecShootOrigin - vecShootDir * -17, vecShellVelocity, self.pev.angles.y, m_iBrassShell, TE_BOUNCE_SHELL); 

		int pitchShift = Math.RandomLong( 0, 20 );
		if( pitchShift > 10 )// Only shift about half the time
			pitchShift = 0;
		else
			pitchShift -= 5;
		
		self.SetBlending( 0, angDir.x );
		self.pev.effects = EF_MUZZLEFLASH;
		GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, self.pev.origin, NORMAL_GUN_VOLUME, 0.3, self );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, m_szShootSound, 1, ATTN_NORM, 0, PITCH_NORM + pitchShift );

		if( self.pev.movetype != MOVETYPE_FLY && self.m_MonsterState != MONSTERSTATE_PRONE )
		{
			self.m_flAutomaticAttackTime = g_Engine.time + Math.RandomFloat(0.5, 0.8);
		}

		--self.m_cAmmoLoaded;
	}
	
	void CheckAmmo()
	{
		if( self.m_cAmmoLoaded <= 0 )
			self.SetConditions( bits_COND_NO_AMMO_LOADED );
	}
	
	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
		case DEMOMAN_AE_SHOOTSHOTGUN:
			FireShotgun();
			break;
		/*case BARNEY_AE_DRAW:
			// barney's bodygroup switches here so he can pull gun from holster
			self.pev.body = BARNEY_BODY_GUNDRAWN;
			m_fGunDrawn = true;
			break;

		case BARNEY_AE_HOLSTER:
			// change bodygroup to replace gun in holster
			self.pev.body = BARNEY_BODY_GUNHOLSTERED;
			m_fGunDrawn = false;
			break;*/

		default:
			BaseClass.HandleAnimEvent( pEvent );
		}
	}
	
	void Precache()
	{
		BaseClass.Precache();

		g_Game.PrecacheModel( "models/gunmanchronicles/demolitionman.mdl") ;
		m_iBrassShell = g_Game.PrecacheModel( "models/shotgunshell.mdl" );
		 
        g_SoundSystem.PrecacheSound( m_szShootSound );
        g_SoundSystem.PrecacheSound( "gunmanchronicles/demoman/demo_idlelong.wav" );
		g_SoundSystem.PrecacheSound( "gunmanchronicles/demoman/demo_kick.wav" );

		g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_diesimple.wav" );
		g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_dieviolent.wav" );
		g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_dieforwards.wav" );
		g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_diebackwards.wav" );
		g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_dieheadshot.wav" );
    	g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_flinch1.wav" );
    	g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_flinch2.wav" );
    	g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_flinch3.wav" );
    	g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_flinch4.wav" );
    	g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_flinch5.wav" );
	}
	
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/gunmanchronicles/demolitionman.mdl" );
		g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );

		pev.solid					= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		if( self.pev.health == 0.0f )
			self.pev.health  = 100.0f;
		self.pev.view_ofs			= Vector( 0, 0, 50 );// position of the eyes relative to monster's origin.
		self.m_flFieldOfView		= VIEW_FIELD_WIDE; // NOTE: we need a wide field of view so npc will notice player and say hello
		self.m_MonsterState			= MONSTERSTATE_NONE;
		self.pev.body				= 0;
		self.m_afCapability			= bits_CAP_HEAR | bits_CAP_TURN_HEAD | bits_CAP_DOORS_GROUP | bits_CAP_USE_TANK;

		m_cClipSize					= 8;
		self.m_cAmmoLoaded			= m_cClipSize;

		self.m_FormattedName = "Demolition Man";

		self.MonsterInit();
	}
	
	void PainSound()
	{
		if( g_Engine.time < m_flPainTime )
		return;
		
		m_flPainTime = g_Engine.time + Math.RandomFloat(0.5, 0.75);
		switch (Math.RandomLong(0,2))
		{
		case 0: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "gunmanchronicles/bandit/bandit_flinch1.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "gunmanchronicles/bandit/bandit_flinch2.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		case 2: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "gunmanchronicles/bandit/bandit_flinch3.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		}
	}
	
	void DeathSound()
	{
		switch (Math.RandomLong(0,1))
		{
		case 0: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "gunmanchronicles/bandit/bandit_diesimple.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "gunmanchronicles/bandit/bandit_dieviolent.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
		}
	}
	
	void TraceAttack( entvars_t@ pevAttacker, float flDamage, Vector vecDir, TraceResult& in ptr, int bitsDamageType)
	{
		switch( ptr.iHitgroup)
		{
		case HITGROUP_CHEST:
		case HITGROUP_STOMACH:
			if( ( bitsDamageType & ( DMG_BULLET | DMG_SLASH | DMG_BLAST) ) != 0 )
			{
				if(flDamage >= 2)
					flDamage -= 2;

				flDamage *= 0.5;
			}
			break;
		case 10:
			if( ( bitsDamageType & (DMG_SNIPER | DMG_BULLET | DMG_SLASH | DMG_CLUB) ) != 0 )
			{
				flDamage -= 20;
				if( flDamage <= 0 )
				{
					g_Utility.Ricochet( ptr.vecEndPos, 1.0 );
					flDamage = 0.01;
				}
			}
			// always a head shot
			ptr.iHitgroup = HITGROUP_HEAD;
			break;
		}

		BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
	}
	
	Schedule@ GetScheduleOfType( int Type )
	{		
		Schedule@ psched;

		switch( Type )
		{
		case SCHED_ARM_WEAPON:
			if( self.m_hEnemy.IsValid() )
				return slBarneyEnemyDraw;// face enemy, then draw.
			break;

		// Hook these to make a looping schedule
		case SCHED_TARGET_FACE:
			// call base class default so that barney will talk
			// when 'used' 
			@psched = BaseClass.GetScheduleOfType( Type );
			
			if( psched is Schedules::slIdleStand )
				return slBaFaceTarget;	// override this for different target face behavior
			else
				return psched;


		case SCHED_RELOAD:
			return slBaReloadQuick; //Immediately reload.

		case SCHED_BARNEY_RELOAD:
			return slBaReload;

		case SCHED_TARGET_CHASE:
			return slBaFollow;

		case SCHED_IDLE_STAND:
			// call base class default so that scientist will talk
			// when standing during idle
			@psched = BaseClass.GetScheduleOfType( Type );

			if( psched is Schedules::slIdleStand )		
				return slIdleBaStand;// just look straight ahead.
			else
				return psched;
		}

		return BaseClass.GetScheduleOfType( Type );
	}
	
	Schedule@ GetSchedule()
	{
		if( self.HasConditions( bits_COND_HEAR_SOUND ) )
		{
			CSound@ pSound = self.PBestSound();
		}

		if( self.HasConditions( bits_COND_ENEMY_DEAD ) )
			self.PlaySentence( "BA_KILL", 4, VOL_NORM, ATTN_NORM );

		switch( self.m_MonsterState )
		{
		case MONSTERSTATE_COMBAT:
			{
				// dead enemy
				if( self.HasConditions( bits_COND_ENEMY_DEAD ) )				
					return BaseClass.GetSchedule();// call base class, all code to handle dead enemies is centralized there.

				// always act surprized with a new enemy
				if( self.HasConditions( bits_COND_NEW_ENEMY ) && self.HasConditions( bits_COND_LIGHT_DAMAGE) )
					return self.GetScheduleOfType( SCHED_SMALL_FLINCH );
					
				if( self.HasConditions( bits_COND_HEAVY_DAMAGE ) )
					return self.GetScheduleOfType( SCHED_TAKE_COVER_FROM_ENEMY );
				
				//Barney reloads now.
				if( self.HasConditions ( bits_COND_NO_AMMO_LOADED ) )
					return self.GetScheduleOfType ( SCHED_BARNEY_RELOAD );
			}
			break;

		case MONSTERSTATE_IDLE:
				//Barney reloads now.
				if( self.m_cAmmoLoaded != m_cClipSize )
					return self.GetScheduleOfType( SCHED_BARNEY_RELOAD );

		case MONSTERSTATE_ALERT:	
			{
				if( self.HasConditions(bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE) )
					return self.GetScheduleOfType( SCHED_SMALL_FLINCH ); // flinch if hurt

				//The player might have just +used us, immediately follow and dis-regard enemies.
				//This state gets set (alert) when the monster gets +used
				if( (!self.m_hEnemy.IsValid() || !self.HasConditions( bits_COND_SEE_ENEMY)) && self.IsPlayerFollowing() )	//Start Player Following
				{
					if( !self.m_hTargetEnt.GetEntity().IsAlive() )
					{
						self.StopPlayerFollowing( false, false );// UNDONE: Comment about the recently dead player here?
						break;
					}
					else
					{
							
						return self.GetScheduleOfType( SCHED_TARGET_FACE );
					}
				}
			}
			break;
		}
		
		return BaseClass.GetSchedule();
	}
	
	void FollowerUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );
		
		CBaseEntity@ pTarget = self.m_hTargetEnt;
		
		if( pTarget is pActivator )
		{
			g_SoundSystem.PlaySentenceGroup( self.edict(), "BA_OK", 1.0, ATTN_NORM, 0, PITCH_NORM );
		}
		else
			g_SoundSystem.PlaySentenceGroup( self.edict(), "BA_WAIT", 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
}

array<ScriptSchedule@>@ monster_human_demoman_schedules;

ScriptSchedule slBaFollow( 
	bits_COND_NEW_ENEMY		|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER, 
	"Follow" );
		
ScriptSchedule slBaFaceTarget(
	//bits_COND_CLIENT_PUSH	|
	bits_COND_NEW_ENEMY		|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND ,
	bits_SOUND_DANGER,
	"FaceTarget" );
	
ScriptSchedule slIdleBaStand(
	bits_COND_NEW_ENEMY		|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND	|
	bits_COND_SMELL,

	bits_SOUND_COMBAT		|// sound flags - change these, and you'll break the talking code.	
	bits_SOUND_DANGER		|
	bits_SOUND_MEAT			|// scents
	bits_SOUND_CARCASS		|
	bits_SOUND_GARBAGE,
	"IdleStand" );
	
ScriptSchedule slBaReload(
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER,
	"Barney Reload");
	
ScriptSchedule slBaReloadQuick(
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER,
	"Barney Reload Quick");
		
ScriptSchedule slBarneyEnemyDraw( 0, 0, "Barney Enemy Draw" );

void InitSchedules()
{
		
	slBaFollow.AddTask( ScriptTask(TASK_MOVE_TO_TARGET_RANGE, 128.0f) );
	slBaFollow.AddTask( ScriptTask(TASK_SET_SCHEDULE, SCHED_TARGET_FACE) );
	
	slBarneyEnemyDraw.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slBarneyEnemyDraw.AddTask( ScriptTask(TASK_FACE_ENEMY) );
	slBarneyEnemyDraw.AddTask( ScriptTask(TASK_PLAY_SEQUENCE_FACE_ENEMY, float(ACT_ARM)) );
		
	slBaFaceTarget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slBaFaceTarget.AddTask( ScriptTask(TASK_FACE_TARGET) );
	slBaFaceTarget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slBaFaceTarget.AddTask( ScriptTask(TASK_SET_SCHEDULE, float(SCHED_TARGET_CHASE)) );
		
	slIdleBaStand.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slIdleBaStand.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slIdleBaStand.AddTask( ScriptTask(TASK_WAIT, 2) );
	//slIdleBaStand.AddTask( ScriptTask(TASK_TLK_HEADRESET) );
		
	slBaReload.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slBaReload.AddTask( ScriptTask(TASK_SET_FAIL_SCHEDULE, float(SCHED_RELOAD)) );
	slBaReload.AddTask( ScriptTask(TASK_FIND_COVER_FROM_ENEMY) );
	slBaReload.AddTask( ScriptTask(TASK_RUN_PATH) );
	slBaReload.AddTask( ScriptTask(TASK_REMEMBER, float(bits_MEMORY_INCOVER)) );
	slBaReload.AddTask( ScriptTask(TASK_WAIT_FOR_MOVEMENT_ENEMY_OCCLUDED) );
	slBaReload.AddTask( ScriptTask(TASK_RELOAD) );
	slBaReload.AddTask( ScriptTask(TASK_FACE_ENEMY) );
			
	slBaReloadQuick.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slBaReloadQuick.AddTask( ScriptTask(TASK_RELOAD) );
	slBaReloadQuick.AddTask( ScriptTask(TASK_FACE_ENEMY) );
	
	array<ScriptSchedule@> scheds = {slBaFollow, slBarneyEnemyDraw, slBaFaceTarget, slIdleBaStand, slBaReload, slBaReloadQuick};
	
	@monster_human_demoman_schedules = @scheds;
}

enum monsterScheds
{
	SCHED_BARNEY_RELOAD = LAST_COMMON_SCHEDULE + 1,
}

void Register()
{
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity( "MonsterHumanDemoman::CMonsterHumanDemoman", "monster_human_demoman" );
}

} // end of namespace