# OctaForge makefile
# written for FreeBSD, Linux, Mac OS X and Windows
#
# author: Daniel 'q66' Kolesa <daniel@octaforge.org>
# license: MIT

CC ?= cc
CC_FLAGS = -O2 -fomit-frame-pointer

CXX ?= c++
CXX_FLAGS = -O2 -fomit-frame-pointer -ffast-math

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
OBJDIR ?= build

# Mac OS X framework path
OSX_FRAMEWORKS = xcode/Frameworks

# C++ compiler flags for OF client
CLIENT_XCXXFLAGS ?=

# C++ compiler flags for OF server
SERVER_XCXXFLAGS ?=

# C++ compiler flags for OF master
MASTER_XCXXFLAGS ?=

# C compiler flags for ENet
ENET_XCFLAGS ?=

# C++ compiler flags for OctaSTD
OCTASTD_XCXXFLAGS ?=

# set to a value if you want the engine to link against
# local (typically static) LuaJIT in platform_YOUROS
LUAJIT_LOCAL ?=

# LuaJIT pkg-config/pkgconf paths
LUAJIT_PKGCONF_PATH += :/usr/local/lib/pkgconfig:/usr/local/libdata/pkgconfig
LUAJIT_PKGCONF_PATH += :/usr/lib/pkgconfig:/usr/libdata/pkgconfig

#####################
# Debugging options #
#####################

###########################################################
# Do not change here if you don't know what you are doing #
###########################################################

# Variables

TARGET_CC = $(CROSS)$(CC)
TARGET_CXX = $(CROSS)$(CXX)
TARGET_STRIP = $(CROSS)strip
TARGET_WINDRES = $(CROSS)windres

ifeq (,$(VERBOSE))
	Q = @
	E = @echo
else
	Q =
	E = @:
endif

# OS detection

ifneq (,$(findstring Windows,$(OS)))
	HOST_TESTSYS := $(shell uname -s 2>&1)
	ifneq (,$(findstring MINGW,$(HOST_TESTSYS)))
		HOST_SYS = Windows
		HOST_FLAV = msys
	else
	ifneq (,$(findstring MSYS,$(HOST_TESTSYS)))
		HOST_SYS = Windows
		HOST_FLAV = msys
	else
	ifneq (,$(findstring CYGWIN,$(HOST_TESTSYS)))
		HOST_SYS = Windows
		HOST_FLAV = cygwin
	else
		HOST_SYS = Windows
		HOST_FLAV = windows
	endif
	endif
	endif
else
	HOST_SYS := $(shell uname -s)
	HOST_FLAV = $(HOST_SYS)
endif

# arch detection

TARGET_TESTARCH := $(shell $(TARGET_CC) -E core/shared/arch_detection.hh -dM)
ifneq (,$(findstring OF_TARGET_X64,$(TARGET_TESTARCH)))
	TARGET_ARCH = x64
	CC_FLAGS += $(CC_FLAGS_x64)
	CXX_FLAGS += $(CXX_FLAGS_x64)
else
ifneq (,$(findstring OF_TARGET_X86,$(TARGET_TESTARCH)))
	TARGET_ARCH = x86
	CC_FLAGS += $(CC_FLAGS_x86)
	CXX_FLAGS += $(CXX_FLAGS_x86)
else
	$(error Unsupported target architecture)
endif
endif

# extra OS stuff

TARGET_SYS ?= $(HOST_SYS)
ifeq (Darwin,$(TARGET_SYS))
ifeq (,$(MACOSX_DEPLOYMENT_TARGET))
	export MACOSX_DEPLOYMENT_TARGET=10.6
endif
endif

# binary names

TARGET_BINARCH = $(TARGET_ARCH)
ifeq ($(TARGET_SYS),Windows)
	TARGET_BINOS = win
	TARGET_XINC += -Iplatform_windows/include
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -L../bin_win64
		override TARGET_WINDRES += -F pe-x86-64
	else
		TARGET_XLIB += -L../bin_win32
		override TARGET_WINDRES += -F pe-i386
	endif
	WINDRES_RC = vcpp/mingw.rc
	WINDRES_RES = vcpp/mingw.res
	WINDRES_CMDLINE = -I vcpp -i $(WINDRES_RC) -J rc \
	-o $(WINDRES_RES) -O coff
