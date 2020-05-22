UnusedGear_MSG_ADDONNAME = "UnusedGear";
UnusedGear_MSG_VERSION   = GetAddOnMetadata(UnusedGear_MSG_ADDONNAME,"Version");
UnusedGear_MSG_AUTHOR    = "opussf";

-- Colours
COLOR_RED = "|cffff0000";
COLOR_GREEN = "|cff00ff00";
COLOR_BLUE = "|cff0000ff";
COLOR_PURPLE = "|cff700090";
COLOR_YELLOW = "|cffffff00";
COLOR_ORANGE = "|cffff6d00";
COLOR_GREY = "|cff808080";
COLOR_GOLD = "|cffcfb52b";
COLOR_NEON_BLUE = "|cff4d4dff";
COLOR_END = "|r";

UnusedGear = {}
UnusedGear_Options = {
	["targetBag"] = 0
}
UnusedGear_savedata = {}
-- itemLog = { link = { log, movedCount, lastMoved } }
-- ignoreItems = { link = true }
--[[
INEED.bindTypes = {
	[ITEM_SOULBOUND] = "Bound",
	[ITEM_BIND_ON_PICKUP] = "Bound",
}
INEED.scanTip = CreateFrame( "GameTooltip", "INEEDTip", UIParent, "GameTooltipTemplate" )
INEED.scanTip2 = _G["INEEDTipTextLeft2"]
INEED.scanTip3 = _G["INEEDTipTextLeft3"]
INEED.scanTip4 = _G["INEEDTipTextLeft4"]

]]

UnusedGear.armorTypes = {
	["Miscellaneous"] = 0,
	["Cloth"] = 1,
	["Leather"] = 2,
	["Mail"] = 3,
	["Plate"] = 4
}
UnusedGear.maxArmorType = 0

UnusedGear.maxArmorTypeByClass = {
	["DEATH KNIGHt"] = "Plate",
	["DEMON HUNTER"] = "Leather",
	["DRUID"] = "Leather",
	["HUNTER"] = "Mail",
	["MAGE"] = "Cloth",
	["MONK"] = "Leather",
	["PALADIN"] = "Plate",
	["PRIEST"] = "Cloth",
	["ROGUE"] = "Leather",
	["SHAMAN"] = "Mail",
	["WARLOCK"] = "Cloth",
	["WARRIOR"] = "Plate"
}

function UnusedGear.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_GREEN..UnusedGear_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function UnusedGear.OnLoad()
	UnusedGear_Frame:RegisterEvent( "MERCHANT_SHOW" )
	UnusedGear_Frame:RegisterEvent( "SCRAPPING_MACHINE_SHOW" )
	UnusedGear_Frame:RegisterEvent( "EQUIPMENT_SETS_CHANGED" )
	UnusedGear_Frame:RegisterEvent( "AUCTION_HOUSE_SHOW" )
	UnusedGear_Frame:RegisterEvent( "BANKFRAME_OPENED" )
	UnusedGear_Frame:RegisterEvent( "ADDON_LOADED" )
	UnusedGear_Frame:RegisterEvent( "VARIABLES_LOADED" )
	local localizedClass, englishClass, classIndex = UnitClass( "player" )
	UnusedGear.maxArmorType = UnusedGear.armorTypes[ UnusedGear.maxArmorTypeByClass[ englishClass ] ]

	--AutoProfit:RegisterEvent("MERCHANT_CLOSED");
	--ap.ForAllJunk();
end

function UnusedGear.ADDON_LOADED()
	-- Unregister the event for this method.
	UnusedGear.Print( "ADDON_LOADED" )
	UnusedGear_Frame:UnregisterEvent("ADDON_LOADED")

	GameTooltip:HookScript( "OnTooltipSetItem", UnusedGear.hookSetItem )
	ItemRefTooltip:HookScript( "OnTooltipSetItem", UnusedGear.hookSetItem )
end

