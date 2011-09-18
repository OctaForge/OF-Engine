# A makefile for OctaForge
# for use under Linux, Windows, FreeBSD, Solaris and Mac OS X
#
# author: Daniel 'q66' Kolesa <quaker66@gmail.com>
# licensed under MIT (see COPYING.txt for more information).

# flag overrides
CXXFLAGS = -O3 -fomit-frame-pointer
override CXXFLAGS += -Wall -fsigned-char -fno-exceptions -fno-rtti

ifneq (,$(MINGW_CROSS))
OS   = Windows
FLAV = MinGW-cross
ARCH = x86

AR     = mingw32-ar rcu
RANLIB = mingw32-ranlib
STRIP  =
ifeq (,$(findstring -g, $(CXXFLAGS)))
ifeq (,$(findstring -pg, $(CXXFLAGS)))
STRIP  = mingw32-strip
endif
endif

CC  = mingw32-gcc
CXX = mingw32-g++
CPP = mingw32-cpp
endif

# basic OS information
ifeq (,$(OS))
OS   = $(shell uname -s)
ARCH = $(shell uname -m)
endif

ifneq (,$(findstring Windows,$(OS)))
OS = Windows
endif
ifneq (,$(findstring MINGW,$(OS)))
OS = Windows
endif

ifeq (,$(ARCH))
ARCH = x86
endif

ifeq (,$(FLAV))
FLAV = $(OS)
endif

# under mingw, CC defaults to 'cc' and that does not exist by default
ifeq ($(CC), cc)
	CC = gcc
endif

# tools
ifeq (,$(MINGW_CROSS))
AR     = ar rcu
RANLIB = ranlib
STRIP  =
ifeq (,$(findstring -g, $(CXXFLAGS)))
ifeq (,$(findstring -pg, $(CXXFLAGS)))
STRIP  = strip
endif
endif
endif

# verbose
ifeq (,$(VERBOSE))
AT = @
endif

# output colorization on non-windows

ifneq ($(FLAV), Windows)
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

# object directory
OBJDIR = build

# paths
ENET_PATH = libraries/enet
LUA_PATH  = libraries/lua
ifneq ($(OS), Windows)
BIN_PATH  = ../bin_unix
else
ifeq ($(FLAV), Windows)
BIN_PATH  = ..\bin_win
else
BIN_PATH  = ../bin_win
endif
endif

# include paths
ENET_INCLUDE_PATH = $(ENET_PATH)/include
LUA_INCLUDE_PATH  = $(LUA_PATH)/include

# binary names
ifeq (,$(findstring Windows,$(OS)))
CLIENT_BIN = OF_Client_$(OS)-$(ARCH)
SERVER_BIN = OF_Server_$(OS)-$(ARCH)
else
CLIENT_BIN = OF_Client_$(OS)-$(ARCH).exe
SERVER_BIN = OF_Server_$(OS)-$(ARCH).exe
endif

# library names
ENET_LIB = $(ENET_PATH)/libenet.a
LUA_LIB  = $(LUA_PATH)/liblua.a

# general includes
INCLUDES  = -Iofstdlib -Ishared -Iengine -Ifpsgame
INCLUDES += -Iintensity -Ioctaforge
INCLUDES += -I$(ENET_INCLUDE_PATH)
INCLUDES += -I$(LUA_INCLUDE_PATH)

# Windows specific
ifeq ($(OS), Windows)
WINDOWS_INCLUDES = -Iplatform_windows/include
WINDOWS_LIBS     = -Lplatform_windows/lib
endif

# Mac OS X specific
ifeq ($(OS), Darwin)
OSX_FRAMEWORK_PATH = /Library/Frameworks

OSX_OBJ = \
	platform_osx/macutils.o \
	platform_osx/SDLMain.o

OSX_INCLUDES  = -I$(OSX_FRAMEWORK_PATH)/SDL.framework/Headers
OSX_INCLUDES += -I$(OSX_FRAMEWORK_PATH)/SDL_image.framework/Headers
OSX_INCLUDES += -I$(OSX_FRAMEWORK_PATH)/SDL_mixer.framework/Headers
OSX_LIBS  = -F$(OSX_FRAMEWORK_PATH) -framework Cocoa
OSX_LIBS += -framework SDL -framework SDL_image -framework SDL_mixer
endif

