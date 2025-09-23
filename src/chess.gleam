import gleam/bool
import gleam/dict
import gleam/int
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

pub type GetMovesError {
  GameAlreadyOver
  SelectedFigureDoesntExist
  SelectedFigureIsNotFriendly
}

/// Return a list of possible moves from a selected figure
pub fn get_moves(
  game: Game,
  figure coord: Coordinate,
) -> Result(set.Set(Coordinate), GetMovesError) {
  case game.state {
    Checkmate(_) -> Error(GameAlreadyOver)
    Forfeit(_) -> Error(GameAlreadyOver)
    Stalemate -> Error(GameAlreadyOver)
    WaitingOnNextMove(moving_player) -> {
      let selected_figure =
        dict.get(game.board, coord)
        |> result.map_error(fn(_) { SelectedFigureDoesntExist })
      use #(selected_figure, selected_figure_owner) <- result.try(
        selected_figure,
      )
      case selected_figure_owner == moving_player {
        False -> Error(SelectedFigureIsNotFriendly)
        True -> {
          case selected_figure {
            Pawn -> Ok(get_moves_for_pawn(game.board, coord, moving_player))
            Bishop -> Ok(get_moves_for_bishop(game.board, coord, moving_player))
            King -> Ok(get_moves_for_king(game.board, coord, moving_player))
            Knight -> Ok(get_moves_for_knight(game.board, coord, moving_player))
            Queen -> Ok(get_moves_for_queen(game.board, coord, moving_player))
            Rook -> Ok(get_moves_for_rook(game.board, coord, moving_player))
          }
        }
      }
    }
  }
}

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

  // Check move up-up
  let up_up = {
    // If up is disallowed, then disallow up_up
    use _ <- option.then(up)
    let to_row = case attacker {
      White -> Row4
      Black -> Row5
    }
    use up_up <- option.then(move_coord(coord, 0, { 2 * up_direction }))
    // if 'up-up' doesn't go to 'to_row' then the pawn has moved and is disqualified
    use <- bool.guard(when: up_up.1 != to_row, return: None)
    case dict.get(board, up_up) {
      Error(_) -> Some(up_up)
      Ok(_) -> None
    }
  }

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
    [up, up_up, up_left, up_right]
    |> option.values
    |> set.from_list

  all_moves
}

fn get_moves_for_king(
  board: Board,
  coord: Coordinate,
  attacker: Player,
) -> set.Set(Coordinate) {
  [#(0, 1), #(1, 1), #(1, 0), #(1, -1), #(0, -1), #(-1, -1), #(-1, 0), #(-1, 1)]
  |> set.from_list()
  |> set.map(JumpTo(origin: coord, offset: _, attacker:))
  |> set.map(evaluate_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

fn get_moves_for_knight(
  board: Board,
  coord: Coordinate,
  attacker: Player,
) -> set.Set(Coordinate) {
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
  |> set.from_list()
  |> set.map(JumpTo(origin: coord, offset: _, attacker:))
  |> set.map(evaluate_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

fn get_moves_for_rook(
  board: Board,
  coord: Coordinate,
  attacker: Player,
) -> set.Set(Coordinate) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

fn get_moves_for_bishop(
  board: Board,
  coord: Coordinate,
  attacker: Player,
) -> set.Set(Coordinate) {
  [#(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

fn get_moves_for_queen(
  board: Board,
  coord: Coordinate,
  attacker: Player,
) -> set.Set(Coordinate) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0), #(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

type MoveDescription {
  JumpTo(origin: Coordinate, offset: #(Int, Int), attacker: Player)
  LineOfSight(origin: Coordinate, direction: #(Int, Int), attacker: Player)
}

fn evaluate_move_description(
  board: Board,
  move_description: MoveDescription,
) -> set.Set(Coordinate) {
  case move_description {
    JumpTo(origin, #(offset_file, offset_row), attacker) -> {
      let destination_coord = move_coord(origin, offset_file, offset_row)
      case destination_coord {
        // Coordinate out of bounds, disallow
        None -> set.new()
        Some(destination_coord) -> {
          let capturee = dict.get(board, destination_coord)
          case capturee {
            // Square free, allow
            Error(_) -> set.from_list([destination_coord])
            Ok(#(_, capturee_owner)) ->
              case capturee_owner == attacker {
                // Square blocked by enemy, allow
                False -> set.from_list([destination_coord])
                // Square blocked by friendly, disallow
                True -> set.new()
              }
          }
        }
      }
    }
    LineOfSight(origin, direction, attacker) -> {
      evaluate_line_of_sight_loop(board, origin, direction, attacker, set.new())
    }
  }
}

fn evaluate_line_of_sight_loop(
  board: Board,
  origin: Coordinate,
  direction: #(Int, Int),
  attacker: Player,
  accumulator: set.Set(Coordinate),
) -> set.Set(Coordinate) {
  let next_coord = move_coord(origin, direction.0, direction.1)
  case next_coord {
    // Out of bounds, stop exploring
    None -> accumulator
    Some(next_coord) -> {
      case dict.get(board, next_coord) {
        // Nothing there: Add next_coord to accumulator and keep exploring
        Error(_) ->
          evaluate_line_of_sight_loop(
            board,
            next_coord,
            direction,
            attacker,
            set.insert(accumulator, next_coord),
          )
        // Blocked by figure
        Ok(#(_, capturee_owner)) -> {
          case capturee_owner == attacker {
            // Blocked by friendly figure, stop exploring
            True -> accumulator
            // Blocked by opposing figure, stop exploring and its coord to accumulator to allow capture
            False -> set.insert(accumulator, next_coord)
          }
        }
      }
    }
  }
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
