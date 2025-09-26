//// Refer to the [README](./index.html) for an introduction and some example code.

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
  Game(board: Board, status: GameStatus)
}

/// Represents if the game still ongoing or over.
pub type GameStatus {
  Victory(winner: Player, by: WinCondition)
  Draw(by: DrawCondition)
  WaitingOnNextMove(next_player: Player)
}

/// Represents a way of winning the game.
pub type WinCondition {
  /// The loser has no legal moves left, while his king is in check.
  Checkmate

  /// The loser forfeited the game.
  Forfeit
}

/// Represents a way of drawing the game
pub type DrawCondition {
  /// TODO: not implemented
  /// 
  /// Both players agreed to end the game in a draw.
  MutualAgreement

  /// A player has no legal moves left, while his king is not in check. See [here](https://www.chess.com/terms/draw-chess#stalemate) for more info.
  Stalemate

  /// TODO: not implemented
  /// 
  /// Both players are missing enough figures to checkmate the enemy king. See [here](https://www.chess.com/terms/draw-chess#dead-position) for more info.
  InsufficientMaterial

  /// TODO: Not implemented
  /// 
  /// Both players reached a position where checkmating the enemy king is impossible. See [here](https://www.chess.com/terms/draw-chess#dead-position) here for more info.
  DeadPosition

  /// TODO: Not implemented
  /// 
  /// The same position has been reached three times. See [here](https://www.chess.com/terms/draw-chess#threefold-repetition) for more info.
  ThreefoldRepition
}

