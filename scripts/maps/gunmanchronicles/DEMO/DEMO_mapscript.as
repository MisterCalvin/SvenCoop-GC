#include "PROP/gunman_cycler"
#include "PROP/decore_asteroid"
#include "PROP/decore_spacedebris"
#include "PROP/hologram_damage"
#include "PROP/hologram_beak"
#include "PROP/entity_digitgod"
#include "PROP/func_gcbreakable"

#include "MONSTER/monster_trainingbot"
#include "MONSTER/monster_human_gunman"
#include "MONSTER/monster_human_unarmed"
#include "MONSTER/monster_flashlight"

// Test Enemy
#include "MONSTER/monster_barney_custom"

// Enemies
#include "MONSTER/monster_human_demoman"
#include "MONSTER/monster_human_bandit"
#include "MONSTER/monster_human_chopper"

#include "TRIGGER/entity_spritegod"
#include "TRIGGER/random_speaker"
#include "TRIGGER/player_gcweaponstrip"
#include "TRIGGER/trigger_tank"

#include "AMMO/ammo_gcgaussclip"
#include "AMMO/ammo_gcbuckshot"
#include "AMMO/ammo_gcminigunclip"
#include "AMMO/ammo_dmlsingle"

#include "WEAPON/weapon_fists"
#include "WEAPON/weapon_gausspistol"
#include "WEAPON/cust_2GaussPistolSniper"
#include "WEAPON/weapon_gcminigun"
#include "WEAPON/weapon_gcshotgun"
#include "WEAPON/weapon_dml"
#include "WEAPON/weapon_vehicledriving"

#include "WEAPON/weapon_crowbartest"

#include "VEHICLE/vehicle_tank"

// Items
#include "ITEMS/item_gascan"
#include "ITEMS/item_armor"

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

	MonsterFriendlyGunman::Register();

	RegisterEntity_MonsterHumanChopper();
    
    // Custom Enemies
    MonsterHumanDemoman::Register();
    MonsterHumanBandit::Register();
    
    // Test Enemy
    BarneyCustom::Register();
	
	RegisterEntity_HologramDamage();
	RegisterEntity_HologramBeak();
	
	RegisterEntity_PlayerGCWeaponStrip();
	
	RegisterEntity_AmmoGCGaussClip();
	RegisterEntity_AmmoGCShotgun();
    RegisterEntity_AmmoGCMinigunClip();
	RegisterEntity_AmmoDMLSingle();
    
    // Items
    RegisterEntity_GasCan();
    RegisterEntity_ItemArmor();
	
    // Weapons
	RegisterEntity_WeaponFists();
	RegisterEntity_WeaponGaussPistol();
	RegisterEntity_WeaponGaussSniper();
    RegisterEntity_WeaponGCMinigun();
	RegisterEntity_WeaponGCShotgun();
	RegisterEntity_WeaponDML();
	RegisterEntity_WeaponVehicleDriving();
	
	RegisterEntity_VehicleTank();

	RegisterHLCrowbar();
	
    // Allies
	g_Game.PrecacheOther("monster_trainingbot");
    g_Game.PrecacheOther("monster_human_gunman");
	g_Game.PrecacheOther("monster_human_unarmed");
    
    // Test Enemy
    g_Game.PrecacheOther("monster_barney_custom");
    
    // Enemies
    g_Game.PrecacheOther("monster_human_demoman");
    g_Game.PrecacheOther("monster_human_bandit");
	g_Game.PrecacheOther("monster_human_chopper");
	
    // Holograms
	g_Game.PrecacheOther("hologram_beak");
	g_Game.PrecacheOther("entity_digitgod");
	
    // Ammo
	g_Game.PrecacheOther("ammo_gcgaussclip");
    g_Game.PrecacheOther("ammo_gcminigunclip");
	g_Game.PrecacheOther("ammo_gcbuckshot");
	g_Game.PrecacheOther("ammo_dmlsingle");
    
    // Items
    g_Game.PrecacheOther("item_gascan");
    g_Game.PrecacheOther("item_armor");
	
    // Weapons
	g_Game.PrecacheOther("weapon_fists");
	g_Game.PrecacheOther("weapon_gausspistol");
	g_Game.PrecacheOther("cust_2GaussPistolSniper");
    g_Game.PrecacheOther("weapon_gcminigun");
	g_Game.PrecacheOther("weapon_gcshotgun");
	g_Game.PrecacheOther("weapon_dml");

	g_Game.PrecacheOther("weapon_hlcrowbar");
	
    // Vehicles
	g_Game.PrecacheOther("vehicle_tank");
}

void MapActivate()
{	
}