# client includes and libs
ifneq ($(OS), Windows)
	ifneq ($(OS), Darwin)
		CLIENT_INC  = $(INCLUDES) -I/usr/X11R6/include
		CLIENT_INC += `sdl-config --cflags` -DCLIENT
		CLIENT_LDD  = -L$(OBJDIR)/$(ENET_PATH) -L$(OBJDIR)/$(LUA_PATH)
		CLIENT_LDD += -lenet -llua -L/usr/X11R6/lib -lX11 `sdl-config --libs`
		CLIENT_LDD += -lSDL_image -lSDL_mixer -lz -lGL
		ifeq ($(OS), Linux)
			CLIENT_LDD += -lrt
		endif
		ifeq ($(OS), SunOS)
			CLIENT_LDD += -lsocket -lnsl
		endif
	else
		CLIENT_INC  = $(INCLUDES) -I/usr/X11R6/include $(OSX_INCLUDES) -DCLIENT
		CLIENT_LDD  = -L$(OBJDIR)/$(ENET_PATH) -L$(OBJDIR)/$(LUA_PATH)
		CLIENT_LDD += -lenet -llua -L/usr/X11R6/lib -lX11 $(OSX_LIBS)
		CLIENT_LDD += -lz -lGL -lobjc
	endif
else
	CLIENT_INC  = $(INCLUDES) $(WINDOWS_INCLUDES) -DCLIENT
	CLIENT_LDD  = -mwindows $(WINDOWS_LIBS)
	CLIENT_LDD += -L$(OBJDIR)/$(ENET_PATH) -L$(OBJDIR)/$(LUA_PATH)
	CLIENT_LDD += -lenet -llua -lSDL -lSDL_image -lSDL_mixer
	CLIENT_LDD += -lzdll -lopengl32 -lws2_32 -lwinmm
	CLIENT_LDD += -static-libgcc -static-libstdc++
endif

# client objects
CLIENT_OBJ = \
	ofstdlib/of_stdio.o \
	ofstdlib/of_string.o \
	octaforge/of_tools.o \
	engine/ui.o \
	engine/blob.o \
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
	engine/rendertext.o \
	engine/material.o \
	engine/octaedit.o \
	engine/grass.o \
	engine/physics.o \
	engine/rendergl.o \
	engine/worldio.o \
	engine/texture.o \
	engine/console.o \
	engine/world.o \
	engine/glare.o \
	engine/renderva.o \
	engine/normal.o \
	engine/rendermodel.o \
	engine/shadowmap.o \
	engine/main.o \
	engine/bih.o \
	engine/octa.o \
	engine/lightmap.o \
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
	octaforge/of_lua.o \
	octaforge/of_vars.o \
	shared/stream.o \
	shared/zip.o \
	engine/movie.o \
	fpsgame/scoreboard.o \
	octaforge/of_localserver.o \
	octaforge/of_world.o \
	octaforge/of_logger.o \
	octaforge/of_entities.o

ifeq ($(OS), Windows)
CLIENT_OBJ += platform_windows/lib/src/SDL_win32_main.o
endif

ifeq ($(OS), Darwin)
CLIENT_OBJ += $(OSX_OBJ)
endif

CLIENT_OBJ_BUILD = $(addprefix $(OBJDIR)/client/, $(CLIENT_OBJ))

# server includes and libs
ifneq ($(OS), Windows)
	ifneq ($(OS), Darwin)
		SERVER_INC  = $(INCLUDES) -I/usr/X11R6/include
		SERVER_INC += `sdl-config --cflags` -DSERVER
		SERVER_LDD  = -L$(OBJDIR)/$(ENET_PATH) -L$(OBJDIR)/$(LUA_PATH)
		SERVER_LDD += -lenet -llua -L/usr/X11R6/lib -lX11 `sdl-config --libs`
		SERVER_LDD += -lSDL_image -lSDL_mixer -lz
		ifeq ($(OS), SunOS)
			SERVER_LDD += -lsocket -lnsl
		endif
	else
		SERVER_INC  = $(INCLUDES) -I/usr/X11R6/include $(OSX_INCLUDES) -DSERVER
		SERVER_LDD  = -L$(OBJDIR)/$(ENET_PATH) -L$(OBJDIR)/$(LUA_PATH)
		SERVER_LDD += -lenet -llua -L/usr/X11R6/lib -lX11 $(OSX_LIBS)
		SERVER_LDD += -lz -lobjc
	endif
