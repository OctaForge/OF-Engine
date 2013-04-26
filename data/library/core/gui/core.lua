-- external locals
local band  = math.band
local bor   = math.bor
local bnot  = math.bnot
local blsh  = math.lsh
local brsh  = math.rsh
local max   = math.max
local min   = math.min
local clamp = math.clamp
local floor = math.floor
local ceil  = math.ceil
local round = math.round
local ffi   = require("ffi")
local _V    = _G["_V"]

local gl = {
    ALPHA = 0x1906,
    ALWAYS = 0x0207,
    BLUE = 0x1905,
    CLAMP_TO_BORDER = 0x812D,
    CLAMP_TO_EDGE = 0x812F,
    COMPARE_REF_TO_TEXTURE = 0x884E,
    CONSTANT_ALPHA = 0x8003,
    CONSTANT_COLOR = 0x8001,
    DST_ALPHA = 0x0304,
    DST_COLOR = 0x0306,
    EQUAL = 0x0202,
    GEQUAL = 0x0206,
    GREATER = 0x0204,
    GREEN = 0x1904,
    LEQUAL = 0x0203,
    LESS = 0x0201,
    LINEAR = 0x2601,
    LINEAR_MIPMAP_LINEAR = 0x2703,
    LINEAR_MIPMAP_NEAREST = 0x2701,
    LINES = 0x0001,
    LINE_LOOP = 0x0002,
    LINE_STRIP = 0x0003,
    MAX_TEXTURE_LOD_BIAS = 0x84FD,
    MIRRORED_REPEAT = 0x8370,
    NEAREST = 0x2600,
    NEAREST_MIPMAP_LINEAR = 0x2702,
    NEAREST_MIPMAP_NEAREST = 0x2700,
    NEVER = 0x0200,
    NONE = 0x0,
    NOTEQUAL = 0x0205,
    ONE = 0x1,
    ONE_MINUS_CONSTANT_ALPHA = 0x8004,
    ONE_MINUS_CONSTANT_COLOR = 0x8002,
    ONE_MINUS_DST_ALPHA = 0x0305,
    ONE_MINUS_DST_COLOR = 0x0307,
    ONE_MINUS_SRC1_ALPHA = 0x88FB,
    ONE_MINUS_SRC1_COLOR = 0x88FA,
    ONE_MINUS_SRC_ALPHA = 0x0303,
    ONE_MINUS_SRC_COLOR = 0x0301,
    POINTS = 0x0000,
    POLYGON = 0x0009,
    QUADS = 0x0007,
    QUAD_STRIP = 0x0008,
    RED = 0x1903,
    REPEAT = 0x2901,
    SRC1_ALPHA = 0x8589,
    SRC1_COLOR = 0x88F9,
    SRC_ALPHA = 0x0302,
    SRC_ALPHA_SATURATE = 0x0308,
    SRC_COLOR = 0x0300,
    TEXTURE_BASE_LEVEL = 0x813C,
    TEXTURE_COMPARE_FUNC = 0x884D,
    TEXTURE_COMPARE_MODE = 0x884C,
    TEXTURE_LOD_BIAS = 0x8501,
    TEXTURE_MAG_FILTER = 0x2800,
    TEXTURE_MAX_LEVEL = 0x813D,
    TEXTURE_MAX_LOD = 0x813B,
    TEXTURE_MIN_FILTER = 0x2801,
    TEXTURE_MIN_LOD = 0x813A,
    TEXTURE_SWIZZLE_A = 0x8E45,
    TEXTURE_SWIZZLE_B = 0x8E44,
    TEXTURE_SWIZZLE_G = 0x8E43,
    TEXTURE_SWIZZLE_R = 0x8E42,
    TEXTURE_WRAP_R = 0x8072,
    TEXTURE_WRAP_S = 0x2802,
    TEXTURE_WRAP_T = 0x2803,
    TRIANGLES = 0x0004,
    TRIANGLE_FAN = 0x0006,
    TRIANGLE_STRIP = 0x0005,
    ZERO = 0x0
}

local scancode_to_keycode = function(x) return bor(x, blsh(1, 30)) end
local char_to_byte = string.byte

local scancode = {
    UNKNOWN = 0,

    A = 4,
    B = 5,
    C = 6,
    D = 7,
    E = 8,
    F = 9,
    G = 10,
    H = 11,
    I = 12,
    J = 13,
    K = 14,
    L = 15,
    M = 16,
    N = 17,
    O = 18,
    P = 19,
    Q = 20,
    R = 21,
    S = 22,
    T = 23,
    U = 24,
    V = 25,
    W = 26,
    X = 27,
    Y = 28,
    Z = 29,

    [1] = 30,
    [2] = 31,
    [3] = 32,
    [4] = 33,
    [5] = 34,
    [6] = 35,
    [7] = 36,
    [8] = 37,
    [9] = 38,
    [0] = 39,

    RETURN = 40,
    ESCAPE = 41,
    BACKSPACE = 42,
    TAB = 43,
    SPACE = 44,

    MINUS = 45,
    EQUALS = 46,
    LEFTBRACKET = 47,
    RIGHTBRACKET = 48,
    BACKSLASH = 49,
    NONUSHASH = 50,
    SEMICOLON = 51,
    APOSTROPHE = 52,
    GRAVE = 53,
    COMMA = 54,
    PERIOD = 55,
    SLASH = 56,
    CAPSLOCK = 57,
    F1 = 58,
    F2 = 59,
    F3 = 60,
    F4 = 61,
    F5 = 62,
    F6 = 63,
    F7 = 64,
    F8 = 65,
    F9 = 66,
    F10 = 67,
    F11 = 68,
    F12 = 69,
    PRINTSCREEN = 70,
    SCROLLLOCK = 71,
    PAUSE = 72,
    INSERT = 73,
    HOME = 74,
    PAGEUP = 75,
    DELETE = 76,
    END = 77,
    PAGEDOWN = 78,
    RIGHT = 79,
    LEFT = 80,
    DOWN = 81,
    UP = 82,

    NUMLOCKCLEAR = 83,
    KP_DIVIDE = 84,
    KP_MULTIPLY = 85,
    KP_MINUS = 86,
    KP_PLUS = 87,
    KP_ENTER = 88,
    KP_1 = 89,
    KP_2 = 90,
    KP_3 = 91,
    KP_4 = 92,
    KP_5 = 93,
    KP_6 = 94,
    KP_7 = 95,
    KP_8 = 96,
    KP_9 = 97,
    KP_0 = 98,
    KP_PERIOD = 99,

    NONUSBACKSLASH = 100,
    APPLICATION = 101,
    POWER = 102,
    KP_EQUALS = 103,
    F13 = 104,
    F14 = 105,
    F15 = 106,
    F16 = 107,
    F17 = 108,
    F18 = 109,
    F19 = 110,
    F20 = 111,
    F21 = 112,
    F22 = 113,
    F23 = 114,
    F24 = 115,
    EXECUTE = 116,
    HELP = 117,
    MENU = 118,
    SELECT = 119,
    STOP = 120,
    AGAIN = 121,
    UNDO = 122,
    CUT = 123,
    COPY = 124,
    PASTE = 125,
    FIND = 126,
    MUTE = 127,
    VOLUMEUP = 128,
    VOLUMEDOWN = 129,
    KP_COMMA = 133,
    KP_EQUALSAS400 = 134,
    INTERNATIONAL1 = 135,
    INTERNATIONAL2 = 136,
    INTERNATIONAL3 = 137,
    INTERNATIONAL4 = 138,
    INTERNATIONAL5 = 139,
    INTERNATIONAL6 = 140,
    INTERNATIONAL7 = 141,
    INTERNATIONAL8 = 142,
    INTERNATIONAL9 = 143,
    LANG1 = 144,
    LANG2 = 145,
    LANG3 = 146,
    LANG4 = 147,
    LANG5 = 148,
    LANG6 = 149,
    LANG7 = 150,
    LANG8 = 151,
    LANG9 = 152,

    ALTERASE = 153,
    SYSREQ = 154,
    CANCEL = 155,
    CLEAR = 156,
    PRIOR = 157,
    RETURN2 = 158,
    SEPARATOR = 159,
    OUT = 160,
    OPER = 161,
    CLEARAGAIN = 162,
    CRSEL = 163,
    EXSEL = 164,

    KP_00 = 176,
    KP_000 = 177,
    THOUSANDSSEPARATOR = 178,
    DECIMALSEPARATOR = 179,
    CURRENCYUNIT = 180,
    CURRENCYSUBUNIT = 181,
    KP_LEFTPAREN = 182,
    KP_RIGHTPAREN = 183,
    KP_LEFTBRACE = 184,
    KP_RIGHTBRACE = 185,
    KP_TAB = 186,
    KP_BACKSPACE = 187,
    KP_A = 188,
    KP_B = 189,
    KP_C = 190,
    KP_D = 191,
    KP_E = 192,
    KP_F = 193,
    KP_XOR = 194,
    KP_POWER = 195,
    KP_PERCENT = 196,
    KP_LESS = 197,
    KP_GREATER = 198,
    KP_AMPERSAND = 199,
    KP_DBLAMPERSAND = 200,
    KP_VERTICALBAR = 201,
    KP_DBLVERTICALBAR = 202,
    KP_COLON = 203,
    KP_HASH = 204,
    KP_SPACE = 205,
    KP_AT = 206,
    KP_EXCLAM = 207,
    KP_MEMSTORE = 208,
    KP_MEMRECALL = 209,
    KP_MEMCLEAR = 210,
    KP_MEMADD = 211,
    KP_MEMSUBTRACT = 212,
    KP_MEMMULTIPLY = 213,
    KP_MEMDIVIDE = 214,
    KP_PLUSMINUS = 215,
    KP_CLEAR = 216,
    KP_CLEARENTRY = 217,
    KP_BINARY = 218,
    KP_OCTAL = 219,
    KP_DECIMAL = 220,
    KP_HEXADECIMAL = 221,

    LCTRL = 224,
    LSHIFT = 225,
    LALT = 226,
    LGUI = 227,
    RCTRL = 228,
    RSHIFT = 229,
    RALT = 230,
    RGUI = 231,

    MODE = 257,

    AUDIONEXT = 258,
    AUDIOPREV = 259,
    AUDIOSTOP = 260,
    AUDIOPLAY = 261,
    AUDIOMUTE = 262,
    MEDIASELECT = 263,
    WWW = 264,
    MAIL = 265,
    CALCULATOR = 266,
    COMPUTER = 267,
    AC_SEARCH = 268,
    AC_HOME = 269,
    AC_BACK = 270,
    AC_FORWARD = 271,
    AC_STOP = 272,
    AC_REFRESH = 273,
    AC_BOOKMARKS = 274,

    BRIGHTNESSDOWN = 275,
    BRIGHTNESSUP = 276,
    DISPLAYSWITCH = 277,
    KBDILLUMTOGGLE = 278,
    KBDILLUMDOWN = 279,
    KBDILLUMUP = 280,
    EJECT = 281,
    SLEEP = 282,

    APP1 = 283,
    APP2 = 284,
}

