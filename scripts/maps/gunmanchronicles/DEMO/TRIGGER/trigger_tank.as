class trigger_tank : ScriptBaseEntity
{
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Spawn()
	{
		BaseClass.Precache();
		
		self.pev.effects		|=	EF_NODRAW;
		
		g_EntityFuncs.SetModel(self, self.pev.model);
		
		self.pev.solid			= SOLID_TRIGGER; //SOLID_BSP;
		self.pev.movetype		= MOVETYPE_NONE; //MOVETYPE_PUSH;
		self.pev.takedamage		= DAMAGE_NO;
		
		g_EntityFuncs.SetOrigin(self, self.pev.origin );
	}
	
	void Touch(CBaseEntity@ pOther)
	{
		if( pOther !is null && string( pOther.pev.classname ) == "vehicle_tank_body" )
		{
			self.SUB_UseTargets( g_EntityFuncs.Instance( pOther.pev.owner ), USE_TOGGLE, 0.0 );
			self.Killed( self.pev, GIB_NORMAL );
		}
	}
	
}

void RegisterEntity_TriggerTank()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_tank", "trigger_tank" );
}
