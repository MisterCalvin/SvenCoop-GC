#include "../GC_CommonFunctions"

enum baseplayerweapon_nextattack_e
{
	WEAPON_NEXT_ATTACK_ALL = 0,
	WEAPON_NEXT_ATTACK_PRIMARY,
	WEAPON_NEXT_ATTACK_SECONDARY,
	WEAPON_NEXT_ATTACK_TERTIARY
}

abstract class GC_BasePlayerWeapon : ScriptBasePlayerWeaponEntity
{
	private	string	W_MODEL;
	private	string	P_MODEL;
	private	string	V_MODEL;
	
	CScheduledFunction@ m_pMenuNextThink = null;
	TraceResult  m_pLastAttackTr;
	CustomMenu@  m_cmMenu = @CustomMenu();
	
	float	m_flDeployDelay				=	0.5f;
	float	m_flEmptyDelay				=	0.15;
	
	float	m_flMenuToggleDelay			=	0.3f;
	float	m_flMenuSwitchDelay			=	0.3f;
	float	m_flMenuTextHold			=	0.3f;
	
	float	m_flPrimaryAttackDelay		=	0.1f;
	float	m_flSecondaryAttackDelay	=	0.5f;
	float	m_flTertiaryAttackDelay		=	0.3f;
	
	int		m_iPrimaryDamage			=	1337;
	int		m_iSecondaryDamage			=	1337;
	int		m_iTertiaryDamage			=	1337;
	
	bool	m_bMenuActive				=	false;
	
	private	string	SOUND_MENU_OPENED	=	"gunmanchronicles/common/wpn_hudon.wav";
	private	string	SOUND_MENU_CLOSED	=	"gunmanchronicles/common/wpn_hudoff.wav";
	
