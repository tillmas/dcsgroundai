--dcsgroundai
--written using MIST 4.5.107

-- *********************************************************
-- Function definitions
-- *********************************************************
function table.contains(table, element)
	for _, value in pairs(table) do
		if value == element then
		  return true
		end
	end
	return false
end

function table.invert(table)
	local s={}
	for k,v in pairs(table) do
		s[v]=k
	end
	return s
end

function getNClosestZones(zoneList, numZones, referencePoint)
	local closestZones = {}
	local distances = {}
	
	-- Calculate distance to each zone
	for i = 1, #zoneList do
		distances[i] = {
			zoneList[i],
			mist.utils.get2DDist(
				referencePoint,
				mist.utils.makeVec2(zoneList[i].point)
			)
		}
	end
	
	-- Sort zones by distance
	table.sort(distances, function(a, b) return a[2] < b[2] end)
	
	-- Get #numZones closest zones
	for i = 1, numZones do
	   closestZones[i] = distances[i][1].name
	end

	return closestZones
end

function assignCoalitionMissions(coalition, targetZones, commanderList, numZones)
	local assignableZones = {}
	
	-- Initialize assignable zones
	for key, zone in pairs(targetZones) do
		table.insert(assignableZones, zone)
	end
	
	-- Assign Missions
	-- For all coalition commanders, assign numZones zones from targetZones
	for cName, cObj in pairs(commanderList[coalition]) do

		-- Set reference point to the location of a randomly selected group in this commander's forces
		local referencePoint = mist.getGroupPoints(commanderList[coalition][cName]["forces"][1])[1]
		 
		local closestZones = getNClosestZones(assignableZones, numZones, referencePoint)
		
		-- Remove closest zones from assignableZones so they are not assigned to another Commander
		for i = 1, #assignableZones do
			for j = 1, #closestZones do
				if assignableZones[i] == closestZones[j] then
					table.remove(assignableZones, i)
					i = i - 1
				end
			end
		end
	
		-- Assign missions to commander
		commanderList[coalition][cName]["assignedZones"] = closestZones
	end
end

-- Assigns a specified number of zones (numZones) from TargetZones to commanders
function assignMissions(targetZones, commanderList, numZones)

	-- TODO: This currently just mutates the object passed as commanderList and returns it.
	-- This should be organized as a chain function or these functions should copy the
	-- commander List.
	assignCoalitionMissions("blue", targetZones, commanderList, numZones)
	assignCoalitionMissions("red", targetZones, commanderList, numZones)
	
	return commanderList
end


