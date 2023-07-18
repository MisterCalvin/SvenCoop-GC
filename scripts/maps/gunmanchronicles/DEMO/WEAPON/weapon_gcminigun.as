//#include "GC_ScriptBasePlayerWeaponEntity"

#include "../AMMO/ammo_gcminigunclip"

enum gcminigun_anim_e
{
	GCMINIGUN_IDLE			= 0,
	GCMINIGUN_IDLE_INSPECT,
	GCMINIGUN_FIRE_NORMAL,
	GCMINIGUN_SPIN_UP,		// Engage Rapid fire Mode
	GCMINIGUN_FIRE_LOOP, 	// Rapid firing
	GCMINIGUN_SPIN_DOWN,	// Disengage Rapid fire mode
	GCMINIGUN_ARMING,
    GCMINIGUN_IDLE_LOOP, 	// Rapid Idle
    GCMINIGUN_HOLSTER
};

enum gcminigun_firemode_e
{
	GCMINIGUN_FIRE_PRIMARY		= 0,
	GCMINIGUN_FIRE_RAPID
};

const int GCMINIGUN_DEFAULT_GIVE		=	GCMINIGUN_GIVE;
const int GCMINIGUN_DEFAULT_MAXCARRY	=	GCMINIGUN_MAXCARRY;

class weapon_gcminigun : GC_BasePlayerWeapon
{
	private string	m_szFireSound				= "gunmanchronicles/weapons/hks1.wav";
    private string	m_szFireSound1				= "gunmanchronicles/weapons/hks2.wav";
    private string	m_szFireSound2				= "gunmanchronicles/weapons/hks3.wav";
	private	string	m_szEmptySound				= "gunmanchronicles/weapons/357_cock1.wav";
	private string	m_szSpinUpSound				= "gunmanchronicles/weapons/mechaspinup.wav";
	private string	m_szSpinDownSound			= "gunmanchronicles/weapons/mechaspindown.wav";
    private string	m_szFireModeToggle			= "gunmanchronicles/weapons/wpn_hudon.wav";
    private string	m_szPistolSprite			= "sprites/gunmanchronicles/hudtext.spr";
    private string  m_szWarningMessage;

    private bool	m_bRapidModeEngaged			= false;
    private bool	m_fPrimaryFire				= false;
	private	bool	m_bOverHeating				= false;
    
   	protected int	FiringMode;
    private int		m_iShell;
    
	//private string	m_szChargeReloadSound	= "gunmanchronicles/weapons/gauss_charge.wav";

	private int		m_iShotCounter;
	
	private float	m_flSingleAttackDelay;
	private float	m_flRapidAttackDelay;
	
	private bool	m_bSecondaryFire	= true;
	
	// Constructor
	weapon_gcminigun()
	{
		this.WorldModel		=	"models/gunmanchronicles/w_mechagun.mdl";
		this.PlayerModel	=	"models/gunmanchronicles/p_9mmar.mdl";
		this.ViewModel		=	"models/gunmanchronicles/v_mechagun.mdl";
		
		this.m_iPrimaryDamage			=	10;
		//this.m_iSecondaryDamage			=	0;
		
        this.m_flSingleAttackDelay		=	0.20f;
		this.m_flRapidAttackDelay		=	0.11f;	
	}
	
	bool GetItemInfo(ItemInfo& out info)
	{
		info.iMaxAmmo1	= GCMINIGUN_DEFAULT_MAXCARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot		= 2;
		info.iPosition	= 4;
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags		= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
		info.iWeight	= 20;

		m_flEmptyDelay	= 1.0f;
		
		return true;
	}
	
