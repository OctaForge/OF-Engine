--[[
    OctaScript

    Copyright (C) 2014 Daniel "q66" Kolesa

    See COPYING.txt for licensing.

    Based on LuaJIT Language Toolkit written by Francesco Abbate:
    https://github.com/franko/luajit-lang-toolkit
]]

local bc   = require("octascript.bytecode")
local util = require("octascript.util")
local bit  = require("bit")

local ID = 0
local genid = function()
   ID = ID + 1
   return '__' .. ID
end

-- constant folding for numbers

local const_eval

local binop_apply = function(op, lhs, rhs)
    if     op == "+"   then return lhs + rhs
    elseif op == "-"   then return lhs - rhs
    elseif op == "*"   then return lhs * rhs
    elseif op == "/"   then return (lhs ~= 0 or rhs ~= 0) and (lhs / rhs) or nil
    elseif op == "%"   then return lhs % rhs
    elseif op == "**"  then return lhs ^ rhs
    elseif op == "|"   then return bit.bor(lhs, rhs)
    elseif op == "&"   then return bit.band(lhs, rhs)
    elseif op == "^"   then return bit.bxor(lhs, rhs)
    elseif op == "<<"  then return bit.lshift(lhs, rhs)
    elseif op == ">>"  then return bit.rshift(lhs, rhs)
    elseif op == ">>>" then return bit.arshift(lhs, rhs)
    end
end

local Rules = {
    Literal = function(node)
        if type(node.value) == "number" then return node.value end
    end,

    BinaryExpression = function(node)
        local op  = node.operator
        local lhs = const_eval(node.left)
        if lhs then
            local rhs = const_eval(node.right)
            if rhs then
                return binop_apply(op, lhs, rhs)
            end
        end
    end,

    UnaryExpression = function(node)
        if node.operator == "-" then
            local v = const_eval(node.argument)
            if v then return -v end
        elseif node.operator == "~" then
            local v = const_eval(node.argument)
            if v then return bit.bnot(v) end
        end
    end
}

const_eval = function(node)
    local rule = Rules[node.kind]
    if rule then
        return rule(node)
    end
end

local const_eval_try = function(node)
    local const = const_eval(node)
    if const then
        return true, const
    elseif node.kind == "Literal" then
        local t = type(node.value)
        return (t == "string" or t == "boolean" or t == "nil"), node.value
    else
        return false
    end
end

-- constant folding for booleans

local bool_const_eval

local bool_apply = function(op, lhs, rhs)
    if     op == "&&" then return lhs and rhs
    elseif op == "||" then return lhs or  rhs
    end
end

local BoolRules = {
    Literal = function(node)
        if type(node.value) == "boolean" then return node.value end
    end,

    BinaryExpression = function(node)
        local op = node.operator
        local lhs = bool_const_eval(node.left)
        if lhs ~= nil then
            local rhs = bool_const_eval(node.right)
            if rhs then
                return bool_apply(op, lhs, rhs)
            end
        end
    end,

    UnaryExpression = function(node)
        if node.operator == "!" then
            local v = bool_const_eval(node.argument)
            if v ~= nil then return not v end
        end
    end
}

bool_const_eval = function(node)
    local  rule = BoolRules[node.kind]
    if rule then
        return rule(node)
    end
end

-- comparison operators with corresponding instruction.
-- the boolean value indicate if the operands should be swapped.
local cmpop = {
    ["<" ] = { "LT", false },
    [">" ] = { "LT", true  },
    ["<="] = { "LE", false },
    [">="] = { "LE", true  },
    ["=="] = { "EQ", false },
    ["!="] = { "NE", false },
}

-- the same of above but for the inverse tests
local cmpopinv = {
    ["<" ] = { "GE", false },
    [">" ] = { "GE", true  },
    ["<="] = { "GT", false },
    [">="] = { "GT", true  },
    ["=="] = { "NE", false },
    ["!="] = { "EQ", false },
}

local lang_error = function(msg, chunkname, line)
    error(string.format("OFS_ERROR%s:%d: %s", chunkname, line, msg), 0)
end

local MULTIRES = -1

-- this should be considered like binary values to perform
-- bitfield operations
local EXPR_RESULT_TRUE, EXPR_RESULT_FALSE, EXPR_RESULT_BOTH = 1, 2, 3

-- Infix arithmetic instructions
local EXPR_EMIT_VN   = { value = true, number = true }

-- USETx, ISEQx and ISNEx instructions
local EXPR_EMIT_VSNP = { value = true, string = true, number = true, primitive = true }

-- TGETx/TSETx instructions
local EXPR_EMIT_VSB  = { value = true, string = true, byte = true }

local store_bit = function(cond)
    return (cond and cond ~= util.null) and EXPR_RESULT_TRUE or EXPR_RESULT_FALSE
end

local xor = function(lhs, rhs)
    return (lhs and not rhs) or (not lhs and rhs)
end

local is_local_var = function(ctx, node)
    if node.kind == "Identifier" then
        local info, uval = ctx:lookup(node.name)
        if info and not uval then
            return info.idx
        end
    end
end

local mov_toreg = function(ctx, dest, src)
    if dest ~= src then
        ctx:op_move(dest, src)
    end
end

-- Conditionally move "src" to "dest" and jump to given target
-- if "src" evaluate to true/false according to "cond".
local cond_mov_toreg = function(ctx, cond, dest, src, jump_label, jreg)
    if dest ~= src then
        ctx:op_testmov(cond, dest, src, jump_label, jreg)
    else
        ctx:op_test(cond, src, jump_label, jreg)
    end
end

local is_byte_number = function(v)
    return type(v) == "number" and v % 1 == 0 and v >= 0 and v < 256
end

local emit_tdup = function(self, dest, ins)
    local kidx, t = self.ctx:new_table_template()
    ins:rewrite(bc.BC.TDUP, dest, kidx)
    return t
end

local is_kint = function(x)
    return x % 1 == 0 and x >= 0 and x < 2^31
end

-- Operations that admit instructions in the form ADDVV, ADDVN, ADDNV
local dirop = {
    ["+"] = "ADD",
    ["*"] = "MUL",
    ["-"] = "SUB",
    ["/"] = "DIV",
    ["%"] = "MOD",
}

