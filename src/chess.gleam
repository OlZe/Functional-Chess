//// This is the game of chess!
//// 
//// Refer to the [README](./index.html) for an introduction and some example code.
//// 
//// Use [`new_game`](#new_game) to start a game and [`player_move`](#player_move) to make game moves!

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
/// 
/// Update with [`player_move`](#player_move).
pub opaque type GameState {
  GameState(internal: OngoingGameState, status: GameStatus)
}

/// Like `GameState` but verified its status to be `GameOngoing`
type OngoingGameState {
  OngoingGameState(board: Board, moving_player: Player)
}

/// Represents if the is game still ongoing or over.
pub type GameStatus {
  /// See [`info`](#EndCondition) to see how the game ended.
  GameEnded(info: EndCondition)

  /// Waiting for the next move by `next_player`.
  GameOngoing(next_player: Player)
}

/// Represents a way of ending the game.
pub type EndCondition {
  Victory(winner: Player, by: WinCondition)
  Draw(by: DrawCondition)
}

/// Represents a way of winning the game.
pub type WinCondition {
  /// The loser has no legal moves left, while his king is in check.
  Checkmated

  /// The loser forfeited the game.
  /// 
  /// Use the [`Move`](#Move) [`PlayerForfeits`](#Move) to end the game like this.
  Forfeited
}

/// Represents a way of drawing the game
pub type DrawCondition {
  /// Both players agreed to end the game in a draw.
  /// 
  /// Use the [`Move`](#Move) [`PlayersAgreeToDraw`](#Move) to end the game like this.
  MutualAgreement

  /// A player has no legal moves left, while his king is not in check. See [here](https://www.chess.com/terms/draw-chess#stalemate) for more info.
  Stalemated

  /// Both players are missing enough figures to checkmate the enemy king. See [here](https://www.chess.com/terms/draw-chess#dead-position) for more info.
  InsufficientMaterial

  /// The same position has been reached three times. See [here](https://www.chess.com/terms/draw-chess#threefold-repetition) for more info.
  ThreefoldRepition

  /// No pawns have been moved and no figures have been captured in 50 full-moves (which is 100 `Move`s as a full-move consists of one move of each player). See [here](https://www.chess.com/terms/draw-chess#fifty-move-rule) for more info.
  FiftyMoveRule
}

/// Represents all figure positions on a chess board.
/// 
/// `other_figures` contains all figures which are not kings.
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
/// You may use the predefined constants in the module [`chess/coordinates`](./chess/coordinates.html)
/// to quickly reference all possible chess squares.
pub type Coordinate {
  Coordinate(file: File, row: Row)
}

/// Represents a file (vertical line of squares) of a chess board.
/// 
/// From white's perspective is FileA is on the left side and FileH on the right side.
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
/// From white's perspective is Row1 on the bottom and Row8 at the top.
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

/// Represents an action a player can do.
/// 
/// To be used with [`player_move`](#player_move)
pub type Move {
  /// Forfeit the game to the opposing player.
  PlayerForfeits

  /// Draw the game through mutual agreement of both players.
  /// 
  /// Note: The user of this package is responsible for coordinating the actual
  /// draw agreement between both players.
  PlayersAgreeToDraw

  /// Player moves a figure. See [`FigureMove`](#FigureMove).
  PlayerMovesFigure(FigureMove)
}

/// Represents a move that moves a figure on the chess board.
/// 
/// To be used with [`Move`](#Move) and [`player_move`](#player_move).
/// 
/// Use [`get_moves`](#get_moves) to get a set of [`AvailableFigureMove`](#AvailableFigureMove) which directly map to this.
pub type FigureMove {
  /// Used to move a figure from `from` to `to`.
  StandardFigureMove(from: Coordinate, to: Coordinate)

  /// Used to move and promote a pawn from `from` to `to` as `new_figure`.
  /// 
  /// `new_figure` may only be Queen, Rook, Bishop or Knight.
  PawnPromotion(from: Coordinate, to: Coordinate, new_figure: Figure)

  /// Used to do an En Passant pawn move. See [here](https://www.chess.com/terms/en-passant) for more info.
  /// 
  /// For `to` use the *destination* of the pawn, *not* the square of the oppsing passing pawn that will be captured.
  EnPassant(from: Coordinate, to: Coordinate)

  /// Castle the king on the king-side.
  ShortCastle

  /// Castle the king on the queen-side.
  LongCastle
}

/// Represents an error when trying to select a figure.
pub type SelectFigureError {
  /// Tried selecting a figure from a coordinate which points to an empty square.
  SelectedFigureDoesntExist

  /// Tried selecting a figure which doesn't belong to the player.
  SelectedFigureIsNotFriendly
}

/// Return a `Board` from a `GameState`.
pub fn get_board(game game: GameState) -> Board {
  game.internal.board
}

/// Return a `GameStatus` from a `GameState`.
pub fn get_status(game game: GameState) -> GameStatus {
  game.status
}

/// Creates a new game in the standard starting chess position.
pub fn new_game() -> GameState {
  new_custom_game(board_new(), White)
}

/// Create a new game in the given position.
/// 
/// `first_player` decides which player goes first.
/// 
/// TODO: Add evaluation to see if the given position is legal.
pub fn new_custom_game(
  board board: Board,
  first_player player: Player,
) -> GameState {
  GameState(
    internal: OngoingGameState(board:, moving_player: player),
    status: GameOngoing(player),
  )
}

