/*!
 * wasi.js - wasi runner for cmake-node
 * Copyright (c) 2020, Christopher Jeffrey (MIT License).
 * https://github.com/chjj/cmake-node
 */

'use strict';

const fs = require('fs');
const {WASI} = require('wasi');

if (process.argv.length < 3) {
  console.error('Usage: $ node wasi.js [file] [args]');
  process.exit(1);
}

const code = fs.readFileSync(process.argv[2]);
const module_ = new WebAssembly.Module(code);

const wasi = new WASI({
  args: process.argv.slice(2),
  env: process.env
});

const instance = new WebAssembly.Instance(module_, {
  wasi_snapshot_preview1: wasi.wasiImport
});

wasi.start(instance);
