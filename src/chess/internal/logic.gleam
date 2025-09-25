//// This internal module is providing game logic

import chess/board.{type Board, type Player, Black, White}
import chess/coordinate.{type Coordinate} as coord
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set

/// Returned by `logic.get_legal_moves` in error cases
pub type GetMovesError {
  SelectedFigureDoesntExist
  SelectedFigureIsNotFriendly
}

/// Retrieve all legal moves of all figures of `moving_player`
pub fn get_all_legal_moves(
  board board: Board,
  moving_player moving_player: Player,
) -> set.Set(#(Coordinate, Coordinate)) {
  let king = case moving_player {
    White -> board.white_king
    Black -> board.black_king
  }
  let figures =
    board.other_figures
    |> dict.to_list
    |> list.filter(fn(coord_and_figure) {
      coord_and_figure.1.1 == moving_player
    })
    |> list.map(fn(coord_and_figure) { coord_and_figure.0 })
    |> list.append([king])
    |> set.from_list()

  let all_moves =
    figures
    |> set.map(fn(from) {
      get_legal_moves(board, from, moving_player)
      |> result.unwrap(set.new())
      |> set.map(fn(to) { #(from, to) })
    })
    // Flatten
    |> set.fold(set.new(), set.union)

  all_moves
}

/// Retrieve all legal moves of a given figure.
pub fn get_legal_moves(
  board board: Board,
  figure coord: Coordinate,
  moving_player moving_player: Player,
) -> Result(set.Set(Coordinate), GetMovesError) {
  case get_unchecked_moves(board, coord, moving_player) {
    Error(SelectedFigureDoesntExist) -> Error(SelectedFigureDoesntExist)
    Error(SelectedFigureIsNotFriendly) -> Error(SelectedFigureIsNotFriendly)
    Ok(moves) -> {
      // Make sure the player is not in check after his move
      moves
      |> set.filter(fn(to) {
        let from = coord
        // Simulate move, then check if moving_player is still in check
        let future_board = board.move(board, from, to)
        !is_in_check(future_board, moving_player)
      })
      |> Ok
    }
  }
}

/// Determines wether the player is being checked by its opponent.
pub fn is_in_check(board board: Board, player attackee: Player) -> Bool {
  // Check if attackee is in check by requesting all moves of all
  // attacker pieces and seeing if any of their moves hit the king

  let attackee_king = case attackee {
    White -> board.white_king
    Black -> board.black_king
  }
  let attacker = case attackee {
    White -> Black
    Black -> White
  }

  // A king can never be checked by the opponent's king,
  // thus iterating only over board.other_figures is sufficient
  board.other_figures
  |> dict.to_list
  // Find all pieces belonging to attacker
  |> list.filter(fn(coord_and_figure) { coord_and_figure.1.1 == attacker })
  |> list.map(fn(coord_and_figure) { coord_and_figure.0 })
  // Get all attacker moves
  |> list.flat_map(fn(coord) {
    get_unchecked_moves(board, coord, attacker)
    |> result.map(set.to_list)
    |> result.unwrap([])
  })
  // Check if any attacker move goes to attackee king
  |> list.contains(attackee_king)
}

/// Retrieve all moves of a given figure.
/// 
/// Doesn't consider if moving_player's king is in check.
fn get_unchecked_moves(
  board board: Board,
  figure coord: Coordinate,
  moving_player moving_player: Player,
) -> Result(set.Set(Coordinate), GetMovesError) {
  let selected_figure =
    board.get(board, coord)
    |> option.to_result(SelectedFigureDoesntExist)
  use #(selected_figure, selected_figure_owner) <- result.try(selected_figure)
  use <- bool.guard(
    when: selected_figure_owner != moving_player,
    return: Error(SelectedFigureIsNotFriendly),
  )

  let moves = case selected_figure {
    board.Pawn -> get_moves_for_pawn(board, coord, moving_player)
    board.Bishop -> get_moves_for_bishop(board, coord, moving_player)
    board.King -> get_moves_for_king(board, coord, moving_player)
    board.Knight -> get_moves_for_knight(board, coord, moving_player)
    board.Queen -> get_moves_for_queen(board, coord, moving_player)
    board.Rook -> get_moves_for_rook(board, coord, moving_player)
  }

  Ok(moves)
}

/// Get all possible destinations of a pawn
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_pawn(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(Coordinate) {
  let up_direction = case attacker {
    White -> 1
    Black -> -1
  }

  // Check move up
  let up = {
    use up <- option.then(coord.move(coord, 0, up_direction))
    case board.get(board, up) {
      // Square empty, allow
      None -> Some(up)
      // Square blocked, disallow
      Some(_) -> None
    }
  }

  // Check move up-up
  let up_up = {
    // If up is disallowed, then disallow up_up
    use up <- option.then(up)
    let to_row = case attacker {
      White -> coord.Row4
      Black -> coord.Row5
    }
    use up_up <- option.then(coord.move(up, 0, up_direction))
    // if 'up-up' doesn't go to 'to_row' then the pawn has moved and is disqualified
    use <- bool.guard(when: up_up.1 != to_row, return: None)
    case board.get(board, up_up) {
      // Square empty, allow
      None -> Some(up_up)
      // Square blocked, disallow
      Some(_) -> None
    }
  }

  // Check capture up-left
  let up_left = {
    use up_left <- option.then(coord.move(coord, -1, up_direction))
    case board.get(board, up_left) {
      // Square empty, disallow
      None -> None
      Some(#(_, other_figure_owner)) ->
        case other_figure_owner == attacker {
          // Square blocked by friendly piece, disallow
          True -> None
          // Square blocked by opposing piece, allow
          False -> Some(up_left)
        }
    }
  }

  // Check capture up-right
  let up_right = {
    use up_right <- option.then(coord.move(coord, 1, up_direction))
    case board.get(board, up_right) {
      // Square empty, disallow
      None -> None
      Some(#(_, other_figure_owner)) ->
        case other_figure_owner == attacker {
          // Square blocked by friendly piece, disallow
          True -> None
          // Square blocked by opposing piece, allow
          False -> Some(up_right)
        }
    }
  }

  let all_moves =
    [up, up_up, up_left, up_right]
    |> option.values
    |> set.from_list

  all_moves
}

/// Get all possible destinations of a king
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_king(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(Coordinate) {
  [#(0, 1), #(1, 1), #(1, 0), #(1, -1), #(0, -1), #(-1, -1), #(-1, 0), #(-1, 1)]
  |> set.from_list()
  |> set.map(JumpTo(origin: coord, offset: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

/// Get all possible destinations of a knight
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_knight(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
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
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

/// Get all possible destinations of a rook
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_rook(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(Coordinate) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

/// Get all possible destinations of a bishop
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_bishop(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(Coordinate) {
  [#(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

/// Get all possible destinations of a queen
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_queen(
  board board: Board,
  coord coord: Coordinate,
  attacking_player attacker: Player,
) -> set.Set(Coordinate) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0), #(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
}

/// Used to describe a standard figure movement possibility
type FigureMoveDescription {
  JumpTo(origin: Coordinate, offset: #(Int, Int), attacker: Player)
  LineOfSight(origin: Coordinate, direction: #(Int, Int), attacker: Player)
}

/// Use the move_description to find all squares which the figure can go to
fn evaluate_figure_move_description(
  board board: Board,
  move_description move_description: FigureMoveDescription,
) -> set.Set(Coordinate) {
  case move_description {
    JumpTo(origin, #(offset_file, offset_row), attacker) -> {
      let destination_coord = coord.move(origin, offset_file, offset_row)
      case destination_coord {
        // Coordinate out of bounds, disallow
        None -> set.new()
        Some(destination_coord) -> {
          let capturee = board.get(board, destination_coord)
          case capturee {
            // Square free, allow
            None -> set.from_list([destination_coord])
            // Square blocked
            Some(#(_, capturee_owner)) ->
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

/// Recursive function used by `evaluate_figure_move_description()` to find
/// all squares in a figure's line of sight
fn evaluate_line_of_sight_loop(
  board board: Board,
  origin origin: Coordinate,
  direction direction: #(Int, Int),
  attacker attacker: Player,
  accumulator accumulator: set.Set(Coordinate),
) -> set.Set(Coordinate) {
  let next_coord = coord.move(origin, direction.0, direction.1)
  case next_coord {
    // Out of bounds, stop exploring
    None -> accumulator
    Some(next_coord) -> {
      case board.get(board, next_coord) {
        // Nothing there: Add next_coord to accumulator and keep exploring
        None ->
          evaluate_line_of_sight_loop(
            board,
            next_coord,
            direction,
            attacker,
            set.insert(accumulator, next_coord),
          )
        // Blocked by figure
        Some(#(_, capturee_owner)) -> {
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
