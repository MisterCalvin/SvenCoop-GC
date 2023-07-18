#include "GC_ScriptBasePlayerWeaponEntity"

#include "../AMMO/ammo_dmlsingle"

enum dml_anim_e
{
	IDLE			= 0,
	IDLEFIDGET,
	RELOADBOTH,
	RELOADLEFT,
	RELOADRIGHT,
	FIRE,
	CUSTOMIZE,
	DRAW
};

enum dml_firemode_e
{
	DML_MODE_NORMAL			= 0,
	DML_MODE_TRIP
};

enum dml_menutitle_e
{
	DML_MENU_LAUNCH			= 0,
	DML_MENU_FLIGHTPATH,
	DML_MENU_DETONATE,
	DML_MENU_PAYLOAD
}

enum dml_bodygroups_e
{
	BODY		= 0,
	ROCKETS,
	SCREEN
}

const int DML_DEFAULT_GIVE		=	2;
const int DML_DEFAULT_MAXCARRY	=	DML_MAXCARRY;

class weapon_dml : GC_BasePlayerWeapon	//, LaserEffect, WallHitEffect
{
	private string	m_szFireSound				= "gunmanchronicles/weapons/dml_fire.wav";
	private string	m_szLockSound				= "gunmanchronicles/weapons/dml_lock.wav";
	private string	m_szCustomizeSound			= "gunmanchronicles/weapons/dml_customize.wav";
	private string	m_szReloadSound				= "gunmanchronicles/weapons/dml_reload.wav";
	private string	m_szDualReloadSound			= "gunmanchronicles/weapons/dml_dualreload.wav";
	private string	m_szFragmentSound			= "gunmanchronicles/weapons/dml_fragment.wav";
	private string	m_szEmptySound				= "gunmanchronicles/weapons/DryFire.wav";
	private string	m_szGrenade1Sound			= "gunmanchronicles/weapons/grenade_hit1.wav";
	private string	m_szGrenade2Sound			= "gunmanchronicles/weapons/grenade_hit2.wav";
	private string	m_szGrenade3Sound			= "gunmanchronicles/weapons/grenade_hit3.wav";
	private float	m_flNextPrimaryAttack;
	private bool	m_bReloadSwitch				= true;
	private int		m_iShotCounter;
	private int		m_iActiveRockets;

	weapon_dml()
	{
		this.WorldModel		=	"models/gunmanchronicles/w_dml.mdl";
		this.PlayerModel	=	"models/gunmanchronicles/p_crossbow.mdl";
		this.ViewModel		=	"models/gunmanchronicles/v_dml.mdl";
		
		this.m_iPrimaryDamage			=	8;
		this.m_iSecondaryDamage			=	50;
		this.m_iTertiaryDamage			=	10;
		
		BuildMenu();
	}
	
	void BuildMenu()
	{
		@m_cmMenu = @CustomMenu();
		
		// Firing Mode
		string title = "LAUNCH";
		m_cmMenu.menu_create(  title );
		m_cmMenu.menu_additem( title, "When Fired" );
		m_cmMenu.menu_additem( title, "When Targetted" );

		// Flight Path
		title = "FLIGHTPATH";
		m_cmMenu.menu_create(  title );
		m_cmMenu.menu_additem( title, "Guided" );
		m_cmMenu.menu_additem( title, "Homing" );
		m_cmMenu.menu_additem( title, "Spiral" );

		// Detonate Options
		title = "DETONATE";
		m_cmMenu.menu_create(  title );
		m_cmMenu.menu_additem( title, "On Impact" );
		m_cmMenu.menu_additem( title, "In Proximity" );
		m_cmMenu.menu_additem( title, "Timed" );
		m_cmMenu.menu_additem( title, "When Tripped" );

		// Payload
		title = "PAYLOAD";
		m_cmMenu.menu_create(  title );
		m_cmMenu.menu_additem( title, "Explosive" );
		m_cmMenu.menu_additem( title, "Cluster" );
	}
	
	void ChangeCustomMenuSelection( uint titleId, uint itemId = Math.UINT32_MAX )
	{	
		GC_BasePlayerWeapon::ChangeCustomMenuSelection( titleId, itemId );
	}
	
	void CloseCustomMenu()
	{
		GC_BasePlayerWeapon::CloseCustomMenu();
	}
	
