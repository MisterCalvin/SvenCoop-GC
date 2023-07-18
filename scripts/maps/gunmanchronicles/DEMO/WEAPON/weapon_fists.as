#include "GC_ScriptBasePlayerWeaponEntity"

enum fists_anim
{
	FISTS_IDLE 				= 0,
	FISTS_IDLEJUDO,
	FISTS_IDLEKICKASS,
	FISTS_RIGHTPUNCH,
	FISTS_LEFTPUNCH,
	FISTS_DOUBLEPUNCH,
	FISTS_READY,
	FISTS_HOLSTER,
	FISTS_KNIFEDRAW,
	FISTS_KNIFEHOLSTER,
	FISTS_IDLEKNIFE,
	FISTS_IDLEKNIFEINSPECT,
	FISTS_KNIFEATTACK1,
	FISTS_KNIFEATTACK2
};

enum fists_bg
{
	FISTS_BG		= 0,
	KNIFE_BG
};

string w_model = "models/gunmanchronicles/w_knife.mdl";
string v_model = "models/gunmanchronicles/v_hands.mdl";
string p_model = "models/gunmanchronicles/p_crowbar.mdl";
//string p_model = "models/gunmanchronicles/p_testt.mdl";

class weapon_fists : GC_BasePlayerWeapon
{
	private string	m_szKnifeAttack1		= 	"gunmanchronicles/weapons/KnifeAttack1.wav";
	private string	m_szKnifeAttack1b		= 	"gunmanchronicles/weapons/KnifeAttack1b.wav";
	private string	m_szKnifeAttack2		= 	"gunmanchronicles/weapons/KnifeAttack2.wav";
	private string	m_szKnifeAttack2b		= 	"gunmanchronicles/weapons/KnifeAttack2b.wav";
	private string	m_szKnifeDraw			= 	"gunmanchronicles/weapons/KnifeDraw.wav";
	private string	m_szKnifeHolster		= 	"gunmanchronicles/weapons/KnifeHolster.wav";
	private string	m_szLeftPunch			= 	"gunmanchronicles/weapons/LeftPunch.wav";
	private string	m_szLeftPunch2			= 	"gunmanchronicles/weapons/LeftPunch2.wav";
	private string	m_szLeftPunch3			= 	"gunmanchronicles/weapons/LeftPunch3.wav";
	private string	m_szRightPunch			= 	"gunmanchronicles/weapons/RightPunch.wav";
	private string	m_szRightPunch2			= 	"gunmanchronicles/weapons/RightPunch2.wav";
	private string	m_szRightPunch3			= 	"gunmanchronicles/weapons/RightPunch3.wav";
	private string	m_szHandsIdleKickass	=	"gunmanchronicles/weapons/Hands_IdleKickAss_F0.wav";

	private	bool	m_bWeaponToggle		=	false;
	private	int		m_iCurBodyConfig	=	0;

	    array<int> m_bodyparts = { 0, 1, 1 };
	
	weapon_fists()
	{
		this.WorldModel		=	w_model;
		this.PlayerModel	=	p_model;
		this.ViewModel		=	v_model;
		
		this.m_iPrimaryDamage			=	8; // Fists
	}
	
	bool GetItemInfo(ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;

		//info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags		= ITEM_FLAG_SELECTONEMPTY;
		return true;
	}
	
	void Precache()
	{
		GC_BasePlayerWeapon::Precache();
		
		// HUD Items
		PrecacheWeaponHudInfo( "gunmanchronicles/weapon_fists.txt" );
		//PrecacheWeaponHudInfo( "gunmanchronicles/crosshairs.spr" );

		g_Game.PrecacheModel( w_model );
		g_Game.PrecacheModel( p_model );
		g_Game.PrecacheModel( v_model );
        
		PrecacheGenericSound( m_szKnifeAttack1 );
		PrecacheGenericSound( m_szKnifeAttack1b );
		PrecacheGenericSound( m_szKnifeAttack2 );
		PrecacheGenericSound( m_szKnifeAttack2b );
		PrecacheGenericSound( m_szKnifeDraw );
		PrecacheGenericSound( m_szKnifeHolster );
		PrecacheGenericSound( m_szLeftPunch );
		PrecacheGenericSound( m_szLeftPunch2 );
		PrecacheGenericSound( m_szLeftPunch3 );
		PrecacheGenericSound( m_szRightPunch );
		PrecacheGenericSound( m_szRightPunch2 );
		PrecacheGenericSound( m_szRightPunch3 );
		PrecacheGenericSound( m_szHandsIdleKickass );
	}
	
	void Spawn()
	{
		GC_BasePlayerWeapon::Spawn();
	}
	
	void Think()
	{
		BaseClass.Think();
	}
	
