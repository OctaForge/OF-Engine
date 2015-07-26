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

TARGET_TESTARCH := $(shell $(TARGET_CC) -E octa/shared/arch_detection.hh -dM)
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

CS_INC = -I. -Iostd -Iocta/shared -Iocta/engine -Iocta/game -Iocta/octaforge
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
	octa/shared/crypto.o \
	octa/shared/geom.o \
	octa/shared/glemu.o \
	octa/shared/stream.o \
	octa/shared/tools.o \
	octa/shared/zip.o \
	octa/engine/aa.o \
	octa/engine/bih.o \
	octa/engine/blend.o \
	octa/engine/client.o \
	octa/engine/command.o \
	octa/engine/console.o \
	octa/engine/dynlight.o \
	octa/engine/grass.o \
	octa/engine/light.o \
	octa/engine/main.o \
	octa/engine/material.o \
	octa/engine/movie.o \
	octa/engine/normal.o \
	octa/engine/octa.o \
	octa/engine/octaedit.o \
	octa/engine/octarender.o \
	octa/engine/physics.o \
	octa/engine/pvs.o \
	octa/engine/rendergl.o \
	octa/engine/renderlights.o \
	octa/engine/rendermodel.o \
	octa/engine/renderparticles.o \
	octa/engine/rendersky.o \
	octa/engine/rendertext.o \
	octa/engine/renderva.o \
	octa/engine/server.o \
	octa/engine/serverbrowser.o \
	octa/engine/shader.o \
	octa/engine/sound.o \
	octa/engine/stain.o \
	octa/engine/texture.o \
	octa/engine/water.o \
	octa/engine/world.o \
	octa/engine/worldio.o \
	octa/game/client.o \
	octa/game/entities.o \
	octa/game/game.o \
	octa/game/render.o \
	octa/game/server.o \
	octa/octaforge/of_logger.o \
	octa/octaforge/of_lua.o \
	octa/gui/core.o

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
	octa/shared/crypto.o \
	octa/shared/stream.o \
	octa/shared/tools.o \
	octa/engine/command.o \
	octa/engine/server.o \
	octa/engine/worldio.o \
	octa/game/server.o \
	octa/octaforge/of_lua.o \
	octa/octaforge/of_logger.o \

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
	octa/shared/crypto.o \
	octa/shared/stream.o \
	octa/shared/tools.o \
	octa/engine/command.o \
	octa/engine/master.o \

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
	-Iostd -std=c++11

OCTASTD_OBJ = \
	ostd/src/new.o

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

$(OBJDIR)/ostd/%.o: ostd/%.cc $$(@D)/.stamp
	$(E) " CC (enet)   $(subst $(OBJDIR)/ostd/,,$@)"
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
		-Iocta/shared \
		-Iocta/engine \
		-Iocta/game \
		-Iocta/octaforge \
		-Iostd \
		-p$$\(OBJDIR\)/client/ \
		$(subst .o,.cc,$(CLIENT_OBJ))

	makedepend -a -Y -w 65536 \
		-Iocta/shared \
		-Iocta/engine \
		-Iocta/game \
		-Iocta/octaforge \
		-Iostd \
		-DSTANDALONE \
		-p$$\(OBJDIR\)/server/ \
		$(subst .o,.cc,$(SERVER_OBJ))

	makedepend -a -Y -w 65536 \
		-Iocta/shared \
		-Iocta/engine \
		-Iocta/game \
		-Iostd \
		-DSTANDALONE \
		-p$$\(OBJDIR\)/master/ \
		$(subst .o,.cc,$(MASTER_OBJ))

	makedepend -a -Y -w 65536 \
		-Iostd \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.cc,$(OCTASTD_OBJ))

	makedepend -a -Y -w 65536 \
		-Ienet/include \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(ENET_OBJ))

# DO NOT DELETE

