#include "CGenericVehicle"
#include "vehicle_tank_body"
#include "vehicle_tank_turret"
#include "vehicle_tank_barrel"

enum vehicletank_attachments_e
{
	TANK_ATTACHMENT_CANNON = 0,
	TANK_ATTACHMENT_ROCKET,
	TANK_ATTACHMENT_BULLET_LEFT,
	TANK_ATTACHMENT_BULLET_RIGHT
};

enum vehicletank_anim_e
{
	TANK_ANIM_OFFLINE = 0,
	TANK_ANIM_IDLE,
	TANK_ANIM_BUMP_FRONT,
	TANK_ANIM_BUMP_BACK,
	TANK_ANIM_BUMP_LEFT,
	TANK_ANIM_BUMP_RIGHT,
	TANK_ANIM_BUMP_FRONT_LEFT,
	TANK_ANIM_BUMP_FRONT_RIGHT,
	TANK_ANIM_BUMP_BACK_LEFT,
	TANK_ANIM_BUMP_BACK_RIGHT,
	TANK_ANIM_FIRE_GUNS,
	TANK_ANIM_FIRE_CANNON
}


final class vehicle_tank : CGenericVehicle
{
	EHandle	m_hBody;
	EHandle m_hTurret;
	EHandle m_hBarrel;
	
	Vector[] m_vecChildOffset(3);
	// Constructor
	vehicle_tank()
	{
		this.m_vecExitPos = Vector( 0, 0, 128 );
		
		this.m_flCameraDistance	=	200.0f;
		this.m_flCameraMinPitch	=	-20.0f;
		this.m_flCameraMaxPitch	=	 17.0f;
	}
	
	/*bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "min_turret_pitch" )
		{
			self.pev.idealpitch = atof( szValue );
			return true;
		}
		else
			return CGenericVehicle::KeyValue( szKey, szValue );
	}*/
	
	void Precache()
	{
		this.SoundEnter	=	"gunmanchronicles/Tank/startup.wav";
		this.SoundIdle	=	"gunmanchronicles/Tank/engineidle.wav";
		this.SoundExit	=	"gunmanchronicles/Tank/powerdown.wav";
		
		CGenericVehicle::Precache();
		
		g_Game.PrecacheModel( "models/mortarshell.mdl" );
		g_Game.PrecacheModel( "models/gunmanchronicles/tank_bboxcollision.mdl" );
		
		PrecacheGenericSound( "gunmanchronicles/Tank/tankx1.wav" );
		PrecacheGenericSound( "gunmanchronicles/weapons/hks1.wav" );
	}
	
	void Spawn()
	{
		self.pev.mins = Vector( -64, -64, -48 );
		self.pev.maxs = Vector(  64,  64,  48 );
		
		CGenericVehicle::Spawn();
		
		self.pev.model = "models/gunmanchronicles/tank_bboxcollision.mdl";
		g_EntityFuncs.SetModel(self, self.pev.model );
		
		InitMdl();
		
		VehicleGroupingInit();
	}
	
	void VehicleGroupingInit()
	{
		m_hBody    = EHandle( GetVehicleChild( "vehicle_tank_body" ) );
		m_hTurret  = EHandle( GetVehicleChild( "vehicle_tank_turret" ) );
		m_hBarrel  = EHandle( GetVehicleChild( "vehicle_tank_barrel" ) );
		
		@CockpitEdict = m_hTurret.GetEntity().edict();
		
		@m_hBody.GetEntity().pev.euser4		= @CockpitEdict;
		@m_hTurret.GetEntity().pev.euser4	= @CockpitEdict;
		@m_hBarrel.GetEntity().pev.euser4	= @CockpitEdict;
		
		m_vecChildOffset[0] = m_hBody.GetEntity().pev.origin - self.pev.origin;
		m_vecChildOffset[1] = m_hTurret.GetEntity().pev.origin - self.pev.origin;
		m_vecChildOffset[2] = m_hBarrel.GetEntity().pev.origin - self.pev.origin;
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( @pActivator );
		
		// if player is null, then check with caller
		if( pPlayer is null )
			@pPlayer = cast<CBasePlayer@>( @pCaller );
		
		// Let's get started...
		if( pPlayer !is null )
		{
			if( ( pPlayer.pev.effects & EF_NODRAW ) == 0 )
				pPlayer.pev.effects |= EF_NODRAW;
				
			DriverEnter( @pPlayer );
		}
		else
			g_Game.AlertMessage(at_error, "vehicle_tank: pPlayer is NULL\n");
		
		BaseClass.Use( pActivator, pCaller, useType, flValue );
	}
	
