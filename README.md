# cmake-node

Node.js toolchain for CMake.

## Design

cmake-node provides a node.js toolchain file and an accompanying wrapper for
CMake. In contrast to node-gyp and other projects, it avoids modification of
the global state, and instead exposes just two functions: `add_node_library`
and `add_node_module`.

cmake-node is very lightweight and requires no dependencies. This provides a
nice alternative to other node build systems, which pull in half of npm just to
build a project.

The latest NAPI headers are bundled and automatically added to your include
paths. While there is a chance cmake-node could fall behind in updating these
headers, it should not be that severe of a issue as NAPI provides a stable ABI.
Support for other node headers (v8, node, openssl, nan, etc) is intentionally
excluded for this reason.

Auto-downloading is only necessary for the windows `node.lib` file. Builds on
unix will never do any network IO.

While cmake-node requires no _node.js_ dependencies, it does require that the
user have certain other dependencies: this includes CMake itself, MSVS on
windows, and Make on unix.

## Example

CMakeLists.txt:

``` cmake
include(NodeJS)

project(my_project LANGUAGES C)

add_node_library(my_library STATIC src/my_lib.c)

add_node_module(my_project src/my_code.c)
target_compile_definitions(my_project PRIVATE FOOBAR=1)
target_link_libraries(my_project PRIVATE my_library)
```

To build:

``` bash
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

``` bash
$ cmake-node rebuild --production
```

It is recommended to put this in your package.json's `install` script.

## Fallback Mode (for node-gyp)

node-gyp is _the_ build system for node.js. To cope with this unfortunate
reality, and to ease transition away from node-gyp, cmake-node offers a
fallback option for users who are willing to also provide a binding.gyp file.

``` bash
$ cmake-node rebuild --fallback
```

The above command will fall back to node-gyp if CMake is not installed on the
system (with limited support for cmake-node command line flags). cmake-node
accomplishes this by checking for usual global install locations for node-gyp
(this includes checking for npm's bundled node-gyp).

## Usage

```
  Usage: cmake-node [options] [command] -- [cmake args]

  Options:

    -v, --version        output the version number
    -c, --config <type>  build type (default: Release)
    -C, --cmake <path>   path to cmake binary (default: cmake/cmake.exe)
    -d, --dist <url>     node.js dist url (windows only)
    -r, --root <path>    path to root directory (default: .)
    -l, --location       print location of the include directory
    -f, --fallback       fall back to node-gyp if cmake is not found
    -g, --gyp <path>     path to node-gyp binary (default: node-gyp)
    -p, --production     clean all files except for .node files
    --node-lib <path>    path to node.lib (windows only)
    --node-exp <path>    path to node.exp/libnode.x (aix/zos only)
    -h, --help           output usage information

  Commands:

    install              install necessary files (windows only)
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
