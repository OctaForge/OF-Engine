# Luacy
## version 0.1

**Luacy** (as in **lunacy** and **Lua**) is a lunatic effort to create a clean
superset of the Lua language (as implemented by LuaJIT).

The point is to avoid implementing features that would make it diverge from
the original language (in fact, everything that LuaJIT runs should still be
runnable), but instead add features that are useful but for some reason
not present in Lua itself (while preserving correct debug information
and without introducing any external dependencies).

Luacy requires few of the library functions. It however requires the `bit`
module (loadable by `require("bit")`), so make sure to have that one.

Performance wise, the compiler is able of processing 35 KLOC in about 200
milliseconds under LuaJIT 2.0 on my setup, I might incorporate more
optimizations later.

Note that all new keywords can be used as variable names outside of their
own context.

# Implemented features

Whole Lua 5.1 grammar is covered by now (with 5.2 lexer, supporting the
extra string escapes for example) plus extensions below. Other features
might appear later.

## Bitwise operators

Luacy features infix bitwise operators built on top of the LuaJIT builtin
bit library. They're pretty much just syntax for the library.

It uses `^^` for bitwise XOR because `^` is already exponentiaton.

<table>
  <tr>
    <th>Operator</th><th>Meaning</th><th>Bit library</th>
  </tr>
  <tr>
    <td>&amp;</td><td>bitwise AND</td><td>bit.band</td>
  </tr>
  <tr>
    <td>|</td><td>bitwise OR</td><td>bit.bor</td>
  </tr>
  <tr>
    <td>^^</td><td>bitwise XOR</td><td>bit.bxor</td>
  </tr>
  <tr>
    <td>~ (unary)</td><td>bitwise NOT</td><td>bit.bnot</td>
  </tr>
  <tr>
    <td>&lt;&lt;</td><td>left shift</td><td>bit.lshift</td>
  </tr>
  <tr>
    <td>&gt;&gt;</td><td>arithmetic right shift</td><td>bit.arshift</td>
  </tr>
  <tr>
    <td>&gt;&gt;&gt;</td><td>logical right shift</td><td>bit.rshift</td>
  </tr>
</table>

## If expression

If can be used as an expression, too. This pretty much provides ternary
operator functionality.

```lua
local x = if y then z else w
```

The `else` part can be left out (it automatically becomes `nil`). It has
the same priority as simple expressions such as table or numbers. It's
also right associative.

## Continue statement

The `continue` statement is provided as in other languages. The syntax is
identical with `break`.

## Short lambda expression syntax

To reduce verbosity, short syntax for lambda expressions is provided. Just
compare:

```lua
local x = map(y, |x| x + 1)
```

vs.

```lua
local x = map(y, function(x) return x + 1 end)
```

This form is also provided:

```lua
local x = map(y, |x| do return x + 1 end)
```

## Enumerations

Tables now provide a special enumeration mode. You can use it like this:

```lua
local enum1 = {:
    FOO, -- enums count from 1 like everything else
    BAR, -- this is 2
    BAZ = FOO + BAR -- members can reference previously defined members
:}

local enum2 = {:
    FOO = 1 << 0, -- enforced value
    BAR = 1 << 1,
    BAZ = FOO | BAR
:}
```

Enumeration tables don't follow the same syntax sugar when it comes to calls
as regular tables.

## New syntax for inequality

You should now use `!=` instead of `~=`. The old version still works, but it's
there purely to provide Lua source compatibility.

## Debug statement

During compilation, you can tell the code generator whether this is a debug
version or not. Code can contain statements like this:

```lua
debug then print("hello")
debug do
    -- more code here
end
```

If it's a debug build, the debug keyword will be removed in the result. If
not, all debug statements will be removed from the resulting code.

## Operator precedence

Here is an operator precedence table for all operators in Luacy. It's the
same with Lua precedences (other than the extensions). The precedences are
from lowest to highest.

<table>
  <tr>
    <th>Operator</th><th>Associativity</th>
  </tr>
  <tr>
    <td>or</td><td>left</td>
  </tr>
  <tr>
    <td>and</td><td>left</td>
  </tr>
  <tr>
    <td>==, !=, &lt;, &lt;=, &gt;, &gt;=</td><td>left</td>
  </tr>
  <tr>
    <td>..</td><td>right</td>
  </tr>
  <tr>
    <td>|</td><td>left</td>
  </tr>
  <tr>
    <td>^^</td><td>left</td>
  </tr>
  <tr>
    <td>&amp;</td><td>left</td>
  </tr>
  <tr>
    <td>&lt;&lt;, &gt;&gt;, &gt;&gt;&gt;</td><td>left</td>
  </tr>
  <tr>
    <td>+, -</td><td>left</td>
  </tr>
  <tr>
    <td>*, /, %</td><td>left</td>
  </tr>
  <tr>
    <td>-, not, ~, #</td><td>unary</td>
  </tr>
  <tr>
    <td>^</td><td>right</td>
  </tr>
</table>