else
ifeq ($(TARGET_SYS),Linux)
	TARGET_BINOS = linux
	TARGET_XINC += -Iplatform_linux/include
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -Lplatform_linux/lib64
	else
		TARGET_XLIB += -Lplatform_linux/lib32
	endif
else
ifeq ($(TARGET_SYS),FreeBSD)
	TARGET_BINOS = freebsd
	TARGET_XINC += -Iplatform_freebsd/include
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -Lplatform_freebsd/lib64
	else
		TARGET_XLIB += -Lplatform_freebsd/lib32
	endif
else
ifeq ($(TARGET_SYS),Darwin)
	TARGET_BINOS = darwin
	TARGET_XINC += -Iplatform_osx/include
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -Lplatform_osx/lib64
	else
		TARGET_XLIB += -Lplatform_osx/lib32
	endif
else
	$(error Unsupported OS)
endif
endif
endif
endif

ifneq ($(TARGET_SYS),Windows)
	CLIENT_BIN = client_$(TARGET_BINOS)_$(TARGET_BINARCH)
	SERVER_BIN = server_$(TARGET_BINOS)_$(TARGET_BINARCH)
	MASTER_BIN = master_$(TARGET_BINOS)_$(TARGET_BINARCH)
else
	CLIENT_BIN = client_$(TARGET_BINOS)_$(TARGET_BINARCH).exe
	SERVER_BIN = server_$(TARGET_BINOS)_$(TARGET_BINARCH).exe
	MASTER_BIN = master_$(TARGET_BINOS)_$(TARGET_BINARCH).exe
endif

# do not strip on debug

ifneq (,$(CC_DEBUG))
	TARGET_STRIP = @:
endif

# binary install paths

ifneq ($(HOST_FLAV),windows)
	ifeq ($(TARGET_SYS),Windows)
		ifeq ($(TARGET_ARCH),x64)
			BIN_PATH = ../bin_win64
		else
			BIN_PATH = ../bin_win32
		endif
	else
		BIN_PATH = ../bin_unix
	endif
else
	ifeq ($(TARGET_SYS),Windows)
		ifeq ($(TARGET_ARCH),x64)
			BIN_PATH = ..\bin_win64
		else
			BIN_PATH = ..\bin_win32
		endif
	else
		BIN_PATH = ..\bin_unix
	endif
endif

# LuaJIT detection

ifeq ($(TARGET_SYS),Darwin)
	LUAJIT_INC =
	LUAJIT_LIB =
else
ifneq ($(TARGET_SYS),Windows)
	ifeq (,$(LUAJIT_LOCAL))
		LUAJIT_INC := $(shell PKG_CONFIG_PATH="$(LUAJIT_PKGCONF_PATH)" \
			pkg-config --silence-errors --cflags luajit)
		LUAJIT_LIB := $(shell PKG_CONFIG_PATH="$(LUAJIT_PKGCONF_PATH)" \
			pkg-config --silence-errors --libs luajit)
		ifeq (,$(LUAJIT_LIB))
			LUAJIT_LIB = -lluajit
		endif
	else
		LUAJIT_LIB = -lluajit
	endif
else
	LUAJIT_LIB = -llua51
endif
endif

# client/server includes

CS_INC = -I. -Ioctastd -Icore/shared -Icore/engine -Icore/game -Icore/octaforge
CS_INC += -Ienet/include $(TARGET_XINC) $(LUAJIT_INC)

ifeq ($(TARGET_SYS),Darwin)
	CS_OSX_INC = -I$(OSX_FRAMEWORKS)/SDL2.framework/Headers
	CS_OSX_INC += -I$(OSX_FRAMEWORKS)/SDL2_image.framework/Headers
	CS_OSX_INC += -I$(OSX_FRAMEWORKS)/SDL2_mixer.framework/Headers
	CS_OSX_INC += -I$(OSX_FRAMEWORKS)/LuaJIT.framework/Headers
	CS_OSX_LIB = -F$(OSX_FRAMEWORKS) -framework SDL2 \
		-framework SDL2_image -framework SDL2_mixer -framework LuaJIT \
		-framework Cocoa
	CS_OSX_CFLAGS = $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) $(CS_OSX_INC)
	CS_OSX_CFLAGS += -Wno-import
	CS_OSX_CXXFLAGS = $(CS_OSX_CFLAGS) -fno-exceptions -fno-rtti -std=c++11