function zoneSelector(zoneList, numZones, removeFromList)
	-- randomly choose zones from a list of zones
	-- if removeFromList is true, chosen zones will be removed from the list (original object is mutated)
	local targetZones = {}
	for i = 1,numZones do
		if removeFromList then
			table.insert(targetZones, table.remove(zoneList, math.random(#zoneList)))
		else
			table.insert(targetZones, zoneList[math.random(#zoneList)])
		end
		
	end
	return targetZones
end

function getAllZonesWithPrefix(prefix)
	-- Returns list of all zones with names containing the prefix [prefix]
	local list = {}
	for _, z in pairs(mist.DBs.zonesByName) do
	
		-- If zone name starts with specified prefix, add the zone to the list.
		if (string.sub(z.name, 1, #prefix) == prefix) then
			local newZone = z
			local zoneControlPrefix = string.sub(z.name, 1, #prefix + 1)
			
			-- If zone name has the form 'prefixR ', set controlledBy to "Red"
			if (zoneControlPrefix == prefix .. "R") then
				z["controlledBy"] = "Red"
				
			-- If zone name has the form 'prefixR ', set controlledBy to "Blue"
			elseif (zoneControlPrefix == prefix .. "B") then
				z["controlledBy"] = "Blue"
		
			-- Otherwise, set controlledBy to "Neutral"
			else
				z["controlledBy"] = "Neutral"
			end

			list[#list+1] = z
		end
	end
	return list
end

function generateCommander()

	-- Commander Strategy Enumerations
	-- DEFAULT: 
	
	-- TODO: Commander strategy enumerations, and 
	-- 		add logic to assign a strategy to commanders
	--	
	--	Need to consider how commanders can persist 
	--		between missions.
	
	return {
		["strategy"] = "DEFAULT",
		["forces"] = {},
		["assignedZones"] = {}
	}
end

function getForceStructure(prefix, ignoredCommanders) 
	-- Returns a list of commanders and their forces, grouped by coalition
	-- {
	--		["Commander1"] = {
	--			["strategy"] = "STRATEGY_NAME",
	--			["forces"] = {
	--				"Unit/Group 1 name"
	--				"Unit/Group 2 name"
	--			}
	--		}
	-- }

	-- Get forces in battlefield with user-defined prefix
	local commanderList = {
		["blue"] = {},
		["red"] = {},
	}
	for _, g in pairs(mist.DBs.groupsByName) do
		-- Parse group object name into prefix, commander's name, and group's name
		-- [PREFIX]_[COMMANDERNAME]_[GROUPNAME]
		local groupPrefix, commanderName, groupName = string.match(g.groupName, "(.*)_(.*)-(.*)")

		-- Validate that the group contains the correct _PREFIX and has a commander that isn't ignored
		if (groupPrefix == prefix) then
		
			if (not table.contains(ignoredCommanders, commanderName)) then
				--	Check if commander object already exists. If not, create it.
				if (commanderList[g.coalition][commanderName] == nil) then
					commanderList[g.coalition][commanderName] = generateCommander()
				end
				
				-- 	Add unit/group to commander object's "forces" table.
				table.insert(commanderList[g.coalition][commanderName]["forces"], g.groupName)
			end
		end
	end
	
	return commanderList
end


-- *********************************************************
-- ****************** 		   MAIN 		****************
-- *********************************************************
-- 0. Setup
-- *********************************************************

-- Mission Editor inputs

local _NUM_TARGET_ZONES = 5
local _IGNORED_COMMANDERS = {'A'}

-- mission editors may change the prefix below to whatever they wish to use in the mission.
-- if the zone name prefix is followed by an R (e.g. 'GAZR-1), the zone will be flagged as Red
-- if the zone name prefix is followed by an B (e.g. 'GAZB-1), the zone will be flagged as Blue
-- if the zone name prefix is not followed by a B or and R, the zone will be flagged as Neutral
local _PREFIX = 'GAZ'
local _NUM_ZONES_PER_COMMANDER = 2

-- *********************************************************
-- 1. Zone Control
-- *********************************************************
local zoneList = {}
zoneList = getAllZonesWithPrefix(_PREFIX)

local targetZones = {}
targetZones = zoneSelector(zoneList, _NUM_TARGET_ZONES, false)


-- *********************************************************
-- 3b.  Force Structure
-- *********************************************************
local commanderForces = getForceStructure(_PREFIX, _IGNORED_COMMANDERS)

-- *********************************************************
-- 2.  Higher Order Command: Assign the commanders missions 
-- *********************************************************
assignMissions(targetZones, commanderForces, _NUM_ZONES_PER_COMMANDER)

-- *********************************************************
-- 4.  Force Disposition
-- *********************************************************
-- TBD

-- *********************************************************
-- 5.  Movement Orders: Send units to waypoints based on commanders' missions
-- *********************************************************
for _, coalition in pairs({"blue", "red"}) do
	for commander, __ in pairs (commanderForces[coalition]) do
		for i = 1, #commanderForces[coalition][commander]["forces"] do
			local assignedZones = commanderForces[coalition][commander]["assignedZones"]
			local randomZone = assignedZones[math.random(#assignedZones)]
			
			mist.groupToRandomZone(commanderForces[coalition][commander]["forces"][i], randomZone, nil, nil, 50, true)
		end
	end
end