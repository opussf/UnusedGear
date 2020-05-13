# Feature

## Ignore bag flag

Don't examine items in the "Ignore this bag" setting.

local NUM_LE_BAG_FILTER_FLAGS = NUM_LE_BAG_FILTER_FLAGS
local LE_BAG_FILTER_FLAG_JUNK = LE_BAG_FILTER_FLAG_JUNK
local LE_BAG_FILTER_FLAG_EQUIPMENT = LE_BAG_FILTER_FLAG_EQUIPMENT


for bagid = NUM_BAG_SLOTS, 0, -1 do
		freeSlots, typeid = GetContainerNumFreeSlots(bagid)
		isEquipmentBag = GetBagSlotFlag( bagid, LE_BAG_FILTER_FLAG_EQUIPMENT )
		--print( "bag: "..bagid.." isType: "..typeid.." free: "..freeSlots.." isEquipmentBag: "..( isEquipmentBag and "True" or "False" ) )


Stripper/Notes:LE_BAG_FILTER_FLAG_IGNORE_CLEANUP = 1
Stripper/Notes:LE_BAG_FILTER_FLAG_EQUIPMENT = 2
Stripper/Notes:LE_BAG_FILTER_FLAG_CONSUMABLES
Stripper/Notes:LE_BAG_FILTER_FLAG_TRADE_GOODS
Stripper/Notes:NUM_LE_BAG_FILTER_FLAGS = 5