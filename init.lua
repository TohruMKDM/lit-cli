local luvi = args and true

return {
    command = require(luvi and 'command' or 'libs/command'),
    argument = require(luvi and 'argument' or 'libs/argument'),
    program = require(luvi and 'program' or 'libs/program'),
    option = require(luvi and 'option' or 'libs/option')
}