/*!
 * cmake.js - cmake toolchain for node.js
 * Copyright (c) 2020, Christopher Jeffrey (MIT License).
 * https://github.com/chjj/node-cmk
 */

'use strict';

const path = require('path');

/*
 * Constants
 */

exports.location = path.resolve(__dirname, '..', 'cmake', 'node.cmake');
