/*!
 * cmake.js - node.js toolchain for cmake
 * Copyright (c) 2020, Christopher Jeffrey (MIT License).
 * https://github.com/chjj/node-cmk
 */

'use strict';

const path = require('path');

/*
 * Constants
 */

exports.bin = path.resolve(__dirname, '..', 'bin', 'node-cmk');
exports.cmake = path.resolve(__dirname, '..', 'cmake', 'node.cmake');
exports.napi = path.resolve(__dirname, '..', 'include', 'node');
