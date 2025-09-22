import chess as c
import gleam/dict
import gleam/set
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

fn start_position() -> c.Board {
  dict.from_list([
    #(c.a1, #(c.Rook, c.White)),
    #(c.b1, #(c.Knight, c.White)),
    #(c.c1, #(c.Bishop, c.White)),
    #(c.d1, #(c.Queen, c.White)),
    #(c.e1, #(c.King, c.White)),
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
    #(c.e8, #(c.King, c.Black)),
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
}

pub fn new_game_test() {
  let game = c.new_game()
  assert game == c.Game(start_position(), c.WaitingOnNextMove(c.White))
}

pub fn pawn_can_move_as_white_test() {
  let game =
    c.Game(
      board: dict.from_list([
        #(c.b1, #(c.Pawn, c.White)),
        #(c.a2, #(c.Pawn, c.Black)),
        #(c.c2, #(c.Pawn, c.Black)),
      ]),
      state: c.WaitingOnNextMove(c.White),
    )

  let assert Ok(moves) = c.show_moves(game, c.b1)

  assert moves == set.from_list([c.a2, c.b2, c.c2])
}

pub fn pawn_cannot_move_as_white_test() {
  let game =
    c.Game(
      board: dict.from_list([
        #(c.b1, #(c.Pawn, c.White)),
        #(c.b2, #(c.Pawn, c.Black)),
        #(c.a2, #(c.Pawn, c.White)),
      ]),
      state: c.WaitingOnNextMove(c.White),
    )

  let assert Ok(moves) = c.show_moves(game, c.b1)

  assert moves == set.new()
}

pub fn pawn_can_move_as_black_test() {
  let game =
    c.Game(
      board: dict.from_list([
        #(c.b8, #(c.Pawn, c.Black)),
        #(c.a7, #(c.Pawn, c.White)),
        #(c.c7, #(c.Pawn, c.White)),
      ]),
      state: c.WaitingOnNextMove(c.Black),
    )

  let assert Ok(moves) = c.show_moves(game, c.b8)
  assert moves == set.from_list([c.a7, c.b7, c.c7])
}

pub fn pawn_cannot_move_as_black_test() {
  let game =
    c.Game(
      board: dict.from_list([
        #(c.b8, #(c.Pawn, c.Black)),
        #(c.b7, #(c.Pawn, c.White)),
        #(c.a7, #(c.Pawn, c.Black)),
      ]),
      state: c.WaitingOnNextMove(c.Black),
    )

  let assert Ok(moves) = c.show_moves(game, c.b8)
  assert moves == set.new()
}
