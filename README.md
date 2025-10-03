# The game of chess written in Gleam

[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://olze.github.io/Functional-Chess/chess.html)
[![GitHub](https://img.shields.io/badge/GitHub-source-blue)](https://github.com/OlZe/Functional-Chess)

> ⚠️🛠️ This project is a work in progress! While all features are complete, significant documentation and API verification efforts are underway!

This is the game of chess implemented as a [Gleam](https://gleam.run/) library using a purely functional programming paradigm.

Great care has been taken to design an easy to use API with strong type safety and descriptive error returns. (Check out the [docs](https://olze.github.io/Functional-Chess/chess.html)!)

This project has no UI or user-facing I/O. There is, however, a basic text renderer to let you experiment before building your own UI! See the chapter *Module Structure* below.

Extensive snapshot-testing is done through [birdie](https://hexdocs.pm/birdie/). See the chapter *Testing* below.

## Features

Play chess acoording to professional chess rules!

- [x] Start
  - [x] in standard starting position 
  - [x] in a verified legal custom position
- [x] Move the figures
  - [x] Request all legal moves of a given figure
  - [x] Prohibit moves that leave the king in check
  - [x] Pawn Promotion
  - [x] En passant
  - [x] Castling
- [x] Win/Lose the game
  - [x] by checkmate
  - [x] by player forfeit
- [x] Draw the game<sup>1</sup>
  - [x] by mutual player agreement
  - [x] by [stalemate](https://www.chess.com/terms/draw-chess#stalemate)
  - [x] by [insufficient material](https://www.chess.com/terms/draw-chess#dead-position)
  - [x] by [threefold repititon](https://www.chess.com/terms/draw-chess#threefold-repetition)
  - [x] by the [50 move rule](https://www.chess.com/terms/draw-chess#fifty-move-rule)
- [x] Track game history
  - [x] Request a history of moves 
  - [x] Go back in time to past board positions/game sates
- [x] Describe moves with [standard algebraic chess notation](https://www.chess.com/terms/chess-notation)

> <sup>1</sup> The rule of achieving a [draw by a dead position](https://www.chess.com/terms/draw-chess#dead-position) is omitted as implementation is quite complex and could have significant impact on performance.
> 
> This should however not impact the actual user experience of playing chess much, as being in a dead position eventually results in a draw through either mutual agreement, threefold repetition or the 50 move rule anyway.
>
> Let me know if you know a nifty algorithm for this!


## Example Usage

This example showcases Gleam code, though the project may be used with any Erlang or JavaScript runtime through Gleam's compiler options.

```gleam
import chess
import chess/coordinates as coord

pub fn main() {
  // Create a new game in standard chess starting position
  let game = chess.new_game()

  echo chess.get_status(game)
  // => GameOngoing(next_player: White)

  // White gets all legal moves of pawn on E2
  echo chess.get_moves(game, coord.e2)
  // => E3 and E4

  // White moves pawn E2 to E4
  let move =
    chess.PlayerMovesFigure(chess.StandardFigureMove(
      from: coord.e2,
      to: coord.e4,
    ))
  let assert Ok(game) = chess.player_move(game, move)

  // Now it's black's turn
  echo chess.get_status(game)
  // => GameOngoing(next_player: Black)

  // Black tries to illegally move king to E5
  let illegal_move =
    chess.PlayerMovesFigure(chess.StandardFigureMove(
      from: coord.e8,
      to: coord.e5,
    ))
  echo chess.player_move(game, illegal_move)
  // => Error(PlayerMoveIsIllegal)

  // Black is frustrated and forfeits the game
  let forfeit_move = chess.PlayerForfeits
  let assert Ok(game) = chess.player_move(game, forfeit_move)
  echo chess.get_status(game)
  // => GameEnded(Victory(winner: White, by: Forfeit))
}
```

## Module Structure

Use the main module [`chess`](https://olze.github.io/Functional-Chess/chess.html) for all the necessary types and functions.

All other submodules are strictly optional, but are here for your convenience:

The submodule [`chess/coordinates`](https://olze.github.io/Functional-Chess/chess/coordinates.html) provides constants to quickly reference all squares on the chess board without constructing those values yourself.

[`chess/algebraic_notation`](https://olze.github.io/Functional-Chess/chess/algebraic_notation.html) allows you to express chess moves in [standard algebraic chess notation](https://www.chess.com/terms/chess-notation), as in `e4`, `Bxc3+` or `exd8=R#`.

Lastly, the module [`chess/text_renderer`](https://olze.github.io/Functional-Chess/chess/text_renderer.html) provides a basic text renderer to express chess positions as a string - with or without ANSI codes to highlight a selected figure and its possible moves. See the example screenshot of in the chapter *Testing* below.


## Development

To compile/change the project yourself install [Gleam](https://gleam.run/) and download the source:

```sh
git clone git@github.com:OlZe/Functional-Chess.git
cd Functional-Chess
gleam test
```

The html docs are [built and deployed automatically](https://github.com/OlZe/Functional-Chess/blob/main/.github/workflows/publish_docs.yml) on push to `main` through GitHub Actions. If you want to build your own html docs locally use:

```sh
gleam docs build --open
```

### Testing

Tests are [automatically evaluated](https://github.com/OlZe/Functional-Chess/blob/main/.github/workflows/test.yml) on push to `main` through GitHub Actions.

[Birdie](https://hexdocs.pm/birdie/) is used to allow for snapshot testing, where test scenarios manipulate the chess board, pretty print it to the console, and require the user to view and confirm that the scenarios were executed correctly. See the example below.

Once a snapshot was confirmed to be correct, it will no longer require confirmation, unless the output changes, in which case birdie will show a diff between the old confirmed output and the new changed output.

When cloning this repo, all snapshots should already be confirmed to be correct.

![An example screenshot of a new snapshot where a chess board is pretty printed to console, with the queen's moves highlighted. The test asks to confirm whether the queen's moves are correct.](https://github.com/OlZe/Functional-Chess/blob/main/birdie_snapshot_example.png?raw=true)


To run the tests locally, use:

```sh
gleam test
```

If there are any snapshots that require confirmation use the following to view them:
```sh
gleam run -m birdie
```
