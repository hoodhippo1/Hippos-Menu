// HIPPO MENU - custom game modes: Gun Game and One In The Chamber
// Standalone script (its own init). Controlled by the dvar hippo_gamemode:
//   0 = off, 1 = Gun Game, 2 = One In The Chamber
// Set from the menu (Game Modes) or the console. Works for real players AND Bot Warfare bots.
// Best played in Free For All. The mode is switched off again every time a map loads.

init()
{
	setDvar("hippo_gamemode", "0");
	setDvar("hippo_modereset", "0");

	level.hmTarget = 15;
	level thread hmOnConnect();
	level thread hmModeWatch();
}

hmOnConnect()
{
	for (;;)
	{
		level waittill("connected", player);
		player thread hmPlayer();
	}
}

hmLadder()
{
	return strTok("usp_mp,deserteagle_mp,mp5k_mp,ump45_mp,kriss_mp,spas12_mp,aa12_mp,m4_mp,scar_mp,ak47_mp,fal_mp,tavor_mp,famas_mp,m240_mp,rpd_mp,barrett_mp,cheytac_mp", ",");
}

hmKills(p)
{
	if (isDefined(p.pers))
	{
		if (isDefined(p.pers["kills"]))
			return p.pers["kills"];
	}
	if (isDefined(p.kills))
		return p.kills;
	return 0;
}

hmName(w)
{
	return getSubStr(w, 0, w.size - 3);
}

hmPlayer()
{
	self endon("disconnect");

	self.hmLevel = 0;
	self.hmScore = 0;
	self.hmBullets = 1;
	self.hmKills = hmKills(self);

	self thread hmWatch();
	self thread hmFireWatch();

	for (;;)
	{
		self waittill("spawned_player");
		self thread hmOnSpawn();
	}
}

hmOnSpawn()
{
	self endon("disconnect");
	self endon("death");

	wait 0.2;

	mode = getDvarInt("hippo_gamemode");
	if (mode == 1)
		self hmGunGive();
	if (mode == 2)
		self hmOitcGive();
}

hmFireWatch()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("weapon_fired");
		if (getDvarInt("hippo_gamemode") == 2)
		{
			if (self.hmBullets > 0)
				self.hmBullets = self.hmBullets - 1;
		}
	}
}

// counts new kills for this player every 0.1s (works for bots too)
hmWatch()
{
	self endon("disconnect");

	for (;;)
	{
		wait 0.1;

		k = hmKills(self);
		if (k < self.hmKills)
			self.hmKills = k;
		if (k == self.hmKills)
			continue;

		gained = k - self.hmKills;
		self.hmKills = k;

		mode = getDvarInt("hippo_gamemode");
		if (mode == 1)
			self hmGunAdvance(gained);
		if (mode == 2)
			self hmOitcKill(gained);
	}
}

hmModeWatch()
{
	last = getDvarInt("hippo_gamemode");

	for (;;)
	{
		wait 0.25;

		if (getDvarInt("hippo_modereset") == 1)
		{
			setDvar("hippo_modereset", "0");
			last = -1;
		}

		m = getDvarInt("hippo_gamemode");
		if (m == last)
			continue;
		last = m;

		foreach (p in level.players)
		{
			if (!isDefined(p.hmLevel))
				continue;

			p.hmLevel = 0;
			p.hmScore = 0;
			p.hmBullets = 1;
			p.hmKills = hmKills(p);

			if (m == 0)
				continue;
			if (!isAlive(p))
				continue;
			if (p.sessionstate != "playing")
				continue;

			if (m == 1)
				p hmGunGive();
			if (m == 2)
				p hmOitcGive();
		}

		if (m == 1)
			iPrintLnBold("^5GUN GAME ^7- every kill gives you the next weapon");
		if (m == 2)
			iPrintLnBold("^5ONE IN THE CHAMBER ^7- 1 bullet, kills give you more");
		if (m == 0)
			iPrintLnBold("^5HIPPO ^7game mode off - respawn for your normal class");
	}
}

// ---------------------------------------------------------------- Gun Game

hmGunGive()
{
	list = hmLadder();
	idx = self.hmLevel;
	if (idx >= list.size)
		idx = list.size - 1;

	w = list[idx];
	self takeAllWeapons();
	self giveWeapon(w);
	self giveMaxAmmo(w);
	self switchToWeapon(w);

	self iPrintLn("^5GUN GAME ^7level " + (idx + 1) + "/" + list.size + ": " + hmName(w));
}

hmGunAdvance(n)
{
	list = hmLadder();
	self.hmLevel = self.hmLevel + n;

	if (self.hmLevel >= list.size)
	{
		hmWin("GUN GAME", self.name + " wins!");
		foreach (p in level.players)
		{
			if (!isDefined(p.hmLevel))
				continue;
			p.hmLevel = 0;
			if (isAlive(p))
			{
				if (p.sessionstate == "playing")
					p hmGunGive();
			}
		}
		return;
	}

	if (isAlive(self))
	{
		if (self.sessionstate == "playing")
			self hmGunGive();
	}
}

// ---------------------------------------------------------------- One In The Chamber

hmOitcGive()
{
	w = "deserteagle_mp";

	self takeAllWeapons();
	self giveWeapon(w);
	self switchToWeapon(w);
	self.hmBullets = 1;
	self setWeaponAmmoClip(w, 1);
	self setWeaponAmmoStock(w, 0);

	self iPrintLn("^5ONE IN THE CHAMBER ^7- score " + self.hmScore + "/" + level.hmTarget);
}

hmOitcKill(n)
{
	self.hmScore = self.hmScore + n;
	self.hmBullets = self.hmBullets + n;
	if (self.hmBullets > 7)
		self.hmBullets = 7;

	if (self.hmScore >= level.hmTarget)
	{
		hmWin("ONE IN THE CHAMBER", self.name + " wins!");
		foreach (p in level.players)
		{
			if (!isDefined(p.hmScore))
				continue;
			p.hmScore = 0;
			p.hmBullets = 1;
			if (isAlive(p))
			{
				if (p.sessionstate == "playing")
					p hmOitcGive();
			}
		}
		return;
	}

	if (isAlive(self))
	{
		if (self.sessionstate == "playing")
		{
			self setWeaponAmmoClip("deserteagle_mp", self.hmBullets);
			self iPrintLn("^5ONE IN THE CHAMBER ^7- +" + n + " bullet, score " + self.hmScore + "/" + level.hmTarget);
		}
	}
}

// ---------------------------------------------------------------- winner announcement

hmIsHuman(p)
{
	if (isDefined(p.pers))
	{
		if (isDefined(p.pers["isBot"]))
		{
			if (p.pers["isBot"])
				return false;
		}
	}
	if (isDefined(p.guid))
	{
		if (isSubStr(p.guid, "bot"))
			return false;
	}
	return true;
}

// uses the level-up banner if OPTIONAL/hippo_banner.gsc is installed, otherwise a screen message + sound
hmWin(title, text)
{
	if (isDefined(level.hippoBanner))
	{
		setDvar("hippo_banner_title", title);
		setDvar("hippo_banner_text", text);
		setDvar("hippo_banner_text2", "");
		setDvar("hippo_banner_icon", "rank_prestige10");
		setDvar("hippo_banner_do", "1");
		return;
	}

	iPrintLnBold("^5" + title + ": ^7" + text);
	foreach (p in level.players)
	{
		if (hmIsHuman(p))
			p playLocalSound("mp_level_up");
	}
}
