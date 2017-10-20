#include "../GC_CommonFunctions"

class entity_spritegod : ScriptBaseEntity
{
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "spritename" )
		{
			self.pev.model = szValue;
			return true;
		}
		else if ( szKey == "spritespeed" )
		{
			self.pev.speed = atof( szValue );
			return true;
		}
		else if ( szKey == "spritecount" )
		{
			self.pev.iuser1  = atoi( szValue );
			return true;
		}
		else if ( szKey == "spritefreq" )
		{
			self.pev.iuser2  = atoi( szValue );
			return true;
		}
		else if ( szKey == "spritenoise" )
		{
			self.pev.iuser3 = atoi( szValue );
			return true;
		}
		else if ( szKey == "spritez" )
		{
			self.pev.movedir.x = atof( szValue );
			return true;
		}
		else if ( szKey == "spritey" )
		{
			self.pev.movedir.y = atof( szValue );
			return true;
		}
		else if ( szKey == "spritex" )
		{
			self.pev.movedir.z = atof( szValue );
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

		//self.pev.nextthink		+= 1.0;
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
	{
		if( self.pev.nextthink == 0.0f )
			self.pev.nextthink = g_Engine.time + 0.1;
		else
			self.pev.nextthink = 0.0f;
	}
	
	void Think()
	{
		self.pev.nextthink = g_Engine.time + 0.1;
		
		Vector vecAngles = Math.VecToAngles( self.pev.movedir );
		vecAngles.x = -vecAngles.x;
		vecAngles.y += 90.0f;
		//vecAngles.z = -vecAngles.z;
		g_EngineFuncs.MakeVectors( vecAngles );
		Vector vecVelo = g_Engine.v_forward * 1.25;
		
		uint8 countRandom = self.pev.iuser1 + Math.RandomLong( 0, self.pev.iuser2 );
		
		CreateTempEnt_SpriteSpray( self.pev.origin, vecVelo, self.pev.model, countRandom, uint8(self.pev.speed), uint8(self.pev.iuser3) );
	}
}

void RegisterEntity_EntitySpriteGod()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "entity_spritegod", "entity_spritegod" );
}
