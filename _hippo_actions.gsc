// HIPPO MENU - feature functions (self-contained helper file, no init())

hippoDvarDefault(name, value)
{
	if (getDvar(name) == "")
		setDvar(name, value);
}

hippoIsBot(p)
{
	if (isDefined(p.pers))
	{
		if (isDefined(p.pers["isBot"]))
		{
			if (p.pers["isBot"])
				return true;
		}
	}
	if (isDefined(p.guid))
	{
		if (isSubStr(p.guid, "bot"))
			return true;
	}
	return false;
}

hippoInitState()
{
	self.hippoOn = [];
	self.hippoVal = [];
	self.hippoObjs = [];

	self.hippoOn["god"] = false;
	self.hippoOn["ammo"] = false;
	self.hippoOn["ufo"] = false;
	self.hippoOn["aim"] = false;
	self.hippoOn["expl"] = false;
	self.hippoOn["jump"] = false;
	self.hippoOn["speed"] = false;
	self.hippoOn["grav"] = false;
	self.hippoOn["third"] = false;
	self.hippoOn["laser"] = false;
	self.hippoOn["thump"] = false;
	self.hippoOn["norecoil"] = false;
	self.hippoThumpTime = 0;
	self.hippoOn["aimwall"] = false;
	self.hippoOn["ikill"] = false;
	self.hippoOn["iauto"] = false;
	self.hippoOn["anim"] = (getDvarInt("hippo_animations") != 0);
	self.hippoOn["kushhud"] = (getDvarInt("hippo_kushhud") != 0);

	ids = strTok("heligun helibtn helicd helispeed mdl perk wclass wpn att camo skill botcount aimsmooth aimwhen aimbone objsel gmode side fov vision theme emblem", " ");
	foreach (id in ids)
		self.hippoVal[id] = 0;

	s = getDvarInt("bots_skill");
	if (s < 0)
		s = 0;
	if (s > 8)
		s = 8;
	self.hippoVal["skill"] = s;

	if (getDvarInt("hippo_side") == 1)
		self.hippoVal["side"] = 1;

	t = getDvarInt("hippo_theme");
	if (t < 0 || t > 6)
		t = 0;
	self.hippoVal["theme"] = t;

	e = getDvarInt("hippo_emblem");
	if (e < 0 || e > 10)
		e = 0;
	self.hippoVal["emblem"] = e;
}

hippoBindKeys()
{
	cmd = "bind " + getDvar("hippo_key_open") + " +hippo_toggle;";
	cmd = cmd + "bind " + getDvar("hippo_key_up") + " +hippo_up;";
	cmd = cmd + "bind " + getDvar("hippo_key_down") + " +hippo_down;";
	cmd = cmd + "bind " + getDvar("hippo_key_select") + " +hippo_select;";
	cmd = cmd + "bind " + getDvar("hippo_key_back") + " +hippo_back";
	self setClientDvar("activeaction", cmd);
}

// ---------------------------------------------------------------- cycles

hippoCycleList(id)
{
	switch (id)
	{
		case "mdl":
			return hippoModelNames();
		case "perk":
			return strTok("extendedmelee,fastsprintrecovery,automantle,spygame,improvedholdbreath,fastsnipe,selectivehearing,heartbreaker,coldblooded,quickdraw,marathon,lightweight,extendedmags,scavenger,explosivebullets,jumpdive,fastmantle,specialgrenade,fraggrenade,armorvest,twoprimaries,extraammo,bulletdamage,exposeenemy,detectexplosive,longersprint,parabolic,quieter,pistoldeath,grenadepulldeath,bulletpenetration,holdbreath,rof,fastreload,bulletaccuracy,gpsjammer", ",");
		case "wclass":
			return hippoWpnClasses();
		case "wpn":
			return hippoWpnAll();
		case "camo":
			return strTok("none,woodland,desert,arctic,digital,red urban,red tiger,blue tiger,fall", ",");
		case "skill":
			return strTok("0,1,2,3,4,5,6,7,8", ",");
		case "botcount":
			return strTok("1,2,4,8", ",");
		case "aimsmooth":
			return strTok("snap,fast,smooth", ",");
		case "objsel":
			return hippoObjNames();
		case "gmode":
			return strTok("off,gun game,one in the chamber", ",");
		case "helispeed":
			return strTok("slow,normal,fast", ",");
		case "helibtn":
			return strTok("frag grenade,aim,melee,use", ",");
		case "heligun":
			return strTok("flash grenade,fire", ",");
		case "helicd":
			return strTok("fast,normal,slow", ",");
		case "aimwhen":
			return strTok("aiming,always", ",");
		case "aimbone":
			return strTok("head,chest", ",");
		case "side":
			return strTok("left,right", ",");
		case "theme":
			return strTok("ice,toxic,crimson,royal,gold,rainbow,kush", ",");
		case "emblem":
			return strTok("10,1,2,3,4,5,6,7,8,9,off", ",");
		case "fov":
			return strTok("65,80,90,105,120", ",");
		case "vision":
			return strTok("default,cheat_bw,cheat_bw_invert,cheat_contrast,cheat_invert,cheat_invert_contrast,cheat_chaplinnight,thermal_mp,ac130,ac130_inverted,missilecam,mpnuke,mpnuke_aftermath,aftermath,sepia,grayscale,end_game,default_night_mp,cargoship_blast", ",");
	}
	return strTok("none", ",");
}

hippoCycleListFor(id)
{
	if (id == "att")
		return hippoAttList(self hippoCurWeaponBase(), hippoWpnClassOf(self.hippoVal["wpn"]));
	return hippoCycleList(id);
}

hippoCycleText(id)
{
	list = self hippoCycleListFor(id);
	return list[self.hippoVal[id] % list.size];
}

