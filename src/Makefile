# OctaForge makefile
# written for FreeBSD, Linux, Solaris, Mac OS X and Windows
# inspired by LuaJIT makefile
#
# author: Daniel 'q66' Kolesa <quaker66@gmail.com>
# license: MIT

CC = cc
CC_FLAGS = -O2 -fomit-frame-pointer -fsigned-char

CXX = c++
CXX_FLAGS = $(CC_FLAGS)

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

#####################
# Debugging options #
#####################

###########################################################
# Do not change here if you don't know what you are doing #
###########################################################

# paths

OFTL_PATH = libraries/OFTL
ENET_PATH = libraries/enet
LUAJIT_PATH = libraries/luajit/src

# Variables

HOST_CC = $(CC)
HOST_CXX = $(CXX)

TARGET_CC = $(CROSS)$(CC)
TARGET_CXX = $(CROSS)$(CXX)
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

# extra flags

#ifneq ($(HOST_SYS),$(TARGET_SYS))
#	ifeq (Windows,$(TARGET_SYS))
#		....
#	endif
#endif

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

OFTL_INC = $(OFTL_PATH)/include
ENET_INC = $(ENET_PATH)/include
LUAJIT_INC = $(LUAJIT_PATH)

# binary names

ifeq ($(TARGET_ARCH),x64)
ifneq ($(TARGET_SYS),Windows)
	TARGET_BINARCH = x86_64
else
	TARGET_BINARCH = $(TARGET_ARCH)
endif
else
	TARGET_BINARCH = $(TARGET_ARCH)
endif

ifneq ($(TARGET_SYS),Windows)
	CLIENT_BIN = OF_Client_$(TARGET_SYS)-$(TARGET_BINARCH)
	SERVER_BIN = OF_Server_$(TARGET_SYS)-$(TARGET_BINARCH)
else
	CLIENT_BIN = OF_Client_$(TARGET_SYS)-$(TARGET_BINARCH).exe
	SERVER_BIN = OF_Server_$(TARGET_SYS)-$(TARGET_BINARCH).exe
endif

# library names

ENET_LIB = $(ENET_PATH)/libenet.a

# client/server includes

CS_INC = -Ishared -Iengine -Ifpsgame
CS_INC += -Iintensity -Ioctaforge
CS_INC += -I$(OFTL_INC) -I$(ENET_INC) -I$(LUAJIT_INC)

ifeq ($(TARGET_SYS),Windows)
	CS_WIN_INC = -Iplatform_windows/include
	ifeq ($(TARGET_ARCH),x64)
		CS_WIN_LIB = -L../bin_win64
	else
		CS_WIN_LIB = -L../bin_win32
	endif
endif

ifeq ($(TARGET_SYS),Darwin)
	CS_OSX_OBJ = platform_osx/macutils.o platform_osx/SDLMain.o
	CS_OSX_INC = -I$(OSX_FRAMEWORKS)/SDL.framework/Headers
	CS_OSX_INC += -I$(OSX_FRAMEWORKS)/SDL_image.framework/Headers
	CS_OSX_INC += -I$(OSX_FRAMEWORKS)/SDL_mixer.framework/Headers
	CS_OSX_LIB = -F$(OSX_FRAMEWORKS) -framework Cocoa -framework SDL \
		-framework SDL_image -framework SDL_mixer
	CS_OSX_CFLAGS = $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) $(CS_OSX_INC)
	CS_OSX_CFLAGS += -Wno-import
	CS_OSX_CXXFLAGS = $(CS_OSX_CFLAGS) -fno-exceptions -fno-rtti
endif

####################
# OctaForge client #
####################

CLIENT_CXXFLAGS = $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(CLIENT_XCXXFLAGS) \
	-fno-exceptions -fno-rtti -std=c++0x -DCLIENT

CLIENT_LDFLAGS = -L$(OBJDIR)/$(ENET_PATH) -L$(LUAJIT_PATH) -lenet -lluajit

