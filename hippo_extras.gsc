// HIPPO MENU - extras (separate script on purpose)
// Switched by the dvars hippo_x_<name> (1 = on, 0 = off) from the menu: Extras.
// If the game shows a compile error naming hippo_extras.gsc, delete this file; the rest of the
// menu keeps working (the Extras switches then do nothing).
// Applies to human players. Everything starts off each time a map loads.

init()
{
	level.hxIds = strTok("norecoil rapid reload spread sprint melee slowmo invis thermal radarjam", " ");
	level.hxPerks = strTok("extendedmelee fastsprintrecovery automantle spygame improvedholdbreath fastsnipe selectivehearing heartbreaker coldblooded quickdraw marathon lightweight extendedmags scavenger explosivebullets jumpdive fastmantle specialgrenade fraggrenade armorvest twoprimaries extraammo bulletdamage exposeenemy detectexplosive longersprint parabolic quieter pistoldeath grenadepulldeath bulletpenetration holdbreath rof fastreload bulletaccuracy gpsjammer", " ");
	setDvar("hippo_perkdo", "");
	setDvar("hippo_perk", "bulletdamage");
	foreach (id in level.hxIds)
		setDvar("hippo_x_" + id, "0");

	setDvar("hippo_x_moneytrail", "0");
	setDvar("hippo_x_moneygun", "0");
	setDvar("hippo_selfmodel", "");
	setDvar("hippo_botmodel", "");

	level thread hxOnConnect();

	// last on purpose: the cash effect (if the game does not already have it)
	hxMoneyInit();
}

hxIsBot(p)
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

hxOnConnect()
{
	for (;;)
	{
		level waittill("connected", player);
		player thread hxPlayer();
	}
}

hxPlayer()
{
	self endon("disconnect");

	wait 3;
	if (hxIsBot(self))
	{
		self thread hxBot();
		return;
	}

	self.hxSelfModel = "";
	self thread hxMoneyTrail();
	self thread hxMoneyGun();

	self.hxLast = [];
	foreach (id in level.hxIds)
		self.hxLast[id] = 0;

	self thread hxSpawnWatch();

	for (;;)
	{
		wait 0.25;

		self hxPerkCmd();
		self hxSelfModelCheck();

		foreach (id in level.hxIds)
		{
			v = getDvarInt("hippo_x_" + id);
			if (v == self.hxLast[id])
				continue;

			self.hxLast[id] = v;
			self hxApply(id, v);
		}
	}
}

// perks, hiding and the like are reset when you respawn, so put them back
hxSpawnWatch()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("spawned_player");
		wait 0.5;

		foreach (id in level.hxIds)
		{
			if (self.hxLast[id] != 0)
				self hxApply(id, self.hxLast[id]);
		}

		if (self.hxSelfModel != "")
			self hxApplyModel(self.hxSelfModel);
	}
}

hxApply(id, on)
{
	switch (id)
	{
		case "norecoil":
			if (on)
				self player_recoilScaleOn(0);
			else
				self player_recoilScaleOn(100);
			break;

		case "rapid":
			if (on)
			{
				setDvar("perk_weapRateMultiplier", 0.4);
				self setPerk("specialty_rof", true);
			}
			else
			{
				self unsetPerk("specialty_rof", true);
				setDvar("perk_weapRateMultiplier", 0.75);
			}
			break;

		case "reload":
			if (on)
			{
				setDvar("perk_weapReloadMultiplier", 0.3);
				self setPerk("specialty_fastreload", true);
			}
			else
			{
				self unsetPerk("specialty_fastreload", true);
				setDvar("perk_weapReloadMultiplier", 0.5);
			}
			break;

		case "spread":
			if (on)
			{
				setDvar("perk_weapSpreadMultiplier", 0.0001);
				self setPerk("specialty_bulletaccuracy", true);
			}
			else
			{
				self unsetPerk("specialty_bulletaccuracy", true);
				setDvar("perk_weapSpreadMultiplier", 0.6);
			}
			break;

		case "sprint":
			setDvar("player_sprintUnlimited", on);
			break;

		case "melee":
			if (on)
				setDvar("player_meleeRange", 250);
			else
				setDvar("player_meleeRange", 64);
			break;

		case "slowmo":
			if (on)
				setDvar("timescale", 0.5);
			else
				setDvar("timescale", 1);
			break;

		case "invis":
			if (on)
				self hide();
			else
				self show();
			break;

		case "thermal":
			if (on)
				self ThermalVisionFOFOverlayOn();
			else
				self ThermalVisionFOFOverlayOff();
			break;

		case "radarjam":
			if (on)
				self RadarJamOn();
			else
				self RadarJamOff();
			break;
	}
}

