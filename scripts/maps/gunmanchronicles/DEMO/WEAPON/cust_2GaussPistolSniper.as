#include "GC_ScriptBasePlayerWeaponEntity"

#include "weapon_gausspistol"

enum gausssniper_anim_e
{
	GAUSSSNIPER_IDLE			= 7,
	GAUSSSNIPER_IDLE_RESTLESS,
	GAUSSSNIPER_IDLE_FIDGET,
	GAUSSSNIPER_SNIPER_SHOT,
	GAUSSSNIPER_DRAW,
	GAUSSSNIPER_HOLSTER
};

enum gausssniper_zoomstate { GAUSSSNIPER_ZOOMSTATE_NO = 0, GAUSSSNIPER_ZOOMSTATE_START, GAUSSSNIPER_ZOOMSTATE_ZOOMING, GAUSSSNIPER_ZOOMSTATE_MAXED };

class cust_2GaussPistolSniper : GC_BasePlayerWeapon, LaserEffect, WallHitEffect
{
	private string					m_szZoomedSound			= "gunmanchronicles/weapons/sniperzoom.wav";
	private string					m_szNozoomedSound		= "gunmanchronicles/weapons/sniperunzoom.wav";
	private string					m_szZoomingSound		= "gunmanchronicles/weapons/gsnipe_zoom.wav";
	
	private string					m_szBangZoomSound		= "gunmanchronicles/weapons/gsnipe_bang.wav";
	private string					m_szBangNozoomSound		= "gunmanchronicles/weapons/gsnipe_bang_nozoom.wav";
	
	private float					m_flZoomingDelay;
	
	private gausssniper_zoomstate	m_iZoomState			= GAUSSSNIPER_ZOOMSTATE_NO;
	
	private bool					m_bSwitchToSniper		= false;
	private bool					m_bSwitchToPistol		= false;
	private uint					m_uiGaussMode;
	
	private bool					m_bHasFormer			= false;

	// Constructor
	cust_2GaussPistolSniper()
	{
		this.WorldModel		=	"models/gunmanchronicles/w_snipercase.mdl";
		this.PlayerModel	=	"models/gunmanchronicles/p_357.mdl";
		this.ViewModel		=	"models/gunmanchronicles/v_guasspistol.mdl";
		
		//this.m_flDeployDelay	=	1.0f;
		
		this.m_iPrimaryDamage			=	40;
		
		// Start Zoom delay
		this.m_flPrimaryAttackDelay		=	0.407f;
		
		// Zooming delay
		this.m_flZoomingDelay			=	0.005f;
		
		// NoZoom Aftershoot delay
		this.m_flSecondaryAttackDelay	=	0.6f;
		
		// Zoom Aftershoot delay
		this.m_flTertiaryAttackDelay	=	0.6f;
		
		BuildMenu();
	}
	
	void BuildMenu()
	{
		@m_cmMenu = @CustomMenu();
		
		// Fire Mode
		string title = "Fire Mode";
		m_cmMenu.menu_create(  title );
		m_cmMenu.menu_additem( title, "Pulse" );
		m_cmMenu.menu_additem( title, "Charge" );
		m_cmMenu.menu_additem( title, "Rapid" );
		m_cmMenu.menu_additem( title, "Sniper" );
	}
	
	// return false when player doesnt have gauss pistol
	bool AddToPlayer(CBasePlayer@ pPlayer)
	{
		if( pPlayer !is null )
		{
			CBaseEntity@ pEnt = pPlayer.HasNamedPlayerItem( "weapon_gausspistol" );
			
			if( pEnt is null )
			{
				if( m_bHasFormer && self !is null )
				{
					g_EntityFuncs.Remove( self );
				}
				return false;
			}
			
			m_bSwitchToSniper = true;
			self.pev.nextthink = WeaponTimeBase() + 0.5f;
		}
		
		m_bHasFormer = true;
		
		return GC_BasePlayerWeapon::AddToPlayer( @pPlayer );;
	}
	
	void ChangeCustomMenuSelection( uint titleId, uint itemId = Math.UINT32_MAX )
	{
		GC_BasePlayerWeapon::ChangeCustomMenuSelection( titleId, itemId );
		
		// my bad, hehe :v
		if( itemId != Math.UINT32_MAX )
		{
			if( itemId != GAUSSPISTOL_MODE_SNIPER )
			{
				//g_Game.AlertMessage( at_console, "yep\n", titleId, itemId );
				
				m_bSwitchToPistol = true;
				m_uiGaussMode  = m_cmMenu.SelectedItem;
			}
			else
			{
				//g_Game.AlertMessage( at_console, "nope\n", titleId, itemId );
				
				m_bSwitchToPistol = false;
			}
		}
	}
	
