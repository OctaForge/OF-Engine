--[[
    OctaScript

    Copyright (C) 2014 Daniel "q66" Kolesa

    See COPYING.txt for licensing.

    Based on LuaJIT Language Toolkit written by Francesco Abbate:
    https://github.com/franko/luajit-lang-toolkit
]]

local util = require("octascript.util")

local kind_to_str

local kind_to_str_t = {
    node = function(spec)
        return spec.kind
    end,
    list = function(spec)
        return "list of " .. kind_to_str(spec.kind)
    end,
    enum = function(spec)
        local ls = {}
        for i, v in ipairs(spec.values) do
            ls[i] = spec.values[i]
        end
        return table.concat(ls, ", ")
    end,
    literal = function(spec)
        return "literal " .. spec.value
    end,
    choice = function(spec)
        local ls = {}
        for i, v in ipairs(spec.values) do
            ls[i] = kind_to_str(v)
        end
        return table.concat(ls, "|")
    end
}

kind_to_str = function(spec)
    if type(spec) == "string" then
        return spec
    end
    local f = kind_to_str_t[spec.type]
    if not f then
        error("ICE: invalid spec type")
    end
    return f(spec)
end

local check

local check_t = {
    node = function(prop, spec)
        if not prop then
            if not spec.optional then
                return false, "expected Node"
            end
            return true
        end
        if not prop.check then
            return false, "expected Node"
        end
        return prop:check(spec.kind)
    end,
    list = function(prop, spec)
        if type(prop) ~= "table" then
            return false, "expected list of " .. kind_to_str(spec.kind)
                .. " (got " .. type(prop) .. ")"
        end
        if prop.is_kind then
            return false, "expected list of " .. kind_to_str(spec.kind)
                .. " (got node)"
        end
        for i, v in ipairs(prop) do
            check(v, spec.kind)
        end
        return true
    end,
    enum = function(prop, spec)
        for i, v in ipairs(spec.values) do
            if prop == v then
                return true
            end
        end
        return false, "expected one of " .. kind_to_str(spec) .. " (got '"
            .. tostring(prop) .. "')"
    end,
    literal = function(prop, spec)
        assert(type(spec.value) == "string")
        if type(prop) == spec.value then
            return true
        end
        return false, "expected " .. spec.value .. " (got " .. type(prop) .. ")"
    end,
    choice = function(prop, spec)
    for i, v in ipairs(spec.values) do
        if check(prop, v) then
            return true
        end
    end
    return false
end
}

check = function(prop, spec)
    if type(spec) == "string" then
        if not prop.check then
            return false, "expected Node"
        end
        return prop:check(spec)
    end
    local f = check_t[spec.type]
    if not f then
        error("ICE: invalid spec type")
    end
    return f(prop, spec)
end

local M = {}

M.new = function()
    return setmetatable({}, { __index = M })
end

local Node = util.Object:clone {
    kind = "Node",
    properties = {},

    __ctor = function(self)
        for name, spec in pairs(self.properties) do
            if  self[name] == nil and spec.default then
                self[name] = spec.default
            end
            local prop = self[name]
            if prop or not spec.optional then
                local  ok, err = check(prop, spec)
                if not ok then
                    error(err .. " for " .. (self.kind or "?") .. "." .. name)
                end
            end
        end
    end,

    is_kind = function(self, kind)
        while self do
            if self.kind == kind then
                return true
            end
            self = self.__index
        end
        return false
    end,

    check = function(self, tag)
        if not self:is_kind(tag) then
            return false, "expected " .. tag
        end
        return true
    end
}

local Expression = Node:clone {
    kind = "Expression"
}

local Statement = Node:clone {
    kind = "Statement"
}

local Identifier = Expression:clone {
    kind = "Identifier",

    properties = {
        name = { type = "literal", value = "string" }
    },

    __ctor = function(self, name, line)
        self.name = name
        self.line = line
        Node.__ctor(self)
    end
}
M.Identifier = Identifier

local new_scope = function(parent)
    return {
        vars = parent and setmetatable({}, { __index = parent.vars }) or {},
        parent = parent
    }
end

M.scope_begin = function(self)
    self.current = new_scope(self.current)
end

M.scope_end = function(self)
    self.current = self.current.parent
end

M.var_declare = function(self, name)
    local id = Identifier(name)
    self.current.vars[name] = true
    return id
end

M.ParenthesizedExpression = Expression:clone {
    kind = "ParenthesizedExpression",

    properties = {
        expression = "Expression"
    },

    __ctor = function(self, expr, line)
        self.expression = expr
    end
}

