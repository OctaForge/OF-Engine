# OctaForge makefile
# written for FreeBSD, Linux, Solaris, Mac OS X and Windows
# partially based on LuaJIT makefile (the LuaJIT parts)
#
# author: Daniel 'q66' Kolesa <quaker66@gmail.com>
# license: MIT

ifeq (,$(CC))
	CC = cc
endif
CC_FLAGS = -O2 -fomit-frame-pointer

ifeq (,$(CXX))
	CXX = c++
endif
CXX_FLAGS = -O2 -fomit-frame-pointer

ifeq (,$(AS))
	AS = s
endif

CC_FLAGS_x86 = -march=i686
CC_FLAGS_x64 =
#CC_FLAGS_x86 = -march=native
#CC_FLAGS_x64 = -march-native

CXX_FLAGS_x86 = $(CC_FLAGS_x86)
CXX_FLAGS_x64 = $(CC_FLAGS_x64)

CC_DEBUG =
#CC_DEBUG = -g

ifeq ($(DEBUG),1)
	CC_DEBUG = -g
endif

CXX_DEBUG = $(CC_DEBUG)

CC_WARN = -Wall
CXX_WARN = $(CC_WARN)

#####################################
# Feature section: modify as needed #
#####################################

# which directory object files will be written to
OBJDIR = build

# Mac OS X framework path
OSX_FRAMEWORKS = /Library/Frameworks

# C++ compiler flags for OF client
CLIENT_XCXXFLAGS =

# C++ compiler flags for OF server
SERVER_XCXXFLAGS =

# C compiler flags for ENet
ENET_XCFLAGS =

# C compiler flags for LuaJIT
LUAJIT_XCFLAGS =

# host C compiler flags for LuaJIT
LUAJIT_HXCFLAGS =

#####################
# Debugging options #
#####################

###########################################################
# Do not change here if you don't know what you are doing #
###########################################################

# paths

ENET_PATH = libraries/enet
LUAJIT_PATHB = libraries/luajit
LUAJIT_PATH = $(LUAJIT_PATHB)/src

# Variables

HOST_CC = $(CC)
HOST_CXX = $(CXX)

TARGET_CC = $(CROSS)$(CC)
TARGET_CXX = $(CROSS)$(CXX)
TARGET_AS = $(CROSS)$(AS)
TARGET_AR = $(CROSS)ar rcus
TARGET_STRIP = $(CROSS)strip

ifeq (,$(VERBOSE))
	Q = @
	E = @echo
else
	Q =
	E = @:
endif

# OS detection

ifeq (Windows,$(findstring Windows,$(OS))$(MSYSTEM)$(TERM))
	HOST_SYS = Windows
	HOST_RM = del
else
	HOST_SYS = $(shell uname -s)
	ifneq (,$(findstring MINGW,$(HOST_SYS)))
		HOST_SYS = Windows
		HOST_MSYS = mingw
	endif
	ifneq (,$(findstring CYGWIN,$(HOST_SYS)))
		HOST_SYS = Windows
		HOST_MSYS = cygwin
	endif
endif

# arch detection

TARGET_TESTARCH = $(shell $(TARGET_CC) -E $(LUAJIT_PATH)/lj_arch.h -dM)
ifneq (,$(findstring LJ_TARGET_X64,$(TARGET_TESTARCH)))
	TARGET_ARCH = x64
else
ifneq (,$(findstring LJ_TARGET_X86,$(TARGET_TESTARCH)))
	TARGET_ARCH = x86
else
	$(error Unsupported target architecture)
endif
endif

# extra OS stuff

TARGET_SYS ?= $(HOST_SYS)
ifeq (Windows, $(TARGET_SYS))
	TARGET_STRIP += --strip-unneeded
else
ifeq (Darwin, $(TARGET_SYS))
	ifeq (,$(MACOSX_DEPLOYMENT_TARGET))
		export MACOSX_DEPLOYMENT_TARGET=10.6
	endif
	TARGET_STRIP += -x
	TARGET_AR+= 2>/dev/null
endif
endif

# do not strip on debug

ifneq (,$(CC_DEBUG))
	TARGET_STRIP = @:
endif

# colored output on non-windows

