# NodeJS.cmake - node.js toolchain for cmake
# Copyright (c) 2020, Christopher Jeffrey (MIT License).
# https://github.com/chjj/cmake-node

if(DEFINED __NODEJS_CMAKE__)
  return()
endif()

set(__NODEJS_CMAKE__ 1)
set(CMAKE_BUILDING_NODE_EXTENSION 1)

if(NOT CMAKE_SYSTEM_NAME)
  message(FATAL_ERROR "System is not configured!")
endif()

if(WIN32)
  set(NODE_BIN "node.exe" CACHE STRING "Node.js executable name")
  set(NODE_LIB "node.lib" CACHE FILEPATH "Path to node.lib")
elseif(CMAKE_SYSTEM_NAME MATCHES "^AIX$|^OS400$")
  set(NODE_EXP "node.exp" CACHE FILEPATH "Path to node.exp")
elseif(CMAKE_SYSTEM_NAME STREQUAL "OS390")
  set(NODE_EXP "libnode.x" CACHE FILEPATH "Path to libnode.x")
endif()

set(_node_dir "${CMAKE_CURRENT_LIST_DIR}")
set(_node_sources)
set(_node_defines)
set(_node_cflags)
set(_node_includes)
set(_node_ldflags)
set(_node_libs)

list(APPEND _node_defines BUILDING_NODE_EXTENSION)
list(APPEND _node_defines BUILDING_WITH_CMAKE_NODE)
list(APPEND _node_includes "${_node_dir}/../include/node")

if(WIN32)
  if(MINGW)
    # Ensure we are redistributable on windows.
    list(APPEND _node_ldflags -static-libgcc)
  else()
    if(CMAKE_CXX_COMPILER_LOADED AND NOT CMAKE_C_COMPILER_LOADED)
      list(APPEND _node_sources "${_node_dir}/../src/win_delay_load_hook.cc")
    else()
      list(APPEND _node_sources "${_node_dir}/../src/win_delay_load_hook.c")
    endif()
    list(APPEND _node_defines NODE_HOST_BINARY="${NODE_BIN}")
    list(APPEND _node_ldflags /delayload:${NODE_BIN})
    list(APPEND _node_ldflags /ignore:4199)
  endif()
  list(APPEND _node_libs ${NODE_LIB})
endif()

if(APPLE)
  list(APPEND _node_ldflags -undefined dynamic_lookup)
endif()

if(CMAKE_SYSTEM_NAME MATCHES "^AIX$|^OS400$")
  list(APPEND _node_cflags -maix64)
  list(APPEND _node_ldflags -Wl,-bbigtoc)
  list(APPEND _node_ldflags -maix64)
  if(CMAKE_SYSTEM_NAME STREQUAL "OS400")
    list(APPEND _node_ldflags -Wl,-brtl)
  endif()
  list(APPEND _node_ldflags -Wl,-bimport:${NODE_EXP})
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "OS390")
  list(APPEND _node_defines _ALL_SOURCE)
  list(APPEND _node_defines _UNIX03_SOURCE)
  list(APPEND _node_cflags -q64)
  list(APPEND _node_cflags -Wc,DLL)
  list(APPEND _node_cflags -qlonglong)
  list(APPEND _node_cflags -qenum=int)
  list(APPEND _node_cflags -qxclang=-fexec-charset=ISO8859-1)
  list(APPEND _node_ldflags -q64)
  list(APPEND _node_libs ${NODE_EXP})
endif()

if(WASI)
  list(APPEND _node_ldflags -mexec-model=reactor)
  list(APPEND _node_ldflags -Wl,--allow-undefined)
  list(APPEND _node_ldflags -Wl,--export-dynamic)
  list(APPEND _node_ldflags -Wl,--export=malloc)
  list(APPEND _node_ldflags -Wl,--export=free)
endif()

function(add_node_library target)
  add_library(${ARGV})

  target_compile_definitions(${target} PRIVATE ${_node_defines})
  target_compile_options(${target} PRIVATE ${_node_cflags})
  target_include_directories(${target} PRIVATE ${_node_includes})

  set_property(TARGET ${target} PROPERTY POSITION_INDEPENDENT_CODE ON)

  if(MINGW)
    get_property(_type TARGET ${target} PROPERTY TYPE)

    if(_type MATCHES "^SHARED_LIBRARY$|^MODULE_LIBRARY$")
      if(COMMAND target_link_options)
        target_link_options(${target} PRIVATE -static-libgcc)
      else()
        set_property(TARGET ${target} PROPERTY LINK_FLAGS "-static-libgcc")
      endif()

      set_target_properties(${target} PROPERTIES PREFIX ""
                                                 SUFFIX ".dll"
                                                 IMPORT_PREFIX ""
                                                 IMPORT_SUFFIX ".lib")
    elseif(_type STREQUAL "STATIC_LIBRARY")
      set_target_properties(${target} PROPERTIES PREFIX ""
                                                 SUFFIX ".lib")
    endif()
  endif()
endfunction()

function(add_node_module target)
  if(WASI)
    add_executable(${target} ${ARGN} ${_node_sources})
  else()
    add_library(${target} SHARED ${ARGN} ${_node_sources})
  endif()

  target_compile_definitions(${target} PRIVATE ${_node_defines}
                             NODE_GYP_MODULE_NAME=${target})
  target_compile_options(${target} PRIVATE ${_node_cflags})
  target_include_directories(${target} PRIVATE ${_node_includes})

  if(COMMAND target_link_options)
    target_link_options(${target} PRIVATE ${_node_ldflags})
  else()
    set(_ldflags "")

    foreach(_ldflag ${_node_ldflags})
      if(_ldflag MATCHES " ")
        string(REPLACE "'" "\\'" _ldflag "${_ldflag}")
        set(_ldflag "'${_ldflag}'")
      endif()

      if(_ldflags)
        set(_ldflags "${_ldflags} ${_ldflag}")
      else()
        set(_ldflags "${_ldflag}")
      endif()
    endforeach()

    if(_ldflags)
      set_property(TARGET ${target} PROPERTY LINK_FLAGS "${_ldflags}")
    endif()
  endif()

  target_link_libraries(${target} PRIVATE ${_node_libs})

  set_target_properties(${target} PROPERTIES PREFIX ""
                                             SUFFIX ".node"
                                             MACOSX_RPATH ON
                                             POSITION_INDEPENDENT_CODE ON
                                             C_VISIBILITY_PRESET hidden
                                             CXX_VISIBILITY_PRESET hidden)

  if(MINGW)
    set_target_properties(${target} PROPERTIES IMPORT_PREFIX ""
                                               IMPORT_SUFFIX ".lib")
  endif()

  if(WASI)
    set_target_properties(${target} PROPERTIES SUFFIX ".wasm"
                                               C_VISIBILITY_PRESET default
                                               CXX_VISIBILITY_PRESET default)
  endif()
endfunction()
