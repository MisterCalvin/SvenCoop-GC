#include "GC_ScriptBasePlayerWeaponEntity"

#include "../AMMO/ammo_gcgaussclip"
#include "../PROJECTILE/gauss_charged"
#include "../PROJECTILE/gauss_ball"

enum gausspistol_anim_e
{
	GAUSSPISTOL_IDLE			= 0,
	GAUSSPISTOL_IDLE_RESTLESS,
	GAUSSPISTOL_SINGLE_SHOT,
	GAUSSPISTOL_RAPID_FIRE,
	GAUSSPISTOL_CHARGE_FIRE,
	GAUSSPISTOL_DRAW,
	GAUSSPISTOL_HOLSTER
};

enum gausspistol_firemode_e
{
	GAUSSPISTOL_MODE_PULSE		= 0,
	GAUSSPISTOL_MODE_CHARGE,
	GAUSSPISTOL_MODE_RAPID,
	GAUSSPISTOL_MODE_SNIPER,
};

const int GAUSSPISTOL_DEFAULT_GIVE		=	20;
const int GAUSSPISTOL_DEFAULT_MAXCARRY	=	GC_URANIUM_MAXCARRY;

class weapon_gausspistol : GC_BasePlayerWeapon, LaserEffect, WallHitEffect
{
	private string	m_szPulseSound			= "gunmanchronicles/weapons/gauss_fire1.wav";
	private string	m_szRapidSound			= "gunmanchronicles/weapons/gauss_fire4.wav";
	private string	m_szChargeSound			= "gunmanchronicles/weapons/gauss_fire2.wav";
	private string	m_szChargeReloadSound	= "gunmanchronicles/weapons/gauss_charge.wav";

	private int		m_iShotCounter;
	
	private float	m_flPulseExhaustedDelay;
	private float	m_flChargeAttackDelay;
	private float	m_flRapidAttackDelay;
	
