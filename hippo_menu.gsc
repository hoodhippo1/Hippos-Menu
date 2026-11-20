// HIPPO MENU - main script (blue/black in-game menu for private bot matches)
// Needs _hippo_actions.gsc and _hippo_ui.gsc in the same folder.

#include scripts\_hippo_actions;
#include scripts\_hippo_ui;

init()
{
	hippoDvarDefault("hippo_key_open", "9");
	hippoDvarDefault("hippo_key_up", "UPARROW");
	hippoDvarDefault("hippo_key_down", "DOWNARROW");
	hippoDvarDefault("hippo_key_select", "ENTER");
	hippoDvarDefault("hippo_key_back", "BACKSPACE");
	hippoDvarDefault("hippo_animations", "1");
	hippoDvarDefault("hippo_side", "0");
	hippoDvarDefault("hippo_theme", "0");
	hippoDvarDefault("hippo_emblem", "0");
	hippoDvarDefault("hippo_textures", "1");
	hippoDvarDefault("hippo_weedicon", "1");
	hippoDvarDefault("hippo_kushhud", "1");
	hippoDvarDefault("hippo_sounds", "0");
	hippoDvarDefault("hippo_globalmodels", "1");
	hippoDvarDefault("hippo_heli_speed", "1");
	hippoDvarDefault("hippo_heli_btn", "0");
	hippoDvarDefault("hippo_heli_gun", "0");
	hippoDvarDefault("hippo_heli_cd", "1");

	// switches for hippo_extras.gsc (all start off)
	xs = strTok("norecoil rapid reload spread sprint melee slowmo invis thermal radarjam moneytrail moneygun", " ");
	foreach (x in xs)
		hippoDvarDefault("hippo_x_" + x, "0");

	// textures must be precached while the map loads
	level.hippoTex = (getDvarInt("hippo_textures") != 0);
	if (level.hippoTex)
	{
		precacheShader("gradient_fadein");
		for (i = 1; i <= 10; i++)
			precacheShader("rank_prestige" + i);

		level.hippoWeed = false;
		if (getDvarInt("hippo_weedicon") != 0)
		{
			precacheShader("cardicon_weed");
			level.hippoWeed = true;
		}
	}

	hippoObjPrecache();

	level thread hippoOnPlayerConnect();

	// last on purpose: thumper rounds need the M79 loaded, the Objects list needs its vehicles loaded
	precacheItem("m79_mp");
	hippoObjPrecacheGlobal();
}

hippoOnPlayerConnect()
{
	for (;;)
	{
		level waittill("connected", player);

		if (hippoIsBot(player))
			continue;

		player thread hippoPlayerSetup();
	}
}

hippoPlayerSetup()
{
	self endon("disconnect");

	self hippoInitState();
	self.hippoIsOpen = false;
	self.hippoMenuName = "main";
	self.hippoSel = 0;
	self.hippoStack = [];
	self.hippoSelStack = [];
	self.hippoUi = [];
	self.hippoRows = [];

	// commands are registered after the first spawn
	self waittill("spawned_player");

	self notifyOnPlayerCommand("hippo_toggle", "+hippo_toggle");
	self notifyOnPlayerCommand("hippo_up", "+hippo_up");
	self notifyOnPlayerCommand("hippo_down", "+hippo_down");
	self notifyOnPlayerCommand("hippo_select", "+hippo_select");
	self notifyOnPlayerCommand("hippo_back", "+hippo_back");

	self thread hippoListen("hippo_toggle");
	self thread hippoListen("hippo_up");
	self thread hippoListen("hippo_down");
	self thread hippoListen("hippo_select");
	self thread hippoListen("hippo_back");
	self thread hippoFeatureLoop();
	self thread hippoExplosiveLoop();
	self thread hippoThumpLoop();
	self thread hippoKillLoop();

	self hippoOnSpawn();
	self iPrintLn("^5HIPPO MENU^7 loaded - press ^3" + getDvar("hippo_key_open") + "^7 to open");

	for (;;)
	{
		self waittill("spawned_player");
		self hippoOnSpawn();
	}
}

hippoOnSpawn()
{
	self.hippoOn["ufo"] = false;
	self hippoBindKeys();
	self hippoReapply();
	self hippoKushRefresh();
}

