
--[[

Session Statistics

Tracks aggregate combat statistics for the current play
session (plugin load → unload). Unlike SkillRecommendations
this data is intentionally NOT persisted – it resets every
time you log in so you get a clean picture of today's play.

Recorded per-category (dmg, taken, heal, power):
  – Number of qualifying encounters
  – Total combat time
  – Total amount (damage / healing / etc.)
  – Best per-second rate + encounter name
  – Worst per-second rate + encounter name

These are displayed in a collapsible tree section in the
stats panel, between Recommendations and Normal Hits.

]]--

local SessionStats = class();

SessionStats.minDuration = 5; -- match SkillRecommendations filter

function SessionStats:Constructor()
	self.data = {
		["dmg"]   = SessionStats.NewCategory(),
		["taken"] = SessionStats.NewCategory(),
		["heal"]  = SessionStats.NewCategory(),
		["power"] = SessionStats.NewCategory()
	};
end

function SessionStats.NewCategory()
	return {
		encounters   = 0,
		totalTime    = 0,
		totalAmount  = 0,
		bestPs       = 0,
		bestPsName   = "",
		worstPs      = math.huge,
		worstPsName  = ""
	};
end

-- Map tab save keys to session categories (same mapping as SkillRecommendations)
SessionStats.tabCategoryMap = {
	["dmgTab"]   = "dmg",
	["takenTab"] = "taken",
	["healTab"]  = "heal",
	["powerTab"] = "power"
};

--[[
	RecordEncounter – called when an encounter terminates.
	Reads the totals row from the mob/restore for each category
	and accumulates into this session's running counters.
]]--
function SessionStats:RecordEncounter(mob, restore, duration)
	duration = (duration or 0);

	-- skip very short encounters (same threshold as recommendations)
	if (duration < SessionStats.minDuration) then return end

	local playerName = player.name;

	local function record(category, source, dataField)
		if (source == nil or source.players == nil or source.players[playerName] == nil) then return end

		-- totals row is keyed by number 1
		local totals = source.players[playerName][1];
		if (totals == nil) then return end
		local sd = totals[dataField];
		if (sd == nil or sd.empty) then return end

		local totalAmt = (sd.TotalAmount ~= nil and sd:TotalAmount() or sd.amount or 0);
		if (totalAmt <= 0) then return end

		local ps = totalAmt / duration;
		local cat = self.data[category];
		local encName = (source.name or L.CurrentEncounter);

		cat.encounters  = cat.encounters + 1;
		cat.totalTime   = cat.totalTime  + duration;
		cat.totalAmount = cat.totalAmount + totalAmt;

		if (ps > cat.bestPs) then
			cat.bestPs     = ps;
			cat.bestPsName = encName;
		end
		if (ps < cat.worstPs) then
			cat.worstPs     = ps;
			cat.worstPsName = encName;
		end
	end

	record("dmg",   mob,     "dmgData");
	record("taken", mob,     "takenData");
	record("heal",  restore, "healData");
	record("power", restore, "powerData");
end

--[[
	GetStats – returns the session stats for a given category.
	Returns nil if there's no data for that category yet.
]]--
function SessionStats:GetStats(category)
	local cat = self.data[category];
	if (cat == nil or cat.encounters == 0) then return nil end

	return {
		encounters  = cat.encounters,
		totalTime   = cat.totalTime,
		totalAmount = cat.totalAmount,
		avgPs       = cat.totalAmount / cat.totalTime,
		bestPs      = cat.bestPs,
		bestPsName  = cat.bestPsName,
		worstPs     = (cat.worstPs ~= math.huge) and cat.worstPs or 0,
		worstPsName = cat.worstPsName
	};
end

-- Return a header label for the tree section
function SessionStats:GetHeaderLabel(category)
	local cat = self.data[category];
	local count = (cat ~= nil) and cat.encounters or 0;
	return L.Session .. "  (" .. tostring(count) .. ")";
end

-- create singleton
_G.sessionStats = SessionStats();
