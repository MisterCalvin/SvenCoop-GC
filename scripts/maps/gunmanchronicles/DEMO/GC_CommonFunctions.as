#include "GC_CommonConstants"
#include "GC_CommonMixins"
#include "GC_TEFunctions"
#include "GC_PevClonerAndCopier"

void PrecacheGenericSound( const string &in soundfile )
{
	if( !soundfile.IsEmpty() )
	{
		g_SoundSystem.PrecacheSound( soundfile );
		g_Game.PrecacheGeneric( "sound/" + soundfile );
	}
}

void PrecacheWeaponHudInfo( const string &in filePath )
{
	g_Game.PrecacheGeneric( "sprites/" + filePath );
}

void DecalGunshotNoRicochet( TraceResult &in pTrace, Bullet iBulletType )
{
	CBaseEntity@ pEntity = g_EntityFuncs.Instance( pTrace.pHit );
	
	// Is the entity valid
	if( pEntity is null )
		return;

	if( pEntity.pev.solid == SOLID_BSP || pEntity.pev.movetype == MOVETYPE_PUSHSTEP )
	{
		// Decal the wall with a gunshot
		switch( iBulletType )
		{
		case BULLET_PLAYER_CROWBAR:
		{
			// wall decal
			g_Utility.DecalTrace( pTrace, DamageDecal( pEntity, DMG_CLUB ) );
			break;
		}
		default:
		{
			// smoke and decal
			g_Utility.DecalTrace( pTrace, DamageDecal( pEntity, DMG_BULLET ) );
		}
		}
	}
}

void DecalGunshot( TraceResult &in pTrace, Bullet iBulletType )
{
	g_WeaponFuncs.DecalGunshot( pTrace, iBulletType );
}

int DamageDecal( CBaseEntity@ pEntity, int bitsDamageType )
{
	return g_WeaponFuncs.DamageDecal( @pEntity, bitsDamageType );
}

//
// RadiusDamage - this entity is exploding, or otherwise needs to inflict damage upon entities within a certain range.
// 
// only damage ents that can clearly be seen by the explosion!
void RadiusDamage( Vector vecSrc, entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, float flRadius, int iClassIgnore = CLASS_NONE, int bitsDamageType = DMG_BLAST, bool accurateDamage = true )
{
	if( accurateDamage )
	{
		// use default function instead
		g_WeaponFuncs.RadiusDamage( vecSrc, pevInflictor, pevAttacker, flDamage, flRadius, iClassIgnore, bitsDamageType );
		return;
	}
	
	CBaseEntity@ pEntity = null;
	TraceResult	tr;
	Vector		vecSpot;

	bool bInWater = ( g_EngineFuncs.PointContents( vecSrc ) == CONTENTS_WATER );

	vecSrc.z += 1;// in case grenade is lying on the ground

	if( pevAttacker is null )
		@pevAttacker = @pevInflictor;

	// iterate on all entities in the vicinity.
	while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( @pEntity, vecSrc, flRadius, "*", "classname" ) ) !is null )
	{		
		if( pEntity.pev.takedamage != DAMAGE_NO )
		{
			// UNDONE: this should check a damage mask, not an ignore
			if( iClassIgnore != CLASS_NONE && pEntity.Classify() == iClassIgnore )
			{
				// houndeyes don't hurt other houndeyes with their attack
				//g_Game.AlertMessage( at_console, "RadiusDamage() Ignored Class!\n" );
				continue;
			}

			// blast's don't tavel into or out of water
			if( (bInWater && pEntity.pev.waterlevel == WATERLEVEL_DRY) || (!bInWater && pEntity.pev.waterlevel == WATERLEVEL_HEAD) )
			{
				//g_Game.AlertMessage( at_console, "RadiusDamage() Out of Range! (WaterLevel)\n" );
				continue;
			}

			vecSpot = pEntity.BodyTarget( vecSrc );

			g_Utility.TraceLine( vecSrc, vecSpot, dont_ignore_monsters, pevInflictor.get_pContainingEntity(), tr );

			if( tr.flFraction == 1.0 || tr.pHit is pEntity.edict() )
			{
				// the explosion can 'see' this entity, so hurt them!
				if( tr.fStartSolid > 0 )
				{
					// if we're stuck inside them, fixup the position and distance
					tr.vecEndPos = vecSrc;
					tr.flFraction = 0.0;
				}
				
				if( tr.flFraction != 1.0 && pEntity.pev.solid != SOLID_BSP && pEntity.pev.solid != SOLID_TRIGGER )
				{
					//g_Game.AlertMessage( at_console, "[TraceAttack] hit %1 dmg %2\n", string( pEntity.pev.classname ), flDamage );
					
					g_WeaponFuncs.ClearMultiDamage();
					pEntity.TraceAttack( pevInflictor, flDamage, ( tr.vecEndPos - vecSrc ).Normalize(), tr, bitsDamageType );
					g_WeaponFuncs.ApplyMultiDamage( pevInflictor, pevAttacker );
				}
				else
				{
					//g_Game.AlertMessage( at_console, "[TakeDamage] hit %1 dmg %2\n", string( pEntity.pev.classname ), flDamage );
					
					pEntity.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
				}
			}
		}
	}
}

