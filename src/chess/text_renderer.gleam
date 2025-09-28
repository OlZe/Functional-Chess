//// This module provides basic functionality to render a game state to a String.
//// 
//// This module does *not* provide a user facing UI or even any user interaction. It's merely used for testing/debugging purposes.
//// 
//// However, feel free to use the provided functions in here to experiment with this library before
//// building your own UI experience.
//// 
//// Example starting position:
//// 
//// ```plain
////       White's turn    
////   ┌─────────────────┐
//// 8 │ ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜ │
//// 7 │ ♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟ │
//// 6 │ · · · · · · · · │
//// 5 │ · · · · · · · · │
//// 4 │ · · · · · · · · │
//// 3 │ · · · · · · · · │
//// 2 │ ♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙ │
//// 1 │ ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖ │
////   └─────────────────┘
////     a b c d e f g h  
//// ```
//// 
//// > 🐞 This example will appear be misaligned, if it's not rendered with a monospace font.

import chess as c
import gleam/dict
import gleam/list
import gleam/option.{type Option, Some}
import gleam/set
import gleam/string
import gleam_community/ansi

/// Like `render` but also highlights a set of available moves on the board.
/// 
/// Uses ANSI codes to make `selected_figure` and the background of its `moves` yellow.
/// 
/// Do not use this if you don't want ANSI codes in the output string.
pub fn render_with_moves(
  game game: c.Game,
  selected_figure selected_figure: c.Coordinate,
  moves moves: set.Set(c.AvailableMove),
) -> String {
  let render_square_with_moves_fn = fn(board: c.Board, coord: c.Coordinate) -> String {
    let square = render_square_plain(board:, coord:)

    // Highlight selected_figure
    let square = case selected_figure == coord {
      False -> square
      True -> ansi.yellow(square)
    }

    // Highlight available move
    let is_move =
      moves
      |> set.map(fn(move) { move.to })
      |> set.contains(coord)

    let square = case is_move {
      False -> square
      True -> ansi.bg_yellow(square)
    }

    square
  }

  let status = render_status(game.status)
  let board = render_board(game.board, render_square_with_moves_fn)

  status <> "\n" <> board
}

/// Renders the `game` into a String without using any ANSI codes.
/// 
/// See `render_with_moves` if you want to highlight available moves as well.
pub fn render(game game: c.Game) -> String {
  let status = render_status(game.status)
  let board = render_board(game.board, render_square_plain)

  status <> "\n" <> board
}

fn render_board(
  board board: c.Board,
  render_square_fn render_square: fn(c.Board, c.Coordinate) -> String,
) -> String {
  let content =
    [c.Row8, c.Row7, c.Row6, c.Row5, c.Row4, c.Row3, c.Row2, c.Row1]
    |> list.map(render_row(board, _, render_square))
    |> string.join("\n")

  let prefix = "  ┌─────────────────┐"
  let suffix = "  └─────────────────┘\n    a b c d e f g h  "

  prefix <> "\n" <> content <> "\n" <> suffix
}

fn render_row(
  board board: c.Board,
  row row: c.Row,
  render_square_fn render_square: fn(c.Board, c.Coordinate) -> String,
) -> String {
  let row_num = case row {
    c.Row1 -> "1"
    c.Row2 -> "2"
    c.Row3 -> "3"
    c.Row4 -> "4"
    c.Row5 -> "5"
    c.Row6 -> "6"
    c.Row7 -> "7"
    c.Row8 -> "8"
  }

  let content =
    [c.FileA, c.FileB, c.FileC, c.FileD, c.FileE, c.FileF, c.FileG, c.FileH]
    |> list.map(c.Coordinate(_, row))
    |> list.map(render_square(board, _))
    |> string.join(" ")

  let prefix = row_num <> " │ "
  let suffix = " │"

  prefix <> content <> suffix
}

/// Renders a square into a basic unicode-char
fn render_square_plain(
  board board: c.Board,
  coord coord: c.Coordinate,
) -> String {
  let square = board_get(board:, coord:)
  case square {
    option.None -> "·"
    option.Some(figure) ->
      case figure {
        #(c.Pawn, c.White) -> "♙"
        #(c.Rook, c.White) -> "♖"
        #(c.Knight, c.White) -> "♘"
        #(c.Bishop, c.White) -> "♗"
        #(c.Queen, c.White) -> "♕"
        #(c.King, c.White) -> "♔"
        #(c.Pawn, c.Black) -> "♟"
        #(c.Rook, c.Black) -> "♜"
        #(c.Knight, c.Black) -> "♞"
        #(c.Bishop, c.Black) -> "♝"
        #(c.Queen, c.Black) -> "♛"
        #(c.King, c.Black) -> "♚"
      }
  }
}

fn render_status(status status: c.GameStatus) -> String {
  case status {
    c.GameOngoing(c.White) -> "     White's turn"
    c.GameOngoing(c.Black) -> "     Black's turn"
    c.GameEnded(c.Victory(winner: c.White, by: c.Checkmate)) ->
      "  Checkmate by White"
    c.GameEnded(c.Victory(winner: c.Black, by: c.Checkmate)) ->
      "  Checkmate by Black"
    c.GameEnded(c.Victory(winner: c.White, by: c.Forfeit)) ->
      "   Forfeit by Black"
    c.GameEnded(c.Victory(winner: c.Black, by: c.Forfeit)) ->
      "   Forfeit by White"
    c.GameEnded(c.Draw(by: c.MutualAgreement)) -> "     Mutual Draw"
    c.GameEnded(c.Draw(by: c.Stalemate)) -> "      Stalemate"
    c.GameEnded(c.Draw(by: c.InsufficientMaterial)) -> "InsufficientMaterial"
    c.GameEnded(c.Draw(by: c.DeadPosition)) -> "    Dead Position"
    c.GameEnded(c.Draw(by: c.ThreefoldRepition)) -> " Threefold Repetition"
  }
}

/// Get a figure on `coord` from a `board`
fn board_get(
  board board: c.Board,
  coord coord: c.Coordinate,
) -> Option(#(c.Figure, c.Player)) {
  case board {
    c.Board(white_king, _, _) if white_king == coord -> Some(#(c.King, c.White))
    c.Board(_, black_king, _) if black_king == coord -> Some(#(c.King, c.Black))
    c.Board(_, _, other_figures) ->
      other_figures |> dict.get(coord) |> option.from_result()
  }
}
