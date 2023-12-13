use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

log_level('debug');

repeat_each(1);
plan tests => repeat_each() * (3 * blocks());

no_long_string();

$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();

run_tests();

__DATA__

=== TEST 1: get proxy protocol addr
--- http_config
    lua_package_path 'lib/?.lua;;';

    server {
        listen unix:$TEST_NGINX_HTML_DIR/nginx.sock proxy_protocol;
        server_name test.com;
        server_tokens off;
        location /foo {
            content_by_lua_block {
                local realip = require "resty.realip"
                local pp, err = realip.get_proxy_protocol_addr()
                if pp == nil then
                    ngx.log(ngx.ERR, "err: ", err)
                    return
                end

                local cjson = require("cjson")
                ngx.log(ngx.INFO, "===", cjson.encode(pp))

                local body = table.concat({table.concat({"dst", pp.dst_addr, pp.dst_port}, ":"),
                    table.concat({"src", pp.src_addr, pp.src_port}, ":")}, "; ")

                ngx.header["content-length"] = #body

                ngx.say(body)
            }
        }
    }

--- config
    location /t {
        content_by_lua_block {
            local sock = ngx.socket.tcp()
            sock:settimeout(3000)
            local ok, err = sock:connect("unix:$TEST_NGINX_HTML_DIR/nginx.sock")
            if not ok then
                ngx.say("failed to connect: ", err)
                return
            end

            local pp = "PROXY TCP4 192.0.2.1 192.0.2.2 123 5678\r\n"
            local bytes, err = sock:send(pp)
            if not bytes then
                ngx.say("failed to send proxy protocol: ", err)
                return
            end

            local req = "GET /foo HTTP/1.1\r\nHost: test.com\r\n\r\n"
            local bytes, err = sock:send(req)
            if not bytes then
                ngx.say("failed to send http request: ", err)
                return
            end

            local status, err = sock:receive("*l")
            if not status then
                ngx.say("failed to receive status: ", err)
                return
            end
            ngx.log(ngx.INFO, "status: ", status)

            local reader = sock:receiveuntil("\r\n\r\n")
            local header, err = reader()
            if not header then
                ngx.say("failed to receive header: ", err)
                return
            end
            ngx.log(ngx.INFO, "header: ", header)

            local body, err = sock:receive("*l")
            if not body then
                ngx.say("failed to receive body: ", err)
                return
            end

            sock:close()

            ngx.print(body)
        }
    }

--- request
GET /t
--- response_body: dst:192.0.2.2:5678; src:192.0.2.1:123
--- no_error_log
[error]

