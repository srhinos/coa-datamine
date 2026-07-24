
local L = {}
local moves = {};
local depth = 0;
local frame = CreateFrame("Frame");
local t = 0;
local current = nil;
local log = {};

local function Log(msg)
    table.insert(log, msg);

    if (SOCD ~= nil) then
        SOCD.log = log;
    end
end

local function ClearLog()
    log = {};
end

local function GetIDFromLink(link)
    Log("GetIDFromLink("..tostring(link)..")");
    return link and tonumber(string.match(link, "item:(%d+)"));
end

local function DoMoves()
    Log("DoMoves()");

    while (current ~= nil or #moves > 0) do
        if current ~= nil then    
            Log("current.id = "..tostring(current.id));
            if CursorHasItem() then
                Log("Cursor Has Item");
                local type, id = GetCursorInfo();
                Log("type = "..tostring(type)..", id = "..tostring(id));
                if (current ~= nil and current.id == id) then
                    if (current.sourcebag ~= nill) then
                        Log("PickupContainerItem("..current.targetbag..", "..current.targetslot..")");

                        PickupContainerItem(current.targetbag, current.targetslot);

            	        local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                        if (current.id ~= GetIDFromLink(link)) then
                            return;
                        end
                    end
                else
                    Log("Sort Aborted");
                    moves = {};
                    current = nil;
                    frame:Hide();
                    return;
                end
            else
                if (current.sourcebag ~= nill) then
        	        local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                    if (current.id ~= GetIDFromLink(link)) then
                        return;
                    end
                end
                current = nil;
            end
        else      
            Log("current == nil");
            if (#moves > 0) then
                Log("("..#moves.." > 0)");
        
                current = table.remove(moves, 1);

                if (current.sourcebag ~= nill) then
                    Log("PickupContainerItem("..current.sourcebag..", "..current.sourceslot..")");
                    PickupContainerItem(current.sourcebag, current.sourceslot);
                    if CursorHasItem() == false then
                        return;
                    end 
                    
                    Log("PickupContainerItem("..current.targetbag..", "..current.targetslot..")");
                    PickupContainerItem(current.targetbag, current.targetslot);
        	        local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                    if (current.id == GetIDFromLink(link)) then
                        Log("current = nil");
                        current = nil;
                    else
                        return;
                    end
                end

            end        
        end
    end
    Log("Sorted!");
    frame:Hide();
end

local function CompareItems(lItem, rItem)
    Log("CompareItems("..lItem.name..", "..rItem.name..")");

    if (rItem.id == nil) then
        Log("(rItem.id == nil)");
        return true;
    elseif (lItem.id == nil) then
        Log("(lItem.id == nil)");
        return false;
    elseif (lItem.class ~= rItem.class) then
        Log("(lItem.class ~= rItem.class)");
        return (lItem.class < rItem.class);
    elseif (lItem.subclass ~= rItem.subclass) then
        Log("(lItem.subclass ~= rItem.subclass)");
        return (lItem.subclass < rItem.subclass);
    elseif (lItem.quality ~= rItem.quality) then
        Log("(lItem.quality ~= rItem.quality)");
        return (lItem.quality > rItem.quality);
    elseif (lItem.name ~= rItem.name) then
        Log("(lItem.name ~= rItem.name)");
        return (lItem.name < rItem.name);
    elseif ((lItem.count) ~= (rItem.count)) then
        Log("((lItem.count) ~= (rItem.count))");
        return ((lItem.count) >= (rItem.count));
    else
        Log("return true");
        return true;
    end
end

local function BeginSort()
    Log("BeginSort()");
    current = nil;
    moves = {};
    ClearCursor();
end

local function SortBag(bag)
    Log("SortBag(bag)");
    
    for i=1,#bag,1 do
        Log("i="..i);
        local lowest = i;
        for j=#bag,i+1,-1 do
            Log("j="..j);
            if (CompareItems(bag[lowest],bag[j]) == false) then
                Log("lowest="..j);
                lowest = j;
            end
        end
        if (i ~= lowest) then
            Log("(i ~= lowest)");

            -- store move
            move = {};
            move.id = bag[lowest].id;
            move.name = bag[lowest].name;
            move.sourcebag = bag[lowest].bag;
            move.sourcetab = bag[lowest].tab;
            move.sourceslot = bag[lowest].slot;
            move.targetbag = bag[i].bag;
            move.targettab = bag[i].tab;
            move.targetslot = bag[i].slot;
            table.insert(moves, move);
            Log("move "..move.name.." from "..move.sourceslot.." to "..move.targetslot);
            
            -- swap items
            local tmp = bag[i];
            bag[i] = bag[lowest];
            bag[lowest] = tmp;

            Log("bag[i] = "..bag[i].name.."("..bag[i].slot.."), bag[lowest] = "..bag[lowest].name.."("..bag[lowest].slot..")");

            -- swap slots
            tmp = bag[i].slot;
            bag[i].slot = bag[lowest].slot;
            bag[lowest].slot = tmp;
            tmp = bag[i].bag;
            bag[i].bag = bag[lowest].bag;
            bag[lowest].bag = tmp;
            tmp = bag[i].tab;
            bag[i].tab = bag[lowest].tab;
            bag[lowest].tab = tmp;

            Log("bag[i] = "..bag[i].name.."("..bag[i].slot.."), bag[lowest] = "..bag[lowest].name.."("..bag[lowest].slot..")");
        end
    end
end

local function CreateBagFromID(bagID)
    Log("CreateBagFromID("..bagID..")");

    local items = GetContainerNumSlots(bagID);
    local bag = {};

    Log("items = "..items);

	for i=1, items, 1 do
	    local item = {};

        Log("i = "..i);

	    local _, count, _, _, _, _, link = GetContainerItemInfo(bagID, i);
	    item.bag = bagID;
	    item.slot = i;
	    item.name = "<EMPTY>";
        item.id = GetIDFromLink(link);
        if (item.id ~= nil) then
            item.count = count;
            item.name, _, item.quality, _, _, item.class, item.subclass, _, item.type, _, item.price = GetItemInfo(item.id);
        end

        Log("item = "..item.name);

        table.insert(bag, item);
    end
    return bag;
end

local function SOCD_BagSortButton(self) 
    ClearLog();

    Log("SOCD_BagSortButton(self)");
    local bags = {};

	for i=0, NUM_BAG_FRAMES, 1 do
	    local framenum = i + 1;
        Log("Bag #"..i.." is checked");
        local bag = CreateBagFromID(i);
        local type = select(2, GetContainerNumFreeSlots(i));
        if type == nil then
            type = "ALL"
        else
            type = tostring(type);
        end
        Log("type = "..type);
        if bags[type] == nil then
            Log("bags[type] == nil");
            bags[type] = bag; 
        else
            Log("bags[type] ~= nil");
            Log("#bags[type] = "..#bags[type]);
            for j=1, #bag, 1 do
                table.insert(bags[type], bag[j]);
            end
            Log("#bags[type] = "..#bags[type]);
        end
    end

    BeginSort();
    for k,v in pairs(bags) do
	    if v ~= nil then
            Log("k = "..k..", v ~= nli");
	        SortBag(v);
	    end   
    end        
    frame:Show();
end

local function CreateSortButton(name, parent, x, y, handler)
    Log("CreateSortButton("..name..", parent, "..x..", "..y..", handler)");

    parent.sortButton = CreateFrame("Button", name, parent, "UIPanelButtonTemplate");
    parent.sortButton.parentFrame = parent;
    parent.sortButton:SetWidth(23);
    parent.sortButton:SetHeight(23);
    parent.sortButton:ClearAllPoints();
    parent.sortButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y);
    parent.sortButton:SetNormalTexture("Interface\\AddOns\\BagSort\\Bags")
    parent.sortButton:GetNormalTexture():SetTexCoord(.12109375, .23046875, .7265625, .9296875)
    parent.sortButton:SetPushedTexture("Interface\\AddOns\\BagSort\\Bags")
	parent.sortButton:GetPushedTexture():SetTexCoord(.00390625, .11328125, .7265625, .9296875)

    if SOCD.IsEnabled then
        parent.sortButton:Show();
    else
        parent.sortButton:Hide();
    end

    parent.sortButton:SetScript("OnClick", handler);

    parent.sortButton:SetScript("OnEnter", function(self)
	    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", -20, -220)
	    GameTooltip:SetText("Click to sort your inventory.")
	    GameTooltip:Show()
    end)

    parent.sortButton:SetScript("OnLeave", function()
	    GameTooltip:Hide()
    end)
end

function SOCD_MainFrame_OnLoad(self)
    Log("SOCD_MainFrame_OnLoad(self)");

    local fEnable = true;
    if (SOCD ~= nil and SOCD.IsEnabled ~= nil) then
        Log("(SOCD ~= nil and SOCD.IsEnabled ~= nil)");
        fEnable = SOCD.IsEnabled;
    end

    SOCD = {};
    Log("SOCD = {};");
    SOCD.IsEnabled = fEnable;
    Log("SOCD.IsEnabled = "..tostring(SOCD.IsEnabled));

    CreateSortButton("ContainerFrame1SortButton", _G["ContainerFrame1"], 142, -6, SOCD_BagSortButton);

    frame:SetScript("OnUpdate", function()
        Log("OnUpdate("..arg1..")");
    	t = t + arg1;
        Log("t = "..t);
    	if t > 0.05 then
            Log("t > 0.05");
    		t = 0
            DoMoves();
    	end
    end)
    frame:Hide();
end

function SOCD_MainFrame_OnEvent(self, event, ...)
    Log("SOCD_MainFrame_OnEvent(self, "..event..", ...)");
end