hippoDoCycle(id)
{
	list = self hippoCycleListFor(id);
	self.hippoVal[id] = (self.hippoVal[id] + 1) % list.size;

	switch (id)
	{
		case "wpn":
			self.hippoVal["att"] = 0;
			self.hippoVal["wclass"] = hippoWpnClassOf(self.hippoVal["wpn"]);
			break;
		case "wclass":
			self.hippoVal["wpn"] = hippoWpnClassStart(self.hippoVal["wclass"]);
			self.hippoVal["att"] = 0;
			break;
		case "skill":
			setDvar("bots_skill", self.hippoVal["skill"]);
			break;
		case "fov":
			self setClientDvar("cg_fov", list[self.hippoVal["fov"]]);
			self iPrintLn("^5HIPPO: ^7FOV " + list[self.hippoVal["fov"]] + " - if it did not change, type ^3cg_fov " + list[self.hippoVal["fov"]] + "^7 in the console (the game blocks scripts from changing it)");
			break;
		case "gmode":
			setDvar("hippo_gamemode", self.hippoVal["gmode"]);
			break;
		case "helispeed":
			setDvar("hippo_heli_speed", self.hippoVal["helispeed"]);
			break;
		case "helibtn":
			setDvar("hippo_heli_btn", self.hippoVal["helibtn"]);
			break;
		case "heligun":
			setDvar("hippo_heli_gun", self.hippoVal["heligun"]);
			break;
		case "helicd":
			setDvar("hippo_heli_cd", self.hippoVal["helicd"]);
			break;
		case "theme":
			setDvar("hippo_theme", self.hippoVal["theme"]);
			break;
		case "emblem":
			setDvar("hippo_emblem", self.hippoVal["emblem"]);
			break;
		case "vision":
			self hippoVisionApply(list[self.hippoVal["vision"]]);
			break;
		case "side":
			setDvar("hippo_side", self.hippoVal["side"]);
			break;
	}
}

// ---------------------------------------------------------------- toggles

hippoDoToggle(id)
{
	self.hippoOn[id] = !self.hippoOn[id];

	switch (id)
	{
		case "god":
			if (!self.hippoOn["god"])
			{
				self.maxhealth = 100;
				self.health = 100;
			}
			break;
		case "ufo":
			if (self.hippoOn["ufo"])
			{
				if (isAlive(self))
					self hippoUfoOn();
				else
					self.hippoOn["ufo"] = false;
			}
			else
			{
				self hippoUfoOff();
			}
			break;
		case "kushhud":
			setDvar("hippo_kushhud", self.hippoOn["kushhud"]);
			break;
		case "anim":
			setDvar("hippo_animations", self.hippoOn["anim"]);
			break;
		case "jump":
			if (self.hippoOn["jump"])
			{
				setDvar("jump_height", 250);
				setDvar("bg_fallDamageMinHeight", 9998);
				setDvar("bg_fallDamageMaxHeight", 9999);
			}
			else
			{
				setDvar("jump_height", 39);
				setDvar("bg_fallDamageMinHeight", 128);
				setDvar("bg_fallDamageMaxHeight", 300);
			}
			break;
		case "speed":
			if (self.hippoOn["speed"])
				self setMoveSpeedScale(1.8);
			else
				self setMoveSpeedScale(1.0);
			break;
		case "grav":
			if (self.hippoOn["grav"])
				setDvar("g_gravity", 200);
			else
				setDvar("g_gravity", 800);
			break;
		case "thump":
			if (self.hippoOn["thump"])
				self iPrintLn("^5HIPPO: ^7Thumper Rounds on - every shot also fires a thumper grenade");
			break;
		case "norecoil":
			self hippoRecoilApply();
			break;
		case "laser":
			if (self.hippoOn["laser"])
				self setClientDvar("laserForceOn", 1);
			else
				self setClientDvar("laserForceOn", 0);
			break;
		case "third":
			if (self.hippoOn["third"])
			{
				self setClientDvar("cg_thirdPersonRange", 200);
				self setClientDvar("cg_thirdPerson", 1);
				self iPrintLn("^5HIPPO: ^7Third Person - if nothing changed, type ^3sv_cheats 1^7 then ^3cg_thirdperson 1^7 in the console");
			}
			else
			{
				self setClientDvar("cg_thirdPerson", 0);
			}
			break;
	}
}

hippoDvarIsOn(name)
{
	if (getDvar(name) == "")
		return true;
	return (getDvarInt(name) != 0);
}

hippoDvarToggle(name)
{
	if (hippoDvarIsOn(name))
		setDvar(name, 0);
	else
		setDvar(name, 1);
}

// ---------------------------------------------------------------- per-frame features

hippoFeatureLoop()
{
	self endon("disconnect");

	tick = 0;
	for (;;)
	{
		wait 0.05;
		tick = tick + 1;

		if (!isAlive(self))
			continue;
		if (self.sessionstate != "playing")
			continue;

		if (self.hippoOn["god"])
		{
			self.maxhealth = 90000;
			self.health = 90000;
		}

		if (self.hippoOn["ammo"] && (tick % 4) == 0)
			self hippoRefillAmmo();

		if (self.hippoOn["aim"])
			self hippoAimStep();

		if (self.hippoOn["iauto"] && (tick % 5) == 0)
			self hippoAutoKill();
	}
}

hippoRefillAmmo()
{
	w = self getCurrentWeapon();
	if (w != "none")
	{
		self giveMaxAmmo(w);
		self setWeaponAmmoClip(w, 999);
	}

	prim = self getWeaponsListPrimaries();
	foreach (p in prim)
		self giveMaxAmmo(p);
}

// ---------------------------------------------------------------- UFO
// Uses the engine's free-look spectator camera: WASD to fly, jump = up, crouch = down.

hippoUfoOn()
{
	self allowSpectateTeam("freelook", true);
	self.sessionstate = "spectator";
}