/// Represents an error that may be returned when using the public functions
pub type Error {
  /// Tried making a move while the game is already over.
  GameAlreadyOver

  /// Tried moving a figure from a coordinate which is empty.
  SelectedFigureDoesntExist

  /// Tried moving a figure which doesn't belong to the player.
  SelectedFigureIsNotFriendly

  /// Tried making a move which is not legal.
  IllegalMove
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

/// Represents a coordinate referring to a square on the chess board.
/// 
/// Use the provided [`coord_*`](#coord_a1) constants to quickly reference all board coordinates.
pub type Coordinate {
  Coordinate(file: File, row: Row)
}

/// Represents a file (vertical line of squares) of a chess board.
/// 
/// Use the provided [`coord_*`](#coord_a1) constants to quickly reference all board coordinates.
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

/// Represents a row (horizontal line of squares) of a chess board.
/// 
/// Use the provided [`coord_*`](#coord_a1) constants to quickly reference all board coordinates.
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

/// Represents a chess move by the player.
/// 
/// To be used in [`player_move`](#player_move).
/// 
/// Use [`get_legal_moves`](#get_legal_moves) to generate.
pub type Move {
  /// Used to move a figure from `from` to `to`
  StdFigureMove(from: Coordinate, to: Coordinate)
}

/// Creates a new game in the standard starting chess position.
pub fn new_game() -> Game {
  Game(board: board_new(), status: WaitingOnNextMove(White))
}

/// Forfeit the game to the opposing player.
/// 
/// Errors if the game was already over.
pub fn forfeit(game game: Game) -> Result(Game, Error) {
  case game.status {
    Draw(_) -> Error(GameAlreadyOver)
    Victory(_, _) -> Error(GameAlreadyOver)
    WaitingOnNextMove(next_player: forfeiter) -> {
      let winner = case forfeiter {
        Black -> White
        White -> Black
      }
      Ok(Game(board: game.board, status: Victory(winner:, by: Forfeit)))
    }
  }
}

/// Move a figure and return the new state.
/// 
/// To get a list of legal figure moves use [`get_legal_moves`](#get_legal_moves).
/// 
/// To forfeit the game use [`forfeit`](#forfeit).
/// 
/// Errors if the provided move is not legal or the game was already over.
pub fn player_move(game game: Game, move move: Move) -> Result(Game, Error) {
  case game.status {
    Draw(_) -> Error(GameAlreadyOver)
    Victory(_, _) -> Error(GameAlreadyOver)
    WaitingOnNextMove(moving_player) -> {
      // Process figure move
      // Check if given move is legal
      let is_legal = {
        get_all_legal_moves_on_arbitrary_board(game.board, moving_player:)
        |> set.contains(move)
      }

      use <- bool.guard(when: !is_legal, return: Error(IllegalMove))

      // Do the move
      let new_board = board_move(game.board, move)

      // Check if game ended
      let new_status = {
        // If there are only kings left, then the game is a stalemate
        // TODO: this is not entirely correct => implemented proper draw-conditions
        use <- bool.guard(
          when: dict.is_empty(new_board.other_figures),
          return: Draw(by: Stalemate),
        )

        let opponent_player = case moving_player {
          Black -> White
          White -> Black
        }

        let opponent_has_no_moves =
          get_all_legal_moves_on_arbitrary_board(new_board, opponent_player)
          |> set.is_empty()

        let opponent_is_in_check = is_in_check(new_board, opponent_player)

        case opponent_has_no_moves, opponent_is_in_check {
          True, True -> Victory(winner: moving_player, by: Checkmate)
          True, False -> Draw(by: Stalemate)
          False, _ -> WaitingOnNextMove(opponent_player)
        }
      }
      Ok(Game(new_board, new_status))
    }
  }
}

/// Return a list of all legal moves from a selected figure.
/// 
/// To execute a move use [`player_move`](#player_move).
pub fn get_legal_moves(
  game game: Game,
  figure coord: Coordinate,
) -> Result(set.Set(Move), Error) {
  case game.status {
    Draw(_) -> Error(GameAlreadyOver)
    Victory(_, _) -> Error(GameAlreadyOver)
    WaitingOnNextMove(moving_player) ->
      get_legal_moves_on_arbitrary_board(game.board, coord, moving_player)
  }
}

/// Retrieve all legal moves of all figures of `moving_player`
fn get_all_legal_moves_on_arbitrary_board(
  board board: Board,
  moving_player moving_player: Player,
) -> set.Set(Move) {
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
) -> Result(set.Set(Move), Error) {
  use moves <- result.try(get_unchecked_moves(board, coord, moving_player))

  // Make sure the player is not in check after his move
  moves
  |> set.filter(fn(move) {
    // Simulate move, then check if moving_player is still in check
    let future_board = board_move(board, move)
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
  // Check if any move goes to attacks the attackee's king
  |> list.any(fn(move) {
    case move {
      StdFigureMove(_, to:) -> to == attackee_king
    }
  })
}

/// Retrieve all moves of a given figure.
/// 
/// Doesn't consider if moving_player's king is in check.
fn get_unchecked_moves(
  board board: Board,
  figure coord: Coordinate,
  moving_player moving_player: Player,
) -> Result(set.Set(Move), Error) {
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
) -> set.Set(Move) {
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
    use <- bool.guard(when: up_up.row != to_row, return: None)
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
    |> list.map(fn(to) { StdFigureMove(coord, to) })
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
) -> set.Set(Move) {
  [#(0, 1), #(1, 1), #(1, 0), #(1, -1), #(0, -1), #(-1, -1), #(-1, 0), #(-1, 1)]
  |> set.from_list()
  |> set.map(JumpTo(origin: coord, offset: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StdFigureMove(coord, to) })
}

/// Get all possible destinations of a knight
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_knight(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(Move) {
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
  |> set.map(fn(to) { StdFigureMove(coord, to) })
}

/// Get all possible destinations of a rook
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_rook(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(Move) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StdFigureMove(coord, to) })
}

/// Get all possible destinations of a bishop
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_bishop(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(Move) {
  [#(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StdFigureMove(coord, to) })
}

/// Get all possible destinations of a queen
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_queen(
  board board: Board,
  coord coord: Coordinate,
  attacking_player attacker: Player,
) -> set.Set(Move) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0), #(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StdFigureMove(coord, to) })
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

/// Moves a figure on the `board`.
/// 
/// Peforms no checking wether the provided move is legal
/// 
/// If the move is happening from an empty square, then nothing happens
fn board_move(board board: Board, move move: Move) -> Board {
  case move {
    StdFigureMove(from:, to:) -> {
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
  }
}

/// Move a coordinate by a specific amount of files and rows
fn coord_move(
  coord coord: Coordinate,
  by_file by_file: Int,
  by_row by_row: Int,
) -> Option(Coordinate) {
  use new_file <- option.then(file_move(coord.file, by_file))
  use new_row <- option.then(row_move(coord.row, by_row))
  Some(Coordinate(file: new_file, row: new_row))
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

/// Short hand for the square A1
pub const coord_a1 = Coordinate(file: FileA, row: Row1)

/// Short hand for the square A2
pub const coord_a2 = Coordinate(file: FileA, row: Row2)

/// Short hand for the square A3
pub const coord_a3 = Coordinate(file: FileA, row: Row3)

/// Short hand for the square A4
pub const coord_a4 = Coordinate(file: FileA, row: Row4)

/// Short hand for the square A5
pub const coord_a5 = Coordinate(file: FileA, row: Row5)

/// Short hand for the square A6
pub const coord_a6 = Coordinate(file: FileA, row: Row6)

/// Short hand for the square A7
pub const coord_a7 = Coordinate(file: FileA, row: Row7)

/// Short hand for the square A8
pub const coord_a8 = Coordinate(file: FileA, row: Row8)

/// Short hand for the square B1
pub const coord_b1 = Coordinate(file: FileB, row: Row1)

/// Short hand for the square B2
pub const coord_b2 = Coordinate(file: FileB, row: Row2)

/// Short hand for the square B3
pub const coord_b3 = Coordinate(file: FileB, row: Row3)

/// Short hand for the square B4
pub const coord_b4 = Coordinate(file: FileB, row: Row4)

/// Short hand for the square B5
pub const coord_b5 = Coordinate(file: FileB, row: Row5)

/// Short hand for the square B6
pub const coord_b6 = Coordinate(file: FileB, row: Row6)

/// Short hand for the square B7
pub const coord_b7 = Coordinate(file: FileB, row: Row7)

/// Short hand for the square B8
pub const coord_b8 = Coordinate(file: FileB, row: Row8)

/// Short hand for the square C1
pub const coord_c1 = Coordinate(file: FileC, row: Row1)

/// Short hand for the square C2
pub const coord_c2 = Coordinate(file: FileC, row: Row2)

/// Short hand for the square C3
pub const coord_c3 = Coordinate(file: FileC, row: Row3)

/// Short hand for the square C4
pub const coord_c4 = Coordinate(file: FileC, row: Row4)

/// Short hand for the square C5
pub const coord_c5 = Coordinate(file: FileC, row: Row5)

/// Short hand for the square C6
pub const coord_c6 = Coordinate(file: FileC, row: Row6)

/// Short hand for the square C7
pub const coord_c7 = Coordinate(file: FileC, row: Row7)

/// Short hand for the square C8
pub const coord_c8 = Coordinate(file: FileC, row: Row8)

/// Short hand for the square D1
pub const coord_d1 = Coordinate(file: FileD, row: Row1)

/// Short hand for the square D2
pub const coord_d2 = Coordinate(file: FileD, row: Row2)

/// Short hand for the square D3
pub const coord_d3 = Coordinate(file: FileD, row: Row3)

/// Short hand for the square D4
pub const coord_d4 = Coordinate(file: FileD, row: Row4)

/// Short hand for the square D5
pub const coord_d5 = Coordinate(file: FileD, row: Row5)

/// Short hand for the square D6
pub const coord_d6 = Coordinate(file: FileD, row: Row6)

/// Short hand for the square D7
pub const coord_d7 = Coordinate(file: FileD, row: Row7)

/// Short hand for the square D8
pub const coord_d8 = Coordinate(file: FileD, row: Row8)

/// Short hand for the square E1
pub const coord_e1 = Coordinate(file: FileE, row: Row1)

/// Short hand for the square E2
pub const coord_e2 = Coordinate(file: FileE, row: Row2)

/// Short hand for the square E3
pub const coord_e3 = Coordinate(file: FileE, row: Row3)

/// Short hand for the square E4
pub const coord_e4 = Coordinate(file: FileE, row: Row4)

/// Short hand for the square E5
pub const coord_e5 = Coordinate(file: FileE, row: Row5)

/// Short hand for the square E6
pub const coord_e6 = Coordinate(file: FileE, row: Row6)

/// Short hand for the square E7
pub const coord_e7 = Coordinate(file: FileE, row: Row7)

/// Short hand for the square E8
pub const coord_e8 = Coordinate(file: FileE, row: Row8)

/// Short hand for the square F1
pub const coord_f1 = Coordinate(file: FileF, row: Row1)

/// Short hand for the square F2
pub const coord_f2 = Coordinate(file: FileF, row: Row2)

/// Short hand for the square F3
pub const coord_f3 = Coordinate(file: FileF, row: Row3)

/// Short hand for the square F4
pub const coord_f4 = Coordinate(file: FileF, row: Row4)

/// Short hand for the square F5
pub const coord_f5 = Coordinate(file: FileF, row: Row5)

/// Short hand for the square F6
pub const coord_f6 = Coordinate(file: FileF, row: Row6)

/// Short hand for the square F7
pub const coord_f7 = Coordinate(file: FileF, row: Row7)

/// Short hand for the square F8
pub const coord_f8 = Coordinate(file: FileF, row: Row8)

/// Short hand for the square G1
pub const coord_g1 = Coordinate(file: FileG, row: Row1)

/// Short hand for the square G2
pub const coord_g2 = Coordinate(file: FileG, row: Row2)

/// Short hand for the square G3
pub const coord_g3 = Coordinate(file: FileG, row: Row3)

/// Short hand for the square G4
pub const coord_g4 = Coordinate(file: FileG, row: Row4)

/// Short hand for the square G5
pub const coord_g5 = Coordinate(file: FileG, row: Row5)

/// Short hand for the square G6
pub const coord_g6 = Coordinate(file: FileG, row: Row6)

/// Short hand for the square G7
pub const coord_g7 = Coordinate(file: FileG, row: Row7)

/// Short hand for the square G8
pub const coord_g8 = Coordinate(file: FileG, row: Row8)

/// Short hand for the square H1
pub const coord_h1 = Coordinate(file: FileH, row: Row1)

/// Short hand for the square H2
pub const coord_h2 = Coordinate(file: FileH, row: Row2)

/// Short hand for the square H3
pub const coord_h3 = Coordinate(file: FileH, row: Row3)

/// Short hand for the square H4
pub const coord_h4 = Coordinate(file: FileH, row: Row4)

/// Short hand for the square H5
pub const coord_h5 = Coordinate(file: FileH, row: Row5)

/// Short hand for the square H6
pub const coord_h6 = Coordinate(file: FileH, row: Row6)

/// Short hand for the square H7
pub const coord_h7 = Coordinate(file: FileH, row: Row7)

/// Short hand for the square H8
pub const coord_h8 = Coordinate(file: FileH, row: Row8)
