# node-cmk

Node.js toolchain for CMake.

## Design

node-cmk differs from other cmake wrappers in that it actually provides a
toolchain file for node.js. It exposes one function, `add_node_module`, which
creates a dynamically loadable library for any given OS.

node-cmk is very lightweight and requires no dependencies. This provides a nice
alternative to node-gyp and cmake-js, which pull in half of npm just to build a
project.

The latest NAPI headers are bundled and automatically added to your include
paths. While there is a chance node-cmk could fall behind in updating these
headers, it should not be that severe of a problem as NAPI provides a stable
ABI. NAN support is intentionally excluded for this reason.

Auto-downloading is only necessary for the windows `node.lib` file. Builds on
unix will never do any network IO.

While node-cmk requires no _node.js_ dependencies, it does require that the
user have certain other dependencies: this includes CMake itself, MSVS on
windows, and Make on unix.

## Example

CMakeLists.txt:

``` cmake
project(my_project LANGUAGES C)
add_node_module(my_project src/my_code.c)
# my_project now behaves like a SHARED target.
target_compile_definitions(my_project PRIVATE FOOBAR=1)
```

To build:

``` bash
$ node-cmk rebuild
```

## Usage

```
  Usage: node-cmk [options] [command] -- [cmake args]

  Options:

    -v, --version        output the version number
    -c, --config <type>  build type (default: Release)
    -C, --cmake <path>   path to cmake binary (default: cmake/cmake.exe)
    -d, --dist <url>     node.js dist url (windows only)
    -r, --root <path>    path to root directory (default: .)
    -l, --location       print location of toolchain file
    -f, --fallback       fall back to node-gyp if cmake is not found
    -g, --gyp            path to node-gyp binary (default: node-gyp)
    -h, --help           output usage information

  Commands:

    install              install necessary files (windows only)
    configure            configure package
    build                build package
    clean                clean root directory
    reconfigure          reconfigure package
    rebuild              rebuild package (default)
```

## Contribution and License Agreement

If you contribute code to this project, you are implicitly allowing your code
to be distributed under the MIT license. You are also implicitly verifying that
all code is your original work. `</legalese>`

## License

- Copyright (c) 2020, Christopher Jeffrey (MIT License).

See LICENSE for more info.
