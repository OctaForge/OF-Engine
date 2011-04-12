#!/bin/bash
# simple script generating a proper scripting_system_lua_exp.hpp from scripting_system_lua_def.hpp

# variables
# input file
IN="cubecreate/scripting_system_lua_def.hpp"
# output file
OUT="cubecreate/scripting_system_lua_exp.hpp"
# temporary preprocessed input
TMP="tmp_$$.$$"
# output version
VER="$(cat $IN|grep 'scripting_system_lua_def.hpp, version'|sed 's/ \* scripting_system_lua_def.hpp, version //')"
# the preprocessor to use to get rid of additional macros
CPP="cpp -DCLIENT -DSERVER"
# sed version
SED="sed"

if [ "$(uname -s)" = "FreeBSD" ]; then
    SED="gsed"
fi

$CPP $IN | grep LUA_BIND | $SED -e 's/ LUA_BIND/\nLUA_BIND/g' -e 's/^   \n//' > $TMP

cat << EOF > $OUT
/*
 * scripting_system_lua_exp.hpp, version $VER
 * Header file for Lua binding definitions
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2010 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#define LUAREG(n) { #n, _bind_##n }
const LE_reg CAPI[] = {
EOF

counter=0
cat $TMP | while read x
do
	if [ $counter -ge 2 ]; then
		name="$(echo $x|$SED -e 's/,.*//' -e 's/.*(//')"
		echo -e "    LUAREG($name)," >> $OUT
	fi
	let counter++
done

cat << EOF >> $OUT
    {0,0}
};

const LE_reg LAPI[] = {
    LUAREG(log),
    LUAREG(echo),
    {0,0}
};
#undef LUAREG
EOF

echo "-----------------------------------------"
echo "Done processing, removing temporary file."

rm $TMP

exit 0
