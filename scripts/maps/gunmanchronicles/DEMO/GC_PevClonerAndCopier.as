CPevDuplicator g_PevDuplicator;

final class CPevDuplicator
{
	entvars_t@ CloneEntPev( entvars_t@ pevCopyTo ) const
	{
		return @pevCopyTo;
	}

	entvars_t@ CopyEntPev( entvars_t@ pevCopyTo, entvars_t@ pevCopyFrom ) const
	{
		if( @pevCopyTo is null || @pevCopyFrom is null )
			return null;
		
		entvars_t@ temp = CloneEntPev( @pevCopyTo );
		
		// const variables :
		// classname, modelindex
		
		temp.globalname			=	pevCopyFrom.globalname;
		
		temp.origin				=	pevCopyFrom.origin;
		temp.oldorigin			=	pevCopyFrom.oldorigin;
		temp.velocity			=	pevCopyFrom.velocity;
		temp.basevelocity		=	pevCopyFrom.basevelocity;
		temp.basevelocity		=	pevCopyFrom.basevelocity;		// Base velocity that was passed in to server physics so 
																	// client can predict conveyors correctly. Server zeroes it, so we need to store here, too.
		temp.movedir			=	pevCopyFrom.movedir;

		temp.angles				=	pevCopyFrom.angles;				// Model angles
		temp.avelocity			=	pevCopyFrom.avelocity;			// angle velocity (degrees per second)
		temp.punchangle			=	pevCopyFrom.punchangle;			// auto-decaying view angle adjustment
		temp.v_angle			=	pevCopyFrom.v_angle;			// Viewing angle (player only)

		// For parametric entities
		temp.endpos				=	pevCopyFrom.endpos;
		temp.startpos			=	pevCopyFrom.startpos;
		temp.impacttime			=	pevCopyFrom.impacttime;
		temp.starttime			=	pevCopyFrom.starttime;

		temp.fixangle			=	pevCopyFrom.fixangle;			// 0:nothing, 1:force view angles, 2:add avelocity
		temp.idealpitch			=	pevCopyFrom.idealpitch;
		temp.pitch_speed		=	pevCopyFrom.pitch_speed;
		temp.ideal_yaw			=	pevCopyFrom.ideal_yaw;
		temp.yaw_speed			=	pevCopyFrom.yaw_speed;

		temp.model				=	pevCopyFrom.model;
		temp.viewmodel			=	pevCopyFrom.viewmodel;			// player's viewmodel
		temp.weaponmodel		=	pevCopyFrom.weaponmodel;		// what other players see

		temp.absmin				=	pevCopyFrom.absmin;				// BB max translated to world coord
		temp.absmax				=	pevCopyFrom.absmax;				// BB max translated to world coord
		temp.mins				=	pevCopyFrom.mins;				// local BB min
		temp.maxs				=	pevCopyFrom.maxs;				// local BB max
		temp.size				=	pevCopyFrom.size;				// maxs - mins
		
		temp.ltime				=	pevCopyFrom.ltime;
		temp.nextthink			=	pevCopyFrom.nextthink;

		temp.movetype			=	pevCopyFrom.movetype;
		temp.solid				=	pevCopyFrom.solid;

		temp.skin				=	pevCopyFrom.skin;
		temp.body				=	pevCopyFrom.body;				// sub-model selection for studiomodels
		temp.effects			=	pevCopyFrom.effects;
		temp.gravity			=	pevCopyFrom.gravity;			// % of "normal" gravity
		temp.friction			=	pevCopyFrom.friction;			// inverse elasticity of MOVETYPE_BOUNCE

		temp.light_level		=	pevCopyFrom.light_level;

		temp.sequence			=	pevCopyFrom.sequence;			// animation sequence
		temp.gaitsequence		=	pevCopyFrom.gaitsequence;		// movement animation sequence for player (0 for none)
		temp.frame				=	pevCopyFrom.frame;				// % playback position in animation sequences (0..255)
		temp.animtime			=	pevCopyFrom.animtime;			// world time when frame was set
		temp.framerate			=	pevCopyFrom.framerate;			// animation playback rate (-8x to 8x)
		
		temp.set_controller( 0, pevCopyFrom.get_controller(0) );	// bone controller setting (0..255)
		temp.set_controller( 1, pevCopyFrom.get_controller(1) );	// bone controller setting (0..255)
		temp.set_controller( 2, pevCopyFrom.get_controller(2) );	// bone controller setting (0..255)
		temp.set_controller( 3, pevCopyFrom.get_controller(3) );	// bone controller setting (0..255)
		
		temp.set_blending( 0, pevCopyFrom.get_blending(0) );		// blending amount between sub-sequences (0..255)
		temp.set_blending( 1, pevCopyFrom.get_blending(1) );		// blending amount between sub-sequences (0..255)
		temp.set_blending( 2, pevCopyFrom.get_blending(2) );		// blending amount between sub-sequences (0..255)
		temp.set_blending( 3, pevCopyFrom.get_blending(3) );		// blending amount between sub-sequences (0..255)

		temp.scale				=	pevCopyFrom.scale;				// sprites and models rendering scale (0..255)
		temp.rendermode			=	pevCopyFrom.rendermode;
		temp.renderamt			=	pevCopyFrom.renderamt;
		temp.rendercolor		=	pevCopyFrom.rendercolor;
		temp.renderfx			=	pevCopyFrom.renderfx;

		temp.health				=	pevCopyFrom.health;
		temp.frags				=	pevCopyFrom.frags;
		temp.weapons			=	pevCopyFrom.weapons;			// bit mask for available weapons
		temp.takedamage			=	pevCopyFrom.takedamage;

		temp.deadflag			=	pevCopyFrom.deadflag;
		temp.view_ofs			=	pevCopyFrom.view_ofs;			// eye position

		temp.button				=	pevCopyFrom.button;
		temp.impulse			=	pevCopyFrom.impulse;

		@temp.chain				=	@pevCopyFrom.chain;				// Entity pointer when linked into a linked list
		@temp.dmg_inflictor		=	@pevCopyFrom.dmg_inflictor;
		@temp.enemy				=	@pevCopyFrom.enemy;
		@temp.aiment			=	@pevCopyFrom.aiment;			// entity pointer when MOVETYPE_FOLLOW
		@temp.owner				=	@pevCopyFrom.owner;
		@temp.groundentity		=	@pevCopyFrom.groundentity;

		temp.spawnflags			=	pevCopyFrom.spawnflags;
		temp.flags				=	pevCopyFrom.flags;
		
		temp.colormap			=	pevCopyFrom.colormap;			// lowbyte topcolor, highbyte bottomcolor
		temp.team				=	pevCopyFrom.team;

		temp.max_health			=	pevCopyFrom.max_health;
		temp.teleport_time		=	pevCopyFrom.teleport_time;
		temp.armortype			=	pevCopyFrom.armortype;
		temp.armorvalue			=	pevCopyFrom.armorvalue;
		temp.waterlevel			=	pevCopyFrom.waterlevel;
		temp.watertype			=	pevCopyFrom.watertype;

		temp.target				=	pevCopyFrom.target;
		temp.targetname			=	pevCopyFrom.targetname;
		temp.netname			=	pevCopyFrom.netname;
		temp.message			=	pevCopyFrom.message;

		temp.dmg_take			=	pevCopyFrom.dmg_take;
		temp.dmg_save			=	pevCopyFrom.dmg_save;
		temp.dmg				=	pevCopyFrom.dmg;
		temp.dmgtime			=	pevCopyFrom.dmgtime;

		temp.noise				=	pevCopyFrom.noise;
		temp.noise1				=	pevCopyFrom.noise1;
		temp.noise2				=	pevCopyFrom.noise2;
		temp.noise3				=	pevCopyFrom.noise3;

		temp.speed				=	pevCopyFrom.speed;
		temp.air_finished		=	pevCopyFrom.air_finished;
		temp.pain_finished		=	pevCopyFrom.pain_finished;
		temp.radsuit_finished	=	pevCopyFrom.radsuit_finished;

		temp.playerclass		=	pevCopyFrom.playerclass;
		temp.maxspeed			=	pevCopyFrom.maxspeed;

		temp.fov				=	pevCopyFrom.fov;
		temp.weaponanim			=	pevCopyFrom.weaponanim;

		temp.pushmsec			=	pevCopyFrom.pushmsec;

		temp.bInDuck			=	pevCopyFrom.bInDuck;
		temp.flTimeStepSound	=	pevCopyFrom.flTimeStepSound;
		temp.flSwimTime			=	pevCopyFrom.flSwimTime;
		temp.flDuckTime			=	pevCopyFrom.flDuckTime;
		temp.iStepLeft			=	pevCopyFrom.iStepLeft;
		temp.flFallVelocity		=	pevCopyFrom.flFallVelocity;

		temp.gamestate			=	pevCopyFrom.gamestate;

		temp.oldbuttons			=	pevCopyFrom.oldbuttons;

		temp.groupinfo			=	pevCopyFrom.groupinfo;

		// For mods
		temp.iuser1				=	pevCopyFrom.iuser1;
		temp.iuser2				=	pevCopyFrom.iuser2;
		temp.iuser3				=	pevCopyFrom.iuser3;
		temp.iuser4				=	pevCopyFrom.iuser4;
		temp.fuser1				=	pevCopyFrom.fuser1;
		temp.fuser2				=	pevCopyFrom.fuser2;
		temp.fuser3				=	pevCopyFrom.fuser3;
		temp.fuser4				=	pevCopyFrom.fuser4;
		temp.vuser1				=	pevCopyFrom.vuser1;
		temp.vuser2				=	pevCopyFrom.vuser2;
		temp.vuser3				=	pevCopyFrom.vuser3;
		temp.vuser4				=	pevCopyFrom.vuser4;
		@temp.euser1			=	@pevCopyFrom.euser1;
		@temp.euser2			=	@pevCopyFrom.euser2;
		@temp.euser3			=	@pevCopyFrom.euser3;
		@temp.euser4			=	@pevCopyFrom.euser4;
		
		return temp;
	}
}
