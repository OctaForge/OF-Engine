# OctaForge makefile
# written for FreeBSD, Linux, Solaris, Mac OS X and Windows
#
# author: Daniel 'q66' Kolesa <quaker66@gmail.com>
# license: MIT

CC ?= cc
CC_FLAGS = -O2 -fomit-frame-pointer

CXX ?= c++
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
OSX_FRAMEWORKS = platform_osx/Frameworks

# C++ compiler flags for OF client
CLIENT_XCXXFLAGS =

# C++ compiler flags for OF server
SERVER_XCXXFLAGS =

# C compiler flags for ENet
ENET_XCFLAGS =

# set to a value if you want the engine to link against
# local (typically static) LuaJIT in platform_YOUROS
LUAJIT_LOCAL =

# LuaJIT pkg-config/pkgconf paths
LUAJIT_PKGCONF_PATH += :/usr/local/lib/pkgconfig:/usr/local/libdata/pkgconfig
LUAJIT_PKGCONF_PATH += :/usr/lib/pkgconfig:/usr/libdata/pkgconfig

#####################
# Debugging options #
#####################

###########################################################
# Do not change here if you don't know what you are doing #
###########################################################

# paths

ENET_PATH = libraries/enet

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

TARGET_TESTARCH = $(shell $(TARGET_CC) -E shared/arch_detection.h -dM)
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
ifeq (Windows,$(TARGET_SYS))
	TARGET_STRIP += --strip-unneeded
else
ifeq (Darwin,$(TARGET_SYS))
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

# binary names

TARGET_BINARCH = $(TARGET_ARCH)
ifeq ($(TARGET_SYS),Windows)
	TARGET_BINOS = win
	TARGET_XINC += -Iplatform_windows
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -Lplatform_windows/lib64
	else
		TARGET_XLIB += -Lplatform_windows/lib32
	endif
else
ifeq ($(TARGET_SYS),Linux)
	TARGET_BINOS = linux
	TARGET_XINC += -Iplatform_linux
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -Lplatform_linux/lib64
	else
		TARGET_XLIB += -Lplatform_linux/lib32
	endif
else
ifeq ($(TARGET_SYS),FreeBSD)
	TARGET_BINOS = freebsd
	TARGET_XINC += -Iplatform_freebsd
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -Lplatform_freebsd/lib64
	else
		TARGET_XLIB += -Lplatform_freebsd/lib32
	endif
else
ifeq ($(TARGET_SYS),Darwin)
	TARGET_BINOS = darwin
	TARGET_XINC += -Iplatform_osx
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -Lplatform_osx/lib64
	else
		TARGET_XLIB += -Lplatform_osx/lib32
	endif
else
ifeq ($(TARGET_SYS),SunOS)
	TARGET_BINOS = solaris
	TARGET_XINC += -Iplatform_solaris
	ifeq (x64,$(TARGET_ARCH))
		TARGET_XLIB += -Lplatform_solaris/lib64
	else
		TARGET_XLIB += -Lplatform_solaris/lib32
	endif
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

# LuaJIT detection

ifneq ($(TARGET_SYS),Windows)
	ifeq (,$(LUAJIT_LOCAL))
		LUAJIT_INC = $(shell PKG_CONFIG_PATH="$(LUAJIT_PKGCONF_PATH)" \
			pkg-config --silence-errors --cflags luajit)
		LUAJIT_LIB = $(shell PKG_CONFIG_PATH="$(LUAJIT_PKGCONF_PATH)" \
			pkg-config --silence-errors --libs luajit)
		ifeq (,$(LUAJIT_LIB))
			LUAJIT_LIB = -lluajit
		endif
	else
		LUAJIT_LIB = -lluajit
	endif
else
	LUAJIT_LIB = -lluajit
endif

# client/server includes

CS_INC = -Ishared -Iengine -Ifpsgame
CS_INC += -Iintensity -Ioctaforge
CS_INC += -I$(ENET_INC) $(TARGET_XINC) $(LUAJIT_INC)

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

CLIENT_LDFLAGS = -L$(OBJDIR)/$(ENET_PATH) -lenet $(TARGET_XLIB) $(LUAJIT_LIB)