endif

####################
# OctaForge client #
####################

CLIENT_CXXFLAGS := $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(CLIENT_XCXXFLAGS) \
	-fsigned-char -fno-exceptions -fno-rtti -std=c++11 \
	-DBINARY_ARCH=$(TARGET_BINARCH) -DBINARY_OS=$(TARGET_BINOS) \
	-DBINARY_ARCH_STR=\"$(TARGET_BINARCH)\" -DBINARY_OS_STR=\"$(TARGET_BINOS)\"

CLIENT_LDFLAGS = $(TARGET_XLIB) $(LUAJIT_LIB)

ifeq ($(TARGET_SYS),Windows)
	CLIENT_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
ifeq ($(TARGET_ARCH),x64)
	CLIENT_CXXFLAGS += -DWIN64
endif
	CLIENT_CXXFLAGS += $(CS_INC)
	CLIENT_LDFLAGS += -mwindows -lSDL2 -lSDL2_image -lSDL2_mixer
	CLIENT_LDFLAGS += -lzlib1 -lopengl32 -lws2_32 -lwinmm
	CLIENT_LDFLAGS += -static-libgcc -static-libstdc++
else
ifeq ($(TARGET_SYS),Darwin)
	CLIENT_CXXFLAGS += $(CS_INC) $(CS_OSX_INC)
	CLIENT_LDFLAGS += $(CS_OSX_LIB) -framework OpenGL -lz
ifeq ($(TARGET_ARCH),x64)
	CLIENT_LDFLAGS += -pagezero_size 10000 -image_base 100000000
endif
else
	CLIENT_CXXFLAGS += $(CS_INC) -I/usr/X11R6/include `sdl2-config --cflags`
	CLIENT_LDFLAGS += `sdl2-config --libs` -lSDL2_image -lSDL2_mixer -lz -lGL
	ifeq ($(TARGET_SYS),Linux)
		CLIENT_LDFLAGS += -ldl -lrt
	else
	ifneq (,$(findstring GNU,$(TARGET_SYS)))
		CLIENT_LDFLAGS += -ldl -lrt
	endif
	endif
endif
endif

CLIENT_OBJ = \
	core/shared/crypto.o \
	core/shared/geom.o \
	core/shared/glemu.o \
	core/shared/stream.o \
	core/shared/tools.o \
	core/shared/zip.o \
	core/engine/aa.o \
	core/engine/bih.o \
	core/engine/blend.o \
	core/engine/client.o \
	core/engine/command.o \
	core/engine/console.o \
	core/engine/dynlight.o \
	core/engine/grass.o \
	core/engine/light.o \
	core/engine/main.o \
	core/engine/material.o \
	core/engine/movie.o \
	core/engine/normal.o \
	core/engine/octa.o \
	core/engine/octaedit.o \
	core/engine/octarender.o \
	core/engine/physics.o \
	core/engine/pvs.o \
	core/engine/rendergl.o \
	core/engine/renderlights.o \
	core/engine/rendermodel.o \
	core/engine/renderparticles.o \
	core/engine/rendersky.o \
	core/engine/rendertext.o \
	core/engine/renderva.o \
	core/engine/server.o \
	core/engine/serverbrowser.o \
	core/engine/shader.o \
	core/engine/sound.o \
	core/engine/stain.o \
	core/engine/texture.o \
	core/engine/water.o \
	core/engine/world.o \
	core/engine/worldio.o \
	core/game/client.o \
	core/game/entities.o \
	core/game/game.o \
	core/game/render.o \
	core/game/server.o \
	core/octaforge/of_logger.o \
	core/octaforge/of_lua.o \

CLIENT_OBJB = $(addprefix $(OBJDIR)/client/, $(CLIENT_OBJ))

####################
# OctaForge server #
####################

SERVER_CXXFLAGS := $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(SERVER_XCXXFLAGS) \
	-fsigned-char -fno-exceptions -fno-rtti -std=c++11 -DSTANDALONE \
	-DBINARY_ARCH=$(TARGET_BINARCH) -DBINARY_OS=$(TARGET_BINOS) \
	-DBINARY_ARCH_STR=\"$(TARGET_BINARCH)\" -DBINARY_OS_STR=\"$(TARGET_BINOS)\"

SERVER_LDFLAGS = $(TARGET_XLIB) $(LUAJIT_LIB)