hippoUfoOff()
{
	self allowSpectateTeam("freelook", false);
	self.sessionstate = "playing";
}

// ---------------------------------------------------------------- aim (bots only)

hippoAimFactor()
{
	v = self.hippoVal["aimsmooth"];
	if (v == 1)
		return 0.5;
	if (v == 2)
		return 0.2;
	return 1.0;
}

hippoAngDiff(a, b)
{
	d = b - a;
	while (d > 180)
		d = d - 360;
	while (d < -180)
		d = d + 360;
	return d;
}

hippoAimPoint(p)
{
	if (self.hippoVal["aimbone"] == 1)
		return p.origin + (0, 0, 45);
	return p getTagOrigin("j_head");
}

hippoBestBot()
{
	best = undefined;
	bestDist = 999999999;
	eye = self getEye();

	foreach (p in level.players)
	{
		if (p == self)
			continue;
		if (!isDefined(p.sessionstate))
			continue;
		if (p.sessionstate != "playing")
			continue;
		if (!isAlive(p))
			continue;
		if (!hippoIsBot(p))
			continue;
		if (level.teamBased && p.team == self.team)
			continue;

		pt = self hippoAimPoint(p);
		if (!self.hippoOn["aimwall"])
		{
			if (!sightTracePassed(eye, pt, false, p))
				continue;
		}

		dist = distanceSquared(eye, pt);
		if (dist < bestDist)
		{
			bestDist = dist;
			best = p;
		}
	}
	return best;
}

hippoAimStep()
{
	if (self.hippoVal["aimwhen"] == 0)
	{
		if (!self adsButtonPressed())
			return;
	}

	t = self hippoBestBot();
	if (!isDefined(t))
		return;

	eye = self getEye();
	want = vectorToAngles(self hippoAimPoint(t) - eye);
	cur = self getPlayerAngles();
	f = self hippoAimFactor();

	pitch = cur[0] + (hippoAngDiff(cur[0], want[0]) * f);
	yaw = cur[1] + (hippoAngDiff(cur[1], want[1]) * f);
	self setPlayerAngles((pitch, yaw, 0));
}

// ---------------------------------------------------------------- instant kill (bots only)

hippoKillBot(t)
{
	if (!isDefined(t))
		return;
	if (!isPlayer(t))
		return;
	if (t == self)
		return;
	if (!isAlive(t))
		return;
	if (!hippoIsBot(t))
		return;
	if (level.teamBased && t.team == self.team)
		return;

	if (isDefined(level.callbackPlayerDamage))
		t [[level.callbackPlayerDamage]](self, self, 99999, 0, "MOD_HEAD_SHOT", self getCurrentWeapon(), t.origin, (0, 0, 1), "head", 0);
	else
		t suicide();
}

hippoAutoKill()
{
	if (self.hippoVal["aimwhen"] == 0)
	{
		if (!self adsButtonPressed())
			return;
	}

	t = self hippoBestBot();
	if (isDefined(t))
		self hippoKillBot(t);
}

hippoKillLoop()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("weapon_fired");

		if (!self.hippoOn["ikill"])
			continue;
		if (!isAlive(self))
			continue;

		t = undefined;
		if (self.hippoOn["aim"])
			t = self hippoBestBot();

		if (!isDefined(t))
		{
			eye = self getEye();
			fwd = anglesToForward(self getPlayerAngles());
			tr = bulletTrace(eye, eye + (fwd * 20000), true, self);
			if (isDefined(tr["entity"]))
				t = tr["entity"];
		}

		self hippoKillBot(t);
	}
}

// ---------------------------------------------------------------- one-shot actions

