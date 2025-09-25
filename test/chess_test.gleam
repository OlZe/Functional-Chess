import chess as m
import chess/board.{Bishop, Black, Knight, Pawn, Queen, Rook, White} as b
import chess/coordinate as c
import gleam/dict
import gleam/set
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

fn start_position() -> b.Board {
  let other_figures =
    dict.from_list([
      #(c.a1, #(Rook, White)),
      #(c.b1, #(Knight, White)),
      #(c.c1, #(Bishop, White)),
      #(c.d1, #(Queen, White)),
      #(c.f1, #(Bishop, White)),
      #(c.g1, #(Knight, White)),
      #(c.h1, #(Rook, White)),
      #(c.a2, #(Pawn, White)),
      #(c.b2, #(Pawn, White)),
      #(c.c2, #(Pawn, White)),
      #(c.d2, #(Pawn, White)),
      #(c.e2, #(Pawn, White)),
      #(c.f2, #(Pawn, White)),
      #(c.g2, #(Pawn, White)),
      #(c.h2, #(Pawn, White)),
      #(c.a8, #(Rook, Black)),
      #(c.b8, #(Knight, Black)),
      #(c.c8, #(Bishop, Black)),
      #(c.d8, #(Queen, Black)),
      #(c.f8, #(Bishop, Black)),
      #(c.g8, #(Knight, Black)),
      #(c.h8, #(Rook, Black)),
      #(c.a7, #(Pawn, Black)),
      #(c.b7, #(Pawn, Black)),
      #(c.c7, #(Pawn, Black)),
      #(c.d7, #(Pawn, Black)),
      #(c.e7, #(Pawn, Black)),
      #(c.f7, #(Pawn, Black)),
      #(c.g7, #(Pawn, Black)),
      #(c.h7, #(Pawn, Black)),
    ])
  b.Board(white_king: c.e1, black_king: c.e8, other_figures:)
}

pub fn new_game_test() {
  let game = m.new_game()
  assert game == m.Game(start_position(), m.WaitingOnNextMove(White))
}

pub fn pawn_can_move_as_white_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b2, #(Pawn, White)),
        #(c.a3, #(Pawn, Black)),
        #(c.c3, #(Pawn, Black)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.b2)
  assert moves == set.from_list([c.a3, c.b3, c.c3, c.b4])
}

pub fn pawn_cannot_move_as_white_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b1, #(Pawn, White)),
        #(c.b2, #(Pawn, Black)),
        #(c.a2, #(Pawn, White)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.b1)
  assert moves == set.new()
}

pub fn pawn_can_move_as_black_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b7, #(Pawn, Black)),
        #(c.a6, #(Pawn, White)),
        #(c.c6, #(Pawn, White)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(Black))
  let assert Ok(moves) = m.get_legal_moves(game, c.b7)
  assert moves == set.from_list([c.a6, c.b6, c.c6, c.b5])
}

pub fn pawn_cannot_move_as_black_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b8, #(Pawn, Black)),
        #(c.b7, #(Pawn, White)),
        #(c.a7, #(Pawn, Black)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(Black))
  let assert Ok(moves) = m.get_legal_moves(game, c.b8)
  assert moves == set.new()
}

pub fn pawn_cannot_doublemove() {
  // Not on starting position
  let board1 =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a3, #(Pawn, White)),
      ]),
    )
  let game = m.Game(board1, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.a3)
  assert moves == set.new()

  // Square directly in front blocked
  let board2 =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a3, #(Pawn, White)),
        #(c.a4, #(Pawn, White)),
      ]),
    )
  let game = m.Game(board2, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.a3)
  assert moves == set.new()

  // Destination square blocked
  let board3 =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a3, #(Pawn, White)),
        #(c.a5, #(Pawn, White)),
      ]),
    )
  let game = m.Game(board3, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.a3)
  assert moves == set.new()
}

pub fn king_can_move_test() {
  let board =
    b.Board(
      white_king: c.b2,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a3, #(Pawn, Black)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.b2)
  assert moves
    == set.from_list([c.b3, c.c3, c.c2, c.c1, c.b1, c.a1, c.a2, c.a3])
}

pub fn king_cannot_move_test() {
  let board =
    b.Board(
      white_king: c.a1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a2, #(Pawn, White)),
        #(c.b2, #(Pawn, White)),
        #(c.b1, #(Pawn, White)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.a1)
  assert moves == set.new()
}

pub fn knight_can_move_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.d4, #(Knight, White))]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.d4)
  assert moves
    == set.from_list([c.b5, c.c6, c.e6, c.f5, c.f3, c.e2, c.c2, c.b3])
}

pub fn knight_cannot_move_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a1, #(Knight, White)),
        #(c.b3, #(Pawn, White)),
        #(c.c2, #(Pawn, White)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.a1)
  assert moves == set.new()
}

pub fn rook_can_move_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.d4, #(Rook, White))]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.d4)
  assert moves
    == set.from_list([
      c.d5,
      c.d6,
      c.d7,
      c.d8,
      c.d3,
      c.d2,
      c.d1,
      c.e4,
      c.f4,
      c.g4,
      c.h4,
      c.c4,
      c.b4,
      c.a4,
    ])
}

pub fn rook_cannot_move_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a1, #(Rook, White)),
        #(c.a3, #(Pawn, White)),
        #(c.c1, #(Pawn, Black)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.a1)
  assert moves == set.from_list([c.a2, c.b1, c.c1])
}