ifneq ($(HOST_SYS),Windows)
	ifeq (,$(NOCOLOR))
		RED    = -e "\033[1;31m
		GREEN  = -e "\033[1;32m
		BLUE   = -e "\033[1;34m
		PURPLE = -e "\033[1;35m
		CYAN   = -e "\033[1;36m
		RRED   = \033[1;31m
		RGREEN = \033[1;32m
		RBLUE  = \033[1;34m
		RCYAN  = \033[1;36m
		ENDCOL = \033[m"
	endif
endif

# binary install paths

ifneq ($(TARGET_SYS),Windows)
	BIN_PATH = ../bin_unix
else
ifeq ($(TARGET_ARCH),x64)
	BIN_PATH = ..\bin_win64
else
	BIN_PATH = ..\bin_win32
endif
endif

# includes

ENET_INC = $(ENET_PATH)/include
LUAJIT_INC = $(LUAJIT_PATH)

# binary names

TARGET_BINARCH = $(TARGET_ARCH)
ifeq ($(TARGET_SYS),Windows)
	TARGET_BINOS = win
else
ifeq ($(TARGET_SYS),Linux)
	TARGET_BINOS = linux
else
ifeq ($(TARGET_SYS),FreeBSD)
	TARGET_BINOS = freebsd
else
ifeq ($(TARGET_SYS),Darwin)
	TARGET_BINOS = darwin
else
ifeq ($(TARGET_SYS),SunOS)
	TARGET_BINOS = solaris
else
	$(error Unsupported OS)
endif
endif
endif
endif
endif

ifneq ($(TARGET_SYS),Windows)
	CLIENT_BIN = client_$(TARGET_BINOS)_$(TARGET_BINARCH)
	SERVER_BIN = server_$(TARGET_BINOS)_$(TARGET_BINARCH)
else
	CLIENT_BIN = client_$(TARGET_BINOS)_$(TARGET_BINARCH).exe
	SERVER_BIN = server_$(TARGET_BINOS)_$(TARGET_BINARCH).exe
endif

# client/server includes

CS_INC = -Ishared -Iengine -Ifpsgame
CS_INC += -Iintensity -Ioctaforge
CS_INC += -I$(ENET_INC) -I$(LUAJIT_INC)

ifeq ($(TARGET_SYS),Windows)
	CS_WIN_INC = -Iplatform_windows/include
	ifeq ($(TARGET_ARCH),x64)
		CS_WIN_LIB = -L../bin_win64
	else
		CS_WIN_LIB = -L../bin_win32
	endif
endif

ifeq ($(TARGET_SYS),Darwin)
	CS_OSX_INC = -I$(OSX_FRAMEWORKS)/SDL2.framework/Headers
	CS_OSX_INC += -I$(OSX_FRAMEWORKS)/SDL2_image.framework/Headers
	CS_OSX_INC += -I$(OSX_FRAMEWORKS)/SDL2_mixer.framework/Headers
	CS_OSX_LIB = -F$(OSX_FRAMEWORKS) -framework SDL2 \
		-framework SDL2_image -framework SDL2_mixer
	CS_OSX_CFLAGS = $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) $(CS_OSX_INC)
	CS_OSX_CFLAGS += -Wno-import
	CS_OSX_CXXFLAGS = $(CS_OSX_CFLAGS) -fno-exceptions -fno-rtti
endif

####################
# OctaForge client #
####################

CLIENT_CXXFLAGS = $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(CLIENT_XCXXFLAGS) \
	-fsigned-char -fno-exceptions -fno-rtti -DCLIENT \
	-DBINARY_ARCH=$(TARGET_BINARCH) -DBINARY_OS=$(TARGET_BINOS)

CLIENT_LDFLAGS = -L$(OBJDIR)/$(ENET_PATH) -L$(OBJDIR)/$(LUAJIT_PATH) \
	-lenet -lluajit

ifeq ($(TARGET_SYS),Windows)
	CLIENT_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
ifeq ($(TARGET_ARCH),x64)
	CLIENT_CXXFLAGS += -DWIN64
endif
	CLIENT_CXXFLAGS += $(CS_INC) $(CS_WIN_INC)
	CLIENT_LDFLAGS += $(CS_WIN_LIB) -lSDL2 -lSDL2_image -lSDL2_mixer
	CLIENT_LDFLAGS += -lzlib1 -lopengl32 -lws2_32 -lwinmm
	CLIENT_LDFLAGS += -static-libgcc -static-libstdc++
else
ifeq ($(TARGET_SYS),Darwin)
	CLIENT_CXXFLAGS += $(CS_INC) $(CS_OSX_INC)
	CLIENT_LDFLAGS += $(CS_OSX_LIB) -framework OpenGL -lz
	CLIENT_LDFLAGS += -pagezero_size 10000 -image_base 100000000
else
	CLIENT_CXXFLAGS += $(CS_INC) -I/usr/X11R6/include `sdl2-config --cflags`
	CLIENT_LDFLAGS += -L/usr/X11R6/lib -lX11 `sdl2-config --libs`
	CLIENT_LDFLAGS += -lSDL2_image -lSDL2_mixer -lz -lGL
	ifeq ($(TARGET_SYS),Linux)
		CLIENT_LDFLAGS += -ldl -lrt
	endif
	ifeq ($(TARGET_SYS),SunOS)
		CLIENT_LDFLAGS += -lsocket -lnsl
	endif
endif
endif

CLIENT_OBJ = \
	octaforge/of_tools.o \
	engine/blend.o \
	engine/serverbrowser.o \
	intensity/editing_system.o \
	intensity/messages.o \
	intensity/message_system.o \
	intensity/client_system.o \
	intensity/client_engine_additions.o \
	fpsgame/fps.o \
	fpsgame/server.o \
	fpsgame/client.o \
	fpsgame/render.o \
	fpsgame/weapon.o \
	shared/tools.o \
	shared/geom.o \
	shared/glemu.o \
	engine/command.o \
	engine/aa.o \
	engine/rendertext.o \
	engine/material.o \
	engine/octaedit.o \
	engine/grass.o \
	engine/physics.o \
	engine/rendergl.o \
	engine/renderlights.o \
	engine/worldio.o \
	engine/texture.o \
	engine/console.o \
	engine/world.o \
	engine/renderva.o \
	engine/normal.o \
	engine/rendermodel.o \
	engine/main.o \
	engine/bih.o \
	engine/octa.o \
	engine/light.o \
	engine/water.o \
	engine/shader.o \
	engine/rendersky.o \
	engine/renderparticles.o \
	engine/octarender.o \
	engine/server.o \
	engine/client.o \
	engine/dynlight.o \
	engine/decal.o \
	engine/sound.o \
	engine/pvs.o \
	intensity/engine_additions.o \
	intensity/targeting.o \
	intensity/network_system.o \
	shared/stream.o \
	shared/zip.o \
	engine/movie.o \
	octaforge/of_lua.o \
	octaforge/of_localserver.o \
	octaforge/of_world.o \
	octaforge/of_logger.o \
	octaforge/of_entities.o

CLIENT_OBJB = $(addprefix $(OBJDIR)/client/, $(CLIENT_OBJ))

####################
# OctaForge server #
####################

SERVER_CXXFLAGS = $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(SERVER_XCXXFLAGS) \
	-fsigned-char -fno-exceptions -fno-rtti -DSERVER \
	-DSTANDALONE -DBINARY_ARCH=$(TARGET_BINARCH) -DBINARY_OS=$(TARGET_BINOS)

SERVER_LDFLAGS = -L$(OBJDIR)/$(ENET_PATH) -L$(OBJDIR)/$(LUAJIT_PATH) \
	-lenet -lluajit

ifeq ($(TARGET_SYS),Windows)
	SERVER_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
ifeq ($(TARGET_ARCH),x64)
	SERVER_CXXFLAGS += -DWIN64
endif
	SERVER_CXXFLAGS += $(CS_INC) $(CS_WIN_INC)
	SERVER_LDFLAGS += $(CS_WIN_LIB) -lzlib1 -lopengl32 -lws2_32 -lwinmm
	SERVER_LDFLAGS += -static-libgcc -static-libstdc++
else
ifeq ($(TARGET_SYS),Darwin)
	SERVER_CXXFLAGS += $(CS_INC) $(CS_OSX_INC)
	SERVER_LDFLAGS += $(CS_OSX_LIB) -lz
	SERVER_LDFLAGS += -pagezero_size 10000 -image_base 100000000
else
	SERVER_CXXFLAGS += $(CS_INC) -I/usr/X11R6/include `sdl2-config --cflags`
	SERVER_LDFLAGS += -L/usr/X11R6/lib -lX11 `sdl2-config --libs`
	SERVER_LDFLAGS += -lz
	ifeq ($(TARGET_SYS),Linux)
		SERVER_LDFLAGS += -ldl
	endif
	ifeq ($(TARGET_SYS),SunOS)
		SERVER_LDFLAGS += -lsocket -lnsl
	endif
endif
endif

SERVER_OBJ = \
	octaforge/of_tools.o \
	intensity/editing_system.o \
	shared/tools.o \
	engine/command.o \
	engine/server.o \
	fpsgame/fps.o \
	fpsgame/server.o \
	fpsgame/client.o \
	intensity/message_system.o \
	intensity/server_system.o \
	intensity/messages.o \
	engine/world.o \
	engine/worldio.o \
	intensity/engine_additions.o \
	engine/octa.o \
	engine/physics.o \
	engine/bih.o \
	shared/geom.o \
	shared/glemu.o \
	engine/client.o \
	engine/octaedit.o \
	intensity/network_system.o \
	engine/octarender.o \
	shared/stream.o \
	shared/zip.o \
	octaforge/of_lua.o \
	octaforge/of_world.o \
	octaforge/of_logger.o \
	octaforge/of_entities.o

SERVER_OBJB = $(addprefix $(OBJDIR)/server/, $(SERVER_OBJ))

########
# ENet #
########

ENET_CFLAGS = $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) $(ENET_XCFLAGS) \
	-I$(ENET_INC) -DHAS_SOCKLEN_T=1 -Wno-error

ENET_OBJ = \
	$(ENET_PATH)/callbacks.o \
	$(ENET_PATH)/host.o \
	$(ENET_PATH)/list.o \
	$(ENET_PATH)/packet.o \
	$(ENET_PATH)/peer.o \
	$(ENET_PATH)/protocol.o \
	$(ENET_PATH)/unix.o \
	$(ENET_PATH)/win32.o

ENET_OBJB = $(addprefix $(OBJDIR)/, $(ENET_OBJ))

ENET_LIB = $(ENET_PATH)/libenet.a

##########
# LuaJIT #
##########

LUAJIT_CFLAGS = -I$(LUAJIT_INC) -I$(LUAJIT_INC)/host \
	-I$(OBJDIR)/$(LUAJIT_INC) -I$(OBJDIR)/$(LUAJIT_INC)/host \
	$(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) $(LUAJIT_XCFLAGS) \
	-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -U_FORTIFY_SOURCE \
	-DLUAJIT_ENABLE_LUA52COMPAT

LUAJIT_HCFLAGS = -I$(LUAJIT_INC) -I$(LUAJIT_INC)/host \
	-I$(OBJDIR)/$(LUAJIT_INC) -I$(OBJDIR)/$(LUAJIT_INC)/host \
	$(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) $(LUAJIT_XCFLAGS) \
	$(LUAJIT_HXCFLAGS) $(LUAJIT_TARCH) \
	-DLUAJIT_ENABLE_LUA52COMPAT

LUAJIT_HLDFLAGS = $(CC_DEBUG)

ifneq (,$(findstring LJ_NO_UNWIND 1,$(TARGET_TESTARCH)))
	LUAJIT_TARCH = -DLUAJIT_NO_UNWIND
endif

LUAJIT_TARCH += $(patsubst %,-DLUAJIT_TARGET=LUAJIT_ARCH_%,$(TARGET_ARCH))

ifneq ($(HOST_SYS),$(TARGET_SYS))
	ifeq (Windows,$(TARGET_SYS))
		LUAJIT_HCFLAGS += -malign-double -DLUAJIT_OS=LUAJIT_OS_WINDOWS
	else
	ifeq (Linux,$(TARGET_SYS))
		LUAJIT_HCFLAGS += -DLUAJIT_OS=LUAJIT_OS_LINUX
	else
	ifeq (Darwin,$(TARGET_SYS))
		LUAJIT_HCFLAGS += -DLUAJIT_OS=LUAJIT_OS_OSX
	else
		LUAJIT_HCFLAGS += -DLUAJIT_OS=LUAJIT_OS_OTHER
	endif
	endif
	endif
endif

LUAJIT_MLUA_OBJ = $(LUAJIT_PATH)/host/minilua.o
LUAJIT_MLUA_LDFLAGS = -lm
LUAJIT_MLUA_BIN = $(LUAJIT_PATH)/host/minilua
LUAJIT_MLUA_EXC = $(OBJDIR)/$(LUAJIT_MLUA_BIN)
LUAJIT_MLUA_OBJB = $(addprefix $(OBJDIR)/, $(LUAJIT_MLUA_OBJ))

ifeq (Windows,$(HOST_SYS))
	LUAJIT_MLUA_BIN = $(LUAJIT_PATH)/host/minilua.exe
	ifeq (,$(HOST_MSYS))
		LUAJIT_MLUA_EXC = $(OBJDIR)\$(subst /,\,$(LUAJIT_PATH))\host\minilua
	endif
endif

LUAJIT_DASM_DIR = $(LUAJIT_PATHB)/dynasm
LUAJIT_DASM = $(LUAJIT_MLUA_EXC) $(LUAJIT_DASM_DIR)/dynasm.lua

LUAJIT_DASM_XFLAGS =
LUAJIT_DASM_AFLAGS =
LUAJIT_DASM_ARCH = $(TARGET_ARCH)

ifneq (,$(findstring LJ_ARCH_BITS 64,$(TARGET_TESTARCH)))
	LUAJIT_DASM_AFLAGS += -D P64
endif
ifneq (,$(findstring LJ_HASJIT 1,$(TARGET_TESTARCH)))
	LUAJIT_DASM_AFLAGS += -D JIT
else
	$(warning JIT disabled, OctaForge might run slowly)
endif
ifneq (,$(findstring LJ_HASFFI 1,$(TARGET_TESTARCH)))
	LUAJIT_DASM_AFLAGS += -D FFI
else
	$(error FFI required for OctaForge to run)
endif
ifneq (,$(findstring LJ_DUALNUM 1,$(TARGET_TESTARCH)))
	LUAJIT_DASM_AFLAGS += -D DUALNUM
endif
ifneq (,$(findstring LJ_ARCH_HASFPU 1,$(TARGET_TESTARCH)))
	LUAJIT_DASM_AFLAGS += -D FPU
	LUAJIT_TARCH += -DLJ_ARCH_HASFPU=1
else
	LUAJIT_TARCH += -DLJ_ARCH_HASFPU=0
endif
ifeq (,$(findstring LJ_ABI_SOFTFP 1,$(TARGET_TESTARCH)))
	LUAJIT_DASM_AFLAGS += -D HFABI
	LUAJIT_TARCH += -DLJ_ABI_SOFTFP=0
else
	LUAJIT_TARCH += -DLJ_ABI_SOFTFP=1
endif

LUAJIT_DASM_AFLAGS += -D VER=$(subst LJ_ARCH_VERSION_,,$(filter \
	LJ_ARCH_VERSION_%,$(subst LJ_ARCH_VERSION ,\
	LJ_ARCH_VERSION_,$(TARGET_TESTARCH))))

ifeq (Windows,$(TARGET_SYS))
	LUAJIT_DASM_AFLAGS += -D WIN
endif
ifeq (x86,$(TARGET_ARCH))
	ifneq (,$(findstring __SSE2__ 1,$(TARGET_TESTARCH)))
		LUAJIT_DASM_AFLAGS+= -D SSE
	endif
else
ifeq (x64,$(TARGET_ARCH))
	LUAJIT_DASM_ARCH = x86
endif
endif

LUAJIT_DASM_FLAGS = $(LUAJIT_DASM_XFLAGS) $(LUAJIT_DASM_AFLAGS)
LUAJIT_DASM_DASC = $(LUAJIT_PATH)/vm_$(LUAJIT_DASM_ARCH).dasc

LUAJIT_BUILDVM_OBJ = \
	$(LUAJIT_PATH)/host/buildvm.o \
	$(LUAJIT_PATH)/host/buildvm_asm.o \
	$(LUAJIT_PATH)/host/buildvm_peobj.o \
	$(LUAJIT_PATH)/host/buildvm_lib.o \
	$(LUAJIT_PATH)/host/buildvm_fold.o

LUAJIT_BUILDVM_OBJB = $(addprefix $(OBJDIR)/, $(LUAJIT_BUILDVM_OBJ))

LUAJIT_BUILDVM_BIN = $(LUAJIT_PATH)/host/buildvm
LUAJIT_BUILDVM_EXC = $(OBJDIR)/$(LUAJIT_BUILDVM_BIN)

ifeq (Windows,$(HOST_SYS))
	LUAJIT_BUILDVM_BIN = $(LUAJIT_PATH)/host/buildvm.exe
	ifeq (,$(HOST_MSYS))
		LUAJIT_BUILDVM_EXC = $(OBJDIR)\$(subst /,\,$(LUAJIT_PATH))\host\buildvm
	endif
endif

LUAJIT_HOST_OBJ = $(LUAJIT_MLUA_OBJ) $(LUAJIT_BUILDVM_OBJ)
LUAJIT_HOST_SRC = $(LUAJIT_HOST_OBJ:.o=.c)
LUAJIT_HOST_BIN = $(LUAJIT_MLUA_BIN) $(LUAJIT_BUILDVM_BIN)

LUAJIT_HOST_OBJB = $(addprefix $(OBJDIR)/, $(LUAJIT_HOST_OBJ))

LUAJIT_VM_ASS = $(LUAJIT_PATH)/lj_vm.s
LUAJIT_VM_OBJ = $(LUAJIT_PATH)/lj_vm.o
LUAJIT_VM_MODE = elfasm

ifeq (Windows,$(TARGET_SYS))
	LUAJIT_VM_MODE = coffasm
endif
ifeq (Darwin,$(TARGET_SYS))
	LUAJIT_VM_MODE = machasm
endif

LUAJIT_LIB_OBJ = \
	$(LUAJIT_PATH)/lib_base.o \
	$(LUAJIT_PATH)/lib_math.o \
	$(LUAJIT_PATH)/lib_bit.o \
	$(LUAJIT_PATH)/lib_string.o \
	$(LUAJIT_PATH)/lib_table.o \
	$(LUAJIT_PATH)/lib_io.o \
	$(LUAJIT_PATH)/lib_os.o \
	$(LUAJIT_PATH)/lib_package.o \
	$(LUAJIT_PATH)/lib_debug.o \
	$(LUAJIT_PATH)/lib_jit.o \
	$(LUAJIT_PATH)/lib_ffi.o

LUAJIT_LIB_SRC = $(LUAJIT_LIB_OBJ:.o=.c)

LUAJIT_CORE_OBJ = \
	$(LUAJIT_PATH)/lj_gc.o \
	$(LUAJIT_PATH)/lj_err.o \
	$(LUAJIT_PATH)/lj_char.o \
	$(LUAJIT_PATH)/lj_bc.o \
	$(LUAJIT_PATH)/lj_obj.o \
	$(LUAJIT_PATH)/lj_str.o \
	$(LUAJIT_PATH)/lj_tab.o \
	$(LUAJIT_PATH)/lj_func.o \
	$(LUAJIT_PATH)/lj_udata.o \
	$(LUAJIT_PATH)/lj_meta.o \
	$(LUAJIT_PATH)/lj_debug.o \
	$(LUAJIT_PATH)/lj_state.o \
	$(LUAJIT_PATH)/lj_dispatch.o \
	$(LUAJIT_PATH)/lj_vmevent.o \
	$(LUAJIT_PATH)/lj_vmmath.o \
	$(LUAJIT_PATH)/lj_strscan.o \
	$(LUAJIT_PATH)/lj_api.o \
	$(LUAJIT_PATH)/lj_lex.o \
	$(LUAJIT_PATH)/lj_parse.o \
	$(LUAJIT_PATH)/lj_bcread.o \
	$(LUAJIT_PATH)/lj_bcwrite.o \
	$(LUAJIT_PATH)/lj_load.o \
	$(LUAJIT_PATH)/lj_ir.o \
	$(LUAJIT_PATH)/lj_opt_mem.o \
	$(LUAJIT_PATH)/lj_opt_fold.o \
	$(LUAJIT_PATH)/lj_opt_narrow.o \
	$(LUAJIT_PATH)/lj_opt_dce.o \
	$(LUAJIT_PATH)/lj_opt_loop.o \
	$(LUAJIT_PATH)/lj_opt_split.o \
	$(LUAJIT_PATH)/lj_opt_sink.o \
	$(LUAJIT_PATH)/lj_mcode.o \
	$(LUAJIT_PATH)/lj_snap.o \
	$(LUAJIT_PATH)/lj_record.o \
	$(LUAJIT_PATH)/lj_crecord.o \
	$(LUAJIT_PATH)/lj_ffrecord.o \
	$(LUAJIT_PATH)/lj_asm.o \
	$(LUAJIT_PATH)/lj_trace.o \
	$(LUAJIT_PATH)/lj_gdbjit.o \
	$(LUAJIT_PATH)/lj_ctype.o \
	$(LUAJIT_PATH)/lj_cdata.o \
	$(LUAJIT_PATH)/lj_cconv.o \
	$(LUAJIT_PATH)/lj_ccall.o \
	$(LUAJIT_PATH)/lj_ccallback.o \
	$(LUAJIT_PATH)/lj_carith.o \
	$(LUAJIT_PATH)/lj_clib.o \
	$(LUAJIT_PATH)/lj_cparse.o \
	$(LUAJIT_PATH)/lj_lib.o \
	$(LUAJIT_PATH)/lj_alloc.o \
	$(LUAJIT_PATH)/lib_aux.o \
	$(LUAJIT_LIB_OBJ) \
	$(LUAJIT_PATH)/lib_init.o

LUAJIT_VMCORE_OBJ = $(LUAJIT_VM_OBJ) $(LUAJIT_CORE_OBJ)

LUAJIT_VMCORE_OBJB = $(addprefix $(OBJDIR)/, $(LUAJIT_VMCORE_OBJ))

LUAJIT_LIB_VMDEF = $(LUAJIT_PATH)/jit/vmdef.lua
LUAJIT_LIB_VMDEFP = $(LUAJIT_LIB_VMDEF)

LUAJIT_LIB = $(LUAJIT_PATH)/libluajit.a

LUAJIT_ALL_HDRGEN = \
	$(LUAJIT_PATH)/lj_bcdef.h $(LUAJIT_PATH)/lj_ffdef.h \
	$(LUAJIT_PATH)/lj_libdef.h $(LUAJIT_PATH)/lj_recdef.h \
	$(LUAJIT_PATH)/lj_folddef.h $(LUAJIT_PATH)/host/buildvm_arch.h

#################
# Build targets #
#################

.PHONY: default all
default: all

.SECONDEXPANSION:

ifneq ($(HOST_SYS),Windows)
%/.stamp:
	$(Q) mkdir -p $(dir $@)
	$(Q) touch $@
else
%/.stamp:
	$(Q) -md $(subst /,\,$(dir $@))
	$(Q) -type nul > $(subst /,\,$@)
endif

.PRECIOUS: %/.stamp

# any C file - target platform

$(OBJDIR)/%.o: %.c $$(@D)/.stamp
	$(E) $(PURPLE)[cc     ]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(TARGET_CC) $(CFLAGS) -c -o $@ $(subst .o,.c,$(subst $(OBJDIR)/,,$@))

# any assembly file - target platform

$(OBJDIR)/%.o: $(OBJDIR)/%.s $$(@D)/.stamp
	$(E) $(PURPLE)[asm    ]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(TARGET_AS) $(AFLAGS) -o $@ $(subst .o,.s,$@)

# LuaJIT host files (minilua, buildvm)

$(LUAJIT_HOST_OBJB): %.o: $(LUAJIT_HOST_SRC) $$(@D)/.stamp
	$(E) $(PURPLE)[hostcc ]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(HOST_CC) $(CFLAGS) -c -o $@ $(subst .o,.c,$(subst $(OBJDIR)/,,$@))

# ENet

$(ENET_OBJB): CFLAGS = $(ENET_CFLAGS)
enet: $(ENET_OBJB)
	$(E) $(CYAN)[ar     ]$(RRED) $(ENET_LIB)$(ENDCOL)
	$(Q) $(TARGET_AR) $(OBJDIR)/$(ENET_LIB) $(ENET_OBJB)

# LuaJIT - minilua

$(LUAJIT_MLUA_OBJB): CFLAGS = $(LUAJIT_HCFLAGS)
$(OBJDIR)/$(LUAJIT_MLUA_BIN): $(LUAJIT_MLUA_OBJB) $$(@D)/.stamp
	$(E) $(GREEN)[hostld ]$(RRED) $(LUAJIT_MLUA_BIN)$(ENDCOL)
	$(Q) $(HOST_CC) $(LUAJIT_HLDFLAGS) -o $@ $(LUAJIT_MLUA_OBJB) \
	$(LUAJIT_MLUA_LDFLAGS)

# LuaJIT - buildvm

$(OBJDIR)/$(LUAJIT_PATH)/host/buildvm_arch.h: $(LUAJIT_DASM_DASC) \
$(OBJDIR)/$(LUAJIT_MLUA_BIN) $$(@D)/.stamp
	$(E) $(BLUE)[dynasm ]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(LUAJIT_DASM) $(LUAJIT_DASM_FLAGS) -o $@ $(LUAJIT_DASM_DASC)

$(OBJDIR)/$(LUAJIT_PATH)/host/buildvm.o: $(LUAJIT_DASM_DIR)/dasm_*.h \
$$(@D)/.stamp

$(LUAJIT_BUILDVM_OBJB): CFLAGS = $(LUAJIT_HCFLAGS)
$(OBJDIR)/$(LUAJIT_BUILDVM_BIN): $(LUAJIT_BUILDVM_OBJB) $$(@D)/.stamp
	$(E) $(GREEN)[hostld ]$(RRED) $(LUAJIT_BUILDVM_BIN)$(ENDCOL)
	$(Q) $(HOST_CC) $(LUAJIT_HLDFLAGS) -o $@ $(LUAJIT_BUILDVM_OBJB) \
	$(LUAJIT_BUILDVM_LDFLAGS)

$(OBJDIR)/$(LUAJIT_VM_ASS): $(OBJDIR)/$(LUAJIT_BUILDVM_BIN) $$(@D)/.stamp
	$(E) $(BLUE)[buildvm]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(LUAJIT_BUILDVM_EXC) -m $(LUAJIT_VM_MODE) -o $@

$(OBJDIR)/$(LUAJIT_PATH)/lj_bcdef.h: $(OBJDIR)/$(LUAJIT_BUILDVM_BIN) \
$(LUAJIT_LIB_SRC) $$(@D)/.stamp
	$(E) $(BLUE)[buildvm]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(LUAJIT_BUILDVM_EXC) -m bcdef -o $@ $(LUAJIT_LIB_SRC)

$(OBJDIR)/$(LUAJIT_PATH)/lj_ffdef.h: $(OBJDIR)/$(LUAJIT_BUILDVM_BIN) \
$(LUAJIT_LIB_SRC) $$(@D)/.stamp
	$(E) $(BLUE)[buildvm]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(LUAJIT_BUILDVM_EXC) -m ffdef -o $@ $(LUAJIT_LIB_SRC)

$(OBJDIR)/$(LUAJIT_PATH)/lj_libdef.h: $(OBJDIR)/$(LUAJIT_BUILDVM_BIN) \
$(LUAJIT_LIB_SRC) $$(@D)/.stamp
	$(E) $(BLUE)[buildvm]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(LUAJIT_BUILDVM_EXC) -m libdef -o $@ $(LUAJIT_LIB_SRC)

$(OBJDIR)/$(LUAJIT_PATH)/lj_recdef.h: $(OBJDIR)/$(LUAJIT_BUILDVM_BIN) \
$(LUAJIT_LIB_SRC) $$(@D)/.stamp
	$(E) $(BLUE)[buildvm]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(LUAJIT_BUILDVM_EXC) -m recdef -o $@ $(LUAJIT_LIB_SRC)

$(OBJDIR)/$(LUAJIT_LIB_VMDEF): $(OBJDIR)/$(LUAJIT_BUILDVM_BIN) \
$(LUAJIT_LIB_SRC) $$(@D)/.stamp
	$(E) $(BLUE)[buildvm]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(LUAJIT_BUILDVM_EXC) -m vmdef -o $(OBJDIR)/$(LUAJIT_LIB_VMDEFP) \
	$(LUAJIT_LIB_SRC)

$(OBJDIR)/$(LUAJIT_PATH)/lj_folddef.h: $(OBJDIR)/$(LUAJIT_BUILDVM_BIN) \
$(LUAJIT_PATH)/lj_opt_fold.c $$(@D)/.stamp
	$(E) $(BLUE)[buildvm]$(RRED) $(subst $(OBJDIR)/,,$@)$(ENDCOL)
	$(Q) $(LUAJIT_BUILDVM_EXC) -m folddef -o $@ $(LUAJIT_PATH)/lj_opt_fold.c

# LuaJIT - library

$(LUAJIT_VMCORE_OBJB): CFLAGS = $(LUAJIT_CFLAGS)
luajit: $(LUAJIT_VMCORE_OBJB)
	$(E) $(CYAN)[ar     ]$(RRED) $(LUAJIT_LIB)$(ENDCOL)
	$(Q) $(TARGET_AR) $(OBJDIR)/$(LUAJIT_LIB) $(LUAJIT_VMCORE_OBJB)

# OctaForge - client

$(OBJDIR)/client/%.o: %.cpp $$(@D)/.stamp
	$(E) $(PURPLE)[cc     ]$(RGREEN)[client]$(RRED) \
	$(subst $(OBJDIR)/client/,,$@)$(ENDCOL)
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) -c -o $@ \
	$(subst .o,.cpp,$(subst $(OBJDIR)/client/,,$@))

client: enet luajit $(CLIENT_OBJB)
	$(E) $(GREEN)[ld     ]$(RGREEN) $(CLIENT_BIN)$(ENDCOL)
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) -o $(CLIENT_BIN) \
	$(CLIENT_OBJB) $(CLIENT_LDFLAGS)

# OctaForge - server

$(OBJDIR)/server/%.o: %.cpp $$(@D)/.stamp
	$(E) $(PURPLE)[cc     ]$(RCYAN)[server]$(RRED) \
	$(subst $(OBJDIR)/server/,,$@)$(ENDCOL)
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) -c -o $@ \
	$(subst .o,.cpp,$(subst $(OBJDIR)/server/,,$@))

