// HIPPO MENU - HUD rendering (self-contained helper file, no init())
// mode: 0 = instant, 1 = slide in, 2 = quick fade

hippoThemeCols(idx)
{
	c = [];

	switch (idx)
	{
		case 1: // toxic
			c["bar"] = (0.05, 0.55, 0.15);
			c["accent"] = (0.40, 1.00, 0.40);
			c["hl"] = (0.10, 0.70, 0.20);
			c["bg"] = (0.02, 0.07, 0.03);
			c["sub"] = (0.50, 1.00, 0.50);
			break;
		case 2: // crimson
			c["bar"] = (0.70, 0.05, 0.08);
			c["accent"] = (1.00, 0.35, 0.30);
			c["hl"] = (0.85, 0.10, 0.15);
			c["bg"] = (0.08, 0.02, 0.02);
			c["sub"] = (1.00, 0.50, 0.45);
			break;
		case 3: // royal
			c["bar"] = (0.45, 0.12, 0.80);
			c["accent"] = (0.80, 0.50, 1.00);
			c["hl"] = (0.55, 0.20, 0.90);
			c["bg"] = (0.05, 0.02, 0.09);
			c["sub"] = (0.80, 0.60, 1.00);
			break;
		case 4: // gold
			c["bar"] = (0.80, 0.55, 0.05);
			c["accent"] = (1.00, 0.85, 0.30);
			c["hl"] = (0.85, 0.60, 0.10);
			c["bg"] = (0.08, 0.06, 0.02);
			c["sub"] = (1.00, 0.85, 0.40);
			break;
		case 6: // kush (green + smoke)
			c["bar"] = (0.08, 0.42, 0.10);
			c["accent"] = (0.55, 0.90, 0.30);
			c["hl"] = (0.15, 0.55, 0.15);
			c["bg"] = (0.02, 0.06, 0.03);
			c["sub"] = (0.65, 0.95, 0.45);
			break;
		case 5: // rainbow (colors are animated)
			c["bar"] = (1.00, 0.20, 0.20);
			c["accent"] = (1.00, 0.60, 0.10);
			c["hl"] = (1.00, 0.20, 0.20);
			c["bg"] = (0.03, 0.03, 0.05);
			c["sub"] = (1.00, 1.00, 1.00);
			break;
		default: // ice (blue and black)
			c["bar"] = (0.04, 0.30, 0.95);
			c["accent"] = (0.35, 0.75, 1.00);
			c["hl"] = (0.10, 0.40, 0.95);
			c["bg"] = (0.02, 0.03, 0.08);
			c["sub"] = (0.45, 0.80, 1.00);
			break;
	}

	return c;
}

hippoRainbow(i)
{
	switch (i % 6)
	{
		case 0:
			return (1.0, 0.15, 0.15);
		case 1:
			return (1.0, 0.60, 0.10);
		case 2:
			return (1.0, 1.0, 0.20);
		case 3:
			return (0.20, 1.0, 0.30);
		case 4:
			return (0.20, 0.60, 1.0);
	}
	return (0.70, 0.30, 1.0);
}

hippoUiStart(e, a, mode, dir)
{
	e.hippoA = a;

	if (mode == 1)
	{
		e.x = e.hippoX - (280 * dir);
		e.alpha = 0;
		e moveOverTime(0.25);
		e.x = e.hippoX;
		e fadeOverTime(0.25);
		e.alpha = a;
	}
	else if (mode == 2)
	{
		e.alpha = 0;
		e fadeOverTime(0.15);
		e.alpha = a;
	}
	else
	{
		e.alpha = a;
	}
}

hippoUiShaderMat(mat, halign, x, y, w, h, col, a, sort, mode, dir)
{
	e = newClientHudElem(self);
	e.horzAlign = halign;
	e.vertAlign = "top";
	e.alignX = "left";
	e.alignY = "top";
	e.x = x;
	e.y = y;
	e.hippoX = x;
	e.sort = sort;
	e.foreground = true;
	e.hidewheninmenu = true;
	e.color = col;
	e setShader(mat, w, h);
	self hippoUiStart(e, a, mode, dir);
	return e;
}

hippoUiShader(halign, x, y, w, h, col, a, sort, mode, dir)
{
	return self hippoUiShaderMat("white", halign, x, y, w, h, col, a, sort, mode, dir);
}

