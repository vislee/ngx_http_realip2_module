Name
====

ngx_http_realip2_module - Extend the realip module.

Table of Contents
=================
* [Name](#name)
* [Status](#status)
* [Install](#install)
* [Synopsis](#synopsis)
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
install realip.lua ${prefix}/lualib/resty/

```


Synopsis
====================

```nginx
lua_package_path "${prefix}/lualib/resty/?.lua;;";

server {
     location /test {
         content_by_lua_block {
             local realip = require "resty.realip"
             realip.set_addr("192.168.0.1")
         }
     }
}

```


Author
======

wenqiang li(vislee)

[Back to TOC](#table-of-contents)


See Also
========

+ [ngx_http_realip_module](http://nginx.org/en/docs/http/ngx_http_realip_module.html)