server: enet luajit $(SERVER_OBJB)
	$(E) $(GREEN)[ld     ]$(RCYAN) $(SERVER_BIN)$(ENDCOL)
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) -o $(SERVER_BIN) \
	$(SERVER_OBJB) $(SERVER_LDFLAGS)

$(OBJDIR)/cube2font.o: shared/cube2font.c
	$(E) $(PURPLE)[cc     ]$(RRED) cube2font.o$(ENDCOL)
	$(TARGET_CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) \
	-c -o $@ $< `freetype-config --cflags`

cube2font: $(OBJDIR)/cube2font.o
	$(E) $(GREEN)[ld     ]$(RRED) cube2font$(ENDCOL)
	$(TARGET_CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) -o cube2font \
	$(OBJDIR)/cube2font.o `freetype-config --libs` -lz

# general targets
all: client server

ifneq ($(FLAV), Windows)
clean:
	$(E) $(CYAN)[clean  ]$(RRED) $(OBJDIR) $(RGREEN)$(CLIENT_BIN) \
	$(RCYAN)$(SERVER_BIN)$(ENDCOL)
	$(Q) -rm -rf $(OBJDIR) $(CLIENT_BIN) $(SERVER_BIN)
else
clean:
	$(E) [clean  ] $(OBJDIR) $(CLIENT_BIN) $(SERVER_BIN)
	$(Q) -rmdir //s //f //q $(OBJDIR)
	$(Q) -del //s //f //q $(CLIENT_BIN) $(SERVER_BIN)