/// Represents an error returned by [`player_move`](#player_move).
pub type PlayerMoveError {
  /// Tried making a move while the game is already over.
  PlayerMoveWhileGameAlreadyOver

  /// Tried making a move with an invalid figure. See [`reason`](#SelectFigureError) for extra info.
  PlayerMoveWithInvalidFigure(reason: SelectFigureError)

  /// Tried making a move which is not legal.
  PlayerMoveIsIllegal
}

/// Let a player make a move.
/// 
/// `move` is to be constructed by yourself.
/// 
/// Use [`get_moves`](#get_moves) to get a set of [`AvailableFigureMove`](#AvailableFigureMove) which
/// provide you with enough information to construct your own [`FigureMove`](#FigureMove) for `move`.
/// 
/// Errors if the provided move is not valid/legal or the game was already over.
pub fn player_move(
  game game: GameState,
  move move: Move,
) -> Result(GameState, PlayerMoveError) {
  case game {
    GameState(_, GameEnded(_)) -> Error(PlayerMoveWhileGameAlreadyOver)
    GameState(game, GameOngoing(moving_player)) -> {
      assert game.moving_player == moving_player as critical_error_text
      case move {
        PlayerForfeits -> Ok(forfeit(game:))
        PlayersAgreeToDraw -> Ok(draw(game:))
        PlayerMovesFigure(move) -> player_move_figure(game:, move:)
      }
    }
  }
}

/// Represents an error returned by [`get_moves`](#get_moves).
pub type GetMovesError {
  /// Tried getting moves while the game is already over.
  GetMovesWhileGameAlreadyOver

  /// Tried making a move with an invalid figure. See [`reason`](#SelectFigureError) for extra info.
  GetMovesWithInvalidFigure(reason: SelectFigureError)
}

/// Represents a move a figure can do.
/// 
/// Directly maps to [`FigureMove`](#FigureMove).
/// 
/// Use [`get_moves`](#get_moves) to generate.
pub type AvailableFigureMove {
  /// The figure can go to `to`.
  /// 
  /// To execute this move use [`StandardFigureMove`](#FigureMove).
  StandardFigureMoveAvailable(to: Coordinate)

  /// The figure is a pawn and can go to `to` and promote to another figure (Queen, Rook, Bishop or Knight).
  /// 
  /// To execute this move use [`PawnPromotion`](#FigureMove).
  PawnPromotionAvailable(to: Coordinate)

  /// The figure is a pawn and can do an En Passant move, ending at `to` while capturing the opponent's passing pawn on the side.
  /// 
  /// See [here](https://www.chess.com/terms/en-passant) for more info.
  EnPassantAvailable(to: Coordinate)

  /// The figure is a king and can castle on the king-side.
  ShortCastleAvailable

  /// The figure is a king and can castle on the queen-side.
  LongCastleAvailable
}

/// Return a list of all legal moves from a selected `figure`.
/// 
/// To execute a move see [`player_move`](#player_move).
/// 
/// Errors if the game was already over or the selected `figure` doesn't exist or isn't owned by the player.
pub fn get_moves(
  game game: GameState,
  figure coord: Coordinate,
) -> Result(set.Set(AvailableFigureMove), GetMovesError) {
  case game {
    GameState(_, GameEnded(_)) -> Error(GetMovesWhileGameAlreadyOver)
    GameState(game, GameOngoing(moving_player)) -> {
      assert game.moving_player == moving_player as critical_error_text

      get_checked_moves(game:, figure: coord)
      |> result.map_error(fn(e) { GetMovesWithInvalidFigure(reason: e) })
    }
  }
}

/// Executes a `FigureMove` and checks whether it's legal as well
/// checking for an `EndCondition`.
fn player_move_figure(
  game game: OngoingGameState,
  move move: FigureMove,
) -> Result(GameState, PlayerMoveError) {
  {
    // Check if given move is legal by getting the available moves
    // from the move's from-square and checking if given move is in that set
    let available_moves =
      {
        let from = case move {
          EnPassant(from, _) -> from
          PawnPromotion(from, _, _) -> from
          StandardFigureMove(from, _) -> from
          LongCastle | ShortCastle ->
            case game.moving_player {
              White -> Coordinate(FileE, Row1)
              Black -> Coordinate(FileE, Row8)
            }
        }

        get_checked_moves(game:, figure: from)
      }
      |> result.map_error(fn(e) { PlayerMoveWithInvalidFigure(reason: e) })
    use available_moves <- result.try(available_moves)
    let is_legal = {
      // Map move to its corresponding AvailableFigureMove
      let move = case move {
        StandardFigureMove(_, to:) -> StandardFigureMoveAvailable(to:)
        PawnPromotion(_, _, to:) -> PawnPromotionAvailable(to:)
        EnPassant(_, to:) -> EnPassantAvailable(to:)
        ShortCastle -> ShortCastleAvailable
        LongCastle -> LongCastleAvailable
      }
      set.contains(available_moves, move)
    }
    use <- bool.guard(when: !is_legal, return: Error(PlayerMoveIsIllegal))

    // Do the move
    let new_game = do_move(game:, move:)

    // Check if game ended
    let new_status = {
      case is_game_ended(new_game) {
        Some(end_condition) -> GameEnded(info: end_condition)
        None -> GameOngoing(next_player: player_flip(game.moving_player))
      }
    }
    Ok(GameState(internal: new_game, status: new_status))
  }
}

