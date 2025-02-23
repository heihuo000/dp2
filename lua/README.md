# lua module for dp2

## 概述

本项目是一个基于 Lua 的游戏服务器框架,提供了丰富的功能模块和工具库。

## 外部接口(FFI)

提供两种 FFI 选择:

### luaffi
独立的 FFI 库,用于从 Lua 调用 C 函数。兼容 luajit FFI 接口。

- 来源: https://github.com/jmckaskill/luaffi
- 注意: 源码已修改以添加功能和修复bug,请勿自行编译替换!

### alien 
C FFI for Lua

- 来源: https://mascarenhas.github.io/alien/
- 注意: 源码已修改以添加功能和修复bug,请勿自行编译替换!

## 核心模块

### luv
libuv 的 Lua 绑定

- 文档: https://github.com/luvit/luv/blob/master/docs.md
- 重要: 不要在主 Lua 状态机中调用 run()!

### effil
Lua 多线程支持

- 来源: https://github.com/effil/effil

### lua-socket
Lua 网络支持

- 文档: https://defold.com/ref/stable/socket/
- 来源: https://github.com/diegonehab/luasocket

### luaSQL
Lua 到 DBMS 的简单接口

- 示例: https://keplerproject.github.io/luasql/examples.html
- 来源: https://github.com/keplerproject/luasql

### lua-protobuf
用于处理 Google protobuf 的 Lua 模块

- 文档: https://github.com/starwing/lua-protobuf/blob/master/README.zh.md

## 工具库

### json.lua
轻量级的 Lua JSON 库

- 来源: https://github.com/rxi/json.lua

### lua-MessagePack
msgpack.org 的纯 Lua 实现

- 来源: https://github.com/markstinson/lua-MessagePack

### LuaFileSystem
补充 Lua 标准发行版中文件系统相关功能

- 文档: https://keplerproject.github.io/luafilesystem/manual.html
- 来源: https://github.com/keplerproject/luafilesystem

### Penlight
一组纯 Lua 库,专注于:
- 输入数据处理(如配置文件读取)
- 函数式编程(如 map, reduce 等)
- OS 路径管理

- 文档: https://lunarmodules.github.io/Penlight/
- 来源: https://github.com/lunarmodules/Penlight

## 开发工具

### lua-tcc
通过 alien 实现的 Tiny C Compiler Lua 绑定

- 示例: 见 tcc/testX.lua
- 类似: https://github.com/nucular/tcclua

### hotfix
函数热更新,保持旧数据

- 来源: https://github.com/jinq0123/hotfix

### serpent
Lua 序列化器和美化打印工具

- 来源: https://github.com/pkulchenko/serpent

### lua-iconv
POSIX iconv 的 Lua 绑定

- 来源: https://github.com/ittner/lua-iconv

## 使用说明

1. 确保已安装所有依赖库
2. 不要替换任何预编译的二进制文件
3. 在使用多线程功能时需格外注意
4. 建议使用 hotfix 进行热更新
5. 参考各模块文档进行开发

## 开发建议

1. 使用 LuaFileSystem 处理文件操作
2. 网络编程优先使用 lua-socket
3. 配置解析使用 Penlight
4. 数据序列化根据场景选择 JSON/MessagePack/serpent
5. 编码转换使用 lua-iconv
6. 需要调用 C 函数时优先使用 luaffi

## 注意事项

1. 不要在主线程中运行 luv
2. 不要替换任何修改过的依赖库
3. 使用 hotfix 时需要注意数据状态
4. 多线程操作需要考虑同步问题
5. 建议遵循各个库的最佳实践