	bool Deploy()
	{  
		NextIdle( 3.0f );

		if ( m_bWeaponToggle = false )
		{
			return DefaultDeploy( FISTS_READY, "onehanded", 0, 0 );
			//return DefaultDeploy( v_model, p_model, FISTS_READY, "onehanded", 0, 0);
		}
		else
		{
			PlayWeaponSound( m_szKnifeDraw );
			return DefaultDeploy( FISTS_KNIFEDRAW, "onehanded", 0, 1 );
			//return DefaultDeploy( v_model, p_model, FISTS_KNIFEDRAW, "onehanded", 0, 1);	
		}
	}
	
	void Holster( int skipLocal )
	{
		if ( m_bWeaponToggle = false )
		{
			self.SendWeaponAnim( FISTS_HOLSTER, skipLocal, 0 );
		}
		else 
		{
			PlayWeaponSound( m_szKnifeHolster );
			self.SendWeaponAnim( FISTS_KNIFEHOLSTER, skipLocal, 1 );
		}

		GC_BasePlayerWeapon::Holster( skipLocal );
	}
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() ) 
		return;

    	if( m_bWeaponToggle == false )
        {
				switch( Math.RandomLong(0,2) )
				{
					case 0 : self.SendWeaponAnim( FISTS_IDLE, 0, 0 ); break;
					case 1 : self.SendWeaponAnim( FISTS_IDLEJUDO, 0, 0 ); break;
					case 2 : PlayWeaponSound( m_szHandsIdleKickass ); self.SendWeaponAnim( FISTS_IDLEKICKASS ); break;
				}
		}

		if( m_bWeaponToggle == true )
			{
				switch( Math.RandomLong(0,1) )
				{
					case 0 : self.SendWeaponAnim( FISTS_IDLEKNIFE, 0, 1 ); break;
					case 1 : self.SendWeaponAnim( FISTS_IDLEKNIFEINSPECT, 0, 1 ); break;
				}
			
			}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
    
	void PrimaryAttack()
	{
    	if ( m_bWeaponToggle == false )
        {
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			self.SendWeaponAnim( FISTS_LEFTPUNCH, 0, 0 );
			LeftPunch();
            NextAttack (0.5f);
			self.pev.nextthink = WeaponTimeBase();
		}
		else
		{
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			self.SendWeaponAnim( FISTS_KNIFEATTACK1, 0, 1 );
            NextAttack (0.6f);
			self.pev.nextthink = WeaponTimeBase();
		}
		//V_PunchAxis( 0, -2.0 ); // Update this; KCM
	}

    void SecondaryAttack ()
	{
		m_bWeaponToggle = !m_bWeaponToggle;

		if ( m_bWeaponToggle == false )
		{
			PlayWeaponSound( m_szKnifeHolster );
			self.SendWeaponAnim( FISTS_KNIFEHOLSTER, 0, 1 );
			self.SendWeaponAnim( FISTS_READY, 0, 0 );
		}
		else 
		{
			//SetBodygroup( 1, 1 );
			self.SendWeaponAnim( FISTS_HOLSTER, 0, 0 );
			self.SendWeaponAnim( FISTS_KNIFEDRAW, 0, 1 );
		}

		NextAttack( 1.0f );
	}
    
    void LeftPunch()
	{
		switch( Math.RandomLong(0,2) )
		{
			case 0 : PlayWeaponSound( m_szLeftPunch ); break;
			case 1 : PlayWeaponSound( m_szLeftPunch2 ); break;
			case 2 : PlayWeaponSound( m_szLeftPunch3 ); break;
		}
	}

	void RightPunch()
	{

		switch( Math.RandomLong(0,2) )
		{
			case 0 : PlayWeaponSound( m_szRightPunch ); break;
			case 1 : PlayWeaponSound( m_szRightPunch2 ); break;
			case 2 : PlayWeaponSound( m_szRightPunch3 ); break;
		}

	}

	void KnifeSlash()
	{
		switch( Math.RandomLong(0,3) )
		{
			case 0 : PlayWeaponSound( m_szKnifeAttack1 ); break;
			case 1 : PlayWeaponSound( m_szKnifeAttack1b ); break;
			case 2 : PlayWeaponSound( m_szKnifeAttack2 ); break;
			case 3 : PlayWeaponSound( m_szKnifeAttack2b ); break;
		}

	}

		void SetElectricState( const bool bState, const bool bForce = false )
	{
		
		if( m_pPlayer is null )
			return;
			
		const int iBit = ( bState ? 1 : 0 ) << 6;
	
		NetworkMessage msg( MSG_ALL, NetworkMessages::CbElec );
			msg.WriteByte( iBit | m_pPlayer.entindex() );
		msg.End();
	}
};

void RegisterEntity_WeaponFists()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_fists", "weapon_fists" );
	g_ItemRegistry.RegisterWeapon( "weapon_fists", "gunmanchronicles", "NULL" );
};