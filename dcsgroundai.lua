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

--
-- HIGHCOMMAND Class Definition
--

function newHIGHCOMMAND (PREFIX)

	local _PREFIX = PREFIX
	local _commanders = {}
	local _targetZones = {}
	local _zones = getAllZonesWithPrefix(PREFIX)

	--- Select zones to assign to commanders
	-- @param numTargetZones 
	local selectTargetZones = function (numTargetZones)
		zoneList = mist.utils.deepCopy(_zones)
		_targetZones = {}
		
		for i = 1, numTargetZones do
			table.insert(_targetZones, table.remove(zoneList, math.random(#zoneList)))
		end
	end
	
	--- Generate commanders based on user-provided commanderConfig
	-- @param commanderConfig - TBD
	local assignForceStructure = function (coalition, commanderConfig)
			
		-- Reset commander list
		_commanders = {}

		-- Get forces in battlefield with user-defined prefix
		for _, g in pairs(mist.DBs.groupsByName) do
			-- Parse group object name into prefix, commander's name, and group's name
			-- [PREFIX]_[COMMANDERNAME]-[GROUPNAME]
			local gPrefix, cName, gName = string.match(g.groupName, "(.*)_(.*)-(.*)")

			-- Validate that the group contains the correct PREFIX and has a commander that isn't ignored
			if (gPrefix == _PREFIX and g.coalition = coalition) then
			
				if (commanderConfig[cName] ~= nil) then
					--	Check if commander object already exists. If not, create it.
					if (_commanders[cName] == nil) then
						_commanders[cName] = newCOMMANDER(cName, commanderConfig[cName], coalition)
					end
					
					-- 	Add unit/group to commander object's "forces" table.
					_commanders[cName].addForces(g)
				end
			end
		end
	end
	
	-- Returns list of commander objects in coalition blue
	local getCoalitionCommanders = function (coalition)
		local list = {}
		for k, v in pairs(_commanders) do
			if v.getCoalition() == coalition then
				list[#list+1] = v
			end
		end
		return list
	end
	
	local assignMissions = function (coalition, numZonesPerCommander)
		local assignableZones = mist.utils.deepCopy(_targetZones)
		local coalitionCommanders = getCoalitionCommanders(coalition)
		
		-- Assign Missions
		-- For all coalition commanders, assign numZones zones from targetZones
		for _, cObj in pairs(coalitionCommanders) do

			-- Set reference point to the location of a randomly selected group in this commander's forces
            local referencePoint = mist.getGroupPoints(cObj.getForces()[1].groupName)[1]

			local closestZones = getNClosestZones(assignableZones, numZonesPerCommander, referencePoint)

			-- Remove closest zones from assignableZones so they are not assigned to another Commander
            local removeZones = {}
			for i = 1, #assignableZones do
				for j = 1, #closestZones do
                    if assignableZones[i].name == closestZones[j] then
                        removeZones[#removeZones+1] = i
                    end
				end
			end
           
            for i = 1, #removeZones  do
               table.remove(assignableZones, removeZones[#removeZones + 1 - i])
            end
		
		
			-- Assign missions to commander
			cObj.assignZones(closestZones)
		end
	end
	
	-- Command all commanders to execute orders
	local executeMissions = function ()
		for _, commander in pairs(_commanders) do
			commander.executeOrders()
		end
	end

	return {
		getIgnoredCommanders = function () return _ignoredCommanders end,
		getTargetZones = function () return _targetZones end,
		getCommanders = function () return _commanders end,
		getBlueCommanders = function () return getCoalitionCommanders("blue") end,
		getRedCommanders = function () return getCoalitionCommanders("red") end,
		selectTargetZones = selectTargetZones,
		assignForceStructure = assignForceStructure,
		assignMissions = assignMissions,
		executeMissions = executeMissions
	}
end

--
-- End HIGHCOMMAND Class Definition
--

--
-- COMMANDER Class Definition
--

function newCOMMANDER(id, strategy, coalition)
	local _id = id
	local _strategy = strategy
	local _coalition = coalition
	local forces = {}
	local assignedZones = {}
	

	local addForces = function(group)
		forces[#forces + 1] = group
	end
	
	local assignZones = function (zones)
		assignedZones = zones
	end
	
	local executeOrders = function()
		-- Generate plan
		if (_strategy == nil or not type(_strategy) == "function") then
			StrategyDefault(assignedZones, forces)
		else
			_strategy(assignedZones, forces)
		end
	end

	return {
		getId = function () return _id end,
		getCoalition = function () return _coalition end,
		getForces = function () return forces end,
		getAssignedZones = function () return assignedZones end,
		addForces = addForces,
		assignZones = assignZones,
		executeOrders = executeOrders
	}
end

--
-- End COMMANDER Class Definition
--

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

function getZoneNames(zones)
	local zoneList = {}
	for k, v in pairs(zones) do
		zoneList[#zoneList+1] = v.name
	end
	return zoneList
end

--
-- STRATEGIES
--

function StrategyDefault(zones, groups)
	for i = 1, #groups do
		local group = groups[i].groupName
		local zone = zones[math.random(#zones)]
		mist.groupToRandomZone(group, zone, nil, nil, 50, true) 
	end
end

function StrategyAggressive(zones, groups)
	for i = 1, #groups do
		mist.groupToRandomZone(groups[i].groupName, zones[1], nil, nil, 50, true)
	end
end

function StrategyWaves(zones, groups)
	local time = 0
	
	for k, v in pairs(groups) do
		-- Send waves every X seconds
		mist.scheduleFunction(mist.groupToRandomZone, {v.name, getZoneNames(zones), nil, nil, 50, true}, timer.getTime() + 10 + time)
		
		time = time + 15
	end
end

--
-- END STRATEGIES
--


-- *********************************************************
-- ****************** 		   MAIN 		****************
-- *********************************************************
-- 0. Setup
-- *********************************************************

-- *** Mission Editor inputs ***

-- mission editors may change the prefix below to whatever they wish to use in the mission.
-- if the zone name prefix is followed by an R (e.g. 'GAZR-1), the zone will be flagged as Red
-- if the zone name prefix is followed by an B (e.g. 'GAZB-1), the zone will be flagged as Blue
-- if the zone name prefix is not followed by a B or and R, the zone will be flagged as Neutral
local _PREFIX = 'GAZ'

local _NUM_TARGET_ZONES = 5
local _IGNORED_COMMANDERS = {'A'}
local _NUM_ZONES_PER_BLUE_COMMANDER = 2
local _COMMANDER_CONFIG = {
	["B"] = StrategyDefault,
	["C"] = StrategyDefault,
	["D"] = StrategyDefault
}

local _NUM_ZONES_PER_RED_COMMANDER = 1
local _COMMANDER_CONFIG = {
	["C"] = StrategyDefault,
}

-- *** Instanstiate High Command
local highCommand = newHIGHCOMMAND(_PREFIX)

-- *********************************************************
-- 1. Zone Control
-- *********************************************************
highCommand.selectTargetZones(_NUM_TARGET_ZONES)


-- *********************************************************
-- 3b.  Force Structure
-- *********************************************************
highCommand.assignForceStructure("blue", _BLUE_COMMANDER_CONFIG)
highCommand.assignForceStructure("red", _RED_COMMANDER_CONFIG)


-- *********************************************************
-- 2.  Higher Order Command: Assign the commanders missions 
-- *********************************************************
highCommand.assignMissions("blue", _NUM_ZONES_PER_BLUE_COMMANDER)
highCommand.assignMissions("red", _NUM_ZONES_PER_RED_COMMANDER)


-- *********************************************************
-- 4.  Force Disposition
-- *********************************************************
-- (Currently assigned in step 3b.

-- *********************************************************
-- 5.  Movement Orders: Send units to waypoints based on commanders' missions
-- *********************************************************
highCommand.executeMissions()