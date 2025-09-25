# A chess game written in Gleam

[![Package Version](https://img.shields.io/hexpm/v/chess)](https://hex.pm/packages/chess)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/chess/)

This is the game of chess implemented in [Gleam](https://gleam.run/) using a purely functional programming paradigm. Functionality is ensured using unit tests.

This project has no UI or I/O. This is purely just a library to be used by other code to play chess through the public facing types/function APIs.

The API is minimal and easy to use. Refer to the [online documentation](https://olze.github.io/Functional-Chess/).

## Development

To run tests:

```sh
$ gleam test
```

To rebuild docs:

```sh
$ gleam docs build
$ rm -r ./docs
$ cp -r ./build/dev/docs/chess ./docs
```