ifeq ($(TARGET_SYS),Windows)
	SERVER_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
ifeq ($(TARGET_ARCH),x64)
	SERVER_CXXFLAGS += -DWIN64
endif
	SERVER_CXXFLAGS += $(CS_INC)
	SERVER_LDFLAGS += -mwindows -lzlib1 -lopengl32 -lws2_32 -lwinmm
	SERVER_LDFLAGS += -static-libgcc -static-libstdc++
else
ifeq ($(TARGET_SYS),Darwin)
	SERVER_CXXFLAGS += $(CS_INC) $(CS_OSX_INC)
	SERVER_LDFLAGS += -lz -framework LuaJIT
ifeq ($(TARGET_ARCH),x64)
	SERVER_LDFLAGS += -pagezero_size 10000 -image_base 100000000
endif
else
	SERVER_CXXFLAGS += $(CS_INC)
	SERVER_LDFLAGS += -lz
	ifeq ($(TARGET_SYS),Linux)
		SERVER_LDFLAGS += -ldl
	endif
endif
endif

SERVER_OBJ = \
	core/shared/crypto.o \
	core/shared/stream.o \
	core/shared/tools.o \
	core/engine/command.o \
	core/engine/server.o \
	core/engine/worldio.o \
	core/game/server.o \
	core/octaforge/of_lua.o \
	core/octaforge/of_logger.o \

SERVER_OBJB = $(addprefix $(OBJDIR)/server/, $(SERVER_OBJ))

####################
# OctaForge master #
####################

MASTER_CXXFLAGS := $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(MASTER_X CXXFLAGS) \
	-fsigned-char -fno-exceptions -fno-rtti -std=c++11 -DSTANDALONE -DMASTER \
	-DBINARY_ARCH=$(TARGET_BINARCH) -DBINARY_OS=$(TARGET_BINOS) \
	-DBINARY_ARCH_STR=\"$(TARGET_BINARCH)\" -DBINARY_OS_STR=\"$(TARGET_BINOS)\"

MASTER_LDFLAGS = $(TARGET_XLIB)

ifeq ($(TARGET_SYS),Windows)
	MASTER_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
ifeq ($(TARGET_ARCH),x64)
	MASTER_CXXFLAGS += -DWIN64
endif
	MASTER_CXXFLAGS += $(CS_INC)
	MASTER_LDFLAGS += -lzlib1 -lopengl32 -lws2_32 -lwinmm
	MASTER_LDFLAGS += -static-libgcc -static-libstdc++
else
ifeq ($(TARGET_SYS),Darwin)
	MASTER_CXXFLAGS += $(CS_INC)
	MASTER_LDFLAGS += -lz
else
	MASTER_CXXFLAGS += $(CS_INC)
	MASTER_LDFLAGS += -lz
	ifeq ($(TARGET_SYS),Linux)
		MASTER_LDFLAGS += -ldl
	endif
endif
endif

MASTER_OBJ = \
	core/shared/crypto.o \
	core/shared/stream.o \
	core/shared/tools.o \
	core/engine/command.o \
	core/engine/master.o \

MASTER_OBJB = $(addprefix $(OBJDIR)/master/, $(MASTER_OBJ))

########
# ENet #
########

ENET_CFLAGS := $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) $(ENET_XCFLAGS) \
	-Ienet/include -Wno-error

# feature availability detection

ifneq (Windows,$(TARGET_SYS))
	ENET_CFLAGS += $(shell enet/check_cflags.sh $(TARGET_CC) $(CFLAGS))
endif

ENET_OBJ = \
	enet/callbacks.o \
	enet/compress.o \
	enet/host.o \
	enet/list.o \
	enet/packet.o \
	enet/peer.o \
	enet/protocol.o \
	enet/unix.o \
	enet/win32.o

ENET_OBJB = $(addprefix $(OBJDIR)/, $(ENET_OBJ))

###########
# OctaSTD #
###########

OCTASTD_CXXFLAGS = $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(OCTASTD_XCXXFLAGS) \
	-Ioctastd -std=c++11

OCTASTD_OBJ = \
	octastd/src/new.o

OCTASTD_OBJB = $(addprefix $(OBJDIR)/, $(OCTASTD_OBJ))

#################
# Build targets #
#################

.PHONY: default all
default: all

