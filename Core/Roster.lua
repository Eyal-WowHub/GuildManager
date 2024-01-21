local _, addon = ...
local Roster = addon:NewObject("Roster")
local Character = addon.Character

local GuildRoster = C_GuildInfo.GuildRoster
local GetNumGuildMembers = GetNumGuildMembers
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumGuildEvents = GetNumGuildEvents
local GetGuildEventInfo = GetGuildEventInfo

local CreateMember, GetMemberByName, GetMembers
do
    local members = {}

    function CreateMember(name)
        if name:find(Character:GetRealm(true)) then
            name = name:gsub("-%w+", "")
        end
        local member = members[name]
        if not member then
            members[name] = {}
            member = members[name]
        end
        return member
    end

    function GetMemberByName(name)
        return members[name]
    end

    function GetMembers()
        return pairs(members)
    end
end

local GetJoinDate
do
    local DAYS_PER_MONTH = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

    local function IsLeapYear(year)
        if (year % 4 == 0 and year % 100 ~= 0) or year % 400 == 0 then
            return true
        else
            return false
        end
    end

    local function GetCurrentDate()
        local calendarTime = C_DateAndTime.GetCurrentCalendarTime()
        local currentHour, currentMins = GetGameTime()
        return calendarTime.year, calendarTime.month, calendarTime.monthDay, calendarTime.weekday, currentHour, currentMins
    end

    local function AdjustDay(elaspedDay, currentDay, month, isLeapYear)
        local daysInMonth = DAYS_PER_MONTH[month]
        if isLeapYear and month == 2 then
            daysInMonth = daysInMonth + 1
        end
        return daysInMonth - (elaspedDay - currentDay)
    end

    local function AdjustMonthAndYear(month, year)
        month = month - 1
        if month == 0 then
            month = 12
            year = year - 1
        end
        return month, year
    end

    function GetJoinDate(elaspedYear, elaspedMonth, elaspedDay, elaspedHour)
        local year, month, day, _, hour = GetCurrentDate()
        
        local isLeapYear = IsLeapYear(year)
        local joinedYear = year - elaspedYear
        local joinedMonth = month - elaspedMonth
        local joinedDay = day - elaspedDay
        local joinedHour = hour - elaspedHour

        if joinedMonth <= 0 then
            joinedMonth = 12 - (elaspedMonth - month)
            joinedYear = joinedYear - 1
        end

        if joinedDay <= 0 then
            joinedDay = AdjustDay(elaspedDay, day, joinedMonth, isLeapYear)
            joinedMonth, joinedYear = AdjustMonthAndYear(joinedMonth, joinedYear)
        end

        if joinedHour <= 0 then
            joinedHour = 24 - (elaspedHour - hour)
            joinedDay = joinedDay - 1
            if joinedDay == 0 then
                joinedMonth, joinedYear = AdjustMonthAndYear(joinedMonth, joinedYear)
                joinedDay = AdjustDay(elaspedDay, day, joinedMonth, isLeapYear)
            end
        end

        return joinedYear, joinedMonth, joinedDay, joinedHour
    end
end

local function GuildUpdate()
    QueryGuildEventLog()
    GuildRoster()
end

Roster:RegisterEvent("PLAYER_LOGIN", GuildUpdate)
Roster:RegisterEvent("PLAYER_GUILD_UPDATE", GuildUpdate)
Roster:RegisterEvent("GUILD_ROSTER_UPDATE", function(event, canRequestGuildRosterUpdate)
    if canRequestGuildRosterUpdate then
        GuildUpdate()
    end
    for index = 1, GetNumGuildMembers() do
        local memberName, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(index)
        if memberName then
            local member = CreateMember(memberName)
            member.index = index
            member.name = memberName
            member.hasOfficerNote = officerNote ~= ""
        end
    end
    for index = GetNumGuildEvents(), 1, -1 do
        local type, memberName, _, _, elaspedYear, elaspedMonth, elaspedDay, elaspedHour = GetGuildEventInfo(index)
        if type == "join" and memberName then
            local member = GetMemberByName(memberName)
            if member then
                local year, month, day = GetJoinDate(elaspedYear, elaspedMonth, elaspedDay, elaspedHour)
                member.joinDate = format("%02d.%02d.%d", day, month, year)
            end
        end
    end
end)

Roster.GetMembers = GetMembers
