#include "GC_ScriptBasePlayerWeaponEntity"

class weapon_vehicledriving : GC_BasePlayerWeapon
{
	// Constructor
	weapon_vehicledriving()
	{
		this.WorldModel		=	"models/gunmanchronicles/null.mdl";
		this.PlayerModel	=	"models/gunmanchronicles/null.mdl";
		this.ViewModel		=	"models/gunmanchronicles/null.mdl";
	}
	
	bool GetItemInfo(ItemInfo& out info)
	{
		info.iMaxAmmo1	= -1;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot		= 0;
		info.iPosition	= 10;
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname ); //self.m_iId;
		info.iFlags		= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
		info.iWeight	= 0;
		
		return true;
	}
	
	void Precache()
	{
		GC_BasePlayerWeapon::Precache();
		
		// Get some extra files
		PrecacheWeaponHudInfo( "gunmanchronicles/weapon_vehicledriving.txt" );
	}
	
	bool AddToPlayer(CBasePlayer@ pPlayer)
	{
		bool result = GC_BasePlayerWeapon::AddToPlayer( pPlayer ) && ( pPlayer.pev.flags & FL_IMMUNE_LAVA ) != 0;
		
		if( result )
		{
			pPlayer.SelectItem( string(self.pev.classname) );
		}
		else
		{
			Drop();
		}
		
		return result;
	}
	void Drop()
	{
		//BaseClass.Drop();
		
		g_EntityFuncs.Remove( self );
	}
	
	// Don't deploy when player is not driving!
	bool CanDeploy()
	{
		return ( m_pPlayer.pev.flags & FL_IMMUNE_LAVA ) != 0;
	}
	
	bool Deploy()
	{
		bool result = DefaultDeploy( 0, "trip" , 0, self.pev.body );
		
		if( result )
		{
			self.m_bExclusiveHold = true;
		}
		else
		{
			Drop();
		}
		
		return result;
	}
	
	// Don't holster when player is still driving!
	bool CanHolster()
	{
		return ( m_pPlayer.pev.flags & FL_IMMUNE_LAVA ) == 0;
	}
	
	void Holster( int iSkipLocal = 0 )
	{
		if( !CanHolster() )
			return;
		
		self.m_fInReload = false;// cancel any reload in progress.

		m_pPlayer.m_flNextAttack	= WeaponTimeBase() + 0.5f;
		
		BaseClass.Holster( iSkipLocal );
		//Drop();
	}
	
	void PrimaryAttack()
	{
		NextAttack(0.f);
	}
	
	void SecondaryAttack()
	{
		PrimaryAttack();
	}
	
	void TertiaryAttack()
	{
		PrimaryAttack();
	}
	
};

void RegisterEntity_WeaponVehicleDriving()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_vehicledriving", "weapon_vehicledriving" );
	g_ItemRegistry.RegisterWeapon( "weapon_vehicledriving", "gunmanchronicles" );
};