.SECONDEXPANSION:

ifneq ($(HOST_FLAV),windows)
%/.stamp:
	$(Q) mkdir -p $(dir $@)
	$(Q) touch $@
else
%/.stamp:
	$(Q) -md $(subst /,\,$(dir $@))
	$(Q) -type nul > $(subst /,\,$@)
endif

.PRECIOUS: %/.stamp

# ENet

$(OBJDIR)/enet/%.o: enet/%.c $$(@D)/.stamp
	$(E) " CC (enet)   $(subst $(OBJDIR)/,,$@)"
	$(Q) $(TARGET_CC) $(CFLAGS) $(ENET_CFLAGS) -c -o $@ \
	$(subst .o,.c,$(subst $(OBJDIR)/,,$@))

# OctaSTD

$(OBJDIR)/octastd/%.o: octastd/%.cc $$(@D)/.stamp
	$(E) " CC (octastd) $(subst $(OBJDIR)/octastd/,,$@)"
	$(Q) $(TARGET_CXX) $(OCTASTD_CXXFLAGS) $(CXXFLAGS) -c -o $@ \
	$(subst .o,.cc,$(subst $(OBJDIR)/,,$@))

# macutils

$(OBJDIR)/xcode/%.o: xcode/%.m  $$(@D)/.stamp
	$(E) " CC (objc)   $(subst $(OBJDIR)/,,$@)"
	$(Q) $(TARGET_CC) $(CFLAGS) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) -c -o $@ \
	$(subst .o,.m,$(subst $(OBJDIR)/,,$@))

EXTRA_OBJ =
EXTRA_OBJB =
ifeq ($(TARGET_SYS),Darwin)
	EXTRA_OBJ = xcode/macutils.o
	EXTRA_OBJB = $(addprefix $(OBJDIR)/, $(EXTRA_OBJ))
endif

# OctaForge - client

$(OBJDIR)/client/%.o: %.cc $$(@D)/.stamp
	$(E) " CC (client) $(subst $(OBJDIR)/client/,,$@)"
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) $(CXXFLAGS) -c -o $@ \
	$(subst .o,.cc,$(subst $(OBJDIR)/client/,,$@))

ifneq ($(TARGET_SYS),Windows)
client: $(ENET_OBJB) $(OCTASTD_OBJB) $(CLIENT_OBJB) $(EXTRA_OBJB)
	$(E) " LD (client) $(CLIENT_BIN)"
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) $(CXXFLAGS) -o $(CLIENT_BIN) \
	$(ENET_OBJB) $(OCTASTD_OBJB) $(CLIENT_OBJB) $(EXTRA_OBJB) \
	$(CLIENT_LDFLAGS) $(LDFLAGS)
else
client: $(ENET_OBJB) $(OCTASTD_OBJB) $(CLIENT_OBJB)
	$(E) " LD (client) $(CLIENT_BIN)"
	$(Q) $(TARGET_WINDRES) $(WINDRES_CMDLINE)
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) $(CXXFLAGS) -o $(CLIENT_BIN) \
	$(WINDRES_RES) $(ENET_OBJB) $(OCTASTD_OBJB) $(CLIENT_OBJB) \
	$(CLIENT_LDFLAGS) $(LDFLAGS)
endif

# OctaForge - server

$(OBJDIR)/server/%.o: %.cc $$(@D)/.stamp
	$(E) " CC (server) $(subst $(OBJDIR)/server/,,$@)"
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) $(CXXFLAGS) -c -o $@ \
	$(subst .o,.cc,$(subst $(OBJDIR)/server/,,$@))

ifneq ($(TARGET_SYS),Windows)
server: $(ENET_OBJB) $(OCTASTD_OBJB) $(SERVER_OBJB)
	$(E) " LD (server) $(SERVER_BIN)"
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) $(CXXFLAGS) -o $(SERVER_BIN) \
	$(ENET_OBJB) $(OCTASTD_OBJB) $(SERVER_OBJB) $(SERVER_LDFLAGS) $(LDFLAGS)
else
server: $(ENET_OBJB) $(OCTASTD_OBJB) $(SERVER_OBJB)
	$(E) " LD (server) $(SERVER_BIN)"
	$(Q) $(TARGET_WINDRES) $(WINDRES_CMDLINE)
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) $(CXXFLAGS) -o $(SERVER_BIN) \
	$(WINDRES_RES) $(ENET_OBJB) $(OCTASTD_OBJB) $(SERVER_OBJB) \
	$(SERVER_LDFLAGS) $(LDFLAGS)