	void Think()
	{
		self.pev.angles = AnglesMod( self.pev.angles );
		
		if( m_hBody.IsValid() )
		{
			//m_hBody.GetEntity().pev.origin = self.pev.origin + m_vecChildOffset[0];
			
			//m_hBody.GetEntity().pev.velocity = self.pev.velocity;
		}
		
		if( m_hTurret.IsValid() )
		{
			//m_hTurret.GetEntity().pev.origin = self.pev.origin + m_vecChildOffset[1];
		}
		
		if( m_hBarrel.IsValid() )
		{
			//m_hBarrel.GetEntity().pev.origin = self.pev.origin + m_vecChildOffset[2];
		}
		
		SUB_ParentThink();
		SUB_TurretThink();
		
		self.pev.nextthink = g_Engine.time + 0.1f;
		
		SUB_AnimThink();
	}
	
	void SUB_AnimThink()
	{
		float flInterval = self.StudioFrameAdvance( 1.f );
		self.DispatchAnimEvents( flInterval );
		
		if( self.m_fSequenceFinished && !self.m_fSequenceLoops )
		{
			// self.ResetSequenceInfo();
			// hack to avoid reloading model every frame
			self.pev.sequence = ( m_hDriver.IsValid()? TANK_ANIM_IDLE : TANK_ANIM_OFFLINE );
			self.pev.animtime = g_Engine.time;
			self.pev.framerate = 1.0;
			self.m_fSequenceFinished = false;
			self.m_flLastEventCheck = g_Engine.time;
			self.pev.frame = 0;
		}
	}
	
	void SUB_TurretThink()
	{
		if( m_hDriver.IsValid() )
		{
			Vector vecViewAngle;
			vecViewAngle = DriverEntity.pev.v_angle;
			
			// Set turret angles
			if( m_hTurret.IsValid() )
			{
				m_hTurret.GetEntity().pev.angles.y = vecViewAngle.y;
				
				// Set Camera View Position
				SetCameraView( m_hTurret.GetEntity().pev.origin );
				
				// Set model turret angles
				float yaw = Math.AngleMod( vecViewAngle.y - self.pev.angles.y );
				//if( yaw < 0.4705882352941176f ) g_Game.AlertMessage(at_error, "vehicle_tank: yaw is %1\n", yaw);
				
				self.pev.set_controller( 0, uint8( 255 * Math.clamp( 0.001f, 1.f, yaw			/ 120.f ) ) );
				self.pev.set_controller( 1, uint8( 255 * Math.clamp( 0.001f, 1.f, (yaw-120.f)	/ 120.f ) ) );
				self.pev.set_controller( 2, uint8( 255 * Math.clamp( 0.001f, 1.f, (yaw-240.f)	/ 120.f ) ) );
			}
			// Set barrel angles
			if( m_hBarrel.IsValid() )
			{
				float pitch = Math.clamp( -90.f, 17.f, vecViewAngle.x );
				m_hBarrel.GetEntity().pev.angles.x = pitch;
				m_hBarrel.GetEntity().pev.angles.y = vecViewAngle.y;
				
				uint8 controller = 214 + uint8( 41 * Math.clamp( 0.001f, 1.f, pitch / 17.f ) );
				if( pitch < 0.f )
					controller =  214 - uint8( 214 * Math.clamp( 0.001f, 1.f, pitch / -70.f ) );
				
				self.pev.set_controller( 3, controller );
			}
		}
	}
	
	void DriverActionHandle( const int buttons )
	{
		CGenericVehicle::DriverActionHandle( buttons );
		
		if( ( buttons & IN_DUCK ) != 0 )
			DriverTertiaryAttack();
	}
	
	void DriverTurningHandle( const int buttons )
	{
		CGenericVehicle::DriverTurningHandle( buttons );
		
		if( m_hBody.IsValid() )
			m_hBody.GetEntity().pev.angles = self.pev.angles;
	}
	
