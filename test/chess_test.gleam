import chess.{Bishop, Black, Knight, Pawn, Queen, Rook, White} as c
import gleam/dict
import gleam/set
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

fn start_position() -> c.Board {
  let other_figures =
    dict.from_list([
      #(c.coord_a1, #(Rook, White)),
      #(c.coord_b1, #(Knight, White)),
      #(c.coord_c1, #(Bishop, White)),
      #(c.coord_d1, #(Queen, White)),
      #(c.coord_f1, #(Bishop, White)),
      #(c.coord_g1, #(Knight, White)),
      #(c.coord_h1, #(Rook, White)),
      #(c.coord_a2, #(Pawn, White)),
      #(c.coord_b2, #(Pawn, White)),
      #(c.coord_c2, #(Pawn, White)),
      #(c.coord_d2, #(Pawn, White)),
      #(c.coord_e2, #(Pawn, White)),
      #(c.coord_f2, #(Pawn, White)),
      #(c.coord_g2, #(Pawn, White)),
      #(c.coord_h2, #(Pawn, White)),
      #(c.coord_a8, #(Rook, Black)),
      #(c.coord_b8, #(Knight, Black)),
      #(c.coord_c8, #(Bishop, Black)),
      #(c.coord_d8, #(Queen, Black)),
      #(c.coord_f8, #(Bishop, Black)),
      #(c.coord_g8, #(Knight, Black)),
      #(c.coord_h8, #(Rook, Black)),
      #(c.coord_a7, #(Pawn, Black)),
      #(c.coord_b7, #(Pawn, Black)),
      #(c.coord_c7, #(Pawn, Black)),
      #(c.coord_d7, #(Pawn, Black)),
      #(c.coord_e7, #(Pawn, Black)),
      #(c.coord_f7, #(Pawn, Black)),
      #(c.coord_g7, #(Pawn, Black)),
      #(c.coord_h7, #(Pawn, Black)),
    ])
  c.Board(white_king: c.coord_e1, black_king: c.coord_e8, other_figures:)
}

pub fn new_game_test() {
  let game = c.new_game()
  assert game == c.Game(start_position(), c.WaitingOnNextMove(White))
}

pub fn pawn_can_move_as_white_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_b2, #(Pawn, White)),
        #(c.coord_a3, #(Pawn, Black)),
        #(c.coord_c3, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_b2)
  assert moves
    == set.from_list([c.coord_a3, c.coord_b3, c.coord_c3, c.coord_b4])
}

pub fn pawn_cannot_move_as_white_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_b1, #(Pawn, White)),
        #(c.coord_b2, #(Pawn, Black)),
        #(c.coord_a2, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_b1)
  assert moves == set.new()
}

pub fn pawn_can_move_as_black_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_b7, #(Pawn, Black)),
        #(c.coord_a6, #(Pawn, White)),
        #(c.coord_c6, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(Black))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_b7)
  assert moves
    == set.from_list([c.coord_a6, c.coord_b6, c.coord_c6, c.coord_b5])
}

pub fn pawn_cannot_move_as_black_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_b8, #(Pawn, Black)),
        #(c.coord_b7, #(Pawn, White)),
        #(c.coord_a7, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(Black))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_b8)
  assert moves == set.new()
}

pub fn pawn_cannot_doublemove() {
  // Not on starting position
  let board1 =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a3, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board1, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_a3)
  assert moves == set.new()

  // Square directly in front blocked
  let board2 =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a3, #(Pawn, White)),
        #(c.coord_a4, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board2, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_a3)
  assert moves == set.new()

  // Destination square blocked
  let board3 =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a3, #(Pawn, White)),
        #(c.coord_a5, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board3, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_a3)
  assert moves == set.new()
}