// perk requests from the menu (Extras > Perks)
hxPerkCmd()
{
	cmd = getDvar("hippo_perkdo");
	if (cmd == "")
		return;
	setDvar("hippo_perkdo", "");

	perk = getDvar("hippo_perk");

	if (cmd == "give")
		self setPerk("specialty_" + perk, true);
	if (cmd == "remove")
		self unsetPerk("specialty_" + perk, true);

	if (cmd == "all")
	{
		foreach (p in level.hxPerks)
			self setPerk("specialty_" + p, true);
	}
	if (cmd == "clear")
	{
		foreach (p in level.hxPerks)
			self unsetPerk("specialty_" + p, true);
	}
}

// ---------------------------------------------------------------- models (you and the bots)

hxApplyModel(m)
{
	// safety: only soldier bodies. Anything without the player skeleton (cars, trees, animals)
	// makes the game stop with "Cannot find tag [j_head]".
	if (!isSubStr(m, "mp_body_"))
		return;
	if (!isAlive(self))
		return;
	self setModel(m);
}

// you: model changes from the menu (Cosmetics > Models)
hxSelfModelCheck()
{
	m = getDvar("hippo_selfmodel");
	if (m == self.hxSelfModel)
		return;

	self.hxSelfModel = m;
	if (m != "")
		self hxApplyModel(m);
}

// bots: every bot follows the hippo_botmodel dvar and keeps it after respawning
hxBot()
{
	self endon("disconnect");

	self.hxBotModel = "";
	self thread hxBotSpawn();

	for (;;)
	{
		wait 0.5;

		m = getDvar("hippo_botmodel");
		if (m == self.hxBotModel)
			continue;

		self.hxBotModel = m;
		if (m != "")
			self hxApplyModel(m);
		else if (isAlive(self))
			self suicide();
	}
}

hxBotSpawn()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("spawned_player");
		wait 0.5;

		if (self.hxBotModel != "")
			self hxApplyModel(self.hxBotModel);
	}
}

// ---------------------------------------------------------------- money trail + money gun

hxMoneyInit()
{
	level.hxMoney = undefined;

	if (isDefined(level._effect))
	{
		if (isDefined(level._effect["money"]))
			level.hxMoney = level._effect["money"];
	}

	if (!isDefined(level.hxMoney))
		level.hxMoney = loadFx("props/cash_player_drop");
}

hxMoneyTrail()
{
	self endon("disconnect");

	for (;;)
	{
		wait 0.3;

		if (getDvarInt("hippo_x_moneytrail") == 0)
			continue;
		if (!isAlive(self))
			continue;
		if (!isDefined(level.hxMoney))
			continue;

		playFx(level.hxMoney, self.origin + (0, 0, 48));
	}
}

hxMoneyGun()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("weapon_fired");

		if (getDvarInt("hippo_x_moneygun") == 0)
			continue;
		if (!isDefined(level.hxMoney))
			continue;

		eye = self getEye();
		fwd = anglesToForward(self getPlayerAngles());
		tr = bulletTrace(eye, eye + (fwd * 3000), true, self);
		pos = tr["position"];
		d = distance(eye, pos);

		playFx(level.hxMoney, pos + (0, 0, 20));
		if (d > 300)
			playFx(level.hxMoney, eye + (fwd * (d * 0.5)));
		if (d > 700)
			playFx(level.hxMoney, eye + (fwd * (d * 0.25)));

		wait 0.1;
	}
}
