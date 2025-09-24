import chess as c
import gleam/dict
import gleam/set
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

fn start_position() -> c.Board {
  let other_figures =
    dict.from_list([
      #(c.a1, #(c.Rook, c.White)),
      #(c.b1, #(c.Knight, c.White)),
      #(c.c1, #(c.Bishop, c.White)),
      #(c.d1, #(c.Queen, c.White)),
      #(c.f1, #(c.Bishop, c.White)),
      #(c.g1, #(c.Knight, c.White)),
      #(c.h1, #(c.Rook, c.White)),
      #(c.a2, #(c.Pawn, c.White)),
      #(c.b2, #(c.Pawn, c.White)),
      #(c.c2, #(c.Pawn, c.White)),
      #(c.d2, #(c.Pawn, c.White)),
      #(c.e2, #(c.Pawn, c.White)),
      #(c.f2, #(c.Pawn, c.White)),
      #(c.g2, #(c.Pawn, c.White)),
      #(c.h2, #(c.Pawn, c.White)),
      #(c.a8, #(c.Rook, c.Black)),
      #(c.b8, #(c.Knight, c.Black)),
      #(c.c8, #(c.Bishop, c.Black)),
      #(c.d8, #(c.Queen, c.Black)),
      #(c.f8, #(c.Bishop, c.Black)),
      #(c.g8, #(c.Knight, c.Black)),
      #(c.h8, #(c.Rook, c.Black)),
      #(c.a7, #(c.Pawn, c.Black)),
      #(c.b7, #(c.Pawn, c.Black)),
      #(c.c7, #(c.Pawn, c.Black)),
      #(c.d7, #(c.Pawn, c.Black)),
      #(c.e7, #(c.Pawn, c.Black)),
      #(c.f7, #(c.Pawn, c.Black)),
      #(c.g7, #(c.Pawn, c.Black)),
      #(c.h7, #(c.Pawn, c.Black)),
    ])
  c.Board(white_king: c.e1, black_king: c.e8, other_figures:)
}

pub fn new_game_test() {
  let game = c.new_game()
  assert game == c.Game(start_position(), c.WaitingOnNextMove(c.White))
}

pub fn pawn_can_move_as_white_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b2, #(c.Pawn, c.White)),
        #(c.a3, #(c.Pawn, c.Black)),
        #(c.c3, #(c.Pawn, c.Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.b2)
  assert moves == set.from_list([c.a3, c.b3, c.c3, c.b4])
}

pub fn pawn_cannot_move_as_white_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b1, #(c.Pawn, c.White)),
        #(c.b2, #(c.Pawn, c.Black)),
        #(c.a2, #(c.Pawn, c.White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.b1)
  assert moves == set.new()
}

pub fn pawn_can_move_as_black_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b7, #(c.Pawn, c.Black)),
        #(c.a6, #(c.Pawn, c.White)),
        #(c.c6, #(c.Pawn, c.White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.Black))
  let assert Ok(moves) = c.get_moves(game, c.b7)
  assert moves == set.from_list([c.a6, c.b6, c.c6, c.b5])
}

pub fn pawn_cannot_move_as_black_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b8, #(c.Pawn, c.Black)),
        #(c.b7, #(c.Pawn, c.White)),
        #(c.a7, #(c.Pawn, c.Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.Black))
  let assert Ok(moves) = c.get_moves(game, c.b8)
  assert moves == set.new()
}

pub fn pawn_cannot_doublemove() {
  // Not on starting position
  let board1 =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a3, #(c.Pawn, c.White)),
      ]),
    )
  let game = c.Game(board1, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.a3)
  assert moves == set.new()

  // Square directly in front blocked
  let board2 =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a3, #(c.Pawn, c.White)),
        #(c.a4, #(c.Pawn, c.White)),
      ]),
    )
  let game = c.Game(board2, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.a3)
  assert moves == set.new()

  // Destination square blocked
  let board3 =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a3, #(c.Pawn, c.White)),
        #(c.a5, #(c.Pawn, c.White)),
      ]),
    )
  let game = c.Game(board3, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.a3)
  assert moves == set.new()
}

