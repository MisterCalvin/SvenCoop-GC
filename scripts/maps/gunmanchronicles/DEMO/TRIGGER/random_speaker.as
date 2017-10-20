class random_speaker : ScriptBaseEntity
{
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "random" )
		{
			self.pev.impulse = atoi( szValue );
			return true;
		}
		else if ( szKey == "volume" )
		{
			self.pev.health = atof( szValue );
			return true;
		}
		else if ( szKey == "rsnoise" )
		{
			self.pev.message = szValue;
			return true;
		}
		else if ( szKey == "wait" )
		{
			self.pev.dmgtime = atof( szValue );
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

		self.pev.nextthink		= g_Engine.time + 0.1;
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		g_SoundSystem.PrecacheSound(   self.pev.message );
		g_Game.PrecacheGeneric(        "sound/" + self.pev.message );
	}
	
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
	{
		bool isActive = ( self.pev.nextthink > 0.0 );

		// isActive is TRUE only if an announcement is pending

		if( useType != USE_TOGGLE )
		{
			// ignore if we're just turning something on that's already on, or
			// turning something off that's already off.
			if( ( isActive && useType == USE_ON ) || ( !isActive && useType == USE_OFF ) )
				return;
		}

		if( useType == USE_ON )
		{
			// turn on announcements
			self.pev.nextthink = g_Engine.time + 0.1;
			return;
		}

		if( useType == USE_OFF )
		{
			// turn off announcements
			self.pev.nextthink = 0.0;
			return;
		}

		// Toggle announcements
		if( isActive )
		{
			// turn off announcements
			self.pev.nextthink = 0.0;
		}
		else 
		{
			// turn on announcements
			self.pev.nextthink = g_Engine.time + 0.1;
		}
		
		BaseClass.Use( @pActivator, @pCaller, useType, flValue );
	}
	
	void Think()
	{
		float flvolume = self.pev.health;
		float flattenuation = ATTN_IDLE;
		int flags = 0;
		int pitch = 100;

		// Wait for the talkmonster to finish first.
		/*if( g_Engine.time <= CTalkMonster::g_talkWaitTime )
		{
			self.pev.nextthink = CTalkMonster::g_talkWaitTime + RANDOM_FLOAT( 5, 10 );
			return;
		}*/

		// play single sentence, one shot
		g_SoundSystem.EmitAmbientSound( self.edict(), self.pev.origin, self.pev.message,
			flvolume, flattenuation, flags, pitch );
		
		// shut off and reset
		self.pev.nextthink = g_Engine.time + self.pev.dmgtime + Math.RandomFloat( 0.1, self.pev.dmgtime * (self.pev.impulse*0.01) );
	}
}

void RegisterEntity_RandomSpeaker()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "random_speaker", "random_speaker" );
}
