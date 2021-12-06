Name
====

ngx_http_realip2_module - Extend the realip module.

Table of Contents
=================
* [Name](#name)
* [Status](#status)
* [Install](#install)
* [Synopsis](#synopsis)
* [Methods](#methods)
	* [set_remote_addr](#set_remote_addr)
	* [get_remote_addr](#get_remote_addr)
* [Author](#author)
* [See Also](#see-also)


Status
======
The module is currently in active development.

[Back to TOC](#table-of-contents)


Install
=======

```sh
# --with-http_realip_module must be disable.
configure --prefix=/usr/local/nginx --add-module=./github.com/vislee/ngx_http_realip2_module
make -j 4

install -d ${prefix}/lualib/resty/
install lib/resty/realip.lua ${prefix}/lualib/resty/

```


Synopsis
====================

```nginx
lua_package_path "${prefix}/lualib/resty/?.lua;;";

server {
     location /test {
         content_by_lua_block {
             local realip = require "resty.realip"

             if ngx.var.remote_addr == "127.0.0.1" then
                 realip.set_remote_addr("10.11.12.13")
             end

             ngx.print(ngx.var.remote_addr, " ", realip.get_remote_addr())
             ngx.exit(ngx.HTTP_OK)
         }
     }
}

```


Methods
=======

set_remote_addr
---------------
**syntax:** *realip.set_remote_addr(addr)*

**context:** *rewrite_by_lua\*,access_by_lua\*,content_by_lua\*,header_filter_by_lua\*,body_filter_by_lua\** 

Set the client address.

get_remote_addr
---------------
**syntax:** *addr, err = realip.get_remote_addr()*

**context:** *rewrite_by_lua\*,access_by_lua\*,content_by_lua\*,header_filter_by_lua\*,body_filter_by_lua\** 

Get the client address.

In case of error, `nil` will be returned as well as a string describing the error.


*NOTE:*  The `ngx.var.remote_addr` will be cached. So the `ngx.var.remote_addr` maybe not changed after `realip.set_remote_addr(addr)`. You can use `realip.get_remote_addr()`.


[Back to TOC](#table-of-contents)

Author
======

wenqiang li(vislee)

[Back to TOC](#table-of-contents)


See Also
========

+ [ngx_http_realip_module](http://nginx.org/en/docs/http/ngx_http_realip_module.html)