else
	SERVER_INC  = $(INCLUDES) $(WINDOWS_INCLUDES) -DSERVER
	SERVER_LDD  = -mwindows $(WINDOWS_LIBS)
	SERVER_LDD += -L$(OBJDIR)/$(ENET_PATH) -L$(OBJDIR)/$(LUA_PATH)
	SERVER_LDD += -lenet -llua -lSDL -lSDL_image -lSDL_mixer
	SERVER_LDD += -lzdll -lopengl32 -lws2_32 -lwinmm
	SERVER_LDD += -static-libgcc -static-libstdc++
endif

# server objects
SERVER_OBJ = \
	ofstdlib/of_stdio.o \
	ofstdlib/of_string.o \
	octaforge/of_tools.o \
	intensity/editing_system.o \
	shared/tools.o \
	engine/server.o \
	engine/serverbrowser.o \
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
	engine/rendermodel.o \
	engine/normal.o \
	engine/bih.o \
	shared/geom.o \
	engine/client.o \
	engine/octaedit.o \
	intensity/targeting.o \
	intensity/network_system.o \
	octaforge/of_lua.o \
	octaforge/of_vars.o \
	engine/octarender.o \
	fpsgame/weapon.o \
	shared/stream.o \
	engine/pvs.o \
	engine/blend.o \
	shared/zip.o \
	octaforge/of_world.o \
	octaforge/of_logger.o \
	octaforge/of_entities.o

ifeq ($(OS), Windows)
SERVER_OBJ += platform_windows/lib/src/SDL_win32_main.o
endif

ifeq ($(OS), Darwin)
SERVER_OBJ += $(OSX_OBJ)
endif

SERVER_OBJ_BUILD = $(addprefix $(OBJDIR)/server/, $(SERVER_OBJ))

# enet includes
ENET_INC = -I$(ENET_INCLUDE_PATH) -DHAS_SOCKLEN_T=1 -Wno-error

# enet objects
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

# lua includes
LUA_INC = -I$(LUA_INCLUDE_PATH)

# lua objects
LUA_OBJ = \
	libraries/lua/lapi.o \
	libraries/lua/lcode.o \
	libraries/lua/ldebug.o \
	libraries/lua/ldo.o \
	libraries/lua/ldump.o \
	libraries/lua/lfunc.o \
	libraries/lua/lgc.o \
	libraries/lua/llex.o \
	libraries/lua/lmem.o \
	libraries/lua/lobject.o \
	libraries/lua/lopcodes.o \
	libraries/lua/lparser.o \
	libraries/lua/lstate.o \
	libraries/lua/lstring.o \
	libraries/lua/ltable.o \
	libraries/lua/ltm.o \
	libraries/lua/lundump.o \
	libraries/lua/lvm.o \
	libraries/lua/lzio.o \
 \
	libraries/lua/lauxlib.o \
	libraries/lua/lbaselib.o \
	libraries/lua/ldblib.o \
	libraries/lua/liolib.o \
	libraries/lua/lmathlib.o \
	libraries/lua/loslib.o \
	libraries/lua/ltablib.o \
	libraries/lua/lstrlib.o \
	libraries/lua/loadlib.o \
	libraries/lua/linit.o
LUA_OBJ_BUILD = $(addprefix $(OBJDIR)/, $(LUA_OBJ))

#
# TARGETS
#

# phony targets
.PHONY: default all

# default target - builds all
default: all

# secondary expansion - feature of gnu make 3.81
.SECONDEXPANSION:

# target for appropriately handling
# directory creation (for OBJDIR)
ifneq ($(FLAV), Windows)
%/.stamp:
	$(AT) mkdir -p $(dir $@)
	$(AT) touch $@
else
%/.stamp:
	$(AT) md $(subst /,\,$(dir $@))
	$(AT) type nul > $(subst /,\,$@)
endif

# mark stamp files as precious so make doesn't delete them
.PRECIOUS: %/.stamp

