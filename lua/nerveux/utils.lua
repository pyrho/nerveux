local utils = {}
local l = require "nerveux.log"
local Job = require "plenary.job"

local DOUBLE_LINK_RE = "%[%[(%w+)|?([%g%s]-)%]%]#?"
local DOUBLE_LINK_RE_NOCAP = "%[%[[%g%s]-%]%]#?"

function utils.match_link(s) return s:match(DOUBLE_LINK_RE) end

--- Given a line, return a table with all links with metadata.
-- Returns a table containing all the IDs and they positions and if
-- they are folgezettels
-- @param line is a string
-- @return a table with all the zettels links contained in that line, containing
--         the start and end indices of the match, the zettel's ID and a boolean
--         indicating whether this is a folgezettel link.
--         If a link alias was present it will also be included.
function utils.get_all_link_indices(line)
  local function get_all_ids_from_line(line_)
    return line_:gmatch(DOUBLE_LINK_RE_NOCAP)
  end

  local matches = get_all_ids_from_line(line)
  local start = 1
  local indices = {}
  for match in matches do
    local start_ix, end_ix = line:find(match, start, true)
    local is_folgezettel = string.sub(line, end_ix, end_ix) == "#"

    local _, _, id, link_alias = match:find(DOUBLE_LINK_RE)
    if link_alias == nil or #link_alias == 0 then link_alias = nil end

    table.insert(indices, {start_ix, end_ix, id, is_folgezettel, link_alias})
    start = end_ix
  end

  return indices
end

function utils.find_link(s) return s:find(DOUBLE_LINK_RE) end

--- Stolen from https://github.com/blitmap/lua-snippets/blob/master/string-pad.lua
function utils.lpad(s, l, is_eol)
  local short_or_eq = #s <= l
  local ss = (is_eol or short_or_eq) and s or (string.sub(s, 0, l) .. "…")
  local res = string.rep(" ", l - #ss) .. s

  return res
end

--- Stolen from https://github.com/blitmap/lua-snippets/blob/master/string-pad.lua
function utils.pad(s, l, is_eol)
  local res1 = utils.rpad(s, (l / 2) + #s, is_eol) -- pad to half-length + the length of s
  local res2 = utils.lpad(res1, l, is_eol) -- right-pad our left-padded string to the full length

  return res2
end

--- Stolen from https://github.com/blitmap/lua-snippets/blob/master/string-pad.lua
function utils.rpad(s, l, is_eol)
  local short_or_eq = #s <= l
  local ss = (is_eol or short_or_eq) and s or (string.sub(s, 1, l - 1) .. "…")
  local res = ss .. string.rep(" ", l - #ss)

  return res
end

function utils.map(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do t[k] = f(v) end
  return t
end

utils.is_process_running = function(process_name, cb)
  local j = Job:new({command = "pgrep", args = {"-c", process_name}})
  j:start()
  j:after_failure(function() return cb(nil, false) end)
  j:after_success(
      function(_, ret_code) return cb(nil, tonumber(ret_code) == 0) end)
end

function utils.get_zettel_id_from_fname()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
end

return utils