/// Forfeit the game to the opposing player.
fn forfeit(game game: OngoingGameState) -> GameState {
  let winner = player_flip(game.moving_player)
  GameState(internal: game, status: GameEnded(Victory(winner:, by: Forfeited)))
}

/// Draw the game through mutual agreement of both players.
fn draw(game game: OngoingGameState) -> GameState {
  GameState(internal: game, status: GameEnded(Draw(by: MutualAgreement)))
}

/// Determines wether the player is being checked by its opponent.
fn is_in_check(game game: OngoingGameState) -> Bool {
  // Check if attackee is in check by requesting all moves of all
  // attacker pieces and seeing if any of their moves hit the king

  let attackee_king = case game.moving_player {
    White -> game.board.white_king
    Black -> game.board.black_king
  }
  let attacker = player_flip(game.moving_player)

  // A king can never be checked by the opponent's king,
  // thus iterating only over board.other_figures is sufficient
  game.board.other_figures
  |> dict.to_list
  // Find all pieces belonging to attacker
  |> list.filter(fn(coord_and_figure) { coord_and_figure.1.1 == attacker })
  |> list.map(fn(coord_and_figure) { coord_and_figure.0 })
  // Get all attacker moves
  |> list.flat_map(fn(coord) {
    // get_unchecked_moves(board, coord, attacker, previous_state)
    get_unchecked_moves(
      OngoingGameState(..game, moving_player: attacker),
      coord,
    )
    |> result.map(set.to_list)
    |> result.unwrap([])
  })
  // Get all attacked squares
  |> list.filter_map(fn(move) {
    case move {
      // En Passant can never hit the king
      EnPassantAvailable(_) -> Error(Nil)
      // Castling can never hit the king
      ShortCastleAvailable -> Error(Nil)
      LongCastleAvailable -> Error(Nil)
      // Pawn Promotion can hit the king
      PawnPromotionAvailable(to:) -> Ok(to)
      StandardFigureMoveAvailable(to:) -> Ok(to)
    }
  })
  // Check if any attacked squares belong to the attackee's king
  |> list.any(fn(to) { to == attackee_king })
}

// Used to check whether the board reached an end condition
fn is_game_ended(game game: OngoingGameState) -> Option(EndCondition) {
  // Check draw by insufficient material
  let ended = case is_insufficient_material(board: game.board) {
    True -> Some(Draw(by: InsufficientMaterial))
    False -> None
  }

  // Early return
  use <- option.lazy_or(ended)

  // Validate stalemate or checkmate
  let ended = is_checkmate_or_stalemate(game:)

  // Early return
  use <- option.lazy_or(ended)

  // Check threefold repetition
  let ended = case is_threefold_repetition(game:) {
    True -> Some(Draw(by: ThreefoldRepition))
    False -> None
  }

  // Early return
  use <- option.lazy_or(ended)

  // Check fifty move rule
  // let ended = case
  //   is_fifty_move_rule(board: game.board, previous_state: game.previous_state)
  // {
  //   True -> Some(Draw(by: FiftyMoveRule))
  //   False -> None
  // }

  // // Early return
  // use <- option.lazy_or(ended)

  // No end condition has been found
  None
}

