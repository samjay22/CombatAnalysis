
--[[

The SkillRecommendations singleton tracks lifetime skill
effectiveness data for the local player across all sessions.

Data is accumulated when each encounter ends and is persisted
to disk via Turbine.PluginData so it survives between sessions.

Each category (dmg, taken, heal, power) stores per-skill
statistics: total amount, attack count, crit count, dev count,
encounter duration, and the number of encounters in which the
skill appeared.

Skills are ranked by a weighted score that combines:
  - DPS/HPS contribution (damage or healing per second)
  - Confidence (skills seen in very few encounters are penalised
    so that one-off outliers don't dominate the list)

During combat the recommendations update every second from
live encounter data, showing real-time per-skill DPS/HPS.
On encounter end the data merges into the lifetime store and
saves to disk.

]]--

local SkillRecommendations = class();

-- The number of top skills shown in the recommendations panel
SkillRecommendations.maxRecommendations = 5;

-- Minimum encounters before a skill is fully trusted
SkillRecommendations.confidenceThreshold = 3;

-- Encounters shorter than this (seconds) are ignored to avoid
-- trash-kill outliers inflating the numbers.
SkillRecommendations.minEncounterDuration = 5;

-- Bump this when the data format or filtering rules change so
-- that stale data is automatically discarded on load.
SkillRecommendations.dataVersion = 2;

function SkillRecommendations:Constructor()
	self.playerClass = (player ~= nil and player.class or "Unknown");
	self.totalEncounters = 0;

	self.data = {
		["dmg"]   = {},
		["taken"] = {},
		["heal"]  = {},
		["power"] = {}
	};
end

-- Load persisted data from disk
function SkillRecommendations:Load()
	local saved = Turbine.PluginData.Load(Turbine.DataScope.Character,"CombatAnalysisRecommendations");
	if (type(saved) == "table") then
		DecodeNumbers(saved);

		-- Discard data from an older version (e.g. before the
		-- min-encounter-duration filter was in place).
		if (saved._dataVersion ~= SkillRecommendations.dataVersion) then
			return;
		end

		for cat,skills in pairs(saved) do
			if (self.data[cat] ~= nil and type(skills) == "table") then
				self.data[cat] = skills;
			end
		end
		if (saved._playerClass ~= nil) then
			self.playerClass = saved._playerClass;
		end
		if (saved._totalEncounters ~= nil) then
			self.totalEncounters = saved._totalEncounters;
		end
	end
end

-- Persist current data to disk
local _recSavePending = false;
local _recNeedResaving = false;

local function buildSaveTable()
	local t = Misc.TableCopy(skillRecommendations.data);
	t._playerClass     = skillRecommendations.playerClass;
	t._totalEncounters = skillRecommendations.totalEncounters;
	t._dataVersion     = SkillRecommendations.dataVersion;
	return EncodeNumbers(t);
end

local function RecSaveComplete(success, errorMessage)
	if (not _recNeedResaving) then
		_recSavePending = false;
		return;
	end
	_recNeedResaving = false;
	Turbine.PluginData.Save(Turbine.DataScope.Character,"CombatAnalysisRecommendations",
		buildSaveTable(), RecSaveComplete);
end

function SkillRecommendations:Save()
	if (_recSavePending) then _recNeedResaving = true; return; end
	_recSavePending = true;
	Turbine.PluginData.Save(Turbine.DataScope.Character,"CombatAnalysisRecommendations",
		buildSaveTable(), RecSaveComplete);
end

local function newEntry()
	return {
		totalAmount   = 0,
		totalAttacks  = 0,
		totalCrits    = 0,
		totalDevs     = 0,
		totalDuration = 0,
		encounters    = 0
	};
end

local function mergeInto(entry, amount, attacks, crits, devs, duration)
	entry.totalAmount   = entry.totalAmount  + amount;
	entry.totalAttacks  = entry.totalAttacks + attacks;
	entry.totalCrits    = entry.totalCrits   + crits;
	entry.totalDevs     = entry.totalDevs    + devs;
	entry.totalDuration = (entry.totalDuration or 0) + duration;
	entry.encounters    = entry.encounters   + 1;
end

--[[
	RecordEncounter – called when an encounter terminates.
	Encounters shorter than minEncounterDuration are skipped.
]]--
function SkillRecommendations:RecordEncounter(mob, restore, duration)
	duration = (duration or 0);

	-- skip very short encounters (trash kills skew DPS numbers)
	if (duration < SkillRecommendations.minEncounterDuration) then return end

	local playerName = player.name;
	self.playerClass = player.class;
	self.totalEncounters = self.totalEncounters + 1;

	local function mergeCategory(category, source, dataField)
		if (source == nil or source.players == nil or source.players[playerName] == nil) then return end

		for skillName, summaryData in pairs(source.players[playerName]) do
			if (type(skillName) == "string") then
				local sd = summaryData[dataField];
				if (sd ~= nil and not sd.empty) then
					local totalAmt = (sd.TotalAmount ~= nil and sd:TotalAmount() or sd.amount or 0);
					local attacks  = (sd.attacks or 0);
					local crits    = (sd.crits or 0);
					local devs     = (sd.devs or 0);

					if (attacks > 0) then
						local store = self.data[category];
						if (store[skillName] == nil) then store[skillName] = newEntry(); end
						mergeInto(store[skillName], totalAmt, attacks, crits, devs, duration);
					end
				end
			end
		end
	end

	mergeCategory("dmg",   mob,     "dmgData");
	mergeCategory("taken", mob,     "takenData");
	mergeCategory("heal",  restore, "healData");
	mergeCategory("power", restore, "powerData");

	self:Save();
end

--[[
	GetTopSkills – returns lifetime top N from the stored data.

	Score = dps × confidence
	  dps        = totalAmount / totalDuration
	  confidence = min(1, encounters / threshold)
]]--
function SkillRecommendations:GetTopSkills(category, maxResults)
	maxResults = (maxResults or SkillRecommendations.maxRecommendations);
	local store = self.data[category];
	if (store == nil) then return {} end

	local threshold = SkillRecommendations.confidenceThreshold;

	local list = {};
	for skillName, entry in pairs(store) do
		if (entry.totalAttacks > 0) then
			local dur = (entry.totalDuration ~= nil and entry.totalDuration > 0) and entry.totalDuration or nil;
			local dps = dur and (entry.totalAmount / dur) or nil;
			local avgPerHit = entry.totalAmount / entry.totalAttacks;
			local rawValue  = dps or avgPerHit;
			local confidence = math.min(1, entry.encounters / threshold);

			table.insert(list, {
				name         = skillName,
				avgPerHit    = avgPerHit,
				dps          = dps,
				score        = rawValue * confidence,
				totalAttacks = entry.totalAttacks,
				critRate     = (entry.totalCrits + entry.totalDevs) / entry.totalAttacks,
				encounters   = entry.encounters
			});
		end
	end

	table.sort(list, function(a, b)
		if (a.score ~= b.score) then return a.score > b.score end
		return (a.dps or a.avgPerHit) > (b.dps or b.avgPerHit);
	end);

	while (#list > maxResults) do table.remove(list); end
	return list;
end

--[[
	GetLiveTopSkills – computes real-time per-skill DPS / HPS
	from the result of tab:GetDataForPlayer().

	skillData  – table keyed by skillName → summaryData objects
	             (the totals entry is keyed by 1, a number, and
	              is skipped automatically)
	duration   – current encounter duration in seconds
	maxResults – optional cap on returned entries
]]--
function SkillRecommendations:GetLiveTopSkills(skillData, duration, maxResults)
	maxResults = (maxResults or SkillRecommendations.maxRecommendations);
	if (skillData == nil) then return {} end

	local safeDur = (duration ~= nil and duration > 0) and duration or 1;
	local list = {};

	for skillName, sd in pairs(skillData) do
		-- skip the totals row (keyed by number 1) and empty data
		if (type(skillName) == "string" and sd ~= nil and not sd.empty) then
			local totalAmt = (sd.TotalAmount ~= nil and sd:TotalAmount() or sd.amount or 0);
			local attacks  = (sd.attacks or 0);
			local crits    = (sd.crits or 0);
			local devs     = (sd.devs or 0);

			if (attacks > 0) then
				table.insert(list, {
					name      = skillName,
					dps       = totalAmt / safeDur,
					avgPerHit = totalAmt / attacks,
					critRate  = (crits + devs) / attacks
				});
			end
		end
	end

	table.sort(list, function(a, b) return a.dps > b.dps end);
	while (#list > maxResults) do table.remove(list); end
	return list;
end

-- Map tab save keys → recommendation category (for lifetime fallback)
SkillRecommendations.tabCategoryMap = {
	["dmgTab"]   = "dmg",
	["takenTab"] = "taken",
	["healTab"]  = "heal",
	["powerTab"] = "power"
};

-- Return a display-friendly label for the recommendations header
function SkillRecommendations:GetHeaderLabel()
	return L.Recommendations .. "  (" .. tostring(self.playerClass) .. ")";
end

-- Clear all recommendation data and save
function SkillRecommendations:Reset()
	for cat, _ in pairs(self.data) do
		self.data[cat] = {};
	end
	self.totalEncounters = 0;
	self:Save();
end

-- create singleton
_G.skillRecommendations = SkillRecommendations();

