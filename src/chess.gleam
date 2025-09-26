//// The main module of this chess package is responsible for the public facing API

import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/set

/// Represents entire game state.
/// 
/// Use [`new_game`](#new_game) to generate.
pub type Game {
  Game(board: Board, state: GameState)
}

/// Represents if the game is won/lost/tied or still ongoing.
pub type GameState {
  Checkmated(winner: Player)
  Forfeited(winner: Player)
  Stalemated
  WaitingOnNextMove(next_player: Player)
}

/// Represents an error that may be returned when making or requesting players moves.
pub type Error {
  GameAlreadyOver
  SelectedFigureDoesntExist
  SelectedFigureIsNotFriendly
  SelectedFigureCantGoThere
}

/// Represents all figure positions on a chess board.
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

/// Represents a coordinate pointing to a square on the chess board.
/// 
/// Use the provided [`coord_*`](#coord_a1) constants to quickly reference coordinates.
pub type Coordinate =
  #(File, Row)

/// Represents a file (up/down line of squares) of a chess board.
/// 
/// Use the provided [`coord_*`](#coord_a1) constants to quickly reference coordinates.
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
/// 
/// Use the provided [`coord_*`](#coord_a1) constants to quickly reference coordinates.
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

/// Creates a new game in the standard starting chess position.
pub fn new_game() -> Game {
  Game(board: board_new(), state: WaitingOnNextMove(White))
}

/// Represents a chess move by the player.
/// 
/// To be used with [`player_move`](#player_move).
pub type PlayerMove {
  MoveFigure(from: Coordinate, to: Coordinate)
  Forfeit
}

/// Process a chess move and return the new state.
/// 
/// To get a list of legal figure moves use [`get_legal_moves`](#get_lega_moves).
pub fn player_move(
  game game: Game,
  move player_move: PlayerMove,
) -> Result(Game, Error) {
  case game.state {
    Checkmated(_) -> Error(GameAlreadyOver)
    Forfeited(_) -> Error(GameAlreadyOver)
    Stalemated -> Error(GameAlreadyOver)
    WaitingOnNextMove(moving_player) -> {
      let opponent_player = case moving_player {
        Black -> White
        White -> Black
      }

      case player_move {
        // Forfeit, return forfeited
        Forfeit -> Ok(Game(game.board, Forfeited(opponent_player)))

        // Process figure move
        MoveFigure(from:, to:) -> {
          use possible_moves <- result.try(get_legal_moves(game, from))

          // Check if given move is legal
          use <- bool.guard(
            when: !set.contains(possible_moves, to),
            return: Error(SelectedFigureCantGoThere),
          )

          // Do the move
          let new_board = board_move(game.board, from, to)

          // Check if game ended
          let new_state = {
            // If there are only kings left, then the game is a stalemate
            use <- bool.guard(
              when: dict.is_empty(new_board.other_figures),
              return: Stalemated,
            )

            let opponent_has_no_moves =
              get_all_legal_moves_on_arbitrary_board(new_board, opponent_player)
              |> set.is_empty()

            let opponent_is_in_check = is_in_check(new_board, opponent_player)

            case opponent_has_no_moves, opponent_is_in_check {
              True, True -> Checkmated(winner: moving_player)
              True, False -> Stalemated
              False, _ -> WaitingOnNextMove(opponent_player)
            }
          }
          Ok(Game(new_board, new_state))
        }
      }
    }
  }
}

/// Return a list of all legal moves from a selected figure.
/// 
/// To execute a move use [`player_move`](#player_move).
pub fn get_legal_moves(
  game game: Game,
  figure coord: Coordinate,
) -> Result(set.Set(Coordinate), Error) {
  case game.state {
    Checkmated(_) -> Error(GameAlreadyOver)
    Forfeited(_) -> Error(GameAlreadyOver)
    Stalemated -> Error(GameAlreadyOver)
    WaitingOnNextMove(moving_player) ->
      get_legal_moves_on_arbitrary_board(game.board, coord, moving_player)
  }
}

/// Retrieve all legal moves of all figures of `moving_player`
fn get_all_legal_moves_on_arbitrary_board(
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
      get_legal_moves_on_arbitrary_board(board, from, moving_player)
      |> result.unwrap(set.new())
      |> set.map(fn(to) { #(from, to) })
    })
    // Flatten
    |> set.fold(set.new(), set.union)

  all_moves
}

