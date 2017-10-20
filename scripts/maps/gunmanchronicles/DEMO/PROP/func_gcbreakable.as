
const string[] gcbreakable_spawnobject = 
{
	"",
	"item_battery",
	"item_healthkit",
	"weapon_crowbar",
	"weapon_gcshotgun",
	"weapon_SPchemicalgun",
	"weapon_beamgun",
	"weapon_minigun",
	"weapon_dml",
	"weapon_gausspistol",
	"ammo_gcbuckshot",
	"ammo_chemical",
	"ammo_beamgunclip",
	"ammo_minigunClip",
	"ammo_dmlclip",
	"ammo_gcgaussclip",
	"weapon_gausspistol",
	"entity_clustergod",
	"cust_2MinigunCooled",
	"cust_2GaussPistolSniper",
	"item_armor"
};

class func_gcbreakable : ScriptBaseEntity
{
	private int			m_Explosion;
	private Materials	m_Material;
	private string		m_iszGibModel;
	private string		m_iszSoundList;
	private string		m_iszDisplayName;
	private int			m_MinLight;

	bool KeyValue(const string& in szKeyName, const string& in szValue)
	{
		// UNDONE_WC: explicitly ignoring these fields, but they shouldn't be in the map file!
		if( szKeyName == "explosion" )
		{
			m_Explosion = atoi(szValue);
			
			return true;
		}
		else if( szKeyName == "material" )
		{
			int i = atoi( szValue );

			// 0:glass, 1:metal, 2:flesh, 3:wood

			if( ( i < 0 ) || ( i >= matLastMaterial ) )
				m_Material = matWood;
			else
				m_Material = Materials(i);

			return true;
		}
		else if( szKeyName == "weapon" )
		{
			self.pev.weapons = atoi(szValue);
			
			return true;
		}
		else if( szKeyName == "gibmodel" )
		{
			m_iszGibModel = szValue;
			
			return true;
		}
		else if( szKeyName == "spawnobject" )
		{
			uint object = atoui( szValue );
			if( object > 0 && object < gcbreakable_spawnobject.length() )
				self.pev.weaponmodel = gcbreakable_spawnobject[object];
			
			return true;
		}
		else if( szKeyName == "explodemagnitude" )
		{
			self.pev.impulse = atoi( szValue );
			
			return true;
		}
		else if( szKeyName == "soundlist" )
		{
			m_iszSoundList = szValue;
			return true;
		}
		else if( szKeyName == "displayname" )
		{
			m_iszDisplayName = szValue;
			return true;
		}
		else if( szKeyName == "_minlight" )
		{
			m_MinLight = atoi(szValue);
			return true;
		}
		else
			return BaseClass.KeyValue( szKeyName, szValue );
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		/*g_Game.PrecacheModel( "models/woodgibs.mdl" );
		g_Game.PrecacheModel( "models/fleshgibs.mdl" );
		g_Game.PrecacheModel( "models/computergibs.mdl" );
		g_Game.PrecacheModel( "models/glassgibs.mdl" );
		g_Game.PrecacheModel( "models/metalplategibs.mdl" );
		g_Game.PrecacheModel( "models/cindergibs.mdl" );
		g_Game.PrecacheModel( "models/rockgibs.mdl" );
		g_Game.PrecacheModel( "models/ceilinggibs.mdl" );*/
		
		if( m_iszGibModel.IsEmpty() == false )
			g_Game.PrecacheModel( m_iszGibModel );
		
		g_EntityFuncs.PrecacheMaterialSounds( m_Material );
	}
	
	void Spawn()
	{
		Precache();
		
		g_EntityFuncs.SetModel(self, self.pev.model);
		
		self.pev.solid		= SOLID_BSP;
		self.pev.movetype	= MOVETYPE_PUSH;
		self.pev.takedamage	= DAMAGE_NO;
		
		self.pev.oldorigin = self.pev.origin;
		
		//g_EntityFuncs.SetSize(self.pev, self.pev.mins, self.pev.maxs);
		g_EntityFuncs.SetOrigin(self, ( self.pev.absmax + self.pev.absmin ) * 0.00001 );
		
		//self.pev.nextthink = self.pev.ltime + 0.2;
		
		Think();
	}
	
