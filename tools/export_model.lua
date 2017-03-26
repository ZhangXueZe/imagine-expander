
require 'pl'
local __FILE__ = (function() return string.gsub(debug.getinfo(2, 'S').source, "^@", "") end)()
package.path = path.join(path.dirname(__FILE__), "..", "lib", "?.lua;") .. package.path
require 'w2nn'
local cjson = require "cjson"

local function meta_data(model)
   local meta = {}
   for k, v in pairs(model) do
      if k:match("w2nn_") then
	 meta[k:gsub("w2nn_", "")] = v
      end
   end
   return meta
end
local function includes(s, a)
   for i = 1, #a do
      if s == a[i] then
	 return true
      end
   end
   return false
end

local function get_bias(mod)
   if mod.bias then
      return mod.bias:float()
   else
      -- no bias
      return torch.FloatTensor(mod.nOutputPlane):zero()
   end
end
local function export(model, output)
   local targets = {"nn.SpatialConvolutionMM",
		    "cudnn.SpatialConvolution",
		    "nn.SpatialFullConvolution",
		    "cudnn.SpatialFullConvolution"
   }
   local jmodules = {}
   local model_config = meta_data(model)
   local first_layer = true

   for k = 1, #model.modules do
      local mod = model.modules[k]
      local name = torch.typename(mod)
      if includes(name, targets) then
	 local weight = mod.weight:float()
	 if name:match("FullConvolution") then
	    weight = torch.totable(weight:reshape(mod.nInputPlane, mod.nOutputPlane, mod.kH, mod.kW))
	 else
	    weight = torch.totable(weight:reshape(mod.nOutputPlane, mod.nInputPlane, mod.kH, mod.kW))
	 end
	 local jmod = {
	    class_name = name,
	    kW = mod.kW,
	    kH = mod.kH,
	    dH = mod.dH,
	    dW = mod.dW,
	    padW = mod.padW,
	    padH = mod.padH,
	    nInputPlane = mod.nInputPlane,
	    nOutputPlane = mod.nOutputPlane,
	    bias = torch.totable(get_bias(mod)),
	    weight = weight
	 }
	 if first_layer then
	    first_layer = false
	    jmod.model_config = model_config
	 end
	 table.insert(jmodules, jmod)
      end
   end
   local fp = io.open(output, "w")
   if not fp then
      error("IO Error: " .. output)
   end
   fp:write(cjson.encode(jmodules))
   fp:close()
end

local cmd = torch.CmdLine()
cmd:text()
cmd:text("waifu2x export model")
cmd:text("Options:")
cmd:option("-i", "input.t7", 'Specify the input torch model')
cmd:option("-o", "output.json", 'Specify the output json file')
cmd:option("-iformat", "ascii", 'Specify the input format (ascii|binary)')

local opt = cmd:parse(arg)
if not path.isfile(opt.i) then
   cmd:help()
   os.exit(-1)
end
local model = torch.load(opt.i, opt.iformat)
export(model, opt.o)