endif

install: client server
ifneq ($(FLAV), Windows)
	$(E) $(GREEN)[install]$(RBLUE) $(CLIENT_BIN) $(RGREEN)-> \
	$(RRED)$(BIN_PATH)$(ENDCOL)
	$(Q) cp -f $(CLIENT_BIN) $(BIN_PATH)
	$(E) $(GREEN)[install]$(RBLUE) $(SERVER_BIN) $(RGREEN)-> \
	$(RRED)$(BIN_PATH)$(ENDCOL)
	$(Q) cp -f $(SERVER_BIN) $(BIN_PATH)
ifeq (,$(NOSTRIP))
	$(Q) $(TARGET_STRIP) $(BIN_PATH)/$(CLIENT_BIN)
	$(Q) $(TARGET_STRIP) $(BIN_PATH)/$(SERVER_BIN)
endif
else
	$(E) [install] $(CLIENT_BIN) -> $(BIN_PATH)
	$(Q) copy $(CLIENT_BIN) $(BIN_PATH)
	$(E) [install] $(SERVER_BIN) -> $(BIN_PATH)
	$(Q) copy $(SERVER_BIN) $(BIN_PATH)
ifeq (,$(NOSTRIP))
	$(Q) $(TARGET_STRIP) $(BIN_PATH)\$(CLIENT_BIN)
	$(Q) $(TARGET_STRIP) $(BIN_PATH)\$(SERVER_BIN)