	private bool	m_bSwitchToSniper			= false;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "SwitchToSniper" )
		{
			if( self.m_hPlayer.IsValid() && m_pPlayer.m_hActiveItem.GetEntity().edict() is self.edict() )
			{
				ChangeCustomMenuSelection( 0, GAUSSPISTOL_MODE_SNIPER );
				CloseCustomMenu();
			}
			
			return true;
		}
		else
			return GC_BasePlayerWeapon::KeyValue( szKey, szValue );
	}
	
	// Constructor
	weapon_gausspistol()
	{
		this.WorldModel		=	"models/gunmanchronicles/w_gauss.mdl";
		this.PlayerModel	=	"models/gunmanchronicles/p_357.mdl";
		this.ViewModel		=	"models/gunmanchronicles/v_guasspistol.mdl";
		
		//this.m_flDeployDelay	=	1.0f;
		
		this.m_iPrimaryDamage			=	8;
		this.m_iSecondaryDamage			=	50;
		this.m_iTertiaryDamage			=	10;
		
		this.m_flPulseExhaustedDelay	=	0.5f;
		this.m_flPrimaryAttackDelay		=	0.12f;
		
		this.m_flChargeAttackDelay		=	1.5f;
		this.m_flRapidAttackDelay		=	0.1f;
		
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
	
	void ChangeCustomMenuSelection( uint titleId, uint itemId = Math.UINT32_MAX )
	{
		if( itemId == GAUSSPISTOL_MODE_SNIPER )
		{
			if( self.m_hPlayer.IsValid() == false )
				return;
			
			if( m_pPlayer.HasNamedPlayerItem( "cust_2GaussPistolSniper" ) !is null )
			{
				m_bSwitchToSniper = true;
			}
			// no sniper kit, move next item...
			else
			{
				m_bSwitchToSniper = false;
				itemId += 1;
			}
		}
		
		GC_BasePlayerWeapon::ChangeCustomMenuSelection( titleId, itemId );
	}
	
	void CloseCustomMenu()
	{
		GC_BasePlayerWeapon::CloseCustomMenu();
		
		if( m_bSwitchToSniper ) SwitchToSniper();
	}
	
	bool GetItemInfo(ItemInfo& out info)
	{
		info.iMaxAmmo1	= GAUSSPISTOL_DEFAULT_MAXCARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot		= 1;
		info.iPosition	= 4;
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
		PrecacheWeaponHudInfo( "gunmanchronicles/weapon_gausspistol.txt" );
		PrecacheWeaponHudInfo( "gunmanchronicles/crosshairs.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud2.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud5.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud7.spr" );
		g_Game.PrecacheModel( self, "models/gunmanchronicles/w_gausst.mdl" );
		PrecacheGenericSound( m_szPulseSound );
		PrecacheGenericSound( m_szRapidSound );
		PrecacheGenericSound( m_szChargeSound );
		PrecacheGenericSound( m_szChargeReloadSound );
	}
	
	void Spawn()
	{
		GC_BasePlayerWeapon::Spawn();
		
		self.m_iDefaultAmmo	=	GAUSSPISTOL_DEFAULT_GIVE;
	}
	
	void Think()
	{
		BaseClass.Think();
		
		//reset shot counter
		m_iShotCounter = 0;
		
		if( self.m_hPlayer.IsValid() && m_bSwitchToSniper )
		{
			m_bSwitchToSniper = false;
			ChangeCustomMenuSelection( 0 , GAUSSPISTOL_MODE_SNIPER );
			m_pPlayer.SelectItem( "cust_2GaussPistolSniper" );
		}
	}
	
	bool Deploy()
	{
		if( CanSwitchToSniper() )
		{
			m_pPlayer.SelectItem( "cust_2GaussPistolSniper" );
			return false;
		}
		
		return DefaultDeploy( GAUSSPISTOL_DRAW, "onehanded" , 0 , self.pev.body );
	}
	
	void Holster( int skipLocal /*= 0*/ )
	{
		m_bSwitchToSniper = false;
		
		self.SendWeaponAnim( GAUSSPISTOL_HOLSTER, skipLocal, self.pev.body );
		
		GC_BasePlayerWeapon::Holster( skipLocal );
	}
	
	void WeaponIdle()
	{
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		// only idle if the slid isn't back
		int iAnim;
		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0, 1.0 );
		float flIdle = 0.1f;

		if( flRand <= 0.3 + 0 * 0.75 )
		{
			iAnim	= GAUSSPISTOL_IDLE;
			flIdle	= 30.0 / 8.0;
		}
		else if( flRand <= 0.6 + 0 * 0.875 )
		{
			iAnim	= GAUSSPISTOL_IDLE;
			flIdle	= 30.0 / 8.0;
		}
		else
		{
			iAnim	= GAUSSPISTOL_IDLE_RESTLESS;
			flIdle	= 30.0 / 10.0;
		}
		
		DefaultWeaponIdle( iAnim, flIdle );
	}
	
	// use no ricochet
	void DrawDecal( TraceResult &in pTrace, Bullet iBulletType, bool noRicochet = false )
	{
		GC_BasePlayerWeapon::DrawDecal( pTrace, iBulletType, true );
		
		// WallPuff for BSP object only!
		if( pTrace.pHit.vars.solid == SOLID_BSP || pTrace.pHit.vars.movetype == MOVETYPE_PUSHSTEP )
		{
			// Pull out of the wall a bit
			if( pTrace.flFraction != 1.0 )
			{
				pTrace.vecEndPos = pTrace.vecEndPos.opAdd( pTrace.vecPlaneNormal );
			}
			
			CreateWallHitEffect( pTrace.vecEndPos );
			CreateWallHitSound( pTrace.vecEndPos );
		}
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
			NextAttack( m_flEmptyDelay );
			return;
		}
		
		switch( m_cmMenu.menu_getvalue( 0 ) )
		{
			case GAUSSPISTOL_MODE_SNIPER:
			{
				// reset to pulse
				ChangeCustomMenuSelection( 0 , GAUSSPISTOL_MODE_PULSE );
				NextAttack( 0.001f );
				break;
			}
			
			case GAUSSPISTOL_MODE_PULSE:
				FirePulseMode();
				break;
			case GAUSSPISTOL_MODE_CHARGE:
				FireChargeMode();
				break;
			case GAUSSPISTOL_MODE_RAPID:
				FireRapidMode();
				break;
		}
	}
	
	void FirePulseMode()
	{
		int currentClip = GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO );
		
		// not enough clip?
		if( SetAmmoAmount( AMMO_TYPE_PRIMARYAMMO, --currentClip ) == false )
		{
			self.PlayEmptySound();
			NextAttack( m_flEmptyDelay );
			return;
		}
		
		m_pPlayer.pev.effects		|=	EF_MUZZLEFLASH;
		self.pev.effects			|=	EF_MUZZLEFLASH;
		m_pPlayer.m_iWeaponVolume	= 	GAUSS_PRIMARY_FIRE_VOLUME;
		m_pPlayer.m_iWeaponFlash	=	0; //DIM_GUN_FLASH;
		
		++m_iShotCounter;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim(    GAUSSPISTOL_SINGLE_SHOT );
		
		float	flMaxDistance	=	8192;
		Vector	vecSrc			=	m_pPlayer.GetGunPosition();
		Vector	vecDirShooting	=	m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
		
		// pulse mode is most accurate, so use zero vector
		FireBullets( 1, vecSrc, vecDirShooting, g_vecZero, flMaxDistance, BULLET_PLAYER_CUSTOMDAMAGE, 1, m_iPrimaryDamage, m_pPlayer.pev );
		
		CreateTempEnt_BeamEntPoint( m_pPlayer, m_pLastAttackTr.vecEndPos, m_szLaserBeam );
		
		// light faster than sound!
		switch( Math.RandomLong(0,1) )
		{
			case 0 : PlayWeaponSound( m_szPulseSound ); break;
			case 1 : PlayWeaponSound( m_szRapidSound ); break;
		}
		
		V_PunchAxis( 0, -2.0 );
		
		if( m_iShotCounter < 3 )
			// not in 3-burst
			NextAttack( m_flPrimaryAttackDelay );
		else
			// exhausted, wait for next attack
			NextAttack( m_flPulseExhaustedDelay );
		
		//g_Game.AlertMessage( at_console, "m_iShotCounter = %1\n", m_iShotCounter );
		
		// reset attack counter on Think()
		self.pev.nextthink = WeaponTimeBase() + m_flPrimaryAttackDelay;
		
		NextIdle( g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 ) );
	}
	
	void FireChargeMode()
	{
		int currentClip = GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO );
		
		// not enough clip?
		if( SetAmmoAmount( AMMO_TYPE_PRIMARYAMMO, currentClip - 10 ) == false )
		{
			self.PlayEmptySound();
			NextAttack( m_flEmptyDelay );
			return;
		}
		
		m_pPlayer.pev.effects		|=	EF_MUZZLEFLASH;
		self.pev.effects			|=	EF_MUZZLEFLASH;
		m_pPlayer.m_iWeaponVolume	= 	GAUSS_PRIMARY_FIRE_VOLUME;
		m_pPlayer.m_iWeaponFlash	=	DIM_GUN_FLASH;
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim(    GAUSSPISTOL_CHARGE_FIRE );
		
		Vector	vecSrc			=	m_pPlayer.GetGunPosition() + g_Engine.v_forward.opMul( 12 );
		
		FireProjectile( "gauss_charged", vecSrc, m_iSecondaryDamage, 100, 1000, m_pPlayer.pev );
		
		// light faster than sound!
		PlayWeaponSound( m_szChargeSound );
		PlayMenuSound(   m_szChargeReloadSound );
		
		V_PunchAxis( 0, -10.0 );
		
		NextAttack( m_flChargeAttackDelay );
		
		NextIdle( g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 ) );
	}
	
	void FireRapidMode()
	{
		int currentClip = GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO );
		
		// not enough clip?
		if( SetAmmoAmount( AMMO_TYPE_PRIMARYAMMO, --currentClip ) == false )
		{
			self.PlayEmptySound();
			NextAttack( m_flEmptyDelay );
			return;
		}
		
		m_pPlayer.pev.effects		|=	EF_MUZZLEFLASH;
		self.pev.effects			|=	EF_MUZZLEFLASH;
		m_pPlayer.m_iWeaponVolume	= 	GAUSS_PRIMARY_FIRE_VOLUME;
		m_pPlayer.m_iWeaponFlash	=	DIM_GUN_FLASH;
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim(    GAUSSPISTOL_RAPID_FIRE );
		
		Vector	vecDirShooting	=	m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		Vector	vecSrc			=	m_pPlayer.GetGunPosition() + g_Engine.v_forward.opMul( 12 ) /*+ g_Engine.v_right.opMul( 4 ) + g_Engine.v_up.opMul( -8 )*/ ;
		
		FireProjectileSpread( "gauss_ball", vecSrc, vecDirShooting, VECTOR_CONE_7DEGREES, m_iTertiaryDamage, 0.0f, 2000, m_pPlayer.pev );
		
		// light faster than sound!
		PlayWeaponSound( m_szRapidSound );
		
		NextAttack( m_flRapidAttackDelay );
		
		NextIdle( g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 ) );
	}
	
	bool CanSwitchToSniper()
	{
		return self.m_hPlayer.IsValid() && m_cmMenu.menu_getvalue( 0 ) == GAUSSPISTOL_MODE_SNIPER && m_pPlayer.HasNamedPlayerItem( "cust_2GaussPistolSniper" ) !is null;
	}
	
	bool SwitchToSniper()
	{
		if( CanSwitchToSniper() )
		{
			// reset to pulse
			ChangeCustomMenuSelection( 0 , GAUSSPISTOL_MODE_PULSE );
			
			CBaseEntity@ pEnt = m_pPlayer.HasNamedPlayerItem( "cust_2GaussPistolSniper" );
				
			if( pEnt !is null )
			{
				m_pPlayer.m_flNextAttack = WeaponTimeBase() + 1337.0f;
				NextAttack( 1337.0f );
				NextIdle(   1337.0f );
				self.SendWeaponAnim( GAUSSPISTOL_HOLSTER, 0, self.pev.body );
				
				self.pev.nextthink = WeaponTimeBase() + 2.0f;
				
				return true;
			}
		}
		
		return false;
	}
};

void RegisterEntity_WeaponGaussPistol()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_gausspistol", "weapon_gausspistol" );
	g_ItemRegistry.RegisterWeapon( "weapon_gausspistol", "gunmanchronicles", "uranium" );
	
	RegisterEntity_ProjectileGaussCharged();
	RegisterEntity_ProjectileGaussRapid();
	
	g_Game.PrecacheOther("gauss_charged");
	g_Game.PrecacheOther("gauss_ball");
};
