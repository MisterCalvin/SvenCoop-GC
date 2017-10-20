#include "GC_ScriptBasePlayerWeaponEntity"

#include "../AMMO/ammo_gcbuckshot"

enum gcshotgun_anim_e
{
	GCSHOTGUN_DRAW			= 0,
	GCSHOTGUN_IDLE,
	GCSHOTGUN_IDLE_INSPECT,
	GCSHOTGUN_SHOOT1,
	GCSHOTGUN_SHOOT2,
	GCSHOTGUN_SHOOT3,
	GCSHOTGUN_SHOOT4,
	GCSHOTGUN_CUSTOMIZE
};

enum gcshotgun_spreadmode_e
{
	GCSHOTGUN_MODE_SHOTGUN		= 0,
	GCSHOTGUN_MODE_RIOTGUN,
	GCSHOTGUN_MODE_RIFLE
};

enum gcshotgun_menutitle_e
{
	GCSHOTGUN_MENU_SHELLCOUNTS = 0,
	GCSHOTGUN_MENU_SPREAD
}

const int GCSHOTGUN_DEFAULT_GIVE		=	GC_BUCKSHOT_GIVE;
const int GCSHOTGUN_DEFAULT_MAXCARRY	=	GC_BUCKSHOT_MAXCARRY;

// special deathmatch shotgun spreads
const Vector VECTOR_CONE_DM_SHOTGUN			=	Vector( 0.08716, 0.04362, 0.00 ); // 10 degrees by 5 degrees
const Vector VECTOR_CONE_DM_DOUBLESHOTGUN	=	Vector( 0.17365, 0.04362, 0.00 ); // 20 degrees by 5 degrees

class weapon_gcshotgun : GC_BasePlayerWeapon
{
	private string	m_szShootSound			= "gunmanchronicles/weapons/sbarrel1.wav";
	private Vector  m_vecSpread				= g_vecZero;
	
	// Constructor
	weapon_gcshotgun()
	{
		this.WorldModel		=	"models/gunmanchronicles/w_shotgun.mdl";
		this.PlayerModel	=	"models/gunmanchronicles/p_shotgun.mdl";
		this.ViewModel		=	"models/gunmanchronicles/v_gcshotgun.mdl";
		
		this.m_flEmptyDelay = 0.15;
		
		BuildMenu();
	}
	
	void BuildMenu()
	{
		@m_cmMenu = @CustomMenu();
		
		// Shell Counts
		string title = "Shell Counts";
		m_cmMenu.menu_create(  title );
		m_cmMenu.menu_additem( title, "1" );
		m_cmMenu.menu_additem( title, "2" );
		m_cmMenu.menu_additem( title, "3" );
		m_cmMenu.menu_additem( title, "4" );
		
		// Spread
		title = "Spread";
		m_cmMenu.menu_create(  title );
		m_cmMenu.menu_additem( title, "Shotgun" );
		m_cmMenu.menu_additem( title, "Riotgun" );
		m_cmMenu.menu_additem( title, "Rifle" );
	}
	
	void ChangeCustomMenuSelection( uint titleId, uint itemId = Math.UINT32_MAX )
	{
		GC_BasePlayerWeapon::ChangeCustomMenuSelection( titleId, itemId );
		
		ShotgunReconfigure();
	}
	
	bool GetItemInfo(ItemInfo& out info)
	{
		info.iMaxAmmo1	= GCSHOTGUN_DEFAULT_MAXCARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot		= 2;
		info.iPosition	= 4;
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname ); //self.m_iId;
		info.iFlags		= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
		info.iWeight	= SHOTGUN_WEIGHT;
		
