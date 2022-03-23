--[[
    File Name		:   MountRoulette.lua
    Created By		:   tubiakou
    Creation Date	:   [2019-01-07 01:28]
    Last Modified	:   [2022-03-22 15:34]
    Description		:   Play Roulette with your mounts!
--]]

local addonName, MR = ...

MR.addonVersion = "1.0.0"


--- Helper function "tableLength"
-- Returns the number of elements in the specified table
-- @param   someTable   The Table to operate on
-- @return  Number of elements in the specified table
local function tableLength( tbl )
    local getN = 0
    for n in pairs( tbl ) do
	getN = getN + 1
    end
    return getN
end


--- Helper function "startswith"
-- Identifies if specified string starts with the specified pattern
-- @param   someString  The string to check
-- @param   start       The pattern to search for at start of string
-- @return  true        Pattern found
-- @return  false       Pattern not found
local function startswith( someStr, start )
    local res = string.sub( someStr, 0, #start ) == start
    debug:debug( "Is '%s' (len. %d) at start of '%s' (len. %d): %s", start, #start, someStr, #someStr, tostring( res ) )
    return res
end

--- Helper function "endswith"
-- Identifies if specified string ends with the specified pattern
-- @param   someString  The string to check
-- @param   ending      The pattern to search for at end of string
-- @return
local function endswith( someStr, ending )
    local res = ending == "" or someStr:sub( -#ending ) == ending
    debug:debug( "res = '%s' for '%s' (len. %d) at end of '%s' (len. %d)", res, start, #start, someStr, #someStr )
    return res
end


local function MR_slashCommandHandler( msg, editbox )
    msg = string.lower( msg )
    if( startswith( msg, "debug" ) ) then
	local p = string.find( msg, " " )
	debug:setLevel( string.upper( string.sub( msg, p + 1 ) ) )
	return
    end
    if( msg == "scan" ) then
	mroulette:generateMountList( )
    elseif( msg == "show" ) then
	mroulette:showMounts( )
    elseif( msg == "choose" ) then
	mroulette:getRandomUseableMount( )
	-- Set up MountRoulette's button
	local MR_chosenMountType, MR_chosenMountID = mroulette:getRandomUseableMount( )

	if MR_chosenMountType ~= nil then
	    local MR_button = CreateFrame( "Button", "MR_button", UIParent, "SecureActionButtonTemplate" )
	    if MR_chosenMountType == "spell" then
		MR_button:SetAttribute( "type", "spell" )
		MR_button:SetAttribute( "spell", GetSpellInfo( MR_chosenMountID ) )
	    else
		MR_button:SetAttribute( "type", "item" )
		MR_button:SetAttribute( "item", GetItemInfo( MR_chosenMountID ) )
	    end
	    SetBindingMacro( "BUTTON3", "MountRouletteMac" )
	end
    else
	debug:always( "/mroulette debug <debug|info|warn|error|always>   Set debugging output severity" )
	debug:always( "/mroulette scan: Refresh the list of available mounts" )
	debug:always( "/mroulette choose: Pick one of your available mounts randomly" )
	debug:always( "/mroulette show: Show all mounts which might be chosen" )
    end
end


function MR_setupSlashCommands( )
    SLASH_MROULETTE1 = "/mroulette";
    SLASH_MROULETTE2 = "/mr";
    SlashCmdList["MROULETTE"] = MR_slashCommandHandler;
end


-- See the various frame:RegisterEvent( ... ) statements below for triggering info
local function MR_eventHandler( self, event, ... )
    debug:debug( "Event %s passed to MR_eventHandler().", event )

    -- Fires: Immediately before PLAYER_ENTERING_WORLD on login, and UI reload,
    --        but NOT when entering/leaving instances
    if( event == "PLAYER_LOGIN" ) then
	MR_setupSlashCommands( );
	mroulette:generateMountList( )
	mroulette:getRandomUseableMount( )
	-- Set up MountRoulette's button
	local MR_chosenMountType, MR_chosenMountID = mroulette:getRandomUseableMount( )

	if MR_chosenMountType ~= nil then
	    local MR_button = CreateFrame( "Button", "MR_button", UIParent, "SecureActionButtonTemplate" )
	    if MR_chosenMountType == "spell" then
		MR_button:SetAttribute( "type", "spell" )
		MR_button:SetAttribute( "spell", GetSpellInfo( MR_chosenMountID ) )
	    else
		MR_button:SetAttribute( "type", "item" )
		MR_button:SetAttribute( "item", GetItemInfo( MR_chosenMountID ) )
	    end
	    SetBindingMacro( "BUTTON3", "MountRouletteMac" )
	end
	debug:always("v%s initialized.", MR.addonVersion )

    -- Catchall for any registered but any unhandled events
    else
	debug:warn( "Unexpected event %s passed to EventHandler() - ignored.", event )
    end
end


debug = MR.Debugging_mt:new( )
debug:setLevel( DEBUG )

-- Create new Mounts object, and create  an initial list of available mounts
mroulette = MR.Mounts_mt:new( )
mroulette:generateMountList( )

local frame = CreateFrame( "Frame" )

-- Set up MountRoulette's macro
-- NOTE: This doesn't seem to work in Classic
--local MR_macroID = CreateMacro( "MR_macro", "INV_MISC_QUESTIONMARK", "/script cast Summon Felsteed", 1 )

-- Set up event-handling.  See the actual event-handler function for info on
-- when each event fires.
frame:RegisterEvent( "PLAYER_LOGIN" )

frame:SetScript( "OnEvent", MR_eventHandler )


-- vim: autoindent tabstop=8 softtabstop=4 shiftwidth=4 noexpandtab
