-- Ensure ShootyEPGP_RollPos is initialized with default values
ShootyEPGP_RollPos = ShootyEPGP_RollPos or { x = 400, y = 300 }
sepgp_showRollWindow = true

-- Function to execute commands
local function ExecuteCommand(command)
    if command == "roll" then
        RandomRoll(1, 100)
    elseif command == "roll 99" then
        RandomRoll(1, 99)
	elseif command == "roll 101" then
        RandomRoll(1, 101)
    elseif command == "roll 50" then
        RandomRoll(1, 50)
    elseif command == "ret roll" then
        if sepgp and sepgp.RollCommand then
            sepgp:RollCommand(false, false, 0)
        end
    elseif command == "ret sr" then
        if sepgp and sepgp.RollCommand then
            sepgp:RollCommand(true, false, 0)
        end
    elseif command == "retcsr" then
        -- Use static popup dialog to input bonus
        StaticPopupDialogs["RET_CSR_INPUT"] = {
            text = "Enter number of weeks you SR this item:",
            button1 = TEXT(ACCEPT),
            button2 = TEXT(CANCEL),
            hasEditBox = 1,
            maxLetters = 5,
            OnAccept = function()
                local editBox = getglobal(this:GetParent():GetName().."EditBox")
                local number = tonumber(editBox:GetText())
                if number then
                    local bonus = calculateBonus(number)
                    sepgp:RollCommand(true, false, bonus)
                else
                    print("Invalid number entered.")
                end
            end,
            OnShow = function()
                local editBox = getglobal(this:GetParent():GetName().."EditBox")
                getglobal(this:GetName().."EditBox"):SetText("")
                getglobal(this:GetName().."EditBox"):SetFocus()
            end,
            OnHide = function()
                if ChatFrameEditBox:IsVisible() then
                    ChatFrameEditBox:SetFocus()
                end
            end,
            EditBoxOnEnterPressed = function()
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
                this:GetParent():Hide()
            end,
            timeout = 0,
            exclusive = 1,
            whileDead = 1,
            hideOnEscape = 1,
        }
        StaticPopup_Show("RET_CSR_INPUT")
    elseif command == "shooty show" then
        sepgp_standings:Toggle()
    end
end

-- Create a frame for the Roll button
local rollFrame = CreateFrame("Frame", "ShootyRollFrame", UIParent)
rollFrame:SetWidth(80)
rollFrame:SetHeight(40)
rollFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ShootyEPGP_RollPos.x, ShootyEPGP_RollPos.y)
if not sepgp_showRollWindow then
    rollFrame:Hide()
end
rollFrame:SetMovable(true)
rollFrame:EnableMouse(true)
rollFrame:RegisterForDrag("LeftButton")

-- Add a border to the frame so it's visible
rollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

-- Create the Roll button inside the frame
local rollButton = CreateFrame("Button", "ShootyRollButton", rollFrame, "UIPanelButtonTemplate")
rollButton:SetWidth(70)
rollButton:SetHeight(30)
rollButton:SetText("Roll")
rollButton:SetPoint("CENTER", rollFrame, "CENTER")

-- Container for roll buttons, initially hidden
local rollOptionsFrame = CreateFrame("Frame", "RollOptionsFrame", rollFrame)
rollOptionsFrame:SetPoint("TOP", rollButton, "BOTTOM", 0, -2)
rollOptionsFrame:SetWidth(70)
rollOptionsFrame:SetHeight(30)
rollOptionsFrame:Hide()

-- Function to create roll option buttons
local function CreateRollButton(name, parent, command, anchor)
    local buttonFrame = CreateFrame("Frame", nil, parent)
    buttonFrame:SetWidth(70)
    buttonFrame:SetHeight(30)
    buttonFrame:SetPoint("TOP", anchor, "BOTTOM", 0, -2)

    buttonFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    local button = CreateFrame("Button", nil, buttonFrame, "UIPanelButtonTemplate")
    button:SetWidth(60)
    button:SetHeight(20)
    button:SetText(name)
    button:SetPoint("CENTER", buttonFrame, "CENTER")

    button:SetScript("OnClick", function()
        ExecuteCommand(command)
        -- Only hide if the command isn't "shooty show"
        if command ~= "shooty show" then
            rollOptionsFrame:Hide()
        end
    end)

    return buttonFrame
end

-- Roll option buttons configuration
local options = {
    { "MS", "roll" },
    { "OS", "roll 99" },
    { "SR", "roll 101" },
    { "Tmog", "roll 50" },
    { "Ret roll", "ret roll" },
    { "Ret sr", "ret sr" },
    { "Ret CSR", "retcsr" },
    { "Standings", "shooty show" }
}

-- Create roll buttons dynamically with closer spacing
local previousButton = rollOptionsFrame
for _, option in ipairs(options) do
    local buttonFrame = CreateRollButton(option[1], rollOptionsFrame, option[2], previousButton)

    if previousButton == rollOptionsFrame then
        -- For the first button, set it relative to the rollOptionsFrame
        buttonFrame:SetPoint("TOP", rollOptionsFrame, "TOP", 0, 0)  -- Align with the top of the options frame
    else
        -- For subsequent buttons, set their position based on the previous button
        buttonFrame:SetPoint("TOP", previousButton, "BOTTOM", 0, 5)  -- Close spacing
    end

    previousButton = buttonFrame  -- Update previousButton to the current buttonFrame for the next iteration
end

-- Toggle roll buttons on Roll button click
rollButton:SetScript("OnClick", function()
    if rollOptionsFrame:IsShown() then
        rollOptionsFrame:Hide()
    else
        rollOptionsFrame:Show()
    end
end)

-- Fix for dragging functionality for the frame
rollFrame:SetScript("OnMouseDown", function(_, arg1)
    if arg1 == "LeftButton" then
        rollFrame:StartMoving()
    end
end)

rollFrame:SetScript("OnMouseUp", function(_, arg1)
    if arg1 == "LeftButton" then
        rollFrame:StopMovingOrSizing()
        ShootyEPGP_RollPos.x = rollFrame:GetLeft()
        ShootyEPGP_RollPos.y = rollFrame:GetTop()
    end
end)

rollFrame:SetScript("OnDragStart", function()
    rollFrame:StartMoving()
end)

rollFrame:SetScript("OnDragStop", function()
    rollFrame:StopMovingOrSizing()
    ShootyEPGP_RollPos.x = rollFrame:GetLeft()
    ShootyEPGP_RollPos.y = rollFrame:GetTop()
end)

-- Restore saved position on load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    if ShootyEPGP_RollPos.x and ShootyEPGP_RollPos.y then
        rollFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ShootyEPGP_RollPos.x, ShootyEPGP_RollPos.y)
    else
        ShootyEPGP_RollPos = { x = 400, y = 300 }
        rollFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ShootyEPGP_RollPos.x, ShootyEPGP_RollPos.y)
    end
    if not sepgp_showRollWindow then
        rollFrame:Hide()
    end
end)
