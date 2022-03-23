--[[
     File Name           :     Mounts.lua
     Created By          :     WireRydr
     Creation Date       :     [2019-01-07 01:28]
     Last Modified       :     [2022-03-22 14:46]
     Description         :     Mounts class for the WoW addon MountRoulette
--]]

--[[
This module of MountRoulette implements a Mounts class, responsible for all
functionality related to Mount-related items and spells
--]]


local addonName, MR = ...

--- Class metatable (stored within the Addon's globals)
MR.Mounts_mt = {}
MR.Mounts_mt.__index = MR.Mounts_mt


-- The following lookup tables list the possible mounts a player may potentially acquire in the current
-- game version.  They're broken down by area (ground vs flying) and type (usable items vs castable spells)
--
-- NOTE: Each table is a numerically-indexed SPARSE array, with index gaps, and therefore cannot be
--	 iterated with pairs() or ipairs().  They are intended for rapid lookups only.
--	    Indices = WoW itemIDs or spellIDs
--	    Values  = speed (one of "fast" or "slow")

local tblPotentialGroundSpells = {
    [5784]="slow",  [13819]="slow", [23161]="fast", [23214]="fast", [34767]="fast", [34769]="slow" }

local tblPotentialFlyingSpells = {  [33943]="slow", [40120]="fast" }

local tblPotentialGroundItems = {
    [1132]="slow",  [2411]="slow",  [2414]="slow",  [5655]="slow",  [5656]="slow",  [5665]="slow",  [5668]="slow",
    [5864]="slow",  [5872]="slow",  [5873]="slow",  [8563]="slow",  [8586]="fast",  [8588]="slow",  [8591]="slow",
    [8592]="slow",  [8595]="slow",  [8629]="slow",  [8631]="slow",  [8632]="slow",  [12302]="fast", [12303]="fast",
    [12325]="slow", [12326]="slow", [12327]="slow", [12330]="fast", [12351]="fast", [12351]="fast", [12353]="fast",
    [12354]="fast", [13086]="fast", [13317]="fast", [13321]="slow", [13322]="slow", [13323]="slow", [13324]="slow",
    [13325]="slow", [13326]="fast", [13327]="fast", [13328]="fast", [13329]="fast", [13331]="slow", [13332]="slow",
    [13333]="slow", [13334]="fast", [13335]="fast", [15277]="slow", [15290]="slow", [15292]="fast", [15293]="fast",
    [18241]="fast", [18242]="fast", [18243]="fast", [18244]="fast", [18245]="fast", [18246]="fast", [18247]="fast",
    [18248]="fast", [18766]="fast", [18767]="fast", [18768]="fast", [18772]="fast", [18773]="fast", [18774]="fast",
    [18776]="fast", [18777]="fast", [18778]="fast", [18785]="fast", [18786]="fast", [18787]="fast", [18788]="fast",
    [18789]="fast", [18790]="fast", [18791]="fast", [18793]="fast", [18794]="fast", [18795]="fast", [18796]="fast",
    [18797]="fast", [18798]="fast", [18902]="fast", [19029]="fast", [19030]="fast", [19872]="fast", [19902]="fast",
    [23193]="fast", [28481]="slow", [28482]="fast", [28915]="fast", [28927]="slow", [28936]="fast", [29102]="fast",
    [29103]="fast", [29104]="fast", [29105]="fast", [29220]="slow", [29221]="slow", [29222]="slow", [29223]="fast",
    [29224]="fast", [29227]="fast", [29228]="fast", [29229]="fast", [29230]="fast", [29231]="fast", [29465]="fast",
    [29466]="fast", [29467]="fast", [29468]="fast", [29469]="fast", [29470]="fast", [29471]="fast", [29472]="fast",
    [29743]="slow", [29744]="slow", [29745]="fast", [29746]="fast", [29747]="fast", [30480]="fast", [31829]="fast",
    [31830]="fast", [31831]="fast", [31832]="fast", [31833]="fast", [31834]="fast", [31835]="fast", [31836]="fast",
    [32768]="fast", [33224]="slow", [33225]="fast", [33809]="fast", [33976]="slow", [33977]="fast", [34129]="fast",
    [35513]="fast", [35906]="fast", [37011]="slow", [37012]="fast", [37598]="fast", [37719]="fast", [37827]="slow",
    [37828]="fast", [38576]="fast", [184865]="fast" }

local tblPotentialFlyingItems = {
    [25470]="slow", [25471]="slow", [25472]="slow", [25473]="fast", [25474]="slow", [25475]="slow", [25476]="slow",
    [25477]="fast", [25527]="fast", [25528]="fast", [25529]="fast", [25531]="fast", [25532]="fast", [25533]="fast",
    [30609]="fast", [32314]="fast", [32316]="fast", [32317]="fast", [32318]="fast", [32319]="fast", [32458]="fast",
    [32857]="fast", [32858]="fast", [32859]="fast", [32860]="fast", [32861]="fast", [32862]="fast", [33999]="fast",
    [34060]="slow", [34061]="fast", [34092]="fast", [35225]="slow", [35226]="fast", [37676]="fast" }


--- Class private method "tableConcatenate"
-- Given two tables t1 and t2, concatenate t2 into t1.  Order of elements will be maintained.
--
-- @param   t1	    Table to have t2 concatenated into
-- @param   t2	    Table to be concatenated into t1
-- @return  t1	    Same t1 table that was passed as argument, but now with t2 concatenated into it
--
-- NOTES:   Both t1 and t2 must be either associative, or non-gapped numerically indexed.
local function tableConcatenate( t1, t2 )
    for i = 1, #t2 do
	t1[#t1+1] = t2[i]
    end
    return t1
end


--- Class private method "ipairs_sparse"
-- Iterates over a SPARSE numerically-indexed table, potentially containing index gaps.
--
-- @param   tbl	    Table (SPARSE, numerically indexed) to iterate over
-- @return  i	    next index in the table
-- @return  tbl[i]  value of the next indexed element
--
-- This function works by:
--  1. Building a new index of keys from the table.
--  2. Sorting the index table.
--  3. Returning a closure where each call of the closure contains a consecutive index and value from the
--     sparse array.
local function ipairs_sparse( tbl )

    -- holds sorted indices
    local tmpIndex  = {}

    local index, _  = next( tbl )

    while index do
	tmpIndex[#tmpIndex+1] = index
	index, _ = next( tbl, index )
    end

    -- sort table indices
    table.sort( tmpIndex )
    local j = 1

    return function()
	-- get index value
	local i = tmpIndex[j]
	j = j + 1
	if i then
	    return i, tbl[i]
	end
    end
end


local function getRidingSkill( )
    local skillIndex, skillName
    local skillRank = 0

    for skillIndex = 1, GetNumSkillLines( ) do
	skillName, _, _, skillRank = select( 1, GetSkillLineInfo( skillIndex ) )
	debug:debug( "skillname[%s] skillRank[%s]", skillName, skillRank )
	if SkillName == "Riding" then break end
    end
    return skillRank
end


--- Class private method "getKnownSpells"
-- Determines all mount-related spells that the player currently knows, and adds them to one of two tables
-- (known spells, fast mounts, and known spells, slow mounts).  A third table is also provided that lists
-- all potentially-available mount spells (both fast and slow) that exist in the game.
--
-- @param   tblKnownFast    Table to add any actually known spells (fast mounts) to
-- @param   tblKnownSlow    Table to add any actually known spells (slow mounts) to
-- @param   tblPotential    Table containing a list of potentially-known spells to check for
-- @return  #tblKnownFast   Number of known fast-mount spells added to the tblKnownFast table
-- @return  #tblKnownSlow   Number of known slow-mount spells added to the tblKnownSlow table
--
-- NOTES: The "known" tables will be emptied before being (potentially) populated with known spells.
--	  If no known spells are found, then the table will be left empty.
--
--	  The "potential" table is a numerically indexed SPARSE array, and not a sequence.  The element
--	  indices are spellIDs, and the values are either "fast" or "slow" to indicate the spell's mount-speed.
--	  It is for rapid lookups, but can be iterated with ipairs_sparse().
local function getKnownSpells( tblKnownFast, tblKnownSlow, tblPotential )

    wipe ( tblKnownFast )
    wipe ( tblKnownSlow )

    for spellID, speed in ipairs_sparse( tblPotential ) do
	if IsSpellKnown( spellID ) then
	    if speed == "fast" then
		table.insert( tblKnownFast, spellID )
		debug:debug( "Known fast mount-related spell: ID  %s", spellID )
	    else
		table.insert( tblKnownSlow, spellID )
		debug:debug( "Known slow mount-related spell: ID  %s", spellID )
	    end
	end
    end
    return #tblKnownFast, #tblKnownSlow
end


--- Class private method "getMatchingBaggedItems"
-- Find all items in all bags that are mount-related (e.g. Pinto Bridle), and add them to one of two
-- tables:  1. fast mount items, and 2. slow mount items.  A third table is also provided that
-- lists all potentially-available mount items (both fast and slow) that exist in the game.
--
-- @param   tblBaggedFast   Table to add any matching mount items to
-- @param   tblBaggedSlow   Table to add any matching mount items to
-- @param   tblPotential    Table containing a list of potenial mount items to check for
-- @return  #tblKnownFast   Number of known fast-mount spells added to the tblKnownFast table
-- @return  #tblKnownSlow   Number of known slow-mount spells added to the tblKnownSlow table
--
-- NOTES: The "known" tables will be emptied before being (potentially) populated with found matching
--	  items.  If no matching items are found then the table will be left empty.
--
--	  The "potential" table is a numerically indexed SPARSE array, and not sequencees.  The element
--	  indices are itemIDs, and the values are either "fast" or "slow" to indicate the item's mount-speed.
--	  They are for rapid lookups, but can be iterated with ipairs_sparse().
local function getMatchingBaggedItems( tblBaggedFast, tblBaggedSlow, tblPotential )
    local itemID
    local num = 0

    wipe( tblBaggedFast )
    wipe( tblBaggedSlow )

    for bag = 0, NUM_BAG_SLOTS do
	for slot = 1, GetContainerNumSlots( bag ) do
	    itemID = GetContainerItemID( bag, slot )
	    if itemID ~= nil and tblPotential[itemID] ~= nil then
		if tblPotential[itemID] == "fast" then
		    table.insert( tblBaggedFast, itemID )
		    debug:debug( "Bag/slot %s/%s contains a fast mount-related item: ID %s", bag, slot, itemID ) 
		else
		    table.insert( tblBaggedSlow, itemID )
		    debug:debug( "Bag/slot %s/%s contains a slow mount-related item: ID %s", bag, slot, itemID ) 
		end
	    end
	end
    end
    return #tblBaggedFast, #tblBaggedSlow
end


--- Class constructor "new"
-- Creates a new Mounts object and sets initial state.
-- @return          The newly constructed and initialized Mounts object
function MR.Mounts_mt:new( )
    local mountsObject = {}                    -- new object
    setmetatable( mountsObject, MR.Mounts_mt )


    -- Per-object private Data
    ----------------------------------------------------------------------------
    self.useCastableMounts	    = true
    self.tblBaggedFlyingItemsFast   = {}
    self.tblBaggedFlyingItemsSlow   = {}
    self.tblBaggedGroundItemsFast   = {}
    self.tblBaggedGroundItemsSlow   = {}
    self.tblKnownFlyingSpellsFast   = {}
    self.tblKnownFlyingSpellsSlow   = {}
    self.tblKnownGroundSpellsFast   = {}
    self.tblKnownGroundSpellsSlow   = {}
    self.ridingSkill		    = getRidingSkill( )
    ----------------------------------------------------------------------------

    return mountsObject
end


--- Class public-method "generateMountList"
-- (Re)generates the full list of available mounts, from known mount spells and mount-related items
-- currently in inventory.
-- @return  num	    Number of mounts available
function MR.Mounts_mt:generateMountList( )
    getMatchingBaggedItems( self.tblBaggedGroundItemsFast, self.tblBaggedGroundItemsSlow, tblPotentialGroundItems )
    getKnownSpells( self.tblKnownGroundSpellsFast, self.tblKnownGroundSpellsSlow, tblPotentialGroundSpells )

    if self:canFly( ) then
	getMatchingBaggedItems( self.tblBaggedFlyingItemsFast, self.tblBaggedFlyingItemsSlow, tblPotentialFlyingItems )
	getKnownSpells( self.tblKnownFlyingSpellsFast, self.tblKnownFlyingSpellsSlow, tblPotentialFlyingSpells )
    end
    debug:info( "%d mount(s) available", self:getTotalNumMounts( ) )
    return num
end


--- Class public-method "canFly"
-- Indicates whether or not the player has sufficient riding skill to use flying mounts
--
-- @return  true    Player has sufficient riding skill to fly
-- @return  false   Player does not have sufficient riding skill to fly
--
-- NOTE: In WoW Classic (and Season-of-Master), no flight is possible
function MR.Mounts_mt:canFly( )
    local flightCapable = false

    if select( 4, GetBuildInfo() ) < 20000 then
	return false
    end

    -- todo: Put Classic TBC code here

    return flightCapable
end



--- Class public-method "showMounts"
-- Lists currently available mounts, from known mount spells, and mount-related items currently
-- in inventory.
function MR.Mounts_mt:showMounts( )

    for i = 1, #self.tblKnownGroundSpellsFast do
	debug:always( "Ground: (fast) %s", GetSpellInfo( self.tblKnownGroundSpellsFast[i] ) )
    end
    for i = 1, #self.tblKnownGroundSpellsSlow do
	debug:always( "Ground: (slow) %s", GetSpellInfo( self.tblKnownGroundSpellsSlow[i] ) )
    end
    for i = 1, #self.tblBaggedGroundItemsFast do
	debug:always( "Ground: (fast) %s", GetItemInfo( self.tblBaggedGroundItemsFast[i] ) )
    end
    for i = 1, #self.tblBaggedGroundItemsSlow do
	debug:always( "Ground: (slow) %s", GetItemInfo( self.tblBaggedGroundItemsSlow[i] ) )
    end
    debug:always( "%d total ground mount(s)", ( self:getNumItemsGround( ) + self:getNumSpellsGround( ) ) )

    if self:canFly( ) then
	for i = 1, #self.tblKnownFlyingSpellsFast do
	    debug:always( "Flying: (fast) %s", GetSpellInfo( self.tblKnownFlyingSpellsFast[i] ) )
	end
	for i = 1, #self.tblKnownFlyingSpellsSlow do
	    debug:always( "Flying: (slow) %s", GetSpellInfo( self.tblKnownFlyingSpellsSlow[i] ) )
	end
	for i = 1, #self.tblBaggedFlyingItemsFast do
	    debug:always( "Flying: (fast) %s", GetItemInfo( self.tblBaggedFlyingItemsFast[i] ) )
	end
	for i = 1, #self.tblBaggedFlyingItemsSlow do
	    debug:always( "Flying: (slow) %s", GetItemInfo( self.tblBaggedFlyingItemsSlow[i] ) )
	end
	debug:always( "%d total flying mount(s)", ( self:getNumItemsFlying( ) + self:getNumSpellsFlying( ) ) )
    end
end


--- Class public-method "getNumItemsFlying"
-- Returns the number of flying mount-capable items presently in player's bags
-- @arg	    speed   Speed ("fast", "slow" or "all") of mounts to count
-- @return  num	    Number of flying mount-capable items presently in player's bags
function MR.Mounts_mt:getNumItemsFlying( speed )
    if speed == "fast" then
	return #self.tblBaggedFlyingItemsFast
    elseif speed == "slow" then
	return #self.tblBaggedFlyingItemsSlow
    else
	return ( #self.tblBaggedFlyingItemsFast + #self.tblBaggedFlyingItemsSlow )
    end
end


--- Class public-method "getNumItemsGround"
-- Returns the number of ground mount-capable items presently in player's bags
-- @arg	    speed   Speed ("fast", "slow" or "all") of mounts to count
-- @return  num	    Number of ground mount-capable items presently in player's bags
function MR.Mounts_mt:getNumItemsGround( speed )
    if speed == "fast" then
	return #self.tblBaggedGroundItemsFast
    elseif speed == "slow" then
	return #self.tblBaggedGroundItemsSlow
    else
	return ( #self.tblBaggedGroundItemsFast + #self.tblBaggedGroundItemsSlow )
    end
end


--- Class public-method "getNumSpellsFlying"
-- Returns the number of flying mount spells presently known to the player
-- @arg	    speed   Speed ("fast", "slow" or "all") of mounts to count
-- @return  num	    Number of ground mount spells presently known to the player
function MR.Mounts_mt:getNumSpellsFlying( speed )
    if speed == "fast" then
	return #self.tblKnownFlyingSpellsFast
    elseif speed == "slow" then
	return #self.tblKnownFlyingSpellsSlow
    else
	return ( #self.tblKnownFlyingSpellsFast + #self.tblKnownFlyingSpellsSlow )
    end
end


--- Class public-method "getNumSpellsGround"
-- Returns the number of ground mount spells presently known to the player
-- @arg	    speed   Speed ("fast", "slow" or "all") of mounts to count
-- @return  num	    Number of ground mount spells presently known to the player
function MR.Mounts_mt:getNumSpellsGround( speed )
    if speed == "fast" then
	return #self.tblKnownGroundSpellsFast
    elseif speed == "slow" then
	return #self.tblKnownGroundSpellsSlow
    else
	return ( #self.tblKnownGroundSpellsFast + #self.tblKnownGroundSpellsSlow )
    end
end


--- Class public-method "getTotalNumMounts"
-- Returns the total number of available mounts
-- @return  num	    Total number of available mounts (ground/flying, spell-castable/item-based)
function MR.Mounts_mt:getTotalNumMounts( )
    return ( self:getNumItemsFlying( ) + self:getNumItemsGround( ) + self:getNumSpellsFlying( ) + self:getNumSpellsGround( ) )
end


--- Class public-method "getRandomUseableMount"
-- Returns a randomly-chosen mount that is currently availble/usable by the player
--
-- @return type, mountID    Selected mount, where:  type = "spell" or "item"
--						    mountID = Spell ID or Item ID (based on type) of mount
-- @return nil		    No mounts available/usable
--
-- NOTES: In WoW Classic (and Season-of-Master), no flight is possible
--	  See the comments below for situational prioritization of results
function MR.Mounts_mt:getRandomUseableMount( )
    local tblAvailableSpells	= {}
    local tblAvailableItems	= {}
    local numAvailableSpells	= 0
    local numAvailableItems	= 0
    local numAvailableTotal	= 0
    local chosenType		= 0

    -- Stop if no mounts available
    if self:getTotalNumMounts( ) == 0 then
	debug:debug( "Can't choose a mount - no mounts available." )
	return nil
    end

    -- Stop if no ground mounts available and the player cannot fly
    if self:canFly( ) == false and ( self:getNumSpellsGround( ) + self:getNumItemsGround( ) ) == 0 then
	debug:debug( "Can't choose a mount - no ground mounts available and you can't fly" )
	return nil
    end

    -- Shortlist all available mounts that are of the highest priority available

    -- Priority (flyable areas)
    --    1. Any FAST flying mount
    --	  2. Any SLOW flying mount
    --    3. Any FAST ground mount
    --    4. Any SLOW ground mount
    if self:canFly() then
	if self:getNumSpellsFlying( "fast" ) > 0 or self:getNumItemsFlying( "fast" ) > 0 then
	    debug:debug( "choosing CANFLY - FLYING - FAST" )
	    tableConcatenate( tblAvailableSpells, self.tblKnownFlyingSpellsFast )
	    tableConcatenate( tblAvailableItems, self.tblBaggedFlyingItemsFast )
	elseif self:getNumSpellsFlying( "slow" ) > 0 or self:getNumItemsFlying( "slow" )  > 0 then
	    debug:debug( "choosing CANFLY - FLYING - SLOW" )
	    tableConcatenate( tblAvailableSpells, self.tblKnownFlyingSpellsSlow )
	    tableConcatenate( tblAvailableItems, self.tblBaggedFlyingItemsSlow )
	elseif self:getNumSpellsGround( "fast" ) > 0 or self:getNumItemsGround( "fast" ) > 0 then
	    debug:debug( "choosing CANFLY - GROUND - FAST" )
	    tableConcatenate( tblAvailableSpells, self.tblKnownGroundSpellsFast )
	    tableConcatenate( tblAvailableItems, self.tblBaggedGroundItemsFast )
	else
	    debug:debug( "choosing CANFLY - GROUND - SLOW" )
	    tableConcatenate( tblAvailableSpells, self.tblKnownGroundSpellsSlow )
	    tableConcatenate( tblAvailableItems, self.tblBaggedGroundItemsSlow )
	end

    -- Priority (non-flyable areas)
    --    1. Any FAST flying mount or FAST ground mount
    --    2. Any SLOW flying mount or SLOW ground mount
    else
	if self:getNumSpellsFlying( "fast" ) > 0 or self:getNumItemsFlying( "fast" ) > 0
	or self:getNumSpellsGround( "fast" ) > 0 or self:getNumItemsGround( "fast" ) > 0 then
	    debug:debug( "choosing NOFLY - FAST" )
	    tableConcatenate( tblAvailableSpells, self.tblKnownFlyingSpellsFast )
	    tableConcatenate( tblAvailableItems, self.tblBaggedFlyingItemsFast )
	    tableConcatenate( tblAvailableSpells, self.tblKnownGroundSpellsFast )
	    tableConcatenate( tblAvailableItems, self.tblBaggedGroundItemsFast )
	else
	    debug:debug( "choosing NOFLY - SLOW" )
	    tableConcatenate( tblAvailableSpells, self.tblKnownFlyingSpellsSlow )
	    tableConcatenate( tblAvailableItems, self.tblBaggedFlyingItemsSlow )
	    tableConcatenate( tblAvailableSpells, self.tblKnownGroundSpellsSlow )
	    tableConcatenate( tblAvailableItems, self.tblBaggedGroundItemsSlow )
	end
    end
    numAvailableSpells	= #tblAvailableSpells
    numAvailableItems	= #tblAvailableItems
    numAvailableTotal	= numAvailableSpells + numAvailableItems

    -- Determine which shortlist (spell or item) to select from.  If only shortlist has available mounts
    -- then it will be used.  Randomly choose betwen shortlists if both contain available mounts.
    -- (This is because spells / items have different types of info and invocations/uses).
    if numAvailableSpells > 0 and numAvailableItems > 0 then
	local tblTypes = { "spell", "item" }
	chosenType = tblTypes[ math.random( 1, numAvailableTotal ) ]
    elseif numAvailableSpells > 0 then
	chosenType = "spell"
    else
	chosentype = "item"
    end

    -- Choose a mount randomly from the shortlisted ones
    if chosenType == "spell" then
	chosenMountID = tblAvailableSpells[math.random( 1, numAvailableSpells ) ]
	debug:always( "|cff0099ff%s|r chosen from |cffffff00%d|r available mount(s)", GetSpellInfo( chosenMountID ), numAvailableTotal )
    else
	chosenMountID = tblAvailableItems[math.random( 1, numAvailableItems ) ]
	debug:always( "|cff0099ff%s|r chosen from |cffffff00%d|r available mount(s)", GetItemInfo( chosenMountID ), numAvailableTotal )
    end

    return chosenType, chosenMountID
end


-- vim: autoindent tabstop=8 softtabstop=4 shiftwidth=4 noexpandtab
