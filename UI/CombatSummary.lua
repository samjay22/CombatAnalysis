
--[[

Post-Combat Summary Toast

A lightweight popup that appears after each qualifying encounter
(>= 5 seconds) showing:
  – Encounter name & duration
  – Player DPS / HPS
  – Top 3 skills ranked by per-second contribution
  – Personal best DPS comparison

The toast auto-fades after a configurable number of seconds
and can be dismissed early with a click.

Personal bests are persisted per-character via Turbine.PluginData.

]]--

_G.CombatSummary = class(Turbine.UI.Window);

-- Layout constants
CombatSummary.popupWidth   = 280;
CombatSummary.popupHeight  = 172;
CombatSummary.rowHeight    = 16;
CombatSummary.padding      = 8;
CombatSummary.displayTime  = 8;   -- seconds before auto-fade
CombatSummary.fadeTime     = 0.6; -- seconds to fade out

-- Minimum encounter length (must match SkillRecommendations.minEncounterDuration)
CombatSummary.minDuration = 5;

function CombatSummary:Constructor()
	Turbine.UI.Window.Constructor(self);

	self:SetVisible(false);
	self:SetMouseVisible(true);
	self:SetZOrder(9999);
	self:SetOpacity(0);

	local W = CombatSummary.popupWidth;
	local H = CombatSummary.popupHeight;
	local P = CombatSummary.padding;
	self:SetSize(W, H);

	-- position top-centre of screen
	local screenW = Turbine.UI.Display.GetWidth();
	self:SetPosition(math.floor((screenW - W) / 2), 50);

	-- themed background
	self:SetBackColor(Theme.Colors.background);

	-- accent border (thin top bar)
	self.topBar = Turbine.UI.Control();
	self.topBar:SetParent(self);
	self.topBar:SetPosition(0, 0);
	self.topBar:SetSize(W, 2);
	self.topBar:SetBackColor(Theme.Colors.accent);
	self.topBar:SetMouseVisible(false);

	-- Header: encounter name
	local y = P;
	self.nameLabel = Turbine.UI.Label();
	self.nameLabel:SetParent(self);
	self.nameLabel:SetPosition(P, y);
	self.nameLabel:SetSize(W - 2*P, 18);
	self.nameLabel:SetFont(Theme.Fonts.heading);
	self.nameLabel:SetForeColor(Theme.Colors.textPrimary);
	self.nameLabel:SetOutlineColor(Theme.Colors.controlOutline);
	self.nameLabel:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft);
	self.nameLabel:SetMultiline(false);
	self.nameLabel:SetMouseVisible(false);

	-- Sub-header: duration + overall DPS
	y = y + 20;
	self.statsLabel = Turbine.UI.Label();
	self.statsLabel:SetParent(self);
	self.statsLabel:SetPosition(P, y);
	self.statsLabel:SetSize(W - 2*P, 16);
	self.statsLabel:SetFont(Theme.Fonts.body);
	self.statsLabel:SetForeColor(Theme.Colors.textSecondary);
	self.statsLabel:SetOutlineColor(Theme.Colors.controlOutline);
	self.statsLabel:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft);
	self.statsLabel:SetMultiline(false);
	self.statsLabel:SetMouseVisible(false);

	-- Divider line
	y = y + 20;
	self.divider = Turbine.UI.Control();
	self.divider:SetParent(self);
	self.divider:SetPosition(P, y);
	self.divider:SetSize(W - 2*P, 1);
	self.divider:SetBackColor(Theme.Colors.borderSoft);
	self.divider:SetMouseVisible(false);

	-- Skill labels header
	y = y + 5;
	self.skillHeader = Turbine.UI.Label();
	self.skillHeader:SetParent(self);
	self.skillHeader:SetPosition(P, y);
	self.skillHeader:SetSize(W - 2*P, 14);
	self.skillHeader:SetFont(Theme.Fonts.small);
	self.skillHeader:SetForeColor(Theme.Colors.textMuted);
	self.skillHeader:SetOutlineColor(Theme.Colors.controlOutline);
	self.skillHeader:SetText(L.CombatSummaryTopSkills);
	self.skillHeader:SetMultiline(false);
	self.skillHeader:SetMouseVisible(false);

	-- 3 skill rows (name on left, /s on right)
	y = y + 16;
	self.skillNames = {};
	self.skillValues = {};
	for i = 1, 3 do
		local nameLabel = Turbine.UI.Label();
		nameLabel:SetParent(self);
		nameLabel:SetPosition(P + 6, y);
		nameLabel:SetSize(W - 2*P - 60, CombatSummary.rowHeight);
		nameLabel:SetFont(Theme.Fonts.body);
		nameLabel:SetForeColor(Theme.Colors.textPrimary);
		nameLabel:SetOutlineColor(Theme.Colors.controlOutline);
		nameLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
		nameLabel:SetMultiline(false);
		nameLabel:SetMouseVisible(false);
		self.skillNames[i] = nameLabel;

		local valLabel = Turbine.UI.Label();
		valLabel:SetParent(self);
		valLabel:SetPosition(W - P - 60, y);
		valLabel:SetSize(60, CombatSummary.rowHeight);
		valLabel:SetFont(Theme.Fonts.body);
		valLabel:SetForeColor(Theme.Colors.accent);
		valLabel:SetOutlineColor(Theme.Colors.controlOutline);
		valLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight);
		valLabel:SetMultiline(false);
		valLabel:SetMouseVisible(false);
		self.skillValues[i] = valLabel;

		y = y + CombatSummary.rowHeight + 2;
	end

	-- Personal best line (bottom)
	y = y + 2;
	self.divider2 = Turbine.UI.Control();
	self.divider2:SetParent(self);
	self.divider2:SetPosition(P, y);
	self.divider2:SetSize(W - 2*P, 1);
	self.divider2:SetBackColor(Theme.Colors.borderSoft);
	self.divider2:SetMouseVisible(false);

	y = y + 4;
	self.bestLabel = Turbine.UI.Label();
	self.bestLabel:SetParent(self);
	self.bestLabel:SetPosition(P, y);
	self.bestLabel:SetSize(W - 2*P, 16);
	self.bestLabel:SetFont(Theme.Fonts.body);
	self.bestLabel:SetForeColor(Theme.Colors.accentActive);
	self.bestLabel:SetOutlineColor(Theme.Colors.controlOutline);
	self.bestLabel:SetTextAlignment(Turbine.UI.ContentAlignment.TopCenter);
	self.bestLabel:SetMultiline(false);
	self.bestLabel:SetMouseVisible(false);

	-- resize to match actual content
	self:SetHeight(y + 20);

	-- Click to dismiss
	self.MouseClick = function()
		self:Dismiss();
	end

	-- Animation state
	self.showing   = false;
	self.startTime = 0;
	self.fadeStart = 0;
	self.phase     = "none"; -- "show", "fade", "none"

	-- Personal best data
	self.personalBests = {
		bestDps       = 0,
		bestDpsName   = "",
		bestHps       = 0,
		bestHpsName   = ""
	};
	self:LoadPersonalBests();