# builds the C files appropriately, using secondary
# expansion to properly pre-create needed directories
$(OBJDIR)/%.o: %.c $$(@D)/.stamp
	@echo $(CYAN)[libraries]$(RRED) Building a C object file \
	$(subst $(OBJDIR)/,,$@).$(ENDCOL)
	$(AT) $(CC) $(CFLAGS) -c -o $@ $(subst .o,.c,$(subst $(OBJDIR)/,,$@))

# some Mac OS X specific targets
ifeq ($(OS), Darwin)
$(OBJDIR)/client/platform_osx/macutils.o: platform_osx/macutils.mm \
$$(@D)/.stamp
	@echo $(CYAN)[OS X]$(RRED) Building an Obj-C++ object file \
	platform_osx/macutils.mm.$(ENDCOL)
	$(AT) $(CXX) $(CXXFLAGS) $(OSX_INCLUDES) \
		-Wno-import -c -o $@ platform_osx/macutils.mm

$(OBJDIR)/client/platform_osx/SDLMain.o: platform_osx/SDLMain.m $$(@D)/.stamp
	@echo $(CYAN)[OS X]$(RRED) Building an Obj-C object file \
	platform_osx/SDLMain.m.$(ENDCOL)
	$(AT) $(CC) $(CFLAGS) $(OSX_INCLUDES) \
		-Wno-import -c -o $@ platform_osx/SDLMain.m

$(OBJDIR)/server/platform_osx/macutils.o: platform_osx/macutils.mm \
$$(@D)/.stamp
	@echo $(CYAN)[OS X]$(RRED) Building an Obj-C++ object file \
	platform_osx/macutils.mm.$(ENDCOL)
	$(AT) $(CXX) $(CXXFLAGS) $(OSX_INCLUDES) \
		-Wno-import -c -o $@ platform_osx/macutils.mm

$(OBJDIR)/server/platform_osx/SDLMain.o: platform_osx/SDLMain.m $$(@D)/.stamp
	@echo $(CYAN)[OS X]$(RRED) Building an Obj-C object file \
	platform_osx/SDLMain.m.$(ENDCOL)
	$(AT) $(CC) $(CFLAGS) $(OSX_INCLUDES) \
		-Wno-import -c -o $@ platform_osx/SDLMain.m
endif

# enet
$(ENET_OBJ_BUILD): CFLAGS += $(ENET_INC)
enet: $(ENET_OBJ_BUILD)
	@echo $(PURPLE)Creating a static library $(ENET_LIB).$(ENDCOL)
	$(AT) $(AR) $(OBJDIR)/$(ENET_LIB) $(ENET_OBJ_BUILD)
	$(AT) $(RANLIB) $(OBJDIR)/$(ENET_LIB)
	@echo $(GREEN)Built target: enet.$(ENDCOL)

# lua
$(LUA_OBJ_BUILD): CFLAGS += $(LUA_INC)
lua: $(LUA_OBJ_BUILD)
	@echo $(PURPLE)Creating a static library $(LUA_LIB).$(ENDCOL)
	$(AT) $(AR) $(OBJDIR)/$(LUA_LIB) $(LUA_OBJ_BUILD)
	$(AT) $(RANLIB) $(OBJDIR)/$(LUA_LIB)
	@echo $(GREEN)Built target: lua.$(ENDCOL)

# client
$(OBJDIR)/client/%.o: %.cpp $$(@D)/.stamp
	@echo $(BLUE)[client]$(RRED) Building a C++ object file \
	$(subst $(OBJDIR)/client/,,$@).$(ENDCOL)
	$(AT) $(CXX) $(CXXFLAGS) -c -o $@ \
		$(subst .o,.cpp,$(subst $(OBJDIR)/client/,,$@))

$(CLIENT_OBJ_BUILD): CXXFLAGS += $(CLIENT_INC)
client: enet lua $(CLIENT_OBJ_BUILD)
	@echo $(BLUE)Linking a client executable $(CLIENT_BIN).$(ENDCOL)
	$(AT) $(CXX) $(CXXFLAGS) -o $(CLIENT_BIN) $(CLIENT_OBJ_BUILD) $(CLIENT_LDD)
	@echo $(GREEN)Built target: client.$(ENDCOL)

# server
$(OBJDIR)/server/%.o: %.cpp $$(@D)/.stamp
	@echo $(PURPLE)[server]$(RRED) Building a C++ object file \
	$(subst $(OBJDIR)/server/,,$@).$(ENDCOL)
	$(AT) $(CXX) $(CXXFLAGS) -c -o $@ \
		$(subst .o,.cpp,$(subst $(OBJDIR)/server/,,$@))

