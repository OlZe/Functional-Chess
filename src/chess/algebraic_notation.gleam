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
import gleam/option.{type Option, None, Some}
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
/// `before_state` and `after_state` are the GameStates immediatly before and immediatly after executing the move.
/// (This is done for performance reasons.)
/// 
/// Errors if the game of `before_state` is already over, or the provided `move` is moving a non-existing/opposing figure.
/// 
/// Warning: For performance reasons, this does not perform proper legality checking of the `move`, `before_state` and `after_state`,
/// meaning that if this function is misused, it may return a non-Error.
pub fn describe(
  before_state before_state: c.GameState,
  move move: c.Move,
  after_state after_state: c.GameState,
) -> Result(String, DescribeError) {
  let all_moves =
    c.get_all_moves(game: before_state)
    |> result.map_error(fn(_) { GameAlreadyOver })
  use all_moves <- result.try(all_moves)

  let is_capture = {
    let figures_after = c.get_amount_figures(after_state)
    let figures_before = c.get_amount_figures(before_state)
    figures_before > figures_after
  }

  let description = case move {
    c.ShortCastle -> Ok("O-O")
    c.LongCastle -> Ok("O-O-O")
    c.StdMove(from:, to:)
    | c.EnPassant(from:, to:)
    | c.PawnPromotion(from:, to:, new_figure: _) -> {
      let moving_figure =
        c.get_figure(before_state, from)
        |> option.to_result(ProvidedMoveIsIllegal)
      use #(moving_figure, _) <- result.try(moving_figure)

      let description =
        describe_figure(moving_figure)
        <> describe_disambiguation(
          before_state:,
          all_moves:,
          from:,
          to:,
          is_capture:,
        )
        <> describe_takes(is_capture)
        <> describe_destination(to)
      Ok(description)
    }
  }

  use description <- result.try(description)

  let promotion = {
    let new_figure = case move {
      c.PawnPromotion(new_figure:, ..) -> Some(new_figure)
      _ -> None
    }
    describe_promotion(new_figure)
  }

  let description = description <> promotion

  let checks = {
    let is_checking_king = case c.get_status(after_state) {
      c.GameEnded(c.Victory(by: c.Checkmated, winner: _)) -> Checkmating
      _ -> {
        let is_checking = after_state |> c.is_in_check()
        case is_checking {
          True -> Checking
          False -> NotChecking
        }
      }
    }
    describe_checks(is_checking_king)
  }

  let description = description <> checks

  Ok(description)
}

type Checking {
  Checkmating
  Checking
  NotChecking
}

fn describe_checks(is_checking: Checking) -> String {
  case is_checking {
    NotChecking -> ""
    Checking -> "+"
    Checkmating -> "#"
  }
}

fn describe_promotion(to to: Option(c.Figure)) -> String {
  case to {
    None -> ""
    Some(to) -> "=" <> describe_figure(to)
  }
}

fn describe_destination(destination destination: c.Coordinate) -> String {
  destination |> coord_to_string()
}

fn describe_takes(is_takes: Bool) -> String {
  case is_takes {
    False -> ""
    True -> "x"
  }
}

fn describe_disambiguation(
  before_state game: c.GameState,
  all_moves all_moves: dict.Dict(c.Coordinate, set.Set(c.AvailableMove)),
  from from: c.Coordinate,
  to to: c.Coordinate,
  is_capture is_capture: Bool,
) -> String {
  let assert Some(figure) = c.get_figure(game, from)

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
          let other_figure = c.get_figure(game, coord)
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
              c.StdMoveAvailable(move_to) -> move_to == to
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

fn describe_figure(figure figure: c.Figure) -> String {
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