local key = {
    MOUSE1 = -1,
    MOUSE2 = -3,
    MOUSE3 = -2,
    MOUSE4 = -4,
    MOUSE5 = -5,
    MOUSE6 = -6,
    MOUSE7 = -7,
    MOUSE8 = -8,

    UNKNOWN = 0,

    RETURN = char_to_byte('\r'),
    ESCAPE = char_to_byte('\033'),
    BACKSPACE = char_to_byte('\b'),
    TAB = char_to_byte('\t'),
    SPACE = char_to_byte(' '),
    EXCLAIM = char_to_byte('!'),
    QUOTEDBL = char_to_byte('"'),
    HASH = char_to_byte('#'),
    PERCENT = char_to_byte('%'),
    DOLLAR = char_to_byte('$'),
    AMPERSAND = char_to_byte('&'),
    QUOTE = char_to_byte("'"),
    LEFTPAREN = char_to_byte('('),
    RIGHTPAREN = char_to_byte(')'),
    ASTERISK = char_to_byte('*'),
    PLUS = char_to_byte('+'),
    COMMA = char_to_byte(','),
    MINUS = char_to_byte('-'),
    PERIOD = char_to_byte('.'),
    SLASH = char_to_byte('/'),
    [0] = char_to_byte('0'),
    [1] = char_to_byte('1'),
    [2] = char_to_byte('2'),
    [3] = char_to_byte('3'),
    [4] = char_to_byte('4'),
    [5] = char_to_byte('5'),
    [6] = char_to_byte('6'),
    [7] = char_to_byte('7'),
    [8] = char_to_byte('8'),
    [9] = char_to_byte('9'),
    COLON = char_to_byte(':'),
    SEMICOLON = char_to_byte(';'),
    LESS = char_to_byte('<'),
    EQUALS = char_to_byte('='),
    GREATER = char_to_byte('>'),
    QUESTION = char_to_byte('?'),
    AT = char_to_byte('@'),
    LEFTBRACKET = char_to_byte('['),
    BACKSLASH = char_to_byte('\\'),
    RIGHTBRACKET = char_to_byte(']'),
    CARET = char_to_byte('^'),
    UNDERSCORE = char_to_byte('_'),
    BACKQUOTE = char_to_byte('`'),
    A = char_to_byte('a'),
    B = char_to_byte('b'),
    C = char_to_byte('c'),
    D = char_to_byte('d'),
    E = char_to_byte('e'),
    F = char_to_byte('f'),
    G = char_to_byte('g'),
    H = char_to_byte('h'),
    I = char_to_byte('i'),
    J = char_to_byte('j'),
    K = char_to_byte('k'),
    L = char_to_byte('l'),
    M = char_to_byte('m'),
    N = char_to_byte('n'),
    O = char_to_byte('o'),
    P = char_to_byte('p'),
    Q = char_to_byte('q'),
    R = char_to_byte('r'),
    S = char_to_byte('s'),
    T = char_to_byte('t'),
    U = char_to_byte('u'),
    V = char_to_byte('v'),
    W = char_to_byte('w'),
    X = char_to_byte('x'),
    Y = char_to_byte('y'),
    Z = char_to_byte('z'),

    CAPSLOCK = scancode_to_keycode(scancode.CAPSLOCK),

    F1 = scancode_to_keycode(scancode.F1),
    F2 = scancode_to_keycode(scancode.F2),
    F3 = scancode_to_keycode(scancode.F3),
    F4 = scancode_to_keycode(scancode.F4),
    F5 = scancode_to_keycode(scancode.F5),
    F6 = scancode_to_keycode(scancode.F6),
    F7 = scancode_to_keycode(scancode.F7),
    F8 = scancode_to_keycode(scancode.F8),
    F9 = scancode_to_keycode(scancode.F9),
    F10 = scancode_to_keycode(scancode.F10),
    F11 = scancode_to_keycode(scancode.F11),
    F12 = scancode_to_keycode(scancode.F12),

    PRINTSCREEN = scancode_to_keycode(scancode.PRINTSCREEN),
    SCROLLLOCK = scancode_to_keycode(scancode.SCROLLLOCK),
    PAUSE = scancode_to_keycode(scancode.PAUSE),
    INSERT = scancode_to_keycode(scancode.INSERT),
    HOME = scancode_to_keycode(scancode.HOME),
    PAGEUP = scancode_to_keycode(scancode.PAGEUP),
    DELETE = '\177',
    END = scancode_to_keycode(scancode.END),
    PAGEDOWN = scancode_to_keycode(scancode.PAGEDOWN),
    RIGHT = scancode_to_keycode(scancode.RIGHT),
    LEFT = scancode_to_keycode(scancode.LEFT),
    DOWN = scancode_to_keycode(scancode.DOWN),
    UP = scancode_to_keycode(scancode.UP),

    NUMLOCKCLEAR = scancode_to_keycode(scancode.NUMLOCKCLEAR),
    KP_DIVIDE = scancode_to_keycode(scancode.KP_DIVIDE),
    KP_MULTIPLY = scancode_to_keycode(scancode.KP_MULTIPLY),
    KP_MINUS = scancode_to_keycode(scancode.KP_MINUS),
    KP_PLUS = scancode_to_keycode(scancode.KP_PLUS),
    KP_ENTER = scancode_to_keycode(scancode.KP_ENTER),
    KP_1 = scancode_to_keycode(scancode.KP_1),
    KP_2 = scancode_to_keycode(scancode.KP_2),
    KP_3 = scancode_to_keycode(scancode.KP_3),
    KP_4 = scancode_to_keycode(scancode.KP_4),
    KP_5 = scancode_to_keycode(scancode.KP_5),
    KP_6 = scancode_to_keycode(scancode.KP_6),
    KP_7 = scancode_to_keycode(scancode.KP_7),
    KP_8 = scancode_to_keycode(scancode.KP_8),
    KP_9 = scancode_to_keycode(scancode.KP_9),
    KP_0 = scancode_to_keycode(scancode.KP_0),
    KP_PERIOD = scancode_to_keycode(scancode.KP_PERIOD),

    APPLICATION = scancode_to_keycode(scancode.APPLICATION),
    POWER = scancode_to_keycode(scancode.POWER),
    KP_EQUALS = scancode_to_keycode(scancode.KP_EQUALS),
    F13 = scancode_to_keycode(scancode.F13),
    F14 = scancode_to_keycode(scancode.F14),
    F15 = scancode_to_keycode(scancode.F15),
    F16 = scancode_to_keycode(scancode.F16),
    F17 = scancode_to_keycode(scancode.F17),
    F18 = scancode_to_keycode(scancode.F18),
    F19 = scancode_to_keycode(scancode.F19),
    F20 = scancode_to_keycode(scancode.F20),
    F21 = scancode_to_keycode(scancode.F21),
    F22 = scancode_to_keycode(scancode.F22),
    F23 = scancode_to_keycode(scancode.F23),
    F24 = scancode_to_keycode(scancode.F24),
    EXECUTE = scancode_to_keycode(scancode.EXECUTE),
    HELP = scancode_to_keycode(scancode.HELP),
    MENU = scancode_to_keycode(scancode.MENU),
    SELECT = scancode_to_keycode(scancode.SELECT),
    STOP = scancode_to_keycode(scancode.STOP),
    AGAIN = scancode_to_keycode(scancode.AGAIN),
    UNDO = scancode_to_keycode(scancode.UNDO),
    CUT = scancode_to_keycode(scancode.CUT),
    COPY = scancode_to_keycode(scancode.COPY),
    PASTE = scancode_to_keycode(scancode.PASTE),
    FIND = scancode_to_keycode(scancode.FIND),
    MUTE = scancode_to_keycode(scancode.MUTE),
    VOLUMEUP = scancode_to_keycode(scancode.VOLUMEUP),
    VOLUMEDOWN = scancode_to_keycode(scancode.VOLUMEDOWN),
    KP_COMMA = scancode_to_keycode(scancode.KP_COMMA),
    KP_EQUALSAS400 =
        scancode_to_keycode(scancode.KP_EQUALSAS400),

    ALTERASE = scancode_to_keycode(scancode.ALTERASE),
    SYSREQ = scancode_to_keycode(scancode.SYSREQ),
    CANCEL = scancode_to_keycode(scancode.CANCEL),
    CLEAR = scancode_to_keycode(scancode.CLEAR),
    PRIOR = scancode_to_keycode(scancode.PRIOR),
    RETURN2 = scancode_to_keycode(scancode.RETURN2),
    SEPARATOR = scancode_to_keycode(scancode.SEPARATOR),
    OUT = scancode_to_keycode(scancode.OUT),
    OPER = scancode_to_keycode(scancode.OPER),
    CLEARAGAIN = scancode_to_keycode(scancode.CLEARAGAIN),
    CRSEL = scancode_to_keycode(scancode.CRSEL),
    EXSEL = scancode_to_keycode(scancode.EXSEL),

    KP_00 = scancode_to_keycode(scancode.KP_00),
    KP_000 = scancode_to_keycode(scancode.KP_000),
    THOUSANDSSEPARATOR =
        scancode_to_keycode(scancode.THOUSANDSSEPARATOR),
    DECIMALSEPARATOR =
        scancode_to_keycode(scancode.DECIMALSEPARATOR),
    CURRENCYUNIT = scancode_to_keycode(scancode.CURRENCYUNIT),
    CURRENCYSUBUNIT =
        scancode_to_keycode(scancode.CURRENCYSUBUNIT),
    KP_LEFTPAREN = scancode_to_keycode(scancode.KP_LEFTPAREN),
    KP_RIGHTPAREN = scancode_to_keycode(scancode.KP_RIGHTPAREN),
    KP_LEFTBRACE = scancode_to_keycode(scancode.KP_LEFTBRACE),
    KP_RIGHTBRACE = scancode_to_keycode(scancode.KP_RIGHTBRACE),
    KP_TAB = scancode_to_keycode(scancode.KP_TAB),
    KP_BACKSPACE = scancode_to_keycode(scancode.KP_BACKSPACE),
    KP_A = scancode_to_keycode(scancode.KP_A),
    KP_B = scancode_to_keycode(scancode.KP_B),
    KP_C = scancode_to_keycode(scancode.KP_C),
    KP_D = scancode_to_keycode(scancode.KP_D),
    KP_E = scancode_to_keycode(scancode.KP_E),
    KP_F = scancode_to_keycode(scancode.KP_F),
    KP_XOR = scancode_to_keycode(scancode.KP_XOR),
    KP_POWER = scancode_to_keycode(scancode.KP_POWER),
    KP_PERCENT = scancode_to_keycode(scancode.KP_PERCENT),
    KP_LESS = scancode_to_keycode(scancode.KP_LESS),
    KP_GREATER = scancode_to_keycode(scancode.KP_GREATER),
    KP_AMPERSAND = scancode_to_keycode(scancode.KP_AMPERSAND),
    KP_DBLAMPERSAND =
        scancode_to_keycode(scancode.KP_DBLAMPERSAND),
    KP_VERTICALBAR =
        scancode_to_keycode(scancode.KP_VERTICALBAR),
    KP_DBLVERTICALBAR =
        scancode_to_keycode(scancode.KP_DBLVERTICALBAR),
    KP_COLON = scancode_to_keycode(scancode.KP_COLON),
    KP_HASH = scancode_to_keycode(scancode.KP_HASH),
    KP_SPACE = scancode_to_keycode(scancode.KP_SPACE),
    KP_AT = scancode_to_keycode(scancode.KP_AT),
    KP_EXCLAM = scancode_to_keycode(scancode.KP_EXCLAM),
    KP_MEMSTORE = scancode_to_keycode(scancode.KP_MEMSTORE),
    KP_MEMRECALL = scancode_to_keycode(scancode.KP_MEMRECALL),
    KP_MEMCLEAR = scancode_to_keycode(scancode.KP_MEMCLEAR),
    KP_MEMADD = scancode_to_keycode(scancode.KP_MEMADD),
    KP_MEMSUBTRACT =
        scancode_to_keycode(scancode.KP_MEMSUBTRACT),
    KP_MEMMULTIPLY =
        scancode_to_keycode(scancode.KP_MEMMULTIPLY),
    KP_MEMDIVIDE = scancode_to_keycode(scancode.KP_MEMDIVIDE),
    KP_PLUSMINUS = scancode_to_keycode(scancode.KP_PLUSMINUS),
    KP_CLEAR = scancode_to_keycode(scancode.KP_CLEAR),
    KP_CLEARENTRY = scancode_to_keycode(scancode.KP_CLEARENTRY),
    KP_BINARY = scancode_to_keycode(scancode.KP_BINARY),
    KP_OCTAL = scancode_to_keycode(scancode.KP_OCTAL),
    KP_DECIMAL = scancode_to_keycode(scancode.KP_DECIMAL),
    KP_HEXADECIMAL =
        scancode_to_keycode(scancode.KP_HEXADECIMAL),

    LCTRL = scancode_to_keycode(scancode.LCTRL),
    LSHIFT = scancode_to_keycode(scancode.LSHIFT),
    LALT = scancode_to_keycode(scancode.LALT),
    LGUI = scancode_to_keycode(scancode.LGUI),
    RCTRL = scancode_to_keycode(scancode.RCTRL),
    RSHIFT = scancode_to_keycode(scancode.RSHIFT),
    RALT = scancode_to_keycode(scancode.RALT),
    RGUI = scancode_to_keycode(scancode.RGUI),

    MODE = scancode_to_keycode(scancode.MODE),

    AUDIONEXT = scancode_to_keycode(scancode.AUDIONEXT),
    AUDIOPREV = scancode_to_keycode(scancode.AUDIOPREV),
    AUDIOSTOP = scancode_to_keycode(scancode.AUDIOSTOP),
    AUDIOPLAY = scancode_to_keycode(scancode.AUDIOPLAY),
    AUDIOMUTE = scancode_to_keycode(scancode.AUDIOMUTE),
    MEDIASELECT = scancode_to_keycode(scancode.MEDIASELECT),
    WWW = scancode_to_keycode(scancode.WWW),
    MAIL = scancode_to_keycode(scancode.MAIL),
    CALCULATOR = scancode_to_keycode(scancode.CALCULATOR),
    COMPUTER = scancode_to_keycode(scancode.COMPUTER),
    AC_SEARCH = scancode_to_keycode(scancode.AC_SEARCH),
    AC_HOME = scancode_to_keycode(scancode.AC_HOME),
    AC_BACK = scancode_to_keycode(scancode.AC_BACK),
    AC_FORWARD = scancode_to_keycode(scancode.AC_FORWARD),
    AC_STOP = scancode_to_keycode(scancode.AC_STOP),
    AC_REFRESH = scancode_to_keycode(scancode.AC_REFRESH),
    AC_BOOKMARKS = scancode_to_keycode(scancode.AC_BOOKMARKS),

    BRIGHTNESSDOWN =
        scancode_to_keycode(scancode.BRIGHTNESSDOWN),
    BRIGHTNESSUP = scancode_to_keycode(scancode.BRIGHTNESSUP),
    DISPLAYSWITCH = scancode_to_keycode(scancode.DISPLAYSWITCH),
    KBDILLUMTOGGLE =
        scancode_to_keycode(scancode.KBDILLUMTOGGLE),
    KBDILLUMDOWN = scancode_to_keycode(scancode.KBDILLUMDOWN),
    KBDILLUMUP = scancode_to_keycode(scancode.KBDILLUMUP),
    EJECT = scancode_to_keycode(scancode.EJECT),
    SLEEP = scancode_to_keycode(scancode.SLEEP)
}

local mod = {
    NONE     = 0x0000,
    LSHIFT   = 0x0001,
    RSHIFT   = 0x0002,
    LCTRL    = 0x0040,
    RCTRL    = 0x0080,
    LALT     = 0x0100,
    RALT     = 0x0200,
    LGUI     = 0x0400,
    RGUI     = 0x0800,
    NUM      = 0x1000,
    CAPS     = 0x2000,
    MODE     = 0x4000,
    RESERVED = 0x8000,
    SHIFT    = bor(0x0001, 0x0002),
    CTRL     = bor(0x0040, 0x0080),
    ALT      = bor(0x0100, 0x0200),
    GUI      = bor(0x0400, 0x0800)
}

local update_var = function(varn, val)
    if not var.exists(varn) then
        return nil
    end

    local t = var.get_type(varn)
    if    t == -1 then
        return nil
    end

    _V[varn] = (t == 2) and tostring(val) or tonumber(val)
end

local needs_adjust = true

-- this is the "primary" world - accessed often, so avoid indexing
-- worlds[1] equals world
local world  = nil
local worlds = {}

local clicked  = nil
local hovering = nil
local focused  = nil

local was_clicked  = nil
local was_hovering = nil

local hover_x = 0
local hover_y = 0
local click_x = 0
local click_y = 0

local cursor_x = 0.5
local cursor_y = 0.5

local prev_cx = 0.5
local prev_cy = 0.5

local is_clicked = function(o)
    return (o == clicked)
end

local is_hovering = function(o)
    return (o == hovering)
end

local is_focused = function(o)
    return (o == focused)
end

local set_focus = function(o)
    focused = o
end

local clear_focus = function(o)
    if o == clicked  then clicked  = nil end
    if o == hovering then hovering = nil end
    if o == focused  then focused  = nil end
end

local ALIGN_MASK    = 0xF

local ALIGN_HMASK   = 0x3
local ALIGN_HSHIFT  = 0
local ALIGN_HNONE   = 0
local ALIGN_LEFT    = 1
local ALIGN_HCENTER = 2
local ALIGN_RIGHT   = 3

local ALIGN_VMASK   = 0xC
local ALIGN_VSHIFT  = 2
local ALIGN_VNONE   = blsh(0, 2)
local ALIGN_BOTTOM  = blsh(1, 2)
local ALIGN_VCENTER = blsh(2, 2)
local ALIGN_TOP     = blsh(3, 2)

local CLAMP_MASK    = 0xF0
local CLAMP_LEFT    = 0x10
local CLAMP_RIGHT   = 0x20
local CLAMP_BOTTOM  = 0x40
local CLAMP_TOP     = 0x80

local NO_ADJUST     = bor(ALIGN_HNONE, ALIGN_VNONE)

local TYPE_OBJECT             = 1
local TYPE_WORLD              = 2
local TYPE_BOX                = 3
local TYPE_TABLE              = 4
local TYPE_SPACER             = 5
local TYPE_FILLER             = 6
local TYPE_OFFSETTER          = 7
local TYPE_CLIPPER            = 8
local TYPE_CONDITIONAL        = 9
local TYPE_BUTTON             = 10
local TYPE_CONDITIONAL_BUTTON = 11
local TYPE_TOGGLE             = 12
local TYPE_SCROLLER           = 13
local TYPE_SCROLLBAR          = 14
local TYPE_SCROLL_BUTTON      = 15
local TYPE_SLIDER             = 16
local TYPE_SLIDER_BUTTON      = 17
local TYPE_RECTANGLE          = 18
local TYPE_IMAGE              = 19
local TYPE_SLOT_VIEWER        = 20
local TYPE_LABEL              = 21
local TYPE_TEXT_EDITOR        = 22
local TYPE_MOVER              = 23
local TYPE_RESIZER            = 24
local TYPE_TAG                = 25
local TYPE_WINDOW             = 26

local loop_children = function(self, fun)
    local ch = self.p_children
    local st = self.p_states

    if st then
        local s = self:choose_state()

        if s ~= self.i_current_state then
            self.i_current_state = s
            needs_adjust = true
        end

        local w = st[s]
        if w then
            local r = fun(w)
            if r ~= nil then return r end
        end
    end

    for i = 1, #ch do
        local o = ch[i]
        local r = fun(o)
        if    r ~= nil then return r end
    end
end

local loop_children_r = function(self, fun)
    local ch = self.p_children
    local st = self.p_states

    for i = #ch, 1, -1 do
        local o = ch[i]
        local r = fun(ch[i])
        if    r ~= nil then return r end
    end

    if st then
        local s = self:choose_state()

        if s ~= self.i_current_state then
            self.i_current_state = s
            needs_adjust = true
        end

        local w = st[s]
        if w then
            local r = fun(w)
            if r ~= nil then return r end
        end
    end
end

local loop_in_children = function(self, cx, cy, fun)
    return loop_children(self, function(o)
        local ox = cx - o.p_x
        local oy = cy - o.p_y

        if ox >= 0 and ox < o.p_w and oy >= 0 and oy < o.p_h then
            local r = fun(o, ox, oy)
            if    r ~= nil then return r end
        end
    end)
end

local loop_in_children_r = function(self, cx, cy, fun)
    return loop_children_r(self, function(o)
        local ox = cx - o.p_x
        local oy = cy - o.p_y

        if ox >= 0 and ox < o.p_w and oy >= 0 and oy < o.p_h then
            local r = fun(o, ox, oy)
            if    r ~= nil then return r end
        end
    end)
end

local clip_area_intersect = function(self, c)
    self[1] = max(self[1], c[1])
    self[2] = max(self[2], c[2])
    self[3] = max(self[1], min(self[3], c[3]))
    self[4] = max(self[2], min(self[4], c[4]))
end

local clip_area_is_fully_clipped = function(self, x, y, w, h)
    return self[1] == self[3] or self[2] == self[4] or x >= self[3] or
           y >= self[4] or (x + w) <= self[1] or (y + h) <= self[2]