pub fn king_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_b2,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a3, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_b2)
  assert moves
    == set.from_list([
      c.coord_b3,
      c.coord_c3,
      c.coord_c2,
      c.coord_c1,
      c.coord_b1,
      c.coord_a1,
      c.coord_a2,
      c.coord_a3,
    ])
}

pub fn king_cannot_move_test() {
  let board =
    c.Board(
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a2, #(Pawn, White)),
        #(c.coord_b2, #(Pawn, White)),
        #(c.coord_b1, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_a1)
  assert moves == set.new()
}

pub fn knight_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_d4, #(Knight, White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_d4)
  assert moves
    == set.from_list([
      c.coord_b5,
      c.coord_c6,
      c.coord_e6,
      c.coord_f5,
      c.coord_f3,
      c.coord_e2,
      c.coord_c2,
      c.coord_b3,
    ])
}

pub fn knight_cannot_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a1, #(Knight, White)),
        #(c.coord_b3, #(Pawn, White)),
        #(c.coord_c2, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_a1)
  assert moves == set.new()
}

pub fn rook_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_d4, #(Rook, White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_d4)
  assert moves
    == set.from_list([
      c.coord_d5,
      c.coord_d6,
      c.coord_d7,
      c.coord_d8,
      c.coord_d3,
      c.coord_d2,
      c.coord_d1,
      c.coord_e4,
      c.coord_f4,
      c.coord_g4,
      c.coord_h4,
      c.coord_c4,
      c.coord_b4,
      c.coord_a4,
    ])
}

pub fn rook_cannot_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a1, #(Rook, White)),
        #(c.coord_a3, #(Pawn, White)),
        #(c.coord_c1, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_a1)
  assert moves == set.from_list([c.coord_a2, c.coord_b1, c.coord_c1])
}

pub fn bishop_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_d4, #(Bishop, White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_d4)
  assert moves
    == set.from_list([
      c.coord_e5,
      c.coord_f6,
      c.coord_g7,
      c.coord_h8,
      c.coord_c3,
      c.coord_b2,
      c.coord_a1,
      c.coord_c5,
      c.coord_b6,
      c.coord_a7,
      c.coord_e3,
      c.coord_f2,
      c.coord_g1,
    ])
}

pub fn bishop_cannot_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_c1, #(Bishop, White)),
        #(c.coord_a3, #(Pawn, White)),
        #(c.coord_e3, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_c1)
  assert moves == set.from_list([c.coord_b2, c.coord_d2, c.coord_e3])
}

pub fn queen_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_d4, #(Queen, White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_d4)
  assert moves
    == set.from_list([
      c.coord_d5,
      c.coord_d6,
      c.coord_d7,
      c.coord_d8,
      c.coord_d3,
      c.coord_d2,
      c.coord_d1,
      c.coord_e4,
      c.coord_f4,
      c.coord_g4,
      c.coord_h4,
      c.coord_c4,
      c.coord_b4,
      c.coord_a4,
      c.coord_e5,
      c.coord_f6,
      c.coord_g7,
      c.coord_h8,
      c.coord_c3,
      c.coord_b2,
      c.coord_a1,
      c.coord_c5,
      c.coord_b6,
      c.coord_a7,
      c.coord_e3,
      c.coord_f2,
      c.coord_g1,
    ])
}

pub fn queen_cannot_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a1, #(Queen, White)),
        #(c.coord_a2, #(Pawn, White)),
        #(c.coord_b2, #(Pawn, White)),
        #(c.coord_b1, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_a1)
  assert moves == set.from_list([c.coord_b1])
}

