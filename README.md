# A chess game written in Gleam

[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://olze.github.io/Functional-Chess/chess.html)
[![GitHub](https://img.shields.io/badge/GitHub-source-blue)](https://github.com/OlZe/Functional-Chess)

> ⚠️🛠️ This project is a work in progress! As of now there are no releases of any kind. See the feature list below.

This is the game of chess implemented in [Gleam](https://gleam.run/) using a purely functional programming paradigm. Functionality is ensured through unit tests.

This project has no UI or I/O. This is purely just a library to be used by other code to play chess through the public facing types/function APIs. However there is a basic text renderer in the submodule [`chess/text_renderer`](https://olze.github.io/Functional-Chess/chess/text_renderer.html) to let you experiment with this library before building your own UI.

The API is minimal and easy to use. Refer to the [online documentation](https://olze.github.io/Functional-Chess/chess.html).

## Example Usage

This example showcases Gleam code, though the project may be used with any Erlang or JavaScript runtime through Gleam's toolchain.

```gleam
import chess
import chess/coordinates as coord

pub fn main() {
  // Create a new game in standard chess starting position
  let game = chess.new_game()

  echo game.status
  // => WaitingOnNextMove(White)

  // White gets all legal moves of pawn on E2
  let _ = echo chess.get_legal_moves(game, coord.e2)
  // => [StandardMoveAvailable(E3), StandardMoveAvailable(E4)]

  // White moves pawn E2 to E4
  let move = chess.StandardMove(from: coord.e2, to: coord.e4)
  let assert Ok(game) = chess.player_move(game, move)

  // Now it's black's turn
  echo game.status
  // => WaitingOnNextMove(Black)

  // Black tries to illegally move king to E5
  let illegal_move = chess.StandardMove(from: coord.e8, to: coord.e5)
  echo chess.player_move(game, illegal_move)
  // => Error(PlayerMoveIsIllegal)
}
```


## Features

> 🛠️ Features marked incomplete are still being worked on.

- [x] Descriptive Error returns
- [x] Start in standard chess starting position
- [x] Request all legal moves of a given figure
- [ ] History of past board positions and moves
- [ ] Move the figures according to professional chess rules
  - [x] Regular figure movement and capture
  - [x] Prohibit moves that leave the king in check
  - [x] Pawn Promotion
  - [ ] Castling
  - [ ] En passant
- [x] Win/Lose the game
  - [x] by checkmate
  - [x] by player forfeit
- [ ] Draw the game
  - [x] by mutual player agreement
  - [x] by [stalemate](https://www.chess.com/terms/draw-chess#stalemate)
  - [x] by [insufficient material](https://www.chess.com/terms/draw-chess#dead-position)
  - [ ] by a [dead position](https://www.chess.com/terms/draw-chess#dead-position)
  - [ ] by [threefold repititon](https://www.chess.com/terms/draw-chess#threefold-repetition)
  - [ ] by the [50 move rule](https://www.chess.com/terms/draw-chess#fifty-move-rule)


## GitHub Workflows

Unit tests `gleam test` are automatically executed on push.

The [online documentation](https://olze.github.io/Functional-Chess) is built and published automatically on push.

## Development

To run tests locally:

```sh
gleam test
```

To build the html docs locally:

```sh
gleam docs build
open build/dev/docs/chess/index.html
```