function UnusedGear.VARIABLES_LOADED()
	-- Unregister the event for this method.
	UnusedGear.Print( "VARIABLES_LOADED" )
	UnusedGear_Frame:UnregisterEvent( "VARIABLES_LOADED" )
	UnusedGear_savedata.itemLog = UnusedGear_savedata.itemLog or {}
	UnusedGear_savedata.ignoreItems = UnusedGear_savedata.ignoreItems or {}
end
function UnusedGear.MERCHANT_SHOW()
	--UnusedGear.Print( "MERCHANT_SHOW" )
	UnusedGear.BuildGearSets()
	UnusedGear.ExtractItems()
end
UnusedGear.SCRAPPING_MACHINE_SHOW = UnusedGear.MERCHANT_SHOW
UnusedGear.AUCTION_HOUSE_SHOW = UnusedGear.MERCHANT_SHOW
UnusedGear.BANKFRAME_OPENED = UnusedGear.MERCHANT_SHOW

function UnusedGear.EQUIPMENT_SETS_CHANGED()
	--UnusedGear.Print( "EQUIPMENT_SETS_CHANGED" )
end

function UnusedGear.BuildGearSets()
	UnusedGear.itemsInSets = {}
	for setNum = 0, C_EquipmentSet.GetNumEquipmentSets(), 1 do
		equipmentSetName = C_EquipmentSet.GetEquipmentSetInfo( setNum )
		if( equipmentSetName ) then
			local setItemArray = C_EquipmentSet.GetItemIDs( setNum )
			for i, itemID in pairs( setItemArray ) do
				if( not UnusedGear.itemsInSets[ itemID ] ) then
					UnusedGear.itemsInSets[ itemID ] = {}
				end
				table.insert( UnusedGear.itemsInSets[ itemID ], equipmentSetName )
			end
		end
	end
end

function UnusedGear.ForAllGear( action, message )
	-- work through all the items
	moveCount = 0
	for bag = 0, 4 do
		if GetContainerNumSlots( bag ) > 0 then -- This slot has a bag
			if not GetBagSlotFlag( bag, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP ) then
				for slot = 0, GetContainerNumSlots( bag ) do -- work through this bag
					itemLog = {}
					moved = false
					local texture, itemCount, locked, quality, readable, lootable, link =
							GetContainerItemInfo( bag, slot )
					if( link and not UnusedGear_savedata.ignoreItems[link] ) then
						table.insert( itemLog, "Process-->" )
						if( quality ) then
							--table.insert( itemLog, "Has quality" )
							iArmorType = nil
							local iName, iLink, iRarity, iLevel, iMinLevel, iType, iSubType, iStackCount, iEquipLoc,
									iTexture, iSellPrice = GetItemInfo( link )
							if iLink then
								--table.insert( itemLog, "has iLink" )
								--UnusedGear.Print( "iLink: "..iLink )
								iID = UnusedGear.GetItemIdFromLink( iLink )
								if iID then
									--table.insert( itemLog, "iID:"..iID )
									iID = tonumber( iID )
									iArmorType = UnusedGear.armorTypes[ iSubType ]
									--UnusedGear.Print( "Look at "..iID..": r: "..iRarity.." "..iType.."("..iSubType..") "..link )
									if( iRarity < 6 ) then
										-- 6 is Legandary, 7 is heirloom
										--table.insert( itemLog, "Rarity<6" )
										if( ( iType == "Armor" and iArmorType ) or iType == "Weapon" or iSubType == "Shields" )  then
											table.insert( itemLog, ( ( iType == "Armor" and "Armor:"..iArmorType )
														or ( iType == "Weapon" and "Weapon" )
														or ( iSubType == "Shields" and "Shield" )
														or "" ) )
											if( not UnusedGear.itemsInSets[ iID ] ) then
												table.insert( itemLog, "not in itemsets" )
												if( not string.find( iName, "Tabard" ) ) then
													table.insert( itemLog, "not a Tabard" )

													--UnusedGear.Print( "q: "..quality.." r: "..iRarity.." "..iType.."("..iSubType..") "..link )
													--UnusedGear.Print( "MOVE: "..link )
													targetBagID, targetSlot = UnusedGear.GetLastFreeSlotInBag( UnusedGear_Options.targetBag )
													if( targetBagID ) then
														ClearCursor()
														PickupContainerItem( bag, slot )
														if( targetBagID == 0 ) then
															PutItemInBackpack()
															moveCount = moveCount + 1
															moved = true
															table.insert( itemLog, "Moved from "..bag.." to Backpack" )
														else
															PutItemInBag( targetBagID+19 )
														end
													end
												end
											else
												table.insert( itemLog, "in an itemset" )
											end
										else
											table.insert( itemLog, "Not armor, a weapon, or a shield" )
										end
									else
										table.insert( itemLog, "Rarity is too high: "..iRarity )
									end

								end
							end
						else
							table.insert( itemLog, "NO QUALITY" )
						end
					else
						table.insert( itemLog, "is ignored" )
					end
					if( link ) then
						UnusedGear_savedata.itemLog[link] = UnusedGear_savedata.itemLog[link] or { ["countMoved"] = 0 }
						UnusedGear_savedata.itemLog[link]["log"] = table.concat( itemLog, ", " )
						if moved then
							UnusedGear_savedata.itemLog[link]["lastMoved"] = time()
							UnusedGear_savedata.itemLog[link]["countMoved"] = UnusedGear_savedata.itemLog[link].countMoved + 1
						end
					end
				end
			end
		end
	end