hippoDoAction(id)
{
	switch (id)
	{
		case "savepos":
			self.hippoSavedOrigin = self.origin;
			self.hippoSavedAngles = self getPlayerAngles();
			self iPrintLn("^5HIPPO: ^7position saved");
			break;

		case "restorepos":
			if (!isDefined(self.hippoSavedOrigin))
			{
				self iPrintLn("^5HIPPO: ^7no saved position");
				break;
			}
			self setOrigin(self.hippoSavedOrigin);
			self setPlayerAngles(self.hippoSavedAngles);
			break;

		case "tpaim":
			eye = self getEye();
			fwd = anglesToForward(self getPlayerAngles());
			tr = bulletTrace(eye, eye + (fwd * 100000), false, self);
			self setOrigin(tr["position"] + (tr["normal"] * 30));
			break;

		case "botadd":
			list = hippoCycleList("botcount");
			setDvar("bots_manage_add", list[self.hippoVal["botcount"]]);
			self iPrintLn("^5HIPPO: ^7adding bots");
			break;

		case "botkick":
			setDvar("bots_manage_fill", 0);
			n = 0;
			foreach (p in level.players)
			{
				if (p == self)
					continue;
				if (hippoIsBot(p))
				{
					kick(p getEntityNumber(), "EXE_PLAYERKICKED");
					n = n + 1;
				}
			}
			self iPrintLn("^5HIPPO: ^7kicked " + n + " bot(s)");
			break;

		case "give":
			self hippoGiveSelected();
			break;

		case "take":
			w = self getCurrentWeapon();
			if (w != "none")
			{
				self takeWeapon(w);
				prim = self getWeaponsListPrimaries();
				if (prim.size > 0)
					self switchToWeapon(prim[0]);
			}
			break;

		case "refill":
			self hippoRefillAmmo();
			break;

		case "botkill":
			n = 0;
			foreach (p in level.players)
			{
				if (p == self)
					continue;
				if (!isAlive(p))
					continue;
				if (hippoIsBot(p))
				{
					p suicide();
					n = n + 1;
				}
			}
			self iPrintLn("^5HIPPO: ^7killed " + n + " bot(s)");
			break;

		case "objspawn":
			self hippoObjSpawn();
			break;

		case "objundo":
			self hippoObjUndo();
			break;

		case "objclear":
			self hippoObjClear();
			self iPrintLn("^5HIPPO: ^7all objects deleted");
			break;

		case "objrot":
			e = self hippoObjLast();
			if (isDefined(e))
				e.angles = e.angles + (0, 45, 0);
			break;

		case "objup":
			e = self hippoObjLast();
			if (isDefined(e))
				e.origin = e.origin + (0, 0, 16);
			break;

		case "objdown":
			e = self hippoObjLast();
			if (isDefined(e))
				e.origin = e.origin - (0, 0, 16);
			break;

		case "mdlme":
			mdl = self hippoModelPick();
			if (mdl == "none")
			{
				self iPrintLn("^5HIPPO: ^7no soldier models known for this map");
				break;
			}
			setDvar("hippo_selfmodel", mdl);
			break;

		case "mdlbots":
			mdl = self hippoModelPick();
			if (mdl == "none")
			{
				self iPrintLn("^5HIPPO: ^7no soldier models known for this map");
				break;
			}
			setDvar("hippo_botmodel", mdl);
			self iPrintLn("^5HIPPO: ^7bots will look like that (they keep it after respawning)");
			break;

		case "mdlresetme":
			setDvar("hippo_selfmodel", "");
			if (isAlive(self))
				self suicide();
			break;

		case "mdlresetbots":
			setDvar("hippo_botmodel", "");
			break;

		case "helispawn":
			if (!isDefined(level.hippoHeli))
			{
				self iPrintLn("^5HIPPO: ^7install OPTIONAL\\hippo_heli.gsc first");
				break;
			}
			setDvar("hippo_heli_who", self getEntityNumber());
			setDvar("hippo_heli_do", "spawn");
			break;

		case "heliremove":
			setDvar("hippo_heli_who", self getEntityNumber());
			setDvar("hippo_heli_do", "remove");
			break;

		case "bannertest":
			self hippoBanner("HIPPO", "KUSH MODE", "420");
			break;

		case "resetall":
			self hippoResetAll();
			break;

		case "perkgive":
			self hippoPerkCmd("give");
			break;

		case "perkremove":
			self hippoPerkCmd("remove");
			break;

		case "perkall":
			self hippoPerkCmd("all");
			break;

		case "perkclear":
			self hippoPerkCmd("clear");
			break;

		case "moderestart":
			setDvar("hippo_modereset", "1");
			break;

		case "visionreset":
			self hippoVisionApply("default");
			self.hippoVal["vision"] = 0;
			break;
	}
}

hippoGiveSelected()
{
	base = self hippoCurWeaponBase();
	name = base + "_mp";

	alist = hippoAttList(base, hippoWpnClassOf(self.hippoVal["wpn"]));
	att = alist[self.hippoVal["att"] % alist.size];
	if (att != "none")
		name = base + "_" + att + "_mp";

	self giveWeapon(name, self.hippoVal["camo"]);
	self giveMaxAmmo(name);
	self switchToWeapon(name);
}

// ---------------------------------------------------------------- fun features

hippoReapply()
{
	if (self.hippoOn["speed"])
		self setMoveSpeedScale(1.8);
}

hippoVisionApply(name)
{
	if (name == "default")
		self visionSetNakedForPlayer(getDvar("mapname"), 0.5);
	else
		self visionSetNakedForPlayer(name, 0.5);
}

// Explosive ammo: every shot makes a rocket detonate where you aim.
hippoExplosiveLoop()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("weapon_fired");

		if (!self.hippoOn["expl"])
			continue;
		if (!isAlive(self))
			continue;

		eye = self getEye();
		fwd = anglesToForward(self getPlayerAngles());
		tr = bulletTrace(eye, eye + (fwd * 8000), true, self);
		pos = tr["position"];

		if (distance(self.origin, pos) < 150)
			continue;

		magicBullet("rpg_mp", pos - (fwd * 16), pos, self);
		wait 0.12;
	}
}

// No recoil: best effort. Sets the client view-kick settings to 0 (and back to the usual values when off).
hippoRecoilApply()
{
	if (self.hippoOn["norecoil"])
	{
		self setClientDvar("bg_viewKickScale", 0);
		self setClientDvar("bg_viewKickMax", 0);
		self setClientDvar("bg_viewKickMin", 0);
		self setClientDvar("bg_viewKickRandom", 0);
		self setClientDvar("cg_viewKickScale", 0);
		self iPrintLn("^5HIPPO: ^7No Recoil on (if your gun still kicks, tell me)");
	}
	else
	{
		self setClientDvar("bg_viewKickScale", 0.8);
		self setClientDvar("bg_viewKickMax", 90);
		self setClientDvar("bg_viewKickMin", 5);
		self setClientDvar("bg_viewKickRandom", 0.4);
		self setClientDvar("cg_viewKickScale", 1);
	}
}

// Thumper rounds: every shot also fires a thumper (M79) grenade where you aim.
hippoThumpLoop()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("weapon_fired");

		if (!self.hippoOn["thump"])
			continue;
		if (!isAlive(self))
			continue;

		now = getTime();
		if ((now - self.hippoThumpTime) < 400)
			continue;
		self.hippoThumpTime = now;

		eye = self getEye();
		fwd = anglesToForward(self getPlayerAngles());
		tr = bulletTrace(eye, eye + (fwd * 8000), true, self);
		pos = tr["position"];
		dist = distance(eye, pos);

		// too close = it would blow up in your own face
		if (dist < 300)
			continue;

		// aim a little high so the lobbed grenade lands on the target
		magicBullet("m79_mp", eye + (fwd * 40), pos + (0, 0, dist * 0.05), self);
	}
}

hippoEmblemMat()
{
	list = hippoCycleList("emblem");
	v = list[self.hippoVal["emblem"] % list.size];
	if (v == "off")
		return "";
	return "rank_prestige" + v;
}