ifeq ($(TARGET_SYS),Windows)
	CLIENT_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
	CLIENT_CXXFLAGS += $(CS_INC) $(CS_WIN_INC)
	CLIENT_LDFLAGS += $(CS_WIN_LIB) -lSDL -lSDL_image -lSDL_mixer
	CLIENT_LDFLAGS += -lzlib1 -lopengl32 -lws2_32 -lwinmm
	CLIENT_LDFLAGS += -static-libgcc -static-libstdc++ -Wl,--export-dynamic
else
ifeq ($(TARGET_SYS),Darwin)
	CLIENT_CXXFLAGS += $(CS_INC) $(CS_OSX_INC)
	CLIENT_LDFLAGS += $(CS_OSX_LIB) -framework OpenGL -lz
	CLIENT_LDFLAGS += -pagezero_size 10000 -image_base 100000000
else
	CLIENT_CXXFLAGS += $(CS_INC) -I/usr/X11R6/include `sdl-config --cflags`
	CLIENT_LDFLAGS += -L/usr/X11R6/lib -lX11 `sdl-config --libs`
	CLIENT_LDFLAGS += -lSDL_image -lSDL_mixer -lz -lGL -Wl,--export-dynamic
	ifeq ($(TARGET_SYS),Linux)
		CLIENT_LDD += -ldl -lrt
	endif
	ifeq ($(TARGET_SYS),SunOS)
		CLIENT_LDD += -lsocket -lnsl
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
	octaforge/of_vars.o \
	shared/stream.o \
	shared/zip.o \
	engine/movie.o \
	octaforge/of_lapi.o \
	octaforge/of_localserver.o \
	octaforge/of_world.o \
	octaforge/of_logger.o \
	octaforge/of_entities.o \
	octaforge/of_eapi.o

ifeq ($(TARGET_SYS),Windows)
CLIENT_OBJ += libraries/OFTL/src/filesystem/platform_win32.o
else
CLIENT_OBJ += libraries/OFTL/src/filesystem/platform_posix.o
endif

ifeq ($(TARGET_SYS),Darwin)
CLIENT_OBJ += $(CS_OSX_OBJ)
endif

CLIENT_OBJ_BUILD = $(addprefix $(OBJDIR)/client/, $(CLIENT_OBJ))

####################
# OctaForge server #
####################

SERVER_CXXFLAGS = $(CXX_FLAGS) $(CXX_DEBUG) $(CXX_WARN) $(SERVER_XCXXFLAGS) \
	-fno-exceptions -fno-rtti -std=c++0x -DSERVER -DSTANDALONE

SERVER_LDFLAGS = -L$(OBJDIR)/$(ENET_PATH) -L$(LUAJIT_PATH) -lenet -lluajit

ifeq ($(TARGET_SYS),Windows)
	SERVER_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
	SERVER_CXXFLAGS += $(CS_INC) $(CS_WIN_INC)
	SERVER_LDFLAGS += $(CS_WIN_LIB) -lzlib1 -lopengl32 -lws2_32 -lwinmm
	SERVER_LDFLAGS += -static-libgcc -static-libstdc++ -Wl,--export-dynamic
else
ifeq ($(TARGET_SYS),Darwin)
	SERVER_CXXFLAGS += $(CS_INC) $(CS_OSX_INC)
	SERVER_LDFLAGS += $(CS_OSX_LIB) -lz
	SERVER_LDFLAGS += -pagezero_size 10000 -image_base 100000000
else
	SERVER_CXXFLAGS += $(CS_INC) -I/usr/X11R6/include `sdl-config --cflags`
	SERVER_LDFLAGS += -L/usr/X11R6/lib -lX11 `sdl-config --libs`
	SERVER_LDFLAGS += -lz -Wl,--export-dynamic
	ifeq ($(TARGET_SYS),Linux)
		SERVER_LDD += -ldl
	endif
	ifeq ($(TARGET_SYS),SunOS)
		SERVER_LDD += -lsocket -lnsl
	endif
endif
endif