endif

# OctaForge - master

$(OBJDIR)/master/%.o: %.cc $$(@D)/.stamp
	$(E) " CC (master) $(subst $(OBJDIR)/master/,,$@)"
	$(Q) $(TARGET_CXX) $(MASTER_CXXFLAGS) $(CXXFLAGS) -c -o $@ \
	$(subst .o,.cc,$(subst $(OBJDIR)/master/,,$@))

ifneq ($(TARGET_SYS),Windows)
master: $(ENET_OBJB) $(OCTASTD_OBJB) $(MASTER_OBJB)
	$(E) " LD (master) $(MASTER_BIN)"
	$(Q) $(TARGET_CXX) $(MASTER_CXXFLAGS) $(CXXFLAGS) -o $(MASTER_BIN) \
	$(ENET_OBJB) $(OCTASTD_OBJB) $(MASTER_OBJB) $(MASTER_LDFLAGS) $(LDFLAGS)
else
master: $(ENET_OBJB) $(OCTASTD_OBJB) $(MASTER_OBJB)
	$(E) " LD (master) $(MASTER_BIN)"
	$(Q) $(TARGET_WINDRES) $(WINDRES_CMDLINE)
	$(Q) $(TARGET_CXX) $(MASTER_CXXFLAGS) $(CXXFLAGS) -o $(MASTER_BIN) \
	$(WINDRES_RES) $(ENET_OBJB) $(OCTASTD_OBJB) $(MASTER_OBJB) \
	$(MASTER_LDFLAGS) $(LDFLAGS)
endif

$(OBJDIR)/tessfont.o: shared/tessfont.c
	$(E) " CC tessfont.o"
	$(Q) $(TARGET_CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) \
	-c -o $@ $< `freetype-config --cflags`

tessfont: $(OBJDIR)/tessfont.o
	$(E) " LD tessfont"
	$(Q) $(TARGET_CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) -o tessfont \
	$(OBJDIR)/tessfont.o `freetype-config --libs` -lz -lm

# general targets
all: client server

clean:
	$(E) " CLEAN ($(OBJDIR) $(CLIENT_BIN) $(SERVER_BIN) $(MASTER_BIN))"
ifneq ($(HOST_FLAV),windows)
	$(Q) -rm -rf $(OBJDIR) $(CLIENT_BIN) $(SERVER_BIN) $(MASTER_BIN)
else
	$(Q) -rmdir /s /q $(OBJDIR)
	$(Q) -del /s /f /q $(CLIENT_BIN) $(SERVER_BIN) $(MASTER_BIN)
endif

install: client server
	$(E) " INSTALL ($(CLIENT_BIN) -> $(BIN_PATH))"
ifneq ($(HOST_FLAV),windows)
	$(Q) cp -f $(CLIENT_BIN) $(BIN_PATH)
else
	$(Q) copy $(CLIENT_BIN) $(BIN_PATH)
endif
	$(E) " INSTALL ($(SERVER_BIN) -> $(BIN_PATH))"
ifneq ($(HOST_FLAV),windows)
	$(Q) cp -f $(SERVER_BIN) $(BIN_PATH)
else
	$(Q) copy $(SERVER_BIN) $(BIN_PATH)
endif
ifeq (,$(NOSTRIP))
	$(Q) $(TARGET_STRIP) $(BIN_PATH)/$(CLIENT_BIN)
	$(Q) $(TARGET_STRIP) $(BIN_PATH)/$(SERVER_BIN)
endif

# dependency generator
depend:
	makedepend -Y -w 65536 \
		-Icore/shared \
		-Icore/engine \
		-Icore/game \
		-Icore/octaforge \
		-Ioctastd \
		-p$$\(OBJDIR\)/client/ \
		$(subst .o,.cc,$(CLIENT_OBJ))

	makedepend -a -Y -w 65536 \
		-Icore/shared \
		-Icore/engine \
		-Icore/game \
		-Icore/octaforge \
		-Ioctastd \
		-DSTANDALONE \
		-p$$\(OBJDIR\)/server/ \
		$(subst .o,.cc,$(SERVER_OBJ))

	makedepend -a -Y -w 65536 \
		-Icore/shared \
		-Icore/engine \
		-Icore/game \
		-Ioctastd \
		-DSTANDALONE \
		-p$$\(OBJDIR\)/master/ \
		$(subst .o,.cc,$(MASTER_OBJ))

	makedepend -a -Y -w 65536 \
		-Ioctastd \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.cc,$(OCTASTD_OBJ))

	makedepend -a -Y -w 65536 \
		-Ienet/include \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(ENET_OBJ))

