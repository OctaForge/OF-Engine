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

TARGET_TESTARCH := $(shell $(TARGET_CC) -E shared/arch_detection.h -dM)
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

CS_INC = -I. -Ioctastd -Ishared -Iengine -Igame -Ioctaforge
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
	shared/crypto.o \
	shared/geom.o \
	shared/glemu.o \
	shared/stream.o \
	shared/tools.o \
	shared/zip.o \
	engine/aa.o \
	engine/bih.o \
	engine/blend.o \
	engine/client.o	\
	engine/command.o \
	engine/console.o \
	engine/dynlight.o \
	engine/grass.o \
	engine/light.o \
	engine/main.o \
	engine/material.o \
	engine/movie.o \
	engine/normal.o	\
	engine/octa.o \
	engine/octaedit.o \
	engine/octarender.o \
	engine/physics.o \
	engine/pvs.o \
	engine/rendergl.o \
	engine/renderlights.o \
	engine/rendermodel.o \
	engine/renderparticles.o \
	engine/rendersky.o \
	engine/rendertext.o \
	engine/renderva.o \
	engine/server.o	\
	engine/serverbrowser.o \
	engine/shader.o \
	engine/sound.o \
	engine/stain.o \
	engine/texture.o \
	engine/water.o \
	engine/world.o \
	engine/worldio.o \
	game/client.o \
	game/entities.o \
	game/game.o \
	game/render.o \
	game/server.o \
	octaforge/of_logger.o \
	octaforge/of_lua.o \
	octastd/src/new.o

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
	shared/crypto.o \
	shared/stream.o \
	shared/tools.o \
	engine/command.o \
	engine/server.o \
	engine/worldio.o \
	game/server.o \
	octaforge/of_lua.o \
	octaforge/of_logger.o \
	octastd/src/new.o

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
	shared/crypto.o \
	shared/stream.o \
	shared/tools.o \
	engine/command.o \
	engine/master.o \
	octastd/src/new.o

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

$(OBJDIR)/client/%.o: %.cpp $$(@D)/.stamp
	$(E) " CC (client) $(subst $(OBJDIR)/client/,,$@)"
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) $(CXXFLAGS) -c -o $@ \
	$(subst .o,.cpp,$(subst $(OBJDIR)/client/,,$@))

ifneq ($(TARGET_SYS),Windows)
client: $(ENET_OBJB) $(CLIENT_OBJB) $(EXTRA_OBJB)
	$(E) " LD (client) $(CLIENT_BIN)"
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) $(CXXFLAGS) -o $(CLIENT_BIN) \
	$(ENET_OBJB) $(CLIENT_OBJB) $(EXTRA_OBJB) $(CLIENT_LDFLAGS) $(LDFLAGS)
else
client: $(ENET_OBJB) $(CLIENT_OBJB)
	$(E) " LD (client) $(CLIENT_BIN)"
	$(Q) $(TARGET_WINDRES) $(WINDRES_CMDLINE)
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) $(CXXFLAGS) -o $(CLIENT_BIN) \
	$(WINDRES_RES) $(ENET_OBJB) $(CLIENT_OBJB) $(CLIENT_LDFLAGS) $(LDFLAGS)
endif

# OctaForge - server

$(OBJDIR)/server/%.o: %.cpp $$(@D)/.stamp
	$(E) " CC (server) $(subst $(OBJDIR)/server/,,$@)"
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) $(CXXFLAGS) -c -o $@ \
	$(subst .o,.cpp,$(subst $(OBJDIR)/server/,,$@))

ifneq ($(TARGET_SYS),Windows)
server: $(ENET_OBJB) $(SERVER_OBJB)
	$(E) " LD (server) $(SERVER_BIN)"
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) $(CXXFLAGS) -o $(SERVER_BIN) \
	$(ENET_OBJB) $(SERVER_OBJB) $(SERVER_LDFLAGS) $(LDFLAGS)
else
server: $(ENET_OBJB) $(SERVER_OBJB)
	$(E) " LD (server) $(SERVER_BIN)"
	$(Q) $(TARGET_WINDRES) $(WINDRES_CMDLINE)
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) $(CXXFLAGS) -o $(SERVER_BIN) \
	$(WINDRES_RES) $(ENET_OBJB) $(SERVER_OBJB) $(SERVER_LDFLAGS) $(LDFLAGS)
endif

# OctaForge - master

$(OBJDIR)/master/%.o: %.cpp $$(@D)/.stamp
	$(E) " CC (master) $(subst $(OBJDIR)/master/,,$@)"
	$(Q) $(TARGET_CXX) $(MASTER_CXXFLAGS) $(CXXFLAGS) -c -o $@ \
	$(subst .o,.cpp,$(subst $(OBJDIR)/master/,,$@))

