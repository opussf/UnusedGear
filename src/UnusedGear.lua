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
	local localizedClass, englishClass, classIndex = UnitClass( "player" )
	UnusedGear.maxArmorType = UnusedGear.armorTypes[ UnusedGear.maxArmorTypeByClass[ englishClass ] ]

	--AutoProfit:RegisterEvent("MERCHANT_CLOSED");
	--ap.ForAllJunk();
end

function UnusedGear.MERCHANT_SHOW()
	--UnusedGear.Print( "MERCHANT_SHOW" )
	UnusedGear.BuildGearSets()
	UnusedGear.ExtractItems()
end
UnusedGear.SCRAPPING_MACHINE_SHOW = UnusedGear.MERCHANT_SHOW
UnusedGear.AUCTION_HOUSE_SHOW = UnusedGear.MERCHANT_SHOW

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
			for slot = 0, GetContainerNumSlots( bag ) do -- work through this bad
				local texture, itemCount, locked, quality, readable, lootable, link =
						GetContainerItemInfo( bag, slot )
				if( quality ) then
					iArmorType = nil
					local iName, iLink, iRarity, iLevel, iMinLevel, iType, iSubType, iStackCount, iEquipLoc,
							iTexture, iSellPrice = GetItemInfo( link )
					iID = tonumber( UnusedGear.GetItemIdFromLink( iLink ) )
					iArmorType = UnusedGear.armorTypes[ iSubType ]
					--UnusedGear.Print( "Look at "..iID..": r: "..iRarity.." "..iType.."("..iSubType..") "..link )
					if( iRarity < 6 and ( ( iType == "Armor" and iArmorType ) or iType == "Weapon" or iSubType == "Shields" ) ) then
						-- 6 is Legandary, 7 is heirloom
						if( not UnusedGear.itemsInSets[ iID ] and not string.find( iName, "Tabard" ) ) then
							--UnusedGear.Print( "q: "..quality.." r: "..iRarity.." "..iType.."("..iSubType..") "..link )
							--UnusedGear.Print( "MOVE: "..link )
							targetBagID, targetSlot = UnusedGear.GetLastFreeSlotInBag( UnusedGear_Options.targetBag )
							if( targetBagID ) then
								ClearCursor()
								PickupContainerItem( bag, slot )
								if( targetBagID == 0 ) then
									PutItemInBackpack()
									moveCount = moveCount + 1
								else
									PutItemInBag( targetBagID+19 )
								end
							end
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

--[[
function Stripper.RemoveFromSlot( slotName, report )
	-- Remove an item from slotName with optional reporting
	-- String: slotName to remove an item from
	-- Boolean: report - to report or not.
	ClearCursor()
	local freeBagId = Stripper.getFreeBag()
	--Stripper.Print("Found a free bag: "..freeBagId);

	if freeBagId then
		local slotNum = GetInventorySlotInfo( slotName )
		--Stripper.Print(slotName..":"..slotNum..":"..(GetInventoryItemLink("player",slotNum) or "nil"))
		if report then
			Stripper.Print( "Removing "..(GetInventoryItemLink("player",slotNum) or "nil") )
		end
		PickupInventoryItem(slotNum)
		PickupContainerItem( bagID, slot )
		if freeBagId == 0 then
			PutItemInBackpack()
		else
			PutItemInBag(freeBagId+19)
		end
		return true
	else
		if report then
			Stripper.Print("No more stripping for you.  Inventory is full");
		end
	end
end
function Stripper.getFreeBag()
	-- http://www.wowwiki.com/BagId
	-- bags are 0 based, right to left.  0 = backpack
	local freeSlots, typeid, firstFreeBag, firstFreeEquipmentBag
	for bagid = NUM_BAG_SLOTS, 0, -1 do
		freeSlots, typeid = GetContainerNumFreeSlots(bagid)
		isEquipmentBag = GetBagSlotFlag( bagid, LE_BAG_FILTER_FLAG_EQUIPMENT )
		--print( "bag: "..bagid.." isType: "..typeid.." free: "..freeSlots.." isEquipmentBag: "..( isEquipmentBag and "True" or "False" ) )
		if( typeid == 0 ) then  -- 0 = no special bag type ( Herb, mine, fishing, etc... )
			if( not firstFreeBag ) then
				firstFreeBag = ( not isEquipmentBag and freeSlots > 0 ) and bagid
			end
			if( not firstFreeEquipmentBag ) then
				firstFreeEquipmentBag = ( isEquipmentBag and freeSlots > 0 ) and bagid
			end
		end
	end
	if( firstFreeEquipmentBag and firstFreeEquipmentBag >= 0 ) then
		--print( "returning firstFreeEquipmentBag: "..firstFreeEquipmentBag )
		return firstFreeEquipmentBag
	end
	if( firstFreeBag and firstFreeBag >=0 ) then
		--print( "returning firstFreeBag: "..firstFreeBag )
		return firstFreeBag
	end
end



function AP.ForAllJunk(action, message)
	local total_value = 0;
	for bag = 0, 4 do
		if GetContainerNumSlots(bag) > 0 then
			for slot = 0, GetContainerNumSlots(bag) do
				local texture, itemCount, locked, quality, readable, _, link =
						GetContainerItemInfo(bag, slot);
				if (quality) then
					local sell = AP.Sell(link);
					if (sell and autoProfitOptions["autoSell"] == 1) then
						--ap.Print(bag..":"..slot..":"..itemCount.."x"..link);
						--ap.Print("Sell this");
						if (message and autoProfitOptions["autoAnnounce"] == 1) then
							AP.Print(message(bag, slot));
						end
						total_value = total_value + (action(bag, slot) * itemCount);
					end
				end

			end -- for slot
		end -- if bag
	end -- for bag
	return total_value;
end

function AP.SellJunk()
	local total_sold = AP.ForAllJunk(
		function(bag, slot)  -- action
			local _, _, _, _, _, _, link = GetContainerItemInfo(bag, slot);
			local _,_, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(link);
			UseContainerItem(bag, slot);
			return vendorPrice;
		end,
		function(bag, slot)
			return "Sold " .. GetContainerItemLink(bag, slot);
		end);
	if (total_sold>0 and autoProfitOptions["autoAnnounce"] == 1 and autoProfitOptions["autoSell"] == 1) then
		AP.Print("Profit", AP.MoneyFormat(total_sold));
	end
end

]]