hippoUiText(halign, x, y, txt, font, scale, col, a, sort, mode, dir)
{
	e = newClientHudElem(self);
	e.horzAlign = halign;
	e.vertAlign = "top";
	e.alignX = "left";
	e.alignY = "top";
	e.x = x;
	e.y = y;
	e.hippoX = x;
	e.sort = sort;
	e.foreground = true;
	e.hidewheninmenu = true;
	e.font = font;
	e.fontScale = scale;
	e.color = col;
	e setText(txt);
	self hippoUiStart(e, a, mode, dir);
	return e;
}

hippoUiDestroy()
{
	if (isDefined(self.hippoUi))
	{
		foreach (e in self.hippoUi)
		{
			if (isDefined(e))
				e destroy();
		}
	}
	if (isDefined(self.hippoRows))
	{
		foreach (e in self.hippoRows)
		{
			if (isDefined(e))
				e destroy();
		}
	}
	self.hippoUi = [];
	self.hippoRows = [];
}

hippoUiBuild(title, labels, sel, mode, emblem)
{
	self notify("hippo_ui_rebuilt");
	self hippoUiDestroy();

	theme = self.hippoVal["theme"];
	cols = hippoThemeCols(theme);

	tex = false;
	if (isDefined(level.hippoTex))
		tex = level.hippoTex;

	dir = 1;
	left = 20;
	halign = "left";
	if (self.hippoVal["side"] == 1)
	{
		dir = -1;
		left = -240;
		halign = "right";
	}

	w = 220;
	rowH = 18;
	top = 110;
	rowTop = top + 56;
	h = 56 + (labels.size * rowH) + 30;

	self.hippoRowTop = rowTop;
	self.hippoRowH = rowH;

	// panel + gradient overlay
	self.hippoUi["bg"] = self hippoUiShader(halign, left, top, w, h, cols["bg"], 0.88, 1, mode, dir);
	if (tex)
		self.hippoUi["gbg"] = self hippoUiShaderMat("gradient_fadein", halign, left, top, w, h, cols["bar"], 0.30, 2, mode, dir);

	// title bar + gradient overlay + accent line
	self.hippoUi["bar"] = self hippoUiShader(halign, left, top, w, 30, cols["bar"], 0.95, 3, mode, dir);
	if (tex)
		self.hippoUi["gbar"] = self hippoUiShaderMat("gradient_fadein", halign, left, top, w, 30, (1, 1, 1), 0.35, 4, mode, dir);
	self.hippoUi["line"] = self hippoUiShader(halign, left, top + 30, w, 2, cols["accent"], 1.0, 4, mode, dir);

	// selection highlight
	self.hippoUi["hl"] = self hippoUiShader(halign, left + 4, rowTop + (sel * rowH) - 3, w - 8, rowH, cols["hl"], 0.45, 5, mode, dir);

	// emblem icons either side of the title
	titleX = left + 12;
	if (tex && emblem != "" && theme != 6)
	{
		self.hippoUi["em1"] = self hippoUiShaderMat(emblem, halign, left + 6, top + 3, 24, 24, (1, 1, 1), 1.0, 6, mode, dir);
		self.hippoUi["em2"] = self hippoUiShaderMat(emblem, halign, left + w - 30, top + 3, 24, 24, (1, 1, 1), 1.0, 6, mode, dir);
		titleX = left + 40;
	}

	// kush theme: weed calling-card icon (glowing) on both sides of the title, plus drifting smoke
	titleCol = (1, 1, 1);
	if (theme == 6)
	{
		titleCol = (0.80, 1.0, 0.65);
		titleX = left + 40;

		weed = false;
		if (isDefined(level.hippoWeed))
			weed = level.hippoWeed;

		if (weed)
		{
			self.hippoUi["wg1"] = self hippoUiShaderMat("cardicon_weed", halign, left + 1, top - 2, 34, 34, (0.35, 1.0, 0.25), 0.15, 5, mode, dir);
			self.hippoUi["wg2"] = self hippoUiShaderMat("cardicon_weed", halign, left + w - 35, top - 2, 34, 34, (0.35, 1.0, 0.25), 0.15, 5, mode, dir);
			self.hippoUi["w1"] = self hippoUiShaderMat("cardicon_weed", halign, left + 5, top + 2, 26, 26, (1, 1, 1), 1.0, 7, mode, dir);
			self.hippoUi["w2"] = self hippoUiShaderMat("cardicon_weed", halign, left + w - 31, top + 2, 26, 26, (1, 1, 1), 1.0, 7, mode, dir);
		}
		else
		{
			self hippoUiLeaf(halign, left + 8, top + 3, mode, dir);
		}
		if (tex)
		{
			self.hippoUi["sm1"] = self hippoUiShaderMat("gradient_fadein", halign, left, top + 40, 150, 60, (0.80, 0.90, 0.80), 0.0, 2, 0, dir);
			self.hippoUi["sm2"] = self hippoUiShaderMat("gradient_fadein", halign, left, top + (h / 2), 150, 70, (0.75, 0.85, 0.75), 0.0, 2, 0, dir);
			self thread hippoUiSmoke("sm1", left, w - 150, 5.0);
			self thread hippoUiSmoke("sm2", left + 20, w - 170, 7.0);
		}
	}

	// texts
	self.hippoUi["title"] = self hippoUiText(halign, titleX, top + 6, "HIPPO'S MENU", "objective", 1.6, titleCol, 1.0, 6, mode, dir);
	self.hippoUi["sub"] = self hippoUiText(halign, left + 12, top + 37, title, "default", 1.1, cols["sub"], 1.0, 6, mode, dir);

	// Two-line footer, positioned inside the menu panel
footY = rowTop + (labels.size * rowH) + 1;

self.hippoUi["foot1"] = self hippoUiText(
	halign, left + 10, footY,
	"^3UP/DOWN ARROW^7 (move)",
	"default", 0.75, (0.7, 0.7, 0.8), 1.0, 6, mode, dir
);

self.hippoUi["foot2"] = self hippoUiText(
	halign, left + 10, footY + 12,
	"^3ENTER^7 (select)  ^3BKSPACE^7 (back)",
	"default", 0.75, (0.7, 0.7, 0.8), 1.0, 6, mode, dir
);

	// pointer next to the selected row
	self.hippoUi["arrow"] = self hippoUiText(halign, left + 5, rowTop + (sel * rowH), ">", "default", 1.4, cols["accent"], 1.0, 6, mode, dir);

	self.hippoRows = [];
	for (i = 0; i < labels.size; i++)
	{
		self.hippoRows[i] = self hippoUiText(halign, left + 16, rowTop + (i * rowH), labels[i], "default", 1.3, (0.80, 0.82, 0.90), 1.0, 6, mode, dir);
	}

	self hippoUiColorRows(sel);

	if (self.hippoOn["anim"])
		self thread hippoUiPulse(theme);
}