end

-- ─── Personal Best Persistence ──────────────────────────────

local _pbSavePending  = false;
local _pbNeedResaving = false;

local function PBSaveComplete()
	if (not _pbNeedResaving) then
		_pbSavePending = false;
		return;
	end
	_pbNeedResaving = false;
	local t = EncodeNumbers(Misc.TableCopy(combatSummary.personalBests));
	Turbine.PluginData.Save(Turbine.DataScope.Character,
		"CombatAnalysisPersonalBests", t, PBSaveComplete);
end

function CombatSummary:SavePersonalBests()
	if (_pbSavePending) then _pbNeedResaving = true; return; end
	_pbSavePending = true;
	local t = EncodeNumbers(Misc.TableCopy(self.personalBests));
	Turbine.PluginData.Save(Turbine.DataScope.Character,
		"CombatAnalysisPersonalBests", t, PBSaveComplete);
end

function CombatSummary:LoadPersonalBests()
	local saved = Turbine.PluginData.Load(Turbine.DataScope.Character,
		"CombatAnalysisPersonalBests");
	if (type(saved) == "table") then
		DecodeNumbers(saved);
		if (saved.bestDps     ~= nil) then self.personalBests.bestDps     = saved.bestDps     end
		if (saved.bestDpsName ~= nil) then self.personalBests.bestDpsName = saved.bestDpsName  end
		if (saved.bestHps     ~= nil) then self.personalBests.bestHps     = saved.bestHps      end
		if (saved.bestHpsName ~= nil) then self.personalBests.bestHpsName = saved.bestHpsName   end
	end
end

-- ─── Show Summary ───────────────────────────────────────────