		return true;
	}
	
	void Precache()
	{
		GC_BasePlayerWeapon::Precache();
		
		// Get some extra files
		PrecacheWeaponHudInfo( "gunmanchronicles/weapon_gcshotgun.txt" );
		PrecacheWeaponHudInfo( "gunmanchronicles/crosshairs.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud1.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud4.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud7.spr" );
		PrecacheGenericSound( m_szShootSound );
		PrecacheGenericSound( "gunmanchronicles/weapons/shotgun_cock_heavy.wav" );
	}
	
	void Spawn()
	{
		GC_BasePlayerWeapon::Spawn();
		
		self.m_iDefaultAmmo	=	GCSHOTGUN_DEFAULT_GIVE;
	}
	
	bool Deploy()
	{
		ShotgunReconfigure();
		
		return DefaultDeploy( GCSHOTGUN_DRAW, "shotgun" , 0 , self.pev.body );
	}
	
	void Holster( int skipLocal /*= 0*/ )
	{
		//self.SendWeaponAnim( GCSHOTGUN_HOLSTER, skipLocal, self.pev.body );
		
		GC_BasePlayerWeapon::Holster( skipLocal );
	}
	
	void WeaponIdle()
	{
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int iAnim;
		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0, 1.0 );
		float flIdle = 0.1f;

		if( !IsMenuOpened() )
		{
			if( flRand <= 0.8 )
			{
				iAnim  = GCSHOTGUN_IDLE;
				flIdle = ( 30.0 / 15.0 );
			}
			else
			{
				iAnim  = GCSHOTGUN_IDLE_INSPECT;
				flIdle = ( 30.0 / 15.0 );
			}
		}
		// customize idle
		else
		{
			iAnim = GCSHOTGUN_CUSTOMIZE;
			flIdle = ( 46.0 / 20.0 );
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
			NextAttack( m_flEmptyDelay );
			return;
		}
		
		FireShotgun();
	}
	
	void FireShotgun()
	{
		int currentClip = GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO );
		int shellCounts = 1 + self.pev.impulse;
		
		// not enough clip?
		if( SetAmmoAmount( AMMO_TYPE_PRIMARYAMMO, currentClip - shellCounts ) == false )
		{
			self.PlayEmptySound();
			NextAttack( m_flEmptyDelay );
			return;
		}
		
		m_pPlayer.pev.effects		|=	EF_MUZZLEFLASH;
		self.pev.effects			|=	EF_MUZZLEFLASH;
		m_pPlayer.m_iWeaponVolume	= 	LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash	=	NORMAL_GUN_FLASH;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim(    GCSHOTGUN_IDLE_INSPECT + shellCounts );
		
		float	flMaxDistance	=	2048;
		Vector	vecSrc			=	m_pPlayer.GetGunPosition();
		Vector	vecDirShooting	=	m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		FireBullets( 4 * shellCounts, vecSrc, vecDirShooting, m_vecSpread, flMaxDistance, BULLET_PLAYER_BUCKSHOT, 0, 0, m_pPlayer.pev );
		
		PlayWeaponSound( m_szShootSound );
		
		V_PunchAxis( 0, -4.0 * shellCounts );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		m_pPlayer.pev.velocity = ( g_Engine.v_forward * -50 * shellCounts ) + m_pPlayer.pev.velocity;
		
		NextAttack( m_flPrimaryAttackDelay );
		
		NextIdle( g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 ) );
	}
	
	void ShotgunReconfigure()
	{
		if( m_cmMenu is null || m_cmMenu.MenuSize <=0 )
			return;
		
		self.pev.impulse = Math.clamp( 0, 3, m_cmMenu.menu_getvalue( GCSHOTGUN_MENU_SHELLCOUNTS ) );
		
		Vector vecSpread    = g_vecZero;
		float  flNextAttack = 0.1;
		switch( m_cmMenu.menu_getvalue( GCSHOTGUN_MENU_SPREAD ) )
		{
			case GCSHOTGUN_MODE_SHOTGUN: vecSpread=VECTOR_CONE_10DEGREES;	flNextAttack = 0.75;break;
			
			case GCSHOTGUN_MODE_RIOTGUN: vecSpread=VECTOR_CONE_20DEGREES;	flNextAttack = 0.75;break;
			
			case GCSHOTGUN_MODE_RIFLE:   vecSpread=VECTOR_CONE_5DEGREES;	flNextAttack = 1.5;break;
		}
		m_vecSpread = vecSpread;
		this.m_flPrimaryAttackDelay = flNextAttack;
	}
};

void RegisterEntity_WeaponGCShotgun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_gcshotgun", "weapon_gcshotgun" );
	g_ItemRegistry.RegisterWeapon( "weapon_gcshotgun", "gunmanchronicles", "buckshot" );
};
