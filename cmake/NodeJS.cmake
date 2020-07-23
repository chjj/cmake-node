# NodeJS.cmake - node.js toolchain for cmake
# Copyright (c) 2020, Christopher Jeffrey (MIT License).
# https://github.com/chjj/cmake-node

if(DEFINED __NODEJS_CMAKE__)
  return()
endif()

set(__NODEJS_CMAKE__ 1)

if(WIN32)
  set(NODE_BIN "node.exe" CACHE STRING "Node.js executable name")
  set(NODE_LIB "node.lib" CACHE FILEPATH "Path to node.lib")
elseif(CMAKE_HOST_SYSTEM_NAME MATCHES "AIX|OS400")
  set(NODE_EXP "node.exp" CACHE FILEPATH "Path to node.exp")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "OS390")
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
list(APPEND _node_includes "${_node_dir}/../include/node")

if(WIN32)
  list(APPEND _node_sources "${_node_dir}/../src/win_delay_load_hook.c")
  list(APPEND _node_defines NODE_HOST_BINARY="${NODE_BIN}")
  list(APPEND _node_ldflags /delayload:${NODE_BIN})
  list(APPEND _node_ldflags /ignore:4199)
  list(APPEND _node_libs "${NODE_LIB}")
endif()

if(APPLE)
  list(APPEND _node_ldflags -undefined dynamic_lookup)
endif()

if(CMAKE_HOST_SYSTEM_NAME MATCHES "AIX|OS400")
  if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "powerpc")
    list(APPEND _node_ldflags -Wl,-bmaxdata:0x60000000/dsa)
  endif()
  if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "powerpc64|ppc64|ppc64le")
    list(APPEND _node_cflags -maix64)
    list(APPEND _node_ldflags -maix64)
  endif()
  list(APPEND _node_ldflags -Wl,-bbigtoc)
  list(APPEND _node_ldflags "-Wl,-bimport:${NODE_EXP}")
endif()

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "OS390")
  list(APPEND _node_cflags -q64)
  list(APPEND _node_cflags -Wc,DLL)
  list(APPEND _node_cflags -qlonglong)
  list(APPEND _node_cflags -qenum=int)
  list(APPEND _node_cflags -qxclang=-fexec-charset=ISO8859-1)
  list(APPEND _node_ldflags -q64)
  list(APPEND _node_ldflags "${NODE_EXP}")
endif()

function(add_node_library target)
  add_library(${ARGV})

  target_compile_definitions(${target} PRIVATE ${_node_defines})
  target_compile_options(${target} PRIVATE ${_node_cflags})
  target_include_directories(${target} PRIVATE ${_node_includes})

  set_property(TARGET ${target} PROPERTY POSITION_INDEPENDENT_CODE ON)
endfunction()

function(add_node_module target)
  set(sources ${ARGV})

  list(REMOVE_AT sources 0)

  add_library(${target} SHARED ${sources} ${_node_sources})

  target_compile_definitions(${target} PRIVATE ${_node_defines}
                             NODE_GYP_MODULE_NAME=${target})
  target_compile_options(${target} PRIVATE ${_node_cflags})
  target_include_directories(${target} PRIVATE ${_node_includes})
  target_link_options(${target} PRIVATE ${_node_ldflags})
  target_link_libraries(${target} PRIVATE ${_node_libs})

  set_property(TARGET ${target} PROPERTY PREFIX "")
  set_property(TARGET ${target} PROPERTY SUFFIX ".node")
  set_property(TARGET ${target} PROPERTY MACOSX_RPATH ON)
  set_property(TARGET ${target} PROPERTY POSITION_INDEPENDENT_CODE ON)
  set_property(TARGET ${target} PROPERTY C_VISIBILITY_PRESET hidden)
  set_property(TARGET ${target} PROPERTY CXX_VISIBILITY_PRESET hidden)
endfunction()