pub fn bishop_can_move_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.d4, #(Bishop, White))]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.d4)
  assert moves
    == set.from_list([
      c.e5,
      c.f6,
      c.g7,
      c.h8,
      c.c3,
      c.b2,
      c.a1,
      c.c5,
      c.b6,
      c.a7,
      c.e3,
      c.f2,
      c.g1,
    ])
}

pub fn bishop_cannot_move_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.c1, #(Bishop, White)),
        #(c.a3, #(Pawn, White)),
        #(c.e3, #(Pawn, Black)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.c1)
  assert moves == set.from_list([c.b2, c.d2, c.e3])
}

pub fn queen_can_move_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.d4, #(Queen, White))]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.d4)
  assert moves
    == set.from_list([
      c.d5,
      c.d6,
      c.d7,
      c.d8,
      c.d3,
      c.d2,
      c.d1,
      c.e4,
      c.f4,
      c.g4,
      c.h4,
      c.c4,
      c.b4,
      c.a4,
      c.e5,
      c.f6,
      c.g7,
      c.h8,
      c.c3,
      c.b2,
      c.a1,
      c.c5,
      c.b6,
      c.a7,
      c.e3,
      c.f2,
      c.g1,
    ])
}

pub fn queen_cannot_move_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a1, #(Queen, White)),
        #(c.a2, #(Pawn, White)),
        #(c.b2, #(Pawn, White)),
        #(c.b1, #(Pawn, Black)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.a1)
  assert moves == set.from_list([c.b1])
}

/// Tests that get_moves() only returns legal moves when the player is in check.
/// A legal move has to get the player out of check
pub fn get_moves_doesnt_stay_in_check_test() {
  let board =
    b.Board(
      // White king is in check by black rook
      white_king: c.a1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a8, #(Rook, Black)),
        #(c.b2, #(Rook, White)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))

  // King can move out of check
  assert m.get_legal_moves(game, c.a1) == Ok(set.from_list([c.b1]))

  // Rook can block check
  assert m.get_legal_moves(game, c.b2) == Ok(set.from_list([c.a2]))
}

pub fn get_moves_errors_test() {
  // Game is checkmate
  let board =
    b.Board(white_king: c.a1, black_king: c.e8, other_figures: dict.new())
  let game = m.Game(board, m.Checkmate(White))
  assert m.get_legal_moves(game, c.a1) == Error(m.GameAlreadyOver)

  // Game is forfeit
  let game = m.Game(board, m.Forfeit(White))
  assert m.get_legal_moves(game, c.a1) == Error(m.GameAlreadyOver)

  // Game is stalemate
  let game = m.Game(board, m.Stalemate)
  assert m.get_legal_moves(game, c.a1) == Error(m.GameAlreadyOver)

  // Select figure which doesn't exist
  let game = m.Game(board, m.WaitingOnNextMove(White))
  assert m.get_legal_moves(game, c.b2) == Error(m.SelectedFigureDoesntExist)

  // Select figure which isn't friendly
  let game = m.Game(board, m.WaitingOnNextMove(Black))
  assert m.get_legal_moves(game, c.a1) == Error(m.SelectedFigureIsNotFriendly)
}

pub fn player_move_test() {
  let board =
    b.Board(
      white_king: c.a1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b2, #(Pawn, Black)),
        #(c.e7, #(Pawn, White)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let expected_board =
    b.Board(
      white_king: c.b2,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.e7, #(Pawn, White))]),
    )
  assert m.player_move(game, c.a1, c.b2)
    == Ok(m.Game(expected_board, m.WaitingOnNextMove(Black)))
}

pub fn player_move_errors_test() {
  let board =
    b.Board(white_king: c.a1, black_king: c.e8, other_figures: dict.new())
  // Game already checkmate
  let game = m.Game(board, m.Checkmate(White))
  assert m.player_move(game, c.a1, c.a2) == Error(m.GameAlreadyOver)

  // Game already forfeit
  let game = m.Game(board, m.Forfeit(White))
  assert m.player_move(game, c.a1, c.a2) == Error(m.GameAlreadyOver)

  // Game already stalemate
  let game = m.Game(board, m.Stalemate)
  assert m.player_move(game, c.a1, c.a2) == Error(m.GameAlreadyOver)
}

pub fn player_cannot_check_himself_test() {
  let board =
    b.Board(
      white_king: c.a1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a3, #(Pawn, Black)),
        #(c.b3, #(Pawn, Black)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))
  let assert Ok(moves) = m.get_legal_moves(game, c.a1)
  assert moves == set.from_list([c.b1])
}

pub fn stalemate_by_empty_board_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.e2, #(Pawn, Black)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))

  let assert Ok(m.Game(_, m.Stalemate)) = m.player_move(game, c.e1, c.e2)
}

pub fn stalemate_by_no_moves_left_test() {
  let board =
    b.Board(
      white_king: c.e1,
      black_king: c.a8,
      other_figures: dict.from_list([
        #(c.h7, #(Rook, White)),
        #(c.h5, #(Rook, White)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))

  let assert Ok(m.Game(_, m.Stalemate)) = m.player_move(game, c.h5, c.b5)
}

pub fn checkmate_test() {
  let board =
    b.Board(
      white_king: c.e4,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b7, #(Rook, White)),
        #(c.a6, #(Rook, White)),
      ]),
    )
  let game = m.Game(board, m.WaitingOnNextMove(White))

  let assert Ok(m.Game(_, m.Checkmate(winner: White))) =
    m.player_move(game, c.a6, c.a8)
}
