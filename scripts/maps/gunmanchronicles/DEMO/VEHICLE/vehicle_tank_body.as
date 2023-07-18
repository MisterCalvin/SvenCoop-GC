#include "CGenericVehicle"

final class vehicle_tank_body : CGenericVehicle
{
	void Spawn()
	{
		//InitBrush();
		InitMdl();
		CGenericVehicle::Spawn();
		
		self.pev.velocity = Vector(1337,1337,1337);
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		SUB_ChildUse( pActivator, pCaller, useType, flValue );
	}
}

void RegisterEntity_VehicleTankBody()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "vehicle_tank_body", "vehicle_tank_body" );
}