ifeq ($(TARGET_SYS),Windows)
	CLIENT_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
ifeq ($(TARGET_ARCH),x64)
	CLIENT_CXXFLAGS += -DWIN64
endif
	CLIENT_CXXFLAGS += $(CS_INC)
	CLIENT_LDFLAGS += -lSDL2 -lSDL2_image -lSDL2_mixer
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
	-DBINARY_ARCH=$(TARGET_BINARCH) -DBINARY_OS=$(TARGET_BINOS)

SERVER_LDFLAGS = -L$(OBJDIR)/$(ENET_PATH) -lenet $(TARGET_XLIB) $(LUAJIT_LIB)

ifeq ($(TARGET_SYS),Windows)
	SERVER_CXXFLAGS += -DWIN32 -DWINDOWS -DNO_STDIO_REDIRECT
ifeq ($(TARGET_ARCH),x64)
	SERVER_CXXFLAGS += -DWIN64
endif
	SERVER_CXXFLAGS += $(CS_INC)
	SERVER_LDFLAGS += -lzlib1 -lopengl32 -lws2_32 -lwinmm
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

# ENet

$(ENET_OBJB): CFLAGS = $(ENET_CFLAGS)
enet: $(ENET_OBJB)
	$(E) $(CYAN)[ar     ]$(RRED) $(ENET_LIB)$(ENDCOL)
	$(Q) $(TARGET_AR) $(OBJDIR)/$(ENET_LIB) $(ENET_OBJB)

# OctaForge - client

$(OBJDIR)/client/%.o: %.cpp $$(@D)/.stamp
	$(E) $(PURPLE)[cc     ]$(RGREEN)[client]$(RRED) \
	$(subst $(OBJDIR)/client/,,$@)$(ENDCOL)
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) -c -o $@ \
	$(subst .o,.cpp,$(subst $(OBJDIR)/client/,,$@))

client: enet $(CLIENT_OBJB)
	$(E) $(GREEN)[ld     ]$(RGREEN) $(CLIENT_BIN)$(ENDCOL)
	$(Q) $(TARGET_CXX) $(CLIENT_CXXFLAGS) -o $(CLIENT_BIN) \
	$(CLIENT_OBJB) $(CLIENT_LDFLAGS)

# OctaForge - server

$(OBJDIR)/server/%.o: %.cpp $$(@D)/.stamp
	$(E) $(PURPLE)[cc     ]$(RCYAN)[server]$(RRED) \
	$(subst $(OBJDIR)/server/,,$@)$(ENDCOL)
	$(Q) $(TARGET_CXX) $(SERVER_CXXFLAGS) -c -o $@ \
	$(subst .o,.cpp,$(subst $(OBJDIR)/server/,,$@))

server: enet $(SERVER_OBJB)
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

# DO NOT DELETE

$(OBJDIR)/client/octaforge/of_tools.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/engine/blend.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/serverbrowser.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/intensity/editing_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_tools.h
$(OBJDIR)/client/intensity/messages.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/targeting.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/network_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/client/intensity/message_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/client/intensity/client_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_world.h
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
$(OBJDIR)/client/engine/physics.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/mpr.h fpsgame/game.h intensity/targeting.h
$(OBJDIR)/client/engine/rendergl.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/targeting.h
$(OBJDIR)/client/engine/renderlights.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/worldio.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_world.h
$(OBJDIR)/client/engine/texture.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/console.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h intensity/client_system.h intensity/targeting.h
$(OBJDIR)/client/engine/world.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h
$(OBJDIR)/client/engine/renderva.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/normal.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/rendermodel.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h engine/ragdoll.h engine/animmodel.h engine/vertmodel.h engine/skelmodel.h engine/hitzone.h intensity/client_system.h octaforge/of_tools.h engine/md3.h engine/md5.h engine/obj.h engine/smd.h engine/iqm.h
$(OBJDIR)/client/engine/main.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/client_system.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_localserver.h octaforge/of_tools.h
$(OBJDIR)/client/engine/bih.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/octa.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/light.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/water.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/shader.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/rendersky.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/renderparticles.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/explosion.h engine/lensflare.h engine/lightning.h
$(OBJDIR)/client/engine/octarender.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/server.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/client/engine/client.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/client_system.h intensity/network_system.h
$(OBJDIR)/client/engine/dynlight.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/decal.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/sound.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/engine/pvs.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/intensity/engine_additions.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h
$(OBJDIR)/client/intensity/targeting.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/targeting.h intensity/client_system.h
$(OBJDIR)/client/intensity/network_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/client/shared/stream.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h
$(OBJDIR)/client/shared/zip.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/client/engine/movie.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/octaforge/of_lua.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h octaforge/of_tools.h intensity/client_system.h intensity/targeting.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_lua_api.h
$(OBJDIR)/client/octaforge/of_localserver.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h fpsgame/game.h octaforge/of_tools.h octaforge/of_localserver.h intensity/client_system.h
$(OBJDIR)/client/octaforge/of_world.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h fpsgame/game.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/client/octaforge/of_logger.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h
$(OBJDIR)/client/octaforge/of_entities.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/targeting.h intensity/editing_system.h octaforge/of_world.h

