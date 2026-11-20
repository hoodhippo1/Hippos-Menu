// HIPPO MENU - OPTIONAL level-up style banners
// Copy into userraw\scripts to enable, delete to disable.
// Shows the game's own level-up banner (icon + 3 lines + sound) for the kush theme, Test Banner and
// Gun Game / One In The Chamber wins.
// It calls the game's own script maps\mp\gametypes\_hud_message::notifyMessage. If the game shows a
// compile error naming hippo_banner.gsc, delete this file; everything else keeps working (you then
// get a plain screen message instead).

init()
{
	level.hippoBanner = true;
	setDvar("hippo_banner_do", "0");
	level thread hbaWatch();
}

hbaIsBot(p)
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

hbaWatch()
{
	for (;;)
	{
		wait 0.25;

		if (getDvarInt("hippo_banner_do") != 1)
			continue;
		setDvar("hippo_banner_do", "0");

		title = getDvar("hippo_banner_title");
		text = getDvar("hippo_banner_text");
		text2 = getDvar("hippo_banner_text2");
		icon = getDvar("hippo_banner_icon");
		if (icon == "")
			icon = "rank_prestige10";

		foreach (p in level.players)
		{
			if (hbaIsBot(p))
				continue;
			p thread hbaShow(title, text, text2, icon);
		}
	}
}

hbaShow(title, text, text2, icon)
{
	self endon("disconnect");

	nd = spawnstruct();
	nd.iconName = icon;
	nd.titleText = title;
	nd.notifyText = text;
	nd.notifyText2 = text2;
	nd.glowColor = (0.3, 0.9, 0.3);
	nd.sound = "mp_level_up";

	self thread maps\mp\gametypes\_hud_message::notifyMessage(nd);
}