# DO NOT DELETE

$(OBJDIR)/client/core/shared/crypto.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/shared/geom.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/shared/glemu.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/shared/stream.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/shared/tools.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/shared/zip.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/engine/aa.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/bih.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/blend.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/client.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/command.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/console.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/game/game.hh
$(OBJDIR)/client/core/engine/dynlight.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/game/game.hh
$(OBJDIR)/client/core/engine/grass.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/light.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/main.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/material.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/movie.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/normal.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/octa.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/octaedit.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/octarender.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/physics.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/engine/mpr.hh core/game/game.hh
$(OBJDIR)/client/core/engine/pvs.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/rendergl.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/game/game.hh
$(OBJDIR)/client/core/engine/renderlights.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/rendermodel.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/game/game.hh core/engine/ragdoll.hh core/engine/animmodel.hh core/engine/vertmodel.hh core/engine/skelmodel.hh core/engine/hitzone.hh core/engine/md3.hh core/engine/md5.hh core/engine/obj.hh core/engine/smd.hh core/engine/iqm.hh
$(OBJDIR)/client/core/engine/renderparticles.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/game/game.hh core/engine/explosion.hh core/engine/lensflare.hh core/engine/lightning.hh
$(OBJDIR)/client/core/engine/rendersky.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/rendertext.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/renderva.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/server.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/serverbrowser.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/shader.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/sound.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/stain.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/texture.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/game/game.hh
$(OBJDIR)/client/core/engine/water.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/world.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/engine/worldio.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh
$(OBJDIR)/client/core/game/client.o: core/game/game.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/game/entities.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/game/game.hh
$(OBJDIR)/client/core/game/game.o: core/game/game.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/game/render.o: core/game/game.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/game/server.o: core/game/game.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/octaforge/of_logger.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/client/core/octaforge/of_lua.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/glexts.hh core/shared/glemu.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/engine.hh core/engine/world.hh core/engine/octa.hh core/engine/light.hh core/engine/texture.hh core/engine/bih.hh core/engine/model.hh core/game/game.hh

$(OBJDIR)/server/core/shared/crypto.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/server/core/shared/stream.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/server/core/shared/tools.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/server/core/engine/command.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh
$(OBJDIR)/server/core/engine/server.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh
$(OBJDIR)/server/core/engine/worldio.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/world.hh
$(OBJDIR)/server/core/game/server.o: core/game/game.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh
$(OBJDIR)/server/core/octaforge/of_lua.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh core/engine/engine.hh core/engine/world.hh core/game/game.hh
$(OBJDIR)/server/core/octaforge/of_logger.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/octaforge/of_logger.hh core/octaforge/of_lua.hh

$(OBJDIR)/master/core/shared/crypto.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh
$(OBJDIR)/master/core/shared/stream.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh
$(OBJDIR)/master/core/shared/tools.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh
$(OBJDIR)/master/core/engine/command.o: core/engine/engine.hh core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh core/engine/world.hh
$(OBJDIR)/master/core/engine/master.o: core/shared/cube.hh octastd/ostd/types.hh octastd/ostd/new.hh octastd/ostd/algorithm.hh octastd/ostd/functional.hh octastd/ostd/platform.hh octastd/ostd/memory.hh octastd/ostd/utility.hh octastd/ostd/type_traits.hh octastd/ostd/internal/tuple.hh octastd/ostd/range.hh octastd/ostd/initializer_list.hh core/shared/tools.hh core/shared/geom.hh core/shared/ents.hh core/shared/command.hh core/shared/iengine.hh core/shared/igame.hh

$(OBJDIR)/octastd/src/new.o: octastd/ostd/types.hh

$(OBJDIR)/enet/callbacks.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/compress.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/host.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/list.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/packet.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/peer.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/protocol.o: enet/include/enet/utility.h enet/include/enet/time.h enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/unix.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
