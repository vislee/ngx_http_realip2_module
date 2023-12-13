-- Copyright (C) vislee

local ffi = require 'ffi'
local base = require("resty.core.base")
base.allows_subsystem('http')

local tonumber = tonumber
local C = ffi.C
local ffi_new = ffi.new
local ffi_str = ffi.string


local _M = {}
_M.version = "0.02"

ffi.cdef[[
    typedef unsigned short u_short;
    int ngx_http_lua_ffi_realip_set_addr(ngx_http_request_t *r,
        const char *ip, size_t len, char **errmsg);
    int ngx_http_lua_ffi_realip_get_addr(ngx_http_request_t *r, ngx_str_t *addr,
        char **errmsg);
    int ngx_http_lua_ffi_get_proxy_protocol_addr(ngx_http_request_t *r,
    ngx_str_t *src_addr, ngx_str_t *dst_addr,
    u_short *src_port, u_short *dst_port, char **errmsg);
]]

if not pcall(ffi.typeof, "ngx_str_t") then
    ffi.cdef[[
        typedef struct {
            size_t                 len;
            const unsigned char   *data;
        } ngx_str_t;
    ]]
end

local str_t = ffi_new("ngx_str_t[1]")

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

local function realip_set_remote_addr(addr)
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

_M.set_remote_addr = realip_set_remote_addr


local function realip_get_remote_addr()
    local r = get_request()

    if not r then
        return nil, "no request found"
    end

    local rc
    rc = C.ngx_http_lua_ffi_realip_get_addr(r, str_t, errmsg)

    if rc == 0 then
        local addr = str_t[0]
        return ffi_str(addr.data, addr.len)
    end

    return nil, ffi_str(errmsg[0])
end

_M.get_remote_addr = realip_get_remote_addr


local function get_proxy_protocol_addr()
    local r = get_request()

    if not r then
        return nil, "no request found"
    end

    local src_addr_str_t = ffi_new("ngx_str_t[1]")
    local dst_addr_str_t = ffi_new("ngx_str_t[1]")
    local src_ushort = ffi_new("u_short[1]")
    local dst_ushort = ffi_new("u_short[1]")

    local rc
    rc = C.ngx_http_lua_ffi_get_proxy_protocol_addr(r, src_addr_str_t, dst_addr_str_t, src_ushort, dst_ushort, errmsg)

    if rc ~= 0 then
        return nil, ffi_str(errmsg[0])
    end

    local src_addr = src_addr_str_t[0]
    local dst_addr = dst_addr_str_t[0]
    local src_port = src_ushort[0]
    local dst_port = dst_ushort[0]

    return {
        src_addr = ffi_str(src_addr.data, src_addr.len),
        dst_addr = ffi_str(dst_addr.data, dst_addr.len),
        src_port = tonumber(src_port),
        dst_port = tonumber(dst_port)
    }
end

_M.get_proxy_protocol_addr = get_proxy_protocol_addr

return _M