// https://forums.alliedmods.net/showpost.php?p=684928&postcount=4
bool is_user_stuck( entvars_t@ pevUser, const Vector &in origin )
{
  if( g_EngineFuncs.PointContents( origin ) == CONTENTS_SOLID ) return true;
  
  Vector maxs = pevUser.maxs;
  
  Vector[] origins(12);
  
  // four centers of the four side planes
  origins[0].x = origin.x;
  origins[0].y = origin.y + maxs.y;
  origins[0].z = origin.z;
  origins[1].x = origin.x + maxs.x;
  origins[1].y = origin.y;
  origins[1].z = origin.z;
  origins[2].x = origin.x;
  origins[2].y = origin.y - maxs.y;
  origins[2].z = origin.z;
  origins[3].x = origin.x - maxs.x;
  origins[3].y = origin.y;
  origins[3].z = origin.z;
  
  // top four corners
  origins[4].x = origin.x + maxs.x;
  origins[4].y = origin.y + maxs.y;
  origins[4].z = origin.z + maxs.z;
  origins[5].x = origin.x - maxs.x;
  origins[5].y = origin.y + maxs.y;
  origins[5].z = origin.z + maxs.z;
  origins[6].x = origin.x + maxs.x;
  origins[6].y = origin.y - maxs.y;
  origins[6].z = origin.z + maxs.z;
  origins[7].x = origin.x - maxs.x;
  origins[7].y = origin.y - maxs.y;
  origins[7].z = origin.z + maxs.z;
  
  // bottom four corners
  origins[8].x = origin.x + maxs.x;
  origins[8].y = origin.y + maxs.y;
  origins[8].z = origin.z - maxs.z;
  origins[9].x = origin.x - maxs.x;
  origins[9].y = origin.y + maxs.y;
  origins[9].z = origin.z - maxs.z;
  origins[10].x = origin.x + maxs.x;
  origins[10].y = origin.y - maxs.y;
  origins[10].z = origin.z - maxs.z;
  origins[11].x = origin.x - maxs.x;
  origins[11].y = origin.y - maxs.y;
  origins[11].z = origin.z - maxs.z;
  
  for( uint i = 0; i < origins.length; i++ )
  {
    if( g_EngineFuncs.PointContents( origins[i] ) == CONTENTS_SOLID )
    {
      return true;
    }
  }
  
  return false;
}

Vector AnglesMod( Vector &in vecAngles )
{
	Vector temp;
	temp.x = Math.AngleMod( vecAngles.x );
	temp.y = Math.AngleMod( vecAngles.y );
	temp.z = Math.AngleMod( vecAngles.z );
	return temp;
}

/*CSoundEnt@ SoundEnt()
{
	return cast<CSoundEnt@>( g_hSoundEnt.GetEntity() );
}
*/
