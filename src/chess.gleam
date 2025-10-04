//// This is the main module which provides all of the necessary functionality to play chess.
//// 
//// Refer to the `README` page for an introduction and some example code.

import chess/internal/counter
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
/// Use `new_game` or `new_custom_game` to generate.
/// 
/// Update with `player_move`.
pub opaque type GameState {
  GameState(
    internal: OngoingGameState,
    history: List(#(FigureMove, Player)),
    status: GameStatus,
    starting_position: OngoingGameState,
  )
}

/// Game state, which is verified to not have ended.
type OngoingGameState {
  OngoingGameState(
    board: Board,
    moving_player: Player,
    /// `File` says in which file the opponent just double-moved a pawn
    en_passant_possible: Option(File),
    short_castle_disqualified_white: Bool,
    long_castle_disqualified_white: Bool,
    short_castle_disqualified_black: Bool,
    long_castle_disqualified_black: Bool,
    fifty_move_rule_counter: Int,
    threefold_repetition_counter: counter.Counter(ThreefoldRepetitionPosition),
  )
}

type ThreefoldRepetitionPosition {
  ThreefoldRepetitionPosition(
    board: Board,
    moving_player: Player,
    en_passant_possible: Option(File),
    short_castle_disqualified_white: Bool,
    long_castle_disqualified_white: Bool,
    short_castle_disqualified_black: Bool,
    long_castle_disqualified_black: Bool,
  )
}

/// Represents if the is game still ongoing or over.
/// 
/// Use `get_status` to retrieve.
pub type GameStatus {
  /// See `info` to see how the game ended.
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
  /// Use the `Move` `PlayerForfeits` to end the game like this.
  Forfeited
}

/// Represents a way of drawing the game
pub type DrawCondition {
  /// Both players agreed to end the game in a draw.
  /// 
  /// Use the `Move` `PlayersAgreeToDraw` to end the game like this.
  MutualAgreement

  /// A player has no legal moves left, while his king is not in check. See [here](https://www.chess.com/terms/draw-chess#stalemate) for more info.
  Stalemated

  /// Both players are missing enough figures to checkmate the enemy king. See [here](https://www.chess.com/terms/draw-chess#dead-position) for more info.
  InsufficientMaterial

  /// The same position has been reached three times. See [here](https://www.chess.com/terms/draw-chess#threefold-repetition) for more info.
  ThreefoldRepition

  /// No pawns have been moved and no figures have been captured in 50 full-moves (which equate to 100 calls to `player_move` as in chess-tmers a full-move consists of one move for each player).
  /// 
  /// See [here](https://www.chess.com/terms/draw-chess#fifty-move-rule) for more info.
  FiftyMoveRule
}

/// Represents all figure positions on a chess board.
/// 
/// `other_figures` contains all figures which are not kings.
/// 
/// Use `get_board` to retrieve.
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
/// You may use the predefined constants in the module `chess/coordinates`
/// to quickly reference all possible chess squares.
pub type Coordinate {
  Coordinate(file: File, row: Row)
}

/// Represents a file (vertical line of squares) of a chess board.
/// 
/// From white's perspective is `FileA` is on the left side and `FileH` on the right side.
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
/// From white's perspective is `Row1` on the bottom and `Row8` at the top.
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
/// To be used with `player_move`.
pub type Move {
  /// Forfeit the game to the opposing player.
  PlayerForfeits

  /// Draw the game through mutual agreement of both players.
  /// 
  /// Note: The user of this package is responsible for coordinating the actual
  /// draw agreement between both players.
  PlayersAgreeToDraw

  /// Player moves a figure. See `FigureMove`.
  PlayerMovesFigure(FigureMove)
}

/// Represents a move that moves a figure on the chess board.
/// 
/// To be used with `Move` and `player_move`.
/// 
/// Use `get_moves` or `get_all_moves` to get a set of `AvailableFigureMove` which directly map to this.
pub type FigureMove {
  /// Used to move a figure from `from` to `to`.
  StandardFigureMove(from: Coordinate, to: Coordinate)

  /// Used to move and promote a pawn from `from` to `to` as `new_figure`.
  /// 
  /// `new_figure` may only be Queen, Rook, Bishop or Knight.
  PawnPromotion(from: Coordinate, to: Coordinate, new_figure: Figure)

  /// Used to do an En Passant pawn move.
  /// 
  /// For `to` use the *destination* of the pawn, *not* the square of the oppsing passing pawn that will be captured.
  EnPassant(from: Coordinate, to: Coordinate)

  /// Used to castle the king on the king-side.
  ShortCastle

  /// Used to castle the king on the queen-side.
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

/// Returns a history of moves along with which player did them.
/// 
/// The first element is the first move played in the game and the last element is the previously played move.
pub fn get_history(game game: GameState) -> List(#(FigureMove, Player)) {
  game.history
}

/// Creates a new game in the standard starting chess position.
pub fn new_game() -> GameState {
  let state =
    OngoingGameState(
      board: board_new(),
      moving_player: White,
      en_passant_possible: None,
      short_castle_disqualified_white: False,
      long_castle_disqualified_white: False,
      short_castle_disqualified_black: False,
      long_castle_disqualified_black: False,
      fifty_move_rule_counter: 0,
      threefold_repetition_counter: counter.new(),
    )

  GameState(
    internal: state,
    status: GameOngoing(White),
    history: [],
    starting_position: state,
  )
}

/// Represents an error returned by `new_custom_game`.
pub type NewCustomGameError {
  /// Tried to create a game, where pawns are on the final row.
  /// 
  /// This is illegal, as these pawns would have promoted and are now stuck instead.
  /// 
  /// See `pawns` for a list of coordinates pointing to the culprits.
  PawnsOnFinalRank(pawns: set.Set(Coordinate))

  /// Tried to create a game, where the first-moving player is already checking
  /// the enemy king.
  /// 
  /// This is illegal as it would allow the first-moving player to "capture" the king.
  EnemyIsInCheck
}

/// Create a new game in the given position.
/// 
/// `first_player` decides which player goes first.
/// 
/// Allows for castling if kings and rooks are in their standard positions.
/// 
/// Errors if the provided position is an illegal starting position.
pub fn new_custom_game(
  board board: Board,
  first_player player: Player,
) -> Result(GameState, NewCustomGameError) {
  // Check for un-promoted pawns on final ranks
  let bad_pawns =
    [FileA, FileB, FileC, FileD, FileE, FileF, FileG, FileH]
    // Get pawn pawn coords
    |> list.flat_map(fn(file) {
      [#(Coordinate(file, Row8), White), #(Coordinate(file, Row1), Black)]
    })
    // Check board for bad pawn coords
    |> list.filter(fn(coord_and_player) {
      board_get(board, coord_and_player.0) == Some(#(Pawn, coord_and_player.1))
    })
    |> list.map(fn(coord_and_player) { coord_and_player.0 })
    |> set.from_list()

  use <- bool.guard(
    when: !set.is_empty(bad_pawns),
    return: Error(PawnsOnFinalRank(bad_pawns)),
  )

  // Check castling rights
  let #(white_short_castle, white_long_castle) = {
    use <- bool.guard(
      when: board.white_king != Coordinate(FileE, Row1),
      return: #(False, False),
    )
    let shrt = board_get(board, Coordinate(FileH, Row1)) == Some(#(Rook, White))
    let long = board_get(board, Coordinate(FileA, Row1)) == Some(#(Rook, White))
    #(shrt, long)
  }

  let #(black_short_castle, black_long_castle) = {
    use <- bool.guard(
      when: board.black_king != Coordinate(FileE, Row8),
      return: #(False, False),
    )
    let shrt = board_get(board, Coordinate(FileH, Row8)) == Some(#(Rook, Black))
    let long = board_get(board, Coordinate(FileA, Row8)) == Some(#(Rook, Black))
    #(shrt, long)
  }

  // Build game
  let state =
    OngoingGameState(
      board:,
      moving_player: player,
      en_passant_possible: None,
      short_castle_disqualified_white: !white_short_castle,
      long_castle_disqualified_white: !white_long_castle,
      short_castle_disqualified_black: !black_short_castle,
      long_castle_disqualified_black: !black_long_castle,
      fifty_move_rule_counter: 0,
      threefold_repetition_counter: counter.new(),
    )

  let game =
    GameState(
      internal: state,
      status: GameOngoing(player),
      history: [],
      starting_position: state,
    )

  // Check if enemy is in check
  let enemy_is_in_check =
    is_in_check_internal(
      OngoingGameState(..game.internal, moving_player: player_flip(player)),
    )

  use <- bool.guard(when: enemy_is_in_check, return: Error(EnemyIsInCheck))

  Ok(game)
}

/// Represents an error returned by `player_move`.
pub type PlayerMoveError {
  /// Tried making a move while the game is already over.
  PlayerMoveWhileGameAlreadyOver

  /// Tried making a move with an invalid figure. See `reason` for extra info.
  PlayerMoveWithInvalidFigure(reason: SelectFigureError)

  /// Tried making a move which is not legal.
  PlayerMoveIsIllegal
}

/// Let a player make a move.
/// 
/// `move` is to be constructed by yourself.
/// 
/// Use `get_moves` or `get_all_moves` to get a set of `AvailableFigureMove` which
/// provide you with enough information to construct your own `FigureMove` for `move`.
/// 
/// Errors if the provided move is not valid/legal or the game was already over.
pub fn player_move(
  game game: GameState,
  move move: Move,
) -> Result(GameState, PlayerMoveError) {
  case game {
    GameState(status: GameEnded(_), ..) -> Error(PlayerMoveWhileGameAlreadyOver)
    GameState(status: GameOngoing(moving_player), internal: internal_game, ..) -> {
      assert internal_game.moving_player == moving_player as critical_error_text
      case move {
        PlayerForfeits ->
          Ok(
            GameState(
              ..game,
              status: GameEnded(Victory(
                winner: player_flip(moving_player),
                by: Forfeited,
              )),
            ),
          )
        PlayersAgreeToDraw ->
          Ok(GameState(..game, status: GameEnded(Draw(MutualAgreement))))
        PlayerMovesFigure(move) -> {
          use #(new_internal_game, new_status) <- result.try(
            player_move_internal(game: internal_game, move:),
          )
          Ok(GameState(
            internal: new_internal_game,
            history: game.history |> list.append([#(move, moving_player)]),
            status: new_status,
            starting_position: game.starting_position,
          ))
        }
      }
    }
  }
}

/// Represents an error returned by `get_moves`.
pub type GetMovesError {
  /// Tried getting moves while the game is already over.
  GetMovesWhileGameAlreadyOver

  /// Tried making a move with an invalid figure. See `reason` for extra info.
  GetMovesWithInvalidFigure(reason: SelectFigureError)
}

/// Represents a move a figure can do.
/// 
/// Directly maps to `FigureMove`.
/// 
/// Use `get_moves` or `get_all_moves` to generate.
pub type AvailableFigureMove {
  /// The figure can go to `to`.
  /// 
  /// To execute this move use `StandardFigureMove`.
  StandardFigureMoveAvailable(to: Coordinate)

  /// The figure is a pawn and can go to `to` and promote to another figure (Queen, Rook, Bishop or Knight).
  /// 
  /// To execute this move use `PawnPromotion`.
  PawnPromotionAvailable(to: Coordinate)

  /// The figure is a pawn and can do an En Passant move, ending at `to` while capturing the opponent's passing pawn on the side.
  /// 
  /// To execute this move use `EnPassant`.
  EnPassantAvailable(to: Coordinate)

  /// The figure is a king and can castle on the king-side.
  /// 
  /// To execute this move use `ShortCastle`.
  ShortCastleAvailable

  /// The figure is a king and can castle on the queen-side.
  /// 
  /// To execute this move use `LongCastle`.
  LongCastleAvailable
}

/// Return a list of all legal moves of a figure on `from`.
/// 
/// To execute a move see `player_move`.
/// 
/// Errors if the game was already over or the selected figure doesn't exist or doesn't belong to the player.
pub fn get_moves(
  game game: GameState,
  from coord: Coordinate,
) -> Result(set.Set(AvailableFigureMove), GetMovesError) {
  case game {
    GameState(status: GameEnded(_), ..) -> Error(GetMovesWhileGameAlreadyOver)
    GameState(status: GameOngoing(moving_player), internal: game, ..) -> {
      assert game.moving_player == moving_player as critical_error_text

      get_moves_internal(game:, figure: coord)
      |> result.map_error(fn(e) { GetMovesWithInvalidFigure(reason: e) })
    }
  }
}

/// Return a list of all legal moves of all figures of the moving player.
/// 
/// To execute a move see `player_move`.
/// 
/// Returns pairs of `Coordinate` and multiple `AvailableFigureMove`. `Coordinate` refers to the
/// figure and the set of `AvailableFigureMove` to the moves that this figure can do.
/// 
/// Errors if the game was already over.
pub fn get_all_moves(
  game game: GameState,
) -> Result(dict.Dict(Coordinate, set.Set(AvailableFigureMove)), Nil) {
  case game {
    GameState(status: GameEnded(_), ..) -> Error(Nil)
    GameState(status: GameOngoing(moving_player), internal: game, ..) -> {
      assert game.moving_player == moving_player as critical_error_text

      Ok(get_all_moves_internal(game:))
    }
  }
}

/// Represent an error returned by `get_past_position`.
pub type GetPastPositionError {
  /// Tried to get a past position with a negative move number.
  GetPastPositionWithNegativeMoveNumber(passed_move_number: Int)

  /// Tried to get a past position with a move number that exceeds the
  /// length of the current game's history.
  GetPastPositionWithMoveNumberExceedingHistory(
    passed_move_number: Int,
    allowed_maximum_move_number: Int,
  )
}

/// Retrieve a past board position from a `game` according to its move history.
/// 
/// Note that the term `move` does not apply to the chess term *full-move*, rather
/// it is a *half-move* or a *ply*, which are done by one player only.
/// 
/// A `move_number` of 0 returns the initial starting position.
/// 
/// A `move_number` of 1 returns the position after the first *half-move*.
/// 
/// Errors if `move_number` is negative or larger than the `game`'s history.
pub fn get_past_position(
  game game: GameState,
  move_number move_number: Int,
) -> Result(GameState, GetPastPositionError) {
  use <- bool.guard(
    when: move_number < 0,
    return: Error(GetPastPositionWithNegativeMoveNumber(
      passed_move_number: move_number,
    )),
  )

  let max_move_number = list.length(game.history)
  use <- bool.guard(
    when: move_number > max_move_number,
    return: Error(GetPastPositionWithMoveNumberExceedingHistory(
      passed_move_number: move_number,
      allowed_maximum_move_number: max_move_number,
    )),
  )

  let init_game =
    GameState(
      internal: game.starting_position,
      history: [],
      status: GameOngoing(game.starting_position.moving_player),
      starting_position: game.starting_position,
    )

  game.history
  |> list.take(move_number)
  |> list.fold(init_game, fn(game, move) {
    let #(move, moving_player) = move
    assert game.status == GameOngoing(moving_player) as critical_error_text

    let assert Ok(game) = player_move(game:, move: PlayerMovesFigure(move))
    game
  })
  |> Ok
}

/// Determines whether the player's king is in check by the opponent.
pub fn is_in_check(game game: GameState) -> Bool {
  is_in_check_internal(game.internal)
}

/// Executes a `FigureMove` and checks whether it's legal as well
/// checking for an `EndCondition`.
fn player_move_internal(
  game game: OngoingGameState,
  move move: FigureMove,
) -> Result(#(OngoingGameState, GameStatus), PlayerMoveError) {
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

        get_moves_internal(game:, figure: from)
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
        None -> GameOngoing(next_player: player_flip(new_game.moving_player))
      }
    }

    // Don't forget to flip the player on the internal game state too
    let new_game =
      OngoingGameState(
        ..new_game,
        moving_player: player_flip(new_game.moving_player),
      )

    Ok(#(new_game, new_status))
  }
}

/// Determines whether the player is being checked by its opponent.
fn is_in_check_internal(game game: OngoingGameState) -> Bool {
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
  let ended = case is_fifty_move_rule(game:) {
    True -> Some(Draw(by: FiftyMoveRule))
    False -> None
  }
  // Early return
  use <- option.lazy_or(ended)

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
    get_all_moves_internal(game: opponent_game)
    |> dict.is_empty()

  let opponent_is_in_check = is_in_check_internal(game: opponent_game)
  case opponent_has_no_moves, opponent_is_in_check {
    True, True -> Some(Victory(winner: game.moving_player, by: Checkmated))
    True, False -> Some(Draw(by: Stalemated))
    False, _ -> None
  }
}

// Checks if this position has been reached for the third time now.
fn is_threefold_repetition(game game: OngoingGameState) -> Bool {
  // Flip player, as it's the opponent's next and it would be a threefold
  // repetition from his piont of view.

  let game =
    OngoingGameState(..game, moving_player: player_flip(game.moving_player))

  let position = get_threefold_repetition_position_from_game(game:)

  game.threefold_repetition_counter
  |> counter.get(position)
  // If this position is 2 times in the history, then it has now been
  // reached for the third time
  >= 2
}

// Checks whether the fifty move rule is satisfied.
fn is_fifty_move_rule(game game: OngoingGameState) -> Bool {
  // We check for 100 as the fifty move rule refers to white+black move combos
  game.fifty_move_rule_counter >= 100
}

/// Retrieve all legal moves of all figures of `moving_player`
fn get_all_moves_internal(
  game game: OngoingGameState,
) -> dict.Dict(Coordinate, set.Set(AvailableFigureMove)) {
  let king = case game.moving_player {
    White -> game.board.white_king
    Black -> game.board.black_king
  }

  // Get all of moving_player's figures
  let figure_coords =
    game.board.other_figures
    |> dict.to_list
    |> list.filter_map(fn(coord_and_figure) {
      let #(coord, #(_, player)) = coord_and_figure
      case player == game.moving_player {
        True -> Ok(coord)
        False -> Error(Nil)
      }
    })
    |> list.append([king])

  // Get every figure's moves
  let all_moves =
    figure_coords
    |> list.map(fn(from) {
      let moves =
        get_moves_internal(game:, figure: from)
        // result.unwrap is okay here because `from` should always be valid
        |> result.lazy_unwrap(fn() { panic as critical_error_text })

      #(from, moves)
    })
    // Remove figures which have no moves
    |> list.filter(fn(from_and_moves) {
      let #(_, moves) = from_and_moves
      !set.is_empty(moves)
    })
    |> dict.from_list

  all_moves
}

/// Retrieve all legal moves of a given figure.
/// Unlike `get_moves` this doesn't require a `Game` variable
fn get_moves_internal(
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
    |> is_in_check_internal()
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
  let en_passant = can_en_passant(game:, coord:)

  let all_moves =
    [en_passant]
    |> option.values()
    |> set.from_list
    |> set.union(standard_moves)

  all_moves
}

fn can_en_passant(
  game game: OngoingGameState,
  coord pawn_pos: Coordinate,
) -> Option(AvailableFigureMove) {
  use to_file <- option.then(game.en_passant_possible)

  // Check en passant from left and right file
  [file_move(to_file, -1), file_move(to_file, 1)]
  |> option.values()
  |> list.find_map(fn(from_file) {
    let #(en_passant_from, en_passant_to) = {
      case game.moving_player {
        White -> #(Coordinate(from_file, Row5), Coordinate(to_file, Row6))
        Black -> #(Coordinate(from_file, Row4), Coordinate(to_file, Row3))
      }
    }
    case pawn_pos == en_passant_from {
      True -> Ok(EnPassantAvailable(to: en_passant_to))
      False -> Error(Nil)
    }
  })
  |> option.from_result
}

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

/// Checks whether the position allows for short castling.
fn can_short_castle(game game: OngoingGameState) -> Bool {
  case game.moving_player {
    White -> {
      use <- bool.guard(
        when: game.short_castle_disqualified_white,
        return: False,
      )

      // assertions are okay, as when the king or rook moves, the
      // previously checked disqualifier flag should cause an early return.
      assert board_get(game.board, Coordinate(FileE, Row1))
        == Some(#(King, White))
        as critical_error_text

      assert board_get(game.board, Coordinate(FileH, Row1))
        == Some(#(Rook, White))
        as critical_error_text

      can_castle_helper(
        game:,
        required_empty: [Coordinate(FileF, Row1), Coordinate(FileG, Row1)],
        required_not_in_check: [
          Coordinate(FileE, Row1),
          Coordinate(FileF, Row1),
          Coordinate(FileG, Row1),
        ],
      )
    }
    Black -> {
      use <- bool.guard(
        when: game.short_castle_disqualified_black,
        return: False,
      )

      // assertions are okay, as when the king or rook moves, the
      // previously checked disqualifier flag should cause an early return.
      assert board_get(game.board, Coordinate(FileE, Row8))
        == Some(#(King, Black))
        as critical_error_text

      assert board_get(game.board, Coordinate(FileH, Row8))
        == Some(#(Rook, Black))
        as critical_error_text

      can_castle_helper(
        game:,
        required_empty: [Coordinate(FileF, Row8), Coordinate(FileG, Row8)],
        required_not_in_check: [
          Coordinate(FileE, Row8),
          Coordinate(FileF, Row8),
          Coordinate(FileG, Row8),
        ],
      )
    }
  }
}

/// Checks whether the position allows for long castling.
fn can_long_castle(game game: OngoingGameState) -> Bool {
  case game.moving_player {
    White -> {
      use <- bool.guard(
        when: game.long_castle_disqualified_white,
        return: False,
      )

      // assertions are okay, as when the king or rook moves, the
      // previously checked disqualifier flag should cause an early return.
      assert board_get(game.board, Coordinate(FileE, Row1))
        == Some(#(King, White))
        as critical_error_text

      assert board_get(game.board, Coordinate(FileA, Row1))
        == Some(#(Rook, White))
        as critical_error_text

      can_castle_helper(
        game:,
        required_empty: [
          Coordinate(FileD, Row1),
          Coordinate(FileC, Row1),
          Coordinate(FileB, Row1),
        ],
        required_not_in_check: [
          Coordinate(FileE, Row1),
          Coordinate(FileD, Row1),
          Coordinate(FileC, Row1),
        ],
      )
    }
    Black -> {
      use <- bool.guard(
        when: game.long_castle_disqualified_black,
        return: False,
      )

      // assertions are okay, as when the king or rook moves, the
      // previously checked disqualifier flag should cause an early return.
      assert board_get(game.board, Coordinate(FileE, Row8))
        == Some(#(King, Black))
        as critical_error_text

      assert board_get(game.board, Coordinate(FileA, Row8))
        == Some(#(Rook, Black))
        as critical_error_text

      can_castle_helper(
        game:,
        required_empty: [
          Coordinate(FileD, Row8),
          Coordinate(FileC, Row8),
          Coordinate(FileB, Row8),
        ],
        required_not_in_check: [
          Coordinate(FileE, Row8),
          Coordinate(FileD, Row8),
          Coordinate(FileC, Row8),
        ],
      )
    }
  }
}

fn can_castle_helper(
  game game: OngoingGameState,
  required_empty required_empty: List(Coordinate),
  required_not_in_check required_not_in_check: List(Coordinate),
) -> Bool {
  // Check that inbetween tiles are empty
  let inbetween_is_empty =
    required_empty
    |> list.all(fn(inbetween_coord) {
      board_get(game.board, inbetween_coord)
      |> option.is_none()
    })

  // Early return if inbetween tiles aren't empty
  use <- bool.guard(when: !inbetween_is_empty, return: False)

  let king_from = case game.moving_player {
    White -> Coordinate(FileE, Row1)
    Black -> Coordinate(FileE, Row8)
  }

  // Check if the king is castling from, through, into a check
  let goes_through_check =
    required_not_in_check
    |> list.map(StandardFigureMove(king_from, _))
    |> list.map(do_move(game, _))
    |> list.any(is_in_check_internal)

  !goes_through_check
}

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

/// Execute a `FigureMove` and returns a new `OngoingGameState`. Does not flip `moving_player`.
/// 
/// Peforms no checking wether the provided move is legal. Overrides other figures at the move's destination.
/// 
/// WARNING: Panics if the move is invalid (moving from an empty square, promoting from a non-pawn, ...)
fn do_move(
  game game: OngoingGameState,
  move move: FigureMove,
) -> OngoingGameState {
  case move {
    StandardFigureMove(from:, to:) ->
      do_move_standard_figure_move(game:, from:, to:)
    PawnPromotion(from:, to:, new_figure:) ->
      do_move_pawn_promotion(game:, from:, to:, new_figure:)
    EnPassant(from:, to:) -> do_move_en_passant(game:, from:, to:)
    ShortCastle -> do_move_short_castle(game:)
    LongCastle -> do_move_long_castle(game:)
  }
}

fn do_move_standard_figure_move(
  game game: OngoingGameState,
  from from: Coordinate,
  to to: Coordinate,
) -> OngoingGameState {
  let is_capture = case dict.get(game.board.other_figures, to) {
    Ok(_) -> True
    Error(_) -> False
  }

  let is_pawn = case dict.get(game.board.other_figures, from) {
    Ok(#(Pawn, _)) -> True
    _ -> False
  }

  // Update fifty move rule counter
  let fifty_move_rule_counter = {
    // Pawn moves and captures reset the fifty move rule as per definition
    use <- bool.guard(when: is_pawn, return: 0)
    use <- bool.guard(when: is_capture, return: 0)

    // Otherwise increase counter
    game.fifty_move_rule_counter + 1
  }

  // Update threefold repetition counter
  let threefold_repetition_counter = {
    // Captures reset threefold repetition, as un-capturing is impossible
    use <- bool.guard(when: is_capture, return: counter.new())
    // Pawn moves reset threefold repetition, as moving the pawn back is impossible
    use <- bool.guard(when: is_pawn, return: counter.new())

    game.threefold_repetition_counter
    |> counter.increment(get_threefold_repetition_position_from_game(game:))
  }

  // Move the figure
  case game.board {
    // Move white king
    Board(white_king:, black_king:, other_figures:) if white_king == from ->
      OngoingGameState(
        ..game,
        en_passant_possible: None,
        // Disqualify castling
        short_castle_disqualified_white: True,
        long_castle_disqualified_white: True,
        fifty_move_rule_counter:,
        threefold_repetition_counter:,
        board: Board(
          white_king: to,
          black_king:,
          other_figures: dict.delete(other_figures, to),
        ),
      )

    // Move black king
    Board(white_king:, black_king:, other_figures:) if black_king == from ->
      OngoingGameState(
        ..game,
        en_passant_possible: None,
        // Disqualify castling
        short_castle_disqualified_black: True,
        long_castle_disqualified_black: True,
        threefold_repetition_counter:,
        fifty_move_rule_counter:,
        board: Board(
          white_king:,
          black_king: to,
          other_figures: dict.delete(other_figures, to),
        ),
      )

    // Move another piece
    Board(white_king:, black_king:, other_figures:) -> {
      let assert Ok(moving_figure) = dict.get(other_figures, from)
        as critical_error_text

      // Set en passant flag if this is a double pawn move
      let allows_en_passant = case moving_figure {
        #(Pawn, White)
          if from.row == Row2 && to.row == Row4 && from.file == to.file
        -> Some(to.file)
        #(Pawn, Black)
          if from.row == Row7 && to.row == Row5 && from.file == to.file
        -> Some(to.file)
        #(_, _) -> None
      }

      // Disqualify castling if not disqualified already and moving from one
      // of the rook's home squares
      let short_castle_disqualified_white =
        game.short_castle_disqualified_white || from == Coordinate(FileH, Row1)

      let long_castle_disqualified_white =
        game.long_castle_disqualified_white || from == Coordinate(FileA, Row1)

      let short_castle_disqualified_black =
        game.short_castle_disqualified_black || from == Coordinate(FileH, Row8)

      let long_castle_disqualified_black =
        game.long_castle_disqualified_black || from == Coordinate(FileA, Row8)

      OngoingGameState(
        moving_player: game.moving_player,
        en_passant_possible: allows_en_passant,
        short_castle_disqualified_white:,
        long_castle_disqualified_white:,
        short_castle_disqualified_black:,
        long_castle_disqualified_black:,
        threefold_repetition_counter:,
        fifty_move_rule_counter:,
        board: Board(
          white_king:,
          black_king:,
          other_figures: other_figures
            |> dict.delete(from)
            |> dict.insert(to, moving_figure),
        ),
      )
    }
  }
}

fn do_move_pawn_promotion(
  game game: OngoingGameState,
  from from: Coordinate,
  to to: Coordinate,
  new_figure new_figure: Figure,
) -> OngoingGameState {
  let board = game.board
  let moving_player = game.moving_player

  assert board_get(board, from) == Some(#(Pawn, moving_player))
    as critical_error_text

  OngoingGameState(
    ..game,
    en_passant_possible: None,
    // Reset fifty move rule counter as per definition
    fifty_move_rule_counter: 0,
    // Reset threefold rep counter, as undoing a pawn move is impossible
    threefold_repetition_counter: counter.new(),
    board: Board(
      white_king: board.white_king,
      black_king: board.black_king,
      other_figures: board.other_figures
        |> dict.delete(from)
        |> dict.insert(to, #(new_figure, moving_player)),
    ),
  )
}

fn do_move_en_passant(
  game game: OngoingGameState,
  from from: Coordinate,
  to to: Coordinate,
) -> OngoingGameState {
  let board = game.board
  let moving_player = game.moving_player
  let capturing_square = Coordinate(file: to.file, row: from.row)

  assert board_get(board, from) == Some(#(Pawn, moving_player))
    as critical_error_text

  assert board_get(board, capturing_square)
    == Some(#(Pawn, player_flip(moving_player)))
    as critical_error_text

  assert board_get(board, to) == None as critical_error_text

  OngoingGameState(
    ..game,
    en_passant_possible: None,
    // Reset fifty move rule counter as per definition
    fifty_move_rule_counter: 0,
    // Reset threefold rep counter, as undoing a pawn move is impossible
    threefold_repetition_counter: counter.new(),
    board: Board(
      white_king: board.white_king,
      black_king: board.black_king,
      other_figures: board.other_figures
        |> dict.delete(from)
        |> dict.delete(capturing_square)
        |> dict.insert(to, #(Pawn, moving_player)),
    ),
  )
}

fn do_move_short_castle(game game: OngoingGameState) -> OngoingGameState {
  let board = game.board
  let moving_player = game.moving_player

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
      OngoingGameState(
        ..game,
        en_passant_possible: None,
        // Disqualify white castling
        short_castle_disqualified_white: True,
        long_castle_disqualified_white: True,
        threefold_repetition_counter: game.threefold_repetition_counter
          |> counter.increment(get_threefold_repetition_position_from_game(
            game:,
          )),
        board: Board(
          white_king: king_to,
          black_king: board.black_king,
          other_figures: board.other_figures
            |> dict.delete(rook_from)
            |> dict.insert(rook_to, #(Rook, moving_player)),
        ),
      )
    Black ->
      OngoingGameState(
        ..game,
        en_passant_possible: None,
        // Disqualify black castling
        short_castle_disqualified_black: True,
        long_castle_disqualified_black: True,
        threefold_repetition_counter: game.threefold_repetition_counter
          |> counter.increment(get_threefold_repetition_position_from_game(
            game:,
          )),
        board: Board(
          white_king: board.white_king,
          black_king: king_to,
          other_figures: board.other_figures
            |> dict.delete(rook_from)
            |> dict.insert(rook_to, #(Rook, moving_player)),
        ),
      )
  }
}

fn do_move_long_castle(game game: OngoingGameState) -> OngoingGameState {
  let board = game.board
  let moving_player = game.moving_player

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
      OngoingGameState(
        ..game,
        en_passant_possible: None,
        // Disqualify white castling
        short_castle_disqualified_white: True,
        long_castle_disqualified_white: True,
        threefold_repetition_counter: game.threefold_repetition_counter
          |> counter.increment(get_threefold_repetition_position_from_game(
            game:,
          )),
        board: Board(
          white_king: king_to,
          black_king: board.black_king,
          other_figures: board.other_figures
            |> dict.delete(rook_from)
            |> dict.insert(rook_to, #(Rook, moving_player)),
        ),
      )
    Black ->
      OngoingGameState(
        ..game,
        en_passant_possible: None,
        // Disqualify black castling
        short_castle_disqualified_black: True,
        long_castle_disqualified_black: True,
        threefold_repetition_counter: game.threefold_repetition_counter
          |> counter.increment(get_threefold_repetition_position_from_game(
            game:,
          )),
        board: Board(
          white_king: board.white_king,
          black_king: king_to,
          other_figures: board.other_figures
            |> dict.delete(rook_from)
            |> dict.insert(rook_to, #(Rook, moving_player)),
        ),
      )
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

fn get_threefold_repetition_position_from_game(
  game game: OngoingGameState,
) -> ThreefoldRepetitionPosition {
  ThreefoldRepetitionPosition(
    board: game.board,
    moving_player: game.moving_player,
    en_passant_possible: game.en_passant_possible,
    short_castle_disqualified_white: game.short_castle_disqualified_white,
    long_castle_disqualified_white: game.long_castle_disqualified_white,
    short_castle_disqualified_black: game.short_castle_disqualified_black,
    long_castle_disqualified_black: game.long_castle_disqualified_black,
  )
}

const critical_error_text = "Critical internal error!\n"
  <> "This is not your fault (unless you mutated the internal state!).\n"
  <> "If you see this message then this likely means, that something in this package's logic is incorrect.\n"
  <> "Please open an issue at https://github.com/OlZe/Functional-Chess with a detailled description to help improve this package.\n"
  <> "Sorry for the inconvience."