M.FunctionDeclaration = Statement:clone {
    kind = "FunctionDeclaration",

    properties = {
        id = {
            type = "choice",
            values = { "MemberExpression", "Identifier" }
        },
        body = {
            type = "list",
            kind = "Statement"
        },
        params = {
            type = "list",
            kind = "Identifier"
        },
        vararg = {
            type = "literal",
            value = "boolean",
            default = false
        },
        locald = {
            type = "literal",
            value = "boolean",
            default = false
        }
    },

    __ctor = function(self, id, body, params, vararg, locald, firstline, lastline)
        self.id = id
        self.body = body
        self.params = params
        self.vararg = vararg
        self.locald = locald
        self.firstline = firstline
        self.lastline = lastline
        Node.__ctor(self)
    end
}

M.FunctionExpression = Expression:clone {
    kind = "FunctionExpression",

    properties = {
        body = {
            type = "list",
            kind = "Statement"
        },
        params = {
            type = "list",
            kind = "Identifier"
        },
        vararg = {
            type = "literal",
            value = "boolean",
            default = false
        }
    },

    __ctor = function(self, body, params, vararg, firstline, lastline)
        self.body = body
        self.params = params
        self.vararg = vararg
        self.firstline = firstline
        self.lastline = lastline
        Node.__ctor(self)
    end
}

M.Chunk = Node:clone {
    kind = "Chunk",

    properties = {
        body = {
            type = "list",
            kind = "Statement"
        },
        chunkname = {
            type = "literal",
            value = "string"
        }
    },

    __ctor = function(self, body, chunkname, firstline, lastline)
        self.body = body
        self.chunkname = chunkname
        self.firstline = firstline
        self.lastline = lastline
        Node.__ctor(self)
    end
}

M.LocalDeclaration = Statement:clone {
    kind = "LocalDeclaration",

    properties = {
        names = {
            type = "list",
            kind = "Identifier"
        },
        expressions = {
            type = "list",
            kind = "Expression"
        }
    },

    __ctor = function(self, ast, vlist, exps, line)
        local ids = {}
        for i, v in ipairs(vlist) do
            ids[i] = ast:var_declare(v)
        end
        self.names = ids
        self.expressions = exps
        self.line = line
        Node.__ctor(self)
    end
}

M.LocalMemberDeclaration = Statement:clone {
    kind = "LocalMemberDeclaration",

    properties = {
        names = {
            type = "list",
            kind = "Identifier"
        },
        expression = "Expression"
    },

    __ctor = function(self, ast, vlist, exp, line)
        local ids = {}
        for i, v in ipairs(vlist) do
            ids[i] = ast:var_declare(v)
        end
        self.names = ids
        self.expression = exp
        self.line = line
        Node.__ctor(self)
    end
}

M.AssignmentExpression = Statement:clone {
    kind = "AssignmentExpression",

    properties = {
        left = {
            type = "list",
            kind = {
                type = "choice",
                values = { "MemberExpression", "Identifier" }
            }
        },
        right = {
            type = "list",
            kind = "Expression"
        }
    },

    __ctor = function(self, vars, exps, line)
        self.left = vars
        self.right = exps
        self.line = line
        Node.__ctor(self)
    end
}

M.MemberExpression = Expression:clone {
    kind = "MemberExpression",

    properties = {
        object = "Expression",
        property = "Expression",
        computed = {
            type = "literal",
            value = "boolean",
            default = false
        }
    },

    __ctor = function(self, object, index, computed, line)
        self.object = object
        self.property = index
        self.computed = computed
        self.line = line
        Node.__ctor(self)
    end
}

M.Literal = Expression:clone {
    kind = "Literal",

    properties = {
        value = {
            type = "choice",
            values = {
                { type = "literal", value = "string" },
                { type = "literal", value = "number" },
                { type = "literal", value = "nil" },
                { type = "literal", value = "boolean" },
                { type = "literal", value = "cdata" }
            }
        },
    },

    __ctor = function(self, val, line)
        self.value = val
        self.line = line
        Node.__ctor(self)
    end
}

local Literal = M.Literal

M.Vararg = Identifier:clone {
    kind = "Vararg",
    properties = {},
    __ctor = function(self, line)
        self.line = line
        Node.__ctor(self)
    end
}