// ---------------------------------------------------------------- weapon tables

hippoWpnClasses()
{
	return strTok("pistol,machine pistol,smg,assault,sniper,shotgun,lmg,launcher", ",");
}

hippoWpnGroup(c)
{
	switch (c)
	{
		case 0:
			return strTok("beretta,usp,deserteagle,coltanaconda", ",");
		case 1:
			return strTok("glock,beretta393,pp2000,tmp", ",");
		case 2:
			return strTok("mp5k,uzi,p90,kriss,ump45", ",");
		case 3:
			return strTok("ak47,m16,m4,fn2000,masada,famas,fal,scar,tavor", ",");
		case 4:
			return strTok("barrett,wa2000,m21,cheytac", ",");
		case 5:
			return strTok("ranger,model1887,striker,aa12,m1014,spas12", ",");
		case 6:
			return strTok("rpd,sa80,mg4,m240,aug", ",");
	}
	return strTok("m79,rpg,at4,stinger,javelin,riotshield", ",");
}

hippoWpnAll()
{
	all = [];
	for (c = 0; c < 8; c++)
	{
		g = hippoWpnGroup(c);
		foreach (w in g)
			all[all.size] = w;
	}
	return all;
}

hippoWpnClassStart(c)
{
	n = 0;
	for (i = 0; i < c; i++)
	{
		g = hippoWpnGroup(i);
		n = n + g.size;
	}
	return n;
}

hippoWpnClassOf(idx)
{
	n = 0;
	for (c = 0; c < 8; c++)
	{
		g = hippoWpnGroup(c);
		if (idx < n + g.size)
			return c;
		n = n + g.size;
	}
	return 7;
}

hippoCurWeaponBase()
{
	all = hippoWpnAll();
	return all[self.hippoVal["wpn"] % all.size];
}

// attachments each gun can really take (single attachment, from the game's weapon list)
hippoAttList(base, c)
{
	if (base == "beretta" || base == "usp")
		return strTok("none,akimbo,fmj,silencer,tactical,xmags", ",");
	if (base == "deserteagle" || base == "coltanaconda")
		return strTok("none,akimbo,fmj,tactical", ",");
	if (base == "ranger" || base == "model1887")
		return strTok("none,akimbo,fmj", ",");

	switch (c)
	{
		case 1:
			return strTok("none,akimbo,eotech,fmj,reflex,silencer,xmags", ",");
		case 2:
			return strTok("none,acog,akimbo,eotech,fmj,reflex,rof,silencer,thermal,xmags", ",");
		case 3:
			return strTok("none,acog,eotech,fmj,gl,heartbeat,reflex,shotgun,silencer,thermal,xmags", ",");
		case 4:
			return strTok("none,acog,fmj,heartbeat,silencer,thermal,xmags", ",");
		case 5:
			return strTok("none,eotech,fmj,grip,reflex,silencer,xmags", ",");
		case 6:
			return strTok("none,acog,eotech,fmj,grip,heartbeat,reflex,silencer,thermal,xmags", ",");
	}
	return strTok("none", ",");
}

// ---------------------------------------------------------------- objects

// every entry is "display name:model name"
hippoObjBase()
{
	return strTok("care package:com_plasticcase_friendly,care package red:com_plasticcase_enemy,case beige:com_plasticcase_beige_big,case green:com_plasticcase_green_big_us_dirt,laptop:com_laptop_2_open,bomb case:com_bomb_objective,tnt bomb:mil_tntbomb_mp,flag:prop_flag_neutral,mig 29:vehicle_mig29_desert,cluster bomb:projectile_cbu97_clusterbomb,little bird:vehicle_little_bird_armed,heli minigun:vehicle_little_bird_minigun_right,harrier:vehicle_av8b_harrier_jet_mp,harrier opfor:vehicle_av8b_harrier_jet_opfor_mp,b2 bomber:vehicle_b2_bomber,ac130:vehicle_ac130_low_mp,ac130 big:vehicle_ac130_coop,uav:vehicle_uav_static_mp,tank wreck:vehicle_m1a1_abrams_d_static,sentry gun:sentry_minigun,minigun:weapon_minigun,silver sphere:test_sphere_silver", ",");
}

