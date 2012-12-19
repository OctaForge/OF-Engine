--[[! File: library/core/std/lua/zlib.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Accessible as "zlib". Provides simple facilities for compression
        and decompression of textual data. Note that the length of the input
        must always fit into 4 bytes unsigned for compatibility (i.e. when
        sending data compressed on a client where ulong is 8 bytes to
        server where ulong is 4 bytes, still plenty of space).

        This module is not safe, so use with care. It's also not available
        in sandboxed environment.
]]

return {
    --[[! Function: compress
        Compresses an input string and returns a compressed one again in
        string form. Other arguments are optional. The second one specifies
        input buffer length (defaults to #input). The third one specifies
        compression level (from 0 to 9, 0 is max speed, 9 is max compression,
        defaults to -1 which equals Z_DEFAULT_COMPRESSION, equivalent of
        level 6).

        First 4 bytes of the buffer are reserved for original input length.
    ]]
    compress = function(input, len, level)
        len   = len   or #input
        level = level or -1

        local n   = EAPI.zlib_compress_bound(len)
        local buf = ffi.new("uint8_t[?]", n + 4)

        local ptr = ffi.cast("uint32_t*", buf)
        ptr[0]    = len
        -- make sure it isn't truncated
        assert(ptr[0] == len)

        local  buflen = ffi.new("unsigned long[1]", n)
        local  ret    = EAPI.zlib_compress(buf + 4, buflen, input, len, level)
        assert(ret == 0)

        return ffi.string(buf, buflen[0] + 4)
    end,

    --[[! Function: decompress
        Decompresses previously compressed data. Returns the original string
        like before compression.
    ]]
    decompress = function(input)
        local ptr = ffi.cast  ("uint8_t *", input)
        local len = ffi.cast  ("uint32_t*", ptr)[0]

        local  buf    = ffi.new("uint8_t[?]", len)
        local  buflen = ffi.new("unsigned long[1]", len)
        local  ret    = EAPI.zlib_uncompress(buf, buflen, ptr + 4, #input - 4)
        assert(ret == 0)

        return ffi.string(buf, buflen[0])
    end
}