hippoListen(note)
{
	self endon("disconnect");

	for (;;)
	{
		self waittill(note);
		self hippoHandle(note);
	}
}

hippoHandle(note)
{
	if (note == "hippo_toggle")
	{
		if (self.hippoIsOpen)
			self hippoClose();
		else if (isAlive(self) || self.hippoOn["ufo"])
			self hippoOpen();
		return;
	}

	if (!self.hippoIsOpen)
		return;

	switch (note)
	{
		case "hippo_up":
			self hippoMove(-1);
			break;
		case "hippo_down":
			self hippoMove(1);
			break;
		case "hippo_select":
			self hippoSelect();
			break;
		case "hippo_back":
			self hippoBack();
			break;
	}
}

// ---------------------------------------------------------------- open / close / render

hippoMode(slide)
{
	if (!self.hippoOn["anim"])
		return 0;
	if (slide)
		return 1;
	return 2;
}

hippoOpen()
{
	self.hippoIsOpen = true;
	self.hippoMenuName = "main";
	self.hippoSel = 0;
	self.hippoStack = [];
	self.hippoSelStack = [];
	self hippoKushHudOff();
	self hippoRender(self hippoMode(true));
	self thread hippoCloseOnDeath();
}

hippoClose()
{
	self.hippoIsOpen = false;
	self notify("hippo_closed");
	self hippoUiDestroy();
	self hippoKushRefresh();
}

hippoCloseOnDeath()
{
	self endon("disconnect");
	self endon("hippo_closed");
	self waittill("death");
	self.hippoIsOpen = false;
	self hippoUiDestroy();
}

hippoRender(mode)
{
	items = hippoMenuDef(self.hippoMenuName);
	labels = [];
	for (i = 0; i < items.size; i++)
		labels[i] = self hippoItemText(items[i]);

	self hippoUiBuild(hippoMenuTitle(self.hippoMenuName), labels, self.hippoSel, mode, self hippoEmblemMat());
}

// ---------------------------------------------------------------- navigation

hippoMove(dir)
{
	items = hippoMenuDef(self.hippoMenuName);
	n = items.size;

	self.hippoSel = self.hippoSel + dir;
	if (self.hippoSel < 0)
		self.hippoSel = n - 1;
	if (self.hippoSel >= n)
		self.hippoSel = 0;

	self hippoSound("ui_mp_suitcasebomb_timer");
	self hippoUiSelect(self.hippoSel);
}

hippoBack()
{
	n = self.hippoStack.size;
	if (n == 0)
	{
		self hippoClose();
		return;
	}

	self.hippoMenuName = self.hippoStack[n - 1];
	self.hippoSel = self.hippoSelStack[n - 1];

	newStack = [];
	newSel = [];
	for (i = 0; i < n - 1; i++)
	{
		newStack[i] = self.hippoStack[i];
		newSel[i] = self.hippoSelStack[i];
	}
	self.hippoStack = newStack;
	self.hippoSelStack = newSel;

	self hippoRender(self hippoMode(false));
}

hippoSelect()
{
	items = hippoMenuDef(self.hippoMenuName);
	item = items[self.hippoSel];
	arg = item["arg"];

	self hippoSound("ui_mp_suitcasebomb_timer");

	switch (item["type"])
	{
		case "menu":
			self.hippoStack[self.hippoStack.size] = self.hippoMenuName;
			self.hippoSelStack[self.hippoSelStack.size] = self.hippoSel;
			self.hippoMenuName = arg;
			self.hippoSel = 0;
			self hippoRender(self hippoMode(false));
			break;

		case "back":
			self hippoBack();
			break;

		case "close":
			self hippoClose();
			break;

		case "toggle":
			self hippoDoToggle(arg);
			self hippoUiSetRow(self.hippoSel, self hippoItemText(item));
			break;

		case "dvar":
			hippoDvarToggle(arg);
			self hippoUiSetRow(self.hippoSel, self hippoItemText(item));
			break;

		case "cycle":
			self hippoDoCycle(arg);
			if (arg == "theme")
			{
				if (self.hippoVal["theme"] == 6)
					self hippoBanner("HIPPO", "KUSH MODE", "");
			}
			if (arg == "side")
				self hippoRender(self hippoMode(true));
			else if (arg == "theme" || arg == "emblem")
				self hippoRender(self hippoMode(false));
			else
				self hippoUiSetRow(self.hippoSel, self hippoItemText(item));
			break;

		case "action":
			self hippoDoAction(arg);
			break;
	}
}