/// Checks wether the `board` is a draw through insufficient material
fn is_insufficient_material(board board: Board) -> Bool {
  case dict.to_list(board.other_figures) {
    // king vs king
    [] -> True

    // king vs king and bishop
    [#(_, #(Bishop, _))] -> True

    // king vs king and knight
    [#(_, #(Knight, _))] -> True

    // king and bishop vs king and bishop (same colour)
    [#(bishop1, #(Bishop, p1)), #(bishop2, #(Bishop, p2))] if p1 != p2 -> {
      coord_colour(bishop1) == coord_colour(bishop2)
    }

    // No insufficient material
    _ -> False
  }
}

/// This function validates checkmate or stalemate together as
/// they're tightly coupled and very similar
fn is_checkmate_or_stalemate(
  game game: OngoingGameState,
) -> Option(EndCondition) {
  let opponent_player = player_flip(game.moving_player)
  let opponent_game = OngoingGameState(..game, moving_player: opponent_player)

  let opponent_has_no_moves =
    get_all_unchecked_moves(game: opponent_game)
    |> set.is_empty()

  let opponent_is_in_check = is_in_check(game: opponent_game)
  case opponent_has_no_moves, opponent_is_in_check {
    True, True -> Some(Victory(winner: game.moving_player, by: Checkmated))
    True, False -> Some(Draw(by: Stalemated))
    False, _ -> None
  }
}

// Checks if this position has been reached three times by the `player`.
// TODO:
fn is_threefold_repetition(game game: OngoingGameState) -> Bool {
  False
}

// // Checks if this position has been reached three times by the `player`.
// fn is_threefold_repetition(game game: OngoingGameState) -> Bool {
//   // We flip the player as we are interested wether the
//   // opponent now has reached a position with moves which occured three times
//   let player = player_flip(game.moving_player)
//   let game = OngoingGameState(..game, moving_player: player)

//   let position = {
//     let moves = get_all_legal_moves_on_arbitrary_board(game:)
//     #(game.board, moves)
//   }

//   position_is_reached_three_times_loop(
//     game:,
//     target_position: position,
//     count: 0,
//   )
// }

// // Checks if `target_position` has been reached three times by `player`
// fn position_is_reached_three_times_loop(
//   game game: OngoingGameState,
//   target_position target_position: #(Board, set.Set(AvailableFigureMove)),
//   count count: Int,
// ) -> Bool {
//   let position = {
//     let moves = get_all_legal_moves_on_arbitrary_board(game:)
//     #(game.board, moves)
//   }

//   let count = case position == target_position {
//     True -> count + 1
//     False -> count
//   }

//   // Early return, if threefold position was found
//   use <- bool.guard(when: count >= 3, return: True)

//   // We want the previous position for `player`, so we have
//   // to go back two positions
//   case game.previous_state {
//     // No more previous moves => no threefold repetition
//     None -> False
//     // This is the opponent's previous position, go back one more
//     Some(#(_, opp_previous_position)) ->
//       case opp_previous_position.previous_state {
//         // `player` has no previous position
//         None -> False
//         Some(#(_, previous_game)) -> {
//           // Prepare to call function with previous_game

//           // Optimization: If a figure has been captured (meaning: if the amount
//           // of figures change), then a three-fold-repetition is impossible as the
//           // amount of figures in a chess game only ever decreases.
//           let is_figure_captured = {
//             let amount_now = board_get_amount_figures(game.board)
//             let amount_previous = board_get_amount_figures(previous_game.board)
//             amount_now != amount_previous
//           }
//           use <- bool.guard(when: is_figure_captured, return: False)

//           position_is_reached_three_times_loop(
//             game: previous_game,
//             target_position:,
//             count:,
//           )
//         }
//       }
//   }
// }

// // Checks whether the fifty move rule is satisfied.
// fn is_fifty_move_rule(
//   board board: Board,
//   previous_state previous_state: Option(#(Move, OngoingGameState)),
// ) -> Bool {
//   is_fifty_move_rule_loop(current_board: board, previous_state:, counter: 0)
// }

// fn is_fifty_move_rule_loop(
//   current_board board: Board,
//   previous_state previous_state: Option(#(Move, OngoingGameState)),
//   counter counter: Int,
// ) -> Bool {
//   use <- bool.guard(when: counter >= 100, return: True)

//   case previous_state {
//     None -> False
//     Some(#(previous_move, previous_game)) -> {
//       let last_move_captured_a_figure = {
//         let amount_now = board_get_amount_figures(board)
//         let amount_prev = board_get_amount_figures(previous_game.board)
//         amount_now != amount_prev
//       }

//       // early return if the last move captured a figure
//       use <- bool.guard(when: last_move_captured_a_figure, return: False)

//       let last_move_moved_a_pawn = case previous_move {
//         // Panics are ok here because the previous move should always be a PlayerMovesFigure
//         PlayerForfeits -> panic as critical_error_text
//         PlayersAgreeToDraw -> panic as critical_error_text
//         PlayerMovesFigure(previous_move) ->
//           case previous_move {
//             EnPassant(_, _) -> True
//             PawnPromotion(_, _, _) -> True
//             LongCastle -> False
//             ShortCastle -> False
//             StandardFigureMove(from, _) ->
//               case board_get(previous_game.board, from) {
//                 Some(#(Pawn, _)) -> True
//                 _ -> False
//               }
//           }
//       }

//       // early return if the last move moved a pawn
//       use <- bool.guard(when: last_move_moved_a_pawn, return: False)

//       is_fifty_move_rule_loop(
//         current_board: previous_game.board,
//         previous_state: previous_game.previous_state,
//         counter: counter + 1,
//       )
//     }
//   }
// }

/// Retrieve all legal moves of all figures of `moving_player`
fn get_all_unchecked_moves(
  game game: OngoingGameState,
) -> set.Set(AvailableFigureMove) {
  let king = case game.moving_player {
    White -> game.board.white_king
    Black -> game.board.black_king
  }

  // Get all of moving_player's figures
  let figures =
    game.board.other_figures
    |> dict.to_list
    |> list.filter(fn(coord_and_figure) {
      coord_and_figure.1.1 == game.moving_player
    })
    |> list.map(fn(coord_and_figure) { coord_and_figure.0 })
    |> list.append([king])
    |> set.from_list()

  // Get every figure's moves
  let all_moves =
    figures
    |> set.map(fn(from) {
      get_checked_moves(game:, figure: from)
      // result.unwrap is okay here because `from` should always be valid
      |> result.lazy_unwrap(fn() { panic as critical_error_text })
    })
    // Flatten
    |> set.fold(set.new(), set.union)

  all_moves
}

/// Retrieve all legal moves of a given figure.
/// Unlike `get_moves` this doesn't require a `Game` variable
fn get_checked_moves(
  game game: OngoingGameState,
  figure coord: Coordinate,
) -> Result(set.Set(AvailableFigureMove), SelectFigureError) {
  use moves <- result.try(get_unchecked_moves(game:, figure: coord))

  // Filter moves, that leave the player in check, out
  moves
  |> set.filter(fn(move) {
    // Simulate move, then check if moving_player is in check
    let move = case move {
      StandardFigureMoveAvailable(to:) -> StandardFigureMove(from: coord, to:)
      EnPassantAvailable(to:) -> EnPassant(from: coord, to:)
      LongCastleAvailable -> LongCastle
      ShortCastleAvailable -> ShortCastle
      // It doesn't matter what we promote the pawn to, as we're only concerned
      // about whether the king is in check when the pawn moves
      PawnPromotionAvailable(to:) ->
        PawnPromotion(from: coord, to:, new_figure: Queen)
    }
    game
    |> do_move(move)
    |> is_in_check()
    |> bool.negate()
  })
  |> Ok
}

/// Retrieve all moves of a given figure.
/// 
/// Doesn't consider if moving_player's king is in check.
fn get_unchecked_moves(
  game game: OngoingGameState,
  figure coord: Coordinate,
) -> Result(set.Set(AvailableFigureMove), SelectFigureError) {
  let selected_figure =
    board_get(game.board, coord)
    |> option.to_result(SelectedFigureDoesntExist)
  use #(selected_figure, selected_figure_owner) <- result.try(selected_figure)
  use <- bool.guard(
    when: selected_figure_owner != game.moving_player,
    return: Error(SelectedFigureIsNotFriendly),
  )

  let moves = case selected_figure {
    Pawn -> get_unchecked_moves_for_pawn(game:, coord:)
    Bishop ->
      get_unchecked_moves_for_bishop(game.board, coord, game.moving_player)
    King -> get_unchecked_moves_for_king(game, coord)
    Knight ->
      get_unchecked_moves_for_knight(game.board, coord, game.moving_player)
    Queen ->
      get_unchecked_moves_for_queen(game.board, coord, game.moving_player)
    Rook -> get_unchecked_moves_for_rook(game.board, coord, game.moving_player)
  }

  Ok(moves)
}

/// Get all possible mmoves of a pawn
/// 
/// Doesn't consider if player's king is in check.
fn get_unchecked_moves_for_pawn(
  game game: OngoingGameState,
  coord coord: Coordinate,
) -> set.Set(AvailableFigureMove) {
  let up_direction = case game.moving_player {
    White -> 1
    Black -> -1
  }

  // Check move up
  let up = {
    use up <- option.then(coord_move(coord, 0, up_direction))
    case board_get(game.board, up) {
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
    let to_row = case game.moving_player {
      White -> Row4
      Black -> Row5
    }
    use up_up <- option.then(coord_move(up, 0, up_direction))
    // if 'up-up' doesn't go to 'to_row' then the pawn has moved and is disqualified
    use <- bool.guard(when: up_up.row != to_row, return: None)
    case board_get(game.board, up_up) {
      // Square empty, allow
      None -> Some(up_up)
      // Square blocked, disallow
      Some(_) -> None
    }
  }

  // Check capture up-left
  let up_left = {
    use up_left <- option.then(coord_move(coord, -1, up_direction))
    case board_get(game.board, up_left) {
      // Square empty, disallow
      None -> None
      Some(#(_, other_figure_owner)) ->
        case other_figure_owner == game.moving_player {
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
    case board_get(game.board, up_right) {
      // Square empty, disallow
      None -> None
      Some(#(_, other_figure_owner)) ->
        case other_figure_owner == game.moving_player {
          // Square blocked by friendly piece, disallow
          True -> None
          // Square blocked by opposing piece, allow
          False -> Some(up_right)
        }
    }
  }

  // Filter valid moves and check for pawn promotion
  let standard_moves =
    [up, up_up, up_left, up_right]
    |> option.values
    |> list.map(fn(to) {
      let promotion_row = case game.moving_player {
        White -> Row8
        Black -> Row1
      }
      case to {
        // Pawn promotion
        Coordinate(_, row:) if row == promotion_row ->
          PawnPromotionAvailable(to:)
        // Regular pawn move
        _ -> StandardFigureMoveAvailable(to:)
      }
    })
    |> set.from_list

  // Check for En Passant
  let en_passant_left = {
    use to_file <- option.then(file_move(coord.file, -1))
    can_en_passant(game:, coord:, to_file:)
  }

  let en_passant_right = {
    use to_file <- option.then(file_move(coord.file, 1))
    can_en_passant(game:, coord:, to_file:)
  }

  let all_moves =
    [en_passant_left, en_passant_right]
    |> option.values()
    |> set.from_list
    |> set.union(standard_moves)

  all_moves
}

// TODO:
fn can_en_passant(
  game game: OngoingGameState,
  coord coord: Coordinate,
  to_file to_file: File,
) -> Option(AvailableFigureMove) {
  None
}

// fn can_en_passant(
//   game game: OngoingGameState,
//   coord coord: Coordinate,
//   to_file to_file: File,
// ) -> Option(AvailableFigureMove) {
//   case game.previous_state {
//     None -> None
//     Some(#(previous_move, _)) -> {
//       // Opponent has to have moved his pawn acoording to required_previous_move
//       // and attacker's pawn has to be at required_attacker_coord
//       let #(
//         required_previous_move_from,
//         required_previous_move_to,
//         en_passant_from,
//         en_passant_to,
//       ) = case game.moving_player {
//         White -> #(
//           Coordinate(to_file, Row7),
//           Coordinate(to_file, Row5),
//           Coordinate(coord.file, Row5),
//           Coordinate(to_file, Row6),
//         )
//         Black -> #(
//           Coordinate(to_file, Row2),
//           Coordinate(to_file, Row4),
//           Coordinate(coord.file, Row4),
//           Coordinate(to_file, Row3),
//         )
//       }

//       // Return if the attacker's pawn is in the wrong position
//       use <- bool.guard(when: coord != en_passant_from, return: None)

//       // Return if the opponent previously didn't move double-up from his pawn home row
//       use <- bool.guard(
//         when: previous_move
//           != PlayerMovesFigure(StandardFigureMove(
//           from: required_previous_move_from,
//           to: required_previous_move_to,
//         )),
//         return: None,
//       )

//       let previous_move_was_pawn = case
//         board_get(game.board, required_previous_move_to)
//       {
//         Some(#(Pawn, _)) -> True
//         _ -> False
//       }

//       // Return if the opponent's previous move wasn't a pawn
//       use <- bool.guard(when: !previous_move_was_pawn, return: None)

//       Some(EnPassantAvailable(to: en_passant_to))
//     }
//   }
// }

/// Get all possible moves of a king
/// 
/// Doesn't consider if player's king is in check.
fn get_unchecked_moves_for_king(
  game game: OngoingGameState,
  coord coord: Coordinate,
) -> set.Set(AvailableFigureMove) {
  let standard_moves =
    [
      #(0, 1),
      #(1, 1),
      #(1, 0),
      #(1, -1),
      #(0, -1),
      #(-1, -1),
      #(-1, 0),
      #(-1, 1),
    ]
    |> set.from_list()
    |> set.map(JumpTo(origin: coord, offset: _, attacker: game.moving_player))
    |> set.map(find_visible_squares_for_a_standard_figure_move(game.board, _))
    // Flatten
    |> set.fold(set.new(), set.union)
    |> set.map(fn(to) { StandardFigureMoveAvailable(to) })

  let short_castle = case can_short_castle(game) {
    True -> Some(ShortCastleAvailable)
    False -> None
  }

  let long_castle = case can_long_castle(game) {
    True -> Some(LongCastleAvailable)
    False -> None
  }

  let all_moves =
    [short_castle, long_castle]
    |> option.values
    |> set.from_list
    |> set.union(standard_moves)

  all_moves
}

/// Checks whether the position allows for castling.
/// 
/// Also traverses entire state history to see if king or rook have ever been moved.
/// 
/// First bool is for short castle, second bool for long castle.
/// TODO:
fn can_short_castle(game game: OngoingGameState) -> Bool {
  False
}

// fn can_short_castle(game game: OngoingGameState) -> Bool {
//   let board = game.board
//   let moving_player = game.moving_player
//   let previous_state = game.previous_state

//   let row = case moving_player {
//     White -> Row1
//     Black -> Row8
//   }

//   let king_from = Coordinate(FileE, row)
//   let king_to = Coordinate(FileG, row)
//   let rook_from = Coordinate(FileH, row)
//   let rook_to = Coordinate(FileF, row)

//   let figures_are_in_position = {
//     // King in position
//     use <- bool.guard(
//       when: board_get(board, king_from) != Some(#(King, moving_player)),
//       return: False,
//     )
//     // King destination is free
//     use <- bool.guard(when: board_get(board, king_to) != None, return: False)
//     // Rook in position
//     use <- bool.guard(
//       when: board_get(board, rook_from) != Some(#(Rook, moving_player)),
//       return: False,
//     )
//     // Rook destination is free
//     use <- bool.guard(when: board_get(board, rook_to) != None, return: False)
//     True
//   }

//   use <- bool.guard(when: !figures_are_in_position, return: False)

//   // Check that player doesn't castle from, through, or into a check
//   let goes_through_check = {
//     [king_from, rook_to, king_to]
//     |> list.map(StandardFigureMove(king_from, _))
//     |> list.map(execute_move(game, _))
//     |> list.any(is_in_check)
//   }

//   use <- bool.guard(when: goes_through_check, return: False)

//   // Go through entire state history to find whether king or rook have ever moved
//   king_and_rook_have_never_moved(king_from, rook_from, previous_state)
// }

// TODO:
fn can_long_castle(game game: OngoingGameState) -> Bool {
  False
}

// fn can_long_castle(game game: OngoingGameState) -> Bool {
//   let board = game.board
//   let moving_player = game.moving_player
//   let previous_state = game.previous_state

//   let row = case moving_player {
//     White -> Row1
//     Black -> Row8
//   }

//   let king_from = Coordinate(FileE, row)
//   let king_to = Coordinate(FileC, row)
//   let rook_from = Coordinate(FileA, row)
//   let rook_to = Coordinate(FileD, row)
//   let inbetween = Coordinate(FileB, row)

//   let figures_are_in_position = {
//     // King is in position
//     use <- bool.guard(
//       when: board_get(board, king_from) != Some(#(King, moving_player)),
//       return: False,
//     )
//     // King destination is free
//     use <- bool.guard(when: board_get(board, king_to) != None, return: False)
//     // Rook is in position
//     use <- bool.guard(
//       when: board_get(board, rook_from) != Some(#(Rook, moving_player)),
//       return: False,
//     )
//     // Rook destination is free
//     use <- bool.guard(when: board_get(board, rook_to) != None, return: False)
//     // Inbetween square is free
//     use <- bool.guard(when: board_get(board, inbetween) != None, return: False)
//     True
//   }

//   use <- bool.guard(when: !figures_are_in_position, return: False)

//   // Check that player doesn't castle from, through, or into a check
//   let goes_through_check = {
//     [king_from, rook_to, king_to]
//     |> list.map(StandardFigureMove(king_from, _))
//     |> list.map(execute_move(game, _))
//     |> list.any(is_in_check)
//   }

//   use <- bool.guard(when: goes_through_check, return: False)

//   // Go through entire state history to find whether king or rook have ever moved
//   king_and_rook_have_never_moved(king_from, rook_from, previous_state)
// }

// fn king_and_rook_have_never_moved(
//   king_start_coord king: Coordinate,
//   rook_start_coord rook: Coordinate,
//   previous_state previous_state: Option(#(Move, OngoingGameState)),
// ) -> Bool {
//   // Recursively traverse entire state history and check for every
//   // state, that king and rook are in their right positions.
//   case previous_state {
//     // base case, no more previous states
//     None -> True
//     Some(#(_, previous_game)) -> {
//       let king_in_position = case board_get(previous_game.board, king) {
//         Some(#(King, _)) -> True
//         _ -> False
//       }

//       let rook_in_position = case board_get(previous_game.board, rook) {
//         Some(#(Rook, _)) -> True
//         _ -> False
//       }

//       // base case, king and rook have moved
//       use <- bool.guard(
//         when: !king_in_position || !rook_in_position,
//         return: False,
//       )

//       // king and rook look good so far. keep exploring the history.
//       king_and_rook_have_never_moved(king, rook, previous_game.previous_state)
//     }
//   }
// }

/// Get all possible moves of a knight
/// 
/// Doesn't consider if player's king is in check.
fn get_unchecked_moves_for_knight(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(AvailableFigureMove) {
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
  |> set.map(find_visible_squares_for_a_standard_figure_move(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StandardFigureMoveAvailable(to:) })
}

/// Get all possible moves of a rook
/// 
/// Doesn't consider if player's king is in check.
fn get_unchecked_moves_for_rook(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(AvailableFigureMove) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(find_visible_squares_for_a_standard_figure_move(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StandardFigureMoveAvailable(to:) })
}

/// Get all possible moves of a bishop
/// 
/// Doesn't consider if player's king is in check.
fn get_unchecked_moves_for_bishop(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(AvailableFigureMove) {
  [#(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(find_visible_squares_for_a_standard_figure_move(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StandardFigureMoveAvailable(to) })
}

/// Get all possible moves of a queen
/// 
/// Doesn't consider if player's king is in check.
fn get_unchecked_moves_for_queen(
  board board: Board,
  coord coord: Coordinate,
  attacking_player attacker: Player,
) -> set.Set(AvailableFigureMove) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0), #(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(find_visible_squares_for_a_standard_figure_move(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StandardFigureMoveAvailable(to:) })
}

/// Used to describe the nature of a regular figure's movement abilities
type StandardMoveDescription {
  JumpTo(origin: Coordinate, offset: #(Int, Int), attacker: Player)
  LineOfSight(origin: Coordinate, direction: #(Int, Int), attacker: Player)
}

/// Use the move_description to find which squares the figure can go to
fn find_visible_squares_for_a_standard_figure_move(
  board board: Board,
  move_description move_description: StandardMoveDescription,
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
    white_king: Coordinate(FileE, Row1),
    black_king: Coordinate(FileE, Row8),
    other_figures: dict.from_list([
      #(Coordinate(FileA, Row1), #(Rook, White)),
      #(Coordinate(FileB, Row1), #(Knight, White)),
      #(Coordinate(FileC, Row1), #(Bishop, White)),
      #(Coordinate(FileD, Row1), #(Queen, White)),
      #(Coordinate(FileF, Row1), #(Bishop, White)),
      #(Coordinate(FileG, Row1), #(Knight, White)),
      #(Coordinate(FileH, Row1), #(Rook, White)),
      #(Coordinate(FileA, Row2), #(Pawn, White)),
      #(Coordinate(FileB, Row2), #(Pawn, White)),
      #(Coordinate(FileC, Row2), #(Pawn, White)),
      #(Coordinate(FileD, Row2), #(Pawn, White)),
      #(Coordinate(FileE, Row2), #(Pawn, White)),
      #(Coordinate(FileF, Row2), #(Pawn, White)),
      #(Coordinate(FileG, Row2), #(Pawn, White)),
      #(Coordinate(FileH, Row2), #(Pawn, White)),
      #(Coordinate(FileA, Row8), #(Rook, Black)),
      #(Coordinate(FileB, Row8), #(Knight, Black)),
      #(Coordinate(FileC, Row8), #(Bishop, Black)),
      #(Coordinate(FileD, Row8), #(Queen, Black)),
      #(Coordinate(FileF, Row8), #(Bishop, Black)),
      #(Coordinate(FileG, Row8), #(Knight, Black)),
      #(Coordinate(FileH, Row8), #(Rook, Black)),
      #(Coordinate(FileA, Row7), #(Pawn, Black)),
      #(Coordinate(FileB, Row7), #(Pawn, Black)),
      #(Coordinate(FileC, Row7), #(Pawn, Black)),
      #(Coordinate(FileD, Row7), #(Pawn, Black)),
      #(Coordinate(FileE, Row7), #(Pawn, Black)),
      #(Coordinate(FileF, Row7), #(Pawn, Black)),
      #(Coordinate(FileG, Row7), #(Pawn, Black)),
      #(Coordinate(FileH, Row7), #(Pawn, Black)),
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

/// Returns how many figures on the board are in play.
/// 
/// Includes both kings.
fn board_get_amount_figures(board board: Board) -> Int {
  dict.size(board.other_figures) + 2
}

/// Execute a `FigureMove`.
/// 
/// Peforms no checking wether the provided move is legal. Overrides other figures at the move's destination.
/// 
/// WARNING: Panics if the move is invalid (moving from an empty square, promoting from a non-pawn, ...)
fn do_move(
  game game: OngoingGameState,
  move move: FigureMove,
) -> OngoingGameState {
  let board = game.board
  let moving_player = game.moving_player

  let new_board = case move {
    StandardFigureMove(from:, to:) -> {
      case board {
        // Move white king
        Board(white_king:, black_king:, other_figures:) if white_king == from ->
          Board(
            white_king: to,
            black_king:,
            other_figures: dict.delete(other_figures, to),
          )

        // Move black king
        Board(white_king:, black_king:, other_figures:) if black_king == from ->
          Board(
            white_king:,
            black_king: to,
            other_figures: dict.delete(other_figures, to),
          )

        // Move another piece
        Board(white_king:, black_king:, other_figures:) -> {
          let assert Ok(moving_figure) = dict.get(other_figures, from)
            as critical_error_text

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
    PawnPromotion(from:, to:, new_figure:) -> {
      assert board_get(board, from) == Some(#(Pawn, moving_player))
        as critical_error_text

      Board(
        white_king: board.white_king,
        black_king: board.black_king,
        other_figures: board.other_figures
          |> dict.delete(from)
          |> dict.insert(to, #(new_figure, moving_player)),
      )
    }
    EnPassant(from:, to:) -> {
      let capturing_square = Coordinate(file: to.file, row: from.row)

      assert board_get(board, from) == Some(#(Pawn, moving_player))
        as critical_error_text

      assert board_get(board, capturing_square)
        == Some(#(Pawn, player_flip(moving_player)))
        as critical_error_text

      assert board_get(board, to) == None as critical_error_text

      Board(
        white_king: board.white_king,
        black_king: board.black_king,
        other_figures: board.other_figures
          |> dict.delete(from)
          |> dict.delete(capturing_square)
          |> dict.insert(to, #(Pawn, moving_player)),
      )
    }
    ShortCastle -> {
      let row = case moving_player {
        White -> Row1
        Black -> Row8
      }
      let king_from = Coordinate(FileE, row)
      let king_to = Coordinate(FileG, row)
      let rook_from = Coordinate(FileH, row)
      let rook_to = Coordinate(FileF, row)

      assert board_get(board, king_from) == Some(#(King, moving_player))
        as critical_error_text
      assert board_get(board, king_to) == None as critical_error_text
      assert board_get(board, rook_from) == Some(#(Rook, moving_player))
        as critical_error_text
      assert board_get(board, rook_to) == None as critical_error_text

      case moving_player {
        White ->
          Board(
            white_king: king_to,
            black_king: board.black_king,
            other_figures: board.other_figures
              |> dict.delete(rook_from)
              |> dict.insert(rook_to, #(Rook, moving_player)),
          )
        Black ->
          Board(
            white_king: board.white_king,
            black_king: king_to,
            other_figures: board.other_figures
              |> dict.delete(rook_from)
              |> dict.insert(rook_to, #(Rook, moving_player)),
          )
      }
    }
    LongCastle -> {
      let row = case moving_player {
        White -> Row1
        Black -> Row8
      }
      let king_from = Coordinate(FileE, row)
      let king_to = Coordinate(FileC, row)
      let rook_from = Coordinate(FileA, row)
      let rook_to = Coordinate(FileD, row)
      let inbetween = Coordinate(FileB, row)

      assert board_get(board, king_from) == Some(#(King, moving_player))
        as critical_error_text
      assert board_get(board, king_to) == None as critical_error_text
      assert board_get(board, rook_from) == Some(#(Rook, moving_player))
        as critical_error_text
      assert board_get(board, rook_to) == None as critical_error_text
      assert board_get(board, inbetween) == None as critical_error_text

      case moving_player {
        White ->
          Board(
            white_king: king_to,
            black_king: board.black_king,
            other_figures: board.other_figures
              |> dict.delete(rook_from)
              |> dict.insert(rook_to, #(Rook, moving_player)),
          )
        Black ->
          Board(
            white_king: board.white_king,
            black_king: king_to,
            other_figures: board.other_figures
              |> dict.delete(rook_from)
              |> dict.insert(rook_to, #(Rook, moving_player)),
          )
      }
    }
  }

  OngoingGameState(..game, board: new_board)
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

type CoordinateColour {
  LightSquare
  DarkSquare
}

/// Get wether the referred square is dark or light squared
fn coord_colour(coord coord: Coordinate) -> CoordinateColour {
  let file_index = case coord.file {
    FileA -> 0
    FileB -> 1
    FileC -> 2
    FileD -> 3
    FileE -> 4
    FileF -> 5
    FileG -> 6
    FileH -> 7
  }
  let row_index = case coord.row {
    Row1 -> 0
    Row2 -> 1
    Row3 -> 2
    Row4 -> 3
    Row5 -> 4
    Row6 -> 5
    Row7 -> 6
    Row8 -> 7
  }
  case { file_index + row_index } % 2 {
    0 -> DarkSquare
    1 -> LightSquare
    _ -> panic
  }
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

fn player_flip(player player: Player) -> Player {
  case player {
    Black -> White
    White -> Black
  }
}

const critical_error_text = "Critical internal error!\n"
  <> "This is not your fault (unless you mutated the internal state!).\n"
  <> "If you see this message then this likely means, that something in this package's logic is incorrect.\n"
  <> "Please open an issue at https://github.com/OlZe/Functional-Chess with a detailled description to help improve this package.\n"
  <> "Sorry for the inconvience."
