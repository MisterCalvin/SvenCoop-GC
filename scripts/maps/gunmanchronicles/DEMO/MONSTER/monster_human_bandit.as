namespace MonsterHumanBandit
{

const int BANDIT_AE_DRAW			= 3;
const int BANDIT_AE_SHOOT_1			= 1;
const int BANDIT_AE_SHOOT_2			= 2;
const int BANDIT_AE_HOLSTER			= 4;

const int BANDIT_BODY_DUALPISTOL	= 0;
const int BANDIT_BODY_HOLSTER		= 1;
const int BANDIT_BODY_MINIGUN		= 2;
const int BANDIT_BODY_GUNGONE		= 3;

enum bandit_bg_e
{
	BODY = 0,
	WEAPONS,
	HEADS,
	ARMOR
};

string npcmodel = "models/gunmanchronicles/bandit.mdl";

class Color
{ 
	uint8 r, g, b, a;
	
	Color() { r = g = b = a = 0; }
	Color(uint8 _r, uint8 _g, uint8 _b, uint8 _a = 255 ) { r = _r; g = _g; b = _b; a = _a; }
	Color (Vector v) { r = int(v.x); g = int(v.y); b = int(v.z); a = 255; }
	string ToString() { return "" + r + " " + g + " " + b + " " + a; }
}

const Color RED(255,0,0);
const Color GREEN(0,255,0);
const Color BLUE(0,0,255);
const Color CYAN(0,255,255);

class CMonsterHumanBandit : ScriptBaseMonsterEntity, LaserEffect
{
	private bool	m_fGunDrawn;
	private float	m_painTime;
	private int		m_head;
	private int		m_iBrassShell;
	private int		m_cClipSize;
	private float	m_flPainTime;
	private	Vector	getattach;
	private string  getattach_sz;

	private	int		DMG_SHOTGUNBLAST	= 67108866; // Two digits above DMG_LAUNCH? ; KCM

	private string	m_szPulseSound			= "gunmanchronicles/weapons/gauss_fire1.wav";
	private string	m_szLaserBeam			= "sprites/gunmanchronicles/gaussbeam2.spr";

    private int 	m_iCurBodyConfig = 0;
    
	CMonsterHumanBandit()
	{
		@this.m_Schedules = @monster_human_bandit_schedules;
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
        
		ys = 360; // 270 seems to be an ideal speed, which matches most animations

		self.pev.yaw_speed = ys;
	}
	
	bool CheckRangeAttack1( float flDot, float flDist )
	{	
		if( flDist <= 2048 && flDot >= 0.5 )
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

	void FirePulseMode()
	{
		Math.MakeVectors( self.pev.angles );
		Vector vecShootOrigin = self.pev.origin + Vector( 0, 0, 55 );
		Vector vecShootDir	= self.ShootAtEnemy( vecShootOrigin );
		Vector angDir		  	= Math.VecToAngles( vecShootDir );

		// pulse mode is most accurate, so use zero vector
		self.FireBullets(1, vecShootOrigin, vecShootDir, g_vecZero, 1024, BULLET_MONSTER_9MM, 0 );

		//te_beampoints( vecShootOrigin, vecShootDir );

		//te_spritetrail( vecShootOrigin, vecShootDir );

		te_usertracer( vecShootOrigin, vecShootDir );

		//CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();

		//te_beaments( self, pEnemy );
		
		self.SetBlending( 0, angDir.x );
		GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, self.pev.origin, GAUSS_PRIMARY_FIRE_VOLUME, 0.3, self );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, ( m_szPulseSound ), 1, ATTN_NORM, 0, PITCH_NORM );

		if( self.pev.movetype != MOVETYPE_FLY && self.m_MonsterState != MONSTERSTATE_PRONE )
		{
			self.m_flAutomaticAttackTime = g_Engine.time + Math.RandomFloat(0.2, 0.5);
		}

		//g_Game.AlertMessage( at_console, "Attachment: " + GETATTACHMENT + "\n");

		// Reload
		--self.m_cAmmoLoaded; // take away a bullet!
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
		case BANDIT_AE_SHOOT_1:
			FirePulseMode();
			break;
		case BANDIT_AE_SHOOT_2:
			FirePulseMode();
			break;
		case BANDIT_AE_DRAW:
			// Bandit's bodygroup switches here so he can pull gun from holster
			self.pev.body = BANDIT_BODY_DUALPISTOL;
			m_fGunDrawn = true;
			break;

		case BANDIT_AE_HOLSTER:
			// change bodygroup to replace gun in holster
			self.pev.body = BANDIT_BODY_HOLSTER;
			m_fGunDrawn = false;
			break;

		default:
			BaseClass.HandleAnimEvent( pEvent );
		}
	}
	
	void Precache()
	{
		BaseClass.Precache();

		// Model precache optimization
		if( string( self.pev.model ).IsEmpty() )
		{
				g_Game.PrecacheModel("models/gunmanchronicles/bandit.mdl");
		}
        	g_SoundSystem.PrecacheSound( "gunmanchronicles/bandit/bandit_draw.wav" );
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
			g_SoundSystem.PrecacheSound( "gunmanchronicles/demoman/demo_kick.wav" );

			g_Game.PrecacheModel( m_szLaserBeam );

			PrecacheGenericSound( m_szPulseSound );

		m_iBrassShell = g_Game.PrecacheModel("models/shell.mdl");
		g_Game.PrecacheModel("models/gunmanchronicles/skull.mdl");
	}
	
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/gunmanchronicles/bandit.mdl" );
            
        m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( npcmodel ), m_iCurBodyConfig, HEADS, Math.RandomLong( 0, 3 ) );

		g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );

		pev.solid					= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		if( self.pev.health == 0.0f )
			self.pev.health  = 100.0f;
		self.pev.view_ofs			= Vector( 0, 0, 50 ); // position of the eyes relative to monster's origin.; Originally last digit was 50
		self.m_flFieldOfView		= VIEW_FIELD_WIDE; // NOTE: we need a wide field of view so npc will notice player and say hello
		self.m_MonsterState			= MONSTERSTATE_NONE;
        self.pev.body				= m_iCurBodyConfig;
		m_fGunDrawn					= false;
		self.m_afCapability			= bits_CAP_HEAR | bits_CAP_TURN_HEAD | bits_CAP_DOORS_GROUP | bits_CAP_USE_TANK;
		self.m_fCanFearCreatures 	= true; // Can attempt to run away from things like zombies
		
		m_cClipSize					= 17; //17 Shots
		self.m_cAmmoLoaded			= m_cClipSize;

		if( string( self.m_FormattedName ).IsEmpty() )
		{
				self.m_FormattedName = "Bandit";
		}

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
        //case 3: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "gunmanchronicles/bandit/bandit_flinch4.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
        //case 4: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "gunmanchronicles/bandit/bandit_flinch5.wav", 1, ATTN_NORM, 0, PITCH_NORM); break;
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

	/*void Killed(entvars_t@ pevAttacker, int iGibbed)
	{
		BaseClass.Killed(pevAttacker, iGibbed);
	}

	void BecomeDead( int flSavedHealth )
	{

	}*/

	void ClientPrintf(CBasePlayer@ pPlayer, PRINT_TYPE printType, const string& in szMessage)
	{
		return;
	}
	
