//// The main module of this chess package is responsible for the public facing API

import chess/board.{type Board, type Player, Black, White}
import chess/coordinate.{type Coordinate}
import chess/internal/logic
import gleam/bool
import gleam/result
import gleam/set

/// Represents entire game state
pub type Game {
  Game(board: Board, state: GameState)
}

/// Represents if the game is won/lost/tied or still ongoing
pub type GameState {
  Checkmate(winner: Player)
  Forfeit(winner: Player)
  Stalemate
  WaitingOnNextMove(next_player: Player)
}

/// Creates a new game in the standard starting chess position.
pub fn new_game() -> Game {
  Game(board: board.new(), state: WaitingOnNextMove(White))
}

/// Represents an error that may be returned by any of the public functions
pub type Error {
  GameAlreadyOver
  SelectedFigureDoesntExist
  SelectedFigureIsNotFriendly
  SelectedFigureCantGoThere
}

/// Process a chess move from `from` to `to` and return the new state.
/// 
/// To get a list of legal moves use `chess.get_legal_moves`
pub fn player_move(
  game game: Game,
  from from: Coordinate,
  to to: Coordinate,
) -> Result(Game, Error) {
  case game.state {
    Checkmate(_) -> Error(GameAlreadyOver)
    Forfeit(_) -> Error(GameAlreadyOver)
    Stalemate -> Error(GameAlreadyOver)
    WaitingOnNextMove(moving_player) -> {
      use possible_moves <- result.try(get_legal_moves(game, from))
      use <- bool.guard(
        when: !set.contains(possible_moves, to),
        return: Error(SelectedFigureCantGoThere),
      )
      let new_board = board.move(game.board, from, to)
      let other_player = case moving_player {
        Black -> White
        White -> Black
      }
      Ok(Game(new_board, WaitingOnNextMove(other_player)))
    }
  }
}

/// Return a list of all legal moves from a selected figure.
/// 
/// To execute a move use `chess.player_move`
pub fn get_legal_moves(
  game game: Game,
  figure coord: Coordinate,
) -> Result(set.Set(Coordinate), Error) {
  case game.state {
    Checkmate(_) -> Error(GameAlreadyOver)
    Forfeit(_) -> Error(GameAlreadyOver)
    Stalemate -> Error(GameAlreadyOver)
    WaitingOnNextMove(moving_player) -> {
      case logic.get_moves(game.board, coord, moving_player) {
        Error(logic.SelectedFigureDoesntExist) ->
          Error(SelectedFigureDoesntExist)
        Error(logic.SelectedFigureIsNotFriendly) ->
          Error(SelectedFigureIsNotFriendly)
        Ok(moves) -> {
          // If moving_player is not in check, then return all moves
          use <- bool.guard(
            when: !logic.is_in_check(game.board, moving_player),
            return: Ok(moves),
          )

          // moving_player is in check, only allow moves that get him out of check
          moves
          |> set.filter(fn(to) {
            let from = coord
            // Simulate move, then check if moving_player is still in check
            let future_board = board.move(game.board, from, to)
            !logic.is_in_check(future_board, moving_player)
          })
          |> Ok
        }
      }
    }
  }
}
