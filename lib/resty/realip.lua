-- Copyright (C) vislee

local ffi = require 'ffi'
local base = require("resty.core.base")
base.allows_subsystem('http')

local C = ffi.C
local ffi_new = ffi.new
local ffi_str = ffi.string


local _M = {}
_M.version = "0.01"

ffi.cdef[[
    int ngx_http_lua_ffi_realip_set_addr(ngx_http_request_t *r,
        const char *ip, size_t len, char **errmsg);
]]


local get_request
do
    local ok, exdata = pcall(require, "thread.exdata")
    if ok and exdata then
        function get_request()
            local r = exdata()
            if r ~= nil then
                return r
            end
        end

    else
        local getfenv = getfenv

        function get_request()
            return getfenv(0).__ngx_req
        end
    end
end


local function _get_errmsg_ptr()
    local errmsg = ffi_new("char *[1]")
    return errmsg
end
local errmsg = _get_errmsg_ptr()

local function realip_set_addr(addr)
    local r = get_request()
    if not r then
        error("no request found")
    end

    local rc
    rc = C.ngx_http_lua_ffi_realip_set_addr(r, addr, #addr, errmsg)

    if rc == 0 then
        return
    end

    error(ffi_str(errmsg[0]), 2)
end

_M.set_addr = realip_set_addr


return _M
