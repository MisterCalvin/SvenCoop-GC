#include "CGenericVehicle"

final class vehicle_tank_turret : CGenericVehicle
{
	void Spawn()
	{
		//InitBrush();
        InitMdl();
		CGenericVehicle::Spawn();
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		SUB_ChildUse( pActivator, pCaller, useType, flValue );
	}
}

void RegisterEntity_VehicleTankTurret()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "vehicle_tank_turret", "vehicle_tank_turret" );
}

