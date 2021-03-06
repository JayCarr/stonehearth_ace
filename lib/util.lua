local util = {}

-- Taken from https://web.archive.org/web/20131225070434/http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3
function util.deep_compare(t1, t2, ignore_mt)
   local ty1 = type(t1)
   local ty2 = type(t2)
   if ty1 ~= ty2 then return false end
   -- non-table types can be directly compared
   if ty1 ~= 'table' then return t1 == t2 end
   -- as well as tables which have the metamethod __eq
   if not ignore_mt then
      local mt = getmetatable(t1)
      if mt and mt.__eq then return t1 == t2 end
   end
   for k1, v1 in pairs(t1) do
      local v2 = t2[k1]
      if v2 == nil or not util.deep_compare(v1, v2, ignore_mt) then return false end
   end
   for k2, v2 in pairs(t2) do
      local v1 = t1[k2]
      if v1 == nil or not util.deep_compare(v1, v2, ignore_mt) then return false end
   end
   return true
end

function util.itable_append(t1, t2)
   for _, v in pairs(t2) do
      t1[#t1+1] = v
   end
   return t1
end

-- used for seeing if two sequences share all the same values
function util.sequence_equals(t1, t2)
   if #t1 ~= #t2 then
      return false
   end

   for i = 1, #t1 do
      if t1[i] ~= t2[i] then
         return false
      end
   end

   return true
end

function util.sum_where_all_keys_present(key_maps, values, keys)
   if type(keys) == 'string' then
      keys = radiant.util.split_string(keys, ' ')
   end

   local total_value = 0

   for match_key, key_map in pairs(key_maps) do
      local match = true
      for _, key in ipairs(keys) do
         if not key_map[key] then
            match = false
            break
         end
      end
      if match then
         total_value = total_value + values[match_key]
      end
   end

   return total_value
end

return util
