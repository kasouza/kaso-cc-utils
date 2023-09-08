local M = {}
local events = {}
local is_running = false
local _modem = nil

M.config = {
    dispatch_wait_time = 5
}

local event_queue = {}

function handle_event(sender_id, event_name)
    if (events[event_name] == nil) then
        return
    end

    print('    Requesting message...')
    rednet.send(sender_id, 'get_message')
    
    print('    Waiting for message to arrive...')

    local response_id, message
    repeat
        response_id, message = rednet.receive()
    until response_id == sender_id
    
    print('    Calling callbacks')
    for k, cb in ipairs(events[event_name]) do
        cb({
            sender_id = sender_id;
            message = message
        })
    end
end

function add_to_event_queue(sender_id, event_name)
    table.insert(event_queue, {
        sender_id = sender_id;
        name = event_name
    })
end

function work_event_queue()
    for _, event in ipairs(event_queue) do
        handle_event(event.sender_id, event.name)
    end
    event_queue = {}
end

function M.add_event_listener(event_name, callback)
    if (events[event_name] == nil) then
        events[event_name] = {}
    end
    
    table.insert(events[event_name], callback)
end

function M.dispatch(event_name, message)
    if (_modem == nil) then
        error('event.lua not initialized')
    end

    print('<dispatch_' .. event_name .. '>')
    rednet.broadcast(event_name)
    print('    Broadcasting...')
    
    while true do    
        local id, listener_message
    
        print('    Waiting for listener\'s message...')
    
        repeat
            id, listener_message = rednet.receive(nil, M.config.dispatch_wait_time)
            if (id == nil) then
                print('</dispatch_' .. event_name  .. '>')
                return
            end
            
            local is_get_message = listener_message == 'get_message'
            if (not is_get_message) then
                handle_event(id, listener_message)
            end
        until listener_message == 'get_message'
        
        rednet.send(id, message)
        print('    Message for event"' .. event_name .. '" sent')
    end
end 

function M.init(modem)
    _modem = modem
    rednet.open(_modem)
end

function M.terminate()
    rednet.close(_modem)
end

function M.listen(modem)
    if (_modem == nil) then
        error('events.lua not initialized')
    end

    print('<listen>')
    is_running = true
    
    while is_running do
        print('    Listening for event...')
        local id, event_name = rednet.receive()
        handle_event(id, event_name)
    end
    
    print('</listen>')
end

function M.stop()
    is_running = false 
end

return M