endif
endif

# dependency generator
depend:
	makedepend -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Ifpsgame \
		-Iintensity \
		-Ioctaforge \
		-DCLIENT \
		-p$$\(OBJDIR\)/client/ \
		$(subst .o,.cpp,$(CLIENT_OBJ))

	makedepend -a -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Ifpsgame \
		-Iintensity \
		-Ioctaforge \
		-DSERVER \
		-p$$\(OBJDIR\)/server/ \
		$(subst .o,.cpp,$(SERVER_OBJ))

	makedepend -a -Y -w 65536 \
		-I$(ENET_INC) \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(ENET_OBJ))

	@mkdir -p $(OBJDIR)/$(LUAJIT_PATH)/host
	@for file in $(LUAJIT_ALL_HDRGEN); do \
		test -f $(OBJDIR)/$$file || touch $(OBJDIR)/$$file; \
		done

	makedepend -a -Y -w 65536 \
		-I$(LUAJIT_INC) -I$(OBJDIR)/$(LUAJIT_INC) \
		-I$(OBJDIR)/$(LUAJIT_INC)/host \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(LUAJIT_VMCORE_OBJ))

	makedepend -a -Y -w 65536 \
		-I$(LUAJIT_INC) -I$(OBJDIR)/$(LUAJIT_INC) \
		-I$(OBJDIR)/$(LUAJIT_INC)/host \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(LUAJIT_HOST_OBJ))

	@for file in $(LUAJIT_ALL_HDRGEN); do \
		test -s $(OBJDIR)/$$file || $(HOST_RM) $(OBJDIR)$$file; \
		done