end

function UnusedGear.ExtractItems()
	UnusedGear.ForAllGear( "", "" )
end

function UnusedGear.GetItemIdFromLink( itemLink )
	-- returns just the integer itemID
	-- itemLink can be a full link, or just "item:999999999"
	if itemLink then
		return strmatch( itemLink, "item:(%d*)" )
	end
end
function UnusedGear.GetLastFreeSlotInBag( bagID )
	freeSlots, typeid = GetContainerNumFreeSlots( bagID )
	if( freeSlots > 0 ) then
		for slot = GetContainerNumSlots( bagID ), 0, -1 do
			local texture = GetContainerItemInfo( bagID, slot )
			if not texture then
				return bagID, slot
			end
		end
	end
end
function UnusedGear.hookSetItem( tooltip, ... ) -- is passed the tooltip frame as a table
	local item, link = tooltip:GetItem()  -- name, link
	if( UnusedGear_savedata.itemLog[link] and UnusedGear_savedata.itemLog[link].log ) then
		tooltip:AddDoubleLine( UnusedGear_savedata.itemLog[link].log, "Moved:"..UnusedGear_savedata.itemLog[link].countMoved )
	end
end


--[[
function INEED.hookSetItem(tooltip, ...)  -- is passed the tooltip frame as a table
	local item, link = tooltip:GetItem()  -- name, link
	local itemID = INEED.getItemIdFromLink( link )
]]
--[[
	local tooltipName = tooltip:GetName()
	local tooltipLine2 = _G[tooltipName.."TextLeft2"]
	local tooltipLine3 = _G[tooltipName.."TextLeft3"]
	local tooltipLine4 = _G[tooltipName.."TextLeft4"]
	local BindTypes = {
		[ITEM_SOULBOUND] = "Bound",
		[ITEM_BIND_ON_PICKUP] = "Bound",
	}


	INEED.Print( "tooltip:name = "..( tooltipName or "unknown" ).." "..
			( ( BindTypes[tooltipLine2:GetText()] or BindTypes[tooltipLine3:GetText()] or BindTypes[tooltipLine4:GetText()] ) and "isBound" or "isNotBound" ) )
]]
	-- local ScanTip2 = _G["AppraiserTipTextLeft2"]
	--.." "..ITEM_SOULBOUND.." "..ITEM_BIND_ON_PICKUP )
	-- INEED.Print("item: "..(item or "nil").." ID: "..itemID)
--[[
	if itemID and INEED_data[itemID] then
		for realm in pairs(INEED_data[itemID]) do
			if realm == INEED.realm then
				for name, data in pairs(INEED_data[itemID][realm]) do
					tooltip:AddDoubleLine(string.format("%s", name),
							string.format("Needs: %i / %i", data.total + (data.inMail or 0), data.needed) )
				end
			end
		end
	end
end

ONLOAD

G
]]