/// Retrieve all legal moves of a given figure.
/// Unlike `get_legal_moves` this doesn't require a full `Game` variable
fn get_legal_moves_on_arbitrary_board(
  board board: Board,
  figure coord: Coordinate,
  moving_player moving_player: Player,
) -> Result(set.Set(Coordinate), Error) {
  use moves <- result.try(get_unchecked_moves(board, coord, moving_player))

  // Make sure the player is not in check after his move
  moves
  |> set.filter(fn(to) {
    let from = coord
    // Simulate move, then check if moving_player is still in check
    let future_board = board_move(board, from, to)
    !is_in_check(future_board, moving_player)
  })
  |> Ok
}

/// Determines wether the player is being checked by its opponent.
fn is_in_check(board board: Board, player attackee: Player) -> Bool {
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
) -> Result(set.Set(Coordinate), Error) {
  let selected_figure =
    board_get(board, coord)
    |> option.to_result(SelectedFigureDoesntExist)
  use #(selected_figure, selected_figure_owner) <- result.try(selected_figure)
  use <- bool.guard(
    when: selected_figure_owner != moving_player,
    return: Error(SelectedFigureIsNotFriendly),
  )

  let moves = case selected_figure {
    Pawn -> get_moves_for_pawn(board, coord, moving_player)
    Bishop -> get_moves_for_bishop(board, coord, moving_player)
    King -> get_moves_for_king(board, coord, moving_player)
    Knight -> get_moves_for_knight(board, coord, moving_player)
    Queen -> get_moves_for_queen(board, coord, moving_player)
    Rook -> get_moves_for_rook(board, coord, moving_player)
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
    use up <- option.then(coord_move(coord, 0, up_direction))
    case board_get(board, up) {
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
      White -> Row4
      Black -> Row5
    }
    use up_up <- option.then(coord_move(up, 0, up_direction))
    // if 'up-up' doesn't go to 'to_row' then the pawn has moved and is disqualified
    use <- bool.guard(when: up_up.1 != to_row, return: None)
    case board_get(board, up_up) {
      // Square empty, allow
      None -> Some(up_up)
      // Square blocked, disallow
      Some(_) -> None
    }
  }

  // Check capture up-left
  let up_left = {
    use up_left <- option.then(coord_move(coord, -1, up_direction))
    case board_get(board, up_left) {
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
    use up_right <- option.then(coord_move(coord, 1, up_direction))
    case board_get(board, up_right) {
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
      let destination_coord = coord_move(origin, offset_file, offset_row)
      case destination_coord {
        // Coordinate out of bounds, disallow
        None -> set.new()
        Some(destination_coord) -> {
          let capturee = board_get(board, destination_coord)
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
  let next_coord = coord_move(origin, direction.0, direction.1)
  case next_coord {
    // Out of bounds, stop exploring
    None -> accumulator
    Some(next_coord) -> {
      case board_get(board, next_coord) {
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

/// Creates a new board in the standard chess starting position.
fn board_new() -> Board {
  Board(
    white_king: coord_e1,
    black_king: coord_e8,
    other_figures: dict.from_list([
      #(coord_a1, #(Rook, White)),
      #(coord_b1, #(Knight, White)),
      #(coord_c1, #(Bishop, White)),
      #(coord_d1, #(Queen, White)),
      #(coord_f1, #(Bishop, White)),
      #(coord_g1, #(Knight, White)),
      #(coord_h1, #(Rook, White)),
      #(coord_a2, #(Pawn, White)),
      #(coord_b2, #(Pawn, White)),
      #(coord_c2, #(Pawn, White)),
      #(coord_d2, #(Pawn, White)),
      #(coord_e2, #(Pawn, White)),
      #(coord_f2, #(Pawn, White)),
      #(coord_g2, #(Pawn, White)),
      #(coord_h2, #(Pawn, White)),
      #(coord_a8, #(Rook, Black)),
      #(coord_b8, #(Knight, Black)),
      #(coord_c8, #(Bishop, Black)),
      #(coord_d8, #(Queen, Black)),
      #(coord_f8, #(Bishop, Black)),
      #(coord_g8, #(Knight, Black)),
      #(coord_h8, #(Rook, Black)),
      #(coord_a7, #(Pawn, Black)),
      #(coord_b7, #(Pawn, Black)),
      #(coord_c7, #(Pawn, Black)),
      #(coord_d7, #(Pawn, Black)),
      #(coord_e7, #(Pawn, Black)),
      #(coord_f7, #(Pawn, Black)),
      #(coord_g7, #(Pawn, Black)),
      #(coord_h7, #(Pawn, Black)),
    ]),
  )
}

/// Get a figure on `coord` from a `board`
fn board_get(
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
fn board_move(
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

/// Move a coordinate by a specific amount of files and rows
fn coord_move(
  coord coord: Coordinate,
  by_file by_file: Int,
  by_row by_row: Int,
) -> Option(Coordinate) {
  use new_file <- option.then(file_move(coord.0, by_file))
  use new_row <- option.then(row_move(coord.1, by_row))
  Some(#(new_file, new_row))
}

/// Move a row up/down `by` times
fn row_move(row row: Row, by by: Int) -> Option(Row) {
  case int.compare(by, 0) {
    order.Eq -> Some(row)
    order.Gt ->
      case row {
        Row1 -> row_move(Row2, by - 1)
        Row2 -> row_move(Row3, by - 1)
        Row3 -> row_move(Row4, by - 1)
        Row4 -> row_move(Row5, by - 1)
        Row5 -> row_move(Row6, by - 1)
        Row6 -> row_move(Row7, by - 1)
        Row7 -> row_move(Row8, by - 1)
        Row8 -> None
      }
    order.Lt ->
      case row {
        Row1 -> None
        Row2 -> row_move(Row1, by + 1)
        Row3 -> row_move(Row2, by + 1)
        Row4 -> row_move(Row3, by + 1)
        Row5 -> row_move(Row4, by + 1)
        Row6 -> row_move(Row5, by + 1)
        Row7 -> row_move(Row6, by + 1)
        Row8 -> row_move(Row7, by + 1)
      }
  }
}

/// Move a file left/right `by` times
fn file_move(file: File, by: Int) -> Option(File) {
  case int.compare(by, 0) {
    order.Eq -> Some(file)
    order.Gt ->
      case file {
        FileA -> file_move(FileB, by - 1)
        FileB -> file_move(FileC, by - 1)
        FileC -> file_move(FileD, by - 1)
        FileD -> file_move(FileE, by - 1)
        FileE -> file_move(FileF, by - 1)
        FileF -> file_move(FileG, by - 1)
        FileG -> file_move(FileH, by - 1)
        FileH -> None
      }
    order.Lt ->
      case file {
        FileA -> None
        FileB -> file_move(FileA, by + 1)
        FileC -> file_move(FileB, by + 1)
        FileD -> file_move(FileC, by + 1)
        FileE -> file_move(FileD, by + 1)
        FileF -> file_move(FileE, by + 1)
        FileG -> file_move(FileF, by + 1)
        FileH -> file_move(FileG, by + 1)
      }
  }
}

/// Short hand for the file/row A1
pub const coord_a1 = #(FileA, Row1)

/// Short hand for the file/row A2
pub const coord_a2 = #(FileA, Row2)

/// Short hand for the file/row A3
pub const coord_a3 = #(FileA, Row3)

/// Short hand for the file/row A4
pub const coord_a4 = #(FileA, Row4)

/// Short hand for the file/row A5
pub const coord_a5 = #(FileA, Row5)

/// Short hand for the file/row A6
pub const coord_a6 = #(FileA, Row6)

/// Short hand for the file/row A7
pub const coord_a7 = #(FileA, Row7)

/// Short hand for the file/row A8
pub const coord_a8 = #(FileA, Row8)

/// Short hand for the file/row B1
pub const coord_b1 = #(FileB, Row1)

/// Short hand for the file/row B2
pub const coord_b2 = #(FileB, Row2)

/// Short hand for the file/row B3
pub const coord_b3 = #(FileB, Row3)

/// Short hand for the file/row B4
pub const coord_b4 = #(FileB, Row4)

/// Short hand for the file/row B5
pub const coord_b5 = #(FileB, Row5)

/// Short hand for the file/row B6
pub const coord_b6 = #(FileB, Row6)

/// Short hand for the file/row B7
pub const coord_b7 = #(FileB, Row7)

/// Short hand for the file/row B8
pub const coord_b8 = #(FileB, Row8)

/// Short hand for the file/row C1
pub const coord_c1 = #(FileC, Row1)

/// Short hand for the file/row C2
pub const coord_c2 = #(FileC, Row2)

/// Short hand for the file/row C3
pub const coord_c3 = #(FileC, Row3)

/// Short hand for the file/row C4
pub const coord_c4 = #(FileC, Row4)

/// Short hand for the file/row C5
pub const coord_c5 = #(FileC, Row5)

/// Short hand for the file/row C6
pub const coord_c6 = #(FileC, Row6)

/// Short hand for the file/row C7
pub const coord_c7 = #(FileC, Row7)

/// Short hand for the file/row C8
pub const coord_c8 = #(FileC, Row8)

/// Short hand for the file/row D1
pub const coord_d1 = #(FileD, Row1)

/// Short hand for the file/row D2
pub const coord_d2 = #(FileD, Row2)

/// Short hand for the file/row D3
pub const coord_d3 = #(FileD, Row3)

/// Short hand for the file/row D4
pub const coord_d4 = #(FileD, Row4)

/// Short hand for the file/row D5
pub const coord_d5 = #(FileD, Row5)

/// Short hand for the file/row D6
pub const coord_d6 = #(FileD, Row6)

/// Short hand for the file/row D7
pub const coord_d7 = #(FileD, Row7)

/// Short hand for the file/row D8
pub const coord_d8 = #(FileD, Row8)

/// Short hand for the file/row E1
pub const coord_e1 = #(FileE, Row1)

/// Short hand for the file/row E2
pub const coord_e2 = #(FileE, Row2)

/// Short hand for the file/row E3
pub const coord_e3 = #(FileE, Row3)

/// Short hand for the file/row E4
pub const coord_e4 = #(FileE, Row4)

/// Short hand for the file/row E5
pub const coord_e5 = #(FileE, Row5)

/// Short hand for the file/row E6
pub const coord_e6 = #(FileE, Row6)

/// Short hand for the file/row E7
pub const coord_e7 = #(FileE, Row7)

/// Short hand for the file/row E8
pub const coord_e8 = #(FileE, Row8)

/// Short hand for the file/row F1
pub const coord_f1 = #(FileF, Row1)

/// Short hand for the file/row F2
pub const coord_f2 = #(FileF, Row2)

/// Short hand for the file/row F3
pub const coord_f3 = #(FileF, Row3)

/// Short hand for the file/row F4
pub const coord_f4 = #(FileF, Row4)

/// Short hand for the file/row F5
pub const coord_f5 = #(FileF, Row5)

/// Short hand for the file/row F6
pub const coord_f6 = #(FileF, Row6)

/// Short hand for the file/row F7
pub const coord_f7 = #(FileF, Row7)

/// Short hand for the file/row F8
pub const coord_f8 = #(FileF, Row8)

/// Short hand for the file/row G1
pub const coord_g1 = #(FileG, Row1)

/// Short hand for the file/row G2
pub const coord_g2 = #(FileG, Row2)

/// Short hand for the file/row G3
pub const coord_g3 = #(FileG, Row3)

/// Short hand for the file/row G4
pub const coord_g4 = #(FileG, Row4)

/// Short hand for the file/row G5
pub const coord_g5 = #(FileG, Row5)

/// Short hand for the file/row G6
pub const coord_g6 = #(FileG, Row6)

/// Short hand for the file/row G7
pub const coord_g7 = #(FileG, Row7)

/// Short hand for the file/row G8
pub const coord_g8 = #(FileG, Row8)

/// Short hand for the file/row H1
pub const coord_h1 = #(FileH, Row1)

/// Short hand for the file/row H2
pub const coord_h2 = #(FileH, Row2)

/// Short hand for the file/row H3
pub const coord_h3 = #(FileH, Row3)

/// Short hand for the file/row H4
pub const coord_h4 = #(FileH, Row4)

/// Short hand for the file/row H5
pub const coord_h5 = #(FileH, Row5)

/// Short hand for the file/row H6
pub const coord_h6 = #(FileH, Row6)

/// Short hand for the file/row H7
pub const coord_h7 = #(FileH, Row7)

/// Short hand for the file/row H8
pub const coord_h8 = #(FileH, Row8)
