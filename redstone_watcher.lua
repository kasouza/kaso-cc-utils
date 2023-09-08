local events = require('events')

local M = {}

function M.watch(args)
    if args.modem ==  nil then
        error('invalid modem')
    end

    if type(args.sides) ~= 'table' then
        error('invalid sides')
    end

    args.event_name = args.event_name or 'redstone_changed'
    args.redstone_type = args.redstone_type or 'analog'
    args.sleep_time = args.sleep_time or 1
    args.dispatch_wait_time = args.dispatch_wait_time or 1

    if (args.sleep_time < 0) then
        error('invalid sleep time: ' .. args.sleep_time)
    end

    if (args.dispatch_wait_time < 0) then
        error('invalid dispatch wait time: ' .. args.dispatch_wait_time)
    end

    local getRedstoneState = nil
    
    if (args.redstone_type == 'digital') then
        getRedstoneState = rs.getInput

    elseif (args.redstone_type == 'analog') then
        getRedstoneState = rs.getAnalogInput

    else
        error('invalid redstone_type "' .. args.redstone_type .. '", valid type are: "digital", "analogic"')
    end

    events.config.dispatch_wait_time = args.dispatch_wait_time
    events.init(args.modem)

    local states = {}
    for _, side in ipairs(args.sides) do
        states[side] = getRedstoneState(side)
        events.dispatch(args.event_name, {
            side = side,
            state = states[side],
        })
    end

    while true do
        for _, side in ipairs(args.sides) do
            local new_state = getRedstoneState(side)
            if states[side] ~= new_state then
                states[side] = new_state
                events.dispatch(args.event_name, {
                    side = side,
                    state = states[side],
                })
            end
        end

        if (args.sleep_time > 0) then
            sleep(args.sleep_time)
        end
    end
end

return M
