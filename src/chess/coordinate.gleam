//// This module's responsible for modelling the coordinate system and providing relevant helper functions.
//// 
//// To allow less verbose usage, constants of every coordinate combination are also provided.

import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/order

/// Represents a coordinate pointing to a square on the chess board
pub type Coordinate =
  #(File, Row)

/// Represents a file (up/down line of squares) of a chess board.
pub type File {
  FileA
  FileB
  FileC
  FileD
  FileE
  FileF
  FileG
  FileH
}

/// Represents a row (left/right line of squares) of a chess board.
pub type Row {
  Row1
  Row2
  Row3
  Row4
  Row5
  Row6
  Row7
  Row8
}

/// Move a coordinate by a specific amount of files and rows
pub fn move(
  coord coord: Coordinate,
  by_file by_file: Int,
  by_row by_row: Int,
) -> Option(Coordinate) {
  use new_file <- option.then(move_file(coord.0, by_file))
  use new_row <- option.then(move_row(coord.1, by_row))
  Some(#(new_file, new_row))
}

/// Move a row up/down `by` times
fn move_row(row row: Row, by by: Int) -> Option(Row) {
  case int.compare(by, 0) {
    order.Eq -> Some(row)
    order.Gt ->
      case row {
        Row1 -> move_row(Row2, by - 1)
        Row2 -> move_row(Row3, by - 1)
        Row3 -> move_row(Row4, by - 1)
        Row4 -> move_row(Row5, by - 1)
        Row5 -> move_row(Row6, by - 1)
        Row6 -> move_row(Row7, by - 1)
        Row7 -> move_row(Row8, by - 1)
        Row8 -> None
      }
    order.Lt ->
      case row {
        Row1 -> None
        Row2 -> move_row(Row1, by + 1)
        Row3 -> move_row(Row2, by + 1)
        Row4 -> move_row(Row3, by + 1)
        Row5 -> move_row(Row4, by + 1)
        Row6 -> move_row(Row5, by + 1)
        Row7 -> move_row(Row6, by + 1)
        Row8 -> move_row(Row7, by + 1)
      }
  }
}

/// Move a file left/right `by` times
fn move_file(file: File, by: Int) -> Option(File) {
  case int.compare(by, 0) {
    order.Eq -> Some(file)
    order.Gt ->
      case file {
        FileA -> move_file(FileB, by - 1)
        FileB -> move_file(FileC, by - 1)
        FileC -> move_file(FileD, by - 1)
        FileD -> move_file(FileE, by - 1)
        FileE -> move_file(FileF, by - 1)
        FileF -> move_file(FileG, by - 1)
        FileG -> move_file(FileH, by - 1)
        FileH -> None
      }
    order.Lt ->
      case file {
        FileA -> None
        FileB -> move_file(FileA, by + 1)
        FileC -> move_file(FileB, by + 1)
        FileD -> move_file(FileC, by + 1)
        FileE -> move_file(FileD, by + 1)
        FileF -> move_file(FileE, by + 1)
        FileG -> move_file(FileF, by + 1)
        FileH -> move_file(FileG, by + 1)
      }
  }
}

pub const a1 = #(FileA, Row1)

pub const a2 = #(FileA, Row2)

pub const a3 = #(FileA, Row3)

pub const a4 = #(FileA, Row4)

pub const a5 = #(FileA, Row5)

pub const a6 = #(FileA, Row6)

pub const a7 = #(FileA, Row7)

pub const a8 = #(FileA, Row8)

pub const b1 = #(FileB, Row1)

pub const b2 = #(FileB, Row2)

pub const b3 = #(FileB, Row3)

pub const b4 = #(FileB, Row4)

pub const b5 = #(FileB, Row5)

pub const b6 = #(FileB, Row6)

pub const b7 = #(FileB, Row7)

pub const b8 = #(FileB, Row8)

pub const c1 = #(FileC, Row1)

pub const c2 = #(FileC, Row2)

pub const c3 = #(FileC, Row3)

pub const c4 = #(FileC, Row4)

pub const c5 = #(FileC, Row5)

pub const c6 = #(FileC, Row6)

pub const c7 = #(FileC, Row7)

pub const c8 = #(FileC, Row8)

pub const d1 = #(FileD, Row1)

pub const d2 = #(FileD, Row2)

pub const d3 = #(FileD, Row3)

pub const d4 = #(FileD, Row4)

pub const d5 = #(FileD, Row5)

pub const d6 = #(FileD, Row6)

pub const d7 = #(FileD, Row7)

pub const d8 = #(FileD, Row8)

pub const e1 = #(FileE, Row1)

pub const e2 = #(FileE, Row2)

pub const e3 = #(FileE, Row3)

pub const e4 = #(FileE, Row4)

pub const e5 = #(FileE, Row5)

pub const e6 = #(FileE, Row6)

pub const e7 = #(FileE, Row7)

pub const e8 = #(FileE, Row8)

pub const f1 = #(FileF, Row1)

pub const f2 = #(FileF, Row2)

pub const f3 = #(FileF, Row3)

pub const f4 = #(FileF, Row4)

pub const f5 = #(FileF, Row5)

pub const f6 = #(FileF, Row6)

pub const f7 = #(FileF, Row7)

pub const f8 = #(FileF, Row8)

pub const g1 = #(FileG, Row1)

pub const g2 = #(FileG, Row2)

pub const g3 = #(FileG, Row3)

pub const g4 = #(FileG, Row4)

pub const g5 = #(FileG, Row5)

pub const g6 = #(FileG, Row6)

pub const g7 = #(FileG, Row7)

pub const g8 = #(FileG, Row8)

pub const h1 = #(FileH, Row1)

pub const h2 = #(FileH, Row2)

pub const h3 = #(FileH, Row3)

pub const h4 = #(FileH, Row4)

pub const h5 = #(FileH, Row5)

pub const h6 = #(FileH, Row6)

pub const h7 = #(FileH, Row7)

pub const h8 = #(FileH, Row8)
