local debug = require("temples/lib/tw-debug")("mk:temples:ui")
local data = require("temples/data")
local utils = require("temples/utils")
local split = utils.split
local trim = utils.trim
local _ = utils._

local ui = {}

local RELIGION_SUPERCHAIN = "troy_main_religion"
local DROPDOWN_BUTTONS = { "tab_factions", "tab_regions", "tab_units", "tab_events", "tab_missions", "tab_notifications" }

-- The dropdown panel is resized down when the height of all inner panels is below this threshold
local HEIGHT_THRESHOLD = 450

local templesDropdownUIC = nil
local bottomWidgetUIC = nil

function ui.destroyComponent(component)
    if not component then
        return
    end

    local root = core:get_ui_root()
    local dummy = find_uicomponent(root, 'DummyComponent')
    if not dummy then
        root:CreateComponent("DummyComponent", "UI/campaign ui/script_dummy")        
    end
    
    local gc = UIComponent(root:Find("DummyComponent"))
    gc:Adopt(component:Address())
    gc:DestroyChildren()
end

function ui.selectSettlement(id)
    local uic = find_uicomponent(core:get_ui_root(), "layout", "dropdown_parent_2", "regions_dropdown", "panel", "panel_clip", "listview", "list_clip", "list_box", "player_provinces", "list_box", "row_entry_" .. id)
    if not uic then
        debug("selectSettlement: Cannot find entry " .. id)
        return
    end

    uic:SimulateLClick()
end

function ui.createRowUIC(temple, parentId, options)
    options = options or {}
  
    local hideIncome = type(options.hideIncome) ~= "nil" and options.hideIncome or false

    local id = temple.province
    -- root > layout > faction_buttons_docker > bar_small_top > TabGroup > tab_regions
    local list = find_uicomponent(core:get_ui_root(), "layout", "dropdown_parent_2", "regions_dropdown", "panel", "panel_clip", "listview", "list_clip", "list_box", "player_provinces", "list_box")
    -- local firstRegionName = find_uicomponent(list, "region_name")
    local rowToCopy = find_uicomponent(list, "row_entry_" .. temple.province)

    if not rowToCopy then
        local btn = find_uicomponent(core:get_ui_root(), "layout", "faction_buttons_docker", "bar_small_top", "TabGroup", "tab_regions")
        btn:SimulateLClick()
        
        rowToCopy = find_uicomponent(list, "row_entry_" .. temple.province)
        btn:SimulateLClick()
    end

    if not rowToCopy then
        return
    end

    local row = UIComponent(rowToCopy:CopyComponent("mk_ui_temples_row_entry_" .. id))
    local parent = find_uicomponent(core:get_ui_root(), "mk_ui_temples_dropdown", "panel", "panel_clip", "listview", "list_clip", "list_box", parentId, "list_box")
    row:PropagatePriority(parent:Priority())
    parent:Adopt(row:Address())

    local localisedProvinceName = effect.get_localised_string("provinces_onscreen_" .. id)
    local localisedRegionName = effect.get_localised_string("regions_onscreen_" .. temple.region)
    local localisedBuildingName = effect.get_localised_string("building_culture_variants_name_" .. temple.temple)
    local localisedZoomClick = effect.get_localised_string("uied_component_texts_localised_string_other_row_Tooltip_7d0008")
    local localisedCapital = effect.get_localised_string("uied_component_texts_localised_string_header_capital_NewState_Text_53000b")
    -- local localisedTemple = effect.get_localised_string("building_sets_onscreen_name_troy_temples_only")
    -- local localisedLevel = effect.get_localised_string("random_localisation_strings_string_level_level_level_level")

    local tooltipTemple = "[[img:" .. temple.icon .. "]] " .. localisedBuildingName
    local tooltip = localisedCapital .. localisedRegionName
    tooltip = tooltip .. " " .. tooltipTemple
    tooltip = tooltip .. "\n" .. localisedZoomClick

    find_uicomponent(row, "icon_public_order"):SetVisible(false)

    find_uicomponent(row, "region_name"):SetStateText(localisedProvinceName)
    find_uicomponent(row, "region_name"):SetTooltipText(tooltip, true)

    local monUIC = find_uicomponent(row, "mon")
    local monState = find_uicomponent(rowToCopy, "mon"):CurrentState()
    monUIC:SetState(monState)

    if not hideIncome then
        local coin = find_uicomponent(row, "income", "coin")
        coin:SetImagePath(temple.icon)
        coin:SetCanResizeWidth(true)
        coin:SetCanResizeHeight(true)
        coin:Resize(40, 40)

        local x, y = coin:Position()
        coin:MoveTo(x - 40, y)

        local income = find_uicomponent(row, "income")
        income:SetStateText("    " .. temple.level)
        income:SetTooltipText(tooltipTemple, true)
    else
        find_uicomponent(row, "income"):SetVisible(false)
    end

    row:SetProperty("province", temple.province)
    row:SetProperty("region", temple.region)
    row:SetProperty("level", temple.level)
    row:SetProperty("temple", temple.temple)
    row:SetProperty("icon", temple.icon)

    ui.registerRowClickListener(row)

    return row
