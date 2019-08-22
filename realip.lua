-- Copyright (C) vislee

local ffi = require 'ffi'
local C = ffi.C
local ffi_new = ffi.new
local ffi_str = ffi.string

local _M = {}
_M.version = "0.01"

ffi.cdef[[
    int ngx_http_lua_ffi_realip_set_addr(ngx_http_request_t *r,
        const char *ip, size_t len, char **errmsg);
]]

local function _get_request()
    return getfenv(0).__ngx_req
end

local function _get_errmsg_ptr()
    local errmsg = ffi_new("char *[1]")
    return errmsg
end
local errmsg = _get_errmsg_ptr()

local function realip_set_addr(addr)
    local r = _get_request()
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