void TraceAttack( entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in ptr, int bitsDamageType)
    {
        CBaseEntity@ pEntity = g_EntityFuncs.Instance( ptr.pHit );
    
        if( ptr.iHitgroup == 1 && ( bitsDamageType & ( DMG_SNIPER | DMG_BULLET | DMG_ENERGYBEAM | DMG_SHOTGUNBLAST ) ) != 0 )
        {

			if ( self.pev.health <= 0)
				return;

			g_Game.AlertMessage( at_console, "Damage before calc: " + flDamage + "\n");

			flDamage *= 0.7;

			g_Game.AlertMessage( at_console, "Damage after calc: " + flDamage + "\n");

			if( self.pev.health <= 35.0f || flDamage >= 35.0f )
				{


					if ( bitsDamageType == DMG_SHOTGUNBLAST )
					{
						g_Game.AlertMessage( at_console, "Shotgun decapitation!\n");
					}

				// Decapitate
				self.pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( npcmodel ), 0, HEADS, 4 );
				//self.pev.body	= self.SetBodyGroup( 2, 4 ); // No head
				//self.pev.body	= self.SetBodyGroup( 1, 3 ); // No weapons
				self.pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( npcmodel ), self.pev.body, WEAPONS, 3 ); 

				BaseClass.Killed(pevAttacker, GIB_NEVER );
				//BaseClass.BecomeDead( flSavedHealth == 0 );

				//te_bloodstream( self.pev.origin + self.pev.view_ofs, Vector(0,0,15) ); // Original Values; KCM
				//te_breakmodel( self.pev.origin + self.pev.view_ofs, Vector(0, 0, 0), Vector(0, 0, 0) ); // Original Values; KCM

				te_bloodstream( self.pev.origin + self.pev.view_ofs, Vector(16,32,64) );
				te_breakmodel( self.pev.origin + self.pev.view_ofs, Vector(0, 0, 0), Vector(0, 0, 0) );
				}
	
		}

		BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
		g_Game.AlertMessage( at_console, "Current Health: " + self.pev.health + "\n");	
	}

	Schedule@ GetScheduleOfType( int Type )
	{		
		Schedule@ psched;

		switch( Type )
		{
		case SCHED_ARM_WEAPON:
			if( self.m_hEnemy.IsValid() )
				return slBarneyEnemyDraw; // face enemy, then draw.
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
					
				// wait for one schedule to draw gun
				if( !m_fGunDrawn )
					return self.GetScheduleOfType( SCHED_ARM_WEAPON );

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

	void te_breakmodel(Vector pos, Vector size, Vector velocity, 
	uint8 speedNoise=16, string model="models/gunmanchronicles/skull.mdl", uint8 count=1, 
	uint8 life=100, uint8 flags=0, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
	{
		NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
		m.WriteByte(TE_BREAKMODEL);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteCoord(size.x);
		m.WriteCoord(size.y);
		m.WriteCoord(size.z);
		m.WriteCoord(velocity.x);
		m.WriteCoord(velocity.y);
		m.WriteCoord(velocity.z);
		m.WriteByte(speedNoise);
		m.WriteShort(g_EngineFuncs.ModelIndex(model));
		m.WriteByte(count);
		m.WriteByte(life);
		m.WriteByte(flags);
		m.End();
	}

	void te_bloodstream(Vector pos, Vector dir, uint8 color=70, uint8 speed=64,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
	{
		NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
		m.WriteByte(TE_BLOODSTREAM);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteCoord(dir.x);
		m.WriteCoord(dir.y);
		m.WriteCoord(dir.z);
		m.WriteByte(color);
		m.WriteByte(speed);
		m.End();
	}

	void te_beampoints(Vector start, Vector end, 
	string sprite="sprites/gunmanchronicles/gaussbeam2.spr", uint8 frameStart=0, 
	uint8 frameRate=100, uint8 life=1, uint8 width=8, uint8 noise=1, 
	Color c=CYAN, uint8 scroll=32,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
	{
		NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
		m.WriteByte(TE_BEAMPOINTS);
		m.WriteCoord(start.x);
		m.WriteCoord(start.y);
		m.WriteCoord(start.z);
		m.WriteCoord(end.x);
		m.WriteCoord(end.y);
		m.WriteCoord(end.z);
		m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
		m.WriteByte(frameStart);
		m.WriteByte(frameRate);
		m.WriteByte(life);
		m.WriteByte(width);
		m.WriteByte(noise);
		m.WriteByte(c.r);
		m.WriteByte(c.g);
		m.WriteByte(c.b);
		m.WriteByte(c.a); // actually brightness
		m.WriteByte(scroll);
		m.End();
	}

	void te_spritetrail(Vector start, Vector end, 
	string sprite="sprites/gunmanchronicles/gaussbeam2.spr", uint8 count=1, uint8 life=1, 
	uint8 scale=1, uint8 speed=96, uint8 speedNoise=8,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRITETRAIL);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteByte(life);
	m.WriteByte(scale);
	m.WriteByte(speedNoise);
	m.WriteByte(speed);
	m.End();
}

void te_usertracer(Vector pos, Vector dir, float speed=60.0f, 
	uint8 life=100, uint color=4, uint8 length=8,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	Vector velocity = dir*speed;
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_USERTRACER);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteByte(life);
	m.WriteByte(color);
	m.WriteByte(length);
	m.End();
}

}

array<ScriptSchedule@>@ monster_human_bandit_schedules;

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
	
	@monster_human_bandit_schedules = @scheds;
}

enum monsterScheds
{
	SCHED_BARNEY_RELOAD = LAST_COMMON_SCHEDULE + 1,
}

void Register()
{
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity( "MonsterHumanBandit::CMonsterHumanBandit", "monster_human_bandit" );
}

}