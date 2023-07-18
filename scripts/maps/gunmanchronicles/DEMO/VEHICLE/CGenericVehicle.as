//// euser4 as cockpit handle (exit point)
abstract class CGenericVehicle : ScriptBaseMonsterEntity
{
	EHandle	m_hDriver;
	EHandle	m_hSteer;
	
	Vector	m_vecExitPos;
	
	float	m_flCameraDistance;
	float	m_flCameraMinPitch;
	float	m_flCameraMaxPitch;
	
	float	m_flNextPrimaryAttack;
	float	m_flNextSecondaryAttack;
	float	m_flNextTertiaryAttack;
	
	bool	m_animate;
	
	
	//// --------------------------
	//// --------------------------
	//// CGenericVehicle Method(es)
	//// --------------------------
	//// --------------------------
	
	edict_t@ CockpitEdict
	{
		get const	{ return self.pev.euser4; }
		set			{ @self.pev.euser4 = @value; }
	}
	
	CBasePlayer@ DriverEntity
	{
		get const	{ return cast<CBasePlayer@>( m_hDriver.GetEntity() ); }
		set			{ m_hDriver = EHandle( @value ); }
	}
	
	CBasePlayerWeapon@ SteerEntity
	{
		get const	{ return cast<CBasePlayerWeapon@>( m_hSteer.GetEntity() ); }
		set			{ m_hSteer = EHandle( @value ); }
	}
	
	string SoundEnter
	{
		get const	{ return self.pev.noise; }
		set			{ self.pev.noise = string_t( value );}
	}
	string SoundExit
	{
		get const	{ return self.pev.noise1; }
		set			{ self.pev.noise1 = string_t( value );}
	}
	string SoundIdle
	{
		get const	{ return self.pev.noise2; }
		set			{ self.pev.noise2 = string_t( value );}
	}
	
	// If your vehicle is brush entity, use this instead
	void InitBrush()
	{
		self.pev.solid			= SOLID_BSP;
		self.pev.movetype		= MOVETYPE_PUSH;
	}
	
	// If your vehicle is model entity, use this instead
	void InitMdl( bool setBox = true, uint solid = SOLID_TRIGGER, uint movetype = MOVETYPE_FLYMISSILE )
	{
		self.InitBoneControllers();
		
		if( setBox )
		{
			//self.SetSequenceBox(); // Set Bounding Box, may be bugged; KCM
		}
		
		self.pev.solid			= solid;
		self.pev.movetype		= movetype;
		
		//self.m_flFrameRate		= 100;
		self.ResetSequenceInfo();
		
		self.pev.framerate		= 1.0;
	}
	
	CBaseEntity@ GetVehicleChild( const string &in classname ) 
	{
		CBaseEntity@ pEnt = null;
		
		while( ( @pEnt = g_EntityFuncs.FindEntityByClassname( @pEnt, classname ) ) !is null )
		{
			if( pEnt.pev.team == self.pev.team )
			{
				@pEnt.pev.owner = self.edict();
				pEnt.pev.angles = self.pev.angles;
				break;
			}
		}
		
		return @pEnt;
	}
	
	void SUB_ChildUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
		
		if( pOwner is null )
		{
			g_Game.AlertMessage(at_error, "GenericVehicle: SUB_ChildUse(): OWNER is NULL\n");
			return;
		}
		
