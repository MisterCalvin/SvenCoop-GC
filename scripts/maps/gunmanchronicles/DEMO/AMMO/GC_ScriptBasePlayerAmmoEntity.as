#include "../GC_CommonFunctions"

abstract class GC_ScriptBasePlayerAmmoEntity : ScriptBasePlayerAmmoEntity, ItemGlowEffect
{
	private string	m_szAmmoType;
	private int 	m_iAmmoGiveAmount;
	private int 	m_iAmmoMaxCarry;
	
	string AmmoType
	{
		get const { return m_szAmmoType; }
		set { m_szAmmoType = value; }
	}
	
	int AmmoGiveAmount
	{
		get const { return m_iAmmoGiveAmount; }
		set { m_iAmmoGiveAmount = value; }
	}
	
	int AmmoMaxCarry
	{
		get const { return m_iAmmoMaxCarry; }
		set { m_iAmmoMaxCarry = value; }
	}
	
	void Precache()
	{
		BaseClass.Precache();
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}
	
	void Spawn()
	{
		BaseClass.Spawn();
		
		self.pev.nextthink = g_Engine.time + 0.1;
	}
	
	void Think()
	{
		BaseClass.Think();
		
		GlowThink();
	}
	
	bool AddAmmo( CBaseEntity@ pOther )
	{
		if( pOther.GiveAmmo( m_iAmmoGiveAmount, m_szAmmoType, m_iAmmoMaxCarry ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}