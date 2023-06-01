local uv = vim.loop

local command = {}

local function split_last_newline(text)
  local idx = text:reverse():find("\n")
  if idx == nil or idx == 1 then
    return text, ""
  end
  return text:sub(1, -idx), text:sub(1 - idx)
end

local function shell(opts, input_stream)
  local cmd = opts.cmd
  local args = opts.args or {}
  local cwd = opts.cwd

  local output = ""
  local output_stream = uv.new_pipe(false)
  local handle

  local function close()
    output_stream:read_stop()
    output_stream:close()
    handle:close()
    handle:kill(vim.loop.constants.SIGTERM)
    if input_stream then
      input_stream:read_stop()
      input_stream:close()
    end
  end

  handle = uv.spawn(cmd, { args = args, stdio = { input_stream, output_stream, nil }, cwd = cwd }, close)
  uv.read_start(output_stream, function(_, data)
    if data then
      output = output .. data
    end
  end)

  local function iterator()
    if handle and handle:is_active() and not output:find("\n") then
      return ""
    end

    local result
    if handle and handle:is_active() or output ~= "" then
      result, output = split_last_newline(output)
      return result
    end
  end

  return iterator, close
end

local function consume_shell(flow, opts)
  local stdin = nil
  if flow.can_read() then
    stdin = uv.new_pipe(false)
  end

  local iterator, close = shell(opts, stdin)

  local finished = false

  local function read_shell_output()
    if flow.stopped() then
      pcall(close)
    end
    if flow.can_read() and not finished then
      local data = flow.read()
      if data == nil then
        stdin:read_stop()
        stdin:shutdown()
        finished = true
      elseif type(data) == "string" then
        stdin:write(data)
      end
    end

    return iterator()
  end

  return function()
    local output = read_shell_output()
    while output == "" and not flow.stopped() do
      flow.write(output)
      output = read_shell_output()
    end
    return output
  end
end

function command.spawn(flow, opts)
  for output in consume_shell(flow, opts) do
    flow.write(output)
  end
end

function command.command(flow, opts)
  local outputs = {}
  for output in consume_shell(flow, opts) do
    for value in vim.gsplit(output, "\n") do
      table.insert(outputs, value)
    end
  end
  return outputs
end

return command
