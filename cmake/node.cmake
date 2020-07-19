# node.cmake - cmake wrapper for node.js
# Copyright (c) 2020, Christopher Jeffrey (MIT License).
# https://github.com/chjj/build

if(DEFINED CMAKE_NODEJS_)
  return()
else()
  set(CMAKE_NODEJS_ 1)
endif()

if(WIN32)
  option(NODE_BIN "Path to node.exe" "node.exe")
  option(NODE_LIB "Path to node.lib" "node.lib")
endif()

set(_node_dir "${CMAKE_CURRENT_LIST_DIR}")
set(_node_sources)
set(_node_defines)
set(_node_globals)
set(_node_cflags)
set(_node_ldflags)
set(_node_libs)

list(APPEND _node_defines BUILDING_NODE_EXTENSION)

if(APPLE)
  list(APPEND _node_ldflags -undefined dynamic_lookup)
  list(APPEND _node_globals _DARWIN_USE_64_BIT_INODE=1)
endif()

if(NOT WIN32)
  list(APPEND _node_globals _LARGEFILE_SOURCE)
  list(APPEND _node_globals _FILE_OFFSET_BITS=64)
endif()

if(WIN32)
  # Explanation: It's impossible to build a DLL
  # with unresolved symbols. As a result, when
  # node.js is built, a .lib file is created,
  # exposing all the necessary symbols.
  #
  # When building an addon, MSVS must link to
  # this .lib file. Unfortunately, this .lib
  # file is specific to both the node version
  # and the architecture.
  #
  # Further reading: http://edll.sourceforge.net/
  #
  # Node.js uses the ".def & .a" solution.
  if (NODE_LIB AND EXISTS "${NODE_LIB}")
    set(_node_lib_file "${NODE_LIB}")
  else()
    set(_node_dist "https://nodejs.org/dist")

    execute_process(COMMAND "${NODE_BIN}" "-p" "process.version"
                    RESULT_VARIABLE _node_ver OUTPUT_QUIET)
    execute_process(COMMAND "${NODE_BIN}" "-p" "process.arch"
                    RESULT_VARIABLE _node_arch OUTPUT_QUIET)

    string(REGEX MATCH "^v[0-9]+.[0-9]+.[0-9]+" _node_ver "${_node_ver}")

    set(_node_lib_url "${_node_dist}/${_node_ver}/win-${_node_arch}/node.lib")
    set(_node_lib_file "node-${_node_ver}-${_node_arch}.lib")

    if(NOT EXISTS "${_node_lib_file}")
      file(DOWNLOAD "${_node_lib_url}" "${_node_lib_file}")
    endif()
  endif()

  get_filename_component(_node_exe "${NODE_BIN}" NAME)

  # Windows requires insane hacks to work properly.
  list(APPEND _node_libs ${_node_lib_file})
  list(APPEND _node_defines HOST_BINARY="${_node_exe}")
  list(APPEND _node_sources "${_node_dir}/src/win_delay_load_hook.c")
  list(APPEND _node_ldflags /delayload:${_node_exe})
  list(APPEND _node_ldflags /ignore:4199)
endif()

foreach(def IN LISTS _node_globals)
  if(MSVC)
    list(APPEND _node_cflags "/D${def}")
  else()
    list(APPEND _node_cflags "-D${def}")
  endif()
endforeach()

string(REPLACE ";" " " _node_cflags "${_node_cflags}")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_node_cflags}" CACHE STRING)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_node_cflags}" CACHE STRING)

function(add_node_module target)
  set(sources ${ARGV})
  list(REMOVE_AT sources 0)
  add_library(${target} SHARED ${sources} ${_node_sources})
  target_compile_definitions(${target} PRIVATE ${_node_defines}
                             NODE_GYP_MODULE_NAME=${target})
  target_include_directories(${target} PRIVATE "${_node_dir}/include/node")
  target_link_options(${target} PRIVATE ${_node_ldflags})
  target_link_libraries(${target} PRIVATE ${_node_libs})
  set_property(TARGET ${target} PROPERTY PREFIX "")
  set_property(TARGET ${target} PROPERTY SUFFIX ".node")
endfunction()