end

function ui.registerRowClickListener(row)
    local province = row:GetProperty("province")
    local listener = "mk_ui_" .. province .. "_click_listener"
    row:SetProperty("listener", listener)

    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return row == UIComponent(context.component) end,
        function(context)
            ui.selectSettlement(province)
        end,
        true
    )
end

function ui.buildTemplesDropdownUIC()
    local parent = find_uicomponent(core:get_ui_root(), "layout", "dropdown_parent_2")
    local regionsDropdown = find_uicomponent(core:get_ui_root(), "layout", "dropdown_parent_2", "regions_dropdown")
    
    local uic = core:get_or_create_component("mk_ui_temples_dropdown", "ui/campaign ui/regions_dropdown")
    
    uic:PropagatePriority(parent:Priority())
    parent:Adopt(uic:Address())
    
    local panel = find_uicomponent(uic, "panel")
    panel:SetVisible(true)
    
    uic:SetMoveable(true)
    uic:SetCanResizeHeight(true)
    uic:SetCanResizeWidth(true)
    
    local w, h = uic:Bounds()
    local rX, rY = regionsDropdown:Position()
    --uic:Resize(w, 716)
    uic:MoveTo(rX, rY)    

    local title = find_uicomponent(panel, "panel_clip", "title", "header", "tx_title_text")
    title:SetStateText("Temples")
    
    -- mk_ui_temples_dropdown > panel > panel_clip > player_row
    find_uicomponent(panel, "panel_clip", "player_row"):SetVisible(false)
    find_uicomponent(panel, "panel_clip", "other_row"):SetVisible(false)
    
    -- mk_ui_temples_dropdown > panel > panel_clip > listview > list_clip > list_box > other_provinces
    find_uicomponent(panel, "panel_clip", "listview", "other_provinces"):SetVisible(false)

    local provincesList = find_uicomponent(panel, "panel_clip", "listview", "player_provinces")
    

    local capitals = data.getOwnedCapitals()
    if #capitals == 0 then
        ui.createNoCapitalText(provincesList)
        provincesList:SetVisible(false)
        return uic
    end


    local templesData = data.getTemplesData(capitals)
    -- Build each temples section (athena, ares, apollo, ...)
    for key, templeKey in pairs(data.TEMPLE_CHAINS) do
        ui.buildProvinceListSectionForGod(key, templeKey, provincesList, templesData)
    end

    -- Also build the "none" section, list of provinces with an owned capital without temple built
    ui.buildProvinceListSectionWithoutTemple(provincesList, templesData)

    provincesList:SetVisible(false)
    return uic
end

