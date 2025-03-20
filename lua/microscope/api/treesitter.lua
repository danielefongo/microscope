local treesitter = {}

local function to_human_node(range)
  return {
    row = range[1] + 1,
    col = range[2] + 1,
    end_row = range[3] + 1,
    end_col = range[4] + 1,
  }
end

local function get_highlights(parser, from, lang)
  local hls = {}

  parser:parse(true)
  parser:for_each_tree(function(tstree, tree)
    local query = vim.treesitter.query.get(tree:lang(), "highlights")
    if not query then
      return
    end

    for capture, node, metadata in query:iter_captures(tstree:root(), from) do
      local name = query.captures[capture]
      local range = to_human_node({ node:range() })

      local node_text = vim.split(vim.treesitter.get_node_text(node, from, metadata[capture]), "\n", { plain = true })

      for i = 0, range.end_row - range.row do
        local node_from, node_to

        local is_first = (i == 0)
        local is_last = (i == range.end_row - range.row)

        if is_first then
          node_from = range.col
        else
          node_from = 1
        end

        if is_last then
          node_to = range.end_col - 1
        else
          node_to = (#node_text[i + 1] or 0) + (is_first and node_from or 0)
        end

        local row = range.row + i
        hls[row] = hls[row] or {}
        table.insert(hls[row], {
          from = node_from,
          to = node_to,
          color = "@" .. name .. "." .. lang,
        })
      end
    end
  end)

  return hls
end

function treesitter.for_buffer(buf, lang)
  if not lang then
    return {}
  end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok then
    return {}
  end

  return get_highlights(parser, buf, lang)
end

function treesitter.for_text(text, lang)
  if not lang then
    return {}
  end

  local ok, parser = pcall(vim.treesitter.get_string_parser, text, lang)
  if not ok then
    return {}
  end

  return get_highlights(parser, text, lang)
end

return treesitter
