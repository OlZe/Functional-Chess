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
pub type Game {
  Game(
    board: Board,
    status: GameStatus,
    /// Keeps the previous game state as well as the move that transformed the previous
    /// game state to *this* game state.
    previous_state: Option(#(Move, Game)),
  )
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

  /// TODO: Not implemented
  /// 
  /// Both players reached a position where checkmating the enemy king is impossible. See [here](https://www.chess.com/terms/draw-chess#dead-position) here for more info.
  DeadPosition

  /// TODO: Not implemented
  /// 
  /// The same position has been reached three times. See [here](https://www.chess.com/terms/draw-chess#threefold-repetition) for more info.
  ThreefoldRepition
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
}

/// Represents an error when trying to select a figure.
pub type SelectFigureError {
  /// Tried selecting a figure from a coordinate which points to an empty square.
  SelectedFigureDoesntExist

  /// Tried selecting a figure which doesn't belong to the player.
  SelectedFigureIsNotFriendly
}

/// Creates a new game in the standard starting chess position.
pub fn new_game() -> Game {
  Game(board: board_new(), status: GameOngoing(White), previous_state: None)
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
  game game: Game,
  move move: Move,
) -> Result(Game, PlayerMoveError) {
  case move {
    PlayerForfeits ->
      forfeit(game:)
      |> result.map_error(fn(_) { PlayerMoveWhileGameAlreadyOver })
    PlayersAgreeToDraw ->
      draw(game:) |> result.map_error(fn(_) { PlayerMoveWhileGameAlreadyOver })
    PlayerMovesFigure(move) -> player_move_figure(game:, move:)
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
}

/// Return a list of all legal moves from a selected `figure`.
/// 
/// To execute a move see [`player_move`](#player_move).
/// 
/// Errors if the game was already over or the selected `figure` doesn't exist or isn't owned by the player.
pub fn get_moves(
  game game: Game,
  figure coord: Coordinate,
) -> Result(set.Set(AvailableFigureMove), GetMovesError) {
  case game.status {
    GameEnded(_) -> Error(GetMovesWhileGameAlreadyOver)
    GameOngoing(moving_player) ->
      get_legal_moves_on_arbitrary_board(
        game.board,
        coord,
        moving_player,
        game.previous_state,
      )
      |> result.map_error(fn(e) { GetMovesWithInvalidFigure(reason: e) })
  }
}

/// Executes a FigureMove
fn player_move_figure(
  game game: Game,
  move move: FigureMove,
) -> Result(Game, PlayerMoveError) {
  case game.status {
    GameEnded(_) -> Error(PlayerMoveWhileGameAlreadyOver)
    GameOngoing(moving_player) -> {
      // Check if given move is legal by getting all available moves and
      // checking if any of them map to it
      let available_moves =
        get_legal_moves_on_arbitrary_board(
          game.board,
          move.from,
          moving_player:,
          previous_state: game.previous_state,
        )
        |> result.map_error(fn(e) { PlayerMoveWithInvalidFigure(reason: e) })
      use available_moves <- result.try(available_moves)
      let is_legal = {
        // Map move to its corresponding AvailableFigureMove
        let move = case move {
          StandardFigureMove(_, to:) -> StandardFigureMoveAvailable(to:)
          PawnPromotion(_, _, to:) -> PawnPromotionAvailable(to:)
          EnPassant(_, to:) -> EnPassantAvailable(to:)
        }
        set.contains(available_moves, move)
      }
      use <- bool.guard(when: !is_legal, return: Error(PlayerMoveIsIllegal))

      // Do the move
      let new_board = board_move(game.board, move)

      // Check if game ended
      let new_status = {
        case is_game_ended(new_board, moving_player, game.previous_state) {
          None -> GameOngoing(next_player: player_flip(moving_player))
          Some(end_condition) -> GameEnded(info: end_condition)
        }
      }
      Ok(Game(
        board: new_board,
        status: new_status,
        previous_state: Some(#(PlayerMovesFigure(move), game)),
      ))
    }
  }
}

/// Forfeit the game to the opposing player.
/// 
/// Errors if the game was already over.
fn forfeit(game game: Game) -> Result(Game, Nil) {
  case game.status {
    GameEnded(_) -> Error(Nil)
    GameOngoing(next_player: forfeiter) -> {
      let winner = player_flip(forfeiter)
      Ok(Game(
        board: game.board,
        status: GameEnded(Victory(winner:, by: Forfeited)),
        previous_state: Some(#(PlayerForfeits, game)),
      ))
    }
  }
}

/// Draw the game through mutual agreement of both players.
/// 
/// Errors if the game was already over.
fn draw(game game: Game) -> Result(Game, Nil) {
  case game.status {
    GameEnded(_) -> Error(Nil)
    GameOngoing(_) -> {
      Ok(Game(
        board: game.board,
        status: GameEnded(Draw(by: MutualAgreement)),
        previous_state: Some(#(PlayersAgreeToDraw, game)),
      ))
    }
  }
}

/// Determines wether the player is being checked by its opponent.
fn is_in_check(
  board board: Board,
  player attackee: Player,
  previous_state previous_state: Option(#(Move, Game)),
) -> Bool {
  // Check if attackee is in check by requesting all moves of all
  // attacker pieces and seeing if any of their moves hit the king

  let attackee_king = case attackee {
    White -> board.white_king
    Black -> board.black_king
  }
  let attacker = player_flip(attackee)

  // A king can never be checked by the opponent's king,
  // thus iterating only over board.other_figures is sufficient
  board.other_figures
  |> dict.to_list
  // Find all pieces belonging to attacker
  |> list.filter(fn(coord_and_figure) { coord_and_figure.1.1 == attacker })
  |> list.map(fn(coord_and_figure) { coord_and_figure.0 })
  // Get all attacker moves
  |> list.flat_map(fn(coord) {
    get_unchecked_moves(board, coord, attacker, previous_state)
    |> result.map(set.to_list)
    |> result.unwrap([])
  })
  // Check if any moves attack the attackee's king
  |> list.any(fn(move) { move.to == attackee_king })
}

fn is_game_ended(
  board board: Board,
  moving_player moving_player: Player,
  previous_state previous_state: Option(#(Move, Game)),
) -> Option(EndCondition) {
  let opponent_player = player_flip(moving_player)

  // Check draw by insufficient material
  use <- bool.guard(
    when: is_insufficient_material(board:),
    return: Some(Draw(by: InsufficientMaterial)),
  )

  // Validate stalemate + checkmate together as they are tightly coupled
  let check_or_stalemate = {
    let opponent_has_no_moves =
      get_all_legal_moves_on_arbitrary_board(
        board,
        opponent_player,
        previous_state,
      )
      |> set.is_empty()

    let opponent_is_in_check =
      is_in_check(board, opponent_player, previous_state)
    case opponent_has_no_moves, opponent_is_in_check {
      True, True -> Some(Victory(winner: moving_player, by: Checkmated))
      True, False -> Some(Draw(by: Stalemated))
      False, _ -> None
    }
  }
  check_or_stalemate
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

/// Retrieve all legal moves of all figures of `moving_player`
fn get_all_legal_moves_on_arbitrary_board(
  board board: Board,
  moving_player moving_player: Player,
  previous_state previous_state: Option(#(Move, Game)),
) -> set.Set(AvailableFigureMove) {
  let king = case moving_player {
    White -> board.white_king
    Black -> board.black_king
  }

  // Get all of moving_player's figures
  let figures =
    board.other_figures
    |> dict.to_list
    |> list.filter(fn(coord_and_figure) {
      coord_and_figure.1.1 == moving_player
    })
    |> list.map(fn(coord_and_figure) { coord_and_figure.0 })
    |> list.append([king])
    |> set.from_list()

  // Get every figure's moves
  let all_moves =
    figures
    |> set.map(fn(from) {
      get_legal_moves_on_arbitrary_board(
        board:,
        figure: from,
        moving_player:,
        previous_state:,
      )
      // result.unwrap is okay here because `from` should always be valid
      |> result.lazy_unwrap(fn() { panic as critical_error_text })
    })
    // Flatten
    |> set.fold(set.new(), set.union)

  all_moves
}

/// Retrieve all legal moves of a given figure.
/// Unlike `get_moves` this doesn't require a `Game` variable
fn get_legal_moves_on_arbitrary_board(
  board board: Board,
  figure coord: Coordinate,
  moving_player moving_player: Player,
  previous_state previous_state: Option(#(Move, Game)),
) -> Result(set.Set(AvailableFigureMove), SelectFigureError) {
  use moves <- result.try(get_unchecked_moves(
    board,
    coord,
    moving_player,
    previous_state,
  ))

  // Filter moves, that leave the player in check, out
  moves
  |> set.filter(fn(move) {
    // Simulate move, then check if moving_player is still in check
    let executeable_move = case move {
      StandardFigureMoveAvailable(to:) -> StandardFigureMove(from: coord, to:)
      EnPassantAvailable(to:) -> EnPassant(from: coord, to:)

      // It doesn't matter what we promote the pawn to, as we're only concerned
      // about whether the king is in check when the pawn moves
      PawnPromotionAvailable(to:) ->
        PawnPromotion(from: coord, to:, new_figure: Queen)
    }
    let future_board = board_move(board, executeable_move)
    !is_in_check(future_board, moving_player, previous_state)
  })
  |> Ok
}

/// Retrieve all moves of a given figure.
/// 
/// Doesn't consider if moving_player's king is in check.
fn get_unchecked_moves(
  board board: Board,
  figure coord: Coordinate,
  moving_player moving_player: Player,
  previous_state previous_state: Option(#(Move, Game)),
) -> Result(set.Set(AvailableFigureMove), SelectFigureError) {
  let selected_figure =
    board_get(board, coord)
    |> option.to_result(SelectedFigureDoesntExist)
  use #(selected_figure, selected_figure_owner) <- result.try(selected_figure)
  use <- bool.guard(
    when: selected_figure_owner != moving_player,
    return: Error(SelectedFigureIsNotFriendly),
  )

  let moves = case selected_figure {
    Pawn ->
      get_moves_for_pawn(
        board,
        coord,
        moving_player,
        previous_move: option.map(previous_state, fn(previous_state) {
          previous_state.0
        }),
      )
    Bishop -> get_moves_for_bishop(board, coord, moving_player)
    King -> get_moves_for_king(board, coord, moving_player)
    Knight -> get_moves_for_knight(board, coord, moving_player)
    Queen -> get_moves_for_queen(board, coord, moving_player)
    Rook -> get_moves_for_rook(board, coord, moving_player)
  }

  Ok(moves)
}

/// Get all possible mmoves of a pawn
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_pawn(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
  previous_move previous_move: Option(Move),
) -> set.Set(AvailableFigureMove) {
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

  // Filter valid moves and check for pawn promotion
  let standard_moves =
    [up, up_up, up_left, up_right]
    |> option.values
    |> list.map(fn(to) {
      let promotion_row = case attacker {
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
    can_en_passant(
      board:,
      coord:,
      to_file:,
      moving_player: attacker,
      previous_move:,
    )
  }

  let en_passant_right = {
    use to_file <- option.then(file_move(coord.file, 1))
    can_en_passant(
      board:,
      coord:,
      to_file:,
      moving_player: attacker,
      previous_move:,
    )
  }

  let all_moves =
    [en_passant_left, en_passant_right]
    |> option.values()
    |> set.from_list
    |> set.union(standard_moves)

  all_moves
}

fn can_en_passant(
  board board: Board,
  coord coord: Coordinate,
  to_file to_file: File,
  moving_player attacker: Player,
  previous_move previous_move: Option(Move),
) -> Option(AvailableFigureMove) {
  case previous_move {
    None -> None
    Some(previous_move) -> {
      // Opponent has to have moved his pawn acoording to required_previous_move
      // and attacker's pawn has to be at required_attacker_coord
      let #(
        required_previous_move_from,
        required_previous_move_to,
        en_passant_from,
        en_passant_to,
      ) = case attacker {
        White -> #(
          Coordinate(to_file, Row7),
          Coordinate(to_file, Row5),
          Coordinate(coord.file, Row5),
          Coordinate(to_file, Row6),
        )
        Black -> #(
          Coordinate(to_file, Row2),
          Coordinate(to_file, Row4),
          Coordinate(coord.file, Row4),
          Coordinate(to_file, Row3),
        )
      }

      // Return if the attacker's pawn is in the wrong position
      use <- bool.guard(when: coord != en_passant_from, return: None)

      // Return if the opponent previously didn't move double-up from his pawn home row
      use <- bool.guard(
        when: previous_move
          != PlayerMovesFigure(StandardFigureMove(
          from: required_previous_move_from,
          to: required_previous_move_to,
        )),
        return: None,
      )

      let previous_move_was_pawn = case
        board_get(board, required_previous_move_to)
      {
        Some(#(Pawn, _)) -> True
        _ -> False
      }

      // Return if the opponent's previous move wasn't a pawn
      use <- bool.guard(when: !previous_move_was_pawn, return: None)

      Some(EnPassantAvailable(to: en_passant_to))
    }
  }
}

/// Get all possible moves of a king
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_king(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(AvailableFigureMove) {
  [#(0, 1), #(1, 1), #(1, 0), #(1, -1), #(0, -1), #(-1, -1), #(-1, 0), #(-1, 1)]
  |> set.from_list()
  |> set.map(JumpTo(origin: coord, offset: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StandardFigureMoveAvailable(to) })
}

/// Get all possible moves of a knight
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_knight(
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
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StandardFigureMoveAvailable(to:) })
}

/// Get all possible moves of a rook
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_rook(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(AvailableFigureMove) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StandardFigureMoveAvailable(to:) })
}

/// Get all possible moves of a bishop
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_bishop(
  board board: Board,
  coord coord: Coordinate,
  moving_player attacker: Player,
) -> set.Set(AvailableFigureMove) {
  [#(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
  // Flatten
  |> set.fold(set.new(), set.union)
  |> set.map(fn(to) { StandardFigureMoveAvailable(to) })
}

/// Get all possible moves of a queen
/// 
/// Doesn't consider if player's king is in check.
fn get_moves_for_queen(
  board board: Board,
  coord coord: Coordinate,
  attacking_player attacker: Player,
) -> set.Set(AvailableFigureMove) {
  [#(0, 1), #(1, 0), #(0, -1), #(-1, 0), #(1, 1), #(1, -1), #(-1, -1), #(-1, 1)]
  |> set.from_list()
  |> set.map(LineOfSight(origin: coord, direction: _, attacker:))
  |> set.map(evaluate_figure_move_description(board, _))
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
fn evaluate_figure_move_description(
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

/// Execute a move on the `board`.
/// 
/// Peforms no checking wether the provided move is legal. Overrides other figures at the move's destination.
/// 
/// WARNING: Panics if the move is invalid (moving from an empty square or promoting or en-passanting from a non-pawn)
fn board_move(board board: Board, move move: FigureMove) -> Board {
  case move {
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
      let assert Ok(#(Pawn, owner)) = dict.get(board.other_figures, from)
        as critical_error_text

      Board(
        white_king: board.white_king,
        black_king: board.black_king,
        other_figures: board.other_figures
          |> dict.delete(from)
          |> dict.insert(to, #(new_figure, owner)),
      )
    }
    EnPassant(from:, to:) -> {
      let assert Ok(#(Pawn, owner)) = dict.get(board.other_figures, from)
        as critical_error_text

      let capturing_square = Coordinate(file: to.file, row: from.row)

      Board(
        white_king: board.white_king,
        black_king: board.black_king,
        other_figures: board.other_figures
          |> dict.delete(from)
          |> dict.delete(capturing_square)
          |> dict.insert(to, #(Pawn, owner)),
      )
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
  <> "This is not your fault.\n"
  <> "If you see this message then this likely means, that something in this package's logic is incorrect.\n"
  <> "Please open an issue at https://github.com/OlZe/Functional-Chess with a detailled description to help improve this package.\n"
  <> "Sorry for the inconvience."
