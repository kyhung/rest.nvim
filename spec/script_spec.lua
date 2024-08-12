---@module 'luassert'

require("spec.minimum_init")

local parser = require("rest-nvim.parser")
local utils = require("rest-nvim.utils")
-- local context = require("rest-nvim.context").Context
-- local logger = require("rest-nvim.logger")

describe("handler script", function ()
  it("alter response body", function ()
    local source = [[
http://localhost:8000

> {%
local json = vim.json.decode(response.body)
json.data = "overwritten"
response.body = vim.json.encode(json)
%}
]]
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    local req = assert(parser.parse(req_node, source))
    ---@type rest.Response
    ---@diagnostic disable-next-line: missing-fields
    local res = {
      body = [[{"data": "given"}]]
    }
    vim.iter(req.handlers):each(function (f) f(res) end)
    assert.same([[{"data":"overwritten"}]], res.body)
  end)
  it("update context from response body", function ()
    local source = [[
http://localhost:8000

> {%
local json = vim.json.decode(response.body)
client.global.set("MYVAR", json.var)
%}
]]
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    local req = assert(parser.parse(req_node, source))
    ---@type rest.Response
    ---@diagnostic disable-next-line: missing-fields
    local res = {
      body = [[{"var": "boo"}]]
    }
    vim.iter(req.handlers):each(function (f) f(res) end)
    assert.same("boo", req.context:resolve("MYVAR"))
  end)
end)