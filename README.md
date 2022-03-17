# lit-cli
A simple module to aid in the creation of command line interfaces

## Information
I was bored one day with nothing to do so I randomly decided to port Linux's `mv` command to windows using [luvi](https://github.com/luvit/luvi) as window's equivalent `move` does not support all the things `mv` does.</br>
But instead of parsing command-line arguments manually I decided to make a library to help me do it and the advantage is that this library should work for any project I may have in the future + help others build their own programs.</br>
My `mv` port is hosted [here](https://github.com/TohruMKDM/windows-mv)

## Installation
This module was originally intended for [luvi](https://github.com/luvit/luvi) so installing it from [lit](https://luvit.io/lit.html) is incredibly easy.
```
lit install TohruMKDM/lit-cli
```
I have added support for PUC Lua and LuaJIT so you can also just clone the repository to use this library on those platforms
```
git clone https://github.com/TohruMKDM/lit-cli.git
```

## Example
```lua
-- main.lua
-- Require the library
local cli = require('cli')

-- Create new program object named 'example' and set it's description
local program = cli.program:init('example')
    :setDescription('This is an example program.')
-- Create a new argument named 'path' and add it to the program
local path = cli.argument:init('path')
    :setDescription('The path to the file')
program:addArgument(path)
-- Create a new option named 'silent', set it's short option and add it to the program
local silent = cli.option:init('silent')
    :setDescription('If set then the operation will be done silently')
    :addShort('s')
program:addOption(silent)

-- Create the handler function
local function handler(prog, arguments, options)
    -- prog: The program object this handler belongs to.
    -- arguments: The parsed arguments
    -- options: The parsed options
    p('arguments', arguments)
    p('options', options)
end
program:setExecute(handler)

-- Handle command line arguments
return program:handler()
```
We are going to assume this is your main.lua file and you built your program using `luvi ./ -o example.exe`</br>
`example test`
```lua
'arguments'    {path = 'test'}
'options'      {}
```
`example test --silent`
```lua
'arguments'    {path = 'test'}
'options'      {silent = true}
```
`example test -s` results in the same output\n
`example`
```
Error: argument 'path' is required'
You can run 'example --help' if you need some help
```
## Documentation
I'll finish this later.