function ui.buildProvinceListSectionForGod(key, templeKey, provincesList, templesData)
    local templesForGod = templesData[key]
    if not templesForGod then
        debug("Don't build ui for %s section as there is no temples built yet", key)
        return
    end
    
    local templeList = UIComponent(provincesList:CopyComponent("mk_ui_" .. templeKey))
    local listTitle = find_uicomponent(templeList, "tx_list_title")
    local ltW, ltH = listTitle:Bounds()
    listTitle:SetStateText(key)

    local height = 35 + ltH

    for i = 1, #templesForGod do
        local temple = templesForGod[i]
        local row = ui.createRowUIC(temple, "mk_ui_" .. templeKey)
        local rW, rH = row:Bounds()

        height = height + rH
    end

    -- local listBox = find_uicomponent(templeList, "list_box")
    local lW, lH = templeList:Bounds()
    templeList:SetCanResizeHeight(true)
    templeList:Resize(lW, height)
    
    local headers = find_uicomponent(templeList, "headers")
    
    find_uicomponent(headers, "sort_happiness"):SetVisible(false)
    find_uicomponent(headers, "sort_koku"):SetVisible(false)
    find_uicomponent(headers, "sort_resource"):SetVisible(false)
    find_uicomponent(headers, "sort_food"):SetVisible(false)
    find_uicomponent(headers, "sort_dev_pts"):SetVisible(false)
    find_uicomponent(headers, "resources_cycle"):SetVisible(false)
    find_uicomponent(headers, "cycle_button_arrow_left"):SetVisible(false)
    find_uicomponent(headers, "cycle_button_arrow_right"):SetVisible(false)
    find_uicomponent(headers, "sort_pooled_resource"):SetVisible(false)

    local sortBtn = ui.createSortButton(headers, templeKey)
    return templeList
end

function ui.buildProvinceListSectionWithoutTemple(provincesList, templesData)
    if not templesData.none then
        debug("Don't build ui for none section as there is no provinces without temples")
        return
    end

    local templeKey = "none"
    local templeList = UIComponent(provincesList:CopyComponent("mk_ui_" .. templeKey))
    local listTitle = find_uicomponent(templeList, "tx_list_title")
    local ltW, ltH = listTitle:Bounds()
    listTitle:SetStateText("No Temples")

    local templesForGod = templesData.none
    local height = 35 + ltH

    for i = 1, #templesForGod do
        local temple = templesForGod[i]
        local row = ui.createRowUIC(temple, "mk_ui_" .. templeKey, { hideIncome = true })
        local rW, rH = row:Bounds()

        height = height + rH
    end

    -- local listBox = find_uicomponent(templeList, "list_box")
    local lW, lH = templeList:Bounds()
    templeList:SetCanResizeHeight(true)
    templeList:Resize(lW, height)
    
    find_uicomponent(templeList, "headers", "sort_happiness"):SetVisible(false)
    find_uicomponent(templeList, "headers", "sort_koku"):SetVisible(false)
    find_uicomponent(templeList, "headers", "sort_resource"):SetVisible(false)
    find_uicomponent(templeList, "headers", "sort_food"):SetVisible(false)
    find_uicomponent(templeList, "headers", "sort_dev_pts"):SetVisible(false)
    find_uicomponent(templeList, "headers", "resources_cycle"):SetVisible(false)
    find_uicomponent(templeList, "headers", "cycle_button_arrow_left"):SetVisible(false)
    find_uicomponent(templeList, "headers", "cycle_button_arrow_right"):SetVisible(false)
    find_uicomponent(templeList, "headers", "sort_pooled_resource"):SetVisible(false)

    return templeList
end

function ui.createNoCapitalText(provincesList)
    local templeKey = "_no_capitals"
    local panel = UIComponent(provincesList:CopyComponent("mk_ui_" .. templeKey))
    local listTitle = find_uicomponent(panel, "tx_list_title")
    local ltW, ltH = listTitle:Bounds()
    listTitle:SetStateText("You don't own any capitals yet")

    find_uicomponent(panel, "headers", "sort_name"):SetVisible(false)
    find_uicomponent(panel, "headers", "sort_happiness"):SetVisible(false)
    find_uicomponent(panel, "headers", "sort_koku"):SetVisible(false)
    find_uicomponent(panel, "headers", "sort_resource"):SetVisible(false)
    find_uicomponent(panel, "headers", "sort_food"):SetVisible(false)
    find_uicomponent(panel, "headers", "sort_dev_pts"):SetVisible(false)
    find_uicomponent(panel, "headers", "resources_cycle"):SetVisible(false)
    find_uicomponent(panel, "headers", "cycle_button_arrow_left"):SetVisible(false)
    find_uicomponent(panel, "headers", "cycle_button_arrow_right"):SetVisible(false)
    find_uicomponent(panel, "headers", "sort_pooled_resource"):SetVisible(false)

    return panel
