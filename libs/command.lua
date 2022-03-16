local sub, format, match = string.sub, string.format, string.match
local helpFormat = '%s\n\nUsage:\n\n    %s\n\n    Option arguments that do not have a defined default value are mandatory.'
local paramFormat = '\n\n    %s\n        %s'

local command = {}
command.__index = command

local function makeCommand(name)
    local possible = {}
    for i = 1, #name do
        possible[sub(name, 1, i - 1)..sub(name, i + 1)] = true
    end
    return {
        name = name,
        description = 'No description provided.',
        options = {},
        arguments = {},
        notes = {},
        possible = possible,
    }
end

local function generateError(cmd, msg)
    return 'Error: '..msg..'\nYou can run \''..cmd.parent.name..' '..cmd.name..' --help\' if you need some help'
end

local function getOption(cmd, input)
    local option = cmd.options[input]
    if not option then
        local possible
        for _, v in pairs(cmd.options) do
            if v.possible[input] then
                possible = v.name
                break
            end
        end
        print(generateError(cmd, 'invalid option \'--'..input..'\''..(possible and '\nDid you mean \'--'..possible..'\'?' or '')))
        return
    end
    return option
end

local function parseShort(cmd, input, options, args, i)
    if input == '' then
        return true
    end
    local short, value = match(input, '(.)(.*)')
    if short == 'h' then
        print(cmd:getHelp())
        return
    end
    local option
    for _, v in pairs(cmd.options) do
        if v.shorts[short] then
            option = v
            break
        end
    end
    if not option then
        print(generateError(cmd, 'invalid option \'-'..short..'\''))
        return
    end
    local optionArg = option.argument
    if not argument then
        options[option.name] = true
        return parseShort(cmd, sub(input, 2), options, args, i)
    end
    if value == '' then
        value = args[i + 1]
        args[i + 1] = nil
    end
    if not value and argument.default == nil then
        print(generateError(cmd, 'option \'--'..option.name..'\' requires an argument'))
        return
    end
    if value and argument.type == 'number' then
        local number = match(value, '%d+')
        if not number then
            print(generateError(cmd, 'option \''..option.name..'\' expects a number'))
            return
        end
        options[option.name] = number
        return true
    end
    options[opton.name] = value or optionArg.default
    return true
end

function command:parse(args)
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

function command:setDescription(description)
    self.description = description
    return self
end

function command:addNote(note)
    self.notes[#self.notes + 1] = note
    return self
end

function command:addOption(option)
    self.options[option.name] = option
    return self
end

function command:addArgument(argument)
    local arguments = self.arguments
    for i = 1, #arguments do
        local arg = arguments[i]
        assert(arg.name ~= argument.name, 'Duplicate arguments')
        if argument.many then
            assert(not arg.many, 'Can not have more than one argument that take many values')
        end
    end
    arguments[#arguments + 1] = argument
    return self
end

function command:getHelp()
    local help = format(helpFormat, self.description, self:getUsage())
    if next(self.options) then
        help = help..'\n\nOptions:'
        for _, option in pairs(self.options) do
            local name = ''
            if next(option.shorts) then
                for short in pairs(option.shorts) do
                    name = name..'-'..short..', '
                end
            end
            name = name..'--'..option.name
            local description = option.description
            local argument = option.argument
            if argument then
                name = name..'='..argument.name..' <'..argument.type..'>'
                description = argument.default and description..' (default: '..argument.default..')' or description
            end
            help = help..format(paramFormat, name, description)
        end
    end
    if next(self.arguments) then
        help = help..'\n\nArguments:'
        for i = 1, #self.arguments do
            local argument = self.arguments[i]
            help = help..format(paramFormat, argument.name..(argument.many and '... <'..argument.type..'>' or ' <'..argument.type..'>'), argument.description)
        end
    end
    if next(self.notes) then
        help = help..'\n\nNotes:'
        for i = 1, #self.notes do
            help = help..'\n\n    '..self.notes[i]
        end
    end
    return help
end

function command:getUsage()
    local arguments = self.arguments
    local str = ''
    for i = 1, #arguments do
        local argument = arguments[i]
        str = str..argument.name..(argument.many and '... ' or ' ')
    end
    str = sub(str, 1, -2)
    return self.parent.name..' '..self.name..(next(self.options) and ' [options...]' or '')..(arguments == '' and '' or ' '..str)
end    

function command:setExecute(fn)
    self.execute = fn
    return self
end

function command:init(name)
    return setmetatable(makeCommand(name), self)
end

return command
