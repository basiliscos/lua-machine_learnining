local inspect = require 'inspect'
local _ = require ("moses")

local id3 = {}
id3.__index = id3

function id3.new()
   local o = { root = nil, target_class = nil }
   setmetatable(o, id3)
   return o
end

function id3:train(all_samples, attributes_count)

   local target_class = attributes_count
   
   local find_best_attribute = function(samples,  misc_attributes)

      -- gather uniq values stats (value/count) for attribute
      local get_uniq_values = function(samples, attribute)
         local uniq_values = {}
         _.each(samples,
                function(k,v)
                   local value = v[attribute]
                   local instances = uniq_values[value] or 0
                   instances = instances + 1
                   uniq_values[value] = instances
                end
         )
         -- print("uniq_values for att." .. attribute .. " : " ..  inspect(uniq_values) .. ", samples count = " .. #samples)
         return uniq_values
      end
      
      local entropy = function(samples)
         local uniq_values = get_uniq_values(samples, target_class)
         local entropy_value = _.reduce(
            _.values(uniq_values),
            function(state, value)
               local frequency = value / #samples
               -- log(1,1) is nan
               -- local log_value = (value == #samples) and -1 or math.log(frequency, 1/frequency)
               local log_value = math.log(frequency)
               local result = state + frequency * log_value
               -- print("result = " .. result .. " freq = " .. frequency .. " log = " .. log_value .. ", " .. #samples)
               return result
            end,
            0
         )
         entropy_value = -1 * entropy_value
         return entropy_value
      end

      local total_entropy = entropy(samples)
      -- print("total entropy = " .. total_entropy)

      local attributes_entropy = _.map(
         misc_attributes,
         function(attribute_idx, attribute)
            local uniq_values = get_uniq_values(samples, attribute)
            local attibute_entropy = _.reduce(
               _.keys(uniq_values),
               function(state, value)
                  local value_samples = _.select(samples, function(k, v) return v[attribute] == value end)
                  local value_entropy = entropy(value_samples, attribute);
                  local shifted_entropy = value_entropy * #value_samples / #samples
                  -- local split_info = 
                  -- print("att." .. attribute .. "/" .. value .. " entropy: " .. shifted_entropy)
                  return state + shifted_entropy
               end,
               0
            )
            -- print("att." .. attribute .. " entropy: " .. attibute_entropy)
            return attibute_entropy
         end
      )
      -- print("attributes entropy: " .. inspect(attributes_entropy))
      local attributes_gain = _.map(attributes_entropy, function(k, v) return total_entropy - v end)
      -- print("information gain: " .. inspect(attributes_gain))

      local max = attributes_gain[1]
      local max_idx = 1
      for idx, value in pairs(attributes_gain) do
         if (max < value) then
            max_idx, max = idx, value
         end
      end

      local best_attr = misc_attributes[max_idx]
      -- print("best att." .. best_attr .. ", idx: " .. max_idx)
      return max_idx, best_attr
   end

   local build_root
   build_root = function(samples, misc_attributes)
      print("samples: " ..inspect(samples))
      print("misc_attributes: " ..inspect(misc_attributes))

      local first_class = samples[1][target_class] 
      local all_the_same = _.all(samples, function(k, v) return v[target_class] == first_class end)
      print("the same examples: " .. (all_the_same and 'y' or 'n'))
      
      local frequences = {}
      _.each(
         samples,
         function(k, v)
            local freq = frequences[v] or 0
            frequences[v] = freq + 1
         end
      )

      local root_node 
      local generate_leaf_node = function(result)
         print("generaing leaf node with result " .. result)
         root_node = {
            type = 'leaf',
            result = result,
         }
      end

      if (all_the_same) then generate_leaf_node(first_class)
      elseif (#misc_attributes == 0) then
         local max_class, max = -1, -1
         for k, v in pairs(frequences) do
            if v > max then
               max_class = k
               max = v
            end
         end
         generate_leaf_node(max_class)
      else
         local divisor_idx, divisor = find_best_attribute(samples, misc_attributes)
         table.remove(misc_attributes, divisor_idx)
         local divisor_values = _.unique(_.map(samples, function (k, v) return v[divisor] end))
         print("divisor = " .. divisor .. ", values = " .. inspect(divisor_values))
         local branches = {}
         for k, value in pairs(divisor_values) do
            local matched_samples = _.select(samples, function(k, v) return v[divisor] == value end)
            print("value = " .. value .. ", samples = " .. #matched_samples)
            -- print("matched samples: " .. inspect(matched_samples))
            local sub_node = build_root(matched_samples, _.clone(misc_attributes))
            table.insert(branches, { value = value, node = sub_node})
         end
         --print(inspect(branches))
         assert(#branches >= 2)
         root_node = {
            type = 'branch',
            divisor = divisor,
            branches = branches,
         }
      end

      assert(root_node)
      return root_node
   end

   local misc_attributes = _.range(1, target_class - 1)
   local tree = build_root(all_samples, misc_attributes)
   self.root = tree
   self.target_class = target_class
   print(inspect(tree))
end

function id3:classify(item)
   assert(self.root)
   assert(self.target_class)
   
   local visit
   visit = function(node)
      if (node.type == 'leaf') then
         return node.result
      else
         -- branch
         local divisor_value = item[node.divisor]
         -- print("examining node " .. inspect(node.branches))
         for k, branch in pairs(node.branches) do
            if (branch.value == divisor_value) then
               return visit(branch.node)
            end
         end
         error("unknown case")
      end
   end
   return visit(self.root)
end

return id3