end

function ui.createSortButton(parent, templeKey)
    local sortResource = find_uicomponent(parent, "sort_pooled_resource")
    local sortName = find_uicomponent(parent, "sort_name")
    local koku = find_uicomponent(parent, "sort_koku")
    local panel = UIComponent(parent:Parent())

    local xResource, yResource = sortResource:Position()
    local xName, yName = sortName:Position()

    local btn = UIComponent(koku:CopyComponent("sort_temple_level"))
    btn:PropagatePriority(parent:Priority())
    parent:Adopt(btn:Address())

    btn:MoveTo(xResource + 20, yName)
    btn:SetTooltipText("Sort by Building Level", true)
    btn:SetVisible(true)
    btn:SetState("selected_down")

    local listener = "mk_ui_" .. templeKey .. "_sort_temple_level_click_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return btn == UIComponent(context.component) end,
        function()
            local state = btn:CurrentState()

            local rows = {}
            local list = find_uicomponent(panel, "list_box")
            for i = 0, list:ChildCount() - 1 do
                local child = UIComponent(list:Find(i))
                table.insert(rows, child)
            end

            table.sort(rows, function(a, b)
                local levelA = tonumber(a:GetProperty("level"))
                local levelB = tonumber(b:GetProperty("level"))

                if state == "selected_down" then
                    return levelA < levelB
                else
                    return levelA > levelB
                end
            end)

            for k, v in pairs(rows) do
                -- Have to copy the rows to workaround the slider being pulled back to top when all rows are removed
                -- Can't just Divorce and Readopt after
                local copy = UIComponent(v:CopyComponent(v:Id()))
                local mon = find_uicomponent(v, "mon")

                find_uicomponent(copy, "mon"):SetState(mon:CurrentState())
                ui.registerRowClickListener(copy)
                ui.destroyComponent(v)
            end                      
        end,
        true
    )

    return btn
end

function ui.buildBottomWidgetUIC()
    local parent = find_uicomponent(core:get_ui_root(), "layout", "faction_buttons_docker")
    local widget = find_uicomponent(parent, "dropdown_bottom_widget_stone_base")
    local copy = UIComponent(widget:CopyComponent("mk_ui_dropdown_bottom_widget_stone_base"))
    
    local x, y = widget:Position()
    copy:MoveTo(x, y)

    local addresses = {}
    local children = { "dropdown_bottom_widget_stone_base", "frame", "radar_things", "bar_small_top", "end_turn_docker", "tab_events_overlay", "button_end_turn_overlay" }

    for k, v in pairs(children) do
        local uic = find_uicomponent(parent, v)
        
        local address = uic:Address()
        uic:Divorce(address)
        table.insert(addresses, address)
    end
    
    for k, v in pairs(addresses) do
        parent:Adopt(v)
    end

    copy:SetVisible(true)
    return copy
end

local preventDropdownButtonEvent = false
function ui.closeDropdown()
    local buttons = DROPDOWN_BUTTONS

    for k, v in pairs(buttons) do
        local btn = find_uicomponent(core:get_ui_root(), "faction_buttons_docker", v)
        local state = btn:CurrentState()
        
        if state == "selected" then
            preventDropdownButtonEvent = true
            btn:SimulateLClick()
            preventDropdownButtonEvent = false
        end
    end
end

function ui.onButtonClick()
    if not templesDropdownUIC then
        templesDropdownUIC = ui.buildTemplesDropdownUIC()
    else
        templesDropdownUIC:SetVisible(not templesDropdownUIC:Visible())
    end

    if not bottomWidgetUIC then
        bottomWidgetUIC = ui.buildBottomWidgetUIC()
    else
        bottomWidgetUIC:SetVisible(not bottomWidgetUIC:Visible())
    end

    ui.resizeTemplesDropdown()
    ui.repositionTemplesDropdown()

    local visible = templesDropdownUIC:Visible()
    if visible then
        ui.closeDropdown()
    end
end