// Small pixel-art leaf made of 6 rectangles (x0,y0 = top-left of a 24x25 box)
hippoUiLeaf(halign, x0, y0, mode, dir)
{
	g1 = (0.35, 0.90, 0.25);
	g2 = (0.20, 0.72, 0.20);
	g3 = (0.30, 0.55, 0.15);

	self.hippoUi["lf0"] = self hippoUiShader(halign, x0 + 10, y0, 4, 17, g1, 1.0, 7, mode, dir);
	self.hippoUi["lf1"] = self hippoUiShader(halign, x0 + 6, y0 + 4, 3, 11, g2, 1.0, 7, mode, dir);
	self.hippoUi["lf2"] = self hippoUiShader(halign, x0 + 15, y0 + 4, 3, 11, g2, 1.0, 7, mode, dir);
	self.hippoUi["lf3"] = self hippoUiShader(halign, x0, y0 + 10, 5, 4, g2, 1.0, 7, mode, dir);
	self.hippoUi["lf4"] = self hippoUiShader(halign, x0 + 19, y0 + 10, 5, 4, g2, 1.0, 7, mode, dir);
	self.hippoUi["lf5"] = self hippoUiShader(halign, x0 + 11, y0 + 17, 2, 8, g3, 1.0, 7, mode, dir);
}

