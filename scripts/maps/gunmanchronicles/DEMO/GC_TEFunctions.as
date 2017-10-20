class Color
{ 
	uint8 r, g, b, a;
	
	Color() { r = g = b = a = 0; }
	Color(uint8 _r, uint8 _g, uint8 _b, uint8 _a = 255 ) { r = _r; g = _g; b = _b; a = _a; }
	Color (Vector v) { r = int(v.x); g = int(v.y); b = int(v.z); a = 255; }
	string ToString() { return "" + r + " " + g + " " + b + " " + a; }
}

const Color NOCOLOR();
const Color RED(255,0,0);
const Color GREEN(0,255,0);
const Color BLUE(0,0,255);
const Color WHITE(255,255,255);
const Color BLACK(0,0,0);
const Color AQUAMARINE(127,255,212);

void CreateTempEnt_Sprite(Vector pos, string sprite="sprites/zerogxplode.spr", 
	uint8 scale=10, uint8 alpha=200, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRITE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(scale);
	m.WriteByte(alpha);
	m.End();
}

void CreateTempEnt_SpriteTrail(Vector start, Vector end, 
	string sprite="sprites/hotglow.spr", uint8 count=3, uint8 life=0, 
	uint8 scale=1, uint8 speed=32, uint8 speedNoise=8,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRITETRAIL);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteByte(life);
	m.WriteByte(scale);
	m.WriteByte(speedNoise);
	m.WriteByte(speed);
	m.End();
}

void CreateTempEnt_BeamPoints(Vector start, Vector end, 
	string sprite="sprites/laserbeam.spr",
	uint8 life=1, uint8 width=4, uint8 noise=0, uint8 scroll=0,
	Color c=AQUAMARINE, uint8 frameStart=0, uint8 frameRate=100, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMPOINTS);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(frameStart);
	m.WriteByte(frameRate);
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(noise);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a); // actually brightness
	m.WriteByte(scroll);
	m.End();
}

void CreateTempEnt_BeamEntPoint(CBaseEntity@ target, Vector end, 
	string sprite="sprites/laserbeam.spr", uint16 attachment = 0x1000, 
	uint8 life=1, uint8 width=4, uint8 noise=1, uint8 scroll=0,
	Color c=AQUAMARINE, uint8 frameStart=0, uint8 frameRate=100,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMENTPOINT);
	m.WriteShort(target.entindex() | attachment);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(frameStart);
	m.WriteByte(frameRate);
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(noise);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a); // actually brightness
	m.WriteByte(scroll);
	m.End();
}

void CreateTempEnt_BeamFollow(CBaseEntity@ target, string sprite="sprites/laserbeam.spr", 
	uint8 life=10, uint8 width=2, Color c=AQUAMARINE,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMFOLLOW);
	m.WriteShort(target.entindex());
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a);
	m.End();
}

void CreateTempEnt_Line(Vector start, Vector end, uint16 life=32, Color c=WHITE,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_LINE);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(life);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.End();
}

void CreateTempEnt_Box(Vector mins, Vector maxs, uint16 life=16, Color c=WHITE,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BOX);
	m.WriteCoord(mins.x);
	m.WriteCoord(mins.y);
	m.WriteCoord(mins.z);
	m.WriteCoord(maxs.x);
	m.WriteCoord(maxs.y);
	m.WriteCoord(maxs.z);
	m.WriteShort(life);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.End();
}

void CreateTempEnt_SpriteSpray(Vector pos, Vector dir, 
	string sprite="sprites/bubble.spr", uint8 count=8, 
	uint8 speed=16, uint8 noise=255,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRITE_SPRAY);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(dir.x);
	m.WriteCoord(dir.y);
	m.WriteCoord(dir.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteByte(speed);
	m.WriteByte(noise);
	m.End();
}