pub fn king_can_move_test() {
  let board =
    c.Board(
      white_king: c.b2,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a2, #(c.Pawn, c.Black)),
        #(c.b1, #(c.Pawn, c.Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.b2)
  assert moves
    == set.from_list([c.b3, c.c3, c.c2, c.c1, c.b1, c.a1, c.a2, c.a3])
}

pub fn king_cannot_move_test() {
  let board =
    c.Board(
      white_king: c.a1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a2, #(c.Pawn, c.White)),
        #(c.b2, #(c.Pawn, c.White)),
        #(c.b1, #(c.Pawn, c.White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.a1)
  assert moves == set.new()
}

pub fn knight_can_move_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.d4, #(c.Knight, c.White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.d4)
  assert moves
    == set.from_list([c.b5, c.c6, c.e6, c.f5, c.f3, c.e2, c.c2, c.b3])
}

pub fn knight_cannot_move_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a1, #(c.Knight, c.White)),
        #(c.b3, #(c.Pawn, c.White)),
        #(c.c2, #(c.Pawn, c.White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.a1)
  assert moves == set.new()
}

pub fn rook_can_move_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.d4, #(c.Rook, c.White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.d4)
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
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a1, #(c.Rook, c.White)),
        #(c.a3, #(c.Pawn, c.White)),
        #(c.c1, #(c.Pawn, c.Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.a1)
  assert moves == set.from_list([c.a2, c.b1, c.c1])
}

pub fn bishop_can_move_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.d4, #(c.Bishop, c.White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.d4)
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
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.c1, #(c.Bishop, c.White)),
        #(c.a3, #(c.Pawn, c.White)),
        #(c.e3, #(c.Pawn, c.Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.c1)
  assert moves == set.from_list([c.b2, c.d2, c.e3])
}

pub fn queen_can_move_test() {
  let board =
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([#(c.d4, #(c.Queen, c.White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.d4)
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
    c.Board(
      white_king: c.e1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.a1, #(c.Queen, c.White)),
        #(c.a2, #(c.Pawn, c.White)),
        #(c.b2, #(c.Pawn, c.White)),
        #(c.b1, #(c.Pawn, c.Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let assert Ok(moves) = c.get_moves(game, c.a1)
  assert moves == set.from_list([c.b1])
}

pub fn get_moves_errors_test() {
  // Game is checkmate
  let board =
    c.Board(white_king: c.a1, black_king: c.e8, other_figures: dict.new())
  let game = c.Game(board, c.Checkmate(c.White))
  assert c.get_moves(game, c.a1) == Error(c.GameAlreadyOver)

  // Game is forfeit
  let game = c.Game(board, c.Forfeit(c.White))
  assert c.get_moves(game, c.a1) == Error(c.GameAlreadyOver)

  // Game is stalemate
  let game = c.Game(board, c.Stalemate)
  assert c.get_moves(game, c.a1) == Error(c.GameAlreadyOver)

  // Select figure which doesn't exist
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  assert c.get_moves(game, c.b2) == Error(c.SelectedFigureDoesntExist)

  // Select figure which isn't friendly
  let game = c.Game(board, c.WaitingOnNextMove(c.Black))
  assert c.get_moves(game, c.a1) == Error(c.SelectedFigureIsNotFriendly)
}

pub fn player_move_test() {
  let board =
    c.Board(
      white_king: c.a1,
      black_king: c.e8,
      other_figures: dict.from_list([
        #(c.b2, #(c.Pawn, c.Black)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(c.White))
  let expected_board =
    c.Board(white_king: c.b2, black_king: c.e8, other_figures: dict.new())
  assert c.player_move(game, c.a1, c.b2)
    == Ok(c.Game(expected_board, c.WaitingOnNextMove(c.Black)))
}

pub fn player_move_errors_test() {
  let board =
    c.Board(white_king: c.a1, black_king: c.e8, other_figures: dict.new())
  // Game already checkmate
  let game = c.Game(board, c.Checkmate(c.White))
  assert c.player_move(game, c.a1, c.a2) == Error(c.GameAlreadyOver)

  // Game already forfeit
  let game = c.Game(board, c.Forfeit(c.White))
  assert c.player_move(game, c.a1, c.a2) == Error(c.GameAlreadyOver)

  // Game already stalemate
  let game = c.Game(board, c.Stalemate)
  assert c.player_move(game, c.a1, c.a2) == Error(c.GameAlreadyOver)
}
