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
- [ ] Identify game-over conditions (Checkmate, Stalemate)
- [ ] Player can forfeit
- [ ] Pawn promotion
- [ ] Castling
- [ ] En passant

## Example Usage

This example showcases Gleam code, though the project may be used with any Erlang or JavaScript runtime.

```gleam
import chess
import chess/coordinate as coord

pub fn main() {
  // Create a new game in standard chess starting position
  let game = chess.new_game()

  echo game.state // => WaitingOnNextMove(White)

  // White gets all legal moves of pawn on E2
  let _ = chess.get_legal_moves(game, coord.e2) // => [E3, E4]

  // White moves pawn E2 to E4
  let assert Ok(game) = chess.player_move(game, coord.e2, coord.e4)

  // Now it's black's turn
  echo game.state // => WaitingOnNextMove(Black)

  // Black tries to illegally move king to E5
  // => Error(chess.SelectedFigureCantGoThere)
  echo chess.player_move(game, coord.e8, coord.e5)
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