end

local clip_area_scissor = function(self)
    local scr_w, scr_h = _V.scr_w, _V.scr_h

    local margin = max((scr_w / scr_h - 1) / 2, 0)

    local sx1, sy1, sx2, sy2 =
        clamp(floor((self[1] + margin) / (1 + 2 * margin) * scr_w), 0, scr_w),
        clamp(floor( self[2] * scr_h), 0, scr_h),
        clamp(ceil ((self[3] + margin) / (1 + 2 * margin) * scr_w), 0, scr_w),
        clamp(ceil ( self[4] * scr_h), 0, scr_h)

    _C.gl_scissor(sx1, scr_h - sy2, sx2 - sx1, sy2 - sy1)
end

local clip_stack = {}

local clip_push = function(x, y, w, h)
    local l = #clip_stack
    if    l == 0 then _C.gl_scissor_enable() end

    local c = { x, y, x + w, y + h }

    l = l + 1
    clip_stack[l] = c

    if l >= 2 then clip_area_intersect(c, clip_stack[l - 1]) end
    clip_area_scissor(c)
end

local clip_pop = function()
    table.remove(clip_stack)

    local l = #clip_stack
    if    l == 0 then _C.gl_scissor_disable()
    else clip_area_scissor(clip_stack[l])
    end
end

local is_fully_clipped = function(x, y, w, h)
    local l = #clip_stack
    if    l == 0 then return false end
    return clip_area_is_fully_clipped(clip_stack[l], x, y, w, h)
end

local quad = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    _C.gle_attrib2f(x,     y)     _C.gle_attrib2f(tx,      ty)
    _C.gle_attrib2f(x + w, y)     _C.gle_attrib2f(tx + tw, ty)
    _C.gle_attrib2f(x + w, y + h) _C.gle_attrib2f(tx + tw, ty + th)
    _C.gle_attrib2f(x,     y + h) _C.gle_attrib2f(tx,      ty + th)
end

local quadtri = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    _C.gle_attrib2f(x,     y)     _C.gle_attrib2f(tx,      ty)
    _C.gle_attrib2f(x + w, y)     _C.gle_attrib2f(tx + tw, ty)
    _C.gle_attrib2f(x,     y + h) _C.gle_attrib2f(tx,      ty + th)
    _C.gle_attrib2f(x + w, y + h) _C.gle_attrib2f(tx + tw, ty + th)
end

local Image

local Object
Object = table.Object:clone {
    name = "Object",
    type = TYPE_OBJECT,

    __get = function(self, n)
        n = "p_" .. n
        return rawget(self, n)
    end,

    __set = function(self, n, v)
        local pn = "p_" .. n
        if  rawget(self, pn) ~= nil then
            rawset(self, pn, v)
            signal.emit(self, n .. "_changed", v)
            needs_adjust = true
            return true
        end
    end,

    __init = function(self, kwargs)
        kwargs        = kwargs or {}
        self.p_parent = nil

        local instances = rawget(self.__proto, "instances")
        if not instances then
            instances = {}
            rawset(self.__proto, "instances", instances)
        end
        instances[self] = self

        self.p_x = 0
        self.p_y = 0
        self.p_w = 0
        self.p_h = 0

        self.i_adjust   = bor(ALIGN_HCENTER, ALIGN_VCENTER)
        self.p_children = { unpack(kwargs) }
        self.__len      = Object.__len

        -- alignment and clamping
        local align_h = kwargs.align_h or 0
        local align_v = kwargs.align_v or 0
        local clamp_l = kwargs.clamp_l or 0
        local clamp_r = kwargs.clamp_r or 0
        local clamp_b = kwargs.clamp_b or 0
        local clamp_t = kwargs.clamp_t or 0

        self.p_floating    = kwargs.floating or false
        self.p_allow_focus = kwargs.allow_focus == nil and true or false

        self:align(align_h, align_v)
        self:clamp(clamp_l, clamp_r, clamp_b, clamp_t)

        -- append any required children
        for i, v in ipairs(kwargs) do
            v.p_parent = self
        end

        -- states
        self.i_current_state = nil
        local states = {}

        local ks = kwargs.states
        if ks then
            for k, v in pairs(ks) do
                states[k] = v
                states[k].p_parent = self
            end
        end

        local dstates = rawget(self.__proto, "states")
        if dstates then
            for k, v in pairs(dstates) do
                if not states[k] then
                    local cl = v:deep_clone()
                    states[k] = cl
                    cl.p_parent = self
                end
            end
        end

        self.p_states = states

        -- and connect signals
        if kwargs.signals then
            for k, v in pairs(kwargs.signals) do
                signal.connect(self, k, v)
            end
        end

        -- tooltip? widget specific
        local t = kwargs.tooltip
        if t then
            self.p_tooltip = t
        end

        -- and init
        if  kwargs.init then
            kwargs.init(self)
        end
    end,

    __len = function(self)
        return #self.p_children
    end,

    clear = function(self)
        clear_focus(self)

        local children = self.p_children
        if children then
            for i = 1, #children do
                local ch = children[i]
                ch:clear()
            end
            self.p_children = nil
        end

        signal.emit(self, "destroy")
        local insts = rawget(self.__proto, "instances")
        if insts then
            insts[self] = nil
        end
    end,

    deep_clone = function(self)
        local ch, rch = {}, self.children
        local cl = self:clone { children = ch }
        for i = 1, #rch do
            local chcl = rch[i]:deep_clone()
            chcl.p_parent = cl
            ch[i] = chcl
        end
        return cl
    end,

    update_state = function(self, sname, sval)
        local states = rawget(self, "states")
        if not states then
            states = {}
            rawset(self, "states", states)
        end

        local oldstate = states[sname]
        states[sname] = sval

        local insts = rawget(self, "instances")
        if insts then for v in pairs(insts) do
            local sts = v.p_states
            if sts then
                local st = sts[sname]
                -- update only on widgets actually using the default state
                if st and st.__proto == oldstate then
                    local nst = sval:deep_clone()
                    nst.p_parent = v
                    sts[sname] = nst
                    st:clear()
                end
            end
        end end

        oldstate:clear()
        needs_adjust = true
    end,

    update_states = function(self, states)
        for k, v in pairs(states) do
            self:update_state(k, v)
        end
    end,

    choose_state = function(self) return nil end,

    layout = function(self)
        self.p_w = 0
        self.p_h = 0

        loop_children(self, function(o)
            o.p_x = 0
            o.p_y = 0
            o:layout()
            self.p_w = max(self.p_w, o.p_x + o.p_w)
            self.p_h = max(self.p_h, o.p_y + o.p_h)
        end)
    end,

    adjust_children_to = function(self, px, py, pw, ph)
        loop_children(self, function(o) o:adjust_layout(px, py, pw, ph) end)
    end,

    adjust_children = function(self)
        Object.adjust_children_to(self, 0, 0, self.p_w, self.p_h)
    end,

    adjust_layout = function(self, px, py, pw, ph)
        local x, y, w, h, a = self.p_x, self.p_y,
            self.p_w, self.p_h, self.i_adjust

        local adj = band(a, ALIGN_HMASK)

        if adj == ALIGN_LEFT then
            x = px
        elseif adj == ALIGN_HCENTER then
            x = px + (pw - w) / 2
        elseif adj == ALIGN_RIGHT then
            x = px + pw - w
        end

        adj = band(a, ALIGN_VMASK)

        if adj == ALIGN_BOTTOM then
            y = py
        elseif adj == ALIGN_VCENTER then
            y = py + (ph - h) / 2
        elseif adj == ALIGN_TOP then
            y = py + ph - h
        end

        if band(a, CLAMP_MASK) ~= 0 then
            if band(a, CLAMP_LEFT ) ~= 0 then x = px end
            if band(a, CLAMP_RIGHT) ~= 0 then
                w = px + pw - x
            end

            if band(a, CLAMP_BOTTOM) ~= 0 then y = py end
            if band(a, CLAMP_TOP   ) ~= 0 then
                h = py + ph - y
            end
        end

        self.p_x, self.p_y, self.p_w, self.p_h = x, y, w, h

        if self.p_floating then
            local fx = self.p_fx
            local fy = self.p_fy

            if not fx then self.p_fx, fx = x, x end
            if not fy then self.p_fy, fy = y, y end

            self.p_x = fx
            self.p_y = fy

            local fw = self.p_fw
            local fh = self.p_fh

            if not fw then self.p_fw, fw = w, w end
            if not fh then self.p_fh, fh = h, h end

            self.p_w = fw
            self.p_h = fh
        end

        self:adjust_children()
    end,

    target = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c = o:target(ox, oy)
            if c then return c end
        end)
    end,

    key = function(self, code, isdown)
        return loop_children_r(self, function(o)
            if o:key(code, isdown) then return true end
        end) or false
    end,

    key_hover = function(self, code, isdown)
        local p = self.p_parent
        if p then return p:key_hover(code, isdown) end
        return false
    end,

    draw = function(self, sx, sy)
        sx = sx or self.p_x
        sy = sy or self.p_y

        loop_children(self, function(o)
            local ox = o.p_x
            local oy = o.p_y
            local ow = o.p_w
            local oh = o.p_h
            if not is_fully_clipped(sx + ox, sy + oy, ow, oh) then
                o:draw(sx + ox, sy + oy)
            end
        end)
    end,

    hover = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c  = o:hover(ox, oy)
            if    c == o then
                hover_x = ox
                hover_y = oy
            end
            if c then return c end
        end)
    end,

    hovering = function(self, cx, cy)
    end,

    pressing = function(self, cx, cy)
    end,

    click = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c  = o:click(ox, oy)
            if    c == o then
                click_x = ox
                click_y = oy
            end
            if c then return c end
        end)
    end,

    clicked = function(self, cx, cy)
        signal.emit(self, "click", cx / self.p_w, cy / self.p_w)
    end,

    takes_input = function(self) return true end,

    find_child = function(self, otype, name, recurse, exclude)
        recurse = (recurse == nil) and true or recurse
        local o = loop_children(self, function(o)
            if o ~= exclude and o.type == otype and
            (not name or name == o.p_obj_name) then
                return o
            end
        end)
        if o then return o end
        if recurse then
            o = loop_children(self, function(o)
                if o ~= exclude then
                    local found = o:find_child(otype, name)
                    if    found ~= nil then return found end
                end
            end)
        end
        return o
    end,

    find_sibling = function(self, otype, name)
        local prev = self
        local cur  = self.p_parent

        while cur do
            local o = cur:find_child(otype, name, true, prev)
            if    o then return o end

            prev = cur
            cur  = cur.p_parent
        end
    end,

    remove = function(self, o)
        for i = 1, #self.p_children do
            if o == self.p_children[i] then
                table.remove(self.p_children, i):clear()
                needs_adjust = true
                return true
            end
        end
        return false
    end,

    remove_nth = function(self, n)
        if #self.p_children < n then
            return false
        end
        table.remove(self.p_children, n):clear()
        needs_adjust = true
        return true
    end,

    destroy = function(self)
        self.p_parent:remove(self)
    end,

    destroy_children = function(self)
        local ch = self.p_children
        for i = 1, #ch do
            ch[i]:clear()
        end
        self.p_children = {}
        needs_adjust = true
        signal.emit(self, "children_destroy")
    end,

    align = function(self, h, v)
        assert_param(h, "number", 2)
        assert_param(v, "number", 3)

        self.i_adjust = bor(
            band(self.i_adjust, bnot(ALIGN_MASK)),
            blsh(clamp(h, -1, 1) + 2, ALIGN_HSHIFT),
            blsh(clamp(v, -1, 1) + 2, ALIGN_VSHIFT)
        )
        needs_adjust = true
    end,

    clamp = function(self, l, r, b, t)
        assert_param(l, "number", 2)
        assert_param(r, "number", 3)
        assert_param(b, "number", 4)
        assert_param(t, "number", 5)

        self.i_adjust = bor(
            band(self.i_adjust, bnot(CLAMP_MASK)),
            l ~= 0 and CLAMP_LEFT   or 0,
            r ~= 0 and CLAMP_RIGHT  or 0,
            b ~= 0 and CLAMP_BOTTOM or 0,
            t ~= 0 and CLAMP_TOP    or 0
        )
        needs_adjust = true
    end,

    get_alignment = function(self)
        local a   = self.i_adjust
        local adj = band(a, ALIGN_HMASK)
        local hal = (adj == ALIGN_LEFT) and -1 or
            (adj == ALIGN_HCENTER and 0 or 1)

        adj = band(a, ALIGN_VMASK)
        local val = (adj == ALIGN_BOTTOM) and 1 or
            (adj == ALIGN_VCENTER and 0 or -1)

        return hal, val
    end,

    get_clamping = function(self)
        local a   = self.i_adjust
        local adj = band(a, CLAMP_MASK)
        if    adj == 0 then
            return 0, 0, 0, 0
        end

        return band(a, CLAMP_LEFT  ), band(a, CLAMP_RIGHT),
               band(a, CLAMP_BOTTOM), band(a, CLAMP_TOP)
    end,

    insert = function(self, pos, obj, fun)
        table.insert(self.p_children, pos, obj)
        obj.p_parent = self
        if fun then fun(obj) end
        return obj
    end,

    append = function(self, obj, fun)
        local children = self.p_children
        children[#children + 1] = obj
        obj.p_parent = self
        if fun then fun(obj) end
        return obj
    end,

    prepend = function(self, obj, fun)
        table.insert(self.p_children, 1, obj)
        obj.p_parent = self
        if fun then fun(obj) end
        return obj
    end,

    set_state = function(self, state, obj)
        local states = self.p_states
        local ostate = states[state]
        if ostate then ostate:clear() end
        states[state] = obj
        obj.p_parent = self
        return obj
    end
}

local Named_Object = Object:clone {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_obj_name = kwargs.name
        return Object.__init(self, kwargs)
    end
}

local Tag = Named_Object:clone {
    type = TYPE_TAG
}

local Window = Named_Object:clone {
    type = TYPE_WINDOW
}

local Overlay = Window:clone {
    takes_input = function(self) return false end,

    target = function() end,
    hover  = function() end,
    click  = function() end
}

