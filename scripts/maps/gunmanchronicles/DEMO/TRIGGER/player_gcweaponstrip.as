enum weaponstrip_iAffected
{
	WEAPONSTRIP_AFFECTED_ACTIVATOR = 0,
	WEAPONSTRIP_AFFECTED_ALL,
	WEAPONSTRIP_AFFECTED_NOTACTIVATOR
};

enum gcweaponstrip_sf
{
	SF_GCWEAPONSTRIP_NORESPAWN	=	1
};

class player_gcweaponstrip : ScriptBaseEntity
{
	int		m_iAffected;
	EHandle	m_hStrip;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "m_iAffected" )
		{
			m_iAffected = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Spawn()
	{
		self.Precache();

		self.pev.solid			= SOLID_NOT;
		self.pev.movetype		= MOVETYPE_NONE;
		self.pev.takedamage		= DAMAGE_NO;
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
	{
		CreateWeaponStrip();
		CBaseEntity@ pEnt = m_hStrip.GetEntity();
		//bool extraCondition = true;
		
		if( pEnt !is null )
		{
			pEnt.Use( @pActivator, @pCaller, useType, flValue );
			g_EntityFuncs.Remove( pEnt );
			
			CBasePlayer@ pPlayer = null;
			
			switch( m_iAffected )
			{
				case WEAPONSTRIP_AFFECTED_ALL:
				{
					for( uint i = 1; i < uint( g_Engine.maxClients-1 ); i++ )
					{
						@pPlayer = cast<CBasePlayer@>( g_EntityFuncs.Instance( i ) );
						if( pPlayer !is null && pPlayer.IsAlive() )
						{
							pPlayer.SetItemPickupTimes( 0.0f );
							GiveNamedItem( pPlayer.pev, "weapon_crowbar" );
							GiveNamedItem( pPlayer.pev, "weapon_medkit"  );
						}
					}
					break;
				}
				case WEAPONSTRIP_AFFECTED_NOTACTIVATOR:
				{
					for( uint i = 1; i < uint( g_Engine.maxClients-1 ); i++ )
					{
						@pPlayer = cast<CBasePlayer@>( g_EntityFuncs.Instance( i ) );
						if( pPlayer !is null && pActivator !is null && pPlayer !is pActivator && pPlayer.IsAlive() )
						{
							pPlayer.SetItemPickupTimes( 0.0f );
							GiveNamedItem( pPlayer.pev, "weapon_crowbar" );
							GiveNamedItem( pPlayer.pev, "weapon_medkit"  );
						}
					}
					break;
				}
				default:
				{
					@pPlayer = cast<CBasePlayer@>( @pActivator );
					if( pPlayer !is null && pPlayer.IsAlive() )
					{
						pPlayer.SetItemPickupTimes( 0.0f );
						GiveNamedItem( pPlayer.pev, "weapon_crowbar" );
						GiveNamedItem( pPlayer.pev, "weapon_medkit"  );
					}
				}
			}
		}
	}
	
	void CreateWeaponStrip()
	{
		if( m_hStrip.GetEntity() !is null )
			return;
		
		CBaseEntity@ pEnt = g_EntityFuncs.Create( "player_weaponstrip", self.pev.origin, Vector(0, 0, 0), true );
		
		if( pEnt is null )
			return;
		
		//g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "targetname", self.pev.targetname );
		g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "m_iAffected", m_iAffected );
		g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "spawnflags", self.pev.spawnflags );
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		
		m_hStrip = EHandle( @pEnt );
	}
	
	void GiveNamedItem( entvars_t@ playerPev, const string &in itemName )
	{
		CBaseEntity@ pEnt = g_EntityFuncs.Create( itemName, playerPev.origin, Vector(0, 0, 0), true );
		
		if( pEnt is null )
			return;
		
		pEnt.pev.origin      = playerPev.origin;
		
		if( self.pev.impulse & SF_GCWEAPONSTRIP_NORESPAWN != 0 )
			pEnt.pev.spawnflags |= SF_DELAYREMOVE | SF_GIVENITEM | SF_CREATEDWEAPON;

		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		//g_EntityFuncs.DispatchTouch( pent, playerPev );
		
		//pEnt.pev.flags		|= FL_KILLME;
	}
	
	void UpdateOnRemove()
	{
		if( m_hStrip.IsValid() )
			g_EntityFuncs.Remove( m_hStrip.GetEntity() );
		
		BaseClass.UpdateOnRemove();
	}
}

void RegisterEntity_PlayerGCWeaponStrip()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "player_gcweaponstrip", "player_gcweaponstrip" );
}
