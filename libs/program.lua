local sub, format, match = string.sub, string.format, string.match
local remove, concat = table.remove, table.concat
local sort, sorter = table.sort, function(a, b)
    return b.default ~= nil
end
local helpFormat = '%s\n\nUsage:\n\n    %s\n\n    Option arguments that do not have a defined default value are mandatory.'
local paramFormat = '\n\n    %s\n        %s'

local program = {}
program.__index = program

local function makeProgram(name)
    return {
        name = name,
        description = 'No description provided.',
        commands = {},
        arguments = {},
        options = {}
    }
end

local function generateError(prog, msg)
    return 'Error: '..msg..'\nYou can run \''..prog.name..' --help\' if you need some help'
end

local function convert(default)
    return type(default) == 'table' and concat(default, ' ') or tostring(default)
end

local function getCommand(prog, input)
    local command = prog.commands[input]
    if not command then
        local possible
        for _, v in pairs(prog.commands) do
            if v.possible[input] then
                possible = v.name
                break
            end
        end
        print(generateError(prog, 'invalid command \''..input..'\''..(possible and '\nDid you mean \''..possible..'\'?' or '')))
        return
    end
    return command
end

local function getOption(prog, input)
    local option = prog.options[input]
    if not option then
        local possible
        for _, v in pairs(prog.options) do
            if v.possible[input] then
                possible = v.name
                break
            end
        end
        print(generateError(prog, 'invalid option \'--'..input..'\''..(possible and '\nDid you mean \'--'..possible..'\'?' or '')))
        return
    end
    return option
end

local function parseShort(prog, input, options, args, i)
    if input == '' then
        return true
    end
    local short, value = match(input, '(.)(.*)')
    if short == 'h' then
        print(prog:getHelp())
        return
    end
    local option
    for _, v in pairs(prog.options) do
        if v.shorts[short] then
            option = v
            break
        end
    end
    if not option then
        print(generateError(prog, 'invalid option \'-'..short..'\''))
        return
    end
    local optionArg = option.argument
    if not argument then
        options[option.name] = true
        return parseShort(prog, sub(input, 2), options, args, i)
    end
    if value == '' then
        value = args[i + 1]
        args[i + 1] = nil
    end
    if not value and argument.default == nil then
        print(generateError(prog, 'option \'--'..option.name..'\' requires an argument'))
        return
    end
    if value and argument.type == 'number' then
        local number = match(value, '%d+')
        if not number then
            print(generateError(prog, 'option \''..option.name..'\' expects a number'))
            return
        end
        options[option.name] = number
        return true
    end
    options[opton.name] = value or optionArg.default
    return true
end


function program:setDescription(description)
    self.description = description
    return self
end

function program:handler()
    local input, luvi
    if args then
        luvi = true
        input = args
    else
        input = arg
    end
    if not input then
        print('Error: could not get command-line arguments')
        return
    end
    if luvi then
        local success, package = pcall(require, 'bundle:/package.lua')
        if success and type(package) == 'table' and package.name == 'luvit/luvit' then
            remove(input, 1)
        end
    end
    return self:parse(input)
end

