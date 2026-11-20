// HIPPO MENU - OPTIONAL armed helicopter (experimental) - v2: UFO-style flight
// Copy into userraw\scripts to enable, delete to disable.
// Menu: Cosmetics > Helicopter > Spawn And Ride.
//
// How it works: you fly with the game's own free-look (UFO) camera, so the movement keys always
// work: WASD move, jump = up, crouch = down, mouse = direction. A Little Bird model
// (vehicle_little_bird_armed) follows your position and turns with your view.
//   flash grenade key (the special grenade key) = machine guns, hold for automatic fire
//   frag grenade key = missiles with a cooldown
//   (both can be changed in the menu: Gun Button / Missile Button). Land from the menu: soft landing.
// If the game shows a compile error naming hippo_heli.gsc, delete this file.

init()
{
	level.hippoHeli = true;
	setDvar("hippo_heli_do", "");
	setDvar("hippo_heli_who", "");

	level thread hhWatch();

	// last on purpose
	precacheModel("vehicle_little_bird_armed");
	precacheItem("ac130_25mm_mp");
	precacheItem("rpg_mp");
}

hhPlayerByNum(num)
{
	foreach (p in level.players)
	{
		if (p getEntityNumber() == num)
			return p;
	}
	return undefined;
}

hhWatch()
{
	for (;;)
	{
		wait 0.25;

		cmd = getDvar("hippo_heli_do");
		if (cmd == "")
			continue;
		setDvar("hippo_heli_do", "");

		p = hhPlayerByNum(getDvarInt("hippo_heli_who"));
		if (!isDefined(p))
			continue;

		if (cmd == "spawn")
			p thread hhSpawn();
		if (cmd == "remove")
			p notify("hh_leave");
	}
}

// ---------------------------------------------------------------- settings

hhCooldown()
{
	v = getDvarInt("hippo_heli_cd");
	if (v == 0)
		return 700;
	if (v == 2)
		return 3000;
	return 1500;
}

hhSpeedScale()
{
	v = getDvarInt("hippo_heli_speed");
	if (v == 0)
		return 0.7;
	if (v == 2)
		return 3.0;
	return 1.5;
}

// missile button: 0 = frag grenade key (default), 1 = aim, 2 = melee, 3 = use
hhMissilePressed()
{
	b = getDvarInt("hippo_heli_btn");
	if (b == 1)
		return self adsButtonPressed();
	if (b == 2)
		return self meleeButtonPressed();
	if (b == 3)
		return self useButtonPressed();
	return self fragButtonPressed();
}

// gun button: 0 = flash grenade key (default), 1 = fire
hhGunPressed()
{
	if (getDvarInt("hippo_heli_gun") == 1)
		return self attackButtonPressed();

	if (isDefined(self.hhFlash))
		return (self.hhFlash == 1);
	return false;
}

hhFlashListen(note, val)
{
	self endon("disconnect");

	for (;;)
	{
		self waittill(note);
		self.hhFlash = val;
	}
}

// the special-grenade key (flash / stun / smoke) is read as a command, press and release
hhKeys()
{
	if (isDefined(self.hhKeysSet))
		return;
	self.hhKeysSet = true;
	self.hhFlash = 0;

	self notifyOnPlayerCommand("hh_s1", "+smoke");
	self notifyOnPlayerCommand("hh_s0", "-smoke");
	self thread hhFlashListen("hh_s1", 1);
	self thread hhFlashListen("hh_s0", 0);
}

hhClamp(v, lo, hi)
{
	if (v < lo)
		return lo;
	if (v > hi)
		return hi;
	return v;
}

// ---------------------------------------------------------------- start / stop

hhGuard(heli)
{
	self endon("hh_done");
	self waittill("disconnect");
	if (isDefined(heli))
		heli delete();
}

hhLeaveWatch()
{
	self endon("disconnect");
	self endon("hh_done");

	for (;;)
	{
		self waittill("hh_leave");
		self.hhLeave = true;
	}
}

hhSpawn()
{
	self endon("disconnect");

	if (isDefined(self.hhHeli))
		return;
	if (!isAlive(self))
		return;
	if (self.sessionstate != "playing")
		return;

	start = self.origin;
	ang = self getPlayerAngles();

	heli = spawn("script_model", start);
	self.hhHeli = heli;
	heli setModel("vehicle_little_bird_armed");
	heli.angles = (0, ang[1], 0);

	self.hhLeave = undefined;
	self hhKeys();
	self thread hhGuard(heli);
	self thread hhLeaveWatch();

	// free-look flight (same as the menu's UFO mode)
	self allowSpectateTeam("freelook", true);
	self.sessionstate = "spectator";
	if (isDefined(self.hippoOn))
		self.hippoOn["ufo"] = true;

	self iPrintLn("^5HIPPO: ^7helicopter - WASD move, jump up, crouch down, mouse steers, flash grenade key = guns, frag grenade key = missiles");

	self thread hhFly(heli, start);
}