function ui.buildButtonUIC()
    local uic = find_uicomponent(core:get_ui_root(), "layout", "faction_buttons_docker", "bar_small_top", "TabGroup", "tab_regions")
    local copy1 = UIComponent(uic:CopyComponent("mk_ui_btn_dummy_01"))
    local copy2 = UIComponent(uic:CopyComponent("mk_ui_btn_dummy_02"))
    local btn = UIComponent(uic:CopyComponent("mk_ui_btn_temples"))

    copy1:SetState("inactive")
    copy1:SetOpacity(0)
    copy1:SetTooltipText("", true)

    copy2:SetState("inactive")
    copy2:SetOpacity(0)
    copy2:SetTooltipText("", true)

    btn:SetTooltipText("Temples", true)
    btn:SetImagePath("ui/buildings/icons/build_icon_zeus_religious.png")

    local listener = "mk_ui_tab_temple_click_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return btn == UIComponent(context.component) end,
        function()
            ui.onButtonClick()
            if templesDropdownUIC and templesDropdownUIC:Visible() then
                ui.dockToBottom()

                
                cm:callback(function()
                    local x, y = templesDropdownUIC:Position()
                    local pX, pY = _("layout > dropdown_parent_2 > regions_dropdown"):Position()
                    if pY ~= y then
                        debug("Callback dockToBottom different position, redock to bottom")
                        ui.dockToBottom()
                    end
                end, 0.1)
            end
        end,
        true
    )

    return btn
end

function ui.destroyTemplesDropdown()
    debug("destroyTempleDropdown")
    ui.destroyComponent(templesDropdownUIC)
    templesDropdownUIC = nil
end

function ui.repositionTemplesDropdown()
    local height = ui.getListBoxHeight()
    if height < HEIGHT_THRESHOLD then
        debug("repositionTemplesDropdown height below threshold, just dock to bottom", height, HEIGHT_THRESHOLD)
        -- ui.dockToBottom()
        return
    end

    debug("repositionTemplesDropdown")
    if not templesDropdownUIC then
        return
    end

    local selectors = {
        "panel",
        "panel > panel_clip",
        "panel > panel_clip > listview"
    }

    local regionsDropdown = find_uicomponent(core:get_ui_root(), "layout", "dropdown_parent_2", "regions_dropdown")
    local x, y = regionsDropdown:Position()
    templesDropdownUIC:MoveTo(x ,y)

    for k, v in pairs(selectors) do
        local ref = _("root > layout > dropdown_parent_2 > regions_dropdown > " .. v)
        local x, y = ref:Position()
        local uic = _("mk_ui_temples_dropdown > " .. v)
        local x2, y2 = uic:Position()
        uic:MoveTo(x, y)
        x2, y2 = uic:Position()
    end
end


function ui.dockToBottom()
    debug("dockToBottom")
    if not templesDropdownUIC then
        return
    end

    -- debug("Open / close province panel to update its position")
    -- local tabRegionsBtn = _("layout", "faction_buttons_docker", "tab_regions")
    -- tabRegionsBtn:SimulateLClick()
    -- tabRegionsBtn:SimulateLClick()

    local x, y = _("mk_ui_dropdown_bottom_widget_stone_base"):Position()
    local wW, wH = _("mk_ui_dropdown_bottom_widget_stone_base"):Bounds()
    local x2, y2 = templesDropdownUIC:Position()
    local w, h = templesDropdownUIC:Bounds()

    local pX, pY = _("layout > dropdown_parent_2 > regions_dropdown"):Position()
    local pW, pH = _("layout > dropdown_parent_2 > regions_dropdown"):Bounds()

    debug("mk_ui_dropdown_bottom_widget_stone_base position:", {x,y})
    debug("mk_ui_dropdown_bottom_widget_stone_base bounds:", {wW,wH})
    
    debug("templesDropdownUIC position:", {x2,y2})
    debug("templesDropdownUIC bounds:", {w,h})
    
    debug("regions_dropdown bounds:", {pX, pY})
    debug("regions_dropdown bounds:", {pW, pH})
    
    debug("Dock to", x2, pY)
    templesDropdownUIC:MoveTo(x2, pY)

    local x22, y22 = templesDropdownUIC:Position()
    debug("New position:", x22, y22)
