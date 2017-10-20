#include "CGenericVehicle"

final class vehicle_tank_barrel : CGenericVehicle
{
	void Spawn()
	{
		InitBrush();
		CGenericVehicle::Spawn();
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		SUB_ChildUse( pActivator, pCaller, useType, flValue );
	}
}

void RegisterEntity_VehicleTankBarrel()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "vehicle_tank_barrel", "vehicle_tank_barrel" );
}