function CombatSummary:ShowSummary(mob, restore, duration)
	-- respect the user setting
	if (not showCombatSummary) then return end

	-- skip trivial encounters
	if (duration == nil or duration < CombatSummary.minDuration) then return end

	local playerName = player.name;

	-- ── Gather player damage data ──
	local dmgAmount  = 0;
	local healAmount = 0;
	local skillDps   = {};

	if (mob ~= nil and mob.players ~= nil and mob.players[playerName] ~= nil) then
		-- totals row is keyed by 1
		local totals = mob.players[playerName][1];
		if (totals ~= nil and totals.dmgData ~= nil and not totals.dmgData.empty) then
			dmgAmount = (totals.dmgData.TotalAmount ~= nil and totals.dmgData:TotalAmount() or totals.dmgData.amount or 0);
		end

		-- per-skill DPS
		for skillName, skillData in pairs(mob.players[playerName]) do
			if (type(skillName) == "string") then
				local sd = skillData.dmgData;
				if (sd ~= nil and not sd.empty) then
					local amt = (sd.TotalAmount ~= nil and sd:TotalAmount() or sd.amount or 0);
					if (amt > 0) then
						table.insert(skillDps, { name = skillName, dps = amt / duration });
					end
				end
			end
		end
	end

	if (restore ~= nil and restore.players ~= nil and restore.players[playerName] ~= nil) then
		local totals = restore.players[playerName][1];
		if (totals ~= nil and totals.healData ~= nil and not totals.healData.empty) then
			healAmount = (totals.healData.TotalAmount ~= nil and totals.healData:TotalAmount() or totals.healData.amount or 0);
		end
	end

	local dps = dmgAmount / duration;
	local hps = healAmount / duration;

	-- sort skills by DPS descending
	table.sort(skillDps, function(a, b) return a.dps > b.dps end);

	-- ── Determine if personal best ──
	local isNewBestDps = (dps > self.personalBests.bestDps and dps > 0);
	local isNewBestHps = (hps > self.personalBests.bestHps and hps > 0);
	local prevBestDps  = self.personalBests.bestDps;

	if (isNewBestDps) then
		self.personalBests.bestDps     = dps;
		self.personalBests.bestDpsName = (mob.name or L.CurrentEncounter);
	end
	if (isNewBestHps) then
		self.personalBests.bestHps     = hps;
		self.personalBests.bestHpsName = (restore.name or L.CurrentEncounter);
	end
	if (isNewBestDps or isNewBestHps) then
		self:SavePersonalBests();
	end

	-- ── Populate labels ──
	local encName = (mob ~= nil and mob.name ~= nil) and mob.name or L.CurrentEncounter;
	self.nameLabel:SetText(encName);

	self.statsLabel:SetText(
		Misc.FormatDuration(duration) ..
		"     " .. L.CombatSummaryDPS .. ": " .. Misc.FormatPs(dps) ..
		(healAmount > 0 and ("     " .. L.CombatSummaryHPS .. ": " .. Misc.FormatPs(hps)) or "")
	);

	-- top 3 skills
	for i = 1, 3 do
		if (skillDps[i] ~= nil) then
			self.skillNames[i]:SetText(skillDps[i].name);
			self.skillValues[i]:SetText(Misc.FormatPs(skillDps[i].dps));
		else
			self.skillNames[i]:SetText("");
			self.skillValues[i]:SetText("");
		end
	end

	-- personal best line
	if (isNewBestDps) then
		self.bestLabel:SetForeColor(Theme.Colors.accentActive);
		if (prevBestDps > 0) then
			self.bestLabel:SetText(L.CombatSummaryNewBest .. "  (" .. L.CombatSummaryPrev .. " " .. Misc.FormatPs(prevBestDps) .. ")");
		else
			self.bestLabel:SetText(L.CombatSummaryNewBest);
		end
	elseif (self.personalBests.bestDps > 0) then
		self.bestLabel:SetForeColor(Theme.Colors.textMuted);
		self.bestLabel:SetText(L.CombatSummaryBestDPS .. ": " .. Misc.FormatPs(self.personalBests.bestDps));
	else
		self.bestLabel:SetText("");
	end

	-- ── Show & start auto-dismiss timer ──
	self:SetOpacity(1);
	self:SetVisible(true);
	self.phase     = "show";
	self.startTime = Turbine.Engine.GetGameTime();
	self:SetWantsUpdates(true);
end

-- ─── Animation ──────────────────────────────────────────────

function CombatSummary:Update()
	local now = Turbine.Engine.GetGameTime();

	if (self.phase == "show") then
		if (now - self.startTime >= CombatSummary.displayTime) then
			self.phase     = "fade";
			self.fadeStart = now;
		end

	elseif (self.phase == "fade") then
		local elapsed = now - self.fadeStart;
		local t = 1 - math.min(1, elapsed / CombatSummary.fadeTime);
		self:SetOpacity(t);
		if (t <= 0) then
			self:Dismiss();
		end
	end
end

function CombatSummary:Dismiss()
	self.phase = "none";
	self:SetWantsUpdates(false);
	self:SetVisible(false);
	self:SetOpacity(0);
end

-- ─── Singleton ──────────────────────────────────────────────

_G.combatSummary = CombatSummary();