SERVER_OBJ = \
	octaforge/of_tools.o \
	intensity/editing_system.o \
	shared/tools.o \
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
	engine/client.o \
	engine/octaedit.o \
	intensity/network_system.o \
	octaforge/of_vars.o \
	engine/octarender.o \
	shared/stream.o \
	shared/zip.o \
	octaforge/of_lapi.o \
	octaforge/of_world.o \
	octaforge/of_logger.o \
	octaforge/of_entities.o \
	octaforge/of_eapi.o

ifeq ($(TARGET_SYS),Windows)
SERVER_OBJ += libraries/OFTL/src/filesystem/platform_win32.o
else
SERVER_OBJ += libraries/OFTL/src/filesystem/platform_posix.o
endif

SERVER_OBJ_BUILD = $(addprefix $(OBJDIR)/server/, $(SERVER_OBJ))

########
# ENet #
########

ENET_CFLAGS = $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) $(ENET_XCFLAGS) \
	-I$(ENET_INC) -DHAS_SOCKLEN_T=1 -Wno-error

ENET_OBJ = \
	libraries/enet/callbacks.o \
	libraries/enet/host.o \
	libraries/enet/list.o \
	libraries/enet/packet.o \
	libraries/enet/peer.o \
	libraries/enet/protocol.o \
	libraries/enet/unix.o \
	libraries/enet/win32.o

ENET_OBJ_BUILD = $(addprefix $(OBJDIR)/, $(ENET_OBJ))

##########
# LuaJIT #
##########

LUAJIT_BUILDMODE = static
LUAJIT_CFLAGS = -DLUAJIT_ENABLE_LUA52COMPAT
LUAJIT_CC  = $(TARGET_CC)
LUAJIT_TARGET_AR = $(TARGET_AR)
LUAJIT_TARGET_STRIP = $(TARGET_STRIP)

#################
# Build targets #
#################

.PHONY: default all
default: all

.SECONDEXPANSION:

ifneq ($(TARGET_SYS),Windows)
%/.stamp:
	$(Q) mkdir -p $(dir $@)
	$(Q) touch $@
else
%/.stamp:
	$(Q) md $(subst /,\,$(dir $@))
	$(Q) type nul > $(subst /,\,$@)
endif

.PRECIOUS: %/.stamp

ifeq ($(TARGET_SYS), Darwin)
$(OBJDIR)/client/platform_osx/macutils.o: platform_osx/macutils.mm \
$$(@D)/.stamp
	$(E) $(CYAN)[OS X]$(RRED) Building an Obj-C++ object file \
	platform_osx/macutils.mm.$(ENDCOL)
	$(Q) $(TARGET_CXX) $(CS_OSX_CXXFLAGS) -c -o $@ platform_osx/macutils.mm

$(OBJDIR)/client/platform_osx/SDLMain.o: platform_osx/SDLMain.m $$(@D)/.stamp
	$(E) $(CYAN)[OS X]$(RRED) Building an Obj-C object file \
	platform_osx/SDLMain.m.$(ENDCOL)
	$(Q) $(TARGET_CC) $(CS_OSX_CFLAGS) -c -o $@ platform_osx/SDLMain.m
endif

$(OBJDIR)/%.o: %.c $$(@D)/.stamp
	$(E) $(CYAN)[libraries]$(RRED) Building a C object file \
		$(subst $(OBJDIR)/,,$@).$(ENDCOL)
	$(Q) $(TARGET_CC) $(CFLAGS) -c -o $@ $(subst .o,.c,$(subst $(OBJDIR)/,,$@))

$(ENET_OBJ_BUILD): CFLAGS = $(ENET_CFLAGS)
enet: $(ENET_OBJ_BUILD)
	$(E) $(PURPLE)Creating a static library $(ENET_LIB).$(ENDCOL)
	$(Q) $(TARGET_AR) $(OBJDIR)/$(ENET_LIB) $(ENET_OBJ_BUILD)
	$(E) $(GREEN)Built target: enet.$(ENDCOL)

luajit:
	$(E) $(PURPLE)Building LuaJIT.$(ENDCOL)
	$(Q) cd $(LUAJIT_PATH); $(MAKE) XCFLAGS=$(LUAJIT_CFLAGS) \
		BUILDMODE=$(LUAJIT_BUILDMODE) CC=$(LUAJIT_CC) \
		TARGET_AR="$(LUAJIT_TARGET_AR)" TARGET_STRIP="$(LUAJIT_TARGET_STRIP)"
	$(E) $(GREEN)Built target: luajit.$(ENDCOL)