// One drifting smoke wisp: fades in, slides sideways, fades out, repeats.
hippoUiSmoke(key, x0, span, secs)
{
	self endon("disconnect");
	self endon("hippo_ui_rebuilt");
	self endon("hippo_closed");

	wait 0.4;

	for (;;)
	{
		e = self.hippoUi[key];
		if (!isDefined(e))
			return;

		e.x = x0;
		e.alpha = 0;
		e fadeOverTime(secs * 0.4);
		e.alpha = 0.22;
		e moveOverTime(secs);
		e.x = x0 + span;
		wait (secs * 0.5);

		if (!isDefined(self.hippoUi[key]))
			return;
		e fadeOverTime(secs * 0.5);
		e.alpha = 0;
		wait (secs * 0.5);
	}
}

// Highlight breathes; the rainbow theme cycles colors.
hippoUiPulse(theme)
{
	self endon("disconnect");
	self endon("hippo_ui_rebuilt");
	self endon("hippo_closed");

	i = 0;
	for (;;)
	{
		if (!isDefined(self.hippoUi["hl"]))
			return;

		a = 0.25;
		if ((i % 2) == 1)
			a = 0.60;

		self.hippoUi["hl"] fadeOverTime(0.5);
		self.hippoUi["hl"].alpha = a;

		if (theme == 6)
		{
			ga = 0.15;
			if ((i % 2) == 1)
				ga = 0.55;
			if (isDefined(self.hippoUi["wg1"]))
			{
				self.hippoUi["wg1"] fadeOverTime(0.5);
				self.hippoUi["wg1"].alpha = ga;
			}
			if (isDefined(self.hippoUi["wg2"]))
			{
				self.hippoUi["wg2"] fadeOverTime(0.5);
				self.hippoUi["wg2"].alpha = ga;
			}
		}

		if (theme == 5)
		{
			c = hippoRainbow(i);
			c2 = hippoRainbow(i + 1);
			if (isDefined(self.hippoUi["bar"]))
			{
				self.hippoUi["bar"] fadeOverTime(0.5);
				self.hippoUi["bar"].color = c;
			}
			if (isDefined(self.hippoUi["gbg"]))
			{
				self.hippoUi["gbg"] fadeOverTime(0.5);
				self.hippoUi["gbg"].color = c;
			}
			if (isDefined(self.hippoUi["line"]))
			{
				self.hippoUi["line"] fadeOverTime(0.5);
				self.hippoUi["line"].color = c2;
			}
			if (isDefined(self.hippoUi["arrow"]))
			{
				self.hippoUi["arrow"] fadeOverTime(0.5);
				self.hippoUi["arrow"].color = c2;
			}
			self.hippoUi["hl"] fadeOverTime(0.5);
			self.hippoUi["hl"].color = c;
		}

		wait 0.5;
		i = i + 1;
	}
}

hippoUiColorRows(sel)
{
	for (i = 0; i < self.hippoRows.size; i++)
	{
		if (i == sel)
			self.hippoRows[i].color = (1, 1, 1);
		else
			self.hippoRows[i].color = (0.62, 0.68, 0.82);
	}
}

hippoUiSelect(sel)
{
	if (!isDefined(self.hippoUi["hl"]))
		return;

	y = self.hippoRowTop + (sel * self.hippoRowH);

	if (self.hippoOn["anim"])
		self.hippoUi["hl"] moveOverTime(0.08);
	self.hippoUi["hl"].y = y - 3;

	if (isDefined(self.hippoUi["arrow"]))
	{
		if (self.hippoOn["anim"])
			self.hippoUi["arrow"] moveOverTime(0.08);
		self.hippoUi["arrow"].y = y;
	}

	self hippoUiColorRows(sel);
}

hippoUiSetRow(i, txt)
{
	if (isDefined(self.hippoRows[i]))
		self.hippoRows[i] setText(txt);
}

// ---------------------------------------------------------------- Kush HUD (in-game overlay)
// While the kush theme is active and the menu is closed: glowing weed icon + "HIPPO" bottom-left,
// drifting smoke, and the glow flashes on every kill.

hippoKushKills(p)
{
	if (isDefined(p.pers))
	{
		if (isDefined(p.pers["kills"]))
			return p.pers["kills"];
	}
	return 0;
}

hippoKushShader(mat, x, y, w, h, col, a, sort)
{
	e = newClientHudElem(self);
	e.horzAlign = "left";
	e.vertAlign = "bottom";
	e.alignX = "left";
	e.alignY = "top";
	e.x = x;
	e.y = y;
	e.sort = sort;
	e.foreground = true;
	e.hidewheninmenu = true;
	e.color = col;
	e.alpha = a;
	e setShader(mat, w, h);
	return e;
}