function program:parse(args)
    if next(self.commands) then
        if #args == 0 then
            print(generateError(self, 'no command given'))
            return
        end
        local input = args[1]
        if sub(input, 1, 2) == '--' then
            input = sub(input, 3)
            local key, value = match(input, '(.+)=(.+)')
            input = key or input
            if input == 'help' then
                if value then
                    local command = getCommand(self, value)
                    if command then
                        print(command:getHelp())
                    end
                else
                    print(self:getHelp())
                end
            else
                print(generateError(prog, 'invalid option \'--'..inpt..'\''))
            end
            return
        end
        if sub(input, 1, 1) == '-' then
            local short, value = match(sub(input, 2), '(.)(.*)')
            value = value == '' and args[2] or value
            if short == 'h' then
                if value then
                    local command = getCommand
                    if command then
                        print(command:getHelp())
                    end
                else
                    print(self:getHelp())
                end
            else
                print(generateError(self, 'invalid option \'-'..short..'\''))
            end
            return
        end
        local command = getCommand(self, input)
        if command then
            remove(args, 1)
            command:parse(args)
        end
        return
    end
    local arguments, options, collection = {}, {}, {}
    local handleOptions, collect = true, false
    local index = 1
    for i = 1, #args do
        local arg = args[i]
        if not arg then
            goto continue
        end
        if arg == '--' then
            handleOptions = false
            goto continue
        end
        if handleOptions and sub(arg, 1, 2) == '--' then
            local input = sub(arg, 3)
            local name, value = match(input, '(.+)=(.+)')
            input = name or value
            if input == 'help' then
                if value then
                    print(generateError(self, 'option \'--help\' does not take an argument'))
                else
                    print(self:getHelp())
                end
                return
            end
            local option = getOption(self, input)
            if not option then
                return
            end
            local optionArg = option.argument
            if value and not optionArg then
                print(generateError(self,  'option \'--'..option.name..'\' does not take an argument'))
                return
            end
            if optionArg then
                if not value and argument.default == nil then
                    print(generateError(self, 'option \'--'..option.name..'\' requires an argument'))
                    return
                end
                if value and optionArg.type == 'number' then
                    local number = match(value, '%d+')
                    if not number then
                        print(generateError(self, 'option \'--'..option.name..'\' expects a number'))
                        return
                    end
                    options[option.name] = number
                else
                    options[option.name] = value or optionArg.default
                end
            else
                options[option.name] = true
            end
            goto continue
        end
        if handleOptions and sub(arg, 1, 1) == '-' then
            if not parseShort(self, sub(arg, 2), options, args, i) then
                return
            end
            goto continue
        end
        if not next(self.arguments) then
            print(generateError(self, self.name..' does not take any arguments'))
            return
        end
        if collect then
            collection[#collection + 1] = arg
            goto continue
        end
        local argument = self.arguments[index]
        if not argument then
            print(generateError(self, 'too many arguments'))
            return
        end
        if argument.many then
            collection[#collection + 1] = arg
            collect = true
            goto continue
        end
        if argument.type == 'number' then
            local number = match(arg, '%d+')
            if not number then
                print(generateError(self, 'argument \''..argument.name..'\' expects a number'))
                return
            end
            arguments[argument.name] = number
        else
            arguments[argument.name] = arg
        end
        index = index + 1
        ::continue::
    end
    if collect then
        if index - #self.arguments == 0 then
            local argument = self.arguments[index]
            if argument.type == 'number' then
                for i = 1, #collection do
                    local number = match(collection[i], '%d+')
                    if not number then
                        print(generateError(self, 'argument \''..argument.name..'\' expects a list of numbers'))
                        return
                    end
                    collection[i] = number
                end
            end
            arguments[argument.name] = collection
        else
            for i = index + 1, #self.arguments do
                if #collection == 1 then
                    break
                end
                local argument = self.arguments[i]
                local input = collection[#collection]
                if argument.type == 'number' then
                    local number = match(input, '%d+')
                    if not number then
                        print(generateError(self, 'argument \''..argument.name..'\' expects a number'))
                        return
                    end
                    arguments[argument.name] = number
                else
                    arguments[argument.name] = input
                end
                collection[#collection] = nil
            end
            local argument = self.arguments[index]
            if argument.type == 'number' then
                for i = 1, #collection do
                    local number = match(collection[i], '%d+')
                    if not number then
                        print(generateError(self, 'argument \''..argument.name..'\' expects a list of numbers'))
                        return
                    end
                    collection[i] = number
                end
            end
            arguments[argument.name] = collection
        end
    end
    for i = 1, #self.arguments do
        local argument = self.arguments[i]
        if not arguments[argument.name] then
            if argument.default ~= nil then
                arguments[argument.name] = argument.default
            else
                print(generateError(self, 'argument \''..argument.name..'\' is required'))
                return
            end
        end
    end
    return self.execute(arguments, options)
end

function program:addArgument(argument)
    local arguments = self.arguments
    for i = 1, #arguments do
        local arg = arguments[i]
        assert(arg.name ~= argument.name, 'Duplicate arguments')
        if argument.many then
            assert(not arg.many, 'Can not have more than one argument that take many values')
        end
    end
    arguments[#arguments + 1] = argument
    sort(arguments, sorter)
    return self
end

function program:addOption(option)
    option = option.getOption and option:getOption() or option
    option.parent = self
    self.options[option.name] = option
    return self
end

function program:setExecute(fn)
    assert(next(self.commands) == nil, 'A program with subcommands cannot have an execute function')
    self.execute = fn
    return self
end

function program:addCommand(command)
    assert(self.execute == nil, 'A program with an execute function cannot have any subcommands')
    command.parent = self
    self.commands[command.name] = command
    return self
end

function program:getHelp()
    if next(self.commands) then
        local help = self.description..'\n\nUsage:'
        for _, command in pairs(self.commands) do
            help = help..format(cmdFormat, command:getUsage(), command.description)
        end
        help = help..'\n\nYou can run \''..self.name..' <command> --help\' if you need more information regarding a specific command'
        return help
    end
    local help = format(helpFormat, self.description, self:getUsage())..'\n\nOptions:'
    for _, option in pairs(self.options) do
        local name = ''
        local description = option.description
        local optionArg = option.argument
        for short in pairs(option.shorts) do
            name = name..'-'..short..', '
        end
        name = name..'--'..option.name
        if optionArg then
            name = name..'='..argument.name.. ' <'..argument.type..'>'
            description = argument.default ~= nil and description..' (default: '..convert(argument.default)..')' or description
        end
        help = help..format(paramFormat, name, description)
    end
    help = help..format(paramFormat, '-h, --help', 'Display this help message and exit')
    if next(self.arguments) then
        help = help..'\n\nArguments:'
        for i = 1, #self.arguments do
            local argument = self.arguments[i]
            help = help..format(paramFormat, argument.name..(argument.many and '... <'..argument.type..'>' or ' <'..argument.type..'>'), argument.default ~= nil and argument.description..' (default: '..convert(argument.default)..')' or argument.description)
        end
    end
    return help
end

function program:getUsage()
    local argString = ''
    for i = 1, #self.arguments do
        local argument = self.arguments[i]
        argString = argString..argument.name..(argument.many and '... ' or ' ')
    end
    argString = sub(argString, 1, -2)
    return self.name..' [options...]'..(argString == '' and '' or ' '..argString)
end

function program:init(name)
    return setmetatable(makeProgram(name), self)
end
return program