	CBasePlayer@ m_pPlayer
	{
		get const	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() );  }
		set			{ self.m_hPlayer = EHandle( @value); }
	}
	
	string WorldModel
	{
		get const	{ return W_MODEL;  }
		set			{ W_MODEL = value; }
	}
	string PlayerModel
	{
		get const	{ return P_MODEL;  }
		set			{ P_MODEL = value; }
	}
	string ViewModel
	{
		get const	{ return V_MODEL;  }
		set			{ V_MODEL = value; }
	}
	string SoundMenuOpened
	{
		get const	{ return SOUND_MENU_OPENED;  }
	}
	string SoundMenuClosed
	{
		get const	{ return SOUND_MENU_CLOSED;  }
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void SendWeaponPickup( edict_t@ pPlayerEdict, const string &in weaponName )
	{
		NetworkMessage msg( MSG_ONE, NetworkMessages::WeapPickup, pPlayerEdict );
		
		msg.WriteLong( g_ItemRegistry.GetIdForName( weaponName ) );
		
		msg.End();
	}
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "setTitleValue" )
		{
			Vector temp;
			g_Utility.StringToVector( temp, szValue );
			
			m_cmMenu.menu_setvalue( uint(temp.x), uint(temp.y) );
			
			//g_Game.AlertMessage( at_console, "setTitleValue %1 %2 %3\n", temp.x, temp.y, temp.z );
			
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		
		g_Game.PrecacheModel( self, W_MODEL );
		g_Game.PrecacheModel( self, P_MODEL );
		g_Game.PrecacheModel( self, V_MODEL );
		
		PrecacheGenericSound( SOUND_MENU_OPENED );
		PrecacheGenericSound( SOUND_MENU_CLOSED );
	}
	
	void Spawn()
	{
		Precache();
		
		if( string(self.pev.model).IsEmpty() )
			self.pev.model = W_MODEL;
		
		g_EntityFuncs.SetModel( self, self.pev.model );
		
		self.FallInit();// get ready to fall down.
	}
	
	void ShowMenu()
	{
		if( m_pMenuNextThink !is null )
			g_Scheduler.RemoveTimer( m_pMenuNextThink );
		
		if( self.m_hPlayer.IsValid() && IsMenuOpened() )
		{
			m_cmMenu.menu_display( m_pPlayer );
			//g_Game.AlertMessage( at_console, "%1\n", m_cmMenu.menu_buildText() );
			
			@m_pMenuNextThink = g_Scheduler.SetTimeout( @this, "ShowMenu", m_flMenuTextHold );
		}
	}
	
	void PrimaryAttack()
	{
		if( IsMenuOpened() )
		{
			CloseCustomMenu();
			NextAttack( m_flMenuToggleDelay );
		}
	}
	
	void SecondaryAttack()
	{
		if( IsMenuOpened() )
		{
			uint nextMenu = m_cmMenu.SelectedTitle + 1;
			
			// Last title reached, close...
			/*if( nextMenu >= m_cmMenu.MenuSize )
				CloseCustomMenu();
			else*/
			// change to next title
				ChangeCustomMenuSelection( nextMenu );
				
			NextAttack( m_flMenuToggleDelay );
		}
		else
		{
			OpenCustomMenu();
			NextAttack( m_flMenuToggleDelay );
		}
	}
	
	void TertiaryAttack()
	{
		if( IsMenuOpened() )
		{
			ChangeCustomMenuSelection( m_cmMenu.SelectedTitle, m_cmMenu.SelectedItem + 1 );
			NextAttack( m_flMenuSwitchDelay );
		}
	}
	
	bool AddToPlayer(CBasePlayer@ pPlayer)
	{
		bool result = BaseClass.AddToPlayer( pPlayer );
		
		if( result )
		{
			SendWeaponPickup( pPlayer.edict(), self.pev.classname );
		}
		
		return result;
	}
	void Drop()
	{
		CloseCustomMenu();
		BaseClass.Drop();
	}
	
	bool CanDeploy()
	{
		// Always can deploy when selectable
		if( ( self.iFlags() & ITEM_FLAG_SELECTONEMPTY ) != 0 )
			return true;
		
		return BaseClass.CanDeploy();
	}
	
	bool DefaultDeploy(int iAnim, const string& in szAnimExt, int skiplocal = 0, int body = 0)
	{
		bool result = self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), iAnim, szAnimExt, skiplocal, body );
		
		NextIdle( m_flDeployDelay + 0.5f );
		NextAttack( m_flDeployDelay );
		
		return result;
	}
	
	void Holster( int skipLocal /*= 0*/ )
	{
		self.m_fInReload = false;// cancel any reload in progress.

		m_pPlayer.m_flNextAttack	= WeaponTimeBase() + 0.5f;
		
		CloseCustomMenu();
		
		BaseClass.Holster( skipLocal );
	}
	
	void DefaultWeaponIdle( const int iAnim, const float flIdleDuration = 0.1f )
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( iAnim, 0, self.pev.body );
		NextIdle( flIdleDuration );
	}
	
	int GetAmmoAmount( AmmoType eType )
	{
		if( self.m_hPlayer.IsValid() == false )
			return -1;
		
		switch( eType )
		{
			case AMMO_TYPE_PRIMARYAMMO:
			{
				return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
			}
			
			case AMMO_TYPE_SECONDARYAMMO:
			{
				return m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType );
			}
		}
		
		return -1;
	}
	
	bool SetAmmoAmount( AmmoType eType, int iValue )
	{
		if( self.m_hPlayer.IsValid() == false || iValue < 0 )
			return false;
		
		int ammoIndex;
		switch( eType )
		{
			case AMMO_TYPE_PRIMARYAMMO:
			{
				ammoIndex = self.m_iPrimaryAmmoType;
				break;
			}
			
			case AMMO_TYPE_SECONDARYAMMO:
			{
				ammoIndex = self.m_iSecondaryAmmoType;
				break;
			}
		}
		
		m_pPlayer.m_rgAmmo( ammoIndex, iValue );
		
		return true;
	}
	
	int GetFOV()
	{
		// more check, less crash :3
		if( self.m_hPlayer.IsValid() == false )
			return -1;
		
		return uint( m_pPlayer.pev.fov );
	}
	void SetFOV( uint uiFOV )
	{
		// more check, less crash :3
		if( self.m_hPlayer.IsValid() )
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = uiFOV;
	}
	
	void PlayWeaponSound( string soundFile, float flVolume = VOL_NORM, float flAttenuation = ATTN_NORM, int iFlags = 0, int iPitch = PITCH_NORM )
	{
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, soundFile, flVolume, flAttenuation, iFlags, iPitch );
	}
	void PlayMenuSound( string soundFile, float flVolume = VOL_NORM, float flAttenuation = ATTN_NORM, int iFlags = 0, int iPitch = PITCH_NORM )
	{
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, soundFile, flVolume, flAttenuation, iFlags, iPitch );
	}
	
	void V_PunchAxis( int axis, float punch )
	{
		float[] vecFloat( 3 );
		vecFloat[Math.clamp(0,vecFloat.length()-1,axis)] = punch;
		
		m_pPlayer.pev.punchangle = Vector( vecFloat[0], vecFloat[2], vecFloat[1] );
	}
	
	void FireBullets(uint cShots, Vector vecSrc, Vector vecDirShooting, Vector vecSpread, float flDistance, Bullet iBulletType, int iTracerFreq = 4, int iDamage = 0, entvars_t@ pevAttacker = null, FireBulletsDrawMode fDraw = FBDM_DRAW)
	{
		m_pPlayer.FireBullets( cShots, vecSrc, vecDirShooting, vecSpread, flDistance, iBulletType, iTracerFreq, iDamage, pevAttacker, fDraw );
		
		m_pLastAttackTr = TraceResult();
		
		// Draw the gunshot decals...
		if( fDraw != FBDM_DONTDRAW )
			StartTraceDecal( cShots, vecSrc, vecDirShooting, vecSpread, flDistance, iBulletType, pevAttacker.get_pContainingEntity() );
	}
	
	CBaseEntity@ FireProjectile( const string& in szClassName, Vector vecSrc, int iDamage = 0, float fRadius = 32.0f, float fSpeed = 1000.0f, entvars_t@ pevAttacker = null, float fTimed = 0.0f )
	{
		// Fake attack to alert entire environment
		FireBullets( 1, vecSrc, m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ), VECTOR_CONE_1DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 4, 0, pevAttacker, FBDM_DONTDRAW );
		
		Vector anglesAim = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;
		
		CBaseEntity@ pProj = g_EntityFuncs.Create( szClassName, vecSrc, anglesAim, true, pevAttacker.get_pContainingEntity() );
		
		if( pProj !is null )
		{
			@pProj.pev.owner  = @pevAttacker.get_pContainingEntity();
			pProj.pev.dmg     = iDamage;
			pProj.pev.dmgtime = fTimed;
			pProj.pev.speed   = fSpeed;
			pProj.pev.fov     = fRadius;
			
			g_EntityFuncs.DispatchSpawn( pProj.edict() );
		}
		
		return pProj;
	}
	
	CBaseEntity@ FireProjectileSpread( const string& in szClassName, Vector vecSrc, Vector vecDirShooting, Vector vecSpread, int iDamage = 0, float fRadius = 32.0f, float fSpeed = 500.0f, entvars_t@ pevAttacker = null, float fTimed = 0.0f )
	{
		Vector vecRight = g_Engine.v_right;
		Vector vecUp = g_Engine.v_up;
		
		// Fake attack to alert entire environment
		FireBullets( 1, vecSrc, vecDirShooting, vecSpread, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 4, 0, pevAttacker, FBDM_DONTDRAW );
		
		// get circular gaussian spread
		float x, y, z;
		do {
			x = Math.RandomFloat( -0.5, 0.5 ) + Math.RandomFloat( -0.5, 0.5 );
			y = Math.RandomFloat( -0.5, 0.5 ) + Math.RandomFloat( -0.5, 0.5 );
			z = x * x + y * y;
		} while (z > 1);

		Vector vecDir = vecDirShooting +
						x * vecSpread.x * vecRight +
						y * vecSpread.y * vecUp;
		Vector vecEnd = vecSrc + vecDir * 8192;
		
		TraceResult tr;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pevAttacker.get_pContainingEntity(), tr );
		
		// debug
		//CreateTempEnt_Box( vecSrc + Vector(-1,-1,-1),	vecSrc + Vector(1,1,1), 32, BLUE );
		//CreateTempEnt_Box( tr.vecEndPos + Vector(-1,-1,-1),	tr.vecEndPos + Vector(1,1,1), 32, GREEN );
			
		Vector anglesAim = Math.VecToAngles( (tr.vecEndPos - vecSrc).Normalize() ) + m_pPlayer.pev.punchangle;
		anglesAim.x = -anglesAim.x; // fix for shitty inverted roll axis
		
		CBaseEntity@ pProj = g_EntityFuncs.Create( szClassName, vecSrc, anglesAim, true, pevAttacker.get_pContainingEntity() );
		
		if( pProj !is null )
		{
			@pProj.pev.owner  = @pevAttacker.get_pContainingEntity();
			pProj.pev.dmg     = iDamage;
			pProj.pev.dmgtime = fTimed;
			pProj.pev.speed   = fSpeed;
			pProj.pev.fov     = fRadius;
			
			g_EntityFuncs.DispatchSpawn( pProj.edict() );
		}
		
		return pProj;
	}
	
	void StartTraceDecal( uint cShots, Vector vecSrc, Vector vecDirShooting, Vector vecSpread, float flDistance, Bullet iBulletType, edict_t@ pEntIgnore = null, bool noRicochet = false )
	{
		TraceResult tr;
		Vector vecRight = g_Engine.v_right;
		Vector vecUp = g_Engine.v_up;
		float x, y, z;
		
		for( uint iShot = 1; iShot <= cShots; iShot++ )
		{
			//Use player's random seed.
			// get circular gaussian spread
			g_Utility.GetCircularGaussianSpread( x, y );
			z = x * x + y * y;

			Vector vecDir = vecDirShooting +
							vecRight.opMul( x * vecSpread.x ) +
							vecUp.opMul( y * vecSpread.y );
			Vector vecEnd;

			vecEnd = vecSrc + vecDir.opMul( flDistance );

			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pEntIgnore, tr );
			
			// do damage, paint decals
			if( tr.flFraction != 1.0 )
			{
				DrawDecal( tr, iBulletType, noRicochet );
			}
			
			m_pLastAttackTr = tr;
		}
	}
	
	void DrawDecal( TraceResult &in pTrace, Bullet iBulletType, bool noRicochet = false )
	{
		if( noRicochet == false )
			DecalGunshot( pTrace, iBulletType );
		else
			DecalGunshotNoRicochet( pTrace, iBulletType );
	}
	
	bool IsMenuOpened()
	{
		return m_bMenuActive;
	}
	void OpenCustomMenu()
	{
		m_bMenuActive	=	true;
		ShowMenu();
		PlayMenuSound( SOUND_MENU_OPENED );
		
		// Prevent unaccidental weapon switching
		self.m_bExclusiveHold = true;
	}
	void CloseCustomMenu()
	{
		m_bMenuActive	=	false;
		// reset title position to zero
		ChangeCustomMenuSelection( 0 );
		PlayMenuSound( SOUND_MENU_CLOSED );
		
		// Unlock the weapon switching
		self.m_bExclusiveHold = false;
	}
	void ChangeCustomMenuSelection( uint titleId, uint itemId = Math.UINT32_MAX )
	{
		m_cmMenu.menu_changeselection( titleId, itemId );
	}
	
	void NextIdle( float timeNext = 0.1f )
	{
		self.m_flTimeWeaponIdle			= WeaponTimeBase() + timeNext;
	}
	void NextAttack( float timeNext = 0.1f , baseplayerweapon_nextattack_e eType = WEAPON_NEXT_ATTACK_ALL )
	{
		float fCalculated = WeaponTimeBase() + timeNext;
		
		switch( eType )
		{
			case WEAPON_NEXT_ATTACK_PRIMARY:
				self.m_flNextPrimaryAttack		= fCalculated;
				return;
			case WEAPON_NEXT_ATTACK_SECONDARY:
				self.m_flNextSecondaryAttack	= fCalculated;
				return;
			case WEAPON_NEXT_ATTACK_TERTIARY:
				self.m_flNextTertiaryAttack		= fCalculated;
				return;
			default:
				break;
		}
		
		self.m_flNextPrimaryAttack		= fCalculated;
		self.m_flNextSecondaryAttack	= fCalculated;
		self.m_flNextTertiaryAttack		= fCalculated;
		//m_pPlayer.m_flNextAttack		= WeaponTimeBase() + timeNext;
	}
	
}