// extra vehicles / trees / props the current map itself loads
hippoObjMapExtra(map)
{
	switch (map)
	{
		case "mp_afghan":
			return strTok("jeep:vehicle_uaz_open_destructible,hummer:vehicle_hummer_destructible,big bush:foliage_pacific_bushtree02_animated,small desert bush:foliage_pacific_bushtree02_halfsize_animated,small green bush:foliage_pacific_bushtree01_halfsize_animated,tree:foliage_cod5_tree_jungle_02_animated,pine tree:foliage_cod5_tree_pine05_large_animated,oxygen orange:machinery_oxygen_tank01,oxygen green:machinery_oxygen_tank02,fuel barrel:com_barrel_russian_fuel_dirt,locker:com_locker_double,ammo crate:com_plasticcase_black_big_us_dirt,transformer:utility_transformer_ratnest01,water collector:utility_water_collector", ",");
		case "mp_derail":
			return strTok("winter jeep:vehicle_uaz_winter_destructible,pickup:vehicle_pickup_destructible_mp,army truck:vehicle_bm21_cover_destructible,gas pump:furniture_gaspump01_damaged,propane tank:com_propane_tank02,trash bin:com_trashbin01,gas trash bin:usa_gas_station_trash_bin_02,roof vent:com_roofvent2_animated,file cabinet:com_filecabinetblackclosed,tv:com_tv1_testpattern,photocopier:prop_photocopier_destructible_02,oxygen orange:machinery_oxygen_tank01,crashed satellite:crashed_satellite", ",");
		case "mp_estate":
			return strTok("white pickup:vehicle_pickup_destructible_mp,white coupe:vehicle_coupe_white_destructible,black suv:vehicle_suburban_destructible_dull,suburban:vehicle_suburban_destructible_beige,red suburban:vehicle_suburban_destructible_red,black sedan:vehicle_luxurysedan_2008_destructible,generator:machinery_generator,big transformer:com_electrical_transformer_large_dam,oxygen orange:machinery_oxygen_tank01,file cabinet:com_filecabinetblackclosed,flatscreen tv:ma_flatscreen_tv_on_wallmount_02", ",");
		case "mp_favela":
			return strTok("white hatchback:vehicle_small_hatch_white_destructible_mp,blue hatchback:vehicle_small_hatch_blue_destructible_mp,pickup:vehicle_pickup_destructible_mp,palm tree:foliage_tree_palm_bushy_3,fire hydrant:com_firehydrant,red news box:com_newspaperbox_red,blue news box:com_newspaperbox_blue,green trash bin:com_trashbin01,black trash bin:com_trashbin02,tv:com_tv2,small transformer:utility_transformer_small01,water collector:utility_water_collector,oxygen orange:machinery_oxygen_tank01,oxygen green:machinery_oxygen_tank02", ",");
		case "mp_highrise":
			return strTok("flatscreen tv:ma_flatscreen_tv_wallmount_01,black trash bin:com_trashbin02,file cabinet:com_filecabinetblackclosed,photocopier:prop_photocopier_destructible_02,oxygen orange:machinery_oxygen_tank01,oxygen green:machinery_oxygen_tank02,big transformer:com_electrical_transformer_large_dam,roof vent:com_roofvent2_animated,propane tank:com_propane_tank02,green fence:highrise_fencetarp_04,orange fence:highrise_fencetarp_05,benzin barrel:com_barrel_benzin", ",");
		case "mp_invasion":
			return strTok("red car:vehicle_80s_wagon1_red_destructible_mp,hummer:vehicle_hummer_destructible,taxi:vehicle_taxi_yellow_destructible,jeep:vehicle_uaz_open_destructible,tall palm:foliage_tree_palm_tall_1,palm:foliage_tree_palm_bushy_1,fire hydrant:com_firehydrant,gas pump:furniture_gaspump01_damaged,green trash bin:com_trashbin01,black trash bin:com_trashbin02,blue news box:com_newspaperbox_blue,red news box:com_newspaperbox_red,transformer:utility_transformer_small01", ",");
		case "mp_checkpoint":
			return strTok("truck:vehicle_moving_truck_destructible,chicken:chicken_black_white,fire hydrant:com_firehydrant,red news box:com_newspaperbox_red,blue news box:com_newspaperbox_blue,tv:com_tv1,photocopier:prop_photocopier_destructible_02,file cabinet:com_filecabinetblackclosed", ",");
		case "mp_quarry":
			return strTok("green van:vehicle_van_green_destructible,white van:vehicle_van_white_destructible,white pickup:vehicle_pickup_destructible_mp,turquoise hatchback:vehicle_small_hatch_turq_destructible_mp,jeep:vehicle_uaz_open_destructible,white truck:vehicle_moving_truck_destructible,small bush:foliage_pacific_bushtree02_animated,big bush:foliage_tree_oak_1_animated2,tall tree:foliage_cod5_tree_jungle_02_animated,generator:machinery_generator,oxygen orange:machinery_oxygen_tank01,oxygen green:machinery_oxygen_tank02,fuel barrel:com_barrel_russian_fuel_dirt,locker:com_locker_double,tv:com_tv1,photocopier:prop_photocopier_destructible_02", ",");
		case "mp_rundown":
			return strTok("white car:vehicle_small_hatch_white_destructible_mp,blue car:vehicle_small_hatch_blue_destructible_mp,jeep:vehicle_uaz_open_destructible,military truck:vehicle_bm21_mobile_bed_destructible,palm tree:foliage_tree_palm_bushy_1,small bush:foliage_pacific_fern01_animated,chicken:chicken_white,chicken black white:chicken_black_white,tv:com_tv1,tv 2:com_tv2,metal trash bin:com_trashcan_metal_closed,green trash bin:com_trashbin01,black trash bin:com_trashbin02,fire hydrant:com_firehydrant,transformer:utility_transformer_ratnest01,water collector:utility_water_collector", ",");
		case "mp_boneyard":
			return strTok("truck:vehicle_moving_truck_destructible,military truck:vehicle_bm21_mobile_bed_destructible,pickup:vehicle_pickup_destructible_mp,tree:foliage_tree_oak_1_animated2,tree 2:foliage_cod5_tree_jungle_02_animated,bush:foliage_pacific_bushtree02_animated,generator:machinery_generator,fire hydrant:com_firehydrant,black trash bin:com_trashbin02,big transformer:com_electrical_transformer_large_dam,oxygen orange:machinery_oxygen_tank01,oxygen green:machinery_oxygen_tank02", ",");
		case "mp_nightshift":
			return strTok("jeep:vehicle_uaz_open_destructible,white van:vehicle_van_white_destructible,military truck:vehicle_bm21_cover_destructible,fire hydrant:com_firehydrant,red news box:com_newspaperbox_red,blue news box:com_newspaperbox_blue,green trash bin:com_trashbin01,black trash bin:com_trashbin02,file cabinet:com_filecabinetblackclosed", ",");
		case "mp_subbase":
			return strTok("winter jeep:vehicle_uaz_winter_destructible,oxygen orange:machinery_oxygen_tank01,oxygen green:machinery_oxygen_tank02,metal trash bin:com_trashcan_metal_closed,tv:com_tv1,file cabinet:com_filecabinetblackclosed,locker:com_locker_double", ",");
		case "mp_terminal":
			return strTok("police car:vehicle_policecar_lapd_destructible,vending machine:com_vending_can_new2_lit,small bush:foliage_pacific_fern01_animated,tree:foliage_cod5_tree_pine05_large_animated,benzin barrel:com_barrel_benzin,tv:com_tv1,flatscreen tv:ma_flatscreen_tv_wallmount_02,flatscreen tv on:ma_flatscreen_tv_on_wallmount_02_static,roof vent:com_roofvent2_animated,trash bin:usa_gas_station_trash_bin_01,file cabinet:com_filecabinetblackclosed,ammo crate:com_plasticcase_black_big_us_dirt", ",");
		case "mp_underpass":
			return strTok("blue van:vehicle_van_slate_destructible,white pickup:vehicle_pickup_destructible_mp,small green bush:foliage_pacific_bushtree01_halfsize_animated,big green bush:foliage_pacific_bushtree01_animated,tall tree:foliage_cod5_tree_jungle_02_animated,tree:foliage_tree_oak_1_animated2,small bush 2:foliage_pacific_palms08_animated,chicken:chicken_black_white,locker:com_locker_double,propane tank:com_propane_tank02,water collector:utility_water_collector,oxygen orange:machinery_oxygen_tank01,oxygen green:machinery_oxygen_tank02,photocopier:prop_photocopier_destructible_02,gas trash bin:usa_gas_station_trash_bin_02,file cabinet:com_filecabinetblackclosed,transformer:utility_transformer_ratnest01,small transformer:utility_transformer_small01", ",");
	}
	return [];
}