end


function ui.resizeTemplesDropdown()
    local height = ui.getListBoxHeight()
    if height < HEIGHT_THRESHOLD then
        return
    end

    local selectors = {
        "panel > panel_clip > listview > list_clip",
        "panel > panel_clip > listview",
        "panel > panel_clip",
        "panel",
        ""
    }

    for k, v in pairs(selectors) do
        local selector = v ~= "" and " > " .. v or v

        local ref = _("regions_dropdown" .. selector)
        local uic = _("mk_ui_temples_dropdown" .. selector)
        uic:SetCanResizeWidth(true)
        uic:SetCanResizeHeight(true)

        local w, h = ref:Bounds()
        uic:Resize(w, h)
    end

    local x, y = _("regions_dropdown > panel > panel_clip > listview > vslider"):Position()
    local x2, y2 = _("mk_ui_temples_dropdown > panel > panel_clip > listview > vslider"):Position()
    _("mk_ui_temples_dropdown > panel > panel_clip > listview > vslider"):MoveTo(x, y2)
end

function ui.getListBoxHeight()
    local height = 0
    local box = _("mk_ui_temples_dropdown > panel > panel_clip > listview > list_clip > list_box")
    for i = 0, box:ChildCount() - 1 do       
        local panel = UIComponent(box:Find(i))
        local w2, h2 = panel:Bounds()
        local id = panel:Id()
        if id ~= "player_provinces" and id ~= "other_provinces" then
            height = height + h2
        end
    end
    
    return height
end

function ui.closeTemplesDropdown()
    local templeBtn = find_uicomponent(core:get_ui_root(), "mk_ui_btn_temples")
    local state = templeBtn:CurrentState()
    
    if state == "selected" then
        templeBtn:SimulateLClick()
    end
    
    if templesDropdownUIC then
        templesDropdownUIC:SetVisible(false)
    end

    if bottomWidgetUIC then
        bottomWidgetUIC:SetVisible(false)
    end
end

function ui.registerDropdownButtonsListeners()
    local buttons = DROPDOWN_BUTTONS

    local parent = find_uicomponent(core:get_ui_root(), "layout", "faction_buttons_docker")
    local templeBtn = find_uicomponent(parent, "mk_ui_btn_temples")

    for k, v in pairs(buttons) do
        local btn = find_uicomponent(parent, v)

        local listener = "mk_ui_" .. v .. "_listener"
        core:remove_listener(listener)
        core:add_listener(
            listener,
            "ComponentLClickUp",
            function(context) return btn == UIComponent(context.component) and not preventDropdownButtonEvent end,
            function(context)
                ui.closeTemplesDropdown()
            end,
            true
        )
    end
end

-- root > layout > faction_buttons_docker > end_turn_docker > button_end_turn
function ui.registerEndTurnButtonListeners()
    local btn = find_uicomponent(core:get_ui_root(), "layout", "faction_buttons_docker", "end_turn_docker", "button_end_turn")
    local listener = "mk_ui_end_turn_btn_listener"

    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return btn == UIComponent(context.component) end,
        function(context)
            ui.closeTemplesDropdown()
        end,
        true
    )
end

