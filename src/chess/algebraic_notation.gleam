//// This module provides functionality to generate [Standard Algrebaic Notation](https://www.chess.com/terms/chess-notation) for chess moves.
//// 
//// Here are some examples of SAN:
//// 
//// `e4`     "Pawn to E4"
//// 
//// `Qxd7`   "Queen takes D7"
//// 
//// `exd3+`  "E-Pawn takes D3, check"
//// 
//// `Nac3`   "Knight A2 to C3"
//// 
//// ## Formatting rules
//// 
//// The formatting is generated as follows:
//// 
//// `(<standard-move> | 'O-O' | 'O-O-O')<checks>`
//// 
//// where:
//// 
//// - `'O-O'` refers to a short castle
//// - `'O-O-O'` refers to a long castle
//// - `<checks>` is:
////   - `'#'` if this move checkmates the enemy king
////   - `'+'` if this move checks the enemy king
////   - otherwise empty
//// 
//// `<standard-move>` is defined as:
//// 
//// `<figure><disambiguation><takes><destination><promotion>`
//// 
//// where: (cases are processed from top to bottom)
//// 
//// - `<figure>` is:
////   - empty for pawn
////   - `'N'` for knight
////   - `'B'` for bishop
////   - `'R'` for rook
////   - `'Q'` for queen
////   - `'K'` for king
//// - `<disambiguation>` is:
////   - `<file>` if the moved figure is a pawn and it captures an enemy figure
////   - empty if moved figure is unambigous
////   - `<file>` if moved figure is ambigous and the ambigous figures are on different files
////   - `<row>` if moved figure is ambigous and the ambigous figures are on different rows
////   - `<square>` otherwise
//// - `<takes>` is:
////   - `'x'` if a capture takes place
////   - empty otherwise
//// - `<destination>` is the `<square>` the figure is moved to
//// - `<promotion>` is:
////   - `'='<figure>` if a pawn is promoting to `<figure>`
////   - empty otherwise
//// 

import chess as c
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import gleam/set

/// An error returned by `describe`.
pub type DescribeError {
  /// Tried to describe a move, which belongs to a game that is already over.
  GameAlreadyOver
  /// Tried to describe a move, which is not legal.
  ProvidedMoveIsIllegal
}

/// Describes the given `move` using Standard Algebraic Notation.
/// 
/// See the module description for the formatting rules and examples.
/// 
/// `game` is the state *before* executing the move.
/// 
/// Errors if the game is already over, or the provided `move` not legal.
pub fn describe(
  game game: c.GameState,
  move move: c.FigureMove,
) -> Result(String, DescribeError) {
  // Make move and handle errors
  let after_state =
    c.player_move(game:, move:)
    |> result.map_error(fn(e) {
      case e {
        c.PlayerMoveIsIllegal -> ProvidedMoveIsIllegal
        c.PlayerMoveWhileGameAlreadyOver -> GameAlreadyOver
        c.PlayerMoveWithInvalidFigure(reason: _) -> ProvidedMoveIsIllegal
      }
    })

  use after_state <- result.try(after_state)

  let all_moves =
    c.get_all_moves(game:)
    // panic is ok here, as it's already verified that the game is not over.
    |> result.map_error(fn(_) { panic })

  use all_moves <- result.try(all_moves)

  describe_internal(game:, after_game: after_state, all_moves:, move:)
  |> Ok
}

