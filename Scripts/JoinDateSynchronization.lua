local _, addon = ...
local Roster = addon.Roster
local JoinDateSynchronization = addon:NewObject("JoinDateSynchronization")

JoinDateSynchronization:RegisterLoadOnDemand("Blizzard_Communities", function()
    local parent = CommunitiesFrame
    local controlFrame = parent.CommunitiesControlFrame
    local logButton = controlFrame.GuildControlButton

    local syncDatesButton = CreateFrame("Button", nil, logButton, "UIPanelButtonNoTooltipTemplate")
    syncDatesButton:SetSize(130, 20)
    syncDatesButton:SetPoint("RIGHT", logButton, "LEFT", 0, 0)
    syncDatesButton:SetText("Sync Dates")
    
    syncDatesButton:SetScript("OnClick", function(self)
        if not C_GuildInfo.CanEditOfficerNote() then return end
        for _, member in Roster:GetMembers() do
            if member.joinDate and not member.hasOfficerNote then
                GuildRosterSetOfficerNote(member.index, member.joinDate)
            end
        end
    end)
end)