local World = Object:clone {
    name = "World",
    type = TYPE_WORLD,

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.p_input = kwargs.input == true and true or false
        self.p_guis = {}

        return Object.__init(self, kwargs)
    end,

    takes_input = function(self)
        return loop_children_r(self, function(o)
            if o:takes_input() then return true end
        end) or false
    end,

    focus_children = function(self)
        return loop_children(self, function(o)
            if o.p_allow_focus or _V.mouselook == 0 then
                return true
            end
        end) or false
    end,

    layout = function(self)
        Object.layout(self)

        local       margin = max((_V.scr_w / _V.scr_h - 1) / 2, 0)
        self.p_x = -margin
        self.p_y = 0
        self.p_w = 2 * margin + 1
        self.p_h = 1

        self.adjust_children(self)
    end,

    build_gui = function(self, name, fun, noinput)
        local old = self:find_child(TYPE_WINDOW, name, false)
        if old then self:remove(old) end

        local win = noinput and Overlay { name = name }
            or Window { name = name }
        win.p_parent = self

        local children = self.p_children
        children[#children + 1] = win

        if fun then fun(win) end
        return win
    end,

    new_gui = function(self, name, fun, noinput)
        self.p_guis[name] = function()
            self:build_gui(name, fun, noinput)
        end
    end,

    show_gui = function(self, name)
        self.p_guis[name]()
    end,

    get_gui = function(self, name)
        return self.p_guis[name]
    end,

    hide_gui = function(self, name)
        local old = self:find_child(TYPE_WINDOW, name, false)
        if old then self:remove(old) end
        return old ~= nil
    end,

    replace_gui = function(self, wname, tname, obj, fun)
        local win = self:find_child(TYPE_WINDOW, wname, false)
        if not win then return false end
        local tag = self:find_child(TYPE_TAG, tname)
        if not tag then return false end
        tag:destroy_children()
        tag:append(obj)
        if fun then fun(obj) end
        return true
    end
}

local H_Box = Object:clone {
    name = "H_Box",
    type = TYPE_BOX,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_padding = kwargs.padding or 0
        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        self.p_w, self.p_h = 0, 0

        loop_children(self, function(o)
            o.p_x = self.p_w
            o.p_y = 0
            o:layout()

            self.p_w = self.p_w + o.p_w
            self.p_h = max(self.p_h, o.p_y + o.p_h)
        end)
        self.p_w = self.p_w + self.p_padding * max(#self.p_children - 1, 0)
    end,

    adjust_children = function(self)
        if #self.p_children == 0 then
            return nil
        end

        local offset = 0
        loop_children(self, function(o)
            o.p_x = offset
            offset = offset + o.p_w

            o:adjust_layout(o.p_x, 0, o.p_w, self.p_h)
            offset = offset + self.p_padding
        end)
    end
}

local V_Box = Object:clone {
    name = "V_Box",
    type = TYPE_BOX,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_padding = kwargs.padding or 0
        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        self.p_w = 0
        self.p_h = 0

        loop_children(self, function(o)
            o.p_x = 0
            o.p_y = self.p_h
            o:layout()

            self.p_h = self.p_h + o.p_h
            self.p_w = max(self.p_w, o.p_x + o.p_w)
        end)
        self.p_h = self.p_h + self.p_padding * max(#self.p_children - 1, 0)
    end,

    adjust_children = function(self)
        if #self.p_children == 0 then
            return nil
        end

        local offset = 0
        loop_children(self, function(o)
            o.p_y = offset
            offset = offset + o.p_h

            o:adjust_layout(0, o.p_y, self.p_w, o.p_h)
            offset = offset + self.p_padding
        end)
    end
}

local Table = Object:clone {
    name = "Table",
    type = TYPE_TABLE,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_columns = kwargs.columns or 0
        self.p_padding = kwargs.padding or 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        local widths, heights = createtable(4), createtable(4)
        self.widths, self.heights = widths, heights

        local column, row = 1, 1
        local columns, padding = self.p_columns, self.p_padding

        loop_children(self, function(o)
            o:layout()

            if #widths < column then
                widths[#widths + 1] = o.p_w
            elseif o.p_w > widths[column] then
                widths[column] = o.p_w
            end

            if #heights < row then
                heights[#heights + 1] = o.p_h
            elseif o.p_h > heights[row] then
                heights[row] = o.p_h
            end

            column = (column % columns) + 1
            if column == 1 then
                row = row + 1
            end
        end)

        local p_w, p_h = 0, 0
        column, row    = 1, 1

        local offset = 0

        loop_children(self, function(o)
            o.p_x = offset
            o.p_y = p_h

            local wc, hr = widths[column], heights[row]
            o:adjust_layout(offset, p_h, wc, hr)
            offset = offset + wc

            p_w = max(p_w, offset)
            column = (column % columns) + 1

            if column == 1 then
                offset = 0
                p_h = p_h + hr
                row = row + 1
            end
        end)

        if column ~= 1 then
            p_h = p_h + heights[row]
        end

        self.p_w = p_w + padding * max(#widths  - 1, 0)
        self.p_h = p_h + padding * max(#heights - 1, 0)
    end,

    adjust_children = function(self)
        if #self.p_children == 0 then
            return nil
        end
        
        local widths, heights = self.widths, self.heights
        local columns = self.p_columns

        local cspace = self.p_w
        local rspace = self.p_h

        for i = 1, #widths do
            cspace = cspace - widths[i]
        end
        for i = 1, #heights do
            rspace = rspace - heights[i]
        end

        cspace = cspace / max(#widths  - 1, 1)
        rspace = rspace / max(#heights - 1, 1)

        local column , row     = 1, 1
        local offsetx, offsety = 0, 0

        loop_children(self, function(o)
            o.p_x = offsetx
            o.p_y = offsety

            local wc, hr = widths[column], heights[row]
            o.adjust_layout(o, offsetx, offsety, wc, hr)

            offsetx = offsetx + wc + cspace
            column = (column % columns) + 1

            if column == 1 then
                offsetx = 0
                offsety = offsety + hr + rspace
                row = row + 1
            end
        end)
    end
}

local Spacer = Object:clone {
    name = "Spacer",
    type = TYPE_SPACER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_pad_h = kwargs.pad_h or 0
        self.p_pad_v = kwargs.pad_v or 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        local ph, pv = self.pad_h, self.pad_v
        local w , h  = ph, pv

        loop_children(self, function(o)
            o.p_x = ph
            o.p_y = pv
            o:layout()

            w = max(w, o.p_x + o.p_w)
            h = max(h, o.p_y + o.p_h)
        end)

        self.p_w = w + ph
        self.p_h = h + pv
    end,

    adjust_children = function(self)
        local ph, pv = self.p_pad_h, self.p_pad_v
        Object.adjust_children_to(self, ph, pv, self.p_w - 2 * ph,
            self.p_h - 2 * pv)
    end
}

local Filler = Object:clone {
    name = "Filler",
    type = TYPE_FILLER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_min_w = kwargs.min_w or 0
        self.p_min_h = kwargs.min_h or 0

        self.p_clip_children = kwargs.clip_children or false

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        Object.layout(self)

        local min_w = self.p_min_w
        local min_h = self.p_min_h

        if  min_w == -1 then
            local w = self.p_parent
            while w.p_parent do
                  w = w.p_parent
            end
            min_w = w.p_w
        end
        if  min_h == -1 then
            min_h = 1
        end

        self.p_w = max(self.p_w, min_w)
        self.p_h = max(self.p_h, min_h)
    end,

    draw = function(self, sx, sy)
        if self.p_clip_children then
            clip_push(sx, sy, self.p_w, self.p_h)
            Object.draw(self, sx, sy)
            clip_pop()
        else
            return Object.draw(self, sx, sy)
        end
    end
}

local Offsetter = Object:clone {
    name = "Offsetter",
    type = TPYPE_OFFSETTER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_offset_h = kwargs.offset_h or 0
        self.p_offset_v = kwargs.offset_v or 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        Object.layout(self)

        local oh, ov = self.p_offset_h, self.p_offset_v

        loop_children(self, function(o)
            o.p_x = o.p_x + oh
            o.p_y = o.p_y + ov
        end)

        self.p_w = self.p_w + oh
        self.p_h = self.p_h + ov
    end,

    adjust_children = function(self)
        local oh, ov = self.p_offset_h, self.p_offset_v
        Object.adjust_children_to(self, oh, ov, self.p_w - oh, self.p_h - ov)
    end
}

local Clipper = Object:clone {
    name = "Clipper",
    type = TYPE_CLIPPER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_clip_w = kwargs.clip_w or 0
        self.p_clip_h = kwargs.clip_h or 0
        self.i_virt_w = 0
        self.i_virt_h = 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        Object.layout(self)
    
        self.i_virt_w = self.p_w
        self.i_virt_h = self.p_h

        local cw, ch = self.p_clip_w, self.p_clip_h

        if cw ~= 0 then self.p_w = min(self.p_w, cw) end
        if ch ~= 0 then self.p_h = min(self.p_h, ch) end
    end,

    adjust_children = function(self)
        Object.adjust_children_to(self, 0, 0, self.i_virt_w, self.i_virt_h)
    end,

    draw = function(self, sx, sy)
        local cw, ch = self.p_clip_w, self.p_clip_h

        if (cw ~= 0 and self.i_virt_w > cw) or (ch ~= 0 and self.i_virt_h > ch)
        then
            clip_push(sx, sy, self.p_w, self.p_h)
            Object.draw(self, sx, sy)
            clip_pop()
        else
            return Object.draw(self, sx, sy)
        end
    end
}

local Conditional = Object:clone {
    name = "Conditional",
    type = TYPE_CONDITIONAL,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_condition = kwargs.condition
        return Object.__init(self, kwargs)
    end,

    choose_state = function(self)
        return (self.p_condition and self:p_condition()) and "true" or "false"
    end
}

local Button = Object:clone {
    name = "Button",
    type = TYPE_BUTTON,

    choose_state = function(self)
        return is_clicked(self) and "clicked" or
            (is_hovering(self) and "hovering" or "default")
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end
}

local Conditional_Button = Button:clone {
    name = "Conditional_Button",
    type = TYPE_CONDITIONAL_BUTTON,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_condition = kwargs.condition
        return Button.__init(self, kwargs)
    end,

    choose_state = function(self)
        return ((self.p_condition and self:p_condition()) and
            (is_clicked(self) and "true_clicked" or
                (is_hovering(self) and "true_hovering" or "true")) or "false")
    end,

    clicked = function(self, cx, cy)
        if self.p_condition and self:p_condition() then
            Object.clicked(self, cx, cy)
        end
    end
}

local Toggle = Button:clone {
    name = "Toggle",
    type = TYPE_TOGGLE,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_condition = kwargs.condition
        return Button.__init(self, kwargs)
    end,

    choose_state = function(self)
        local h = is_hovering(self)
        return (self.p_condition and self:p_condition() and
            (h and "toggled_hovering" or "toggled") or
            (h and "default_hovering" or "default"))
    end,
}

local H_Scrollbar
local V_Scrollbar

local Scroller = Clipper:clone {
    name = "Scroller",
    type = TYPE_SCROLLER,

    __init = function (self, kwargs)
        kwargs = kwargs or {}

        self.i_offset_h = 0
        self.i_offset_v = 0
        self.i_can_scroll = 0

        return Clipper.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        local oh, ov, vw, vh = self.i_offset_h, self.i_offset_v,
            self.i_virt_w, self.i_virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then return nil end

        return Object.target(self, cx + oh, cy + ov)
    end,

    hover = function(self, cx, cy)
        local oh, ov, vw, vh = self.i_offset_h, self.i_offset_v,
            self.i_virt_w, self.i_virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then
            self.i_can_scroll = false
            return nil
        end

        self.i_can_scroll = true
        return Object.hover(self, cx + oh, cy + ov)
    end,

    click = function(self, cx, cy)
        local oh, ov, vw, vh = self.i_offset_h, self.i_offset_v,
            self.i_virt_w, self.i_virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then return nil end

        return Object.click(self, cx + oh, cy + ov)
    end,

    key_hover = function(self, code, isdown)
        local m4, m5 = key.MOUSE4, key.MOUSE5
        if code ~= m4 or code ~= m5 then
            return Object.key_hover(self, code, isdown)
        end

        if not self.i_can_scroll or not isdown then
            return false
        end

        local  sb = self:find_sibling(TYPE_SCROLLBAR)
        if not sb then return false end

        local adjust = (code == m4 and -0.2 or 0.2) * sb.p_arrow_speed
        if sb.__proto == V_Scrollbar then
            self:scroll_v(adjust)
        else
            self:scroll_h(adjust)
        end

        return true
    end,

    draw = function(self, sx, sy)
        if (self.p_clip_w ~= 0 and self.i_virt_w > self.p_clip_w) or
           (self.p_clip_h ~= 0 and self.i_virt_h > self.p_clip_h)
        then
            clip_push(sx, sy, self.p_w, self.p_h)
            Object.draw(self, sx - self.i_offset_h, sy - self.i_offset_v)
            clip_pop()
        else
            return Object.draw(self, sx, sy)
        end
    end,

    get_h_limit = function(self)
        return max(self.i_virt_w - self.p_w, 0)
    end,

    get_v_limit = function(self)
        return max(self.i_virt_h - self.p_h, 0)
    end,

    get_h_offset = function(self)
        return self.i_offset_h / max(self.i_virt_w, self.p_w)
    end,

    get_v_offset = function(self)
        return self.i_offset_v / max(self.i_virt_h, self.p_h)
    end,

    get_h_scale = function(self)
        return self.p_w / max(self.i_virt_w, self.p_w)
    end,

    get_v_scale = function(self)
        return self.p_h / max(self.i_virt_h, self.p_h)
    end,

    set_h_scroll = function(self, hs)
        self.i_offset_h = clamp(hs, 0, self:get_h_limit())
    end,

    set_v_scroll = function(self, vs)
        self.i_offset_v = clamp(vs, 0, self:get_v_limit())
    end,

    scroll_h = function(self, hs)
        self:set_h_scroll(self.i_offset_h + hs)
    end,

    scroll_v = function(self, vs)
        self:set_v_scroll(self.i_offset_v + vs)
    end
}

local Scrollbar = Object:clone {
    name = "Scrollbar",
    type = TYPE_SCROLLBAR,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_arrow_size  = kwargs.arrow_size  or 0
        self.p_arrow_speed = kwargs.arrow_speed or 0
        self.i_arrow_dir   = 0

        return Object.__init(self, kwargs)
    end,

    choose_direction = function(self, cx, cy)
        return 0
    end,

    hover = function(self, cx, cy)
        return Object.hover(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    click = function(self, cx, cy)
        return Object.click(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    scroll_to = function(self, cx, cy) end,

    key_hover = function(self, code, isdown)
        local m4, m5 = key.MOUSE4, key.MOUSE5
        if code ~= m4 or code ~= m5 then
            return Object.key_hover(self, code, isdown)
        end

        if not not isdown then return false end

        local  sc = self:find_sibling(TYPE_SCROLLER)
        if not sc or not sc.i_can_scroll then return false end

        local adjust = (code == m4 and -0.2 or 0.2) * self.p_arrow_speed
        if self.__proto == V_Scrollbar then
            sc:scroll_v(adjust)
        else
            sc:scroll_h(adjust)
        end

        return true
    end,

    clicked = function(self, cx, cy)
        local id = self:choose_direction(cx, cy)
        self.i_arrow_dir = id

        if id == 0 then
            self:scroll_to(cx, cy)
        else
            self:hovering(cx, cy)
        end

        return Object.clicked(self, cx, cy)
    end,

    arrow_scroll = function(self) end,

    hovering = function(self, cx, cy)
        if is_clicked(self) then
            if self.i_arrow_dir ~= 0 then
                self:arrow_scroll()
            end
        else
            local button = self:find_child(TYPE_SCROLL_BUTTON, nil, false)
            if button and is_clicked(button) then
                self.i_arrow_dir = 0
                button:hovering(cx - button.p_x, cy - button.p_y)
            else
                self.i_arrow_dir = self:choose_direction(cx, cy)
            end
        end
    end,

    move_button = function(self, o, fromx, fromy, tox, toy) end
}

local Scroll_Button = Object:clone {
    name = "Scroll_Button",
    type = TYPE_SCROLL_BUTTON,

    __init = function(self, kwargs)
        self.i_offset_h = 0
        self.i_offset_v = 0

        return Object.__init(self, kwargs)
    end,

    choose_state = function(self)
        return is_clicked(self) and "clicked" or
            (is_hovering(self) and "hovering" or "default")
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    hovering = function(self, cx, cy)
        local p = self.p_parent
        if is_clicked(self) and p and p.type == TYPE_SCROLLBAR then
            p:move_button(self, self.i_offset_h, self.i_offset_v, cx, cy)
        end
    end,

    clicked = function(self, cx, cy)
        self.i_offset_h = cx
        self.i_offset_v = cy

        return Object.clicked(self, cx, cy)
    end
}

H_Scrollbar = Scrollbar:clone {
    name = "H_Scrollbar",

    choose_state = function(self)
        local ad = self.i_arrow_dir

        if ad == -1 then
            return is_clicked(self) and "up_clicked" or
                (is_hovering(self) and "up_hovering" or "default")
        elseif ad == 1 then
            return is_clicked(self) and "down_clicked" or
                (is_hovering(self) and "down_hovering" or "default")
        end
        return "default"
    end,

    choose_direction = function(self, cx, cy)
        local as = self.p_arrow_size
        return (cx < as) and -1 or (cx >= (self.p_w - as) and 1 or 0)
    end,

    arrow_scroll = function(self)
        local  scroll = self:find_sibling(TYPE_SCROLLER)
        if not scroll then return nil end

        scroll:scroll_h(self.i_arrow_dir * self.p_arrow_speed *
            frame.get_frame_time())
    end,

    scroll_to = function(self, cx, cy)
        local  scroll = self:find_sibling(TYPE_SCROLLER)
        if not scroll then return nil end

        local  btn = self:find_child(TYPE_SCROLL_BUTTON, nil, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local bscale = (max(self.p_w - 2 * as, 0) - btn.p_w) /
            (1 - scroll:get_h_scale())

        local offset = (bscale > 0.001) and (cx - as) / bscale or 0

        scroll.set_h_scroll(scroll, offset * scroll.i_virt_w)
    end,

    adjust_children = function(self)
        local  scroll = self:find_sibling(TYPE_SCROLLER)
        if not scroll then return nil end

        local  btn = self:find_child(TYPE_SCROLL_BUTTON, nil, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local sw, btnw = self.p_w, btn.p_w

        local bw = max(sw - 2 * as, 0) * scroll:get_h_scale()
        btn.p_w  = max(btnw, bw)

        local bscale = (scroll:get_h_scale() < 1) and
            (max(sw - 2 * as, 0) - btn.p_w) / (1 - scroll:get_h_scale()) or 1

        btn.p_x = as + scroll:get_h_offset() * bscale
        btn.i_adjust = band(btn.i_adjust, bnot(ALIGN_HMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.p_x + tox - fromx, o.p_y + toy)
    end
}

V_Scrollbar = Scrollbar:clone {
    name = "V_Scrollbar",

    choose_state = function(self)
        local ad = self.i_arrow_dir

        if ad == -1 then
            return is_clicked(self) and "left_clicked" or
                (is_hovering(self) and "left_hovering" or "default")
        elseif ad == 1 then
            return is_clicked(self) and "right_clicked" or
                (is_hovering(self) and "right_hovering" or "default")
        end
        return "default"
    end,

    choose_direction = function(self, cx, cy)
        local as = self.p_arrow_size
        return (cy < as) and -1 or (cy >= (self.p_h - as) and 1 or 0)
    end,

    arrow_scroll = function(self)
        local  scroll = self:find_sibling(TYPE_SCROLLER)
        if not scroll then return nil end

        scroll:scroll_v(self.i_arrow_dir * self.p_arrow_speed *
            frame.get_frame_time())
    end,

    scroll_to = function(self, cx, cy)
        local  scroll = self:find_sibling(TYPE_SCROLLER)
        if not scroll then return nil end

        local  btn = self:find_child(TYPE_SCROLL_BUTTON, nil, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local bscale = (max(self.p_h - 2 * as, 0) - btn.p_h) /
            (1 - scroll:get_v_scale())

        local offset = (bscale > 0.001) and
            (cy - as) / bscale or 0

        scroll:set_v_scroll(offset * scroll.i_virt_h)
    end,

    adjust_children = function(self)
        local  scroll = self:find_sibling(TYPE_SCROLLER)
        if not scroll then return nil end

        local  btn = self:find_child(TYPE_SCROLL_BUTTON, nil, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local sh, btnh = self.p_h, btn.p_h

        local bh = max(sh - 2 * as, 0) * scroll:get_v_scale()

        btn.p_h = max(btnh, bh)

        local bscale = (scroll:get_v_scale() < 1) and
            (max(sh - 2 * as, 0) - btn.p_h) / (1 - scroll:get_v_scale()) or 1

        btn.p_y = as + scroll:get_v_offset() * bscale
        btn.i_adjust = band(btn.i_adjust, bnot(ALIGN_VMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.p_x + tox, o.p_y + toy - fromy)
    end
}

local Slider = Object:clone {
    name = "Slider",
    type = TYPE_SLIDER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_min_value = kwargs.min_value or 0
        self.p_max_value = kwargs.max_value or 0
        self.p_value     = kwargs.value     or 0

        if kwargs.var then
            local varn = kwargs.var
            self.i_var = varn

            if not var.exists(varn) then
                var.new(varn, var.INT, self.p_value)
            end

--            if not var.is_alias(varn) then
                local mn, mx = var.get_min(varn), var.get_max(varn)
                self.p_min_value = clamp(self.p_min_value, mn, mx)
                self.p_max_value = clamp(self.p_max_value, mn, mx)
--            end
        end

        self.p_arrow_size = kwargs.arrow_size or 0
        self.p_step_size  = kwargs.step_size  or 1
        self.p_step_time  = kwargs.step_time  or 1000

        self.i_last_step = 0
        self.i_arrow_dir = 0

        return Object.__init(self, kwargs)
    end,

    do_step = function(self, n)
        local mn, mx, ss = self.p_min_value, self.p_max_value, self.p_step_size

        local maxstep = abs(mx - mn) / ss
        local curstep = (self.p_value - min(mn, mx)) / ss
        local newstep = clamp(curstep + n, 0, maxstep)

        local val = min(mx, mn) + newstep * ss
        self.value = val

        local varn = self.i_var
        if varn then update_var(varn, val) end
    end,

    set_step = function(self, n)
        local mn, mx, ss = self.p_min_value, self.p_max_value, self.p_step_size

        local steps   = abs(mx - mn) / ss
        local newstep = clamp(n, 0, steps)

        local val = min(mx, mn) + newstep * ss
        self.value = val

        local varn = self.i_var
        if varn then update_var(varn, val) end
    end,

    key_hover = function(self, code, isdown)
        if code == key.UP or code == key.LEFT then
            if isdown then self:do_step(-1) end
            return true
        elseif code == key.MOUSE4 then
            if isdown then self:do_step(-3) end
            return true
        elseif code == key.DOWN or code == key.RIGHT then
            if isdown then self:do_step(1) end
            return true
        elseif code == key.MOUSE5 then
            if isdown then self:do_step(3) end
            return true
        end

        return Object.key_hover(self, code, isdown)
    end,

    choose_direction = function(self, cx, cy)
        return 0
    end,

    hover = function(self, cx, cy)
        return Object.hover(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    click = function(self, cx, cy)
        return Object.click(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    scroll_to = function(self, cx, cy) end,

    clicked = function(self, cx, cy)
        local ad = self.choose_direction(self, cx, cy)
        self.i_arrow_dir = ad

        if ad == 0 then
            self:scroll_to(cx, cy)
        else
            self:hovering(cx, cy)
        end

        return Object.clicked(self, cx, cy)
    end,

    arrow_scroll = function(self)
        local tmillis = _C.totalmillis()
        if (self.i_last_step + self.p_step_time) > tmillis then
            return nil
        end

        self.i_last_step = tmillis
        self.do_step(self, self.i_arrow_dir)
    end,

    hovering = function(self, cx, cy)
        if is_clicked(self) then
            if self.i_arrow_dir ~= 0 then
                self:arrow_scroll()
            end
        else
            local button = self:find_child(TYPE_SLIDER_BUTTON, nil, false)

            if button and is_clicked(button) then
                self.i_arrow_dir = 0
                button.hovering(button, cx - button.p_x, cy - button.p_y)
            else
                self.i_arrow_dir = self:choose_direction(cx, cy)
            end
        end
    end,

    move_button = function(self, o, fromx, fromy, tox, toy) end
}

local Slider_Button = Object:clone {
    name = "Slider_Button",
    type = TYPE_SLIDER_BUTTON,

    __init = function(self, kwargs)
        self.i_offset_h = 0
        self.i_offset_v = 0

        return Object.__init(self, kwargs)
    end,

    choose_state = function(self)
        return is_clicked(self) and "clicked" or
            (is_hovering(self) and "hovering" or "default")
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    hovering = function(self, cx, cy)
        local p = self.p_parent

        if is_clicked(self) and p and p.type == TYPE_SLIDER then
            p:move_button(self, self.i_offset_h, self.i_offset_v, cx, cy)
        end
    end,

    clicked = function(self, cx, cy)
        self.i_offset_h = cx
        self.i_offset_v = cy

        return Object.clicked(self, cx, cy)
    end,

    layout = function(self)
        local lastw = self.p_w
        local lasth = self.p_h

        Object.layout(self)

        if is_clicked(self) then
            self.p_w = lastw
            self.p_h = lasth
        end
    end
}

local H_Slider = Slider:clone {
    name = "H_Slider",

    choose_state = function(self)
        local ad = self.i_arrow_dir

        if ad == -1 then
            return is_clicked(self) and "up_clicked" or
                (is_hovering(self) and "up_hovering" or "default")
        elseif ad == 1 then
            return is_clicked(self) and "down_clicked" or
                (is_hovering(self) and "down_hovering" or "default")
        end
        return "default"
    end,

    choose_direction = function(self, cx, cy)
        local as = self.p_arrow_size
        return cx < as and -1 or (cx >= (self.p_w - as) and 1 or 0)
    end,

    scroll_to = function(self, cx, cy)
        local  btn = self:find_child(TYPE_SLIDER_BUTTON, nil, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local sw, bw = self.p_w, btn.p_w

        self.set_step(self, round((abs(self.p_max_value - self.p_min_value) /
            self.p_step_size) * clamp((cx - as - bw / 2) /
                (sw - 2 * as - bw), 0.1, 1)))
    end,

    adjust_children = function(self)
        local  btn = self:find_child(TYPE_SLIDER_BUTTON, nil, false)
        if not btn then return nil end

        local mn, mx, ss = self.p_min_value, self.p_max_value, self.p_step_size

        local steps   = abs(mx - mn) / self.p_step_size
        local curstep = (self.p_value - min(mx, mn)) / ss

        local as = self.p_arrow_size

        local width = max(self.p_w - 2 * as, 0)

        btn.p_w = max(btn.p_w, width / steps)
        btn.p_x = as + (width - btn.p_w) * curstep / steps
        btn.i_adjust = band(btn.i_adjust, bnot(ALIGN_HMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.p_x + o.p_w / 2 + tox - fromx, o.p_y + toy)
    end
}

local V_Slider = Slider:clone {
    name = "V_Slider",

    choose_state = function(self)
        local ad = self.i_arrow_dir

        if ad == -1 then
            return is_clicked(self) and "left_clicked" or
                (is_hovering(self) and "left_hovering" or "default")
        elseif ad == 1 then
            return is_clicked(self) and "right_clicked" or
                (is_hovering(self) and "right_hovering" or "default")
        end
        return "default"
    end,

    choose_direction = function(self, cx, cy)
        local as = self.p_arrow_size
        return cy < as and -1 or (cy >= (self.p_h - as) and 1 or 0)
    end,

    scroll_to = function(self, cx, cy)
        local  btn = self:find_child(TYPE_SLIDER_BUTTON, nil, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local sh, bh = self.p_h, btn.p_h
        local mn, mx = self.p_min_value, self.p_max_value

        self.set_step(self, round(((max(mx, mn) - min(mx, mn)) /
            self.p_step_size) * clamp((cy - as - bh / 2) /
                (sh - 2 * as - bh), 0.1, 1)))
    end,

    adjust_children = function(self)
        local  btn = self:find_child(TYPE_SLIDER_BUTTON, nil, false)
        if not btn then return nil end

        local mn, mx, ss = self.p_min_value, self.p_max_value, self.p_step_size

        local steps   = (max(mx, mn) - min(mx, mn)) / ss + 1
        local curstep = (self.p_value - min(mx, mn)) / ss

        local as = self.p_arrow_size

        local height = max(self.p_h - 2 * as, 0)

        btn.p_h = max(btn.p_h, height / steps)
        btn.p_y = as + (height - btn.p_h) * curstep / steps
        btn.i_adjust = band(btn.i_adjust, bnot(ALIGN_VMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self.scroll_to(self, o.p_x + o.p_h / 2 + tox, o.p_y + toy - fromy)
    end
}

local Rectangle = Filler:clone {
    name = "Rectangle",
    type = TYPE_RECTANGLE,

    __init = function(self, kwargs)
        kwargs       = kwargs or {}
        self.p_solid = kwargs.solid == false and false or true
        self.p_r     = kwargs.r or 255
        self.p_g     = kwargs.g or 255
        self.p_b     = kwargs.b or 255
        self.p_a     = kwargs.a or 255

        return Filler.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    draw = function(self, sx, sy)
        local w, h, solid = self.p_w, self.p_h, self.p_solid

        if not solid then _C.gl_blend_func(gl.ZERO, gl.SRC_COLOR) end
        _C.shader_hudnotexture_set()
        _C.gle_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        _C.gle_defvertex(2)
        _C.gle_begin(gl.TRIANGLE_STRIP)

        _C.gle_attrib2f(sx,     sy)
        _C.gle_attrib2f(sx + w, sy)
        _C.gle_attrib2f(sx,     sy + h)
        _C.gle_attrib2f(sx + w, sy + h)

        _C.gle_end()
        _C.gle_color4f(1, 1, 1, 1)
        _C.shader_hud_set()
        if not solid then
            _C.gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        end

        return Filler.draw(self, sx, sy)
    end
}

local check_alpha_mask = function(tex, x, y)
    if not tex:get_alphamask() then
        _C.texture_load_alpha_mask(tex)
        if not tex:get_alphamask() then
            return true
        end
    end

    local xs, ys = tex:get_xs(), tex:get_ys()
    local tx, ty = clamp(floor(x * xs), 0, xs - 1),
                   clamp(floor(y * ys), 0, ys - 1)

    local m = tex:get_alphamask(ty * ((xs + 7) / 8))
    if band(m, blsh(1, tx % 8)) ~= 0 then
        return true
    end

    return false
end

Image = Filler:clone {
    name = "Image",
    type = TYPE_IMAGE,

    __init = function(self, kwargs)
        kwargs    = kwargs or {}
        local tex = kwargs.file and _C.texture_load(kwargs.file)

        local af = kwargs.alt_file
        if _C.texture_is_notexture(tex) and af then
            tex = _C.texture_load(af)
        end

        self.i_tex = tex
        self.p_min_filter = kwargs.min_filter
        self.p_mag_filter = kwargs.mag_filter

        self.p_r     = kwargs.r or 255
        self.p_g     = kwargs.g or 255
        self.p_b     = kwargs.b or 255
        self.p_a     = kwargs.a or 255

        return Filler.__init(self, kwargs)
    end,

    get_tex = function()
        return self.i_tex:get_name()
    end,

    get_tex_raw = function()
        return self.i_tex
    end,

    set_tex = function(file, alt)
        local tex = _C.texture_load(file)
        if _C.texture_is_notexture(tex) and alt then
              tex = _C.texture_load(alt)
        end
        self.i_tex   = tex
        needs_adjust = true
    end,

    set_tex_raw = function(tex)
        self.i_tex   = tex
        needs_adjust = true
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.i_tex
        return (tex:get_bpp() < 32 or check_alpha_mask(tex, cx / self.p_w,
                                                      cy / self.p_h)) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gle_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.p_w, self.p_h)
        _C.gle_end()

        return Object.draw(self, sx, sy)
    end,

    layout = function(self)
        Object.layout(self)

        local min_w = self.p_min_w
        local min_h = self.p_min_h

        if min_w and min_w < 0 then
            min_w = abs(min_w) / _V.scr_h
        end

        if min_h and min_h < 0 then
            min_h = abs(min_h) / _V.scr_h
        end

        if  min_w == -1 then
            local w = self.parent
            while w.parent do
                  w = w.parent
            end
            min_w = w.p_w
        end
        if  min_h == -1 then
            min_h = 1
        end

        if  min_w == 0 or min_h == 0 then
            local tex, scrh = self.i_tex, _V.scr_h
            if  min_w == 0 then
                min_w = tex:get_w() / scrh
            end
            if  min_h == 0 then
                min_h = tex:get_h() / scrh
            end
        end

        self.p_w = max(self.p_w, min_w)
        self.p_h = max(self.p_h, min_h)
    end
}

local get_border_size = function(tex, size, vert)
    if size >= 0 then
        return size
    end

    return abs(n) / (vert and tex:get_ys() or tex:get_xs())
end

local Cropped_Image = Image:clone {
    name = "Cropped_Image",

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        Image.__init(self, kwargs)
        local tex = self.i_tex

        self.p_crop_x = get_border_size(tex, kwargs.crop_x or 0, false)
        self.p_crop_y = get_border_size(tex, kwargs.crop_y or 0, true)
        self.p_crop_w = get_border_size(tex, kwargs.crop_w or 1, false)
        self.p_crop_h = get_border_size(tex, kwargs.crop_h or 1, true)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.i_tex
        return (tex:get_bpp() < 32 or check_alpha_mask(tex,
            self.p_crop_x + cx / self.p_w * self.p_crop_w,
            self.p_crop_y + cy / self.p_h * self.p_crop_h)) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gle_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.p_w, self.p_h,
            self.p_crop_x, self.p_crop_y, self.p_crop_w, self.p_crop_h)
        _C.gle_end()

        return Object.draw(self, sx, sy)
    end
}

local Stretched_Image = Image:clone {
    name = "Stretched_Image",

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end
        if self.i_tex:get_bpp() < 32 then return self end

        local mx, my, mw, mh, pw, ph = 0, 0, self.p_min_w, self.p_min_h,
                                             self.p_w,     self.p_h

        if     pw <= mw          then mx = cx / pw
        elseif cx <  mw / 2      then mx = cx / mw
        elseif cx >= pw - mw / 2 then mx = 1 - (pw - cx) / mw
        else   mx = 0.5 end

        if     ph <= mh          then my = cy / ph
        elseif cy <  mh / 2      then my = cy / mh
        elseif cy >= ph - mh / 2 then my = 1 - (ph - cy) / mh
        else   my = 0.5 end

        return check_alpha_mask(self.i_tex, mx, my) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gle_begin(gl.QUADS)

        local mw, mh, pw, ph = self.p_min_w, self.p_min_h, self.p_w, self.p_h

        local splitw = (mw ~= 0 and min(mw, pw) or pw) / 2
        local splith = (mh ~= 0 and min(mh, ph) or ph) / 2
        local vy, ty = sy, 0

        for i = 1, 3 do
            local vh, th = 0, 0
            if i == 1 then
                if splith < ph - splith then
                    vh, th = splith, 0.5
                else
                    vh, th = ph, 1
                end
            elseif i == 2 then
                vh, th = ph - 2 * splith, 0
            elseif i == 3 then
                vh, th = splith, 0.5
            end

            local vx, tx = sx, 0

            for j = 1, 3 do
                local vw, tw = 0, 0
                if j == 1 then
                    if splitw < pw - splitw then
                        vw, tw = splitw, 0.5
                    else
                        vw, tw = pw, 1
                    end
                elseif j == 2 then
                    vw, tw = pw - 2 * splitw, 0
                elseif j == 3 then
                    vw, tw = splitw, 0.5
                end
                quad(vx, vy, vw, vh, tx, ty, tw, th)
                vx, tx = vx + vw, tx + tw
                if  tx >= 1 then break end
            end
            vy, ty = vy + vh, ty + th
            if  ty >= 1 then break end
        end

        _C.gle_end()

        return Object.draw(self, sx, sy)
    end
}

local Bordered_Image = Image:clone {
    name = "Bordered_Image",

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        Image.__init(self, kwargs)

        self.p_tex_border    = get_border_size(self.i_tex,
                                               kwargs.tex_border or 0)
        self.p_screen_border = kwargs.screen_border or 0
    end,

    layout = function(self)
        Object.layout(self)

        local sb = self.p_screen_border
        self.p_w = max(self.p_w, 2 * sb)
        self.p_h = max(self.p_h, 2 * sb)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.i_tex

        if tex:get_bpp() < 32 then
            return self
        end

        local mx, my, tb, sb = 0, 0, self.p_tex_border, self.p_screen_border
        local pw, ph = self.p_w, self.p_h

        if     cx <  sb      then mx = cx / sb * tb
        elseif cx >= pw - sb then mx = 1 - tb + (cx - (pw - sb)) / sb * tb
        else   mx = tb + (cx - sb) / (pw - 2 * sb) * (1 - 2 * tb) end

        if     cy <  sb      then my = cy / sb * tb
        elseif cy >= ph - sb then my = 1 - tb + (cy - (ph - sb)) / sb * tb
        else   my = tb + (cy - sb) / (ph - 2 * sb) * (1 - 2 * tb) end

        return check_alpha_mask(tex, mx, my) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gle_begin(gl.QUADS)

        local vy, ty = sy, 0
        for i = 1, 3 do
            local vh, th = 0, 0
            if i == 2 then
                vh, th = self.p_h - 2 * sb, 1 - 2 * tb
            else
                vh, th = sb, tb
            end
            local vx, tx = sx, 0
            for j = 1, 3 do
                local vw, tw = 0, 0
                if j == 2 then
                    vw, tw = self.p_w - 2 * sb, 1 - 2 * tb
                else
                    vw, tw = sb, tb
                end
                quad(vx, vy, vw, vh, tx, ty, tw, th)
                vx, tx = vx + vw, tx + tw
            end
            vy, ty = vy + vh, ty + th
        end

        _C.gle_end()

        return Object.draw(self, sx, sy)
    end
}

local Tiled_Image = Image:clone {
    name = "Tiled_Image",

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.p_tile_w = kwargs.tile_w or 0
        self.p_tile_h = kwargs.tile_h or 0

        return Image.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.i_tex

        if tex:get_bpp() < 32 then return self end

        local tw, th = self.p_tile_w, self.p_tile_h
        local dx, dy = cx % tw, cy % th

        return check_alpha_mask(tex, dx / tw, dy / th) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        local pw, ph, tw, th = self.p_w, self.p_h, self.p_tile_w, self.p_tile_h

        -- we cannot use the built in OpenGL texture
        -- repeat with clamped textures
        if tex:get_clamp() ~= 0 then
            local dx, dy = 0, 0
            _C.gle_defvertex(2)
            _C.gle_deftexcoord0(2)
            _C.gle_begin(gl.QUADS)
            while dx < pw do
                while dy < ph do
                    local dw, dh = min(tw, pw - dx), min(th, ph - dy)
                    quad(sx + dx, sy + dy, dw, dh, 0, 0, dw / tw, dh / th)
                    dy = dy + th
                end
                dx, dy = dy + tw, 0
            end
            _C.gle_end()
        else
            _C.gle_defvertex(2)
            _C.gle_deftexcoord0(2)
            _C.gle_begin(gl.TRIANGLE_STRIP)
            quadtri(sx, sy, pw, ph, 0, 0, pw / tw, ph / th)
            _C.gle_end()
        end

        return Object.draw(self, sx, sy)
    end
}

local Slot_Viewer = Filler:clone {
    name = "Slot_Viewer",

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_slot = kwargs.slot or 0

        return Filler.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o or not _C.slot_exists(self.p_slot) then return o end
        return _C.slot_check_vslot(self.p_slot) and self
    end,

    draw = function(self, sx, sy)
        _C.texture_draw_slot(self.p_slot, self.p_w, self.p_h, sx, sy)
        return Object.draw(self, sx, sy)
    end
}

-- default size of text in terms of rows per screenful
var.new("uitextrows", var.INT, 1, 40, 200, var.PERSIST)

local Label = Object:clone {
    name = "Label",

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.p_text  = kwargs.text  or ""
        self.p_scale = kwargs.scale or  1
        self.p_wrap  = kwargs.wrap  or -1
        self.p_r     = kwargs.r or 255
        self.p_g     = kwargs.g or 255
        self.p_b     = kwargs.b or 255
        self.p_a     = kwargs.a or 255

        return Object.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    draw_scale = function(self)
        return self.p_scale / (_V["fonth"] * _V["uitextrows"])
    end,

    draw = function(self, sx, sy)
        _C.hudmatrix_push()

        local k = self:draw_scale()
        _C.hudmatrix_scale(k, k, 1)
        _C.hudmatrix_flush()

        local w = self.p_wrap
        _C.text_draw(self.p_text, sx / k, sy / k,
            self.p_r, self.p_g, self.p_b, self.p_a, -1, w <= 0 and -1 or w / k)

        _C.gle_color4f(1, 1, 1, 1)
        _C.hudmatrix_pop()

        return Object.draw(self, sx, sy)
    end,

    layout = function(self)
        Object.layout(self)

        local k = self:draw_scale()

        local w, h = _C.text_get_bounds(self.p_text,
            self.p_wrap <= 0 and -1 or self.p_wrap / k)

        if self.p_wrap <= 0 then
            self.p_w = max(self.p_w, w * k)
        else
            self.p_w = max(self.p_w, min(self.p_wrap, w * k))
        end

        self.p_h = max(self.p_h, h * k)
    end
}

local textediting   = nil
local refreshrepeat = 0

local clipboard = {}

local Text_Editor = Object:clone {
    name = "Text_Editor",
    type = TYPE_TEXT_EDITOR,

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        local length = kwargs.length or 0
        local height = kwargs.height or 1
        local scale  = kwargs.scale  or 1

        self.lastaction = _C.totalmillis()
        self.scale      = scale

        self.i_offset_h = 0
        self.i_offset_v = 0

        self.name     = kwargs.name
        self.filename = nil

        -- cursor position - ensured to be valid after a region() or
        -- currentline()
        self.cx = 0
        self.cy = 0
        -- selection mark, mx = -1 if following cursor - avoid direct access,
        -- instead use region()
        self.mx = -1
        self.my = -1
        -- maxy = -1 if unlimited lines, 1 if single line editor
        self.maxx = length <  0 and -1 or length
        self.maxy = height <= 0 and  1 or -1

        self.scrolly = 0 -- vertical scroll offset

        self.line_wrap = length < 0
        -- required for up/down/hit/draw/bounds
        self.pixel_width  = math.abs(length) * _V.fontw
        -- -1 for variable size, i.e. from bounds
        self.pixel_height = -1

        self.password = kwargs.is_password or false

        -- must always contain at least one line
        self.lines = { kwargs.value or "" }

        if length < 0 and height <= 0 then
            local w, h = _C.text_get_bounds(self.lines[1], self.pixel_width)
            self.pixel_height = h
        else
            self.pixel_height = _V.fonth * math.max(height, 1)
        end

        return Object.__init(self, kwargs)
    end,

    clear = function(self)
        if self == textediting then
            textediting = nil
        end

        refreshrepeat = refreshrepeat + 1

        return Object:clear()
    end,

    edit_clear = function(self, init)
        self.cx = 0
        self.cy = 0

        self:mark(false)

        if init == false then
            self.lines = {}
        else
            self.lines = { init or "" }
        end
    end,

    mark = function(self, enable)
        self.mx = enable and self.cx or -1
        self.my = self.cy
    end,

    select_all = function(self)
        self.cx = 0
        self.cy = 0
        self.mx = 1 / 0
        self.my = 1 / 0
    end,

    -- constrain results to within buffer - s = start, e = end, return true if
    -- a selection range also ensures that cy is always within lines[] and cx
    -- is valid
    region = function(self)
        local sx, sy, ex, ey

        local  n = #self.lines
        assert(n ~= 0)

        local cx, cy, mx, my = self.cx, self.cy, self.mx, self.my

        if cy < 0 then cy = 0 elseif cy >= n then cy = n - 1 end
        local len = #self.lines[cy + 1]
        if cx < 0 then cx = 0 elseif cx > len then cx = len end
        if mx >= 0 then
            if my < 0 then my = 0 elseif my >= n then my = n - 1 end
            len = #self.lines[my + 1]
            if mx > len then mx = len end
        end
        sx, sy = (mx >= 0) and mx or cx, (mx >= 0) and my or cy -- XXX
        ex, ey = cx, cy
        if     sy >  ey             then sy, ey, sx, ex = ey, sy, ex, sx
        elseif sy == ey and sx > ex then sx, ex         = ex, sx end

        self.cx, self.cy, self.mx, self.my = cx, cy, mx, my

        return ((sx ~= ex) or (sy ~= ey)), sx, sy, ex, ey
    end,

    -- also ensures that cy is always within lines[] and cx is valid
    current_line = function(self)
        local  n = #self.lines
        assert(n ~= 0)

        if     self.cy <  0 then self.cy = 0
        elseif self.cy >= n then self.cy = n - 1 end

        local len = #self.lines[self.cy + 1]

        if     self.cx < 0   then self.cx = 0
        elseif self.cx > len then self.cx = len end

        return self.lines[self.cy + 1]
    end,

    copy_selection_to = function(self, b)
        if self == b then return nil end

        b:clear(false)
        local sx, sy, ex, ey = select(2, self:region())

        for i = 1, 1 + ey - sy do
            if b.maxy ~= -1 and #b.lines >= b.maxy then break end

            local y = sy + i
            local line = self.lines[y]

            if y - 1 == sy then line = line:sub(sx + 1) end
            b.lines[#b.lines + 1] = line
        end

        if #b.lines == 0 then b.lines = { "" } end
    end,

    to_string = function(self)
        return table.concat(self.lines, "\n")
    end,

    selection_to_string = function(self)
        local buf = {}
        local sx, sy, ex, ey = select(2, self:region())

        for i = 1, 1 + ey - sy do
            local y = sy + i
            local line = self.lines[y]

            if y - 1 == sy then line = line:sub(sx + 1) end

            buf[#buf + 1] = line
            buf[#buf + 1] = "\n"
        end

        return table.concat(buf)
    end,

    remove_lines = function(self, start, count)
        for i = 1, count do
            table.remove(self.lines, start)
        end
    end,

    -- removes the current selection (if any),
    -- returns true if selection was removed
    del = function(self)
        local b, sx, sy, ex, ey = self:region()
        if not b then
            self:mark(false)
            return false
        end

        if sy == ey then
            if sx == 0 and ex == #self.lines[ey + 1] then
                self:remove_lines(sy + 1, 1)
            else self.lines[sy + 1]:del(
                sx + 1, ex - sx)
            end
        else
            if ey > sy + 1 then
                self:remove_lines(sy + 2, ey - (sy + 1))
                ey = sy + 1
            end

            if ex == #self.lines[ey + 1] then
                self:remove_lines(ey + 1, 1)
            else
                self.lines[ey + 1]:del(1, ex)
            end

            if sx == 0 then
                self:remove_lines(sy + 1, 1)
            else
                self.lines[sy + 1]:del(sx + 1,
                    #self.lines[sy] - sx)
            end
        end

        if #self.lines == 0 then self.lines = { "" } end
        self:mark(false)

        self.cx = sx
        self.cy = sy

        local current = self:current_line()
        if self.cx > #current and self.cy < #self.lines - 1 then
            self.lines[self.cy + 1] = table.concat {
                self.lines[self.cy + 1], self.lines[self.cy + 2] }
            self:remove_lines(self.cy + 2, 1)
        end

        return true
    end,

    insert = function(self, ch)
        self:del()
        local current = self:current_line()

        if ch == "\n" then
            if self.maxy == -1 or self.cy < self.maxy - 1 then
                local newline = current:sub(self.cx + 1)
                current = current:sub(1, self.cx)
                self.cy = math.min(#self.lines, self.cy + 1)
                table.insert(self.lines, self.cy + 1, newline)
            else
                current = current:sub(1, self.cx)
            end
            self.cx = 0
        else
            local len = #current
            if self.maxx >= 0 and len > self.maxx - 1 then
                len = self.maxx - 1 end
            if self.cx <= len then
                self.cx = self.cx + 1
                if #ch > 1 then
                    current = current:insert(self.cx, ch:sub(1, 1))
                    self.lines[self.cy + 1] = current
                    self:insert(ch:sub(2))
                else
                    current = current:insert(self.cx, ch)
                    self.lines[self.cy + 1] = current
                end
            end
        end
    end,

    insert_all_from = function(self, b)
        if self == b then return nil end

        self:del()

        if #b.lines == 1 or self.maxy == 1 then
            local current = self:current_line()
            local str  = b.lines[1]
            local slen = #str

            if self.maxx >= 0 and slen + self.cx > self.maxx then
                slen = self.maxx - self.cx
            end

            if slen > 0 then
                local len = #current
                if self.maxx >= 0 and slen + self.cx + len > self.maxx then
                    len = math.max(0, self.maxx - (self.cx + slen))
                end

                current = current:insert(self.cx + 1, slen)
                self.cx = self.cx + slen
            end

            self.lines[self.cy + 1] = current
        else for i = 1, #b.lines do
            if i == 1 then
                self.cy = self.cy + 1
                local newline = self.lines[self.cy]:sub(self.cx + 1)
                self.lines[self.cy] = self.lines[self.cy]:sub(
                    1, self.cx):insert(self.cy + 1, newline)
            elseif i >= #b.lines then
                self.cx = #b.lines[i]
                self.lines[self.cy + 1] = table.concat {
                    b.lines[i], self.lines[self.cy + 1] }
            elseif self.maxy < 0 or #self.lines < self.maxy then
                self.cy = self.cy + 1
                table.insert(self.lines, self.cy, b.lines[i])
            end
        end end
    end,

    movement_mark = function(self)
        self:scroll_on_screen()
        if band(_C.input_get_modifier_state(), mod.SHIFT) ~= 0 then
                if not self:region() then self:mark(true) end
        else
            self:mark(false)
        end
    end,

    scroll_on_screen = function(self)
        self:region()
        self.scrolly = math.clamp(self.scrolly, 0, self.cy)
        local h = 0
        for i = self.cy + 1, self.scrolly + 1, -1 do
            local width, height = _C.text_get_bounds(self.lines[i],
                self.line_wrap and self.pixel_width or -1)
            if h + height > self.pixel_height then
                self.scrolly = i
                break
            end
            h = h + height
        end
    end,

    input = function(self, str)
        for ch in str:gmatch(".") do self:insert(ch) end
    end,

    edit_key = function(self, code)
        local mod_keys
        if ffi.os == "OSX" then
            mod_keys = mod.GUI
        else
            mod_keys = mod.CTRL
        end

        switch(code,
            case(key.UP, function()
                self:movement_mark()
                if self.line_wrap then
                    local str = self:current_line()
                    local x, y = _C.text_get_position(str, self.cx + 1,
                        self.pixel_width)
                    if y > 0 then
                        self.cx = _C.text_is_visible(str, x, y - FONTH,
                            self.pixel_width)
                        self:scroll_on_screen()
                        return nil
                    end
                end
                self.cy = self.cy - 1
                self:scroll_on_screen()
            end),

            case(key.DOWN, function()
                self:movement_mark()
                if self.line_wrap then
                    local str = self:current_line()
                    local x, y = _C.text_get_position(str, self.cx,
                        self.pixel_width)
                    local width, height = _C.text_get_bounds(str,
                        self.pixel_width)
                    y = y + _V.fonth
                    if y < height then
                        self.cx = _C.text_is_visible(str, x, y, self.pixel_width)
                        self:scroll_on_screen()
                        return nil
                    end
                end
                self.cy = self.cy + 1
                self:scroll_on_screen()
            end),

            case(key.MOUSE4, function()
                self.scrolly = self.scrolly - 3
            end),

            case(key.MOUSE5, function()
                self.scrolly = self.scrolly + 3
            end),

            case(key.PAGEUP, function()
                self:movement_mark()
                if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 0
                else
                    self.cy = self.cy - self.pixel_height / _V.fonth
                end
                self:scroll_on_screen()
            end),

            case(key.PAGEDOWN, function()
                self:movement_mark()
                if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 1 / 0
                else
                    self.cy = self.cy + self.pixel_height / _V.fonth
                end
                self:scroll_on_screen()
            end),

            case(key.HOME, function()
                self:movement_mark()
                self.cx = 0
                if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 0
                end
                self:scroll_on_screen()
            end),

            case(key.END, function()
                self:movement_mark()
                self.cx = 1 / 0
                if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 1 / 0
                end
                self:scroll_on_screen()
            end),

            case(key.LEFT, function()
                self:movement_mark()
                if     self.cx > 0 then self.cx = self.cx - 1
                elseif self.cy > 0 then
                    self.cx = 1 / 0
                    self.cy = self.cy - 1
                end
                self:scroll_on_screen()
            end),

            case(key.RIGHT, function()
                self:movement_mark()
                if self.cx < #self.lines[self.cy + 1] then
                    self.cx = self.cx + 1
                elseif self.cy < #self.lines - 1 then
                    self.cx = 0
                    self.cy = self.cy + 1
                end
                self:scroll_on_screen()
            end),

            case(key.DELETE, function()
                if not self:del() then
                    local current = self:current_line()
                    if self.cx < #current then
                        current = current:del(self.cx + 1, 1)
                    elseif self.cy < #self.lines - 1 then
                        -- combine with next line
                        current = table.concat {
                            current, self.lines[self.cy + 2] }
                        self:remove_lines(self.cy + 2, 1)
                    end
                    self.lines[self.cy + 1] = current
                end
                self:scroll_on_screen()
            end),

            case(key.BACKSPACE, function()
                if not self:del() then
                    local current = self:current_line()
                    if self.cx > 0 then
                        self.cx = self.cx - 1
                        self.lines[self.cy + 1] = current:del(self.cx + 1, 1)
                    elseif self.cy > 0 then
                        -- combine with previous line
                        self.cx = #self.lines[self.cy]
                        self.lines[self.cy] = table.concat {
                            self.lines[self.cy], current }
                        self:remove_lines(self.cy + 1, 1)
                        self.cy = self.cy - 1
                    end
                end
                self:scroll_on_screen()
            end),

            case({  key.LSHIFT, key.RSHIFT,
                    key.LCTRL,  key.RCTRL,
                    key.LGUI,   key.RGUI },
                function() end),

            case(key.RETURN, function()
                -- maintain indentation
                local str = self:current_line()
                self:insert "\n"
                for c in str:gmatch "." do if c == " " or c == "\t" then
                    self:insert(c) else break
                end end
                self:scroll_on_screen()
            end),

            case(key.TAB, function()
                local b, sx, sy, ex, ey = self:region()
                if b then
                    for i = sy, ey do
                        if band(_C.input_get_modifier_state(), mod.SHIFT) ~= 0 then
                            local rem = 0
                            for j = 1, math.min(4, #self.lines[i + 1]) do
                                if self.lines[i + 1]:sub(j, j) == " " then
                                    rem = rem + 1
                                else
                                    if self.lines[i + 1]:sub(j, j) == "\t" and j == 0 then
                                        rem = rem + 1
                                    end
                                    break
                                end
                            end
                            self.lines[i + 1] = self.lines[i + 1]:del(1, rem)
                            if i == self.my then self.mx = self.mx - (rem > self.mx and self.mx or rem) end
                            if i == self.cy then self.cx = self.cx -  rem end
                        else
                            self.lines[i + 1] = "\t" .. self.lines[i + 1]
                            if i == self.my then self.mx = self.mx + 1 end
                            if i == self.cy then self.cx = self.cx + 1 end
                        end
                    end
                end
                self:scroll_on_screen()
            end),

            case({ key.A, key.X, key.C, key.V }, function()
                if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                    return nil
                end
                self:scroll_on_screen()
            end),

            default(function()
                self:scroll_on_screen()
            end))

        if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
            if code == key.A then
                self:select_all()
            elseif code == key.X or code == key.C then
                clipboard = {}

                local sx, sy, ex, ey = select(2, self:region())

                for i = 1, 1 + ey - sy do
                    local y = sy + i
                    local line = self.lines[y]

                    if y - 1 == sy then line = line:sub(sx + 1) end
                    clipboard[#clipboard + 1] = line
                end

                if #clipboard == 0 then clipboard = { "" } end

                if code == key.X then self:del() end
            elseif code == key.V then
                self:del()

                if #clipboard == 1 or self.maxy == 1 then
                    local current = self:current_line()
                    local str  = clipboard[1]
                    local slen = #str

                    if self.maxx >= 0 and slen + self.cx > self.maxx then
                        slen = self.maxx - self.cx
                    end

                    if slen > 0 then
                        local len = #current
                        if self.maxx >= 0 and slen + self.cx + len > self.maxx then
                            len = math.max(0, self.maxx - (self.cx + slen))
                        end

                        current = current:insert(self.cx + 1, slen)
                        self.cx = self.cx + slen
                    end

                    self.lines[self.cy + 1] = current
                else for i = 1, #clipboard do
                    if i == 1 then
                        self.cy = self.cy + 1
                        local newline = self.lines[self.cy]:sub(self.cx + 1)
                        self.lines[self.cy] = self.lines[self.cy]:sub(
                            1, self.cx):insert(self.cy + 1, newline)
                    elseif i >= #clipboard then
                        self.cx = #clipboard[i]
                        self.lines[self.cy + 1] = table.concat {
                            clipboard[i], self.lines[self.cy + 1] }
                    elseif self.maxy < 0 or #self.lines < self.maxy then
                        self.cy = self.cy + 1
                        table.insert(self.lines, self.cy, clipboard[i])
                    end
                end end
            end
            self:scroll_on_screen()
        end
    end,

    set_file = function(self, filename)
        self.filename = filename
    end,

    get_file = function(self)
        return self.filename
    end,

    load_file = function(self, fn)
        if fn then
            self.filename = path(fn, true) -- XXX
        end

        if not self.filename then return nil end

        self.cx = 0
        self.cy = 0

        self:mark(false)
        self.lines = {}

        local f = io.open(self.filename, "r")
        if    f then
            local maxx, maxy = self.maxx, self.maxy
            local lines = f:read("*all"):split("\n")
            if maxy > -1 and #lines > maxy then
                lines = { unpack(lines, 1, maxy) }
            end
            if maxx > -1 then
                lines = table.map(lines, function(line)
                    return line:sub(1, maxx)
                end)
            end
            f:close()
            self.lines = lines
        end
        if #lines == 0 then
            lines = { "" }
        end
    end,

    save_file = function(self, fn)
        if fn then
            self.filename = path(fn, true) -- XXX
        end

        if not self.filename then return nil end

        local  f = io.open(self.filename, "w")
        if not f then return nil end
        local lines = self.lines
        for i = 1, #lines do
            f:write(lines[i])
            f:write("\n")
        end
        f:close()
    end,

    hit = function(self, hitx, hity, dragged)
        local max_width = self.line_wrap and self.pixel_width or -1
        local h = 0
        for i = self.scrolly + 1, #self.lines do
            local width, height = _C.text_get_bounds(self.lines[i], max_width)
            if h + height > self.pixel_height then break end
            if hity >= h and hity <= h + height then
                local x = _C.text_is_visible(self.lines[i], hitx, hity - h, max_width)
                if dragged then
                    self.mx = x
                    self.my = i - 1
                else
                    self.cx = x
                    self.cy = i - 1
                end
                break
            end
            h = h + height
        end
    end,

    limit_scroll_y = function(self)
        local max_width = self.line_wrap and self.pixel_width or -1
        local slines = #self.lines
        local ph = self.pixel_height
        while slines > 0 and ph > 0 do
            local width, height = _C.text_get_bounds(self.lines[slines], max_width)
            if height > ph then break end
            ph = ph - height
            slines = slines - 1
        end
        return slines
    end,

    exec = function(sel)
        assert(pcall(assert(loadstring(sel and self:selection_to_string() or
            self:to_string()))))
    end,

    copy = function(self)
        clipboard = {}

        local sx, sy, ex, ey = select(2, self:region())

        for i = 1, 1 + ey - sy do
            local y = sy + i
            local line = self.lines[y]

            if y - 1 == sy then line = line:sub(sx + 1) end
            clipboard[#clipboard + 1] = line
        end

        if #clipboard == 0 then clipboard = { "" } end
    end,

    paste = function(self)
        self:del()

        if #clipboard == 1 or self.maxy == 1 then
            local current = self:current_line()
            local str  = clipboard[1]
            local slen = #str

            if self.maxx >= 0 and slen + self.cx > self.maxx then
                slen = self.maxx - self.cx
            end

            if slen > 0 then
                local len = #current
                if self.maxx >= 0 and slen + self.cx + len > self.maxx then
                    len = math.max(0, self.maxx - (self.cx + slen))
                end

                current = current:insert(self.cx + 1, slen)
                self.cx = self.cx + slen
            end

            self.lines[self.cy + 1] = current
        else for i = 1, #clipboard do
            if i == 1 then
                self.cy = self.cy + 1
                local newline = self.lines[self.cy]:sub(self.cx + 1)
                self.lines[self.cy] = self.lines[self.cy]:sub(
                    1, self.cx):insert(self.cy + 1, newline)
            elseif i >= #clipboard then
                self.cx = #clipboard[i]
                self.lines[self.cy + 1] = table.concat {
                    clipboard[i], self.lines[self.cy + 1] }
            elseif self.maxy < 0 or #self.lines < self.maxy then
                self.cy = self.cy + 1
                table.insert(self.lines, self.cy, clipboard[i])
            end
        end end
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    commit = function(self) end,

    hovering = function(self, cx, cy)
        if is_clicked(self) and is_focused(self) then
            local dragged = (
                max(abs(cx - self.i_offset_h), abs(cy - self.i_offset_v)) >
                    (_V["fontw"] / 4) * self.scale /
                        (_V["fonth"] * _V.uitextrows)
            )
            self:hit(
                floor(cx * (_V["fonth"] * _V.uitextrows) /
                    self.scale - _V["fontw"] / 2
                ),
                floor(cy * (_V["fonth"] * _V.uitextrows) /
                    self.scale
                ),
                dragged
            )
        end
    end,

    clicked = function(self, cx, cy)
        set_focus(self)
        self:mark()
        self.i_offset_h = cx
        self.i_offset_v = cy

        return Object.clicked(self, cx, cy)
    end,

    key_hover = function(self, code, isdown)
        if code == key.LEFT   or code == key.RIGHT or
           code == key.UP     or code == key.DOWN  or
           code == key.MOUSE4 or code == key.MOUSE5
        then
            if isdown then self:edit_key(code) end
            return true
        end
        return Object.key_hover(self, code, isdown)
    end,

    key = function(self, code, isdown)
        if Object.key(self, code, isdown) then return true end
        if not is_focused(self) then return false end

        if code == key.RETURN or code == key.KP_ENTER
        then
            if self.maxy == 1 then
                set_focus(nil)
                return true
            end
        elseif code == key.HOME      or
               code == key.END       or
               code == key.PAGEUP    or
               code == key.PAGEDOWN  or
               code == key.DELETE    or
               code == key.BACKSPACE or
               code == key.LSHIFT    or
               code == key.RSHIFT    or
               code == key.LCTRL     or
               code == key.RCTRL     or
               code == key.LGUI      or
               code == key.RGUI
        then local pass
        else
            local axcv = (code == key.A) or
                         (code == key.X) or
                         (code == key.C) or
                         (code == key.V)

            if not (axcv and _C.input_get_modifier_state() ~= mod.NONE) then
                return false
            end
        end

        if isdown then self:edit_key(code) end
        return true
    end,

    reset_value = function(self) end,

    layout = function(self)
        Object.layout(self)

        if not is_focused(self) then
            self:reset_value()
        end

        if self.line_wrap and self.maxy == 1 then
            local w, h = _C.text_get_bounds(self.lines[1], self.pixel_width)
            self.pixel_height = h
        end

        self.p_w = max(self.p_w, (self.pixel_width + _V.fontw) *
            self.scale / (_V.fonth * _V.uitextrows))

        self.p_h = max(self.p_h, self.pixel_height *
            self.scale / (_V.fonth * _V.uitextrows)
        )
    end,

    draw = function(self, sx, sy)
        _C.hudmatrix_push()

        _C.hudmatrix_translate(sx, sy, 0)
        local s = self.scale / (_V.fonth * _V.uitextrows)
        _C.hudmatrix_scale(s, s, 1)
        _C.hudmatrix_flush()

        local x, y, color, hit = _V.fontw / 2, 0, 0xFFFFFF, is_focused(self)

        local max_width = self.line_wrap and self.pixel_width or -1

        local selection, sx, sy, ex, ey = self:region()

        self.scrolly = math.clamp(self.scrolly, 0, #self.lines - 1)

        if selection then
            -- convert from cursor coords into pixel coords
            local psx, psy = _C.text_get_position(self.lines[sy + 1], sx, max_width)
            local pex, pey = _C.text_get_position(self.lines[ey + 1], ex, max_width)
            local maxy = #self.lines
            local h = 0
            for i = self.scrolly + 1, maxy do
                local width, height = _C.text_get_bounds(self.lines[i], max_width)
                if h + height > self.pixel_height then
                    maxy = i - 1
                    break
                end
                if i == sy + 1 then
                    psy = psy + h
                end
                if i == ey + 1 then
                    pey = pey + h
                    break
                end
                h = h + height
            end
            maxy = maxy - 1

            if ey >= self.scrolly and sy <= maxy then
                -- crop top/bottom within window
                if  sy < self.scrolly then
                    sy = self.scrolly
                    psy = 0
                    psx = 0
                end
                if  ey > maxy then
                    ey = maxy
                    pey = self.pixel_height - _V.fonth
                    pex = self.pixel_width
                end

                _C.shader_hudnotexture_set()
                _C.gle_color3ub(0xA0, 0x80, 0x80)
                _C.gle_defvertex(2)
                _C.gle_begin(gl.QUADS)
                if psy == pey then
                    _C.gle_attrib2f(x + psx, y + psy)
                    _C.gle_attrib2f(x + pex, y + psy)
                    _C.gle_attrib2f(x + pex, y + pey + _V.fonth)
                    _C.gle_attrib2f(x + psx, y + pey + _V.fonth)
                else
                    _C.gle_attrib2f(x + psx,              y + psy)
                    _C.gle_attrib2f(x + psx,              y + psy + _V.fonth)
                    _C.gle_attrib2f(x + self.pixel_width, y + psy + _V.fonth)
                    _C.gle_attrib2f(x + self.pixel_width, y + psy)
                    if (pey - psy) > _V.fonth then
                        _C.gle_attrib2f(x,                    y + psy + _V.fonth)
                        _C.gle_attrib2f(x + self.pixel_width, y + psy + _V.fonth)
                        _C.gle_attrib2f(x + self.pixel_width, y + pey)
                        _C.gle_attrib2f(x,                    y + pey)
                    end
                    _C.gle_attrib2f(x,       y + pey)
                    _C.gle_attrib2f(x,       y + pey + _V.fonth)
                    _C.gle_attrib2f(x + pex, y + pey + _V.fonth)
                    _C.gle_attrib2f(x + pex, y + pey)
                end
                _C.gle_end()
                _C.shader_hud_set()
            end
        end

        local h = 0
        for i = self.scrolly + 1, #self.lines do
            local width, height = _C.text_get_bounds(self.lines[i], max_width)
            if h + height > self.pixel_height then
                break
            end
            local r, g, b = hextorgb(color)
            _C.text_draw(self.password and ("*"):rep(#self.lines[i])
                or self.lines[i], x, y + h, r, g, b, 0xFF,
                (hit and (self.cy == i - 1)) and self.cx or -1, max_width)

            -- line wrap indicator
            if self.line_wrap and height > _V.fonth then
                _C.shader_hudnotexture_set()
                _C.gle_color3ub(0x80, 0xA0, 0x80)
                _C.gle_defvertex(2)
                _C.gle_begin(gl.gl.TRIANGLE_STRIP)
                _C.gle_attrib2f(x,                y + h + _V.fonth)
                _C.gle_attrib2f(x,                y + h + height)
                _C.gle_attrib2f(x - _V.fontw / 2, y + h + _V.fonth)
                _C.gle_attrib2f(x - _V.fontw / 2, y + h + height)
                _C.gle_end()
                _C.shader_hud_set()
            end

            h = h + height
        end

        _C.hudmatrix_pop()

        return Object.draw(self, sx, sy)
    end
}

local Field = Text_Editor:clone {
    name = "Field",

    __init = function(self, kwargs)
        kwargs   = kwargs or {}

        self.p_value = kwargs.value or ""

        if kwargs.var then
            local varn = kwargs.var
            self.i_var = varn

            if not var.exists(varn) then
                var.new(varn, var.STRING, self.p_value)
            end
        end

        return Text_Editor.__init(self, kwargs)
    end,

    commit = function(self)
        local val = self.lines[1]
        self.value = val

        local varn = self.i_var
        if varn then update_var(varn, val) end
    end,

    key_hover = function(self, code, isdown)
               return self:key(code, isdown)
    end,

    key = function(self, code, isdown)
        if Object.key(self, code, isdown) then return true end
        if not is_focused(self) then return false end

        if code == key.ESCAPE then
            set_focus(nil)
            return true
        elseif code == key.KP_ENTER or
               code == key.RETURN   or
               code == key.TAB
        then
            self:commit()
            set_focus(nil)
            return true
        end

        if isdown then
            self:edit_key(code)
        end
        return true
    end,

    reset_value = function(self)
        local str = self.p_value
        if self.lines[1] ~= str then self:edit_clear(str) end
    end
}

local Mover = Object:clone {
    name = "Mover",
    type = TYPE_MOVER,

    link = function(self, win)
        self.win = win
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        local w = self.win
        local u = w.p_parent
        local c = u.p_children
        local n = table.find(c, w)
        local l = #c

        if n ~= l then
            local o = c[l]
            c[l] = w
            c[n] = o
        end

        return self:target(cx, cy) and self
    end,

    can_move = function(self)
        local wp = self.win.p_parent

        -- no parent means world; we don't need checking for non-mdi windows
        if not wp.p_parent then
            return true
        end

        local rx, ry, p = self.p_x, self.p_y, wp
        while p do
            rx = rx + p.p_x
            ry = ry + p.p_y
            local  pp = p.p_parent
            if not pp then break end
            p    = pp
        end

        -- world has no parents :( but here we can re-use it
        local w = p.p_w
        -- transform x position of the cursor (which ranges from 0 to 1)
        -- into proper UI positions (that are dependent on screen width)
        local cx = cursor_x * w - (w - 1) / 2
        local cy = cursor_y

        if cx < rx or cy < ry or cx > (rx + wp.p_w) or cy > (ry + wp.p_h) then
            -- avoid bugs; stop moving when cursor is outside
            clicked = nil
            return false
        end

        return true
    end,

    pressing = function(self, cx, cy)
        local w = self.win
        if w and w.p_floating and is_clicked(self) and self:can_move() then
            w.p_fx, w.p_x = w.p_fx + cx, w.p_x + cx
            w.p_fy, w.p_y = w.p_fy + cy, w.p_y + cy
        end
    end
}

local Resizer = Object:clone {
    name = "Resizer",
    type = TYPE_RESIZER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.p_horizontal = kwargs.horizontal ~= false and true or false
        self.p_vertical   = kwargs.vertical   ~= false and true or false

        return Object.__init(self, kwargs)
    end,

    link = function(self, win)
        self.win = win
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        local w = self.win
        local u = w.p_parent
        local c = u.p_children
        local n = table.find(c, w)
        local l = #c

        if n ~= l then
            local o = c[l]
            c[l] = w
            c[n] = o
        end

        return self:target(cx, cy) and self
    end,

    can_resize = function(self)
        local wp = self.win.p_parent

        if not wp.p_parent then
            return true
        end

        local rx, ry, p = self.p_x, self.p_y, wp
        while p do
            rx = rx + p.p_x
            ry = ry + p.p_y
            local  pp = p.p_parent
            if not pp then break end
            p    = pp
        end

        local w = p.p_w

        local cx = cursor_x * w - (w - 1) / 2
        local cy = cursor_y

        if cx < rx or cy < ry or cx > (rx + wp.p_w) or cy > (ry + wp.p_h) then
            clicked = nil
            return false
        end

        return true
    end,

    pressing = function(self, cx, cy)
        local w = self.win
        if w and w.p_floating and is_clicked(self) and self:can_resize() then
            if self.p_horizontal then
                w.p_fw, w.p_w = w.p_fw + cx, w.p_w + cx
            end
            if self.p_vertical then
                w.p_fh, w.p_h = w.p_fh + cy, w.p_h + cy
            end
            needs_adjust = true
        end
    end
}

local cursor_reset = function()
    if _V.editing ~= 0 or #world.p_children == 0 then
        cursor_x = 0.5
        cursor_y = 0.5
    end
end
set_external("cursor_reset", cursor_reset)

var.new("cursorsensitivity", var.FLOAT, 0.001, 1, 1000)

local cursor_move = function(dx, dy)
    if (#world.p_children == 0 or not world.focus_children(world)) and
        _V.mouselook ~= 0
    then
        return false
    end

    local scale = 500 / _V.cursorsensitivity

    cursor_x = clamp(cursor_x + dx * (_V.scr_h / (_V.scr_w * scale)), 0, 1)
    cursor_y = clamp(cursor_y + dy / scale, 0, 1)

    return true
end
set_external("cursor_move", cursor_move)

local cursor_exists = function(targeting)
    if not world.focus_children(world) then
        return false
    end

    if #world.p_children ~= 0 then
        if not targeting then return true, true end
        if world and world.target(world, cursor_x * world.p_w, cursor_y * world.p_h) then
            return true
        end
    end

    return false
end
set_external("cursor_exists", cursor_exists)

local cursor_get_position = function()
    if #world.p_children ~= 0 or _V.mouselook == 0 then
        return cursor_x, cursor_y
    else
        return 0.5, 0.5
    end
end
set_external("cursor_get_position", cursor_get_position)

set_external("input_text", function(str)
    if textediting then
        textediting:input(str)
        return true
    end
    return false
end)

set_external("input_keypress", function(code, isdown)
    if not cursor_exists() then return false end

    if code == key.MOUSE5 or code == key.MOUSE4 or
       code == key.LEFT   or code == key.RIGHT  or
       code == key.DOWN   or code == key.UP
    then
        if (focused  and  focused:key_hover(code, isdown)) or
           (hovering and hovering:key_hover(code, isdown))
        then return true end
        return false
    elseif code == key.MOUSE1 then
        if isdown then
            clicked = world:click(cursor_x * world.p_w, cursor_y * world.p_h)
            if clicked then clicked:clicked(click_x, click_y) end
        else
            clicked = nil
        end
        return true
    end

    return world:key(code, isdown)
end)

set_external("gui_clear", function()
    if  _V.mainmenu ~= 0 and _C.isconnected() then
        var.set("mainmenu", 0, true, false) -- no clamping, readonly var

        world:destroy_children()
        worlds = { world }
    end
end)

local register_world = function(w, pos)
    if pos then
        worlds[math.min(pos, #worlds + 1)] = w
        world = w
    else
        worlds[#worlds + 1] = w
    end

    return w
end

set_external("gl_render", function()
    for i = 1, #worlds do
        local w = worlds[i]

        if #w.p_children ~= 0 then
            _C.hudmatrix_ortho(w.p_x, w.p_x + w.p_w, w.p_y + w.p_h, w.p_y, -1, 1)
            _C.hudmatrix_reset()
            _C.shader_hud_set()

            _C.gl_blend_enable()
            _C.gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

            _C.gle_color3f(1, 1, 1)
            w:draw()

            local tooltip = hovering and hovering.tooltip
            if    tooltip then
                local margin = max((w.p_w - 1) / 2, 0)
                local left, right = -margin, 1 + 2 * margin
                local x, y = left + cursor_x * right + 0.01, cursor_y + 0.01

                local tw, th = tooltip.p_w, tooltip.p_h
                if (x + tw * 0.95) > (right - margin) then
                    x = x - tw + 0.02
                    if x <= -margin then x = -margin + 0.02 end
                end
                if (y + th * 0.95) > 1 then
                    y = y - th + 0.02
                    if y < 0 then y = 0 end
                end

                tooltip:draw(x, y)
            end

            _C.gl_scissor_disable()
            _C.gle_disable()
        end
    end
end)

local needsapply = {}

var.new("applydialog", var.INT, 0, 1, 1, var.PERSIST)

set_external("change_add", function(desc, ctype)
    if _V["applydialog"] == 0 then return nil end

    for i, v in pairs(needsapply) do
        if v.desc == desc then return nil end
    end

    needsapply[#needsapply + 1] = { ctype = ctype, desc = desc }
    LAPI.GUI.show_changes()
end)

local CHANGE_GFX     = blsh(1, 0)
local CHANGE_SOUND   = blsh(1, 1)
local CHANGE_SHADERS = blsh(1, 2)

set_external("changes_clear", function(ctype)
    ctype = ctype or bor(CHANGE_GFX, CHANGE_SOUND)

    needsapply = table.filter(needsapply, function(i, v)
        if band(v.ctype, ctype) == 0 then
            return true
        end

        v.ctype = band(v.ctype, bnot(ctype))
        if v.ctype == 0 then
            return false
        end

        return true
    end)
end)

set_external("changes_apply", function()
    local changetypes = 0
    for i, v in pairs(needsapply) do
        changetypes = bor(changetypes, v.ctype)
    end

    if band(changetypes, CHANGE_GFX) ~= 0 then
        cubescript "resetgl"
    end

    if band(changetypes, CHANGE_SOUND) ~= 0 then
        cubescript "resetsound"
    end

    if band(changetypes, CHANGE_SHADERS) ~= 0 then
        cubescript "resetshaders"
    end
end)

set_external("changes_get", function()
    return table.map(needsapply, function(v) return v.desc end)
end)

local mshown = false

set_external("frame_start", function()
    local main = world:get_gui("main")
    if main and not mshown and _V.mainmenu ~= 0 and not _C.isconnected(true) then
        main()
        mshown = true
    end

    if needs_adjust then
        world:layout()
        needs_adjust = false
    end

    was_hovering = hovering
    was_clicked  = clicked

    if cursor_exists() then
        local w, h = world.p_w, world.p_h

        hovering = world.hover(world, cursor_x * w, cursor_y * h)
        if  hovering then
            hovering.hovering(hovering, hover_x, hover_y)
        end

        -- hacky
        if clicked then clicked:pressing(
            (cursor_x - prev_cx) * w,
            (cursor_y - prev_cy)
        ) end
    else
        hovering = nil
        clicked  = nil
    end

    if was_hovering ~= hovering or was_clicked ~= clicked then
        world:layout(world)
    end

    if hovering then
        local tooltip = hovering.tooltip
        if    tooltip then
              tooltip:layout()
              tooltip:adjust_children()
        end
    end

    local wastextediting = (textediting ~= nil)

    if textediting and not is_focused(textediting) then
        textediting:commit()
    end

    if not focused or focused.type ~= TYPE_TEXT_EDITOR then
        textediting = nil
    else
        textediting = focused
    end

    if refreshrepeat ~= 0 or (textediting ~= nil) ~= wastextediting then
        local c = textediting ~= nil
        _C.input_textinput(c, blsh(1, 1)) -- TI_GUI
        _C.input_keyrepeat(c, blsh(1, 1)) -- KR_GUI
        refreshrepeat = 0
    end

    prev_cx = cursor_x
    prev_cy = cursor_y
end)

local f = function()
    needs_adjust = true
end

signal.connect(_V, "scr_w_changed", f)
signal.connect(_V, "scr_h_changed", f)
signal.connect(_V, "uitextrows_changed", f)

return {
    register_world = register_world,
    get_world = function(n)
        if not n then return world end
        return worlds[n]
    end,

    cursor_reset = cursor_reset,
    cursor_move = cursor_move,
    cursor_exists = cursor_exists,
    cursor_get_position = cursor_get_position,

    FILTER_LINEAR                 = gl.LINEAR,
    FILTER_LINEAR_MIPMAP_LINEAR   = gl.LINEAR_MIPMAP_LINEAR,
    FILTER_LINEAR_MIPMAP_NEAREST  = gl.LINEAR_MIPMAP_NEAREST,
    FILTER_NEAREST                = gl.NEAREST,
    FILTER_NEAREST_MIPMAP_LINEAR  = gl.NEAREST_MIPMAP_LINEAR,
    FILTER_NEAREST_MIPMAP_NEAREST = gl.NEAREST_MIPMAP_NEAREST,

    Object = Object,
    World = World,
    H_Box = H_Box,
    V_Box = V_Box,
    Table = Table,
    Spacer = Spacer,
    Filler = Filler,
    Offsetter = Offsetter,
    Clipper = Clipper,
    Conditional = Conditional,
    Button = Button,
    Conditional_Button = Conditional_Button,
    Toggle = Toggle,
    Scroller = Scroller,
    Scrollbar = Scrollbar,
    Scroll_Button = Scroll_Button,
    H_Scrollbar = H_Scrollbar,
    V_Scrollbar = V_Scrollbar,
    Slider = Slider,
    Slider_Button = Slider_Button,
    H_Slider = H_Slider,
    V_Slider = V_Slider,
    Rectangle = Rectangle,
    Image = Image,
    Cropped_Image = Cropped_Image,
    Stretched_Image = Stretched_Image,
    Bordered_Image = Bordered_Image,
    Tiled_Image = Tiled_Image,
    Slot_Viewer = Slot_Viewer,
    Label = Label,
    Text_Editor = Text_Editor,
    Field = Field,
    Mover = Mover,
    Resizer = Resizer
}