$(OBJDIR)/client/%.o: %.cpp $$(@D)/.stamp
	$(E) $(BLUE)[client]$(RRED) Building a C++ object file \
	$(subst $(OBJDIR)/client/,,$@).$(ENDCOL)
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) -c -o $@ \
		$(subst .o,.cpp,$(subst $(OBJDIR)/client/,,$@))

client: enet luajit $(CLIENT_OBJ_BUILD)
	$(E) $(BLUE)Linking a client executable $(CLIENT_BIN).$(ENDCOL)
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) -o $(CLIENT_BIN) \
		$(CLIENT_OBJ_BUILD) $(CLIENT_LDFLAGS)
	$(E) $(GREEN)Built target: client.$(ENDCOL)

$(OBJDIR)/server/%.o: %.cpp $$(@D)/.stamp
	$(E) $(PURPLE)[server]$(RRED) Building a C++ object file \
	$(subst $(OBJDIR)/server/,,$@).$(ENDCOL)
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) -c -o $@ \
		$(subst .o,.cpp,$(subst $(OBJDIR)/server/,,$@))

server: enet luajit $(SERVER_OBJ_BUILD)
	$(E) $(BLUE)Linking a server executable $(SERVER_BIN).$(ENDCOL)
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) -o $(SERVER_BIN) \
		$(SERVER_OBJ_BUILD) $(SERVER_LDFLAGS)
	$(E) $(GREEN)Built target: server.$(ENDCOL)

$(OBJDIR)/cube2font.o: shared/cube2font.c
	$(TARGET_CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) \
		-c -o $@ $< `freetype-config --cflags`

cube2font: $(OBJDIR)/cube2font.o
	$(TARGET_CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_WARN) -o cube2font \
		$(OBJDIR)/cube2font.o `freetype-config --libs` -lz

# general targets
all: client server

ifneq ($(FLAV), Windows)
clean:
	$(E) $(CYAN)Cleaning up...$(ENDCOL)
	$(Q) -rm -rf $(OBJDIR) $(CLIENT_BIN) $(SERVER_BIN)
	$(Q) -cd $(LUAJIT_PATH); $(MAKE) clean
	$(E) $(GREEN)... done.$(ENDCOL)
else
clean:
	$(E) Cleaning up...
	$(Q) -rmdir //s //f //q $(OBJDIR)
	$(Q) -del //s //f //q $(CLIENT_BIN) $(SERVER_BIN)
	$(Q) -cd $(LUAJIT_PATH); $(MAKE) clean
	$(E) ... done.
endif

install: client server
	$(E) $(CYAN)Installing...$(ENDCOL)
ifneq ($(FLAV), Windows)
	$(E) $(CYAN)Copying $(CLIENT_BIN) to $(BIN_PATH).$(ENDCOL)
	$(Q) cp -f $(CLIENT_BIN) $(BIN_PATH)
	$(E) $(CYAN)Copying $(SERVER_BIN) to $(BIN_PATH).$(ENDCOL)
	$(Q) cp -f $(SERVER_BIN) $(BIN_PATH)
ifeq (,$(NOSTRIP))
	$(Q) $(TARGET_STRIP) $(BIN_PATH)/$(CLIENT_BIN)
	$(Q) $(TARGET_STRIP) $(BIN_PATH)/$(SERVER_BIN)
endif
else
	$(E) Copying $(CLIENT_BIN) to $(BIN_PATH).
	$(Q) copy $(CLIENT_BIN) $(BIN_PATH)
	$(E) Copying $(SERVER_BIN) to $(BIN_PATH).
	$(Q) copy $(SERVER_BIN) $(BIN_PATH)
ifeq (,$(NOSTRIP))
	$(Q) $(TARGET_STRIP) $(BIN_PATH)\$(CLIENT_BIN)
	$(Q) $(TARGET_STRIP) $(BIN_PATH)\$(SERVER_BIN)