# DO NOT DELETE

$(OBJDIR)/client/octaforge/of_tools.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/engine/blend.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/serverbrowser.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/intensity/editing_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/messages.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/targeting.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/network_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/intensity/message_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/intensity/client_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_world.h
$(OBJDIR)/client/intensity/client_engine_additions.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/client_system.h intensity/targeting.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/fpsgame/fps.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/client/fpsgame/server.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/fpsgame/client.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/editing_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/network_system.h intensity/targeting.h octaforge/of_localserver.h
$(OBJDIR)/client/fpsgame/render.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h fpsgame/game.h shared/crypto.h intensity/client_system.h
$(OBJDIR)/client/fpsgame/weapon.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h fpsgame/game.h
$(OBJDIR)/client/shared/tools.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/shared/geom.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/shared/glemu.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/engine/command.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/aa.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/rendertext.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/material.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/octaedit.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/grass.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/physics.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/mpr.h fpsgame/game.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/client/engine/rendergl.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/client/engine/renderlights.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_entities.h
$(OBJDIR)/client/engine/worldio.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_world.h octaforge/of_entities.h
$(OBJDIR)/client/engine/texture.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_entities.h
$(OBJDIR)/client/engine/console.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h
$(OBJDIR)/client/engine/world.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/engine/renderva.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_entities.h
$(OBJDIR)/client/engine/normal.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/rendermodel.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/ragdoll.h engine/animmodel.h engine/vertmodel.h engine/skelmodel.h engine/hitzone.h octaforge/of_tools.h engine/md3.h engine/md5.h engine/obj.h engine/smd.h engine/iqm.h
$(OBJDIR)/client/engine/main.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/client_system.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_localserver.h octaforge/of_tools.h
$(OBJDIR)/client/engine/bih.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/octa.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/light.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_entities.h
$(OBJDIR)/client/engine/water.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/shader.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/rendersky.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/renderparticles.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_entities.h engine/explosion.h engine/lensflare.h engine/lightning.h
$(OBJDIR)/client/engine/octarender.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/server.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/client/engine/client.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/client_system.h intensity/network_system.h
$(OBJDIR)/client/engine/dynlight.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/decal.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/sound.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_entities.h
$(OBJDIR)/client/engine/pvs.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/intensity/engine_additions.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/targeting.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/targeting.h intensity/client_system.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/network_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/client/shared/stream.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h
$(OBJDIR)/client/shared/zip.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/engine/movie.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/octaforge/of_lua.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h octaforge/of_tools.h intensity/client_system.h intensity/targeting.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_entities.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_lua_api.h
$(OBJDIR)/client/octaforge/of_localserver.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h octaforge/of_localserver.h intensity/client_system.h
$(OBJDIR)/client/octaforge/of_world.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h fpsgame/game.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/octaforge/of_logger.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h
$(OBJDIR)/client/octaforge/of_entities.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_entities.h

