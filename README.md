# A chess game written in Gleam

> ⚠️🛠️ This project is a work in progress! As of now there are no releases of any kind.

This is the game of chess implemented in [Gleam](https://gleam.run/) using a purely functional programming paradigm. Functionality is ensured using unit tests.

This project has no UI or I/O. This is purely just a library to be used by other code to play chess through the public facing types/function APIs.

The API is minimal and easy to use. Refer to the [online documentation](https://olze.github.io/Functional-Chess/).

## Features

Features marked incomplete are still being worked on.

- [x] Start in standard starting position
- [x] Move the figures just like in a real game
- [x] Request all legal moves of a given figure
- [x] Prohibit moves that leave the king in check
- [x] Descriptive Error returns
- [x] Identify game-over conditions (Checkmate, Stalemate)
- [x] Player can forfeit
- [ ] Pawn promotion
- [ ] Castling
- [ ] En passant

## Example Usage

This example showcases Gleam code, though the project may be used with any Erlang or JavaScript runtime.

```gleam
import chess

pub fn main() {
  // Create a new game in standard chess starting position
  let game = chess.new_game()

  echo game.status
  // => WaitingOnNextMove(White)

  // White gets all legal moves of pawn on E2
  let _ = echo chess.get_legal_moves(game, chess.coord_e2)
  // => [E2->E3, E2->E4]

  // White moves pawn E2 to E4
  let move = chess.StdFigureMove(from: chess.coord_e2, to: chess.coord_e4)
  let assert Ok(game) = chess.player_move(game, move)

  // Now it's black's turn
  echo game.status
  // => WaitingOnNextMove(Black)

  // Black tries to illegally move king to E5
  let illegal_move =
    chess.StdFigureMove(from: chess.coord_e8, to: chess.coord_e5)
  echo chess.player_move(game, illegal_move)
  // => Error(SelectedFigureCantGoThere)
}
```

## GitHub Workflows

Unit tests `gleam test` are automatically executed on push.

The [online documentation](https://olze.github.io/Functional-Chess/) is built and published automatically on push.

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