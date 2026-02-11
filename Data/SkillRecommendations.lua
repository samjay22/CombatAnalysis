
--[[

The SkillRecommendations singleton tracks lifetime skill
effectiveness data for the local player across all sessions.

Data is accumulated when each encounter ends and is persisted
to disk via Turbine.PluginData so it survives between sessions.

Each category (dmg, taken, heal, power) stores per-skill
statistics: total amount, attack count, crit count, dev count,
and the number of encounters in which the skill appeared.

The class also provides helper methods to compute a sorted
"top N" list of recommended skills for any given category.

]]--

local SkillRecommendations = class();

-- The number of top skills shown in the recommendations panel
SkillRecommendations.maxRecommendations = 5;

function SkillRecommendations:Constructor()
	-- categories mirror the four main stat tabs
	self.data = {
		["dmg"]   = {},
		["taken"] = {},
		["heal"]  = {},
		["power"] = {}
	};
end

-- Load persisted data from disk (called once on startup, after settings)
function SkillRecommendations:Load()
	local saved = Turbine.PluginData.Load(Turbine.DataScope.Character,"CombatAnalysisRecommendations");
	if (type(saved) == "table") then
		DecodeNumbers(saved);
		for cat,skills in pairs(saved) do
			if (self.data[cat] ~= nil and type(skills) == "table") then
				self.data[cat] = skills;
			end
		end
	end
end

-- Persist current data to disk
local _recSavePending = false;
local _recNeedResaving = false;

local function RecSaveComplete(success, errorMessage)
	if (not _recNeedResaving) then
		_recSavePending = false;
		return;
	end
	_recNeedResaving = false;
	Turbine.PluginData.Save(Turbine.DataScope.Character,"CombatAnalysisRecommendations",
		EncodeNumbers(Misc.TableCopy(skillRecommendations.data)), RecSaveComplete);
end

function SkillRecommendations:Save()
	if (_recSavePending) then _recNeedResaving = true; return; end
	_recSavePending = true;
	-- deep copy so encoding doesn't corrupt the live table
	local toSave = EncodeNumbers(Misc.TableCopy(self.data));
	Turbine.PluginData.Save(Turbine.DataScope.Character,"CombatAnalysisRecommendations", toSave, RecSaveComplete);
end

--[[
	RecordEncounter is called when an encounter terminates.
	It iterates the player's per-skill data for each category
	and merges it into the lifetime store.
	
	mob      – the mob being recorded (for dmg/taken)
	restore  – the restore being recorded (for heal/power)
]]--
function SkillRecommendations:RecordEncounter(mob, restore)
	local playerName = player.name;
	
	-- helper: merge one category
	local function mergeCategory(category, source, dataField)
		if (source == nil or source.players == nil or source.players[playerName] == nil) then return end
		
		for skillName, summaryData in pairs(source.players[playerName]) do
			-- skip the numeric totals entry (index 1) and only process named skills
			if (type(skillName) == "string") then
				local sd = summaryData[dataField];
				if (sd ~= nil and not sd.empty) then
					local totalAmt = (sd.TotalAmount ~= nil and sd:TotalAmount() or sd.amount or 0);
					local attacks  = (sd.attacks or 0);
					local crits    = (sd.crits or 0);
					local devs     = (sd.devs or 0);
					
					if (attacks > 0) then
						local store = self.data[category];
						if (store[skillName] == nil) then
							store[skillName] = {
								totalAmount  = 0,
								totalAttacks = 0,
								totalCrits   = 0,
								totalDevs    = 0,
								encounters   = 0
							};
						end
						local entry = store[skillName];
						entry.totalAmount  = entry.totalAmount  + totalAmt;
						entry.totalAttacks = entry.totalAttacks + attacks;
						entry.totalCrits   = entry.totalCrits   + crits;
						entry.totalDevs    = entry.totalDevs    + devs;
						entry.encounters   = entry.encounters   + 1;
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
	GetTopSkills returns the top N skills for a given category,
	sorted by average amount per attack (descending).
	
	Each entry is: { name, avgPerHit, totalAmount, totalAttacks, critRate, encounters }
]]--
function SkillRecommendations:GetTopSkills(category, maxResults)
	maxResults = (maxResults or SkillRecommendations.maxRecommendations);
	local store = self.data[category];
	if (store == nil) then return {} end
	
	local list = {};
	for skillName, entry in pairs(store) do
		if (entry.totalAttacks > 0) then
			table.insert(list, {
				name         = skillName,
				avgPerHit    = entry.totalAmount / entry.totalAttacks,
				totalAmount  = entry.totalAmount,
				totalAttacks = entry.totalAttacks,
				critRate     = (entry.totalCrits + entry.totalDevs) / entry.totalAttacks,
				encounters   = entry.encounters
			});
		end
	end
	
	-- sort descending by average per hit
	table.sort(list, function(a, b)
		if (a.avgPerHit ~= b.avgPerHit) then return a.avgPerHit > b.avgPerHit end
		return a.totalAmount > b.totalAmount;
	end);
	
	-- trim to max
	while (#list > maxResults) do
		table.remove(list);
	end
	
	return list;
end

-- Map tab save keys to recommendation categories
SkillRecommendations.tabCategoryMap = {
	["dmgTab"]   = "dmg",
	["takenTab"] = "taken",
	["healTab"]  = "heal",
	["powerTab"] = "power"
};

-- Clear all recommendation data and save
function SkillRecommendations:Reset()
	for cat, _ in pairs(self.data) do
		self.data[cat] = {};
	end
	self:Save();
end

-- create singleton
_G.skillRecommendations = SkillRecommendations();