$(OBJDIR)/server/octaforge/of_tools.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/editing_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/shared/tools.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/engine/command.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/engine/server.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/server/fpsgame/fps.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/server/fpsgame/server.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/fpsgame/client.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/editing_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/network_system.h intensity/targeting.h
$(OBJDIR)/server/intensity/message_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/server/intensity/server_system.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/intensity/messages.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/network_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/engine/world.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/engine/worldio.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_entities.h octaforge/of_localserver.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/engine_additions.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/engine/octa.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/engine/physics.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/mpr.h fpsgame/game.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/server/engine/bih.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/shared/geom.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/shared/glemu.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/engine/client.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h
$(OBJDIR)/server/engine/octaedit.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/intensity/network_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/server/engine/octarender.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/shared/stream.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h
$(OBJDIR)/server/shared/zip.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/octaforge/of_lua.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h octaforge/of_tools.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_entities.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_lua_api.h
$(OBJDIR)/server/octaforge/of_world.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h fpsgame/game.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/octaforge/of_logger.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h
$(OBJDIR)/server/octaforge/of_entities.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_entities.h

$(OBJDIR)/libraries/enet/callbacks.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/host.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/list.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/packet.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/peer.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/protocol.o: libraries/enet/include/enet/utility.h libraries/enet/include/enet/time.h libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/unix.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h