function ui.registerUIListeners()
    local localFaction = cm:get_local_faction()

    local listeners = {
        RegionFactionChangeEvent = "mk_ui_RegionFactionChangeEvent_listener",
        PanelOpenedCampaign = "mk_ui_PanelOpenedCampaign_listener",
        PanelClosedCampaign = "mk_ui_PanelClosedCampaign_listener",
        BuildingCompleted = "mk_ui_BuildingCompleted_listener",
        BuildingDemolished = "mk_ui_BuildingDemolished_listener",
        PanelOpenedCampaignEscMenu = "mk_ui_PanelOpenedCampaignEscMenu_listener",
        CharacterDetailsOpenedCampaign = "mk_ui_PanelOpenedCampaign_character_details_panel_listener",
    }

    core:remove_listener(listeners.RegionFactionChangeEvent)
    core:remove_listener(listeners.PanelOpenedCampaign)
    core:remove_listener(listeners.PanelClosedCampaign)
    core:remove_listener(listeners.BuildingCompleted)
    core:remove_listener(listeners.BuildingDemolished)
    core:remove_listener(listeners.PanelOpenedCampaignEscMenu)
    core:remove_listener(listeners.CharacterDetailsOpenedCampaign)

    core:add_listener(
        listeners.PanelOpenedCampaignEscMenu,
        "PanelOpenedCampaign",
        function(context)
            return context.string == "esc_menu_campaign"
        end,
        function(context)
            debug("PanelOpenedCampaignEscMenu", context.string)
            ui.closeTemplesDropdown()
            ui.destroyTemplesDropdown()
        end,
        true
    )

    core:add_listener(
        listeners.RegionFactionChangeEvent,
        "RegionFactionChangeEvent",
        function(context)
            local prevFaction = context:previous_faction():name()
            local newFaction = context:region():owning_faction():name()
            return prevFaction == localFaction or newFaction == localFaction
        end,
        function(context)
            debug("RegionFactionChangeEvent for %s faction", localFaction)
            ui.closeTemplesDropdown()
            ui.destroyTemplesDropdown()
        end,
        true
    )

    core:add_listener(
        listeners.PanelOpenedCampaign,
        "PanelOpenedCampaign",
        function(context) 
            local panel = context.string
            return panel ~= "units_panel" and panel ~="settlement_panel" and panel ~= "character_details_panel"
        end,
        function(context)
            debug("PanelOpenedCampaign", context.string)
            ui.closeTemplesDropdown()
        end,
        true
    )

    core:add_listener(
        listeners.CharacterDetailsOpenedCampaign,
        "PanelOpenedCampaign",
        function(context) 
            local panel = context.string
            return panel == "character_details_panel"
        end,
        function(context)
            debug("PanelOpenedCampaign CharacterDetailsOpenedCampaign", context.string)
            ui.closeTemplesDropdown()
            -- ui.destroyTemplesDropdown()
        end,
        true
    )

    core:add_listener(
        listeners.PanelClosedCampaign,
        "PanelClosedCampaign",
        function(context) return true end,
        function(context)
            debug("PanelClosedCampaign", context.string)
            ui.repositionTemplesDropdown()
        end,
        true
    )

    core:add_listener(
        listeners.BuildingCompleted,
        "BuildingCompleted",
        function(context)
            local building = context:building()
            local superchain = building:superchain()
            local faction = building:faction():name()

            return faction == localFaction and superchain == RELIGION_SUPERCHAIN
        end,
        function(context)
            local building = context:building()
            debug("BuildingCompleted building", building:name())

            ui.closeTemplesDropdown()
            ui.destroyTemplesDropdown()
        end,
        true
    )

    -- superchain troy_main_religion
    core:add_listener(
        listeners.BuildingDemolished,
        "BuildingDemolished",
        function(context) 
            local building = context:building()
            local superchain = building:superchain()
            local faction = building:faction():name()

            return faction == localFaction and superchain == RELIGION_SUPERCHAIN
        end,
        function(context)
            local building = context:building()
            debug("BuildingDemolished building", building:name())

            ui.closeTemplesDropdown()
            ui.destroyTemplesDropdown()
        end,
        true
    )
end

function ui.build()
    debug("Build UI")
    ui.buildButtonUIC()
    ui.registerDropdownButtonsListeners()
    ui.registerEndTurnButtonListeners()
    ui.registerUIListeners()
end

function ui.init()
    local turn = cm:turn_number()
    local isNewGame = cm:is_new_game()
    debug("Init, turn number is %d", turn)
    debug("New game: ", isNewGame)

    if not isNewGame then
        ui.build()
        return
    end

    debug("New game, special care to build UI only when the first event panel is closed. Otherwise, UI becomes unresponsive")

    local listener = "mk_ui_PanelClosedCampaign_first_turn_listener"
    core:add_listener(
        listener,
        "PanelClosedCampaign",
        function(context) return context.string == "events" end,
        function(context)
            debug("Close events for first turn, delayed build")
            core:remove_listener(listener)
            ui.build()
        end,
        true
    )
    
end

_G.ui = ui
return ui