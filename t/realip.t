use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

log_level('debug');

repeat_each(1);
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
            realip.set_addr("192.168.0.1")
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
