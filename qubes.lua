
local pcoreLoad = 0
local ecoreLoad = 0

local gpuVmName = ""

local totalMemory = ""
local freeMemory = ""

local vmCount = 0
local pCoreVcpus = 0
local eCoreVcpus = 0

local cpuTemp = ""
local fanSpeed = ""

function conky_Main()
    GetCoreLoad()
    GetGpuVmName()
    GetMemoryInfo()
    GetVmInfo()
    GetTempInfo()
    return "";
end

function conky_GetPCoreLoad()
    if pcoreLoad < 10 then
        return " " .. tostring(pcoreLoad);
    end
    return tostring(pcoreLoad);
end

function conky_GetECoreLoad()
    if ecoreLoad < 10 then
        return " " .. tostring(ecoreLoad);
    end
    return tostring(ecoreLoad);
end

function conky_GetPCoreVcpus()
    return pCoreVcpus
end

function conky_GetECoreVcpus()
    return eCoreVcpus
end

function conky_GetFreeMemory()
    local memInt = tonumber(freeMemory)
    if memInt < 10000 then
        return "   " .. freeMemory
    elseif memInt < 100000 then
        return "  " .. freeMemory
    else 
        return " " .. freeMemory
    end
end

function conky_GetTotalMemory()
    return totalMemory
end

function conky_GetVmCount()
    return vmCount
end

function conky_GetFanSpeed()
    return fanSpeed
end

function conky_GetCpuTemp()
    return cpuTemp
end

function conky_GetGpuVmName()
    if gpuVmName == nil or gpuVmName == "" then
        return "none"
    end

    return gpuVmName
end

function GetCoreLoad()

    local output = RunCommand("xenpm start 1 | grep -e P0")

    local idx = 1
    pcoreLoad = 0
    ecoreLoad = 0
    for line in output:gmatch("[^\r\n]+") do
        if(line ~= nil) then
            local elements = SplitString(line, "[^%s]+")
            if elements[2] ~= nil then
                if idx < 17 then
                    pcoreLoad = pcoreLoad + tonumber(elements[2])
                else
                    ecoreLoad = ecoreLoad + tonumber(elements[2])
                end
                idx = idx + 1
            end
        end
    end

    pcoreLoad = math.ceil(pcoreLoad / 160)
    ecoreLoad = math.ceil(ecoreLoad / 160)

end

function GetGpuVmName()

    local output = RunCommand("qvm-ls --no-spinner --fields name,state --tags gpuvm | grep Running | awk '{print $1}'")
    gpuVmName = output:gsub("%s+", "")

end

function GetMemoryInfo()

    local lines = GetLines("xl info | grep -e total_memory -e free_memory");
    totalMemory = SplitString(lines[1], "[^%s]+")[3]
    freeMemory = SplitString(lines[2], "[^%s]+")[3]

end

function GetVmInfo()

    local output = RunCommand("xl vcpu-list")

    vmCount = 0
    pCoreVcpus = 0
    eCoreVcpus = 0
    local domains = {}
    for line in output:gmatch("[^\r\n]+") do
        vmCount = vmCount +1;

        local elements = SplitString(line, "[^%s]+")
        
        if elements[4] ~= nil then
            local value = tonumber(elements[4])
            if value ~= nil then
                if value < 16 then
                    pCoreVcpus = pCoreVcpus + 1
                else
                    eCoreVcpus = eCoreVcpus + 1
                end
            end
        end
        
        if elements[1] ~= nil and not Contains(domains, elements[1]) then
                table.insert(domains, elements[1])
        end
        
    end
    vmCount = #domains -1;

end

function GetTempInfo()

    local lines = GetLines("sensors | grep -e 'PECI 0.0' -e fan1:");
    fanSpeed = SplitString(lines[1], "[^%s]+")[2]
    cpuTemp = SplitString(lines[2], "[^%s]+")[3]

end

function Contains(table, val)

    for i=1,#table do
        if table[i] == val then 
            return true
        end
    end

    return false

 end

function RunCommand(command)

    local cmd = io.popen(command)
    if cmd == nil then
        return ""
    end

    local output = cmd:read("*a")
    cmd:close();

    return output

end

function GetLines(command)
    local lines = {}
    local output = RunCommand(command)
    for line in output:gmatch("[^\r\n]+") do
        if(line ~= nil) then
            table.insert(lines, line)
        end
    end

    return lines

end

function SplitString(string, pattern)

    local elements = {}
    for e in string:gmatch(pattern) do
        if e ~= nil and e ~= "" then
            local value = e:gsub("%s+", "")
            table.insert(elements, value)
        end
    end

    return elements;

end