endif
endif
	$(E) $(GREEN)... done.$(ENDCOL)

# dependency generator
depend:
	makedepend -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Ifpsgame \
		-Iintensity \
		-Ioctaforge \
		-I$(OFTL_INC) \
		-DCLIENT \
		-p$$\(OBJDIR\)/client/ \
		$(subst .o,.cpp,$(CLIENT_OBJ))

	makedepend -a -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Ifpsgame \
		-Iintensity \
		-Ioctaforge \
		-I$(OFTL_INC) \
		-DSERVER \
		-p$$\(OBJDIR\)/server/ \
		$(subst .o,.cpp,$(SERVER_OBJ))

	makedepend -a -Y -w 65536 \
		-I$(ENET_INC) \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(ENET_OBJ))

# DO NOT DELETE

$(OBJDIR)/client/octaforge/of_tools.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/engine/blend.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/serverbrowser.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/intensity/editing_system.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/messages.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/targeting.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/network_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/intensity/message_system.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/intensity/client_system.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/client_engine_additions.h intensity/targeting.h intensity/client_system.h octaforge/of_world.h
$(OBJDIR)/client/intensity/client_engine_additions.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/client_system.h intensity/client_engine_additions.h intensity/targeting.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/fpsgame/fps.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/client/fpsgame/server.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/fpsgame/client.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/editing_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/network_system.h intensity/targeting.h intensity/client_engine_additions.h
$(OBJDIR)/client/fpsgame/render.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h fpsgame/game.h shared/crypto.h intensity/client_system.h
$(OBJDIR)/client/fpsgame/weapon.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h fpsgame/game.h
$(OBJDIR)/client/shared/tools.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h
$(OBJDIR)/client/shared/geom.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h
$(OBJDIR)/client/engine/aa.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/AreaTex.h engine/SearchTex.h
$(OBJDIR)/client/engine/rendertext.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/material.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/octaedit.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/grass.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/physics.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/mpr.h fpsgame/game.h intensity/targeting.h intensity/client_engine_additions.h octaforge/of_entities.h
$(OBJDIR)/client/engine/rendergl.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/client_engine_additions.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/client/engine/renderlights.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/worldio.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_world.h octaforge/of_entities.h
$(OBJDIR)/client/engine/texture.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/console.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/client_engine_additions.h octaforge/of_tools.h
$(OBJDIR)/client/engine/world.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/engine/renderva.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/normal.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/rendermodel.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/ragdoll.h engine/animmodel.h engine/vertmodel.h engine/skelmodel.h engine/hitzone.h octaforge/of_tools.h engine/md3.h engine/md5.h engine/obj.h engine/smd.h engine/iqm.h
$(OBJDIR)/client/engine/main.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/client_system.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_localserver.h octaforge/of_tools.h
$(OBJDIR)/client/engine/bih.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/octa.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/light.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/water.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/shader.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/rendersky.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/renderparticles.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h engine/explosion.h engine/lensflare.h engine/lightning.h
$(OBJDIR)/client/engine/octarender.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/server.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/client/engine/client.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/client_system.h intensity/network_system.h
$(OBJDIR)/client/engine/dynlight.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/decal.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/sound.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/pvs.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/intensity/engine_additions.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/targeting.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/targeting.h intensity/client_system.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/network_system.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/client/octaforge/of_vars.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h intensity/targeting.h
$(OBJDIR)/client/shared/stream.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_tools.h
$(OBJDIR)/client/shared/zip.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h
$(OBJDIR)/client/engine/movie.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/octaforge/of_lapi.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h octaforge/of_tools.h intensity/client_engine_additions.h intensity/client_system.h intensity/targeting.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_entities.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_lapi_base.h octaforge/of_lapi_blend.h octaforge/of_lapi_camera.h octaforge/of_lapi_edit.h octaforge/of_lapi_entity.h octaforge/of_lapi_input.h octaforge/of_lapi_messages.h octaforge/of_lapi_model.h octaforge/of_lapi_network.h octaforge/of_lapi_parthud.h octaforge/of_lapi_shaders.h octaforge/of_lapi_sound.h octaforge/of_lapi_tex.h octaforge/of_lapi_world.h
$(OBJDIR)/client/octaforge/of_localserver.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_tools.h octaforge/of_localserver.h intensity/client_system.h
$(OBJDIR)/client/octaforge/of_world.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_tools.h fpsgame/game.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/octaforge/of_logger.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_tools.h
$(OBJDIR)/client/octaforge/of_entities.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h
$(OBJDIR)/client/octaforge/of_eapi.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/libraries/OFTL/src/filesystem/platform_posix.o: libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/pair.h