hippoObjEntries()
{
	list = hippoObjBase();
	extra = hippoObjMapExtra(getDvar("mapname"));
	foreach (e in extra)
		list[list.size] = e;

	custom = getDvar("hippo_models");
	if (custom != "")
	{
		more = strTok(custom, " ");
		foreach (c in more)
			list[list.size] = c + ":" + c;
	}
	return list;
}

hippoObjNames()
{
	names = [];
	entries = hippoObjEntries();
	foreach (e in entries)
	{
		parts = strTok(e, ":");
		names[names.size] = parts[0];
	}
	return names;
}

hippoObjModels()
{
	models = [];
	entries = hippoObjEntries();
	foreach (e in entries)
	{
		parts = strTok(e, ":");
		models[models.size] = parts[1];
	}
	return models;
}

// call from init(): custom models from the hippo_models dvar must be precached at map load
hippoObjPrecache()
{
	custom = getDvar("hippo_models");
	if (custom == "")
		return;

	extra = strTok(custom, " ");
	foreach (e in extra)
		precacheModel(e);
}

// models every map has (vehicles etc.). Called LAST in init; turn off with: set hippo_globalmodels "0"
hippoObjPrecacheGlobal()
{
	if (getDvarInt("hippo_globalmodels") == 0)
		return;

	models = strTok("vehicle_little_bird_armed,vehicle_little_bird_minigun_right,vehicle_av8b_harrier_jet_mp,vehicle_av8b_harrier_jet_opfor_mp,vehicle_b2_bomber,vehicle_ac130_low_mp,vehicle_ac130_coop,vehicle_uav_static_mp,vehicle_m1a1_abrams_d_static,sentry_minigun,weapon_minigun,test_sphere_silver", ",");
	foreach (mdl in models)
		precacheModel(mdl);
}

hippoObjSpawn()
{
	if (self.hippoObjs.size >= 30)
	{
		self iPrintLn("^5HIPPO: ^7object limit reached (30)");
		return;
	}

	models = hippoObjModels();
	mdl = models[self.hippoVal["objsel"] % models.size];

	eye = self getEye();
	ang = self getPlayerAngles();
	fwd = anglesToForward(ang);
	tr = bulletTrace(eye, eye + (fwd * 1500), false, self);

	ent = spawn("script_model", tr["position"] + (0, 0, 4));
	self.hippoObjs[self.hippoObjs.size] = ent;
	ent setModel(mdl);
	ent.angles = (0, ang[1], 0);

	self iPrintLn("^5HIPPO: ^7spawned " + mdl);
}

hippoObjLast()
{
	n = self.hippoObjs.size;
	if (n == 0)
		return undefined;
	return self.hippoObjs[n - 1];
}

hippoObjUndo()
{
	n = self.hippoObjs.size;
	if (n == 0)
		return;

	ent = self.hippoObjs[n - 1];
	if (isDefined(ent))
		ent delete();

	keep = [];
	for (i = 0; i < n - 1; i++)
		keep[i] = self.hippoObjs[i];
	self.hippoObjs = keep;
}

hippoObjClear()
{
	foreach (e in self.hippoObjs)
	{
		if (isDefined(e))
			e delete();
	}
	self.hippoObjs = [];
}

// ---------------------------------------------------------------- reset + perks

// turns every on/off feature off again and puts the extras and the vision back to normal
hippoResetAll()
{
	ids = strTok("god ammo ufo aim aimwall ikill iauto expl thump jump speed grav third laser norecoil", " ");
	foreach (id in ids)
	{
		if (isDefined(self.hippoOn[id]))
		{
			if (self.hippoOn[id])
				self hippoDoToggle(id);
		}
	}

	xs = strTok("norecoil rapid reload spread sprint melee slowmo invis thermal radarjam", " ");
	foreach (x in xs)
		setDvar("hippo_x_" + x, "0");

	self.hippoVal["vision"] = 0;
	self hippoVisionApply("default");

	self iPrintLn("^5HIPPO: ^7everything reset");
}

// perks are applied by hippo_extras.gsc; this just leaves it a note
hippoPerkCmd(cmd)
{
	list = hippoCycleList("perk");
	setDvar("hippo_perk", list[self.hippoVal["perk"] % list.size]);
	setDvar("hippo_perkdo", cmd);
	self iPrintLn("^5HIPPO: ^7perk " + cmd);
}