hhLand(heli, groundZ)
{
	self.hhHeli = undefined;
	self.hhLeave = undefined;

	if (self.sessionstate == "spectator")
	{
		org = self.origin;
		ang = self getPlayerAngles();

		// slow descent
		steps = 20;
		for (i = 1; i <= steps; i++)
		{
			z = org[2] - ((org[2] - groundZ) * i / steps);
			self setOrigin((org[0], org[1], z));
			if (isDefined(heli))
				heli moveTo((org[0], org[1], z - 48), 0.05);
			wait 0.05;
		}

		self allowSpectateTeam("freelook", false);
		self.sessionstate = "playing";
		self setOrigin((org[0], org[1], groundZ + 6));
		self setPlayerAngles(ang);
	}

	if (isDefined(self.hippoOn))
		self.hippoOn["ufo"] = false;

	self notify("hh_done");

	if (isDefined(heli))
		heli delete();
}

// ---------------------------------------------------------------- flight + weapons

hhFly(heli, start)
{
	self endon("disconnect");

	// smooth takeoff
	for (i = 1; i <= 20; i++)
	{
		if (!isDefined(heli))
			return;
		self setOrigin(start + (0, 0, i * 6));
		heli moveTo(start + (0, 0, (i * 6) - 48), 0.05);
		wait 0.05;
	}

	last = self.origin;
	tick = 0;
	lastMissile = 0;
	side = 1;
	curScale = -1;
	groundZ = start[2];

	for (;;)
	{
		wait 0.05;
		tick = tick + 1;

		if (!isDefined(heli))
			break;
		if (self.sessionstate != "spectator")
			break;
		if (isDefined(self.hhLeave))
			break;

		// speed setting (free-look camera speed)
		sc = hhSpeedScale();
		if (sc != curScale)
		{
			curScale = sc;
			setDvar("player_spectateSpeedScale", sc);
		}

		org = self.origin;
		ang = self getPlayerAngles();
		yaw = ang[1];

		// how fast we are moving forward / sideways: used to tilt the helicopter
		vel = (org - last) * 20;
		last = org;
		hfwd = anglesToForward((0, yaw, 0));
		hrgt = anglesToRight((0, yaw, 0));
		fs = (vel[0] * hfwd[0]) + (vel[1] * hfwd[1]);
		ls = (vel[0] * hrgt[0]) + (vel[1] * hrgt[1]);
		pitch = hhClamp(fs / 40, -10, 14);
		roll = hhClamp(ls / 40, -16, 16);

		// the helicopter follows the player, turned the way the player looks
		heli.angles = (pitch, yaw, roll);
		heli moveTo(org + (0, 0, -48), 0.08);

		// ground height below us (for the soft landing later)
		gtr = bulletTrace(org, org - (0, 0, 4000), false, heli);
		gp = gtr["position"];
		groundZ = gp[2];

		// aiming: shoot at whatever the crosshair points at
		vf = anglesToForward(ang);
		atr = bulletTrace(org, org + (vf * 8000), false, heli);
		aimPos = atr["position"];

		nf = anglesToForward(heli.angles);
		nr = anglesToRight(heli.angles);
		muzzle = heli.origin + (nf * 230) + (nr * (side * 45)) + (0, 0, 6);
		shot = anglesToForward(vectorToAngles(aimPos - muzzle));

		// machine guns, automatic while fire is held
		if (self hhGunPressed() && (tick % 2) == 0)
		{
			side = 0 - side;
			magicBullet("ac130_25mm_mp", muzzle, muzzle + (shot * 9000), self);
			if ((tick % 4) == 0)
				heli playSound("weap_cobra_20mm_fire_npc");
		}

		// missiles with cooldown
		if (self hhMissilePressed() && (getTime() - lastMissile) > hhCooldown())
		{
			lastMissile = getTime();
			side = 0 - side;
			magicBullet("rpg_mp", muzzle, muzzle + (shot * 9000), self);
			heli playSound("weap_cobra_missile_fire");
		}
	}

	self hhLand(heli, groundZ);
}