class CustomMenu
{
	private HUDTextParams			hudParams;
	private string[]				szArrTitle;
	private array<array<string>>	szArrItem;
	private uint[]					iArrTitleValue;
	
	private uint					iSelectedTitle;
	private uint					iSelectedItem;
	
	uint SelectedTitle
	{
		get const { return iSelectedTitle; }
	}
	string SelectedTitleValue
	{
		get const { return szArrTitle[iSelectedTitle]; }
	}
	
	uint SelectedItem
	{
		get const { return iSelectedItem; }
	}
	string SelectedItemValue
	{
		get const { return szArrItem[iSelectedTitle][ iArrTitleValue[iSelectedTitle] ]; }
	}
	
	uint MenuSize
	{
		get const { return szArrTitle.length(); }
	}
	
	int FindTitle( const string &in title )
	{
		return szArrTitle.find( title );
	}
	
	int FindItem( const int titleId, const string &in item )
	{
		if( titleId < 0 || uint( titleId ) >= szArrTitle.length() )
			return -1;
		
		return szArrItem[ titleId ].find( item );
	}
	int FindItem( const string &in title, const string &in item )
	{
		return FindItem( FindTitle( title ), item );
	}
	
	// Constructor
	CustomMenu( float x = -1, float y = 0.27f, int channel = 2, Color color1 = WHITE, Color color2 = WHITE )
	{
		this.hudParams.x       = x;
		this.hudParams.y       = y;
		this.hudParams.r1      = color1.r;
		this.hudParams.g1      = color1.g;
		this.hudParams.b1      = color1.b;
		this.hudParams.a1      = color1.a;
		this.hudParams.r2      = color2.r;
		this.hudParams.g2      = color2.g;
		this.hudParams.b2      = color2.b;
		this.hudParams.a2      = color2.a;
		this.hudParams.channel = channel;
		
		this.hudParams.effect      = 0;
		this.hudParams.fadeinTime  = 0.0f;
		this.hudParams.fadeoutTime = 0.0f;
		this.hudParams.holdTime    = 0.4f;
	}
	