	void Precache()
	{
		GC_BasePlayerWeapon::Precache();
		
		// Get some extra files
		PrecacheWeaponHudInfo( "gunmanchronicles/weapon_gcminigun.txt" );
		PrecacheWeaponHudInfo( "gunmanchronicles/crosshairs.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud1.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud4.spr" );
		PrecacheWeaponHudInfo( "gunmanchronicles/640hud7.spr" );
        
		g_Game.PrecacheModel( self, "models/gunmanchronicles/w_mechagun.mdl" );
        
        m_iShell = g_Game.PrecacheModel( "models/gunmanchronicles/shell.mdl" );
        
		PrecacheGenericSound( m_szFireSound );
        PrecacheGenericSound( m_szFireSound1 );
        PrecacheGenericSound( m_szFireSound2 );
        PrecacheGenericSound( m_szFireModeToggle );
		PrecacheGenericSound( m_szSpinUpSound );
		PrecacheGenericSound( m_szSpinDownSound );
		PrecacheGenericSound( m_szEmptySound );
        
        g_Game.PrecacheModel( m_szPistolSprite );
        g_Game.PrecacheGeneric( m_szPistolSprite );
	}
	
	void Spawn()
	{
		GC_BasePlayerWeapon::Spawn();
		
		self.m_iDefaultAmmo	=	GCMINIGUN_DEFAULT_GIVE;
	}
	
	void Think()
	{
		BaseClass.Think();

		// reset shot counter
		m_iShotCounter = 0;

		if ( m_bOverHeating == true && m_iShotCounter < 5 )
		{
			SetElectricState ( false );
		}    
	}
	
	bool Deploy()
	{
		/*HUDSpriteParams params;
        params.spritename = "gunmanchronicles/hudtext.spr";
        params.flags = HUD_ELEM_DEFAULT_ALPHA;
        params.color1 = RGBA( 255, 255, 255, 255 );
        params.channel = 0;
        params.frame = 0;
      	params.top = 0;
        params.height = 34;
        params.width = 0;
        params.x = 0.5;
        params.y = 1.0;

        g_PlayerFuncs.HudCustomSprite( m_pPlayer, params );*/

		NextIdle( 3.0f );
		return DefaultDeploy( GCMINIGUN_ARMING, "MP5" , 0 , self.pev.body );
	}
	
	void Holster( int skipLocal )
	{
		self.SendWeaponAnim( GCMINIGUN_HOLSTER, skipLocal, self.pev.body );
		GC_BasePlayerWeapon::Holster( skipLocal );
	}
	
