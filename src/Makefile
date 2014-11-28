# OctaForge makefile
# written for FreeBSD, Linux, Mac OS X and Windows
#
# author: Daniel 'q66' Kolesa <quaker66@gmail.com>
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
OSX_FRAMEWORKS = platform_osx/Frameworks

# C++ compiler flags for OF client
CLIENT_XCXXFLAGS ?=

# C++ compiler flags for OF server
SERVER_XCXXFLAGS ?=

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
	WINDRES_RC = platform_windows/vcpp/mingw.rc
	WINDRES_RES = platform_windows/vcpp/mingw.res
	WINDRES_CMDLINE = -I platform_windows/vcpp -i $(WINDRES_RC) -J rc \
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
else
	CLIENT_BIN = client_$(TARGET_BINOS)_$(TARGET_BINARCH).exe
	SERVER_BIN = server_$(TARGET_BINOS)_$(TARGET_BINARCH).exe
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

# client/server includes

CS_INC = -I. -Ishared -Iengine -Igame
CS_INC += -Iintensity -Ioctaforge
CS_INC += -Ienet/include $(TARGET_XINC) $(LUAJIT_INC)

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

CLIENT_CXXFLAGS := $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(CLIENT_XCXXFLAGS) \
	-fsigned-char -fno-exceptions -fno-rtti \
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
		ifneq (,$(OVR))
			CLIENT_CXXFLAGS += -ILibOVR/Include -DHAS_OVR=1
			ifeq ($(TARGET_ARCH),x64)
				CLIENT_LDFLAGS += -LLibOVR/Lib/Linux/Release/x86_64 -lovr \
					-ludev -lXinerama
			else
				CLIENT_LDFLAGS += -LLibOVR/Lib/Linux/Release/i386 -lovr \
					-ludev -lXinerama
			endif
		endif
		CLIENT_LDFLAGS += -ldl -lrt
	else
	ifneq (,$(findstring GNU,$(TARGET_SYS)))
		CLIENT_LDFLAGS += -ldl -lrt
	endif
	endif
endif
endif

CLIENT_OBJ = \
	octaforge/of_tools.o \
	engine/blend.o \
	engine/serverbrowser.o \
	intensity/messages.o \
	intensity/message_system.o \
	intensity/client_system.o \
	game/game.o \
	game/server.o \
	game/client.o \
	game/render.o \
	game/weapon.o \
	shared/tools.o \
	shared/geom.o \
	shared/glemu.o \
	engine/command.o \
	engine/aa.o \
	engine/rendertext.o \
	engine/material.o \
	engine/octaedit.o \
	engine/grass.o \
	engine/ovr.o \
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
	engine/stain.o \
	engine/sound.o \
	engine/pvs.o \
	intensity/engine_additions.o \
	intensity/targeting.o \
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

SERVER_CXXFLAGS := $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(SERVER_XCXXFLAGS) \
	-fsigned-char -fno-exceptions -fno-rtti -DSERVER \
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
	SERVER_LDFLAGS += -lz
ifeq ($(TARGET_ARCH),x64)
	SERVER_LDFLAGS += -pagezero_size 10000 -image_base 100000000
endif
else
	SERVER_CXXFLAGS += $(CS_INC) -I/usr/X11R6/include `sdl2-config --cflags`
	SERVER_LDFLAGS += -lz
	ifeq ($(TARGET_SYS),Linux)
		SERVER_LDFLAGS += -ldl
	endif
endif
endif

SERVER_OBJ = \
	octaforge/of_tools.o \
	shared/tools.o \
	engine/command.o \
	engine/server.o \
	game/game.o \
	game/server.o \
	intensity/message_system.o \
	intensity/messages.o \
	intensity/engine_additions.o \
	shared/geom.o \
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

$(OBJDIR)/%.o: %.c $$(@D)/.stamp
	$(E) " CC (enet)   $(subst $(OBJDIR)/,,$@)"
	$(Q) $(TARGET_CC) $(CFLAGS) $(ENET_CFLAGS) -c -o $@ \
	$(subst .o,.c,$(subst $(OBJDIR)/,,$@))

# OctaForge - client

$(OBJDIR)/client/%.o: %.cpp $$(@D)/.stamp
	$(E) " CC (client) $(subst $(OBJDIR)/client/,,$@)"
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) $(CXXFLAGS) -c -o $@ \
	$(subst .o,.cpp,$(subst $(OBJDIR)/client/,,$@))

ifneq ($(TARGET_SYS),Windows)
client: $(ENET_OBJB) $(CLIENT_OBJB)
	$(E) " LD (client) $(CLIENT_BIN)"
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) $(CXXFLAGS) -o $(CLIENT_BIN) \
	$(ENET_OBJB) $(CLIENT_OBJB) $(CLIENT_LDFLAGS) $(LDFLAGS)
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

$(OBJDIR)/tessfont.o: shared/tessfont.c
	$(E) " CC tessfont.o"
	$(Q) $(TARGET_CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) \
	-c -o $@ $< `freetype-config --cflags`

tessfont: $(OBJDIR)/tessfont.o
	$(E) " LD tessfont"
	$(Q) $(TARGET_CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) -o tessfont \
	$(OBJDIR)/tessfont.o `freetype-config --libs` -lz -lm

# amalgamated build
# warning: requires lots of virtual memory (and takes long to compile).