		pOwner.Use( pActivator, pCaller, useType, flValue );
	}
	
	void SUB_ParentThink()
	{
		self.pev.nextthink = g_Engine.time + 0.1f;
		
		if( !m_hDriver.IsValid() )
		{
			// nullify driver handle
			m_hDriver = null;
			return;
		}
		
		int buttons = DriverEntity.pev.button;
		
		DriverActionHandle( buttons );
		DriverTurningHandle( buttons );
		DriverMovingHandle( buttons );
	}
	
	void DriverActionHandle( const int buttons )
	{
		if( ( buttons & IN_JUMP ) != 0 )
			DriverExit();
		
		if( ( buttons & IN_ATTACK ) != 0 )
			DriverPrimaryAttack();
		
		if( ( buttons & IN_ATTACK2 ) != 0 )
			DriverSecondaryAttack();
		
		if( ( buttons & IN_ALT1 ) != 0 )
			DriverTertiaryAttack();
	}
	
	void DriverTurningHandle( const int buttons )
	{
		float yawVel    = self.pev.avelocity.y;
		float maxYaw    = self.pev.ideal_yaw;
		float yawSpeed  = self.pev.yaw_speed;
		int   isTurning = 1;
		
		if( ( buttons & IN_MOVELEFT ) != 0 )
		{
			yawVel = Math.clamp(  0.f, maxYaw, yawVel + yawSpeed );
		}
		else if( ( buttons & IN_MOVERIGHT ) != 0 )
		{
			yawVel = Math.clamp( -maxYaw, 0.f, yawVel - yawSpeed );
		}
		else
		{
			isTurning = 0;
			
			if( yawVel > 0.f ) yawVel = Math.clamp( -maxYaw, 0.f, yawVel - yawSpeed );
			else
			if( yawVel < 0.f ) yawVel = Math.clamp(  0.f, maxYaw, yawVel + yawSpeed );
		}
		
		self.pev.bInDuck    = isTurning;
		self.pev.avelocity.y = yawVel;
	}
	
	void DriverMovingHandle( const int buttons )
	{
		//if( !self.pev.FlagBitSet( FL_ONGROUND ) )
		//	return;
		
		Math.MakeVectors( self.pev.angles );
		Vector vecMove = g_Engine.v_forward * self.pev.maxspeed;
	
		if( ( buttons & IN_FORWARD ) != 0 )
			self.pev.velocity = vecMove;
	
		if( ( buttons & IN_BACK ) != 0 )
			self.pev.velocity = -vecMove;
	}
	
	void DriverPrimaryAttack()
	{
	}
	void DriverSecondaryAttack()
	{
	}
	void DriverTertiaryAttack()
	{
	}
	
	void EmitWeaponSound( edict_t@ pEnt, string soundFile, float flVolume = VOL_NORM, float flAttenuation = ATTN_NORM, int iFlags = 0, int iPitch = PITCH_NORM )
	{
		g_SoundSystem.EmitSoundDyn( pEnt, CHAN_WEAPON, soundFile, flVolume, flAttenuation, iFlags, iPitch );
	}
	void EmitStaticSound( edict_t@ pEnt, string soundFile, float flVolume = VOL_NORM, float flAttenuation = ATTN_NORM, int iFlags = 0, int iPitch = PITCH_NORM )
	{
		g_SoundSystem.EmitSoundDyn( pEnt, CHAN_STATIC, soundFile, flVolume, flAttenuation, iFlags, iPitch );
	}
	
	void SetCameraView( const Vector &in vecTarget )
	{
		if( m_hDriver.IsValid() )
		{
			Vector vecStart	= vecTarget, 
			vecEnd			= vecTarget,
			vecViewAngle	= DriverEntity.pev.v_angle;
			
			// clamp pitch
			vecViewAngle.x = Math.clamp( m_flCameraMinPitch, m_flCameraMaxPitch, vecViewAngle.x );
			
			Math.MakeVectors( vecViewAngle );
			Vector vecViewBack = g_Engine.v_forward;

			vecEnd		= vecEnd + -( vecViewBack * m_flCameraDistance );
			vecEnd.z	+= 20.0;
			
			TraceResult tr;
			g_Utility.TraceHull( vecStart, vecEnd, ignore_monsters, human_hull, null, tr );
			float flFraction = tr.flFraction;
			
			// adjust camera place if close to a wall
			if( flFraction != 1.0 )
			{
				//g_Game.AlertMessage(at_error, "vehicle_tank: flFraction is %1\n",flFraction);
				
				flFraction *= m_flCameraDistance;
				vecEnd = vecStart + -( vecViewBack * flFraction );
			}
			
			g_EntityFuncs.SetOrigin( DriverEntity, vecEnd );
		}
	}
	
	void DriverEnter( CBasePlayer@ pPlayer )
	{
		if( DriverEntity !is null )
		{
			g_Game.AlertMessage(at_error, "GenericVehicle: DriverEnter(): current driver is NOT NULL\n");
			return;
		}
		
		if( pPlayer is null || !pPlayer.IsAlive() )
		{
			g_Game.AlertMessage(at_error, "GenericVehicle: DriverEnter(): player is NOT VALID\n");
			return;
		}
		
		CBasePlayerWeapon@ pActiveItem = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );
		if( pActiveItem !is null && pActiveItem.m_bExclusiveHold )
		{
			g_Game.AlertMessage(at_error, "GenericVehicle: DriverEnter(): player is CARRYING EXCLUSIVE HOLD\n");
			
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Can't enter with unswitchable weapon.");
			
			return;
		}
		
		// Assign driver handle
		@DriverEntity = @pPlayer;
		entvars_t@ pevPlayer = @pPlayer.pev;
		
		// Driving flag
		pevPlayer.flags			|= FL_IMMUNE_LAVA;
		
		// Edict flags
		if( ( pPlayer.pev.effects & EF_NODRAW ) == 0 )
			pPlayer.pev.effects |= EF_NODRAW;
			
		if( !pevPlayer.FlagBitSet( FL_GODMODE ) )
			pevPlayer.flags		|= FL_GODMODE;
		
		if( !pevPlayer.FlagBitSet( FL_NOTARGET ) )
			pevPlayer.flags		|= FL_NOTARGET;
		
		if( !pevPlayer.FlagBitSet( FL_SPECTATOR ) )
			pevPlayer.flags		|= FL_SPECTATOR;	
		
		if( !pevPlayer.FlagBitSet( FL_NOWEAPONS ) )
			pevPlayer.flags		|= FL_NOWEAPONS;	
		
		// No-Clipping
		pevPlayer.solid			= SOLID_NOT;
		pevPlayer.movetype		= MOVETYPE_NOCLIP;
		pevPlayer.maxspeed		= 1;
		
		// Give vehicle steer "weapon"
		DriverEntity.GiveNamedItem( "weapon_vehicledriving" );
		
		@SteerEntity = cast<CBasePlayerWeapon@>( DriverEntity.HasNamedPlayerItem( "weapon_vehicledriving" ) );
		if( SteerEntity !is null )
		{
			pPlayer.SelectItem( "weapon_vehicledriving" );
		}
		
		// Disable Player Movement Control
		//pPlayer.EnableControl( false );
		
		// Third-person view
		pPlayer.SetViewMode( ViewMode_ThirdPerson );
		
		// Start thinking!
		self.pev.nextthink = g_Engine.time + 0.1f;
		
		// Emit Sound
		EmitWeaponSound( self.edict(), SoundEnter );
		EmitStaticSound( self.edict(), SoundIdle );
	}
	
	void DriverExit()
	{
		self.pev.velocity = g_vecZero;
		
		CBasePlayer@ pPlayer = DriverEntity;
		
		if( pPlayer is null )
		{
			g_Game.AlertMessage(at_error, "GenericVehicle: DriverExit(): Player is NULL\n");
			return;
		}
		
		// Nullify driver handle
		m_hDriver = null;
		
		// Remove driving flag
		pPlayer.pev.flags		&= ~FL_IMMUNE_LAVA;
		
		// Edicts flag
		if( ( pPlayer.pev.effects & EF_NODRAW ) != 0 )
			pPlayer.pev.effects &= ~EF_NODRAW;
		
		if( pPlayer.pev.FlagBitSet( FL_GODMODE ) )
			pPlayer.pev.flags &= ~FL_GODMODE;
		
		if( pPlayer.pev.FlagBitSet( FL_NOTARGET ) )
			pPlayer.pev.flags &= ~FL_NOTARGET;
		
		if( pPlayer.pev.FlagBitSet( FL_SPECTATOR ) )
			pPlayer.pev.flags	&= ~FL_SPECTATOR;	
		
		if( pPlayer.pev.FlagBitSet( FL_NOWEAPONS ) )
			pPlayer.pev.flags	&= ~FL_NOWEAPONS;	
		
		// Normal solidity
		pPlayer.pev.maxspeed	= 0;
		pPlayer.pev.solid		= SOLID_BBOX;
		pPlayer.pev.movetype	= MOVETYPE_WALK;
		
		// Remove vehicle steer "weapon"
		if( pPlayer !is null && SteerEntity !is null )
		{
			//g_Game.AlertMessage(at_error, "SteerEntity SteerEntity SteerEntity\n");
			
			SteerEntity.DropItem(); // Changed from to DropItem; KCM
			//m_hSteer.DropItem();
			pPlayer.SetItemPickupTimes( g_Engine.time );
			m_hSteer = null;
		}
		
		// Enable Player Movement Control
		//pPlayer.EnableControl( true );
		
		// First-person view
		pPlayer.SetViewMode( ViewMode_FirstPerson );
		
		// Stop thinking!
		//self.pev.nextthink = g_Engine.time;
		
		// If this vehicle has cockpit, set driver origin to exit point
		CBaseEntity@ pCockpit = g_EntityFuncs.Instance( CockpitEdict );
		if( pCockpit !is null )
		{
			Vector vecOrigin	=	pCockpit.pev.origin + m_vecExitPos;
			pPlayer.pev.origin	=	vecOrigin;
		}
		
		// Emit Sound
		EmitStaticSound( self.edict(), SoundExit );
	}
	
	//// --------------------
	//// --------------------
	//// BaseClass Method(es)
	//// --------------------
	//// --------------------
	int ObjectCaps() { return (BaseClass.ObjectCaps() & ~FCAP_ACROSS_TRANSITION) | FCAP_IMPULSE_USE; }
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "vehicle_id" )
		{
			self.pev.team = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		if( !SoundEnter.IsEmpty() ) PrecacheGenericSound( SoundEnter );
		if( !SoundIdle.IsEmpty() ) PrecacheGenericSound( SoundIdle );
		if( !SoundExit.IsEmpty() ) PrecacheGenericSound( SoundExit );
	}
	
	int Classify()
	{
		return CLASS_MACHINE;
	}
	
	void Spawn()
	{
		Precache();
		
		// cached first old data
		self.pev.oldorigin		= self.pev.origin;
		self.pev.vuser4			= self.pev.angles;
		
		g_EntityFuncs.SetModel(self, self.pev.model );
		
		g_EntityFuncs.SetSize(self.pev, self.pev.mins, self.pev.maxs);
		
		g_EntityFuncs.SetOrigin(self, self.pev.origin);
		
		self.pev.view_ofs		= VEC_VIEW;// position of the eyes relative to monster's origin.
		self.m_flFieldOfView	= 0.5;// indicates the width of this monster's forward view cone ( as a dotproduct result )
		self.m_MonsterState		= MONSTERSTATE_NONE;
		
		self.m_afCapability		= bits_CAP_DOORS_GROUP;
		
		if( string( self.pev.netname ).IsEmpty() )
			self.pev.netname	= "Drivable Vehicle";
		
		if( string( self.m_FormattedName ).IsEmpty() )
			self.m_FormattedName	=	self.pev.netname;

		self.pev.rendermode = 0;
		self.pev.effects    = 0;
		
		if( self.pev.ideal_yaw == 0.f ) self.pev.ideal_yaw = 100.f;
		if( self.pev.yaw_speed == 0.f ) self.pev.yaw_speed = 15.f;
		if( self.pev.maxspeed  == 0.f ) self.pev.maxspeed  = 200.f;
	}
	
	void TraceAttack(entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in traceResult, int bitsDamageType)
	{
		BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, traceResult, bitsDamageType );
		
		if( self.pev.solid != SOLID_BSP && flDamage > 0.0f )
			g_Utility.Ricochet( traceResult.vecEndPos,1.0f );
	}
}