	bool GetItemInfo(ItemInfo& out info)
	{
		info.iMaxAmmo1	= DML_DEFAULT_MAXCARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot		= 3;
		info.iPosition	= 6;
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags		= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
		info.iWeight	= 25;
		
		return true;
	}
	
	void Precache()
	{
		GC_BasePlayerWeapon::Precache();
		
		// Get some extra files
		//PrecacheLaserEffect();
		//PrecacheWallHitEffect();

		PrecacheWeaponHudInfo( "gunmanchronicles/weapon_dml.txt" );
		PrecacheWeaponHudInfo( "gunmanchronicles/crosshairs.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/dmllock.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud2.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud5.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud7.spr" );

		g_Game.PrecacheModel( self, "models/gunmanchronicles/dmlcluster.mdl" );
		g_Game.PrecacheModel( self, "models/gunmanchronicles/dmlrocket.mdl" );

		PrecacheGenericSound( m_szFireSound );
		PrecacheGenericSound( m_szCustomizeSound );
		PrecacheGenericSound( m_szReloadSound );
		PrecacheGenericSound( m_szDualReloadSound );
		PrecacheGenericSound( m_szLockSound );
		PrecacheGenericSound( m_szFragmentSound );
		PrecacheGenericSound( m_szEmptySound );
		PrecacheGenericSound( m_szGrenade1Sound );
		PrecacheGenericSound( m_szGrenade2Sound );
		PrecacheGenericSound( m_szGrenade3Sound );
	}
	
	void Spawn()
	{
		GC_BasePlayerWeapon::Spawn();
		
		self.m_iDefaultAmmo	=	DML_DEFAULT_GIVE;
	}
	
	void Think()
	{
		BaseClass.Think();
		
		//reset shot counter
		m_iActiveRockets = 0;
	}
	
	bool Deploy()
	{
		//NextIdle ( 4.0f );
		return DefaultDeploy( DRAW, "gauss" , 0 , self.pev.body );
	}
	
	void Holster( int skipLocal )
	{
		self.SendWeaponAnim( DRAW, skipLocal, self.pev.body );
		
		GC_BasePlayerWeapon::Holster( skipLocal );
	}
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() ) return;
        		switch( Math.RandomLong(0,1) )
		{
			case 0 : self.SendWeaponAnim( IDLE ); break;
			case 1 : self.SendWeaponAnim( IDLEFIDGET ); break;
		}
        self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
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
			
			//CreateWallHitEffect( pTrace.vecEndPos );
			//CreateWallHitSound( pTrace.vecEndPos );
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

		//int currentClip = GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO );
		
		// not enough clip?
		/*if( SetAmmoAmount( AMMO_TYPE_PRIMARYAMMO, currentClip - 10 ) == false )
		{
			self.PlayEmptySound();
			NextAttack( m_flEmptyDelay );
			return;
		}*/

		// Rocket
		if( m_flNextPrimaryAttack > g_Engine.time )
			return;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( FIRE );

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		Vector	vecSrc	= m_pPlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 8 + g_Engine.v_up * -8;
		
		g_EntityFuncs.CreateRPGRocket( vecSrc, m_pPlayer.pev.v_angle, self.edict() );

		if ( m_bReloadSwitch == true )
		{
		self.SendWeaponAnim( RELOADLEFT );
		m_iActiveRockets++;

		m_pPlayer.pev.effects		|=	EF_MUZZLEFLASH;
		self.pev.effects			|=	EF_MUZZLEFLASH;
		m_pPlayer.m_iWeaponVolume	= 	NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash	=	DIM_GUN_FLASH;

		m_bReloadSwitch = !m_bReloadSwitch;
		NextAttack ( 2.0f );
		}
	else
		{
		self.SendWeaponAnim( RELOADRIGHT );
		m_iActiveRockets++;

		m_pPlayer.pev.effects		|=	EF_MUZZLEFLASH;
		self.pev.effects			|=	EF_MUZZLEFLASH;
		m_pPlayer.m_iWeaponVolume	= 	NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash	=	DIM_GUN_FLASH;

		m_bReloadSwitch = !m_bReloadSwitch;
		NextAttack ( 2.0f );
		}

		NextIdle ( 4.0f );
		//m_flNextPrimaryAttack = g_Engine.time + 3.0f;
	}
};

void RegisterEntity_WeaponDML()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dml", "weapon_dml" );
	g_ItemRegistry.RegisterWeapon( "weapon_dml", "gunmanchronicles", "rpg" );
};