/// Tests that get_moves() only returns legal moves when the player is in check.
/// A legal move has to get the player out of check
pub fn get_moves_doesnt_stay_in_check_test() {
  let board =
    c.Board(
      // White king is in check by black rook
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a8, #(Rook, Black)),
        #(c.coord_b2, #(Rook, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))

  // King can move out of check
  assert c.get_legal_moves(game, c.coord_a1) == Ok(set.from_list([c.coord_b1]))

  // Rook can block check
  assert c.get_legal_moves(game, c.coord_b2) == Ok(set.from_list([c.coord_a2]))
}

pub fn get_moves_errors_test() {
  // Game is checkmate
  let board =
    c.Board(
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.new(),
    )
  let game = c.Game(board, c.Checkmated(White))
  assert c.get_legal_moves(game, c.coord_a1) == Error(c.GameAlreadyOver)

  // Game is forfeit
  let game = c.Game(board, c.Forfeited(White))
  assert c.get_legal_moves(game, c.coord_a1) == Error(c.GameAlreadyOver)

  // Game is stalemate
  let game = c.Game(board, c.Stalemated)
  assert c.get_legal_moves(game, c.coord_a1) == Error(c.GameAlreadyOver)

  // Select figure which doesn't exist
  let game = c.Game(board, c.WaitingOnNextMove(White))
  assert c.get_legal_moves(game, c.coord_b2)
    == Error(c.SelectedFigureDoesntExist)

  // Select figure which isn't friendly
  let game = c.Game(board, c.WaitingOnNextMove(Black))
  assert c.get_legal_moves(game, c.coord_a1)
    == Error(c.SelectedFigureIsNotFriendly)
}

pub fn player_move_test() {
  let board =
    c.Board(
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_b2, #(Pawn, Black)),
        #(c.coord_e7, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let expected_board =
    c.Board(
      white_king: c.coord_b2,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_e7, #(Pawn, White))]),
    )
  assert c.player_move(game, c.MoveFigure(c.coord_a1, c.coord_b2))
    == Ok(c.Game(expected_board, c.WaitingOnNextMove(Black)))
}

pub fn player_move_errors_test() {
  let board =
    c.Board(
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.new(),
    )
  // Game already checkmate
  let game = c.Game(board, c.Checkmated(White))
  assert c.player_move(game, c.MoveFigure(c.coord_a1, c.coord_a2))
    == Error(c.GameAlreadyOver)

  // Game already forfeit
  let game = c.Game(board, c.Forfeited(White))
  assert c.player_move(game, c.MoveFigure(c.coord_a1, c.coord_a2))
    == Error(c.GameAlreadyOver)

  // Game already stalemate
  let game = c.Game(board, c.Stalemated)
  assert c.player_move(game, c.MoveFigure(c.coord_a1, c.coord_a2))
    == Error(c.GameAlreadyOver)
}

pub fn player_cannot_check_himself_test() {
  let board =
    c.Board(
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a3, #(Pawn, Black)),
        #(c.coord_b3, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let assert Ok(moves) = c.get_legal_moves(game, c.coord_a1)
  assert moves == set.from_list([c.coord_b1])
}

pub fn stalemate_by_empty_board_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_e2, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))

  let assert Ok(c.Game(_, c.Stalemated)) =
    c.player_move(game, c.MoveFigure(c.coord_e1, c.coord_e2))
}

pub fn stalemate_by_no_moves_left_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_a8,
      other_figures: dict.from_list([
        #(c.coord_h7, #(Rook, White)),
        #(c.coord_h5, #(Rook, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))

  let assert Ok(c.Game(_, c.Stalemated)) =
    c.player_move(game, c.MoveFigure(c.coord_h5, c.coord_b5))
}

pub fn checkmate_test() {
  let board =
    c.Board(
      white_king: c.coord_e4,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_b7, #(Rook, White)),
        #(c.coord_a6, #(Rook, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))

  let assert Ok(c.Game(_, c.Checkmated(winner: White))) =
    c.player_move(game, c.MoveFigure(c.coord_a6, c.coord_a8))
}

pub fn forfeit_test() {
  let board =
    c.Board(
      white_king: c.coord_e4,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a2, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))

  let assert Ok(c.Game(_, c.Forfeited(winner: Black))) =
    c.player_move(game, c.Forfeit)
}
