import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/set

pub type Game {
  Game(board: Board, state: GameState)
}

pub type GameState {
  Checkmate(winner: Player)
  Forfeit(winner: Player)
  Stalemate
  WaitingOnNextMove(next_player: Player)
}

pub type Board =
  dict.Dict(Coordinate, #(Figure, Player))

pub type Coordinate =
  #(File, Row)

pub type Figure {
  Pawn
  Knight
  Bishop
  Rook
  Queen
  King
}

pub type Player {
  White
  Black
}

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

pub fn new_game() -> Game {
  let board =
    dict.from_list([
      #(a1, #(Rook, White)),
      #(b1, #(Knight, White)),
      #(c1, #(Bishop, White)),
      #(d1, #(Queen, White)),
      #(e1, #(King, White)),
      #(f1, #(Bishop, White)),
      #(g1, #(Knight, White)),
      #(h1, #(Rook, White)),
      #(a2, #(Pawn, White)),
      #(b2, #(Pawn, White)),
      #(c2, #(Pawn, White)),
      #(d2, #(Pawn, White)),
      #(e2, #(Pawn, White)),
      #(f2, #(Pawn, White)),
      #(g2, #(Pawn, White)),
      #(h2, #(Pawn, White)),
      #(a8, #(Rook, Black)),
      #(b8, #(Knight, Black)),
      #(c8, #(Bishop, Black)),
      #(d8, #(Queen, Black)),
      #(e8, #(King, Black)),
      #(f8, #(Bishop, Black)),
      #(g8, #(Knight, Black)),
      #(h8, #(Rook, Black)),
      #(a7, #(Pawn, Black)),
      #(b7, #(Pawn, Black)),
      #(c7, #(Pawn, Black)),
      #(d7, #(Pawn, Black)),
      #(e7, #(Pawn, Black)),
      #(f7, #(Pawn, Black)),
      #(g7, #(Pawn, Black)),
      #(h7, #(Pawn, Black)),
    ])
  Game(board:, state: WaitingOnNextMove(White))
}

/// Return a list of possible moves from a selected figure
/// Returns Error(Nil) if selected_figure is not on the board or not the next_player's turn.
pub fn show_moves(
  game: Game,
  figure coord: Coordinate,
) -> Result(set.Set(Coordinate), Nil) {
  case game.state {
    Checkmate(_) -> Error(Nil)
    Forfeit(_) -> Error(Nil)
    Stalemate -> Error(Nil)
    WaitingOnNextMove(moving_player) -> {
      use #(selected_figure, selected_figure_owner) <- result.try(dict.get(
        game.board,
        coord,
      ))
      case selected_figure_owner == moving_player {
        False -> Error(Nil)
        True -> {
          case selected_figure {
            Pawn -> Ok(get_moves_for_pawn(game.board, coord, moving_player))
            Bishop -> todo
            King -> Ok(get_moves_for_king(game.board, coord, moving_player))
            Knight -> Ok(get_moves_for_knight(game.board, coord, moving_player))
            Queen -> todo
            Rook -> todo
          }
        }
      }
    }
  }
}

/// Return list of all possible moves with a pawn on coord owned by owner
fn get_moves_for_pawn(
  board: Board,
  coord: Coordinate,
  attacker: Player,
) -> set.Set(Coordinate) {
  let up_direction = case attacker {
    White -> 1
    Black -> -1
  }

  // Check move up
  let up = move_coord(coord, 0, up_direction)
  let up =
    option.then(up, fn(up) {
      case dict.get(board, up) {
        // Square empty, allow
        Error(_) -> Some(up)
        // Square blocked, disallow
        Ok(_) -> None
      }
    })

  // Check capture up-left
  let up_left = move_coord(coord, -1, up_direction)
  let up_left =
    option.then(up_left, fn(up_left) {
      case dict.get(board, up_left) {
        // Square empty, disallow
        Error(_) -> None
        Ok(#(_, other_figure_owner)) ->
          case other_figure_owner == attacker {
            // Square blocked by friendly piece, disallow
            True -> None
            // Square blocked by opposing piece, allow
            False -> Some(up_left)
          }
      }
    })

  // Check capture up-right
  let up_right = move_coord(coord, 1, up_direction)
  let up_right =
    option.then(up_right, fn(up_right) {
      case dict.get(board, up_right) {
        // Square empty, disallow
        Error(_) -> None
        Ok(#(_, other_figure_owner)) ->
          case other_figure_owner == attacker {
            // Square blocked by friendly piece, disallow
            True -> None
            // Square blocked by opposing piece, allow
            False -> Some(up_right)
          }
      }
    })

  let all_moves =
    [up, up_left, up_right]
    |> option.values
    |> set.from_list

  all_moves
}

fn get_moves_for_king(
  board: Board,
  coord: Coordinate,
  attacker: Player,
) -> set.Set(Coordinate) {
  // All possible coordinate offsets
  [#(0, 1), #(1, 1), #(1, 0), #(1, -1), #(0, -1), #(-1, -1), #(-1, 0), #(-1, 1)]
  // Map to real coordinates
  |> list.map(fn(offset) {
    let #(offset_file, offset_row) = offset
    move_coord(coord, offset_file, offset_row)
  })
  // Filter coordinates out of bounds
  |> option.values
  // Filter coordinates that are valid moves
  |> list.filter(fn(capturee_coord) {
    case dict.get(board, capturee_coord) {
      // Square empty, allow
      Error(_) -> True
      Ok(#(_, capturee_owner)) ->
        case capturee_owner == attacker {
          // Square blocked by friendly figure, disallow
          True -> False
          // Square blocked opposing figure, allow
          False -> True
        }
    }
  })
  |> set.from_list()
}

fn get_moves_for_knight(
  board: Board,
  coord: Coordinate,
  attacker: Player,
) -> set.Set(Coordinate) {
  // All possible coordinate offsets
  [
    #(1, 2),
    #(2, 1),
    #(2, -1),
    #(1, -2),
    #(-1, -2),
    #(-2, -1),
    #(-2, 1),
    #(-1, 2),
  ]
  // Map to real coordinates
  |> list.map(fn(offset) {
    let #(offset_file, offset_row) = offset
    move_coord(coord, offset_file, offset_row)
  })
  // Filter coordinates out of bounds
  |> option.values
  // Filter coordinates that are valid moves
  |> list.filter(fn(capturee_coord) {
    case dict.get(board, capturee_coord) {
      // Square empty, allow
      Error(_) -> True
      Ok(#(_, capturee_owner)) ->
        case capturee_owner == attacker {
          // Square blocked by friendly figure, disallow
          True -> False
          // Square blocked opposing figure, allow
          False -> True
        }
    }
  })
  |> set.from_list()
}

fn move_coord(
  coord: Coordinate,
  by_file by_file: Int,
  by_row by_row: Int,
) -> Option(Coordinate) {
  use new_file <- option.then(move_file(coord.0, by_file))
  use new_row <- option.then(move_row(coord.1, by_row))
  Some(#(new_file, new_row))
}

fn move_row(row: Row, by: Int) -> Option(Row) {
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