hippoKushText(txt, x, y, font, scale, col, a, sort)
{
	e = newClientHudElem(self);
	e.horzAlign = "left";
	e.vertAlign = "bottom";
	e.alignX = "left";
	e.alignY = "top";
	e.x = x;
	e.y = y;
	e.sort = sort;
	e.foreground = true;
	e.hidewheninmenu = true;
	e.font = font;
	e.fontScale = scale;
	e.color = col;
	e.alpha = a;
	e setText(txt);
	return e;
}

hippoKushHudOff()
{
	self notify("hippo_kush_off");

	if (isDefined(self.hippoKush))
	{
		foreach (e in self.hippoKush)
		{
			if (isDefined(e))
				e destroy();
		}
	}
	self.hippoKush = [];
}

hippoKushRefresh()
{
	self hippoKushHudOff();

	if (self.hippoVal["theme"] != 6)
		return;
	if (!self.hippoOn["kushhud"])
		return;
	if (self.hippoIsOpen)
		return;

	self hippoKushHudOn();
}

hippoKushHudOn()
{
	self.hippoKush = [];

	weed = false;
	if (isDefined(level.hippoWeed))
		weed = level.hippoWeed;
	tex = false;
	if (isDefined(level.hippoTex))
		tex = level.hippoTex;

	textX = 16;
	if (weed)
	{
		self.hippoKush["glow"] = self hippoKushShader("cardicon_weed", 4, -104, 72, 72, (0.35, 1.0, 0.25), 0.15, 1);
		self.hippoKush["icon"] = self hippoKushShader("cardicon_weed", 14, -94, 52, 52, (1, 1, 1), 1.0, 2);
		textX = 74;
	}

	self.hippoKush["name"] = self hippoKushText("HIPPO", textX, -88, "objective", 1.9, (0.55, 1.0, 0.35), 1.0, 3);
	self.hippoKush["sub"] = self hippoKushText("KUSH MODE", textX + 2, -62, "default", 1.0, (0.80, 0.95, 0.80), 0.85, 3);

	if (tex)
	{
		self.hippoKush["s1"] = self hippoKushShader("gradient_fadein", textX - 10, -70, 90, 34, (0.80, 0.90, 0.80), 0.0, 1);
		self.hippoKush["s2"] = self hippoKushShader("gradient_fadein", textX + 30, -70, 90, 34, (0.75, 0.85, 0.75), 0.0, 1);
		self thread hippoKushSmoke("s1", textX - 10, 5.0);
		self thread hippoKushSmoke("s2", textX + 30, 7.0);
	}

	self thread hippoKushLoop();
}

// smoke wisp that rises from the icon, fades in and out, repeats
hippoKushSmoke(key, x0, secs)
{
	self endon("disconnect");
	self endon("hippo_kush_off");

	wait 0.5;

	for (;;)
	{
		e = self.hippoKush[key];
		if (!isDefined(e))
			return;

		e.y = -70;
		e.alpha = 0;
		e fadeOverTime(secs * 0.4);
		e.alpha = 0.22;
		e moveOverTime(secs);
		e.y = -125;
		wait (secs * 0.5);

		if (!isDefined(self.hippoKush[key]))
			return;
		e fadeOverTime(secs * 0.5);
		e.alpha = 0;
		wait (secs * 0.5);
	}
}

// pulsing glow, plus a bright flash on every kill
hippoKushLoop()
{
	self endon("disconnect");
	self endon("hippo_kush_off");

	last = hippoKushKills(self);
	i = 0;

	for (;;)
	{
		k = hippoKushKills(self);
		if (k < last)
			last = k;

		if (k > last)
		{
			last = k;
			if (isDefined(self.hippoKush["glow"]))
			{
				self.hippoKush["glow"] fadeOverTime(0.1);
				self.hippoKush["glow"].alpha = 0.9;
			}
			wait 0.25;
		}

		a = 0.15;
		if ((i % 2) == 1)
			a = 0.50;

		if (isDefined(self.hippoKush["glow"]))
		{
			self.hippoKush["glow"] fadeOverTime(0.6);
			self.hippoKush["glow"].alpha = a;
		}

		wait 0.6;
		i = i + 1;
	}
}