$(SERVER_OBJ_BUILD): CXXFLAGS += $(SERVER_INC)
server: enet lua $(SERVER_OBJ_BUILD)
	@echo $(BLUE)Linking a server executable $(SERVER_BIN).$(ENDCOL)
	$(AT) $(CXX) $(CXXFLAGS) -o $(SERVER_BIN) $(SERVER_OBJ_BUILD) $(SERVER_LDD)
	@echo $(GREEN)Built target: server.$(ENDCOL)

# general targets
all: client server

ifneq ($(FLAV), Windows)
clean:
	@echo $(CYAN)Cleaning up...$(ENDCOL)
	$(AT) -rm -rf $(OBJDIR) $(CLIENT_BIN) $(SERVER_BIN)
	@echo $(GREEN)... done.$(ENDCOL)
else
clean:
	@echo Cleaning up...
	$(AT) -rmdir //s //f //q $(OBJDIR)
	$(AT) -del //s //f //q $(CLIENT_BIN) $(SERVER_BIN)
	@echo ... done.
endif

install: client server
	@echo $(CYAN)Installing...$(ENDCOL)
ifneq ($(FLAV), Windows)
	@echo $(CYAN)Copying $(CLIENT_BIN) to $(BIN_PATH).$(ENDCOL)
	$(AT) cp $(CLIENT_BIN) $(BIN_PATH)
	@echo $(CYAN)Copying $(SERVER_BIN) to $(BIN_PATH).$(ENDCOL)
	$(AT) cp $(SERVER_BIN) $(BIN_PATH)
ifneq (,$(STRIP))
ifeq (,$(NOSTRIP))
	@echo $(CYAN)Stripping $(BIN_PATH)/$(CLIENT_BIN).$(ENDCOL)
	$(AT) $(STRIP) $(BIN_PATH)/$(CLIENT_BIN)
	@echo $(CYAN)Stripping $(BIN_PATH)/$(SERVER_BIN).$(ENDCOL)
	$(AT) $(STRIP) $(BIN_PATH)/$(SERVER_BIN)
endif
endif
else
	@echo Copying $(CLIENT_BIN) to $(BIN_PATH).
	$(AT) copy $(CLIENT_BIN) $(BIN_PATH)
	@echo Copying $(SERVER_BIN) to $(BIN_PATH).
	$(AT) copy $(SERVER_BIN) $(BIN_PATH)
ifneq (,$(STRIP))
ifeq (,$(NOSTRIP))
	@echo Stripping $(BIN_PATH)\$(CLIENT_BIN).
	$(AT) $(STRIP) $(BIN_PATH)\$(CLIENT_BIN)
	@echo Stripping $(BIN_PATH)\$(SERVER_BIN).
	$(AT) $(STRIP) $(BIN_PATH)\$(SERVER_BIN)
endif
endif
endif
	@echo $(GREEN)... done.$(ENDCOL)

# dependency generator
depend:
	makedepend -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Ifpsgame \
		-Iintensity \
		-Ioctaforge \
		-Iofstdlib \
		-p$$\(OBJDIR\)/client/ \
		$(subst .o,.cpp,$(CLIENT_OBJ))

	makedepend -a -Y -w 65536 \
		-Ishared \
		-Iengine \
		-Ifpsgame \
		-Iintensity \
		-Ioctaforge \
		-Iofstdlib \
		-p$$\(OBJDIR\)/server/ \
		$(subst .o,.cpp,$(SERVER_OBJ))

	makedepend -a -Y -w 65536 \
		-I$(ENET_INCLUDE_PATH) \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(ENET_OBJ))

	makedepend -a -Y -w 65536 \
		-I$(LUA_INCLUDE_PATH) \
		-p$$\(OBJDIR\)/ \
		$(subst .o,.c,$(LUA_OBJ))

# DO NOT DELETE