-- Bit operations
local bitop = {
    ["|"  ] = "bor",
    ["&"  ] = "band",
    ["^"  ] = "bxor",
    ["<<" ] = "lshift",
    [">>>"] = "rshift",
    [">>" ] = "arshift"
}

local gen_ident = function(self, name, dest)
    local var, uval = self.ctx:lookup(name)
    if var then
        if uval then
            -- Ensure variable is marked as upvalue in proto in take
            -- the upvalue index.
            local uv = self.ctx:upval(name)
            self.ctx:op_uget(dest, uv)
        else
            mov_toreg(self.ctx, dest, var.idx)
        end
    elseif name == "__rt_core" or self.globals == true
    or (self.globals and self.globals[name]) then
        self.ctx:op_gget(dest, name)
    else
        lang_error("undeclared variable '" .. name .. "'", self.chunkname,
            self.ctx.currline)
    end
end

local gen_rt = function(self, name, dest)
    gen_ident(self, "__rt_" .. name, dest)
end

-- ExpressionRule's entries take a node and a destination register (dest)
-- used to store the result. At the end of the call no new registers are
-- marked as used.
-- ExpressionRule functions return nothing or a boolean value to indicate if
-- a the expression terminate with a tail call instruction.
local ExpressionRule = {
    Literal = function(self, node, dest)
        if node.value == util.null and type(node.value) == "cdata" then
            gen_rt(self, "null", dest)
        else
            self.ctx:op_load(dest, node.value)
        end
    end,

    Identifier = function(self, node, dest)
        local name = node.name
        gen_ident(self, node.name, dest)
    end,

    Vararg = function(self, node, dest)
        self.ctx:op_varg(dest, 1)
    end,

    Table = function(self, node, dest)
        if #node.array_entries == 0 and #node.hash_keys == 0 then
            self.ctx:op_tnew(dest, 0, 0)
            return
        end

        local free = self.ctx.freereg
        local ins = self.ctx:op_tnew(free, 0, 0)
        self.ctx:nextreg()
        local t
        local vtop = self.ctx.freereg
        local narray, nhash = 0, 0
        local zeroarr = 0
        for k = 1, #node.array_entries do
            local expr = node.array_entries[k]
            local is_const, expr_val = const_eval_try(expr)
            if is_const then
                if not t then t = emit_tdup(self, free, ins) end
                t.array[k] = expr_val
                narray = k + 1
            else
                local ktag, kval
                if k < 256 then
                    ktag, kval = "B", k
                else
                    ktag, kval = "V", self.ctx:nextreg()
                    self.ctx:op_load(kval, k)
                end
                local v = self:expr_toanyreg(expr)
                self.ctx:op_tset(free, ktag, kval, v)
                self.ctx.freereg = vtop
            end
        end

        for i = 1, #node.hash_keys do
            local key, value = node.hash_keys[i], node.hash_values[i]
            local k_is_const, kval = const_eval_try(key)
            local v_is_const, vval = const_eval_try(value)
            if k_is_const and kval ~= nil and v_is_const then
                if type(kval) == "number" and is_kint(kval) then
                    if not t then t = emit_tdup(self, free, ins) end
                    t.array[kval] = vval
                    narray = math.max(narray, kval + 1)
                    if kval == 0 then zeroarr = 1 end
                else
                    nhash = nhash + 1
                    if not t then t = emit_tdup(self, free, ins) end
                    t.hash_keys[nhash] = kval
                    t.hash_values[nhash] = vval
                end
            else
                local ktag, kval = self:expr_toanyreg_tagged(key, EXPR_EMIT_VSB)
                local v = self:expr_toanyreg(value)
                self.ctx:op_tset(free, ktag, kval, v)
                self.ctx.freereg = vtop
            end
        end

        if t then
            t.narray, t.nhash = narray, nhash
        else
            local na = #node.array_entries + zeroarr
            local nh = #node.hash_keys - zeroarr
            local sz = ins.tnewsize(na > 0 and na or nil, nh)
            ins:rewrite(bc.BC.TNEW, free, sz)
        end

        mov_toreg(self.ctx, dest, free)

        self.ctx.freereg = free
    end,

    Array = function(self, node, dest)
        local fields = node.fields
        local szhint = #fields

        local free = self.ctx.freereg

        gen_rt(self, "array", free)
        self.ctx:nextreg()

        local mexp
        if node.multi_expr then
            mexp = fields[#fields]
            szhint = szhint - 1
            fields[#fields] = nil
        end

        local treg = self.ctx.freereg
        local ins = self.ctx:op_tnew(treg, 0, 0)
        self.ctx:nextreg()

        local narray = 0

        local t
        local vtop = self.ctx.freereg

        for k = 1, szhint do
            local expr = fields[k]
            local is_const, expr_val = const_eval_try(expr)
            if is_const then
                if not t then t = emit_tdup(self, treg, ins) end
                t.array[k - 1] = expr_val
                narray = k
            else
                local ktag, kval
                if (k - 1) < 256 then
                    ktag, kval = "B", k - 1
                else
                    ktag, kval = "V", self.ctx:nextreg()
                    self.ctx:op_load(kval, k - 1)
                end
                local v = self:expr_toanyreg(expr)
                self.ctx:op_tset(treg, ktag, kval, v)
                self.ctx.freereg = vtop
            end
        end

        if t then
            t.narray, t.nhash = narray, 0
        elseif szhint > 0 then
            local sz = ins.tnewsize(#fields, 0)
            ins:rewrite(bc.BC.TNEW, treg, sz)
        end

        self.ctx:op_load(self.ctx:nextreg(), szhint)
        local mres = false
        if mexp then
            mres = self:expr_tomultireg(mexp, MULTIRES)
            self.ctx:nextreg()
        end
        self.ctx.freereg = free
        if mres then
            self.ctx:op_callm(free, 1, 2)
        else
            self.ctx:op_call(free, 1, 2)
        end
        mov_toreg(self.ctx, dest, free)
    end,

    Enum = function(self, node, dest)
        if #node.keys == 0 then
            self.ctx:op_tnew(dest, 0, 0)
            return
        end

        local free = self.ctx.freereg
        local ins = self.ctx:op_tnew(free, 0, #node.keys)
        self.ctx:nextreg()
        local prev_reg
        for i = 1, #node.keys do
            local v = node.values[i] and self:expr_toanyreg(node.values[i])
                                      or self.ctx.freereg
            if not node.values[i] then
                self.ctx:op_infix("ADD", v, "V", prev_reg, "N",
                    self.ctx:const(1))
            end
            prev_reg = v
            local kt, kv = self:property_tagged(node.keys[i])
            self.ctx:op_tset(free, kt, kv, v)
            self.ctx:newvar(node.keys[i], v)
            self.ctx:nextreg()
        end
        mov_toreg(self.ctx, dest, free)
        self.ctx.freereg = free
    end,

    ConcatenateExpression = function(self, node, dest)
        local free = self.ctx.freereg
        for i = 1, #node.terms do
            self:expr_tonextreg(node.terms[i])
        end
        self.ctx.freereg = free
        self.ctx:op_cat(dest, free, free + #node.terms - 1)
    end,

    BinaryExpression = function(self, node, dest, jreg)
        local free = self.ctx.freereg
        local o = node.operator
        if cmpop[o] then
            local l = genid()
            self:test_emit(node, l, jreg, false, EXPR_RESULT_BOTH, dest)
            self.ctx:here(l)
        elseif dirop[o] then
            local atag, a = self:expr_toanyreg_tagged(node.left, EXPR_EMIT_VN)
            local btag, b = self:expr_toanyreg_tagged(node.right, EXPR_EMIT_VN)
            if atag == "N" and btag == "N" then
                -- handle "nan" values here the same way LuaJIT does
                -- usually, both operands will always be 0 when both constant
                -- but re-check just to make sure, in order to trigger the
                -- assert when there's a bug in the generator
                local aval = const_eval(node.left)
                local bval = const_eval(node.right)
                if aval == 0 and bval == 0 then
                    atag, a = "V", self.ctx.freereg
                    self.ctx:op_load(self.ctx:nextreg(), 0)
                else
                    assert(false, "operands are both constants")
                end
            end
            self.ctx.freereg = free
            self.ctx:op_infix(dirop[o], dest, atag, a, btag, b)
        elseif bitop[o] then
            gen_rt(self, bitop[o], free)
            self.ctx:nextreg()
            self:expr_tonextreg(node.left)
            self:expr_tonextreg(node.right)
            self.ctx.freereg = free
            self.ctx:op_call(free, 1, 2)
            mov_toreg(self.ctx, dest, free)
        else
            local a = self:expr_toanyreg(node.left)
            local b = self:expr_toanyreg(node.right)
            self.ctx.freereg = free
            if o == "**" then
                self.ctx:op_pow(dest, a, b)
            else
                error("bad binary operator: "..o, 2)
            end
        end
    end,

    UnaryExpression = function(self, node, dest, jreg)
        local free = self.ctx.freereg
        local o = node.operator
        if o == "~" then
            gen_rt(self, "bnot", free)
            self.ctx:nextreg()
            self:expr_tonextreg(node.argument)
            self.ctx.freereg = free
            self.ctx:op_call(free, 1, 1)
            mov_toreg(self.ctx, dest, free)
            return
        end
        local a = self:expr_toanyreg(node.argument)
        self.ctx.freereg = free
        if o == "-" then
            self.ctx:op_unm(dest, a)
        --elseif o == "!" then
        --    self.ctx:op_not(dest, a)
        elseif o == "!" then
            local l, al1, al2 = genid(), genid(), genid()
            self.ctx:op_comp("NE", a, "P", self.ctx:kpri(false), al1, free, false)
            self.ctx:op_load(dest, true)
            self.ctx:jump(l, jreg)
            self.ctx:here(al1)
            self.ctx.freereg = free
            self.ctx:op_comp("EQ", a, "P", self.ctx:kpri(nil), al2, free, false)
            self.ctx:op_load(dest, false)
            self.ctx:jump(l, jreg)
            self.ctx:here(al2)
            self.ctx.freereg = free
            self.ctx:op_load(dest, true)
            self.ctx:here(l)
        else
            error("bad unary operator: "..o, 2)
        end
    end,

    LogicalExpression = function(self, node, dest, jreg)
        local negate = (node.operator == "||")
        local lstore = store_bit(negate)
        local l = genid()
        self:test_emit(node.left, l, jreg, negate, lstore, dest)
        self:expr_toreg(node.right, dest, jreg)
        self.ctx:here(l)
    end,

    IfExpression = function(self, node, dest, jreg)
        local tl, fl = genid(), genid()
        self:test_emit(node.cond, fl, jreg, false, 0, dest)
        self:expr_toreg(node.texpr, dest, jreg)
        self.ctx:jump(tl, jreg)
        self.ctx:here(fl)
        self:expr_toreg(node.fexpr, dest, jreg)
        self.ctx:here(tl)
    end,

    MemberExpression = function(self, node, dest)
        local free = self.ctx.freereg
        local lhs = self:lhs_expr_emit(node)
        self.ctx.freereg = free
        self.ctx:op_tget(dest, lhs.target, lhs.key_type, lhs.key)
    end,

    FunctionExpression = function(self, node, dest)
        local free = self.ctx.freereg
        local child = self.ctx:child(node.firstline, node.lastline)
        self.ctx = child
        for i=1, #node.params do
            if node.params[i].kind == "Vararg" then
                self.ctx.flags = bit.bor(self.ctx.flags, bc.Proto.VARARG)
            else
                self.ctx:param(node.params[i].name)
            end
        end
        self:block_emit(node.body)
        self:close_proto(node.lastline)

        self.ctx = self.ctx:parent()
        self.ctx.freereg = free
        self.ctx:line(node.lastline)
        self.ctx:op_fnew(dest, child.idx)
    end,

    ParenthesizedExpression = function(self, node, dest, jreg)
        self:expr_toreg(node.expression, dest, jreg)
    end,

    ImportExpression = function(self, node, dest)
        local free = self.ctx.freereg
        gen_rt(self, "import", free)
        self.ctx:nextreg()
        self:expr_tonextreg(node.modname)
        self.ctx.freereg = free
        self.ctx:op_call(free, 1, 1)
        mov_toreg(self.ctx, dest, free)
    end,

    TypeofExpression = function(self, node, dest)
        local free = self.ctx.freereg
        gen_rt(self, "type", free)
        self.ctx:nextreg()
        self:expr_tonextreg(node.expression)
        self.ctx.freereg = free
        self.ctx:op_call(free, 1, 1)
        mov_toreg(self.ctx, dest, free)
    end,

    AssignmentExpression = function(self, node, dest)
        local free = self.ctx.freereg
        local lhs = self:lhs_expr_emit(node.left)
        local exp = self:expr_tonextreg(node.right)
        self:assign(lhs, exp)
        self.ctx.freereg = free
        mov_toreg(self.ctx, dest, exp)
    end
}

ExpressionRule.FunctionDeclaration = ExpressionRule.FunctionExpression

local LHSExpressionRule = {
    Identifier = function(self, node)
        local info, uval = self.ctx:lookup(node.name)
        if uval then
            -- Ensure variable is marked as upvalue in proto and take
            -- upvalue index.
            info.mutable = true
            local uv = self.ctx:upval(node.name)
            return {tag = "upval", uv = uv}
        elseif info then
            info.mutable = true
            return {tag = "local", target = info.idx}
        else
            return {tag = "global", name = node.name}
        end
    end,

    MemberExpression = function(self, node)
        local target = self:expr_toanyreg(node.object)
        local key_type, key
        if node.computed then
            key_type, key = self:expr_toanyreg_tagged(node.property,
                EXPR_EMIT_VSB)
        else
            key_type, key = self:property_tagged(node.property.name)
        end
        return { tag = "member", target = target, key = key,
            key_type = key_type }
    end
}

local emit_call_ins = function(self, free, narg, want, mres, use_tail)
    if mres then
        if use_tail then
            self.ctx:close_uvals()
            self.ctx:op_callmt(free, narg - 1)
        else
            self.ctx:op_callm(free, want, narg - 1)
        end
    else
        if use_tail then
            self.ctx:close_uvals()
            self.ctx:op_callt(free, narg)
        else
            self.ctx:op_call(free, want, narg)
        end
    end
end

local emit_call_expression = function(self, node, want, use_tail, use_self)
    local free = self.ctx.freereg

    if use_self then
        local obj = self:expr_toanyreg(node.receiver)
        self.ctx:op_move(free + 1, obj)
        self.ctx:setreg(free + 1)
        local method_type, method = self:property_tagged(node.method.name)
        self.ctx:op_tget(free, obj, method_type, method)
        self.ctx:nextreg()
    else
        self:expr_tonextreg(node.callee)
    end

    local narg = #node.arguments
    for i=1, narg - 1 do
        self:expr_tonextreg(node.arguments[i])
    end
    local mres = false
    if narg > 0 then
        local lastarg = node.arguments[narg]
        mres = self:expr_tomultireg(lastarg, MULTIRES)
        self.ctx:nextreg()
    end

    if use_self then narg = narg + 1 end
    self.ctx.freereg = free

    emit_call_ins(self, free, narg, want, mres, use_tail)

    return want == MULTIRES, use_tail
end

-- MultiExprRule's entries take a node and a number of wanted results (want)
-- and an optional boolean argument "tail" that indicate to emit tail call
-- if possible.
-- The argument "want" can also be MULTIRES to indicate that the caller want
-- as many results as the instructions returns.
-- The code will store on the stack (starting from freereg) the number of
-- wanted results.
-- Return a first boolean value to indicate if many results are generated.
-- A second boolean value indicate if a tail call was actually done.
local MultiExprRule = {
    Vararg = function(self, node, want)
        self.ctx:op_varg(self.ctx.freereg, want)
        return true, false -- Multiple results, no tail call.
    end,

    CallExpression = function(self, node, want, tail)
        return emit_call_expression(self, node, want, tail, false)
    end,

    SendExpression = function(self, node, want, tail)
        return emit_call_expression(self, node, want, tail, true)
    end,

    TryExpression = function(self, node, want, tail)
        local free = self.ctx.freereg

        local call = node.expression
        local handler = node.handler

        gen_rt(self, handler and "xpcall" or "pcall", free)
        self.ctx:nextreg()

        local base = self.ctx.freereg
        local use_self = call.kind == "SendExpression"

        if use_self then
            local obj = self:expr_toanyreg(call.receiver)
            if handler then
                self:expr_toreg(handler, base + 1)
                self.ctx:op_move(base + 2, obj)
                self.ctx:setreg(base + 2)
            else
                self.ctx:op_move(base + 1, obj)
                self.ctx:setreg(base + 1)
            end
            local method_type, method = self:property_tagged(call.method.name)
            self.ctx:op_tget(base, obj, method_type, method)
            self.ctx:nextreg()
        else
            self:expr_tonextreg(call.callee)
            if handler then
                self:expr_tonextreg(handler)
            end
        end

        local narg = #call.arguments
        for i=1, narg - 1 do
            self:expr_tonextreg(call.arguments[i])
        end
        local mres = false
        if narg > 0 then
            local lastarg = call.arguments[narg]
            mres = self:expr_tomultireg(lastarg, MULTIRES)
            self.ctx:nextreg()
        end

        narg = narg + 1
        if use_self then narg = narg + 1 end
        if handler  then narg = narg + 1 end
        self.ctx.freereg = free

        emit_call_ins(self, free, narg, want, mres, tail)

        return want == MULTIRES, tail
    end
}

local compare_op = function(negate, op)
    local optbl = negate and cmpop or cmpopinv
    local e = optbl[op]
    return e[1], e[2]
end

-- Return true IFF the variable "store" has the EXPR_RESULT_FALSE bit
-- set. If "negate" is true check the EXPR_RESULT_TRUE bit instead.
local has_branch = function(store, negate)
    return bit.band(store, store_bit(negate)) ~= 0
end

local TestRule = {
    Literal = function(self, node, jmp, jreg, negate, store, dest)
        local free = self.ctx.freereg
        local v = node.value
        if bit.band(store, store_bit(v)) ~= 0 then
            self:expr_toreg(node, dest)
        else
            jreg = self.ctx.freereg
        end
        if xor(negate, not v) then
            self.ctx:jump(jmp, jreg)
        end
    end,

    BinaryExpression = function(self, node, jmp, jreg, negate, store, dest)
        local o = node.operator
        if cmpop[o] then
            local free = self.ctx.freereg
            local atag, a, btag, b
            if o == "==" or o == "!=" then
                atag, a = self:expr_toanyreg_tagged(node.left, EXPR_EMIT_VSNP)
                if atag == "V" then
                    btag, b = self:expr_toanyreg_tagged(node.right,
                        EXPR_EMIT_VSNP)
                else
                    btag, b = atag, a
                    atag, a = "V", self:expr_toanyreg(node.right)
                end
            else
                a = self:expr_toanyreg(node.left)
                b = self:expr_toanyreg(node.right)
            end
            self.ctx.freereg = free
            local use_imbranch = has_branch(store, negate)
            if use_imbranch then
                local test, swap = compare_op(not negate, o)
                local altlabel = genid()
                self.ctx:op_comp(test, a, btag, b, altlabel, free, swap)
                self.ctx:op_load(dest, negate)
                self.ctx:jump(jmp, jreg)
                self.ctx:here(altlabel)
                self.ctx.freereg = free
            else
                local test, swap = compare_op(negate, o)
                self.ctx:op_comp(test, a, btag, b, jmp, free, swap)
            end
            if has_branch(store, not negate) then
                self.ctx:op_load(dest, not negate)
            end
        else
            self:expr_test(node, jmp, jreg, negate, store, dest)
        end
    end,

    UnaryExpression = function(self, node, jmp, jreg, negate, store, dest)
        --if node.operator == "!" and store == 0 then
        --    self:test_emit(node.argument, jmp, jreg, not negate)
        --else
            self:expr_test(node, jmp, jreg, negate, store,
                dest or self.ctx.freereg)
        --end
    end,

    LogicalExpression = function(self, node, jmp, jreg, negate, store, dest)
        local or_operator = (node.operator == "||")
        local lstore = bit.band(store, store_bit(or_operator))
        local imbranch = xor(negate, or_operator)
        if imbranch then
            local templ = genid()
            self:test_emit(node.left, templ, jreg, not negate, lstore, dest)
            self:test_emit(node.right, jmp, jreg, negate, store, dest)
            self.ctx:here(templ)
        else
            self:test_emit(node.left, jmp, jreg, negate, lstore, dest)
            self:test_emit(node.right, jmp, jreg, negate, store, dest)
        end
    end,

    IfExpression = function(self, node, jmp, jreg, negate, store, dest)
         local tl, fl = genid(), genid()
         local lstore = store_bit(negate)
         self:test_emit(node.cond, fl, jreg, false, 0, dest)
         self:test_emit(node.texpr, jmp, jreg, negate, lstore, dest)
         self.ctx:jump(tl, jreg)
         self.ctx:here(fl)
         self:test_emit(node.fexpr, jmp, jreg, negate, lstore, dest)
         self.ctx:here(tl)
    end
}

-- Eliminate write-after-read hazards for local variable assignment.
-- Implement the same approach found in lj_parse.c from luajit.
-- Check left-hand side against variable register "reg".
local assign_hazard = function(self, lhs, reg)
    local tmp = self.ctx.freereg -- Rename to this temp. register (if needed).
    local hazard = false
    for i = #lhs, 1, -1 do
        if lhs[i].tag == "member" then
            if lhs[i].target == reg then -- t[i], t = 1, 2
                hazard = true
                lhs[i].target = tmp
            end
            if lhs[i].key_type == "V" and
                lhs[i].key == reg then -- t[i], i = 1, 2
                hazard = true
                lhs[i].key = tmp
            end
        end
    end
    if hazard then
        self.ctx:nextreg()
        self.ctx:op_move(tmp, reg)
    end
end

local StatementRule = {
    FunctionDeclaration = function(self, node)
        local path = node.id
        -- transform node
        local enode = node.decorator or node
        if not node.locald then
            if path.kind == "Identifier" then
                self.ctx:newvar(path.name, self:expr_tonextreg(enode))
            else
                self:expr_tolhs(self:lhs_expr_emit(path), enode)
            end
        else
            -- We avoid calling "lhs_expr_emit" on "path" because
            -- it would mark the variable as mutable.
            local vinfo = self.ctx:newvar(path.name)
            self:expr_toreg(enode, vinfo.idx)
            local pc = #self.ctx.code + 1
            vinfo.startpc = pc
            vinfo.endpc = pc
        end
    end,

    CallExpression = function(self, node)
        self:expr_tomultireg(node, 0, false)
    end,

    SendExpression = function(self, node)
        self:expr_tomultireg(node, 0, false)
    end,

    TryExpression = function(self, node)
        self:expr_tomultireg(node, 0, false)
    end,

    LabelStatement = function(self, node)
        local ok, label = self.ctx:goto_label(node.label)
        if not ok then
            lang_error(label, self.chunkname, node.line)
        end
    end,

    GotoStatement = function(self, node)
        self.ctx:goto_jump(node.label, node.line)
    end,

    DoStatement = function(self, node)
        self:block_enter()
        self:block_emit(node.body)
        self:block_leave(node.body.lastline)
    end,

    IfStatement = function(self, node, root_exit)
        local free = self.ctx.freereg
        local ncons = #node.tests
        -- Count the number of branches, including the "else" branch.
        local count = node.alternate and ncons + 1 or ncons
        local local_exit = count > 1 and genid()
        -- Set the exit point to the extern exit if given or set to local
        -- exit (potentially false).
        local exit = root_exit or local_exit

        for i = 1, ncons do
            local test, block = node.tests[i], node.cons[i]
            local next_test = genid()
            -- Set the exit point to jump on at the end of for this block.
            -- If this is the last branch (count == 1) set to false.
            local bexit = count > 1 and exit

            self:test_emit(test, next_test, free)

            self:block_enter()
            self:block_emit(block, bexit)
            self:block_leave(block.lastline, bexit)

            self.ctx:here(next_test)
            count = count - 1
        end

        if node.alternate then
            self:block_enter()
            self:block_emit(node.alternate)
            self:block_leave(node.alternate.lastline)
        end
        if exit and exit == local_exit then
            self.ctx:here(exit)
        end
        self.ctx.freereg = free
    end,

    ExpressionStatement = function(self, node)
        return self:emit(node.expression)
    end,

    LocalDeclaration = function(self, node)
        local nvars = #node.names
        local nexps = #node.expressions
        local base = self.ctx.freereg
        local slots = nvars
        for i = 1, nexps - 1 do
            if slots == 0 then break end
            self:expr_tonextreg(node.expressions[i])
            slots = slots - 1
        end

        if slots > 0 then
            if nexps > 0 then
                self:expr_tomultireg(node.expressions[nexps], slots)
            else
                self.ctx:op_nils(base, slots)
            end
            self.ctx:nextreg(slots)
        end

        for i=1, nvars do
            local lhs = node.names[i]
            self.ctx:newvar(lhs.name, base + (i - 1))
        end
    end,

    LocalMemberDeclaration = function(self, node)
        local nvars = #node.names

        local base = self.ctx.freereg
        local tbase = base + nvars
        self.ctx:setreg(tbase)
        self:expr_toreg(node.expression, tbase)

        self.ctx.freereg = base
        for i = 1, nvars do
            self.ctx:op_tget(base + (i - 1), tbase,
                self:property_tagged(node.names[i].name))
        end
        self.ctx.freereg = base
        for i = 1, nvars do
            self.ctx:newvar(node.names[i].name, base + (i - 1))
            self.ctx:nextreg()
        end
    end,

    AssignmentStatement = function(self, node)
        local free = self.ctx.freereg
        local nvars = #node.left
        local nexps = #node.right

        local lhs = {}
        for i = 1, nvars do
            local va = self:lhs_expr_emit(node.left[i])
            if va.tag == "local" then
                assign_hazard(self, lhs, va.target)
            end
            lhs[i] = va
        end

        local slots = nvars
        local exprs = {}
        for i=1, nexps - 1 do
            if slots == 0 then break end
            -- LuaJIT compatibility:
            -- Use a temporary register even the LHS is not an immediate local
            -- variable.
            local use_reg = true
            -- local use_reg = is_local_var(self.ctx, node.left[i])
            if use_reg then
                exprs[i] = self:expr_tonextreg(node.right[i])
            else
                exprs[i] = self:expr_toanyreg(node.right[i])
            end
            slots = slots - 1
        end

        local i = nexps
        if slots == 1 then
            -- Case where (nb of expression) >= (nb of variables).
            self:expr_tolhs(lhs[i], node.right[i])
        else
            -- Case where (nb of expression) < (nb of variables). In this case
            -- we cosider that the last expression can generate multiple values.
            local exp_base = self.ctx.freereg
            self:expr_tomultireg(node.right[i], slots)
            for k = slots - 1, 0, -1 do
                self:assign(lhs[i + k], exp_base + k)
            end
        end

        for i = nvars - slots, 1, -1 do
            self:assign(lhs[i], exprs[i])
        end

        self.ctx.freereg = free
    end,

    WhileStatement = function(self, node)
        local free = self.ctx.freereg
        local loop, exit, cont = genid(), genid(), genid()
        self:loop_enter(exit, free, cont)
        self.ctx:here(loop)
        self:test_emit(node.test, exit, free)
        self.ctx:loop(exit)
        self:block_emit(node.body)
        self.ctx:here(cont)
        self.ctx:jump(loop, free)
        self.ctx:here(exit)
        self:loop_leave(node.lastline)
        self.ctx.freereg = free
    end,

    RepeatStatement = function(self, node)
        local free = self.ctx.freereg
        local loop, exit, cont = genid(), genid(), genid()
        self:loop_enter(exit, free, cont)
        self.ctx:here(loop)
        self.ctx:loop(exit)
        self:block_emit(node.body)
        self.ctx:here(cont)
        self:test_emit(node.test, loop, free)
        self.ctx:here(exit)
        self:loop_leave(node.lastline)
        self.ctx.freereg = free
    end,

    BreakStatement = function(self)
        local base, exit, need_uclo = self.ctx:current_loop()
        self.ctx:scope_jump(exit, base, need_uclo)
        self.ctx.scope.need_uclo = false
    end,

    ContinueStatement = function(self)
        local base, cont, need_uclo = self.ctx:current_loop(true)
        self.ctx:scope_jump(cont, base, need_uclo)
        self.ctx.scope.need_uclo = false
    end,

    ForStatement = function(self, node)
        local free = self.ctx.freereg
        local exit, cont = genid(), genid()
        local init = node.init
        local name = init.id.name
        local line = node.line

        self:expr_tonextreg(init.value)
        self:expr_tonextreg(node.last)
        if node.step then
            self:expr_tonextreg(node.step)
        else
            self.ctx:op_load(self.ctx.freereg, 1)
            self.ctx:nextreg()
        end
        local forivinfo = self.ctx:forivars(0x01)
        local loop = self.ctx:op_fori(free)
        self:loop_enter(exit, free, cont)
        self.ctx:newvar(name)
        self:block_enter()
        self:block_emit(node.body)
        self:block_leave()
        self.ctx:here(cont)
        self:loop_leave(node.body.lastline)
        self.ctx:op_forl(free, loop)
        self.ctx:setpcline(line)
        forivinfo.endpc = #self.ctx.code
        self.ctx:here(exit)
        self.ctx.freereg = free
    end,

    ForInStatement = function(self, node)
        local free = self.ctx.freereg
        local iter = free + 3
        local line = node.line

        local loop, exit, cont = genid(), genid(), genid()

        local vars = node.namelist.names
        local iter_list = node.explist

        local iter_count = 0
        for i = 1, #iter_list - 1 do
            self:expr_tonextreg(iter_list[i])
            iter_count = iter_count + 1
            if iter_count == 2 then break end
        end

        -- func, state, ctl
        self:expr_tomultireg(iter_list[iter_count+1], 3 - iter_count)
        self.ctx:setreg(iter)
        local forivinfo = self.ctx:forivars(0x04)
        self.ctx:jump(loop, self.ctx.freereg)

        self:loop_enter(exit, free, cont)

        for i=1, #vars do
            local name = vars[i].name
            self.ctx:newvar(name, iter + i - 1)
            self.ctx:setreg(iter + i)
        end

        local ltop = self.ctx:here(genid())
        self:block_emit(node.body)
        self.ctx:here(cont)
        self:loop_leave(node.lastline)
        self.ctx:here(loop)
        self.ctx:op_iterc(iter, #vars)
        self.ctx:setpcline(line)
        self.ctx:op_iterl(iter, ltop)
        self.ctx:setpcline(line)
        forivinfo.endpc = #self.ctx.code
        self.ctx:here(exit)
        self.ctx.freereg = free
    end,

    ReturnStatement = function(self, node)
        local narg = #node.arguments
        local lvar = (narg == 1) and is_local_var(self.ctx, node.arguments[1])
        if narg == 0 then
            self.ctx:close_uvals()
            self.ctx:op_ret0()
        elseif lvar then
            self.ctx:close_uvals()
            self.ctx:op_ret1(lvar)
        else
            local base = self.ctx.freereg
            for i=1, narg - 1 do
                self:expr_tonextreg(node.arguments[i])
            end
            local lastarg = node.arguments[narg]
            local req_tc = (narg == 1)
            local mret, tail = self:expr_tomultireg(lastarg, MULTIRES, req_tc)
            self.ctx.freereg = base
            if not tail then
                self.ctx:close_uvals()
                if mret then
                    self.ctx:op_retm(base, narg - 1)
                elseif narg == 1 then
                    self.ctx:op_ret1(base)
                else
                    self.ctx:op_ret(base, narg)
                end
            end
        end
        if self.ctx:is_root_scope() then
            self.ctx.explret = true
        end
    end,

    ImportStatement = function(self, node)
        local free = self.ctx.freereg
        local fields = node.fields
        if fields then
            local base = free + #fields
            self.ctx:setreg(base)
            gen_rt(self, "import", base)
            self.ctx:nextreg()
            self:expr_tonextreg(node.modname)
            self.ctx.freereg = base
            self.ctx:op_call(base, 1, 1)
            self.ctx.freereg = free
            for i = 1, #fields do
                self.ctx:op_tget(free + (i - 1), base,
                    self:property_tagged(fields[i][1]))
            end
            self.ctx.freereg = free
            for i = 1, #fields do
                self.ctx:newvar(fields[i][2].name, free + (i - 1))
                self.ctx:nextreg()
            end
        else
            gen_rt(self, "import", free)
            self.ctx:nextreg()
            self:expr_tonextreg(node.modname)
            self.ctx.freereg = free
            if not node.varname then
                self.ctx:op_call(free, 0, 1)
            else
                self.ctx:op_call(free, 1, 1)
                self.ctx:newvar(node.varname.name)
            end
        end
    end,

    Chunk = function(self, node, name)
        self:block_emit(node.body)
        self:close_proto()
    end
}

local Generator = util.Object:clone {
    __ctor = function(self, tree, name, allowg)
        self.line = 0
        self.main = bc.Proto.new(bc.Proto.VARARG, tree.firstline, tree.lastline)
        self.ctx = self.main
        self.globals = allowg
        self.chunkname = tree.chunkname
        self:emit(tree)
        self.dump = bc.Dump.new(self.main, name)
    end,

    block_enter = function(self)
        self.ctx:enter()
    end,

    block_leave = function(self, lastline, exit)
        self.ctx:fscope_end()
        self.ctx:close_block(self.ctx.scope.basereg, exit)
        self.ctx:leave()
        if lastline then self.ctx:line(lastline) end
    end,

    loop_enter = function(self, exit, exit_reg, cont)
        self:block_enter()
        self.ctx:loop_register(exit, exit_reg, cont)
    end,

    loop_leave = function(self, lastline)
        self:block_leave(lastline)
    end,

    assign = function(self, lhs, expr)
        local saveline = self.ctx.currline
        self.ctx:line(lhs.line)
        if lhs.tag == "member" then
            -- SET instructions with a Primitive "P" index are not accepted.
            -- The method self:lhs_expr_emit does never generate such requests.
            assert(lhs.key_type ~= "P", "invalid assignment instruction")
            self.ctx:op_tset(lhs.target, lhs.key_type, lhs.key, expr)
        elseif lhs.tag == "upval" then
            self.ctx:op_uset(lhs.uv, "V", expr)
        elseif lhs.tag == "local" then
            mov_toreg(self.ctx, lhs.target, expr)
        elseif self.globals == true or (self.globals and self.globals[lhs.name]) then
            self.ctx:op_gset(expr, lhs.name)
        else
            lang_error("undeclared variable '" .. lhs.name .. "'", self.chunkname,
                self.ctx.currline)
        end
        self.ctx:line(saveline)
    end,

    emit = function(self, node, ...)
        if node.line then self.ctx:line(node.line) end
        local rule = StatementRule[node.kind]
        if not rule then
            error("cannot find a statement rule for " .. node.kind)
        end
        rule(self, node, ...)
    end,

    block_emit = function(self, stmts, if_exit)
        local n = #stmts
        for i = 1, n - 1 do
            self:emit(stmts[i])
        end
        if n > 0 then
            self:emit(stmts[n], if_exit)
        end
    end,

    -- Emit the code to evaluate "node" and perform a conditional
    -- jump based on its value.
    -- The arguments "jmp" and "jreg" are respectively the jump location
    -- and the rbase operand for the JMP operation if the store is performed.
    -- When no store is done JMP will use "freereg" as rbase operand.
    -- If "negate" is false the jump on FALSE and viceversa.
    -- The argument "store" is a bitfield that specifies which
    -- computed epxression should be stored. The bit EXPR_RESULT_TRUE
    -- means that the value should be stored when its value is "true".
    -- If "store" is not ZERO than dest should be the register
    -- destination for the result.
    test_emit = function(self, node, jmp, jreg, negate, store, dest)
        if node.line then self.ctx:line(node.line) end
        local rule = TestRule[node.kind]
        store = store or 0
        if rule then
            rule(self, node, jmp, jreg, negate, store, dest)
        else
            self:expr_test(node, jmp, jreg, negate, store, dest)
        end
    end,

    -- Emit code to test an expression as a boolean value
    expr_test = function(self, node, jmp, jreg, negate, store, dest)
        local free = self.ctx.freereg
        local const_v = bool_const_eval(node)
        if const_v ~= nil then
            if bit.band(store, store_bit(const_v)) ~= 0 then
                self.ctx:op_load(dest, const_v)
            end
            if xor(negate, not const_v) then
                self.ctx:jump(jmp, jreg)
            end
        else
            local expr = self:expr_toanyreg(node)
            if store ~= 0 then
                cond_mov_toreg(self.ctx, negate, dest, expr, jmp,
                    self.ctx.freereg)
            else
                self.ctx:op_test(negate, expr, jmp, self.ctx.freereg)
            end
        end
        self.ctx.freereg = free
    end,

    -- Emit code to compute the "node" expression in any register. Return
    -- the register itself and an optional boolean value to indicate if a
    -- tail call was used.
    -- If a new register is needed to store the results one is automatically
    -- allocated and marked as used.
    expr_toanyreg = function(self, node, tail)
        local localvar = is_local_var(self.ctx, node)
        if localvar then
            return localvar, false
        else
            local dest = self.ctx.freereg
            local tailcall = self:expr_toreg(node, dest, dest + 1, tail)
            return self.ctx:nextreg(), tailcall
        end
    end,

    -- Emit code to compute the "node" expression by storing the result in
    -- the given register "dest". It does return an optional boolean value
    -- to indicate if a tail call was used.
    -- This function always leave the freereg counter to its initial value.
    expr_toreg = function(self, node, dest, jreg, tail)
        if node.line then self.ctx:line(node.line) end
        local const_val = const_eval(node)
        if const_val then
            self.ctx:op_load(dest, const_val)
        else
            local rule = ExpressionRule[node.kind]
            if rule then
                rule(self, node, dest, jreg or self.ctx.freereg)
            elseif MultiExprRule[node.kind] then
                rule = MultiExprRule[node.kind]
                local base = self.ctx.freereg
                local mres, tailcall = rule(self, node, 1, base == dest and tail)
                mov_toreg(self.ctx, dest, base)
                return tailcall
            else
                error("Cannot find an ExpressionRule for " .. node.kind)
            end
        end
        return false -- no tail call
    end,

    -- Emit code to compute the "node" expression in the next available register
    -- and increment afterward the free register counter.
    -- It does call "expr_toreg" with (dest + 1) as "jreg" argument to inform
    -- an eventual "test_emit" call that the next free register after the expression
    -- store is (dest + 1).
    expr_tonextreg = function(self, node)
        local dest = self.ctx.freereg
        self:expr_toreg(node, dest, dest + 1)
        self.ctx:setreg(dest + 1)
        return dest
    end,

    -- Generate the code to store multiple values in consecutive registers
    -- starting from the current "freereg". The argument "want" indicate
    -- how many values should be generated or MULTIRES.
    -- The optional boolean parameter "tail" indicate if a tail call instruction
    -- should be generated if possible.
    -- Return two boolean values. The first indicate if it does return multi
    -- results. The second if a tail call was actually generated.
    expr_tomultireg = function(self, node, want, tail)
        if node.line then self.ctx:line(node.line) end
        local rule = MultiExprRule[node.kind]
        if rule then
            return rule(self, node, want, tail)
        elseif (want > 0 or want == MULTIRES) then
            local dest = self.ctx.freereg
            self:expr_toreg(node, dest, dest + 1)
            self.ctx:maxframe(dest + 1)
            if want > 1 then
                self.ctx:op_nils(dest + 1, want - 1)
                self.ctx:maxframe(dest + want)
            end
            return false, false
        end
    end,

    -- Like "expr_toreg" but it can return an expression (register) or
    -- an immediate constant. It does return a tag and then the value
    -- itself.
    expr_toanyreg_tagged = function(self, node, emit)
        local const_val = const_eval(node)
        if emit.byte and const_val and is_byte_number(const_val) then
            return "B", const_val
        elseif emit.number and const_val then
            return "N", self.ctx:const(const_val)
        end
        if node.kind == "Literal" then
            local value = node.value
            local tv = type(value)
            if emit.primitive and (tv == "nil" or tv == "boolean") then
                return "P", self.ctx:kpri(value)
            elseif emit.string and tv == "string" then
                return self:property_tagged(value)
            end
            -- fall through
        end
        return "V", self:expr_toanyreg(node)
    end,

    property_tagged = function(self, property_name)
        local kprop = self.ctx:const(property_name)
        if kprop < 255 then
            return 'S', kprop
        else
            local prop = self.ctx:nextreg()
            self.ctx:op_load(prop, property_name)
            return 'V', prop
        end
    end,

    -- Emit code to store an expression in the given LHS.
    expr_tolhs = function(self, lhs, expr)
        local free = self.ctx.freereg
        if lhs.tag == "upval" then
            local tag, expr = self:expr_toanyreg_tagged(expr, EXPR_EMIT_VSNP)
            self.ctx:op_uset(lhs.uv, tag, expr)
            self.ctx:setpcline(lhs.line)
        elseif lhs.tag == "local" then
            self:expr_toreg(expr, lhs.target)
        else
            local reg = self:expr_toanyreg(expr)
            self:assign(lhs, reg)
        end
        self.ctx.freereg = free
    end,

    lhs_expr_emit = function(self, node)
        local line = self.ctx.currline
        local rule = assert(LHSExpressionRule[node.kind],
            "undefined assignment rule for node type: \"" .. node.kind .. "\"")
        if node.line then self.ctx:line(node.line) end
        local lhs = rule(self, node)
        lhs.line = line
        return lhs
    end,

    close_proto = function(self, lastline)
        if lastline then self.ctx:line(lastline) end
        local err, line = self.ctx:close_proto()
        if err then
            lang_error(err, self.chunkname, line)
        end
    end
}

return function(tree, name, allowg)
    return Generator(tree, name, allowg).dump:pack()
end