fn describe_internal(
  game game: c.GameState,
  after_game after_game: c.GameState,
  all_moves all_moves: dict.Dict(c.Coordinate, set.Set(c.AvailableFigureMove)),
  move move: c.FigureMove,
) -> String {
  let is_capture = {
    let figures_after = c.get_board(after_game).other_figures |> dict.size()
    let figures_before = c.get_board(game).other_figures |> dict.size()
    figures_before > figures_after
  }

  let description = case move {
    c.ShortCastle -> "O-O"
    c.LongCastle -> "O-O-O"
    c.StandardFigureMove(from:, to:) -> {
      let assert Some(#(moving_figure, _)) =
        game |> c.get_board() |> board_get(from)
      figure(moving_figure)
      <> disambiguation(game:, all_moves:, from:, to:, is_capture:)
      <> takes(is_capture)
      <> destination(to)
    }
    c.EnPassant(from:, to:) -> {
      let assert Some(#(moving_figure, _)) =
        game |> c.get_board() |> board_get(from)
      figure(moving_figure)
      <> disambiguation(game:, all_moves:, from:, to:, is_capture:)
      <> takes(is_capture)
      <> destination(to)
    }
    c.PawnPromotion(from:, to:, new_figure:) -> {
      let assert Some(#(moving_figure, _)) =
        game |> c.get_board() |> board_get(from)
      figure(moving_figure)
      <> disambiguation(game:, all_moves:, from:, to:, is_capture:)
      <> takes(is_capture)
      <> destination(to)
      <> promotion(to: new_figure)
    }
  }

  let is_checking = case c.get_status(after_game) {
    c.GameEnded(c.Victory(by: c.Checkmated, winner: _)) -> Checkmating
    _ -> {
      let is_checking = after_game |> c.is_in_check()
      case is_checking {
        True -> Checking
        False -> NotChecking
      }
    }
  }

  description <> checks(is_checking)
}

type Checking {
  Checkmating
  Checking
  NotChecking
}

fn checks(is_checking: Checking) -> String {
  case is_checking {
    NotChecking -> ""
    Checking -> "+"
    Checkmating -> "#"
  }
}

fn promotion(to to: c.Figure) -> String {
  "=" <> figure(to)
}

fn destination(destination destination: c.Coordinate) -> String {
  destination |> coord_to_string()
}

fn takes(is_takes: Bool) -> String {
  case is_takes {
    False -> ""
    True -> "x"
  }
}

fn disambiguation(
  game game: c.GameState,
  all_moves all_moves: dict.Dict(c.Coordinate, set.Set(c.AvailableFigureMove)),
  from from: c.Coordinate,
  to to: c.Coordinate,
  is_capture is_capture: Bool,
) -> String {
  let assert Some(figure) = game |> c.get_board() |> board_get(from)

  case figure {
    #(c.Pawn, _) if is_capture -> file_to_string(from.file)
    #(figure, player) -> {
      // Get the player's same figures which could cause ambiguation
      let same_figures =
        all_moves
        |> dict.keys()
        // Filter for same figures on different positions
        |> list.filter(fn(coord) {
          use <- bool.guard(when: coord == from, return: False)
          let other_figure = game |> c.get_board() |> board_get(coord)
          other_figure == Some(#(figure, player))
        })

      // Get the same_figures which have a move which go to the same destination
      let ambigous_figures =
        same_figures
        |> list.filter(fn(same_figure) {
          // Check if same_figure has a move which goes to `to`
          all_moves
          |> dict.get(same_figure)
          |> result.lazy_unwrap(fn() { panic })
          |> set.to_list()
          |> list.any(fn(move_of_ambig_figure) {
            case move_of_ambig_figure {
              c.LongCastleAvailable -> False
              c.ShortCastleAvailable -> False
              c.EnPassantAvailable(move_to) -> move_to == to
              c.PawnPromotionAvailable(move_to) -> move_to == to
              c.StandardFigureMoveAvailable(move_to) -> move_to == to
            }
          })
        })

      // If no ambigous figures are found, then return empty, as per definition
      use <- bool.guard(when: list.is_empty(ambigous_figures), return: "")

      // If they're all on a different file, then disambiguate by file
      let are_different_files =
        ambigous_figures
        |> list.all(fn(other_coord) { other_coord.file != from.file })

      use <- bool.guard(
        when: are_different_files,
        return: from.file |> file_to_string(),
      )

      // If they're all on a different row, then disambiguate by row
      let are_different_rows =
        ambigous_figures
        |> list.all(fn(other_coord) { other_coord.row != from.row })

      use <- bool.guard(
        when: are_different_rows,
        return: from.row |> row_to_string(),
      )

      // Otherwise disambiguate by the `from` coordinate
      from |> coord_to_string()
    }
  }
}

fn figure(figure figure: c.Figure) -> String {
  case figure {
    c.Pawn -> ""
    c.Bishop -> "B"
    c.King -> "K"
    c.Knight -> "N"
    c.Queen -> "Q"
    c.Rook -> "R"
  }
}

fn coord_to_string(coord coord: c.Coordinate) -> String {
  let file = file_to_string(coord.file)
  let row = row_to_string(coord.row)
  file <> row
}

fn row_to_string(row row: c.Row) -> String {
  case row {
    c.Row1 -> "1"
    c.Row2 -> "2"
    c.Row3 -> "3"
    c.Row4 -> "4"
    c.Row5 -> "5"
    c.Row6 -> "6"
    c.Row7 -> "7"
    c.Row8 -> "8"
  }
}

fn file_to_string(file file: c.File) -> String {
  case file {
    c.FileA -> "a"
    c.FileB -> "b"
    c.FileC -> "c"
    c.FileD -> "d"
    c.FileE -> "e"
    c.FileF -> "f"
    c.FileG -> "g"
    c.FileH -> "h"
  }
}

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