$(OBJDIR)/client/ofstdlib/of_string.o: ofstdlib/of_string.h ofstdlib/of_utils.h ofstdlib/of_stdio.h
$(OBJDIR)/client/octaforge/of_tools.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/engine/ui.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/textedit.h intensity/client_engine_additions.h
$(OBJDIR)/client/engine/blob.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/blend.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h ofstdlib/of_shared_ptr.h
$(OBJDIR)/client/engine/serverbrowser.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/intensity/editing_system.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/messages.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/network_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/intensity/message_system.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/intensity/client_system.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/client_engine_additions.h intensity/targeting.h intensity/client_system.h octaforge/of_world.h
$(OBJDIR)/client/intensity/client_engine_additions.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/client_system.h intensity/client_engine_additions.h intensity/targeting.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/fpsgame/fps.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/client/fpsgame/server.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/fpsgame/client.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/editing_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/network_system.h intensity/targeting.h
$(OBJDIR)/client/fpsgame/render.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h fpsgame/game.h shared/crypto.h intensity/client_system.h
$(OBJDIR)/client/fpsgame/weapon.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h fpsgame/game.h
$(OBJDIR)/client/shared/tools.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h
$(OBJDIR)/client/shared/geom.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h
$(OBJDIR)/client/engine/rendertext.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/material.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/octaedit.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/grass.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/physics.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/mpr.h fpsgame/game.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/client/engine/rendergl.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/client_engine_additions.h intensity/targeting.h
$(OBJDIR)/client/engine/worldio.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_entities.h
$(OBJDIR)/client/engine/texture.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/console.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/client_engine_additions.h octaforge/of_tools.h ofstdlib/of_shared_ptr.h
$(OBJDIR)/client/engine/world.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/engine/glare.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/rendertarget.h
$(OBJDIR)/client/engine/renderva.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/normal.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/rendermodel.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/ragdoll.h engine/animmodel.h engine/vertmodel.h engine/skelmodel.h engine/md5.h engine/obj.h engine/smd.h engine/iqm.h
$(OBJDIR)/client/engine/shadowmap.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/rendertarget.h octaforge/of_entities.h
$(OBJDIR)/client/engine/main.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/client_system.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_localserver.h octaforge/of_tools.h
$(OBJDIR)/client/engine/bih.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/octa.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/lightmap.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/water.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/shader.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/rendersky.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/renderparticles.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/rendertarget.h octaforge/of_entities.h engine/depthfx.h engine/explosion.h engine/lensflare.h engine/lightning.h
$(OBJDIR)/client/engine/octarender.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/server.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/client/engine/client.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h
$(OBJDIR)/client/engine/dynlight.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/decal.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/engine/sound.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_entities.h
$(OBJDIR)/client/engine/pvs.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/intensity/engine_additions.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/targeting.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/client/intensity/network_system.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/client/octaforge/of_lua.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h octaforge/of_tools.h octaforge/of_localserver.h octaforge/of_world.h octaforge/of_entities.h octaforge/of_lua_definitions.h octaforge/of_lua_base.h octaforge/of_lua_entity.h octaforge/of_lua_world.h octaforge/of_lua_sound.h octaforge/of_lua_model.h octaforge/of_lua_tex.h octaforge/of_lua_shaders.h octaforge/of_lua_parthud.h octaforge/of_lua_gui.h octaforge/of_lua_edit.h octaforge/of_lua_blend.h octaforge/of_lua_messages.h octaforge/of_lua_input.h octaforge/of_lua_textedit.h octaforge/of_lua_network.h octaforge/of_lua_camera.h
$(OBJDIR)/client/octaforge/of_vars.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/shared/stream.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h octaforge/of_tools.h
$(OBJDIR)/client/shared/zip.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h
$(OBJDIR)/client/engine/movie.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/fpsgame/scoreboard.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/client/octaforge/of_localserver.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h octaforge/of_tools.h octaforge/of_localserver.h intensity/client_system.h
$(OBJDIR)/client/octaforge/of_world.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h octaforge/of_tools.h fpsgame/game.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/client/octaforge/of_logger.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_tools.h
$(OBJDIR)/client/octaforge/of_entities.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h ofstdlib/of_shared_ptr.h