M.Table = Expression:clone {
    kind = "Table",

    properties = {
        array_entries = {
            type = "list",
            kind = "Expression",
        },
        hash_keys = {
            type = "list",
            kind = "Expression",
        },
        hash_values = {
            type = "list",
            kind = "Expression",
        }
    },

    __ctor = function(self, avals, hkeys, hvals, line)
        self.array_entries = avals
        self.hash_keys = hkeys
        self.hash_values = hvals
        self.line = line
        Node.__ctor(self)
    end
}

M.Enum = Expression:clone {
    kind = "Enum",

    properties = {
        keys = {
            type = "list",
            kind = "string",
        },
        values = {
            type = "list",
            kind = {
                type = "node",
                kind = "Expression",
                optional = true
            }
        }
    },

    __ctor = function(self, keys, vals, line)
        self.keys = keys
        self.values = vals
        self.line = line
        Node.__ctor(self)
    end
}

M.UnaryExpression = Expression:clone {
    kind = "UnaryExpression",

    properties = {
        operator = {
            type = "enum",
            values = { "not", "-", "#" },
        },
        argument = "Expression"
    },

    __ctor = function(self, op, v, line)
        self.operator = op
        self.argument = v
        self.line = line
        Node.__ctor(self)
    end
}

local concat_append = function(ts, node)
    if node.kind == "ConcatenateExpression" then
        for i = 1, #node.terms do
            ts[#ts + 1] = node.terms[i]
        end
    else
        ts[#ts + 1] = node
    end
end

local bitops = {
    ["&" ] = "band",   ["|" ] = "bor",     ["^^" ] = "bxor",
    ["<<"] = "lshift", [">>"] = "arshift", [">>>"] = "rshift",
    ["~" ] = "bnot"
}

M.BinaryExpression = Expression:clone {
    binary_properties = {
        operator = {
            type = "enum",
            values = {
                "+", "-", "*", "/", "^", "%", "==", "~=", ">=", ">", "<=", "<"
            }
        },
        left = "Expression",
        right = "Expression"
    },

    concat_properties = {
        terms = {
            type = "list",
            kind = "Expression"
        }
    },

    logical_properties = {
        operator = {
            type = "enum",
            values = { "and", "or" }
        },
        left = "Expression",
        right = "Expression"
    },

    __ctor = function(self, op, lhs, rhs, line)
        if op == ".." then
            self.kind = "ConcatenateExpression"
            self.properties = self.concat_properties
            local terms = {}
            concat_append(terms, lhs)
            concat_append(terms, rhs)
            self.terms = terms
            self.line = lhs.line
        else
            if op == "and" or op == "or" then
                self.kind = "LogicalExpression"
                self.properties = self.logical_properties
            else
                self.kind = "BinaryExpression"
                self.properties = self.binary_properties
            end
            self.operator = op
            self.left = lhs
            self.right = rhs
        end
        self.line = line
        Node.__ctor(self)
    end
}

M.IfExpression = Expression:clone {
    kind = "IfExpression",

    properties = {
        cond = "Expression",
        texpr = "Expression",
        fexpr = {
            type = "node",
            kind = "Expression",
            optional = true
        }
    },

    __ctor = function(self, cond, texpr, fexpr, line)
        self.cond = cond
        self.texpr = texpr
        self.fexpr = fexpr
        self.line = line
        Node.__ctor(self)
    end
}

M.SendExpression = Expression:clone {
    kind = "SendExpression",

    properties = {
        receiver = "Expression",
        method = "Identifier",
        arguments = {
            type = "list",
            kind = "Expression"
        }
    },

    __ctor = function(self, v, key, args, line)
        self.receiver = v
        self.method = Identifier(key)
        self.arguments = args
        self.line = line
        Node.__ctor(self)
    end
}

M.CallExpression = Expression:clone {
    kind = "CallExpression",

    properties = {
        callee = "Expression",
        arguments = { type = "list", kind = "Expression" }
    },

    __ctor = function(self, v, args, line)
        self.callee = v
        self.arguments = args
        self.line = line
        Node.__ctor(self)
    end
}

M.ReturnStatement = Statement:clone {
    kind = "ReturnStatement",

    properties = {
        arguments = {
            type = "list",
            kind = "Expression"
        }
    },

    __ctor = function(self, exps, line)
        self.arguments = exps
        self.line = line
        Node.__ctor(self)
    end
}

M.BreakStatement = Statement:clone {
    kind = "BreakStatement",

    __ctor = function(self, line)
        self.line = line
        Node.__ctor(self)
    end
}

M.ContinueStatement = Statement:clone {
    kind = "ContinueStatement",

    __ctor = function(self, line)
        self.line = line
        Node.__ctor(self)
    end
}

M.LabelStatement = Statement:clone {
    kind = "LabelStatement",

    properties = {
        label = { type = "literal", value = "string" }
    },

    __ctor = function(self, name, line)
        self.label = name
        self.line = line
        Node.__ctor(self)
    end
}

M.ExpressionStatement = Statement:clone {
    kind = "ExpressionStatement",

    properties = {
        expression = {
            type = "choice",
            values = { "Statement", "Expression" }
        }
    },

    __ctor = function(self, expr, line)
        self.expression = expr
        self.line = line
        Node.__ctor(self)
    end
}

M.IfStatement = Statement:clone {
    kind = "IfStatement",

    properties = {
        tests = {
            type = "list",
            kind = "Expression"
        },
        cons = {
            type = "list",
            kind = { type = "list", kind = "Statement" }
        },
        alternate = {
            type = "list",
            kind = "Statement",
            optional = true
        }
    },

    __ctor = function(self, tests, cons, else_branch, line)
        self.tests = tests
        self.cons = cons
        self.alternate = else_branch
        self.line = line
        Node.__ctor(self)
    end
}

M.DoStatement = Statement:clone {
    kind = "DoStatement",

    properties = {
        body = {
            type = "list",
            kind = "Statement"
        }
    },

    __ctor = function(self, body, line)
        self.body = body
        self.line = line
        Node.__ctor(self)
    end
}

M.WhileStatement = Statement:clone {
    kind = "WhileStatement",

    properties = {
        test = "Expression",
        body = {
            type = "list",
            kind = "Statement"
        }
    },

    __ctor = function(self, test, body, line)
        self.test = test
        self.body = body
        self.line = line
        Node.__ctor(self)
    end
}

M.RepeatStatement = Statement:clone {
    kind = "RepeatStatement",

    properties = {
        test = "Expression",
        body = {
            type = "list",
            kind = "Statement"
        }
    },

    __ctor = function(self, test, body, line)
        self.test = test
        self.body = body
        self.line = line
        Node.__ctor(self)
    end
}

local ForInit = Expression:clone {
    kind = "ForInit",

    properties = {
        id = "Identifier",
        value = "Expression"
    },

    __ctor = function(self, var, init, line)
        self.id = var
        self.value = init
        self.line = line
        Node.__ctor(self)
    end
}

M.ForStatement = Statement:clone {
    kind = "ForStatement",

    properties = {
        init = "ForInit",
        last = "Expression",
        step = {
            type = "node",
            kind = "Expression",
            optional = true
        },
        body = {
            type = "list",
            kind = "Statement"
        }
    },

    __ctor = function(self, var, init, last, step, body, line)
        self.init = ForInit(var, init, line)
        self.last = last
        self.step = step
        self.body = body
        self.line = line
        Node.__ctor(self)
    end
}

local ForNames = Expression:clone {
    kind = "ForNames",

    properties = {
        names = {
            type = "list",
            kind = "Identifier"
        }
     },

    __ctor = function(self, vars, line)
        self.names = vars
        self.line = line
        Node.__ctor(self)
    end
}

M.ForInStatement = Statement:clone {
    kind = "ForInStatement",

    properties = {
        namelist = "ForNames",
        explist = {
            type = "list",
            kind = "Expression"
        },
        body = {
            type = "list",
            kind = "Statement"
        }
    },

    __ctor = function(self, vars, exps, body, line)
        self.namelist = ForNames(vars, line)
        self.explist = exps
        self.body = body
        self.line = line
        Node.__ctor(self)
    end
}

M.GotoStatement = Statement:clone {
    kind = "GotoStatement",

    properties = {
        label = { type = "literal", value = "string" }
    },

    __ctor = function(self, name, line)
        self.label = name
        self.line = line
        Node.__ctor(self)
    end
}

M.ImportStatement = Statement:clone {
    kind = "ImportStatement",

    properties = {
        varname = {
            optional = true,
            type = "node",
            kind = "Identifier"
        },
        modname = "Literal",
        fields  = {
            optional = true,
            type = "list",
            kind = {
                type = "list",
                kind = {
                    type = "choice",
                    values = { { type = "literal", value = "string" },
                               "Identifier" }
                }
            }
        }
    },

    __ctor = function(self, varname, modname, fields, line)
        self.varname = varname
        self.modname = Literal(modname)
        self.fields = fields
        Node.__ctor(self)
    end
}

return M