// ---------------------------------------------------------------- models, sounds, banners

// Only real soldier bodies can be used: the game needs the player skeleton (head, weapon hand) on
// every player and bot, otherwise it stops with an error. So no cars, trees or animals here.
hippoBodySet(code)
{
	switch (code)
	{
		case "A":
			return strTok("mp_body_desert_tf141_assault_a,mp_body_desert_tf141_assault_b,mp_body_desert_tf141_lmg,mp_body_desert_tf141_smg,mp_body_desert_tf141_shotgun,mp_body_tf141_desert_sniper,mp_body_riot_tf141_desert", ",");
		case "B":
			return strTok("mp_body_opforce_arab_assault_a,mp_body_opforce_arab_lmg_a,mp_body_opforce_arab_shotgun_a,mp_body_opforce_arab_smg_a,mp_body_op_arab_sniper,mp_body_riot_op_arab", ",");
		case "C":
			return strTok("mp_body_ally_sniper_ghillie_desert,mp_body_op_sniper_ghillie_desert", ",");
		case "D":
			return strTok("mp_body_militia_assault_aa_blk,mp_body_militia_assault_aa_wht,mp_body_militia_lmg_aa_blk,mp_body_militia_smg_aa_blk,mp_body_op_miltia_sniper,mp_body_riot_op_militia", ",");
		case "E":
			return strTok("mp_body_forest_tf141_assault_a,mp_body_forest_tf141_assault_b,mp_body_forest_tf141_lmg,mp_body_forest_tf141_smg,mp_body_forest_tf141_shotgun,mp_body_tf141_forest_sniper,mp_body_riot_tf141_forest", ",");
		case "F":
			return strTok("mp_body_airborne_assault_a,mp_body_airborne_lmg,mp_body_airborne_smg,mp_body_airborne_shotgun,mp_body_op_airborne_sniper,mp_body_riot_op_airborne", ",");
		case "G":
			return strTok("mp_body_ally_sniper_ghillie_forest,mp_body_op_sniper_ghillie_forest", ",");
		case "H":
			return strTok("mp_body_tf141_assault_a,mp_body_tf141_assault_b,mp_body_tf141_lmg,mp_body_tf141_smg,mp_body_tf141_shotgun,mp_body_tf141_arctic_sniper,mp_body_riot_tf141_arctic", ",");
		case "I":
			return strTok("mp_body_opforce_arctic_assault_a,mp_body_opforce_arctic_lmg,mp_body_opforce_arctic_shotgun,mp_body_opforce_arctic_smg,mp_body_op_arctic_sniper,mp_body_riot_op_arctic", ",");
		case "J":
			return strTok("mp_body_ally_sniper_ghillie_arctic,mp_body_op_sniper_ghillie_arctic", ",");
		case "K":
			return strTok("mp_body_seal_udt_assault_a,mp_body_seal_udt_assault_b,mp_body_seal_udt_lmg,mp_body_seal_udt_smg,mp_body_seal_udt_sniper,mp_body_riot_udt", ",");
		case "L":
			return strTok("mp_body_us_army_assault_a,mp_body_us_army_lmg,mp_body_us_army_smg,mp_body_us_army_shotgun,mp_body_army_sniper,mp_body_us_army_riot", ",");
	}
	return strTok("mp_body_ally_sniper_ghillie_urban,mp_body_op_sniper_ghillie_urban", ",");
}

hippoModelList()
{
	codes = "";
	switch (getDvar("mapname"))
	{
		case "mp_afghan":
		case "mp_rust":
		case "mp_boneyard":
			codes = "A B C";
			break;
		case "mp_quarry":
			codes = "A D C";
			break;
		case "mp_favela":
			codes = "A D M";
			break;
		case "mp_checkpoint":
			codes = "K B M";
			break;
		case "mp_estate":
		case "mp_brecourt":
			codes = "E F G";
			break;
		case "mp_underpass":
			codes = "E D G";
			break;
		case "mp_derail":
			codes = "H I J";
			break;
		case "mp_subbase":
			codes = "K I M";
			break;
		case "mp_highrise":
		case "mp_nightshift":
		case "mp_terminal":
			codes = "L F M";
			break;
		case "mp_invasion":
			codes = "L B M";
			break;
	}

	list = [];
	if (codes == "")
	{
		list[0] = "none";
		return list;
	}

	sets = strTok(codes, " ");
	foreach (c in sets)
	{
		g = hippoBodySet(c);
		foreach (m in g)
			list[list.size] = m;
	}
	return list;
}

hippoModelNames()
{
	names = [];
	list = hippoModelList();
	foreach (m in list)
	{
		if (m == "none")
			names[names.size] = "none (unknown map)";
		else
			names[names.size] = getSubStr(m, 8, m.size);
	}
	return names;
}

hippoModelPick()
{
	models = hippoModelList();
	return models[self.hippoVal["mdl"] % models.size];
}

// plays a sound only for you, and only if Menu Sounds is on
hippoSound(snd)
{
	if (getDvarInt("hippo_sounds") != 0)
		self playLocalSound(snd);
}

// level-up style banner (needs OPTIONAL/hippo_banner.gsc), otherwise a plain screen message
hippoBanner(title, text, text2)
{
	if (!isDefined(level.hippoBanner))
	{
		self iPrintLnBold("^2" + title + " ^7" + text);
		self playLocalSound("mp_level_up");
		return;
	}

	icon = "rank_prestige10";
	if (isDefined(level.hippoWeed))
	{
		if (level.hippoWeed)
			icon = "cardicon_weed";
	}

	setDvar("hippo_banner_title", title);
	setDvar("hippo_banner_text", text);
	setDvar("hippo_banner_text2", text2);
	setDvar("hippo_banner_icon", icon);
	setDvar("hippo_banner_do", "1");
}