	void WeaponIdle()
	{
    	if( self.m_flNextPrimaryAttack < g_Engine.time )
			m_iShotCounter = 0;

		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
    
    	if( m_bRapidModeEngaged == true )
        {
			if (GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO ) == 0)
			{
					m_bRapidModeEngaged = false;
                    self.SendWeaponAnim( GCMINIGUN_SPIN_DOWN );
                    PlayWeaponSound( m_szSpinDownSound );
                    FiringMode = 0;
                    NextAttack( 2.3f );
                    NextIdle ( 4.0f );
					return;
			}
			
        	if( self.m_flTimeWeaponIdle > WeaponTimeBase() + 0.05 ) return;
			self.SendWeaponAnim( GCMINIGUN_IDLE_LOOP );
            self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.6f; // Change this; KCM, originally 0.65f

			/*self.SendWeaponAnim( GCMINIGUN_IDLE_LOOP );
			self.m_fSequenceLoops = true;
			self.pev.animtime =	2.0;
			self.m_flTimeWeaponIdle = self.animtime;*/

            }
		else {
             if( self.m_flTimeWeaponIdle > WeaponTimeBase() ) return;
        		switch( Math.RandomLong(0,1) )
		{
			case 0 : self.SendWeaponAnim( GCMINIGUN_IDLE ); break;
			case 1 : self.SendWeaponAnim( GCMINIGUN_IDLE_INSPECT ); break;
		}
        self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
        }
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
		}
	}
    
	void PrimaryAttack()
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
		m_pPlayer.m_iWeaponVolume	= 	NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash	=	0;
		
		++m_iShotCounter;
        
    	switch( FiringMode )
        {
            case 0:
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			self.SendWeaponAnim( GCMINIGUN_FIRE_NORMAL );
            if ( m_iShotCounter > 10 )
            {
            HUDTextParams textParams;
            	textParams.x = 0.513;
                textParams.y = 0.936;
                textParams.effect = 0;
                textParams.r1 = 255;
                textParams.g1 = 255;
                textParams.b1 = 0;
                textParams.channel = 1;
                g_PlayerFuncs.HudMessage( m_pPlayer, textParams, "WARNING" ); // DO NOT DELETE THIS FUCKING LINE; KCM
            }

			if ( m_iShotCounter > 5 )
			{
				SetElectricState ( true );
				//te_elight(m_pPlayer, m_pPlayer.GetAutoaimVector(0));
				//m_bOverHeating = true; 
			}
            NextAttack (0.3f); // play with this; KCM
            break; 
            
        	case 1:
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			self.SendWeaponAnim( GCMINIGUN_FIRE_LOOP );
            NextAttack (0.2f);

			self.pev.nextthink = WeaponTimeBase();
            break; 
		}
        		
        float	flMaxDistance	=	8192;
		Vector	vecSrc			=	m_pPlayer.GetGunPosition();
		Vector	vecDirShooting	=	m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
		
		// pulse mode is most accurate, so use zero vector
		FireBullets( 1, vecSrc, vecDirShooting, g_vecZero, flMaxDistance, BULLET_PLAYER_CUSTOMDAMAGE, 1, m_iPrimaryDamage, m_pPlayer.pev );
        
        // Copied from Insurgency weapons; give Kerncore credit - KCM
        ShellEject( m_pPlayer, m_iShell, Vector( 26, 6.5, -7.1 ));
		
		// light faster than sound!
		switch( Math.RandomLong(0,1) )
		{
			case 0 : PlayWeaponSound( m_szFireSound ); break;
            case 1 : PlayWeaponSound( m_szFireSound ); break;
		}
		
		V_PunchAxis( 0, -2.0 );
	}

    void SecondaryAttack()
	{
		if (GetAmmoAmount( AMMO_TYPE_PRIMARYAMMO ) <= 0)
		{
			PlayWeaponSound( m_szEmptySound );
			NextAttack( 3.0f );
			return;
		}

        m_bRapidModeEngaged = !m_bRapidModeEngaged;
        RapidFireMode();
	}

    void RapidFireMode()
    {
    if (m_bRapidModeEngaged == false)
                {
                    self.SendWeaponAnim( GCMINIGUN_SPIN_DOWN );
                    PlayWeaponSound( m_szSpinDownSound );
                    FiringMode = 0;
                    NextAttack( 2.3f );
                    NextIdle ( 4.0f );
                }
            else
                {
					//PlayWeaponSound( m_szFireModeToggle );
                    self.SendWeaponAnim( GCMINIGUN_SPIN_UP );
                    PlayWeaponSound( m_szSpinUpSound );
                    FiringMode = 1;
                    NextAttack( 2.3f );
                    NextIdle( 2.0f ); // Originally 2.0f
                }
    }

	void SetElectricState( const bool bState, const bool bForce = false )
	{
		if ( !m_bOverHeating == false ) {
		if( m_pPlayer is null )
			return;
			
		const int iBit = ( bState ? 1 : 0 ) << 6;
	
		NetworkMessage msg( MSG_ALL, NetworkMessages::CbElec ); // CbElec
			msg.WriteByte( iBit | m_pPlayer.entindex() );
		msg.End();
	} else {
		}
	}

	void te_elight(CBaseEntity@ target, Vector pos, float radius=1024.0f, 
	Color c=GREEN, uint8 life=16, float decayRate=2000.0f, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_ELIGHT);
	m.WriteShort(target.entindex());
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(radius);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(life);
	m.WriteCoord(decayRate);
	m.End();
}

};

void RegisterEntity_WeaponGCMinigun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_gcminigun", "weapon_gcminigun" );
	g_ItemRegistry.RegisterWeapon( "weapon_gcminigun", "gunmanchronicles", "9mm" );
};