--[[
    File Name		:   MountRoulette.lua
    Created By		:   tubiakou
    Creation Date	:   [2019-01-07 01:28]
    Last Modified	:   [2022-03-23 22:00]
    Description		:   Play Roulette with your mounts!
--]]

local addonName, MR = ...

MR.addonVersion = "1.0.0"


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
-- @return  true        Pattern found
-- @return  false       Pattern not found
local function endswith( someStr, ending )
    local res = ending == "" or someStr:sub( -#ending ) == ending
    debug:debug( "res = '%s' for '%s' (len. %d) at end of '%s' (len. %d)", res, start, #start, someStr, #someStr )
    return res
end

--- Refreshes the list of available mounts, chooses one, and configures MountRoulette's button
--
-- @param   (none)
-- @return  mountType	Type of chosen mount ("spell" or "item"), or nil if none chosen
-- @return  mountID	Spell ID or Item ID (based on type) of chosen mount, or nil if none chosen
--
local function MR_refreshMount( )
    local mountType, mountID = mroulette:getRandomUsableMount( )

    if mountType ~= nil then
	mroulette:configureButton( MR_button, mountType, mountID )
--	local bindResult = SetBindingMacro( "BUTTON3", "MountRouletteMac" )
	local bindResult = SetBinding( "BUTTON3", "MACRO MountRouletteMac" )
	if bindResult == nil then 
	    debug:debug( "Failed to set up the macro binding." )
	else
	    SaveBindings( 2 )	-- per-character bindings
	    debug:debug( "bind result: %d", bindResult )

	end
    end
    return mountType, mountID
end


local function MR_slashCommandHandler( msg, editbox )
    msg = string.lower( msg )
    if( startswith( msg, "debug" ) ) then
	local p = string.find( msg, " " )
	debug:setLevel( string.upper( string.sub( msg, p + 1 ) ) )
	return
    end
    if( msg == "scan" ) then
	local numMountsFound = mroulette:generateMountList( )
	debug:warn( "%d found available mount(s)", numMountsFound )

    elseif( msg == "show" ) then
	mroulette:showMounts( )
    elseif( msg == "choose" ) then
	local chosenMountType, chosenMountID = MR_refreshMount( )
	if chosenMountType == "spell" then
	    debug:always( "|cff0099ff%s|r chosen from |cffffff00%d|r available mount(s)", GetSpellInfo( chosenMountID ), mroulette:getTotalNumMounts( ) )
	else
	    debug:always( "|cff0099ff%s|r chosen from |cffffff00%d|r available mount(s)", GetItemInfo( chosenMountID ), mroulette:getTotalNumMounts( ) )
	end
    else
	debug:always( "/mroulette debug <debug|info|warn|error|always>   Set debugging output severity" )
	debug:always( "/mroulette scan: Refresh the list of available mounts" )
	debug:always( "/mroulette choose: Pick one of your available mounts randomly" )
	debug:always( "/mroulette show: Show all mounts which might be chosen" )
    end
end


local function MR_setupSlashCommands( )
    SLASH_MROULETTE1 = "/mroulette";
    SLASH_MROULETTE2 = "/mr";
    SlashCmdList["MROULETTE"] = MR_slashCommandHandler;
end


-- See the various frame:RegisterEvent( ... ) statements below for triggering info
local function MR_eventHandler( self, event, ... )
    debug:debug( "Event %s passed to MR_eventHandler().", event )

    -- Fires: Immediately before PLAYER_ENTERING_WORLD on login, and UI reload,
    --        but NOT when entering/leaving instances
--    if( event == "PLAYER_LOGIN" ) then
    if( event == "PLAYER_ENTERING_WORLD" ) then
	MR_setupSlashCommands( )
	MR_refreshMount( )
	debug:always("v%s initialized.", MR.addonVersion )

    elseif event == "BAG_UPDATE"
	or event == "SKILL_LINES_CHANGED"
	or event == "SPELLS_CHANGED"
	or event == "ZONE_CHANGED"
	or event == "ZONE_CHANGED_NEW_AREA"
    then
	MR_refreshMount( )

    -- Catchall for any registered but any unhandled events
    else
	debug:warn( "Unexpected event %s passed to EventHandler() - ignored.", event )
    end
end

-- Instantiate a debugging object and set desired initial verbosity level
debug = MR.Debugging_mt:new( )
debug:setLevel( WARN )


local frame = CreateFrame( "Frame" )

-- Set up event-handling.  See the actual event-handler function for info on
-- when each event fires.
--frame:RegisterEvent( "PLAYER_LOGIN" )
frame:RegisterEvent( "PLAYER_ENTERING_WORLD" )
frame:RegisterEvent( "BAG_UPDATE" )
frame:RegisterEvent( "SKILL_LINES_CHANGED" )
frame:RegisterEvent( "SPELLS_CHANGED" )
frame:RegisterEvent( "ZONE_CHANGED" )
frame:RegisterEvent( "ZONE_CHANGED_NEW_AREA" )
frame:SetScript( "OnEvent", MR_eventHandler )

-- Create new Mounts object
mroulette = MR.Mounts_mt:new( )

-- Set up MountRoulette's macro
-- NOTE: todo: This doesn't seem to work in Classic.  See if it works in TBC
--local MR_macroID = CreateMacro( "MR_macro", "INV_MISC_QUESTIONMARK", "/script cast Summon Felsteed", 1 )


-- Button that players can set keybinds / mousebinds to, to perform the actual mount.
-- It will be configured whenever a mount is chosen.
local MR_button = CreateFrame( "Button", "MR_button", UIParent, "SecureActionButtonTemplate" )


-- vim: autoindent tabstop=8 softtabstop=4 shiftwidth=4 noexpandtab