$(OBJDIR)/server/octaforge/of_tools.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/editing_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/targeting.h intensity/client_system.h octaforge/of_tools.h
$(OBJDIR)/server/shared/tools.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/engine/command.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/engine/server.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h
$(OBJDIR)/server/fpsgame/fps.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h octaforge/of_world.h
$(OBJDIR)/server/fpsgame/server.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h fpsgame/game.h intensity/network_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/fpsgame/client.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/editing_system.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/network_system.h intensity/targeting.h
$(OBJDIR)/server/intensity/message_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h
$(OBJDIR)/server/intensity/server_system.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/intensity/messages.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/client_system.h intensity/message_system.h intensity/messages.h intensity/editing_system.h intensity/network_system.h octaforge/of_world.h octaforge/of_tools.h
$(OBJDIR)/server/engine/world.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_tools.h
$(OBJDIR)/server/engine/worldio.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_tools.h
$(OBJDIR)/server/intensity/engine_additions.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/message_system.h intensity/messages.h intensity/client_system.h octaforge/of_tools.h
$(OBJDIR)/server/engine/octa.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/engine/physics.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h engine/mpr.h fpsgame/game.h intensity/targeting.h
$(OBJDIR)/server/engine/bih.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/shared/geom.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/shared/glemu.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/engine/client.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h
$(OBJDIR)/server/engine/octaedit.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/intensity/network_system.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/network_system.h octaforge/of_tools.h
$(OBJDIR)/server/engine/octarender.o: engine/engine.h shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/shared/stream.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h
$(OBJDIR)/server/shared/zip.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h
$(OBJDIR)/server/octaforge/of_lua.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h octaforge/of_tools.h intensity/editing_system.h intensity/message_system.h intensity/messages.h octaforge/of_world.h octaforge/of_localserver.h octaforge/of_lua_api.h
$(OBJDIR)/server/octaforge/of_world.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h octaforge/of_tools.h fpsgame/game.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h
$(OBJDIR)/server/octaforge/of_logger.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h octaforge/of_tools.h
$(OBJDIR)/server/octaforge/of_entities.o: shared/cube.h shared/tools.h shared/geom.h shared/ents.h shared/command.h shared/glexts.h shared/glemu.h shared/iengine.h shared/igame.h octaforge/of_logger.h octaforge/of_lua.h intensity/engine_additions.h engine/engine.h engine/world.h engine/octa.h engine/light.h engine/bih.h engine/texture.h engine/model.h fpsgame/game.h intensity/targeting.h intensity/editing_system.h octaforge/of_world.h

$(OBJDIR)/libraries/enet/callbacks.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/host.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/list.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/packet.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/peer.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/protocol.o: libraries/enet/include/enet/utility.h libraries/enet/include/enet/time.h libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
$(OBJDIR)/libraries/enet/unix.o: libraries/enet/include/enet/enet.h libraries/enet/include/enet/unix.h libraries/enet/include/enet/types.h libraries/enet/include/enet/protocol.h libraries/enet/include/enet/list.h libraries/enet/include/enet/callbacks.h
