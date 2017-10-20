#include "PROP/gunman_cycler"
#include "PROP/decore_asteroid"
#include "PROP/decore_spacedebris"
#include "PROP/hologram_damage"
#include "PROP/hologram_beak"
#include "PROP/entity_digitgod"
#include "PROP/func_gcbreakable"

#include "MONSTER/monster_trainingbot"
#include "MONSTER/monster_human_unarmed"
#include "MONSTER/monster_flashlight"

#include "TRIGGER/entity_spritegod"
#include "TRIGGER/random_speaker"
#include "TRIGGER/player_gcweaponstrip"
#include "TRIGGER/trigger_tank"

#include "AMMO/ammo_gcgaussclip"
#include "AMMO/ammo_gcbuckshot"

#include "WEAPON/weapon_gausspistol"
#include "WEAPON/cust_2GaussPistolSniper"
#include "WEAPON/weapon_gcshotgun"
#include "WEAPON/weapon_vehicledriving"

#include "VEHICLE/vehicle_tank"

void MapInit()
{
	//InitSoundEnt();
	
	RegisterEntity_GunmanCycler();
	RegisterEntity_DecoreAsteroid();
	RegisterEntity_DecoreSpaceDebris();
	RegisterEntity_DigitGod();
	RegisterEntity_FuncGCBreakable();
	RegisterEntity_EntitySpriteGod();
	RegisterEntity_RandomSpeaker();
	RegisterEntity_TriggerTank();
	
	RegisterEntity_MonsterTrainingBot();
	RegisterEntity_MonsterHumanUnarmed();
	RegisterEntity_MonsterFlashlight();
	
	RegisterEntity_HologramDamage();
	RegisterEntity_HologramBeak();
	
	RegisterEntity_PlayerGCWeaponStrip();
	
	RegisterEntity_AmmoGCGaussClip();
	RegisterEntity_AmmoGCShotgun();
	
	RegisterEntity_WeaponGaussPistol();
	RegisterEntity_WeaponGaussSniper();
	RegisterEntity_WeaponGCShotgun();
	RegisterEntity_WeaponVehicleDriving();
	
	RegisterEntity_VehicleTank();
	
	g_Game.PrecacheOther("monster_trainingbot");
	g_Game.PrecacheOther("monster_human_unarmed");
	
	g_Game.PrecacheOther("hologram_beak");
	g_Game.PrecacheOther("entity_digitgod");
	
	g_Game.PrecacheOther("ammo_gcgaussclip");
	g_Game.PrecacheOther("ammo_gcbuckshot");
	
	g_Game.PrecacheOther("weapon_gausspistol");
	g_Game.PrecacheOther("cust_2GaussPistolSniper");
	g_Game.PrecacheOther("weapon_gcshotgun");
	
	g_Game.PrecacheOther("vehicle_tank");
}

void MapActivate()
{	
}

/* that shit's broken...
   now i'm at an all time low low low low low low low low low low low low low low 
void InitSoundEnt()
{
	g_EntityFuncs.Remove( g_hSoundEnt.GetEntity() );
	
	CSoundEnt@ pEnt = cast<CSoundEnt@>( g_EntityFuncs.CreateEntity( "soundent" ) );
	
	if( pEnt !is null )
		g_hSoundEnt = EHandle( @pEnt );
}
*/
