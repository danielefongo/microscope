-- Taken from https://github.com/swarn/fzy-lua

local SCORE_GAP_LEADING = -0.005
local SCORE_GAP_TRAILING = -0.005
local SCORE_GAP_INNER = -0.01
local SCORE_MATCH_CONSECUTIVE = 1.0
local SCORE_MATCH_SLASH = 0.9
local SCORE_MATCH_WORD = 0.8
local SCORE_MATCH_CAPITAL = 0.7
local SCORE_MATCH_DOT = 0.6
local SCORE_MAX = math.huge
local SCORE_MIN = -math.huge
local MATCH_MAX_LENGTH = 1024

local fzy = {}

local function is_lower(c)
  return c:match("%l")
end

local function is_upper(c)
  return c:match("%u")
end

local function precompute_bonus(haystack)
  local match_bonus = {}

  local last_char = "/"
  for i = 1, string.len(haystack) do
    local this_char = haystack:sub(i, i)
    if last_char == "/" or last_char == "\\" then
      match_bonus[i] = SCORE_MATCH_SLASH
    elseif last_char == "-" or last_char == "_" or last_char == " " then
      match_bonus[i] = SCORE_MATCH_WORD
    elseif last_char == "." then
      match_bonus[i] = SCORE_MATCH_DOT
    elseif is_lower(last_char) and is_upper(this_char) then
      match_bonus[i] = SCORE_MATCH_CAPITAL
    else
      match_bonus[i] = 0
    end

    last_char = this_char
  end

  return match_bonus
end

local function compute(needle, haystack, D, M, case_sensitive)
  local match_bonus = precompute_bonus(haystack)
  local n = string.len(needle)
  local m = string.len(haystack)

  if not case_sensitive then
    needle = string.lower(needle)
    haystack = string.lower(haystack)
  end

  local haystack_chars = {}
  for i = 1, m do
    haystack_chars[i] = haystack:sub(i, i)
  end

  for i = 1, n do
    D[i] = {}
    M[i] = {}

    local prev_score = SCORE_MIN
    local gap_score = i == n and SCORE_GAP_TRAILING or SCORE_GAP_INNER
    local needle_char = needle:sub(i, i)

    for j = 1, m do
      if needle_char == haystack_chars[j] then
        local score = SCORE_MIN
        if i == 1 then
          score = ((j - 1) * SCORE_GAP_LEADING) + match_bonus[j]
        elseif j > 1 then
          local a = M[i - 1][j - 1] + match_bonus[j]
          local b = D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE
          score = math.max(a, b)
        end
        D[i][j] = score
        prev_score = math.max(score, prev_score + gap_score)
        M[i][j] = prev_score
      else
        D[i][j] = SCORE_MIN
        prev_score = prev_score + gap_score
        M[i][j] = prev_score
      end
    end
  end
end

function fzy.positions(needle, haystack, case_sensitive)
  local n = string.len(needle)
  local m = string.len(haystack)

  if n == 0 or m == 0 or m > MATCH_MAX_LENGTH or n > m then
    return {}, SCORE_MIN
  elseif n == m then
    local consecutive = {}
    for i = 1, n do
      consecutive[i] = i
    end
    return consecutive, SCORE_MAX
  end

  local D = {}
  local M = {}
  compute(needle, haystack, D, M, case_sensitive)

  local positions = {}
  local match_required = false
  local j = m
  for i = n, 1, -1 do
    while j >= 1 do
      if D[i][j] ~= SCORE_MIN and (match_required or D[i][j] == M[i][j]) then
        match_required = (i ~= 1) and (j ~= 1) and (M[i][j] == D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE)
        positions[i] = j
        j = j - 1
        break
      else
        j = j - 1
      end
    end
  end

  return positions, M[n][m]
end

return fzy