	void Think()
	{
		g_Game.AlertMessage( at_console, "origin = %1 %2 %3\noldorigin = %4 %5 %6\n", self.pev.origin.x, self.pev.origin.y, self.pev.origin.z, self.pev.oldorigin.x, self.pev.oldorigin.y, self.pev.oldorigin.z );
		
		CBaseEntity@ pBreakable = CreateBreakableObject();
		
		if( pBreakable !is null )
			self.Killed( self.pev, GIB_NORMAL );
	}
	
	CBaseEntity@ CreateBreakableObject() const
	{			
		CBaseEntity@ pBreakable = g_EntityFuncs.Create( "func_breakable", self.pev.origin, self.pev.angles, true );
	
		if( pBreakable is null )
		{
			g_Game.AlertMessage( at_console, "Unexpected null pointer while creating breakable!\n" );
			return null;
		}
		
		g_PevDuplicator.CopyEntPev( @pBreakable.pev, @self.pev );
		
		edict_t@ pEdict = pBreakable.edict();
		
		g_EntityFuncs.DispatchKeyValue( pEdict, "classname",		"func_breakable" );
		g_EntityFuncs.DispatchKeyValue( pEdict, "model",   			self.pev.model );
		g_EntityFuncs.DispatchKeyValue( pEdict, "target",   		self.pev.target );
		g_EntityFuncs.DispatchKeyValue( pEdict, "health",   		self.pev.health );
		g_EntityFuncs.DispatchKeyValue( pEdict, "material",			m_Material );
		g_EntityFuncs.DispatchKeyValue( pEdict, "weapon",			self.pev.weapons );
		g_EntityFuncs.DispatchKeyValue( pEdict, "explosion",		m_Explosion );
		
		if( m_iszGibModel.IsEmpty() == false )
			g_EntityFuncs.DispatchKeyValue( pEdict, "gibmodel",			m_iszGibModel );
		
		g_EntityFuncs.DispatchKeyValue( pEdict, "explodemagnitude",	self.pev.impulse );
		g_EntityFuncs.DispatchKeyValue( pEdict, "soundlist",		m_iszSoundList );
		
		g_EntityFuncs.DispatchKeyValue( pEdict, "displayname",		m_iszDisplayName );
		g_EntityFuncs.DispatchKeyValue( pEdict, "_minlight",		m_MinLight );
		g_EntityFuncs.DispatchKeyValue( pEdict, "spawnflags",		self.pev.spawnflags );
		
		g_EntityFuncs.DispatchKeyValue( pEdict, "classify",			self.Classify() );
		g_EntityFuncs.DispatchKeyValue( pEdict, "ondestroyfn",		"GCBREAKABLE::SpawnObject" );
		
		g_EntityFuncs.DispatchSpawn( pEdict );
		
		//In case the entity got removed
		@pBreakable = g_EntityFuncs.Instance( pEdict );
		
		g_Game.AlertMessage( at_console, "CREATED! classname = %1, %2\n", pBreakable.pev.classname, pBreakable.pev.weaponmodel );
		
		return pBreakable;
	}
}

namespace GCBREAKABLE
{
void SpawnObject( CBaseEntity@ pEntity )
{
	if( pEntity is null )
		return;
	
	string className = pEntity.pev.weaponmodel;
	
	g_Game.AlertMessage( at_console, "DESTROYED! classname = %1, %2\n", pEntity.pev.classname, className );
	
	if( className.IsEmpty() == false )
		g_EntityFuncs.Create( className, pEntity.pev.origin, pEntity.pev.angles, false );
}
}

void RegisterEntity_FuncGCBreakable()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "func_gcbreakable", "func_gcbreakable" );
}
