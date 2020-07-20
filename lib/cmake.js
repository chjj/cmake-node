/*!
 * cmake.js - node.js toolchain for cmake
 * Copyright (c) 2020, Christopher Jeffrey (MIT License).
 * https://github.com/chjj/cmake-node
 */

'use strict';

const path = require('path');

/*
 * Constants
 */

exports.bin = path.resolve(__dirname, '..', 'bin', 'cmake-node');
exports.cmake = path.resolve(__dirname, '..', 'cmake', 'NodeJS.cmake');
exports.napi = path.resolve(__dirname, '..', 'include', 'node');
