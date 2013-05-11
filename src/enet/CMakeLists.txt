if(NOT OF_TARGET_WINDOWS)
    include(CheckFunctionExists)
    include(CheckStructHasMember)
    include(CheckTypeSize)

    macro(CHECK_FUNC FUNCTION VARIABLE)
        CHECK_FUNCTION_EXISTS(${FUNCTION} ${VARIABLE})
        if(DEFINED ${VARIABLE})
            add_definitions(-D${VARIABLE})
        endif()
    endmacro()

    CHECK_FUNC(gethostbyaddr_r HAS_GETHOSTBYADDR_R)
    CHECK_FUNC(gethostbyname_r HAS_GETHOSTBYNAME_R)
    CHECK_FUNC(poll HAS_POLL)
    CHECK_FUNC(fcntl HAS_FCNTL)
    CHECK_FUNC(inet_pton HAS_INET_PTON)
    CHECK_FUNC(inet_ntop HAS_INET_NTOP)

    CHECK_STRUCT_HAS_MEMBER("struct msghdr" msg_flags sys/socket.h
        HAS_MSGHDR_FLAGS)
    if(DEFINED HAS_MSGHDR_FLAGS)
        add_definitions(-DHAS_MSGHDR_FLAGS)
    endif()

    set(CMAKE_EXTRA_INCLUDE_FILES sys/types.h;sys/socket.h)
    CHECK_TYPE_SIZE(socklen_t SOCKLEN_T)
    set(CMAKE_EXTRA_INCLUDE_FILES)
    if(DEFINED HAVE_SOCKLEN_T)
        add_definitions(-DHAS_SOCKLEN_T)
    endif()
endif()

if(NOT DEFINED MSVC)
    add_definitions(-Wno-error)
endif()

add_library(enet STATIC callbacks host list packet peer protocol unix win32)