// ---------------------------------------------------------------- menu data

hippoItem(label, type, arg)
{
	i = [];
	i["label"] = label;
	i["type"] = type;
	i["arg"] = arg;
	return i;
}

hippoAdd(m, item)
{
	m[m.size] = item;
	return m;
}

hippoMenuTitle(name)
{
	switch (name)
	{
		case "main":
			return "MAIN";
		case "botaim":
            		return "BOTS / AIMBOT";
        	case "sandbox":
            		return "SANDBOX";
		case "player":
			return "PLAYER";
		case "bots":
			return "BOTS";
		case "weapons":
			return "WEAPONS";
		case "fun":
			return "FUN & VISUAL";
		case "cosmetic":
			return "COSMETICS";
		case "heli":
			return "HELICOPTER";
		case "models":
			return "MODELS";
		case "perks":
			return "PERKS";
		case "extras":
			return "EXTRAS";
		case "objects":
			return "OBJECTS";
		case "modes":
			return "GAME MODES";
		case "aim":
			return "AIM OPTIONS";
		case "look":
			return "APPEARANCE";
		case "controls":
			return "CONTROLS";
	}
	return "MENU";
}

hippoMenuDef(name)
{
	m = [];

	switch (name)
	{
		        case "main":
            m = hippoAdd(m, hippoItem("Player", "menu", "player"));
            m = hippoAdd(m, hippoItem("Fun", "menu", "fun"));
            m = hippoAdd(m, hippoItem("Bots/Aimbot", "menu", "botaim"));
            m = hippoAdd(m, hippoItem("Sandbox", "menu", "sandbox"));
            m = hippoAdd(m, hippoItem("Settings", "menu", "look"));
            break;

		case "perks":
			m = hippoAdd(m, hippoItem("Perk", "cycle", "perk"));
			m = hippoAdd(m, hippoItem("Give Perk", "action", "perkgive"));
			m = hippoAdd(m, hippoItem("Remove Perk", "action", "perkremove"));
			m = hippoAdd(m, hippoItem("Give All Perks", "action", "perkall"));
			m = hippoAdd(m, hippoItem("Clear All Perks", "action", "perkclear"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "extras":
			m = hippoAdd(m, hippoItem("Perks", "menu", "perks"));
			m = hippoAdd(m, hippoItem("No Recoil", "dvar", "hippo_x_norecoil"));
			m = hippoAdd(m, hippoItem("Rapid Fire", "dvar", "hippo_x_rapid"));
			m = hippoAdd(m, hippoItem("Fast Reload", "dvar", "hippo_x_reload"));
			m = hippoAdd(m, hippoItem("No Spread", "dvar", "hippo_x_spread"));
			m = hippoAdd(m, hippoItem("Unlimited Sprint", "dvar", "hippo_x_sprint"));
			m = hippoAdd(m, hippoItem("Long Melee", "dvar", "hippo_x_melee"));
			m = hippoAdd(m, hippoItem("Slow Motion", "dvar", "hippo_x_slowmo"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "cosmetic":
			m = hippoAdd(m, hippoItem("Models", "menu", "models"));
			m = hippoAdd(m, hippoItem("Helicopter", "menu", "heli"));
			m = hippoAdd(m, hippoItem("Money Trail", "dvar", "hippo_x_moneytrail"));
			m = hippoAdd(m, hippoItem("Money Gun", "dvar", "hippo_x_moneygun"));
			m = hippoAdd(m, hippoItem("Invisible", "dvar", "hippo_x_invis"));
			m = hippoAdd(m, hippoItem("Thermal Overlay", "dvar", "hippo_x_thermal"));
			m = hippoAdd(m, hippoItem("Jam Radar", "dvar", "hippo_x_radarjam"));
			m = hippoAdd(m, hippoItem("Menu Click Sound", "dvar", "hippo_sounds"));
			m = hippoAdd(m, hippoItem("Test Banner", "action", "bannertest"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "heli":
			m = hippoAdd(m, hippoItem("Spawn And Ride", "action", "helispawn"));
			m = hippoAdd(m, hippoItem("Land Helicopter", "action", "heliremove"));
			m = hippoAdd(m, hippoItem("Flight Speed", "cycle", "helispeed"));
			m = hippoAdd(m, hippoItem("Missile Button", "cycle", "helibtn"));
			m = hippoAdd(m, hippoItem("Gun Button", "cycle", "heligun"));
			m = hippoAdd(m, hippoItem("Missile Reload", "cycle", "helicd"));
			m = hippoAdd(m, hippoItem("Flash = guns, Frag = missiles", "info", ""));
			m = hippoAdd(m, hippoItem("Needs OPTIONAL hippo_heli.gsc", "info", ""));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "models":
			m = hippoAdd(m, hippoItem("Model", "cycle", "mdl"));
			m = hippoAdd(m, hippoItem("Swap Me", "action", "mdlme"));
			m = hippoAdd(m, hippoItem("Swap All Bots", "action", "mdlbots"));
			m = hippoAdd(m, hippoItem("Reset Me", "action", "mdlresetme"));
			m = hippoAdd(m, hippoItem("Reset Bots", "action", "mdlresetbots"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "objects":
			m = hippoAdd(m, hippoItem("Object", "cycle", "objsel"));
			m = hippoAdd(m, hippoItem("Spawn At Crosshair", "action", "objspawn"));
			m = hippoAdd(m, hippoItem("Delete Last", "action", "objundo"));
			m = hippoAdd(m, hippoItem("Delete All", "action", "objclear"));
			m = hippoAdd(m, hippoItem("Rotate Last", "action", "objrot"));
			m = hippoAdd(m, hippoItem("Raise Last", "action", "objup"));
			m = hippoAdd(m, hippoItem("Lower Last", "action", "objdown"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "modes":
			m = hippoAdd(m, hippoItem("Mode", "cycle", "gmode"));
			m = hippoAdd(m, hippoItem("Restart Mode", "action", "moderestart"));
			m = hippoAdd(m, hippoItem("Gun Game: kill = next gun", "info", ""));
			m = hippoAdd(m, hippoItem("OITC: 1 bullet, kill = more", "info", ""));
			m = hippoAdd(m, hippoItem("Best in Free For All", "info", ""));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "player":
			m = hippoAdd(m, hippoItem("God Mode", "toggle", "god"));
			m = hippoAdd(m, hippoItem("Infinite Ammo", "toggle", "ammo"));
			m = hippoAdd(m, hippoItem("UFO Mode", "toggle", "ufo"));
			m = hippoAdd(m, hippoItem("Save Position", "action", "savepos"));
			m = hippoAdd(m, hippoItem("Restore Position", "action", "restorepos"));
			m = hippoAdd(m, hippoItem("Teleport To Crosshair", "action", "tpaim"));
			m = hippoAdd(m, hippoItem("Reset Everything", "action", "resetall"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;
case "botaim":
    m = hippoAdd(m, hippoItem("Bots", "menu", "bots"));
    m = hippoAdd(m, hippoItem("Aim Options", "menu", "aim"));
    m = hippoAdd(m, hippoItem("Back", "back", ""));
    break;

case "sandbox":
    m = hippoAdd(m, hippoItem("Weapons", "menu", "weapons"));
    m = hippoAdd(m, hippoItem("Cosmetics & Vehicles", "menu", "cosmetic"));
    m = hippoAdd(m, hippoItem("Objects", "menu", "objects"));
    m = hippoAdd(m, hippoItem("Game Modes", "menu", "modes"));
    m = hippoAdd(m, hippoItem("Back", "back", ""));
    break;

		case "bots":
			m = hippoAdd(m, hippoItem("Spawn Count", "cycle", "botcount"));
			m = hippoAdd(m, hippoItem("Spawn Bots", "action", "botadd"));
			m = hippoAdd(m, hippoItem("Kick All Bots", "action", "botkick"));
			m = hippoAdd(m, hippoItem("Kill All Bots", "action", "botkill"));
			m = hippoAdd(m, hippoItem("Bot Skill", "cycle", "skill"));
			m = hippoAdd(m, hippoItem("Bots Fire", "dvar", "bots_main_firing"));
			m = hippoAdd(m, hippoItem("Bots Move", "dvar", "bots_main_move"));
			m = hippoAdd(m, hippoItem("Bots Target", "dvar", "bots_main_target"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "weapons":
			m = hippoAdd(m, hippoItem("Class", "cycle", "wclass"));
			m = hippoAdd(m, hippoItem("Weapon", "cycle", "wpn"));
			m = hippoAdd(m, hippoItem("Attachment", "cycle", "att"));
			m = hippoAdd(m, hippoItem("Camo", "cycle", "camo"));
			m = hippoAdd(m, hippoItem("Give Weapon", "action", "give"));
			m = hippoAdd(m, hippoItem("Take Current Weapon", "action", "take"));
			m = hippoAdd(m, hippoItem("Refill Ammo", "action", "refill"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "fun":
			m = hippoAdd(m, hippoItem("Explosive Ammo", "toggle", "expl"));
			m = hippoAdd(m, hippoItem("Thumper Rounds", "toggle", "thump"));
			m = hippoAdd(m, hippoItem("Super Jump", "toggle", "jump"));
			m = hippoAdd(m, hippoItem("Speed Boost", "toggle", "speed"));
			m = hippoAdd(m, hippoItem("Low Gravity", "toggle", "grav"));
			m = hippoAdd(m, hippoItem("Third Person", "toggle", "third"));
			m = hippoAdd(m, hippoItem("Red Laser", "toggle", "laser"));
			m = hippoAdd(m, hippoItem("Field Of View", "cycle", "fov"));
			m = hippoAdd(m, hippoItem("Vision", "cycle", "vision"));
			m = hippoAdd(m, hippoItem("Reset Vision", "action", "visionreset"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "aim":
			m = hippoAdd(m, hippoItem("Aim Assist (Bots)", "toggle", "aim"));
			m = hippoAdd(m, hippoItem("Aim Strength", "cycle", "aimsmooth"));
			m = hippoAdd(m, hippoItem("Aim When", "cycle", "aimwhen"));
			m = hippoAdd(m, hippoItem("Target", "cycle", "aimbone"));
			m = hippoAdd(m, hippoItem("Through Walls", "toggle", "aimwall"));
			m = hippoAdd(m, hippoItem("Instant Kill", "toggle", "ikill"));
			m = hippoAdd(m, hippoItem("Auto Kill", "toggle", "iauto"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "look":
			m = hippoAdd(m, hippoItem("Animations", "toggle", "anim"));
			m = hippoAdd(m, hippoItem("Menu Side", "cycle", "side"));
			m = hippoAdd(m, hippoItem("Theme", "cycle", "theme"));
			m = hippoAdd(m, hippoItem("Emblem", "cycle", "emblem"));
			m = hippoAdd(m, hippoItem("Kush HUD", "toggle", "kushhud"));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;

		case "controls":
			m = hippoAdd(m, hippoItem("Open/Close: " + getDvar("hippo_key_open"), "info", ""));
			m = hippoAdd(m, hippoItem("Up: " + getDvar("hippo_key_up"), "info", ""));
			m = hippoAdd(m, hippoItem("Down: " + getDvar("hippo_key_down"), "info", ""));
			m = hippoAdd(m, hippoItem("Select: " + getDvar("hippo_key_select"), "info", ""));
			m = hippoAdd(m, hippoItem("Back: " + getDvar("hippo_key_back"), "info", ""));
			m = hippoAdd(m, hippoItem("Edit hippo_menu.cfg to change", "info", ""));
			m = hippoAdd(m, hippoItem("FOV/3rd person: see README", "info", ""));
			m = hippoAdd(m, hippoItem("Back", "back", ""));
			break;
	}

	return m;
}

hippoItemText(item)
{
	label = item["label"];
	arg = item["arg"];

	switch (item["type"])
	{
		case "menu":
			return label + "  ^5>";
		case "toggle":
			if (self.hippoOn[arg])
				return label + ": ^2ON";
			return label + ": ^1OFF";
		case "dvar":
			if (hippoDvarIsOn(arg))
				return label + ": ^2ON";
			return label + ": ^1OFF";
		case "cycle":
			return label + ": ^5" + self hippoCycleText(arg);
	}
	return label;
}
