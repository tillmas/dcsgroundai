--dcsgroundai
--written using MIST 4.5.107

-- *** Mission Editor inputs ***

local _PREFIX = 'GAZ'

local _NUM_TARGET_ZONES = 5
local _IGNORED_COMMANDERS = {'A'}
local _NUM_ZONES_PER_BLUE_COMMANDER = 2
local _BLUE_COMMANDER_CONFIG = {
	["B"] = StrategyDefault,
	["C"] = StrategyDefault,
	["D"] = StrategyDefault
}

local _NUM_ZONES_PER_RED_COMMANDER = 1
local _RED_COMMANDER_CONFIG = {
	["C"] = StrategyDefault,
}