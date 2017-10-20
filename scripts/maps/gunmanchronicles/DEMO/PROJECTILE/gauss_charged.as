#include "GC_ScriptBaseProjectileEntity"

class gauss_charged : GC_BaseProjectile, WallHitEffect
{
	private	string	m_szDetonatedSound	=	"gunmanchronicles/weapons/gauss_spritebig.wav";
	
	// Constructor
	gauss_charged()
	{
		this.WorldModel				=	"sprites/gunmanchronicles/gausswomp.spr";
		this.TrailModel				=	"sprites/gunmanchronicles/gaussbeam2.spr";
		this.ProjectileDetonation	=	PROJECTILE_KILL_IMPACT;
		
		this.m_bUseTrail			=	true;
	}
	
	void Precache()
	{
		GC_BaseProjectile::Precache();
		
		PrecacheWallHitEffect();
		
		PrecacheGenericSound( m_szDetonatedSound );
	}
	
	void Spawn()
	{
		self.pev.movetype	= MOVETYPE_FLY;
		self.pev.solid		= SOLID_BBOX;
		
		GC_BaseProjectile::Spawn();
		
		g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ) );
		
		SetTransparency( kRenderTransAdd, 255, 255, 255, 255, kRenderFxNone );
		
		MoveForward();
	}
	
	void Think()
	{
		GC_BaseProjectile::Think();
		
		CreateTempEnt_SpriteTrail( self.pev.origin, self.pev.origin, m_szWallSpark, Math.RandomLong( 3, 8 ), 0, 1, 16, 8 );
	}
	
	void DetonateOnImpact(CBaseEntity@ pOther)
	{
		// Toucher is the owner
		if( pOther.edict() is self.pev.owner || pOther.pev.solid == SOLID_TRIGGER )
		{
			BaseClass.Touch(@pOther);
			return;
		}
		
		RadiusDamage( self.pev.origin, self.pev, self.pev.owner.vars, self.pev.dmg, self.pev.fov, CLASS_NONE, DMG_BLAST, false );
		
		EmitSoundDyn( m_szDetonatedSound );
		
		Vector vecStart = self.pev.origin;
		Math.MakeVectors( self.pev.angles );
		Vector vecEnd   = vecStart + g_Engine.v_forward;
		
		BaseClass.Touch(@pOther);
		self.Killed( self.pev, GIB_NORMAL );
		
		TraceResult tr;
		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, dont_ignore_glass, self.edict(), tr );
		
		g_Utility.DecalTrace( tr, DECAL_GARGSTOMP1 );
		
		//CreateTempEnt_Box( tr.vecEndPos + Vector(-1,-1,-1),	tr.vecEndPos + Vector(1,1,1), 32, GREEN );
		
		//switch( Math.RandomLong( 0, 2 ) )
		//{
		//	case 0: g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 ); break;
		//	case 1: g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH2 ); break;
		//	case 2: g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH3 ); break;
		//}
		
		// Pull out of the wall a bit
		if( tr.flFraction != 1.0 )
		{
			tr.vecEndPos = tr.vecEndPos.opAdd( tr.vecPlaneNormal );
		}
		CreateWallHitEffectBig( tr.vecEndPos );
	}
	
}

void RegisterEntity_ProjectileGaussCharged()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "gauss_charged", "gauss_charged" );
};
