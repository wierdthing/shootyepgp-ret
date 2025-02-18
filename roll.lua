-- Ensure ShootyEPGP_RollPos is initialized with default values
ShootyEPGP_RollPos = ShootyEPGP_RollPos or { x = 400, y = 300 }
sepgp_showRollWindow = true

-- Function to execute commands
local function ExecuteCommand(command)
    if command == "roll" then
        RandomRoll(1, 100)
    elseif command == "roll 99" then
        RandomRoll(1, 99)
    elseif command == "roll 50" then
        RandomRoll(1, 50)
    elseif command == "ret roll" then
        -- Retroll (SR)
        if sepgp and sepgp.RollCommand then
            sepgp:RollCommand(false, false, 0)  -- SR roll, no DSR
        end
    elseif command == "ret sr" then
        -- Ret SR roll
        if sepgp and sepgp.RollCommand then
            sepgp:RollCommand(true, false, 0)  -- SR roll, no DSR
        end
    elseif command == "retcsr" then
        -- Use static popup dialog to input bonus
        StaticPopupDialogs["RET_SCR_INPUT"] = {
            text = "Enter number of weeks you SR this item:",
            button1 = TEXT(ACCEPT),
            button2 = TEXT(CANCEL),
            hasEditBox = 1,
            maxLetters = 5,
            OnAccept = function()
                -- Access the EditBox using getglobal as in your working example
                local editBox = getglobal(this:GetParent():GetName().."EditBox")
				local number = tonumber(editBox:GetText())
                if number then
                    -- Call the RollCommand with the entered bonus
					local bonus = calculateBonus(number)
                    sepgp:RollCommand(true, false, bonus)
                else
                    print("Invalid number entered.")
                end
            end,
            OnShow = function()
                -- Optionally, set default value for the EditBox if needed
                local editBox = getglobal(this:GetParent():GetName().."EditBox")
                getglobal(this:GetName().."EditBox"):SetText("")
				getglobal(this:GetName().."EditBox"):SetFocus()
            end,
            OnHide = function()
                -- Reset focus back to the chat input if needed
                if ChatFrameEditBox:IsVisible() then
                    ChatFrameEditBox:SetFocus()
                end
            end,
            EditBoxOnEnterPressed = function()
                -- Use the entered number for the command
				local editBox = getglobal(this:GetParent():GetName().."EditBox")
				local number = tonumber(editBox:GetText())
                if number then
                    local bonus = calculateBonus(number)
                    sepgp:RollCommand(true, false, bonus)
                else
                    print("Invalid number entered.")
                end
                this:GetParent():Hide()
            end,
            EditBoxOnEscapePressed = function()
                -- Hide the popup without performing any action
                this:GetParent():Hide()
            end,
            timeout = 0,
            exclusive = 1,
            whileDead = 1,
            hideOnEscape = 1,
        }
        -- Show the popup dialog
        StaticPopup_Show("RET_SCR_INPUT")
    end
end

-- Create a frame for the Roll button
local rollFrame = CreateFrame("Frame", "ShootyRollFrame", UIParent)
rollFrame:SetWidth(50)  -- Increased width for the frame
rollFrame:SetHeight(50)  -- Increased height for the frame
rollFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ShootyEPGP_RollPos.x, ShootyEPGP_RollPos.y)
if not sepgp_showRollWindow then
    rollFrame:Hide()
end
rollFrame:SetMovable(true)
rollFrame:EnableMouse(true)
rollFrame:RegisterForDrag("LeftButton")

-- Add a border to the frame so it's visible
rollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Background texture
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",  -- Border texture
    tile = true, tileSize = 32, edgeSize = 32, 
    insets = { left = 11, right = 11, top = 11, bottom = 11 }
})

-- Create the Roll button inside the frame
local rollButton = CreateFrame("Button", "ShootyRollButton", rollFrame, "UIPanelButtonTemplate")
rollButton:SetWidth(30)
rollButton:SetHeight(30)
rollButton:SetText("Roll")
rollButton:SetPoint("CENTER", rollFrame, "CENTER")  -- Center the button inside the frame

-- Create a container frame for the roll options
local rollOptionFrame = CreateFrame("Frame", "ShootyRollOptionFrame", UIParent)
rollOptionFrame:SetWidth(55)
rollOptionFrame:SetHeight(30)
rollOptionFrame:SetPoint("TOP", rollFrame, "BOTTOM", 0, -5)
rollOptionFrame:Hide()

-- Function to create roll option buttons
local function CreateRollButton(name, parent, command)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(50)
    button:SetHeight(25)
    button:SetText(name)
    button:SetScript("OnClick", function()
        ExecuteCommand(command)
    end)
    return button
end

-- Roll option buttons configuration
local options = {
    { "MS", "roll" },
    { "OS", "roll 99" },
    { "Tmog", "roll 50" },
    { "Ret roll", "ret roll" },
    { "Ret sr", "ret sr" },
    { "Retcsr", "retcsr" }
}

-- Create the roll option buttons
local previousButton
for i, option in ipairs(options) do
    local button = CreateRollButton(option[1], rollOptionFrame, option[2])
    if previousButton then
        button:SetPoint("TOP", previousButton, "BOTTOM", 0, -5)
    else
        button:SetPoint("TOP", rollOptionFrame, "TOP", 0, -5)
    end
    previousButton = button
end

-- Toggle roll options when main button is clicked
rollButton:SetScript("OnClick", function()
    if rollOptionFrame:IsShown() then
        rollOptionFrame:Hide()
    else
        rollOptionFrame:Show()
    end
end)

-- Fix for dragging functionality for the frame
rollFrame:SetScript("OnMouseDown", function(_, arg1)
    if arg1 == "LeftButton" then
        rollFrame:StartMoving()  -- Start moving the frame
    end
end)

rollFrame:SetScript("OnMouseUp", function(_, arg1)
    if arg1 == "LeftButton" then
        rollFrame:StopMovingOrSizing()  -- Stop moving the frame
        -- Save the position of the frame after dragging
        ShootyEPGP_RollPos.x = rollFrame:GetLeft()
        ShootyEPGP_RollPos.y = rollFrame:GetTop()
    end
end)

-- Ensure dragging works after frame creation
rollFrame:SetScript("OnDragStart", function()
    rollFrame:StartMoving()  -- Explicitly start moving the frame on drag
end)

rollFrame:SetScript("OnDragStop", function()
    rollFrame:StopMovingOrSizing()  -- Explicitly stop moving the frame
    -- Save the position of the frame after drag
    ShootyEPGP_RollPos.x = rollFrame:GetLeft()
    ShootyEPGP_RollPos.y = rollFrame:GetTop()
end)

-- Restore saved position on load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    -- Ensure the position is valid, fall back to default if necessary
    if ShootyEPGP_RollPos.x and ShootyEPGP_RollPos.y then
        rollFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ShootyEPGP_RollPos.x, ShootyEPGP_RollPos.y)
    else
        -- Default position if not available
        ShootyEPGP_RollPos = { x = 400, y = 300 }
        rollFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ShootyEPGP_RollPos.x, ShootyEPGP_RollPos.y)
    end
    if not sepgp_showRollWindow then
        rollFrame:Hide()
    end
end)