$(OBJDIR)/client/octa/shared/crypto.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/shared/geom.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/shared/glemu.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/shared/stream.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/shared/tools.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/shared/zip.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/engine/aa.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/bih.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/blend.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/client.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/command.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/console.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/game/game.hh
$(OBJDIR)/client/octa/engine/dynlight.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/game/game.hh
$(OBJDIR)/client/octa/engine/grass.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/light.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/main.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/material.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/movie.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/normal.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/octa.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/octaedit.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/octarender.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/physics.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/engine/mpr.hh octa/game/game.hh
$(OBJDIR)/client/octa/engine/pvs.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/rendergl.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/game/game.hh
$(OBJDIR)/client/octa/engine/renderlights.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/rendermodel.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/game/game.hh octa/engine/ragdoll.hh octa/engine/animmodel.hh octa/engine/vertmodel.hh octa/engine/skelmodel.hh octa/engine/hitzone.hh octa/engine/md3.hh octa/engine/md5.hh octa/engine/obj.hh octa/engine/smd.hh octa/engine/iqm.hh
$(OBJDIR)/client/octa/engine/renderparticles.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/game/game.hh octa/engine/explosion.hh octa/engine/lensflare.hh octa/engine/lightning.hh
$(OBJDIR)/client/octa/engine/rendersky.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/rendertext.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/renderva.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/server.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/serverbrowser.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/shader.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/sound.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/stain.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/texture.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/game/game.hh
$(OBJDIR)/client/octa/engine/water.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/world.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/engine/worldio.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh
$(OBJDIR)/client/octa/game/client.o: octa/game/game.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/game/entities.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/game/game.hh
$(OBJDIR)/client/octa/game/game.o: octa/game/game.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/game/render.o: octa/game/game.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/game/server.o: octa/game/game.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/octaforge/of_logger.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/client/octa/octaforge/of_lua.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/engine.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh octa/game/game.hh
$(OBJDIR)/client/octa/gui/core.o: ostd/ostd/tuple.hh ostd/ostd/internal/tuple.hh ostd/ostd/types.hh ostd/ostd/type_traits.hh ostd/ostd/memory.hh ostd/ostd/new.hh ostd/ostd/utility.hh octa/gui/core.hh ostd/ostd/event.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/vector.hh ostd/ostd/range.hh ostd/ostd/algorithm.hh ostd/ostd/initializer_list.hh ostd/ostd/string.hh ostd/ostd/vecmath.hh octa/shared/cube.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/glexts.hh octa/shared/glemu.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/engine.hh octa/engine/world.hh octa/engine/octa.hh octa/engine/light.hh octa/engine/texture.hh octa/engine/bih.hh octa/engine/model.hh

$(OBJDIR)/server/octa/shared/crypto.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/server/octa/shared/stream.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/server/octa/shared/tools.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/server/octa/engine/command.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh
$(OBJDIR)/server/octa/engine/server.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh
$(OBJDIR)/server/octa/engine/worldio.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/world.hh
$(OBJDIR)/server/octa/game/server.o: octa/game/game.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh
$(OBJDIR)/server/octa/octaforge/of_lua.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh octa/engine/engine.hh octa/engine/world.hh octa/game/game.hh
$(OBJDIR)/server/octa/octaforge/of_logger.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/octaforge/of_logger.hh octa/octaforge/of_lua.hh

$(OBJDIR)/master/octa/shared/crypto.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh
$(OBJDIR)/master/octa/shared/stream.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh
$(OBJDIR)/master/octa/shared/tools.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh
$(OBJDIR)/master/octa/engine/command.o: octa/engine/engine.hh octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh octa/engine/world.hh
$(OBJDIR)/master/octa/engine/master.o: octa/shared/cube.hh ostd/ostd/types.hh ostd/ostd/new.hh ostd/ostd/algorithm.hh ostd/ostd/functional.hh ostd/ostd/platform.hh ostd/ostd/memory.hh ostd/ostd/utility.hh ostd/ostd/type_traits.hh ostd/ostd/internal/tuple.hh ostd/ostd/range.hh ostd/ostd/initializer_list.hh octa/shared/tools.hh octa/shared/geom.hh octa/shared/ents.hh octa/shared/command.hh octa/shared/iengine.hh octa/shared/igame.hh

$(OBJDIR)/ostd/src/new.o: ostd/ostd/types.hh

$(OBJDIR)/enet/callbacks.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/compress.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/host.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/list.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/packet.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/peer.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/protocol.o: enet/include/enet/utility.h enet/include/enet/time.h enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/unix.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