$(OBJDIR)/server/ofstdlib/of_string.o: ofstdlib/of_string.h ofstdlib/of_utils.h ofstdlib/of_stdio.h
$(OBJDIR)/server/octaforge/of_tools.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/editing_system.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/shared/tools.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h
$(OBJDIR)/server/engine/server.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/server/engine/serverbrowser.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/fpsgame/fps.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/server/fpsgame/server.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/fpsgame/client.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/editing_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/network_system.h intensity/targeting.h
$(OBJDIR)/server/intensity/message_system.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/server/intensity/server_system.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/messages.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/network_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/engine/world.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/engine/worldio.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_entities.h
$(OBJDIR)/server/intensity/engine_additions.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h octaforge/of_entities.h
$(OBJDIR)/server/engine/octa.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/engine/physics.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/mpr.h fpsgame/game.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/server/engine/rendermodel.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h engine/ragdoll.h engine/animmodel.h engine/vertmodel.h engine/skelmodel.h engine/md5.h engine/obj.h engine/smd.h engine/iqm.h
$(OBJDIR)/server/engine/normal.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/engine/bih.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/shared/geom.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h
$(OBJDIR)/server/engine/client.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h
$(OBJDIR)/server/engine/octaedit.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/intensity/targeting.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/targeting.h octaforge/of_entities.h
$(OBJDIR)/server/intensity/network_system.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/server/octaforge/of_lua.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h octaforge/of_tools.h octaforge/of_localserver.h octaforge/of_world.h octaforge/of_entities.h octaforge/of_lua_definitions.h octaforge/of_lua_base.h octaforge/of_lua_entity.h octaforge/of_lua_world.h octaforge/of_lua_sound.h octaforge/of_lua_model.h octaforge/of_lua_tex.h octaforge/of_lua_shaders.h octaforge/of_lua_parthud.h octaforge/of_lua_gui.h octaforge/of_lua_edit.h octaforge/of_lua_blend.h octaforge/of_lua_messages.h octaforge/of_lua_input.h octaforge/of_lua_textedit.h octaforge/of_lua_network.h octaforge/of_lua_camera.h
$(OBJDIR)/server/octaforge/of_vars.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/server/engine/octarender.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/fpsgame/weapon.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h fpsgame/game.h
$(OBJDIR)/server/shared/stream.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h octaforge/of_tools.h
$(OBJDIR)/server/engine/pvs.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/engine/blend.o: engine/engine.h shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h ofstdlib/of_shared_ptr.h
$(OBJDIR)/server/shared/zip.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h
$(OBJDIR)/server/octaforge/of_world.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h octaforge/of_tools.h fpsgame/game.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h
$(OBJDIR)/server/octaforge/of_logger.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h engine/engine.h engine/world.h engine/octa.h engine/lightmap.h engine/bih.h engine/texture.h engine/model.h engine/varray.h octaforge/of_tools.h
$(OBJDIR)/server/octaforge/of_entities.o: shared/cube.h ofstdlib/of_string.h ofstdlib/of_utils.h shared/tools.h ofstdlib/of_new.h shared/geom.h shared/ents.h shared/iengine.h intensity/intensity.h octaforge/of_vars.h intensity/engine_additions.h octaforge/of_logger.h octaforge/of_lua.h shared/igame.h ofstdlib/of_shared_ptr.h

$(OBJDIR)/libraries/enet/callbacks.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/host.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/list.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/packet.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/peer.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/protocol.o: libraries/enet/include/enet/utility.h libraries/enet/include/enet/time.h libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/unix.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h