	void menu_create( const string &in title )
	{
		szArrTitle.insertLast( title );
		szArrItem.resize( szArrTitle.length() );
		iArrTitleValue.resize( szArrTitle.length() );
	}
	
	void menu_additem( const string &in title, const array<string> &in item )
	{
		menu_additem( FindTitle( title ), item );
	}
	void menu_additem( const uint titleId, const array<string> &in item )
	{
		for( uint i = 0; i < item.length(); i++ )
			menu_additem( titleId, item[i] );
	}
	
	void menu_additem( const string &in title, const string &in item )
	{
		menu_additem( FindTitle( title ), item );
	}
	void menu_additem( const uint titleId, const string &in item )
	{
		uint cachedId = titleId;
		if( titleId >= szArrTitle.length() )
			cachedId = 0;
		
		szArrItem[ cachedId ].insertLast( item );
	}
	
	void menu_changeselection( const string &in title, const uint itemId )
	{
		menu_changeselection( FindTitle( title ), itemId );
	}
	void menu_changeselection( const uint titleId, const string &in item )
	{
		menu_changeselection( titleId, FindItem( titleId, item ) );
	}
	void menu_changeselection( const string &in title, const string &in item )
	{
		uint titleId = FindTitle( title );
		if( titleId >= szArrTitle.length() )
			titleId = 0;
		
		menu_changeselection( titleId, FindItem( titleId, item ) );
	}
	