	// Main cannon
	void DriverPrimaryAttack()
	{
		if( m_flNextPrimaryAttack > g_Engine.time )
			return;
		
		m_flNextPrimaryAttack = g_Engine.time + 0.8f;
		
		self.m_MonsterState = MONSTERSTATE_COMBAT;
		self.pev.sequence = TANK_ANIM_FIRE_CANNON;
		
		Vector vecOrigin, vecAngles;
		self.GetAttachment( TANK_ATTACHMENT_CANNON , vecOrigin, vecAngles );
		vecAngles = vecAngles + m_hBarrel.GetEntity().pev.angles;
		Math.MakeVectors( vecAngles );
		//vecOrigin = vecOrigin + g_Engine.v_forward*3.f; // a bit more forward
		
		//g_EntityFuncs.CreateRPGRocket( vecOrigin, vecAngles, DriverEntity.edict() );
		g_EntityFuncs.ShootMortar( DriverEntity.pev, vecOrigin, g_Engine.v_forward*3300 );
		
		EmitWeaponSound( m_hBarrel.GetEntity().edict(), "gunmanchronicles/Tank/tankx1.wav", VOL_NORM, ATTN_NORM );
		
		g_PlayerFuncs.ScreenShake( vecOrigin, 16.f, 10.0f, 1.f, 500.f );
		//SoundEnt().InsertSound( bits_SOUND_COMBAT, self.pev.origin, 384, 0.3, m_hBarrel.GetEntity() );
	}
	
	// Rocket
	void DriverSecondaryAttack()
	{
		if( m_flNextSecondaryAttack > g_Engine.time )
			return;
		
		m_flNextSecondaryAttack = g_Engine.time + 4.f;
		
		Vector vecOrigin, vecAngles;
		self.GetAttachment( TANK_ATTACHMENT_ROCKET , vecOrigin, vecAngles );
		vecAngles = vecAngles + m_hBarrel.GetEntity().pev.angles;
		Math.MakeVectors( vecAngles );
		vecOrigin = vecOrigin + g_Engine.v_forward*3.f; // a bit more forward
		
		g_EntityFuncs.CreateRPGRocket( vecOrigin, vecAngles, DriverEntity.edict() );
	}
	
	// Machine Gun
	void DriverTertiaryAttack()
	{
		if( m_flNextTertiaryAttack > g_Engine.time )
			return;
		
		m_flNextTertiaryAttack = g_Engine.time + 0.1f;
		
		self.m_MonsterState = MONSTERSTATE_HUNT;
		self.pev.sequence = TANK_ANIM_FIRE_GUNS;
		
		self.pev.iStepLeft = ( self.pev.iStepLeft == 0 ? 1 : 0 );
		
		Vector vecOrigin, vecAngles;
		self.GetAttachment( TANK_ATTACHMENT_BULLET_RIGHT - self.pev.iStepLeft, vecOrigin, vecAngles );	
		
		//g_EntityFuncs.CreateRPGRocket( vecOrigin, ( vecAngles + self.pev.angles ), self.edict() );
		
		Math.MakeVectors( vecAngles + self.pev.angles );
		vecOrigin = vecOrigin + g_Engine.v_forward*3.f; // a bit more forward
		Vector vecDir = g_Engine.v_forward*128 + g_Engine.v_up*Math.RandomFloat(-6,-15) + g_Engine.v_right*Math.RandomFloat(-2,2) ;
		self.FireBullets( 1, vecOrigin, vecDir, VECTOR_CONE_1DEGREES, 2048, BULLET_MONSTER_SAW, 1 );
		
		EmitWeaponSound( self.edict(), "gunmanchronicles/weapons/hks1.wav", VOL_NORM, ATTN_NORM );
		
		//SoundEnt().InsertSound( bits_SOUND_COMBAT, self.pev.origin, 384, 0.3, self );
	}
}

void RegisterEntity_VehicleTank()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "vehicle_tank", "vehicle_tank" );
	
	RegisterEntity_VehicleTankBody();
	RegisterEntity_VehicleTankTurret();
	RegisterEntity_VehicleTankBarrel();
}