$(OBJDIR)/libraries/lua/lapi.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lapi.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/ldo.h libraries/lua/include/lfunc.h libraries/lua/include/lgc.h libraries/lua/include/lstring.h libraries/lua/include/ltable.h libraries/lua/include/lundump.h libraries/lua/include/lvm.h
$(OBJDIR)/libraries/lua/lcode.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lcode.h libraries/lua/include/llex.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/lopcodes.h libraries/lua/include/lparser.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/ldo.h libraries/lua/include/lgc.h libraries/lua/include/ltable.h
$(OBJDIR)/libraries/lua/ldebug.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lapi.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/lcode.h libraries/lua/include/llex.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/lopcodes.h libraries/lua/include/lparser.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/ldo.h libraries/lua/include/lfunc.h libraries/lua/include/lstring.h libraries/lua/include/lgc.h libraries/lua/include/ltable.h libraries/lua/include/lvm.h
$(OBJDIR)/libraries/lua/ldo.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/ldo.h libraries/lua/include/lfunc.h libraries/lua/include/lgc.h libraries/lua/include/lopcodes.h libraries/lua/include/lparser.h libraries/lua/include/lstring.h libraries/lua/include/ltable.h libraries/lua/include/lundump.h libraries/lua/include/lvm.h
$(OBJDIR)/libraries/lua/ldump.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/lundump.h
$(OBJDIR)/libraries/lua/lfunc.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lfunc.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/lgc.h libraries/lua/include/lmem.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h
$(OBJDIR)/libraries/lua/lgc.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/ldo.h libraries/lua/include/lfunc.h libraries/lua/include/lgc.h libraries/lua/include/lstring.h libraries/lua/include/ltable.h
$(OBJDIR)/libraries/lua/llex.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldo.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/llex.h libraries/lua/include/lparser.h libraries/lua/include/lstring.h libraries/lua/include/lgc.h libraries/lua/include/ltable.h
$(OBJDIR)/libraries/lua/lmem.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/ldo.h
$(OBJDIR)/libraries/lua/lobject.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldo.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/lstring.h libraries/lua/include/lgc.h libraries/lua/include/lvm.h
$(OBJDIR)/libraries/lua/lopcodes.o: libraries/lua/include/lopcodes.h libraries/lua/include/llimits.h libraries/lua/include/lua.h libraries/lua/include/luaconf.h
$(OBJDIR)/libraries/lua/lparser.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lcode.h libraries/lua/include/llex.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/lopcodes.h libraries/lua/include/lparser.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/ldo.h libraries/lua/include/lfunc.h libraries/lua/include/lstring.h libraries/lua/include/lgc.h libraries/lua/include/ltable.h
$(OBJDIR)/libraries/lua/lstate.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/ldo.h libraries/lua/include/lfunc.h libraries/lua/include/lgc.h libraries/lua/include/llex.h libraries/lua/include/lstring.h libraries/lua/include/ltable.h
$(OBJDIR)/libraries/lua/lstring.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lmem.h libraries/lua/include/llimits.h libraries/lua/include/lobject.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lstring.h libraries/lua/include/lgc.h
$(OBJDIR)/libraries/lua/ltable.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/ldo.h libraries/lua/include/lgc.h libraries/lua/include/ltable.h
$(OBJDIR)/libraries/lua/ltm.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/lstate.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/lstring.h libraries/lua/include/lgc.h libraries/lua/include/ltable.h
$(OBJDIR)/libraries/lua/lundump.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/ldo.h libraries/lua/include/lfunc.h libraries/lua/include/lstring.h libraries/lua/include/lgc.h libraries/lua/include/lundump.h
$(OBJDIR)/libraries/lua/lvm.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/ldebug.h libraries/lua/include/lstate.h libraries/lua/include/lobject.h libraries/lua/include/llimits.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h libraries/lua/include/lmem.h libraries/lua/include/ldo.h libraries/lua/include/lfunc.h libraries/lua/include/lgc.h libraries/lua/include/lopcodes.h libraries/lua/include/lstring.h libraries/lua/include/ltable.h libraries/lua/include/lvm.h
$(OBJDIR)/libraries/lua/lzio.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/llimits.h libraries/lua/include/lmem.h libraries/lua/include/lstate.h libraries/lua/include/lobject.h libraries/lua/include/ltm.h libraries/lua/include/lzio.h
$(OBJDIR)/libraries/lua/lauxlib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h
$(OBJDIR)/libraries/lua/lbaselib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h libraries/lua/include/lualib.h
$(OBJDIR)/libraries/lua/ldblib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h libraries/lua/include/lualib.h
$(OBJDIR)/libraries/lua/liolib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h libraries/lua/include/lualib.h
$(OBJDIR)/libraries/lua/lmathlib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h libraries/lua/include/lualib.h
$(OBJDIR)/libraries/lua/loslib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h libraries/lua/include/lualib.h
$(OBJDIR)/libraries/lua/ltablib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h libraries/lua/include/lualib.h
$(OBJDIR)/libraries/lua/lstrlib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h libraries/lua/include/lualib.h
$(OBJDIR)/libraries/lua/loadlib.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lauxlib.h libraries/lua/include/lualib.h
$(OBJDIR)/libraries/lua/linit.o: libraries/lua/include/lua.h libraries/lua/include/luaconf.h libraries/lua/include/lualib.h libraries/lua/include/lauxlib.h
