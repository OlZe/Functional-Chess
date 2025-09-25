//// The main module of this chess package is responsible for the public facing API

import chess/board.{type Board, type Player, Black, White}
import chess/coordinate.{type Coordinate}
import chess/internal/logic
import gleam/bool
import gleam/dict
import gleam/result
import gleam/set

/// Represents entire game state
pub type Game {
  Game(board: Board, state: GameState)
}

/// Represents if the game is won/lost/tied or still ongoing
pub type GameState {
  Checkmated(winner: Player)
  Forfeited(winner: Player)
  Stalemated
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

pub type PlayerMove {
  MoveFigure(from: Coordinate, to: Coordinate)
  Forfeit
}

/// Process a chess `move` and return the new state.
/// 
/// To get a list of legal figure moves use `chess.get_legal_moves`
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
          let new_board = board.move(game.board, from, to)

          // Check if game ended
          let new_state = {
            // If there are only kings left, then the game is a stalemate
            use <- bool.guard(
              when: dict.is_empty(new_board.other_figures),
              return: Stalemated,
            )

            let opponent_has_no_moves =
              logic.get_all_legal_moves(new_board, opponent_player)
              |> set.is_empty()

            let opponent_is_in_check =
              logic.is_in_check(new_board, opponent_player)

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
/// To execute a move use `chess.player_move`
pub fn get_legal_moves(
  game game: Game,
  figure coord: Coordinate,
) -> Result(set.Set(Coordinate), Error) {
  case game.state {
    Checkmated(_) -> Error(GameAlreadyOver)
    Forfeited(_) -> Error(GameAlreadyOver)
    Stalemated -> Error(GameAlreadyOver)
    WaitingOnNextMove(moving_player) ->
      logic.get_legal_moves(game.board, coord, moving_player)
      |> result.map_error(fn(error) {
        case error {
          logic.SelectedFigureDoesntExist -> SelectedFigureDoesntExist
          logic.SelectedFigureIsNotFriendly -> SelectedFigureIsNotFriendly
        }
      })
  }
}
