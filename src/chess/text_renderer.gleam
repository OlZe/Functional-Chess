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
import chess/coordinates
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option.{type Option, Some}
import gleam/set
import gleam/string
import gleam_community/ansi

/// Like `render` but also highlights a set of available moves on the board through ANSI codes.
/// 
/// - `selected_figure` will be colored yellow
/// - standard moves will have a yellow background
/// - pawn promotion moves will have a blue background
/// - en passant moves will have a yellow background
/// - Long/Short castling will have a yellow background at the king's destination square
/// - squares of multiple different moves have a red background to signalize an error
/// 
/// Do not use this if you don't want ANSI codes in the output string.
pub fn render_with_moves(
  game game: c.GameState,
  selected_figure selected_figure: c.Coordinate,
  moves moves: set.Set(c.AvailableFigureMove),
) -> String {
  let board = c.get_board(game)

  let render_square_with_moves_fn = fn(board: c.Board, coord: c.Coordinate) -> String {
    let square = render_square_plain(board:, coord:)

    // Highlight selected_figure
    let square = case selected_figure == coord {
      False -> square
      True -> ansi.yellow(square)
    }

    // Determine background
    let is_destination_standard_move =
      moves
      |> set.contains(c.StandardFigureMoveAvailable(to: coord))

    let is_destination_pawn_promotion =
      moves |> set.contains(c.PawnPromotionAvailable(to: coord))

    let is_destination_en_passant =
      moves |> set.contains(c.EnPassantAvailable(to: coord))

    let is_destination_short_castle = {
      use <- bool.guard(
        when: !set.contains(moves, c.ShortCastleAvailable),
        return: False,
      )

      // Short castle is in the move list.
      // Find owner of king to determine standard castling highlight square.
      case board_get(board, selected_figure) {
        Some(#(c.King, owner)) -> {
          let highlight_square = case owner {
            c.White -> coordinates.g1
            c.Black -> coordinates.g8
          }
          coord == highlight_square
        }
        _ -> False
      }
    }

    let is_destination_long_castle = {
      use <- bool.guard(
        when: !set.contains(moves, c.LongCastleAvailable),
        return: False,
      )

      // Long castle is in the move list.
      // Find owner of king to determine standard castling highlight square.
      case board_get(board, selected_figure) {
        Some(#(c.King, owner)) -> {
          let highlight_square = case owner {
            c.White -> coordinates.c1
            c.Black -> coordinates.c8
          }
          coord == highlight_square
        }
        _ -> False
      }
    }

    // Set highlight
    let square = case
      is_destination_standard_move,
      is_destination_pawn_promotion,
      is_destination_en_passant,
      is_destination_short_castle,
      is_destination_long_castle
    {
      // Highlight standard move
      True, False, False, False, False -> ansi.bg_yellow(square)
      // Highlight pawn promotion
      False, True, False, False, False -> ansi.bg_blue(square)
      // Highlight en passant
      False, False, True, False, False -> ansi.bg_yellow(square)
      // Highlight short castle
      False, False, False, True, False -> ansi.bg_yellow(square)
      // Highlight long castle
      False, False, False, False, True -> ansi.bg_yellow(square)
      // No highlight
      False, False, False, False, False -> square
      // Error
      _, _, _, _, _ -> ansi.bg_bright_red(square)
    }

    square
  }

  let status = render_status(c.get_status(game))
  let board = render_board(board, render_square_with_moves_fn)

  status <> "\n" <> board
}

/// Renders the `game` into a String without using any ANSI codes.
/// 
/// See the module description for an example.
/// 
/// Use `render_with_moves` if you want to highlight available moves as well.
pub fn render(game game: c.GameState) -> String {
  let status = render_status(c.get_status(game))
  let board = render_board(c.get_board(game), render_square_plain)

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
    c.GameEnded(c.Victory(winner: c.White, by: c.Checkmated)) ->
      "  Checkmate by White"
    c.GameEnded(c.Victory(winner: c.Black, by: c.Checkmated)) ->
      "  Checkmate by Black"
    c.GameEnded(c.Victory(winner: c.White, by: c.Forfeited)) ->
      "   Forfeit by Black"
    c.GameEnded(c.Victory(winner: c.Black, by: c.Forfeited)) ->
      "   Forfeit by White"
    c.GameEnded(c.Draw(by: c.MutualAgreement)) -> "     Mutual Draw"
    c.GameEnded(c.Draw(by: c.Stalemated)) -> "      Stalemate"
    c.GameEnded(c.Draw(by: c.InsufficientMaterial)) -> "InsufficientMaterial"
    c.GameEnded(c.Draw(by: c.ThreefoldRepition)) -> " Threefold Repetition"
    c.GameEnded(c.Draw(by: c.FiftyMoveRule)) -> "  Fifty Moves Rule"
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
