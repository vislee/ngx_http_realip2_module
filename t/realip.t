use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

log_level('debug');

repeat_each(10);
plan tests => repeat_each() * (3 * blocks());

no_long_string();

run_tests();

__DATA__

=== TEST 1: set realip in lua
--- http_config
    lua_package_path 'lib/?.lua;;';

    init_by_lua_block {
        require 'luacov.tick'
        jit.off()
    }

--- config
    location /t {
        access_by_lua_block {
            local realip = require "resty.realip"
            realip.set_remote_addr("192.168.0.1")
        }

        content_by_lua_block {
            ngx.say(ngx.var.remote_addr)
            ngx.exit(ngx.HTTP_OK)
        }
    }

--- request
GET /t
--- response_body_like: 192.168.0.1
--- error_code: 200
--- no_error_log
[error]


=== TEST 2: remote_addr
--- http_config
    lua_package_path 'lib/?.lua;;';

    init_by_lua_block {
        require 'luacov.tick'
        jit.off()
    }

--- config
    location /t {

        content_by_lua_block {
            ngx.say(ngx.var.remote_addr)
            ngx.exit(ngx.HTTP_OK)
        }
    }

--- request
GET /t
--- response_body_like: 127.0.0.1
--- error_code: 200
--- no_error_log
[error]



=== TEST 3: get realip in lua
--- http_config
    lua_package_path 'lib/?.lua;;';

    init_by_lua_block {
        require 'luacov.tick'
        jit.off()
    }

--- config
    location /t {

        content_by_lua_block {
            local realip = require "resty.realip"

            local mid
            if ngx.var.remote_addr == "127.0.0.1" then
                realip.set_remote_addr("10.11.12.13")
                mid = realip.get_remote_addr()
                realip.set_remote_addr("10.11.12.14")
            end

            ngx.print(ngx.var.remote_addr, " ", mid, " ", realip.get_remote_addr())
            ngx.exit(ngx.HTTP_OK)
        }
    }

--- request
GET /t
--- response_body: 127.0.0.1 10.11.12.13 10.11.12.14
--- error_code: 200
--- no_error_log
[error]