ifneq ($(TARGET_SYS),Windows)
master: $(ENET_OBJB) $(MASTER_OBJB)
	$(E) " LD (master) $(MASTER_BIN)"
	$(Q) $(TARGET_CXX) $(MASTER_CXXFLAGS) $(CXXFLAGS) -o $(MASTER_BIN) \
	$(ENET_OBJB) $(MASTER_OBJB) $(MASTER_LDFLAGS) $(LDFLAGS)
else
master: $(ENET_OBJB) $(MASTER_OBJB)
	$(E) " LD (master) $(MASTER_BIN)"
	$(Q) $(TARGET_WINDRES) $(WINDRES_CMDLINE)
	$(Q) $(TARGET_CXX) $(MASTER_CXXFLAGS) $(CXXFLAGS) -o $(MASTER_BIN) \
	$(WINDRES_RES) $(ENET_OBJB) $(MASTER_OBJB) $(MASTER_LDFLAGS) $(LDFLAGS)
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
		-Ishared \
		-Iengine \
		-Igame \
		-Ioctaforge \
		-Ioctastd \
		-p$$\(OBJDIR\)/client/ \
		$(subst .o,.cpp,$(CLIENT_OBJ))

	makedepend -a -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Igame \
		-Ioctaforge \
		-Ioctastd \
		-DSTANDALONE \
		-p$$\(OBJDIR\)/server/ \
		$(subst .o,.cpp,$(SERVER_OBJ))

	makedepend -a -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Igame \
		-Ioctastd \
		-DSTANDALONE \
		-p$$\(OBJDIR\)/master/ \
		$(subst .o,.cpp,$(MASTER_OBJ))

	makedepend -a -Y -w 65536 \
		-Ienet/include \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(ENET_OBJ))

# DO NOT DELETE

$(OBJDIR)/client/shared/crypto.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/shared/geom.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/shared/glemu.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/shared/stream.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/shared/tools.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/shared/zip.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/engine/aa.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/bih.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/blend.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/client.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/command.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/console.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h game/game.h
$(OBJDIR)/client/engine/dynlight.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h game/game.h
$(OBJDIR)/client/engine/grass.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/light.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/main.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/material.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/movie.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/normal.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/octa.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/octaedit.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/octarender.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/physics.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h engine/mpr.h game/game.h
$(OBJDIR)/client/engine/pvs.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/rendergl.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h game/game.h
$(OBJDIR)/client/engine/renderlights.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/rendermodel.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h game/game.h engine/ragdoll.h engine/animmodel.h engine/vertmodel.h engine/skelmodel.h engine/hitzone.h engine/md3.h engine/md5.h engine/obj.h engine/smd.h engine/iqm.h
$(OBJDIR)/client/engine/renderparticles.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h game/game.h engine/explosion.h engine/lensflare.h engine/lightning.h
$(OBJDIR)/client/engine/rendersky.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/rendertext.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/renderva.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/server.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/serverbrowser.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/shader.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/sound.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/stain.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/texture.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h game/game.h
$(OBJDIR)/client/engine/water.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/world.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/engine/worldio.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h
$(OBJDIR)/client/game/client.o: game/game.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/game/entities.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h game/game.h
$(OBJDIR)/client/game/game.o: game/game.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/game/render.o: game/game.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/game/server.o: game/game.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/octaforge/of_logger.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/client/octaforge/of_lua.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/texture.h engine/bih.h engine/model.h game/game.h
$(OBJDIR)/client/octastd/src/new.o: octastd/octa/types.h

$(OBJDIR)/server/shared/crypto.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/server/shared/stream.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/server/shared/tools.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/server/engine/command.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h
$(OBJDIR)/server/engine/server.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h
$(OBJDIR)/server/engine/worldio.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/world.h
$(OBJDIR)/server/game/server.o: game/game.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/server/octaforge/of_lua.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h engine/engine.h engine/world.h game/game.h
$(OBJDIR)/server/octaforge/of_logger.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h
$(OBJDIR)/server/octastd/src/new.o: octastd/octa/types.h

$(OBJDIR)/master/shared/crypto.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h
$(OBJDIR)/master/shared/stream.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h
$(OBJDIR)/master/shared/tools.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h
$(OBJDIR)/master/engine/command.o: engine/engine.h shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h engine/world.h
$(OBJDIR)/master/engine/master.o: shared/cube.h octastd/octa/new.h octastd/octa/types.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/iengine.h shared/igame.h
$(OBJDIR)/master/octastd/src/new.o: octastd/octa/types.h

$(OBJDIR)/enet/callbacks.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/compress.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/host.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/list.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/packet.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/peer.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/protocol.o: enet/include/enet/utility.h enet/include/enet/time.h enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/unix.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
