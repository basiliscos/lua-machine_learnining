local inspect = require 'inspect'
local _ = require ("moses")

local ml_test = {}
ml_test.__index = ml_test

local _read_dataset = function(datafile, training_share)
   local samples_file = assert(io.open(datafile, 'r'))
   -- get all classes
   local classes = {}
   local dataline
   for line in samples_file:lines() do
      -- print(line)
      dataline = {}
      for m in string.gmatch(line, "([%w.-]+),?") do
         -- print("found " .. m)
         table.insert(dataline, m)
      end
      if (#dataline > 2) then
         local class = dataline[#dataline]
         local samples = classes[class] or {}
         table.insert(samples, dataline)
         classes[class] = samples;
      end
   end

   local dataset = {
      attributes_count = #dataline,
      training = { groupped = {}, all = {} },
      test = { groupped = {}, all = {}},
   }
   -- divide classes to training and test samples
   for class, samples in pairs(classes) do
      local test_samples = {}
      for idx = 1, ((1-training_share)*#samples) do
         local sample = table.remove(samples)
         table.insert(test_samples, sample)
      end
      dataset.training.groupped[class] = samples
      _.push(dataset.training.all, table.unpack(_.map(samples, function(k, v) return v end)))
      dataset.test.groupped[class] = test_samples
      _.push(dataset.test.all, table.unpack(_.map(test_samples, function(k, v) return v end)))
   end

   -- print(inspect(dataset))
   return dataset
end

ml_test.get_datafile = function(datafile, training_share)
   return _read_dataset(datafile, training_share)
end

ml_test.classify = function(datafile, algorithm)
   local dataset = _read_dataset(datafile)
   print(inspect(dataset))
   local first_sample = dataset.training.all[1]
   local attributes_count = #first_sample
   print("attributes count: " .. attributes_count)
   algorithm:train(dataset.training.all, attributes_count)
end

return ml_test
