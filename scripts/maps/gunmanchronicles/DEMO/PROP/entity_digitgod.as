class entity_digitgod : ScriptBaseEntity
{
	private EHandle[]	m_hSprites;
	private float		m_flCountedDmg;
	private float		m_flMaxDmg;
	private bool		m_blTriggered;
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "maxdamage" )
		{
			m_flMaxDmg = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		g_Game.PrecacheModel( "models/gunmanchronicles/digits.mdl" );
	}
	
	void Spawn()
	{
		Precache();
		
		BaseClass.Spawn();
		
		self.pev.solid			= SOLID_NOT;
		self.pev.movetype		= MOVETYPE_NONE;
		self.pev.takedamage		= DAMAGE_NO;
		
		CreateSprites();
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		BaseClass.Use( pActivator, pCaller, useType, flValue );
		
		//g_Game.AlertMessage( at_console, "flValue = %1 \n", flValue );
		
		if( useType != USE_SET )
		{
			ResetCounter();
		}
		else
		{
			m_flCountedDmg = Math.clamp( 0.0f, 999.0f, m_flCountedDmg + flValue ) ;
		}
		
		UpdateCounter();
		
		if( !m_blTriggered && m_flCountedDmg >= m_flMaxDmg )
		{
			m_blTriggered = true;
			self.SUB_UseTargets( pActivator, useType, flValue );
		}
		
		//g_Game.AlertMessage( at_console, "m_flCountedDmg = %1 \n", m_flCountedDmg );
	}
	
	void UpdateOnRemove()
	{
		DestroySprites();
		
		BaseClass.UpdateOnRemove();
	}
	
	void UpdateCounter()
	{
		int[] digits;
		
		int n = int( m_flCountedDmg );
		do {
			int digit = n % 10;
			digits.insertLast( digit );
			n /= 10;
		} while (n > 0);
		
		//g_Game.AlertMessage(at_console, "m_hSprites length = %1.\n", m_hSprites.length() );
        
     	if( m_hSprites[0].IsValid() ) m_hSprites[0].GetEntity().pev.skin = ( digits.length() > 0 ? digits[0] : 0 );
		if( m_hSprites[1].IsValid() ) m_hSprites[1].GetEntity().pev.skin = ( digits.length() > 1 ? digits[1] : 0 );
		if( m_hSprites[2].IsValid() ) m_hSprites[2].GetEntity().pev.skin = ( digits.length() > 2 ? digits[2] : 0 );
	}
	
	void ResetCounter()
	{
		m_blTriggered = false;
		m_flCountedDmg = 0.0f;
	}
	
	void DestroySprites()
	{
		for( uint i = 0; i < m_hSprites.length(); i++ )
		{
			if( m_hSprites[i].IsValid() )
			{
				g_EntityFuncs.Remove( m_hSprites[i].GetEntity() );
				m_hSprites[i] = null;
			}
		}
	}
	
	void CreateSprites()
	{
		DestroySprites();
		
		Math.MakeVectors( self.pev.angles );
		Vector vecRight = g_Engine.v_right.opMul( -16.0 );
		Vector vecLeft  = g_Engine.v_right.opMul(  16.0 );
		
		do
		{
			Vector vecOrigin = g_vecZero;
			switch( m_hSprites.length() )
			{
				case 0: vecOrigin = self.pev.origin + vecRight; break;
				case 1: vecOrigin = self.pev.origin; break;
				case 2: vecOrigin = self.pev.origin + vecLeft; break;
			}
			
			CSprite@ pEnt = g_EntityFuncs.CreateSprite( "models/gunmanchronicles/digits.mdl", vecOrigin, false );
			
			if( pEnt is null )
			{
				g_Game.AlertMessage(at_console, "Counter Sprite is NULL, breaks the loop... %1.\n", m_hSprites.length() );
				break;
			}
			
			pEnt.pev.angles = self.pev.angles;
			pEnt.TurnOn();
			
			m_hSprites.insertLast( EHandle(pEnt) );
		} while( m_hSprites.length() < 3 );
	}
}

void RegisterEntity_DigitGod()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "entity_digitgod", "entity_digitgod" );
}
