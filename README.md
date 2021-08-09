# cmake-node

Node.js build system on top of CMake.

## Features

- No node.js dependencies
- No network IO (no downloading headers or import libraries)
- MinGW support for cross-compiling to Windows
- WASM support (see below for an explanation)

## Todo

- [osxcross] support for cross-compiling to Darwin

## Design

cmake-node provides an include file and an accompanying wrapper for CMake. In
contrast to other projects, it avoids modification of the global state, and
instead exposes just two functions: `add_node_library` and `add_node_module`.

cmake-node is very lightweight and requires no dependencies. This provides a
nice alternative to other node build systems, which pull in half of npm just to
build a project.

The latest NAPI headers are bundled and automatically added to your include
paths. While there is a chance cmake-node could fall behind in updating these
headers, it should not be that severe of a issue as NAPI provides a stable ABI.
Support for other node headers (v8, node, openssl, nan, etc) is intentionally
excluded for this reason.

While cmake-node requires no _node.js_ dependencies, it does require that the
user have certain other dependencies: this includes CMake itself, Visual Studio
on Windows, Xcode on OSX, and Make on unix.

## Example

CMakeLists.txt:

``` cmake
project(my_project LANGUAGES C)

include(NodeJS)

add_node_library(my_library STATIC src/my_lib.c)

add_node_module(my_project src/my_code.c)
target_compile_definitions(my_project PRIVATE FOOBAR=1)
target_link_libraries(my_project PRIVATE my_library)
```

To build:

``` sh
$ cmake-node rebuild
```

To load (CJS):

``` js
const cmake = require('cmake-node');
const binding = cmake.load('my_project', __dirname);
```

To load (ESM):

``` js
import cmake from 'cmake-node';

const binding = cmake.load('my_project', import.meta.url);
```

## Building for production

cmake-node commands accept a `--production` flag which will clean the workspace
for release. This removes all files generated during the build aside from your
resulting `.node` file.

``` sh
$ cmake-node rebuild --production
```

It is recommended to put this in your package.json's `install` script.

## Fallback Mode (for node-gyp)

node-gyp is _the_ build system for node.js. To cope with this unfortunate
reality, and to ease transition away from node-gyp, cmake-node offers a
fallback option for users who are willing to also provide a binding.gyp file.

``` sh
$ cmake-node rebuild --fallback
```

The above command will fall back to node-gyp if CMake is not installed on the
system (with limited support for cmake-node command line flags). cmake-node
accomplishes this by checking for usual global install locations for node-gyp
(this includes checking for npm's bundled node-gyp).

## MinGW Support

cmake-node allows native modules to be cross-compiled for win32 using the mingw
toolchain.

``` sh
$ cmake-node rebuild --mingw --arch=x64
```

The prefixed mingw toolchain must be in your `PATH`.

## WASM Support

A while ago, some node.js contributors had the brilliant idea of [exposing NAPI
to WASM][wasm-napi]. In theory, this means you can cross-compile your NAPI
module to WASM and have it work transparently. Combined with WASI, this means
only minimal (or no) changes need to be made to your code. cmake-node has
experimental support for this.

``` sh
$ cmake-node rebuild --wasm --wasi-sdk=/path/to/wasi-sdk
```

This feature requires wasi-sdk 12 or above as it requires reactor support (i.e.
`-mexec-model=reactor`).

You can find a proof-of-concept WASM NAPI module [here][napi-module] (credit to
@devsnek).

## Usage

```
  Usage: cmake-node [options] [command] -- [cmake args]

  Options:

    -v, --version        output the version number
    -c, --config <type>  build type (default: Release)
    -C, --cmake <path>   path to cmake binary (default: cmake{,.exe})
    -d, --dist <url>     node.js dist url (windows only)
    -r, --root <path>    path to root directory (default: .)
    -l, --location       print location of the include directory
    -f, --fallback       fall back to node-gyp if cmake is not found
    -g, --gyp <path>     path to node-gyp binary (default: node-gyp{,.cmd})
    -p, --production     clean all files except for .node files
    --node-bin <name>    name of node binary (windows only)
    --node-def <name>    path to node.def (windows only)
    --node-lib <path>    path to node.lib (windows only)
    --node-exp <path>    path to node.exp/libnode.x (aix/zos only)
    -M, --mingw          cross-compile for win32 using mingw
    -W, --wasm           cross-compile for wasm using wasi-sdk
    --wasi-sdk <path>    path to wasi-sdk
    -A, --arch <arch>    select mingw arch (x86 or x64)
    -h, --help           output usage information

  Commands:

    install              install necessary files
    list                 list currently installed files
    clear                clear cache
    configure            configure package
    build                build package
    clean                clean root directory
    reconfigure          reconfigure package
    rebuild              rebuild package
    ui                   open ui for package (ccmake/cmake-gui)
```

## Contribution and License Agreement

If you contribute code to this project, you are implicitly allowing your code
to be distributed under the MIT license. You are also implicitly verifying that
all code is your original work. `</legalese>`

## License

- Copyright (c) 2020, Christopher Jeffrey (MIT License).

See LICENSE for more info.

[wasm-napi]: https://github.com/nodejs/abi-stable-node/issues/375
[napi-module]: https://gist.github.com/devsnek/db5499bf774f078e9ebb679680bd2cd1
[osxcross]: https://github.com/tpoechtrager/osxcross
