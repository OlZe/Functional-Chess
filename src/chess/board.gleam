//// This module's responsible for modelling the chess board and providing relevant helper functions.

import chess/coordinate.{type Coordinate} as coord
import gleam/dict
import gleam/option.{type Option, Some}

/// Represents all figure positions on a chess board
pub type Board {
  Board(
    white_king: Coordinate,
    black_king: Coordinate,
    other_figures: dict.Dict(Coordinate, #(Figure, Player)),
  )
}

/// Represents a chess figure.
pub type Figure {
  Pawn
  Knight
  Bishop
  Rook
  Queen
  King
}

/// Represents one of the two chess players.
pub type Player {
  White
  Black
}

/// Creates a new board in the standard chess starting position.
pub fn new() -> Board {
  Board(
    white_king: coord.e1,
    black_king: coord.e8,
    other_figures: dict.from_list([
      #(coord.a1, #(Rook, White)),
      #(coord.b1, #(Knight, White)),
      #(coord.c1, #(Bishop, White)),
      #(coord.d1, #(Queen, White)),
      #(coord.f1, #(Bishop, White)),
      #(coord.g1, #(Knight, White)),
      #(coord.h1, #(Rook, White)),
      #(coord.a2, #(Pawn, White)),
      #(coord.b2, #(Pawn, White)),
      #(coord.c2, #(Pawn, White)),
      #(coord.d2, #(Pawn, White)),
      #(coord.e2, #(Pawn, White)),
      #(coord.f2, #(Pawn, White)),
      #(coord.g2, #(Pawn, White)),
      #(coord.h2, #(Pawn, White)),
      #(coord.a8, #(Rook, Black)),
      #(coord.b8, #(Knight, Black)),
      #(coord.c8, #(Bishop, Black)),
      #(coord.d8, #(Queen, Black)),
      #(coord.f8, #(Bishop, Black)),
      #(coord.g8, #(Knight, Black)),
      #(coord.h8, #(Rook, Black)),
      #(coord.a7, #(Pawn, Black)),
      #(coord.b7, #(Pawn, Black)),
      #(coord.c7, #(Pawn, Black)),
      #(coord.d7, #(Pawn, Black)),
      #(coord.e7, #(Pawn, Black)),
      #(coord.f7, #(Pawn, Black)),
      #(coord.g7, #(Pawn, Black)),
      #(coord.h7, #(Pawn, Black)),
    ]),
  )
}

/// Get a figure on `coord` from a `board`
pub fn get(
  board board: Board,
  coord coord: Coordinate,
) -> Option(#(Figure, Player)) {
  case board {
    Board(white_king, _, _) if white_king == coord -> Some(#(King, White))
    Board(_, black_king, _) if black_king == coord -> Some(#(King, Black))
    Board(_, _, other_figures) ->
      other_figures |> dict.get(coord) |> option.from_result()
  }
}

/// Moves a figure from `from` to `to` on `board`.
/// 
/// Peforms no checking wether `from` and `to` is a legal chess move.
/// 
/// If `from` is pointing to an empty square, then nothing happens
pub fn move(
  board board: Board,
  from from: Coordinate,
  to to: Coordinate,
) -> Board {
  case board {
    Board(white_king:, black_king:, other_figures:) if white_king == from ->
      Board(
        white_king: to,
        black_king:,
        other_figures: dict.delete(other_figures, to),
      )
    Board(white_king:, black_king:, other_figures:) if black_king == from ->
      Board(
        white_king:,
        black_king: to,
        other_figures: dict.delete(other_figures, to),
      )
    Board(white_king:, black_king:, other_figures:) -> {
      let moving_figure = dict.get(other_figures, from)
      case moving_figure {
        Error(_) -> board
        Ok(moving_figure) ->
          Board(
            white_king:,
            black_king:,
            other_figures: other_figures
              |> dict.delete(from)
              |> dict.insert(to, moving_figure),
          )
      }
    }
  }
}