amalg_client:
	$(MAKE) client CLIENT_OBJ=shared/client_amalg.o

amalg_server:
	$(MAKE) server SERVER_OBJ=shared/server_amalg.o

install_amalg:
	$(MAKE) install CLIENT_OBJ=shared/client_amalg.o \
		SERVER_OBJ=shared/server_amalg.o

amalg: amalg_client amalg_server

# general targets
all: client server

clean:
	$(E) " CLEAN ($(OBJDIR) $(CLIENT_BIN) $(SERVER_BIN))"
ifneq ($(HOST_FLAV),windows)
	$(Q) -rm -rf $(OBJDIR) $(CLIENT_BIN) $(SERVER_BIN)
else
	$(Q) -rmdir //s //f //q $(OBJDIR)
	$(Q) -del //s //f //q $(CLIENT_BIN) $(SERVER_BIN)
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
		-Iintensity \
		-Ioctaforge \
		-p$$\(OBJDIR\)/client/ \
		$(subst .o,.cpp,$(CLIENT_OBJ))

	makedepend -a -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Igame \
		-Iintensity \
		-Ioctaforge \
		-DSERVER \
		-p$$\(OBJDIR\)/server/ \
		$(subst .o,.cpp,$(SERVER_OBJ))

	makedepend -a -Y -w 65536 \
		-Ienet/include \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(ENET_OBJ))

# DO NOT DELETE

$(OBJDIR)/client/octaforge/of_tools.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/engine/blend.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/serverbrowser.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/intensity/messages.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/targeting.h intensity/client_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/intensity/message_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/intensity/client_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h intensity/targeting.h intensity/client_system.h octaforge/of_world.h
$(OBJDIR)/client/game/game.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/client_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/client/game/server.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h game/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/game/client.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/targeting.h octaforge/of_localserver.h
$(OBJDIR)/client/game/render.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h game/game.h shared/crypto.h intensity/client_system.h
$(OBJDIR)/client/game/weapon.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h game/game.h
$(OBJDIR)/client/shared/tools.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/shared/geom.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/shared/glemu.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/engine/command.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/aa.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/rendertext.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/material.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/octaedit.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/grass.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/ovr.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/physics.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/mpr.h game/game.h intensity/targeting.h
$(OBJDIR)/client/engine/rendergl.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/targeting.h intensity/client_system.h
$(OBJDIR)/client/engine/renderlights.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/worldio.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_world.h
$(OBJDIR)/client/engine/texture.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_world.h
$(OBJDIR)/client/engine/console.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h intensity/client_system.h game/game.h intensity/targeting.h
$(OBJDIR)/client/engine/world.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h
$(OBJDIR)/client/engine/renderva.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/normal.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/rendermodel.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h engine/ragdoll.h engine/animmodel.h engine/vertmodel.h engine/skelmodel.h engine/hitzone.h intensity/client_system.h octaforge/of_tools.h engine/md3.h engine/md5.h engine/obj.h engine/smd.h engine/iqm.h
$(OBJDIR)/client/engine/main.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/client_system.h intensity/message_system.h intensity/messages.h octaforge/of_localserver.h octaforge/of_tools.h
$(OBJDIR)/client/engine/bih.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/octa.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/light.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/water.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/shader.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/rendersky.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/renderparticles.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/explosion.h engine/lensflare.h engine/lightning.h
$(OBJDIR)/client/engine/octarender.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/server.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/client/engine/client.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/client_system.h
$(OBJDIR)/client/engine/dynlight.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/stain.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/sound.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/pvs.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/intensity/engine_additions.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h
$(OBJDIR)/client/intensity/targeting.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/targeting.h
$(OBJDIR)/client/shared/stream.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h
$(OBJDIR)/client/shared/zip.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/engine/movie.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/octaforge/of_lua.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h octaforge/of_tools.h intensity/client_system.h intensity/targeting.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_lua_api.h
$(OBJDIR)/client/octaforge/of_localserver.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h game/game.h octaforge/of_tools.h octaforge/of_localserver.h intensity/client_system.h
$(OBJDIR)/client/octaforge/of_world.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h octaforge/of_world.h game/game.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/octaforge/of_logger.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h
$(OBJDIR)/client/octaforge/of_entities.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/targeting.h octaforge/of_world.h

$(OBJDIR)/server/octaforge/of_tools.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/shared/tools.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/engine/command.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/engine/server.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/server/game/game.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/server/game/server.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h game/game.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/message_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/server/intensity/server_system.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/intensity/messages.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/client_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/engine_additions.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h
$(OBJDIR)/server/shared/geom.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/shared/stream.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h
$(OBJDIR)/server/shared/zip.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/octaforge/of_lua.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h octaforge/of_tools.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_lua_api.h
$(OBJDIR)/server/octaforge/of_world.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h octaforge/of_world.h game/game.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/octaforge/of_logger.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h
$(OBJDIR)/server/octaforge/of_entities.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h game/game.h intensity/targeting.h octaforge/of_world.h

$(OBJDIR)/enet/callbacks.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/compress.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/host.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/list.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/packet.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/peer.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/protocol.o: enet/include/enet/utility.h enet/include/enet/time.h enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
$(OBJDIR)/enet/unix.o: enet/include/enet/enet.h enet/include/enet/unix.h enet/include/enet/types.h enet/include/enet/protocol.h enet/include/enet/list.h enet/include/enet/callbacks.h