$(OBJDIR)/server/octaforge/of_tools.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/editing_system.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/shared/tools.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h
$(OBJDIR)/server/engine/server.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/server/fpsgame/fps.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/server/fpsgame/server.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/fpsgame/client.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/editing_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/network_system.h intensity/targeting.h
$(OBJDIR)/server/intensity/message_system.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/server/intensity/server_system.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/intensity/messages.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/network_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/engine/world.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/engine/worldio.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_entities.h octaforge/of_localserver.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/engine_additions.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/engine/octa.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/engine/physics.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/mpr.h fpsgame/game.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/server/engine/bih.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/shared/geom.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h
$(OBJDIR)/server/engine/client.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h
$(OBJDIR)/server/engine/octaedit.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/intensity/network_system.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/server/octaforge/of_vars.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/server/engine/octarender.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/shared/stream.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_tools.h
$(OBJDIR)/server/shared/zip.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h
$(OBJDIR)/server/octaforge/of_lapi.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h octaforge/of_tools.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_entities.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_lapi_base.h octaforge/of_lapi_blend.h octaforge/of_lapi_camera.h octaforge/of_lapi_edit.h octaforge/of_lapi_entity.h octaforge/of_lapi_input.h octaforge/of_lapi_messages.h octaforge/of_lapi_model.h octaforge/of_lapi_network.h octaforge/of_lapi_parthud.h octaforge/of_lapi_shaders.h octaforge/of_lapi_sound.h octaforge/of_lapi_tex.h octaforge/of_lapi_world.h
$(OBJDIR)/server/octaforge/of_world.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_tools.h fpsgame/game.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/octaforge/of_logger.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_tools.h
$(OBJDIR)/server/octaforge/of_entities.o: shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h
$(OBJDIR)/server/octaforge/of_eapi.o: engine/engine.h shared/cube.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/pair.h libraries/OFTL/include/OFTL/hashmap.h libraries/OFTL/include/OFTL/hashset.h libraries/OFTL/include/OFTL/map.h libraries/OFTL/include/OFTL/set.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/shared_ptr.h libraries/OFTL/include/OFTL/random.h libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/lua.h libraries/OFTL/include/OFTL/tuple.h libraries/OFTL/include/OFTL/lua/base.h libraries/OFTL/include/OFTL/lua/function.h libraries/OFTL/include/OFTL/lua/dynamic.h libraries/OFTL/include/OFTL/lua/table.h libraries/OFTL/include/OFTL/lua/state.h libraries/OFTL/include/OFTL/lua/stack.h shared/tools.h shared/geom.h shared/ents.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lapi.h octaforge/of_vars.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/libraries/OFTL/src/filesystem/platform_posix.o: libraries/OFTL/include/OFTL/filesystem.h libraries/OFTL/include/OFTL/utils.h libraries/OFTL/include/OFTL/string.h libraries/OFTL/include/OFTL/stdio.h libraries/OFTL/include/OFTL/iterator.h libraries/OFTL/include/OFTL/list.h libraries/OFTL/include/OFTL/vector.h libraries/OFTL/include/OFTL/traits.h libraries/OFTL/include/OFTL/new.h libraries/OFTL/include/OFTL/algorithm.h libraries/OFTL/include/OFTL/functional.h libraries/OFTL/include/OFTL/pair.h

$(OBJDIR)/libraries/enet/callbacks.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/host.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/list.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/packet.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/peer.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/protocol.o: libraries/enet/include/enet/utility.h libraries/enet/include/enet/time.h libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/unix.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