	void menu_changeselection( const uint titleId, uint itemId = Math.UINT32_MAX )
	{
		if( titleId >= szArrTitle.length() )
			// move to first
			iSelectedTitle = 0;
		else
			iSelectedTitle  = titleId;
		
		
		
		if( itemId == Math.UINT32_MAX )
			// dont change current item
			iSelectedItem = iArrTitleValue[ iSelectedTitle ];
		else
		if( itemId >= szArrItem[ titleId ].length() )
			// move to first
			iSelectedItem = 0;
		else
			iSelectedItem = itemId;
		
		
		
		menu_setvalue( iSelectedTitle, iSelectedItem );
	}
	
	void menu_setvalue( const uint titleId, const uint itemId )
	{
		if( titleId >= szArrTitle.length() || itemId >= szArrItem[ titleId ].length() )
			return;
		
		iArrTitleValue[ titleId ] = itemId;
	}
	uint menu_getvalue( const uint titleId )
	{
		if( titleId >= szArrTitle.length() )
			return iArrTitleValue[ szArrTitle.length()-1 ];
		
		return iArrTitleValue[ titleId ];
	}
	
	string menu_buildText()
	{
		string temp;
		
		for( uint i = 0; i < szArrTitle.length(); i++ )
		{
			// add new line after first loop
			if( i > 0 )
				temp += "\n";
				
			// add title
			temp += szArrTitle[i] + "\t\t\t";
			
			// is this currently selected title?
			string selectedPrefix, selectedSuffix;
			if( i == iSelectedTitle )
			{
				selectedPrefix = " >>";
				selectedSuffix = "<< ";
			}
			
			// add item
			temp += selectedPrefix + szArrItem[i][ iArrTitleValue[i] ] + selectedSuffix;
		}
		
		return temp;
	}
	
	void menu_display( CBasePlayer@ pTargetPlayer )
	{
		g_PlayerFuncs.HudMessage( pTargetPlayer, this.hudParams, this.menu_buildText() );
	}
}