	void CloseCustomMenu()
	{
		GC_BasePlayerWeapon::CloseCustomMenu();	
		
		if( m_bSwitchToPistol ) SwitchToPistol();
	}
	
	bool GetItemInfo(ItemInfo& out info)
	{
		info.iMaxAmmo1	= GAUSSPISTOL_DEFAULT_MAXCARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot		= 0;	//dont draw in hud
		info.iPosition	= 0;	//dont draw in hud
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname ); //self.m_iId;
		info.iFlags		= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
		info.iWeight	= GLOCK_WEIGHT;
		
		return true;
	}
	
	void Precache()
	{
		GC_BasePlayerWeapon::Precache();
		
		// Get some extra files
		PrecacheLaserEffect();
		PrecacheWallHitEffect();
		PrecacheWeaponHudInfo( "gunmanchronicles/cust_2GaussPistolSniper.txt" );
		PrecacheWeaponHudInfo( "gunmanchronicles/scopezoom.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/crosshairs.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud2.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud5.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud7.spr" );
		PrecacheGenericSound( m_szZoomedSound );
		PrecacheGenericSound( m_szNozoomedSound );
		PrecacheGenericSound( m_szZoomingSound );
		PrecacheGenericSound( m_szBangZoomSound );
		PrecacheGenericSound( m_szBangNozoomSound );
	}
	
	void Spawn()
	{
		GC_BasePlayerWeapon::Spawn();
		
		// sniper extension
		self.pev.body = 1;
		
		// reset mode to sniper
		ChangeCustomMenuSelection( 0, GAUSSPISTOL_MODE_SNIPER );
	}
	
	void Think()
	{
		BaseClass.Think();
		
		if( self.m_hPlayer.IsValid() )
		{
			if( m_bSwitchToPistol )
			{
				m_bSwitchToPistol = false;
				
				CBaseEntity@ pEnt = m_pPlayer.HasNamedPlayerItem( "weapon_gausspistol" );
					
				if( pEnt !is null )
				{
					g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "setTitleValue", "0 " + m_uiGaussMode + " 0" );
					m_pPlayer.SelectItem( "weapon_gausspistol" );
				}
			}
			
			if( m_bSwitchToSniper )
			{
				m_bSwitchToSniper = false;
				
				CBaseEntity@ pEnt = cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ).HasNamedPlayerItem( "weapon_gausspistol" );
				if( pEnt !is null ) g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "SwitchToSniper", "0" );
			}
		}
	}
	
	bool Deploy()
	{
		// reset mode to sniper
		ChangeCustomMenuSelection( 0, GAUSSPISTOL_MODE_SNIPER );
		
		return DefaultDeploy( GAUSSSNIPER_DRAW, "sniper" , 0, self.pev.body );
	}
	
	void Holster( int skipLocal /*= 0*/ )
	{
		m_bSwitchToPistol = false;
		
		// reset FoV
		ResetZoom();
		
		self.SendWeaponAnim( GAUSSSNIPER_HOLSTER, skipLocal, self.pev.body );
		
		GC_BasePlayerWeapon::Holster( skipLocal );
	}
	
	void WeaponIdle()
	{
		bool drawCircle = false;
		
		// Holding an attack
		if( m_iZoomState != GAUSSSNIPER_ZOOMSTATE_NO )
		{
			int currentClip = GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO );
			
			// handle attack here...
			switch( m_iZoomState )
			{
				
				case GAUSSSNIPER_ZOOMSTATE_START:
				{
					currentClip -= 8; // clip drecrement
					
					// release the lowest rail damage
					m_iSecondaryDamage = m_iPrimaryDamage;
					
					// Player IS HOLDING attack button? ignore this idle
					if( m_pPlayer.pev.button & IN_ATTACK != 0 )
						return;
					
					this.m_szWallHitSound = m_szBangNozoomSound;
					
					break;
				}
				
				case GAUSSSNIPER_ZOOMSTATE_ZOOMING:
				{
					drawCircle = true;
					currentClip -= 20; // clip drecrement
					m_iSecondaryDamage = m_iPrimaryDamage + int( ( 40 - GetFOV() ) * 4.433333333333333 ); // dont ask me where i got this numbers :x
					this.m_szWallHitSound = m_szBangZoomSound;
					break;
				}
				case GAUSSSNIPER_ZOOMSTATE_MAXED:
				{
					drawCircle = true;
					currentClip -= 20; // clip drecrement
					m_iSecondaryDamage = 133;
					this.m_szWallHitSound = m_szBangZoomSound;
					break;
				}
				
			}
			
			// // Player is holding jump button OR not enough clip?
			if( m_pPlayer.pev.button & IN_JUMP != 0 || SetAmmoAmount( AMMO_TYPE_PRIMARYAMMO, currentClip ) == false )
			{
				ResetZoom();
				self.PlayEmptySound();
				NextAttack( m_flEmptyDelay );
				NextIdle(   m_flEmptyDelay );
				return;
			}
			
			// ATTACK!!!
			FireRailGun( drawCircle );
			
			// quick reset
			if( m_iZoomState != GAUSSSNIPER_ZOOMSTATE_MAXED )
			{
				//g_Game.AlertMessage( at_console, "QUICK ZOOM!\n" );
				
				if( m_iZoomState == GAUSSSNIPER_ZOOMSTATE_START )
				{
					PlayWeaponSound( m_szNozoomedSound );
					// prepare for next attack!
					NextAttack( m_flSecondaryAttackDelay );
				}
				else
				{
					PlayWeaponSound( m_szZoomedSound );
					// prepare for next attack!
					NextAttack( m_flTertiaryAttackDelay );
				}
				
				// reset zoom
				ResetZoom();
				
				// reset gait sequence
				UpdatePlayerGaitSequence();
				
				// default idle
				NextIdle( g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 ) );
			}
			// maxed zoom state reset after delay
			else
			{
				//g_Game.AlertMessage( at_console, "ACCURATE ZOOM!\n" );
				PlayWeaponSound( m_szZoomedSound );
				
				m_iZoomState = GAUSSSNIPER_ZOOMSTATE_NO;
				
				// prepare for next attack!
				NextAttack( m_flTertiaryAttackDelay );
				
				// reset zoom idle
				NextIdle( m_flTertiaryAttackDelay );
			}
			
			return;
		}
		else if( self.m_flTimeWeaponIdle <= WeaponTimeBase() )
		{
			//g_Game.AlertMessage( at_console, "RESET ZOOM! %1\n",  self.m_flTimeWeaponIdle );
			
			// reset zoom
			ResetZoom();
			
			// reset gait sequence
			UpdatePlayerGaitSequence();
		}
		
		// Default Idle handled here...
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		// only idle if the slid isn't back
		int iAnim;
		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0, 1.0 );
		float flIdle = 0.1f;

		if( flRand <= 0.3 + 0 * 0.75 )
		{
			iAnim	= GAUSSSNIPER_IDLE;
			flIdle	= 30.0 / 10.0;
		}
		else if( flRand <= 0.6 + 0 * 0.875 )
		{
			iAnim	= GAUSSSNIPER_IDLE_FIDGET;
			flIdle	= 30.0 / 10.0;
		}
		else
		{
			iAnim	= GAUSSSNIPER_IDLE_RESTLESS;
			flIdle	= 30.0 / 10.0;
		}
		
		DefaultWeaponIdle( iAnim, flIdle );
	}
	
	void PrimaryAttack()
	{
		if( IsMenuOpened() )
		{
			CloseCustomMenu();
			NextAttack( m_flMenuToggleDelay );
			return;
		}
		
		int currentClip = GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO );
		
		// don't fire underwater (completely submerged) or when clip is empty
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || currentClip <= 0 )
		{
			self.PlayEmptySound();
			ResetZoom();
			NextAttack( m_flEmptyDelay );
			return;
		}
		
		//g_Game.AlertMessage( at_console, "GetFOV %1\n", GetFOV() );
		
		// Player is holding jump button
		if( m_pPlayer.pev.button & IN_JUMP != 0 )
		{
			ResetZoom();
			
			NextAttack( 0.1 );
			
			return;
		}
		
		switch( m_iZoomState )
		{
			case GAUSSSNIPER_ZOOMSTATE_NO:
			{
				m_iZoomState = GAUSSSNIPER_ZOOMSTATE_START;
				m_szWallHitSound = m_szBangNozoomSound;
				
				PlayWeaponSound( m_szZoomingSound );
				
				SetFOV( 40 );
				
				UpdatePlayerGaitSequence();
				
				NextAttack( m_flPrimaryAttackDelay );
				NextIdle( 0.1f );
				
				return;
			}
			case GAUSSSNIPER_ZOOMSTATE_START:
			case GAUSSSNIPER_ZOOMSTATE_ZOOMING:
			{
				SetFOV( Math.clamp( 10, 40, GetFOV() - 1 ) );
				if( GetFOV() <= 10 )
				{
					m_iZoomState = GAUSSSNIPER_ZOOMSTATE_MAXED;
				}
				else if( GetFOV() >= 32 )
				{
					m_iZoomState = GAUSSSNIPER_ZOOMSTATE_START;
				}
				else
				{
					m_iZoomState = GAUSSSNIPER_ZOOMSTATE_ZOOMING;
				}
				
				m_szWallHitSound = m_szBangZoomSound;
				
				UpdatePlayerGaitSequence();
				
				NextAttack( m_flZoomingDelay );
				NextIdle( 0.1f );
				
				return;
			}
			case GAUSSSNIPER_ZOOMSTATE_MAXED:
			{
				UpdatePlayerGaitSequence();
				
				NextAttack( m_flZoomingDelay );
				NextIdle( 0.1f );
				
				return;
			}
		}
	}
	
	void FireRailGun( bool drawCircle = false )
	{
		m_pPlayer.m_iWeaponVolume	= 	LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash	=	BRIGHT_GUN_FLASH;
		m_pPlayer.pev.effects		|=	EF_MUZZLEFLASH;
		self.pev.effects			|=	EF_MUZZLEFLASH;
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim(    GAUSSSNIPER_SNIPER_SHOT, 0, self.pev.body );
		
		TraceResult tr;
		Vector vecSrc			=	m_pPlayer.GetGunPosition() + g_Engine.v_forward * 8 + g_Engine.v_right * 0.7 + g_Engine.v_up * -0.5; //perfectionist!!
		Vector vecDirShooting	=	m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
		Vector vecRight			=	g_Engine.v_right;
		Vector vecUp			=	g_Engine.v_up;
		Vector vecSpread		=	g_vecZero;
		
		//Use player's random seed.
		// get circular gaussian spread
		uint iShot = 1, shared_rand = m_pPlayer.random_seed;
		float 
		x = g_PlayerFuncs.SharedRandomFloat( shared_rand + iShot,         -0.5, 0.5 )	+ g_PlayerFuncs.SharedRandomFloat( shared_rand + ( 1 + iShot ), -0.5, 0.5 ),
		y = g_PlayerFuncs.SharedRandomFloat( shared_rand + ( 2 + iShot ), -0.5, 0.5 )	+ g_PlayerFuncs.SharedRandomFloat( shared_rand + ( 3 + iShot ), -0.5, 0.5 ),
		z = x * x + y * y;
		
		Vector vecDir = vecDirShooting +
						x * vecSpread.x * vecRight +
						y * vecSpread.y * vecUp;
		Vector vecEnd = vecSrc + vecDir * 8192;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		// do damage, paint decals
		if( tr.flFraction != 1.0 )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( pEntity !is null && self.m_hPlayer.IsValid() && pEntity.pev.takedamage != DAMAGE_NO )
			{
				g_WeaponFuncs.ClearMultiDamage();
				pEntity.TraceAttack( self.m_hPlayer.GetEntity().pev, m_iSecondaryDamage, vecDir, tr, DMG_ENERGYBEAM | DMG_NEVERGIB );
				g_WeaponFuncs.ApplyMultiDamage( self.pev, self.m_hPlayer.GetEntity().pev );
			}

			DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
			
			if( drawCircle )
				CreateWallHitEffectBig( tr.vecEndPos );
			else
				CreateWallHitEffect( tr.vecEndPos );
		}
		
		if( drawCircle )
			DrawSinusShapeLaser( vecSrc, tr.vecEndPos, 0.8 );
		
		CreateTempEnt_BeamPoints( vecSrc, tr.vecEndPos, m_szLaserBeam, 8, 3 );
	}
	
	void ResetZoom()
	{
		// reset zoom
		m_iZoomState = GAUSSSNIPER_ZOOMSTATE_NO;
		SetFOV( 0 );
	}
	
	void UpdatePlayerGaitSequence()
	{
		m_pPlayer.m_szAnimExtension = ( m_iZoomState == GAUSSSNIPER_ZOOMSTATE_NO ? "sniper" : "sniperscope" );
	}
	
	bool SwitchToPistol()
	{
		if( self.m_hPlayer.IsValid() && m_cmMenu.menu_getvalue( 0 ) != GAUSSPISTOL_MODE_SNIPER )
		{
			CBaseEntity@ pEnt = m_pPlayer.HasNamedPlayerItem( "weapon_gausspistol" );
				
			if( pEnt !is null )
			{
				m_pPlayer.m_flNextAttack = WeaponTimeBase() + 1337.0f;
				NextAttack( 1337.0f );
				NextIdle(   1337.0f );
				self.SendWeaponAnim( GAUSSSNIPER_HOLSTER, 0, self.pev.body );
				
				self.pev.nextthink = WeaponTimeBase() + 2.0f;
				
				return true;
			}
		}
		
		return false;
	}
};

void RegisterEntity_WeaponGaussSniper()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cust_2GaussPistolSniper", "cust_2GaussPistolSniper" );
	g_ItemRegistry.RegisterWeapon( "cust_2GaussPistolSniper", "gunmanchronicles", "uranium" );
};
