//// The main module of this chess package is responsible for the public facing API

import chess/board.{type Board, type Player, Black, White}
import chess/coordinate.{type Coordinate}
import chess/internal/logic
import gleam/bool
import gleam/dict
import gleam/list
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
      let opponent_player = case moving_player {
        Black -> White
        White -> Black
      }
      let new_state = {
        // If there are only kings left, then the game is a stalemate
        use <- bool.guard(
          when: dict.is_empty(new_board.other_figures),
          return: Stalemate,
        )

        // Check if other_player has no moves left => Checkmate or Stalemate
        let opponent_has_no_moves = {
          let opponent_king = case opponent_player {
            Black -> new_board.black_king
            White -> new_board.white_king
          }
          let opponent_figures =
            new_board.other_figures
            |> dict.to_list
            |> list.filter(fn(coord_and_figure) {
              coord_and_figure.1.1 == opponent_player
            })
            |> list.map(fn(coord_and_figure) { coord_and_figure.0 })
            |> list.append([opponent_king])

          let opponent_moves =
            opponent_figures
            |> list.flat_map(fn(from) {
              get_legal_moves_helper(new_board, from, opponent_player)
              |> result.map(set.to_list)
              |> result.unwrap([])
            })

          list.is_empty(opponent_moves)
        }

        let opponent_is_in_check = logic.is_in_check(new_board, opponent_player)

        case opponent_has_no_moves, opponent_is_in_check {
          True, True -> Checkmate(winner: moving_player)
          True, False -> Stalemate
          False, _ -> WaitingOnNextMove(opponent_player)
        }
      }
      Ok(Game(new_board, new_state))
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
    WaitingOnNextMove(moving_player) ->
      get_legal_moves_helper(game.board, coord, moving_player)
  }
}

fn get_legal_moves_helper(
  board board: Board,
  figure coord: Coordinate,
  moving_player moving_player: Player,
) -> Result(set.Set(Coordinate), Error) {
  case logic.get_moves(board, coord, moving_player) {
    Error(logic.SelectedFigureDoesntExist) -> Error(SelectedFigureDoesntExist)
    Error(logic.SelectedFigureIsNotFriendly) ->
      Error(SelectedFigureIsNotFriendly)
    Ok(moves) -> {
      // Make sure the player is not in check after his move
      moves
      |> set.filter(fn(to) {
        let from = coord
        // Simulate move, then check if moving_player is still in check
        let future_board = board.move(board, from, to)
        !logic.is_in_check(future_board, moving_player)
      })
      |> Ok
    }
  }
}
