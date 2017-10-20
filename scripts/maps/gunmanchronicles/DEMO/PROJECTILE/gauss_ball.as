#include "GC_ScriptBaseProjectileEntity"

class gauss_ball : GC_BaseProjectile, WallHitEffect
{
	private	string	m_szDetonatedSound	=	"gunmanchronicles/weapons/gauss_spritesmall.wav";
	
	// Constructor
	gauss_ball()
	{
		this.WorldModel				=	"sprites/gunmanchronicles/gausswomp.spr";
		this.TrailModel				=	"sprites/gunmanchronicles/gaussbeam3.spr";
		this.ProjectileDetonation	=	PROJECTILE_KILL_IMPACT;
		
		this.m_bUseTrail			=	true;
		this.m_uiTrailWidth			=	3;
		this.m_uiTrailLife			=	2;
		this.m_cTrailColor			=	WHITE;
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
		
		self.pev.scale		=	0.25f;
		
		g_EntityFuncs.SetSize( self.pev, Vector( -3, -3, -3 ), Vector( 3, 3, 3 ) );
		
		SetTransparency( kRenderTransAdd, 255, 255, 255, 255, kRenderFxNone );
		
		MoveForward();
	}
	
	void DetonateOnImpact(CBaseEntity@ pOther)
	{
		// Toucher is the owner
		if( pOther.edict() is self.pev.owner || pOther.pev.solid == SOLID_TRIGGER )
		{
			BaseClass.Touch(@pOther);
			return;
		}
		
		TraceResult tr;
		
		if( pOther.pev.takedamage != DAMAGE_NO )
		{
			// Draw Blood...
			entvars_t@ pevAttacker  = self.pev.owner.vars;
			entvars_t@ pevInflictor = self.pev;
			Vector vecStart= self.pev.origin;
			Vector vecSpot = pOther.BodyTarget( vecStart );
			g_Utility.TraceLine( vecStart, vecSpot, dont_ignore_monsters, dont_ignore_glass, null, tr );
			
			if( tr.flFraction == 1.0 || tr.pHit is pOther.edict() )
			{
				// the explosion can 'see' this entity, so hurt them!
				if( tr.fStartSolid > 0 )
				{
					// if we're stuck inside them, fixup the position and distance
					tr.vecEndPos = vecStart;
					tr.flFraction = 0.0;
				}
				
				if( tr.flFraction != 1.0 )
				{
					//g_Game.AlertMessage( at_console, "[TraceAttack] hit %1 dmg %2\n", string( pOther.pev.classname ), self.pev.dmg );
					
					g_WeaponFuncs.ClearMultiDamage();
					pOther.TraceAttack( pevInflictor, self.pev.dmg, ( tr.vecEndPos - vecStart ).Normalize(), tr, DMG_ENERGYBEAM );
					g_WeaponFuncs.ApplyMultiDamage( pevInflictor, pevAttacker );
				}
				else
				{
					//g_Game.AlertMessage( at_console, "[TakeDamage] hit %1 dmg %2\n", string( pOther.pev.classname ), self.pev.dmg );
					
					pOther.TakeDamage( pevInflictor, pevAttacker, self.pev.dmg, DMG_ENERGYBEAM );
				}
			}
		}
		
		EmitSoundDyn( m_szDetonatedSound );
		
		Vector vecStart = self.pev.origin;
		Math.MakeVectors( self.pev.angles );
		Vector vecEnd   = vecStart + g_Engine.v_forward;
		
		BaseClass.Touch(@pOther);
		self.Killed( self.pev, GIB_NORMAL );
		
		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, dont_ignore_glass, null, tr );
		
		//DecalGunshotNoRicochet( tr, BULLET_PLAYER_CUSTOMDAMAGE );
		
		// WallPuff for BSP object only!
		//if( tr.pHit.vars.solid == SOLID_BSP || tr.pHit.vars.movetype == MOVETYPE_PUSHSTEP )
		{
			switch( Math.RandomLong( 0, 4 ) )
			{
				case 0: g_Utility.DecalTrace( tr, DECAL_BIGSHOT1 ); break;
				case 1: g_Utility.DecalTrace( tr, DECAL_BIGSHOT2 ); break;
				case 2: g_Utility.DecalTrace( tr, DECAL_BIGSHOT3 ); break;
				case 3: g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 ); break;
				case 4: g_Utility.DecalTrace( tr, DECAL_BIGSHOT5 ); break;
			}
			
			// Pull out of the wall a bit
			if( tr.flFraction != 1.0 )
			{
				tr.vecEndPos = tr.vecEndPos.opAdd( tr.vecPlaneNormal );
			}
			CreateTempEnt_Sprite( tr.vecEndPos, m_szWallPuff, 2 );
		}
	}
	
}

void RegisterEntity_ProjectileGaussRapid()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "gauss_ball", "gauss_ball" );
};
