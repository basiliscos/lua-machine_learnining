#!/usr/bin/env lua

package.path = "src/?.lua;src/?/init.lua;t/?.lua;" .. package.path

require 'Test.More'
local inspect = require 'inspect'
local ml = require 'ml'
local ml_test = require 'MLTest'
local id3 = require 'ml/ID3'

subtest(
   "play tennis samples",
   function()
      local id3_instance = id3.new()
      local dataset = ml_test.get_datafile('t/data/play-tennis.data', 1.0)
      -- print(inspect(dataset))
      local class = dataset.attributes_count
      id3_instance:train(dataset.training.all, class)

      local first = dataset.training.all[1]
      -- print("sample: " .. inspect(first) .. " expected: " .. first[class])
      is(id3_instance:classify(first),
         first[class],
         "existing value is classified right"
      )
      is(id3_instance:classify({ 'sunny', 'hot', 'normal', 'strong' }),
         'yes',
         "unseen example is classified right"
      )
   end
)

subtest(
   "footbal samples",
   function()
      local id3_instance = id3.new()
      local dataset = ml_test.get_datafile('t/data/footbal.data', 1.0)
      -- print(inspect(dataset))
      local class = dataset.attributes_count
      id3_instance:train(dataset.training.all, class)

      local first = dataset.training.all[1]
      is(id3_instance:classify(first),
         first[class],
         "existing value is classified right"
      )
      is(id3_instance:classify({'b', 'guest', 'stay', 'y' }),
         'loose',
         "unseen example is classified right"
      )
   end
)

-- test samples cannot be used for ID3 because it operates only on
-- discrete values
subtest(
   "iris samples",
   function()
      local id3_instance = id3.new()
      local dataset = ml_test.get_datafile('t/data/iris.data', 1)
      -- print(inspect(dataset))
      local class = dataset.attributes_count
      id3_instance:train(dataset.training.all, class)

      local first = dataset.training.all[1]
      is(id3_instance:classify(first),
         first[class],
         "existing value is classified right"
      )
   end
)

done_testing(3)
