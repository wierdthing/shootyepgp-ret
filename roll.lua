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
        if sepgp and sepgp.RollCommand then
            sepgp:RollCommand(false, false, 0)
        end
    elseif command == "ret sr" then
        if sepgp and sepgp.RollCommand then
            sepgp:RollCommand(true, false, 0)
        end
    elseif command == "shooty show" then
        sepgp_standings:Toggle()
    end
end

-- Create a frame for the Roll and Standings buttons
local rollFrame = CreateFrame("Frame", "ShootyRollFrame", UIParent)
rollFrame:SetWidth(80)
rollFrame:SetHeight(70)
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

-- Create the Standings button inside the frame
local standingsButton = CreateFrame("Button", "ShootyStandingsButton", rollFrame, "UIPanelButtonTemplate")
standingsButton:SetWidth(60)
standingsButton:SetHeight(25)
standingsButton:SetText("Standings")
standingsButton:SetPoint("TOP", rollFrame, "TOP", 0, -5)
standingsButton:SetScript("OnClick", function()
    ExecuteCommand("shooty show")
end)

-- Create the Roll button inside the frame
local rollButton = CreateFrame("Button", "ShootyRollButton", rollFrame, "UIPanelButtonTemplate")
rollButton:SetWidth(60)
rollButton:SetHeight(25)
rollButton:SetText("Roll")
rollButton:SetPoint("TOP", standingsButton, "BOTTOM", 0, -5)

-- Container for roll buttons, initially hidden
local rollOptionsFrame = CreateFrame("Frame", "RollOptionsFrame", rollFrame)
rollOptionsFrame:SetPoint("TOP", rollButton, "BOTTOM", 0, -2)
rollOptionsFrame:SetWidth(60)
rollOptionsFrame:SetHeight(25)
rollOptionsFrame:Hide()

-- Function to create roll option buttons
local function CreateRollButton(name, parent, command, anchor)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(60)
    button:SetHeight(20)
    button:SetText(name)
    button:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
    button:SetScript("OnClick", function()
        ExecuteCommand(command)
        rollOptionsFrame:Hide()
    end)
    return button
end

-- Roll option buttons configuration
local options = {
    { "MS", "roll" },
    { "OS", "roll 99" },
    { "Tmog", "roll 50" },
    { "Ret roll", "ret roll" },
    { "Ret sr", "ret sr" }
}

-- Create roll buttons dynamically
local previousButton = rollOptionsFrame
for _, option in ipairs(options) do
    previousButton = CreateRollButton(option[1], rollOptionsFrame, option[2], previousButton)
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