$(OBJDIR)/libraries/luajit/src/lj_gc.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_udata.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_err.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_char.o: libraries/luajit/src/lj_char.h libraries/luajit/src/lj_def.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h
$(OBJDIR)/libraries/luajit/src/lj_bc.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_bc.h build/libraries/luajit/src/lj_bcdef.h
$(OBJDIR)/libraries/luajit/src/lj_obj.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h
$(OBJDIR)/libraries/luajit/src/lj_str.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_char.h
$(OBJDIR)/libraries/luajit/src/lj_tab.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_tab.h
$(OBJDIR)/libraries/luajit/src/lj_func.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_udata.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_udata.h
$(OBJDIR)/libraries/luajit/src/lj_meta.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_strscan.h
$(OBJDIR)/libraries/luajit/src/lj_debug.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h
$(OBJDIR)/libraries/luajit/src/lj_state.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_lex.h libraries/luajit/src/lj_alloc.h
$(OBJDIR)/libraries/luajit/src/lj_dispatch.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_ccallback.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h libraries/luajit/src/luajit.h
$(OBJDIR)/libraries/luajit/src/lj_vmevent.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_vmevent.h
$(OBJDIR)/libraries/luajit/src/lj_vmmath.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_strscan.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_char.h libraries/luajit/src/lj_strscan.h
$(OBJDIR)/libraries/luajit/src/lj_api.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_udata.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_strscan.h
$(OBJDIR)/libraries/luajit/src/lj_lex.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_lex.h libraries/luajit/src/lj_parse.h libraries/luajit/src/lj_char.h libraries/luajit/src/lj_strscan.h
$(OBJDIR)/libraries/luajit/src/lj_parse.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_lex.h libraries/luajit/src/lj_parse.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_vmevent.h
$(OBJDIR)/libraries/luajit/src/lj_bcread.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_lex.h libraries/luajit/src/lj_bcdump.h libraries/luajit/src/lj_state.h
$(OBJDIR)/libraries/luajit/src/lj_bcwrite.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_bcdump.h libraries/luajit/src/lj_lex.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_load.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_lex.h libraries/luajit/src/lj_bcdump.h libraries/luajit/src/lj_parse.h
$(OBJDIR)/libraries/luajit/src/lj_ir.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ircall.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lj_carith.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_strscan.h libraries/luajit/src/lj_lib.h
$(OBJDIR)/libraries/luajit/src/lj_opt_mem.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_iropt.h
$(OBJDIR)/libraries/luajit/src/lj_opt_fold.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_carith.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_strscan.h build/libraries/luajit/src/lj_folddef.h
$(OBJDIR)/libraries/luajit/src/lj_opt_narrow.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_strscan.h
$(OBJDIR)/libraries/luajit/src/lj_opt_dce.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_iropt.h
$(OBJDIR)/libraries/luajit/src/lj_opt_loop.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_snap.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_opt_split.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h
$(OBJDIR)/libraries/luajit/src/lj_opt_sink.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_target.h libraries/luajit/src/lj_target_x86.h
$(OBJDIR)/libraries/luajit/src/lj_mcode.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_mcode.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_snap.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_snap.h libraries/luajit/src/lj_target.h libraries/luajit/src/lj_target_x86.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cdata.h
$(OBJDIR)/libraries/luajit/src/lj_record.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ircall.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_record.h libraries/luajit/src/lj_ffrecord.h libraries/luajit/src/lj_snap.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_crecord.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lj_cparse.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_clib.h libraries/luajit/src/lj_ccall.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ircall.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_record.h libraries/luajit/src/lj_ffrecord.h libraries/luajit/src/lj_snap.h libraries/luajit/src/lj_crecord.h
$(OBJDIR)/libraries/luajit/src/lj_ffrecord.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ircall.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_record.h libraries/luajit/src/lj_ffrecord.h libraries/luajit/src/lj_crecord.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_strscan.h build/libraries/luajit/src/lj_recdef.h
$(OBJDIR)/libraries/luajit/src/lj_asm.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ircall.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_mcode.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_snap.h libraries/luajit/src/lj_asm.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_target.h libraries/luajit/src/lj_target_x86.h libraries/luajit/src/lj_emit_x86.h libraries/luajit/src/lj_asm_x86.h
$(OBJDIR)/libraries/luajit/src/lj_trace.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_mcode.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_snap.h libraries/luajit/src/lj_gdbjit.h libraries/luajit/src/lj_record.h libraries/luajit/src/lj_asm.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_vmevent.h libraries/luajit/src/lj_target.h libraries/luajit/src/lj_target_x86.h
$(OBJDIR)/libraries/luajit/src/lj_gdbjit.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_dispatch.h
$(OBJDIR)/libraries/luajit/src/lj_ctype.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_ccallback.h
$(OBJDIR)/libraries/luajit/src/lj_cdata.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_cdata.h
$(OBJDIR)/libraries/luajit/src/lj_cconv.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_ccallback.h
$(OBJDIR)/libraries/luajit/src/lj_ccall.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lj_ccall.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_traceerr.h
$(OBJDIR)/libraries/luajit/src/lj_ccallback.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_ccall.h libraries/luajit/src/lj_ccallback.h libraries/luajit/src/lj_target.h libraries/luajit/src/lj_target_x86.h libraries/luajit/src/lj_mcode.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_vm.h
$(OBJDIR)/libraries/luajit/src/lj_carith.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lj_carith.h
$(OBJDIR)/libraries/luajit/src/lj_clib.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_udata.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lj_clib.h
$(OBJDIR)/libraries/luajit/src/lj_cparse.o: libraries/luajit/src/lj_obj.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cparse.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_char.h libraries/luajit/src/lj_strscan.h
$(OBJDIR)/libraries/luajit/src/lj_lib.o: libraries/luajit/src/lauxlib.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_func.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_strscan.h libraries/luajit/src/lj_lib.h
$(OBJDIR)/libraries/luajit/src/lj_alloc.o: libraries/luajit/src/lj_def.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_alloc.h
$(OBJDIR)/libraries/luajit/src/lib_aux.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_trace.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_traceerr.h libraries/luajit/src/lj_lib.h libraries/luajit/src/lj_alloc.h
$(OBJDIR)/libraries/luajit/src/lib_base.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_char.h libraries/luajit/src/lj_strscan.h libraries/luajit/src/lj_lib.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_math.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_lib.h libraries/luajit/src/lj_vm.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_bit.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_lib.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_string.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_bcdump.h libraries/luajit/src/lj_lex.h libraries/luajit/src/lj_char.h libraries/luajit/src/lj_lib.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_table.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_lib.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_io.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_state.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_lib.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_os.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_lib.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_package.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_lib.h
$(OBJDIR)/libraries/luajit/src/lib_debug.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_lib.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_jit.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_debug.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_ircall.h libraries/luajit/src/lj_iropt.h libraries/luajit/src/lj_target.h libraries/luajit/src/lj_target_x86.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_vm.h libraries/luajit/src/lj_vmevent.h libraries/luajit/src/lj_lib.h libraries/luajit/src/luajit.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_ffi.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_def.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_err.h libraries/luajit/src/lj_errmsg.h libraries/luajit/src/lj_str.h libraries/luajit/src/lj_tab.h libraries/luajit/src/lj_meta.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_cparse.h libraries/luajit/src/lj_cdata.h libraries/luajit/src/lj_cconv.h libraries/luajit/src/lj_carith.h libraries/luajit/src/lj_ccall.h libraries/luajit/src/lj_ccallback.h libraries/luajit/src/lj_clib.h libraries/luajit/src/lj_ff.h build/libraries/luajit/src/lj_ffdef.h libraries/luajit/src/lj_lib.h build/libraries/luajit/src/lj_libdef.h
$(OBJDIR)/libraries/luajit/src/lib_init.o: libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lauxlib.h libraries/luajit/src/lualib.h libraries/luajit/src/lj_arch.h

$(OBJDIR)/libraries/luajit/src/host/buildvm.o: libraries/luajit/src/host/buildvm.h libraries/luajit/src/lj_def.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_gc.h libraries/luajit/src/lj_bc.h libraries/luajit/src/lj_ir.h libraries/luajit/src/lj_ircall.h libraries/luajit/src/lj_jit.h libraries/luajit/src/lj_frame.h libraries/luajit/src/lj_dispatch.h libraries/luajit/src/lj_ctype.h libraries/luajit/src/lj_ccall.h libraries/luajit/src/luajit.h libraries/luajit/dynasm/dasm_proto.h libraries/luajit/dynasm/dasm_x86.h build/libraries/luajit/src/host/buildvm_arch.h libraries/luajit/src/lj_traceerr.h
$(OBJDIR)/libraries/luajit/src/host/buildvm_asm.o: libraries/luajit/src/host/buildvm.h libraries/luajit/src/lj_def.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_bc.h
$(OBJDIR)/libraries/luajit/src/host/buildvm_peobj.o: libraries/luajit/src/host/buildvm.h libraries/luajit/src/lj_def.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_bc.h
$(OBJDIR)/libraries/luajit/src/host/buildvm_lib.o: libraries/luajit/src/host/buildvm.h libraries/luajit/src/lj_def.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_lib.h
$(OBJDIR)/libraries/luajit/src/host/buildvm_fold.o: libraries/luajit/src/host/buildvm.h libraries/luajit/src/lj_def.h libraries/luajit/src/lua.h libraries/luajit/src/luaconf.h libraries/luajit/src/lj_arch.h libraries/luajit/src/lj_obj.h libraries/luajit/src/lj_ir.h
