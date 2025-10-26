import birdie
import chess.{Bishop, Black, Knight, Pawn, Queen, Rook, White} as c
import chess/coordinates as coord
import chess/text_renderer as r
import gleam/dict
import gleam/list
import gleam/set
import gleam/string
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn new_game_test() {
  c.new_game()
  |> r.render()
  |> birdie.snap(
    title: "New game appears in the standard starting position and state",
  )
}

pub fn new_custom_game_errors_test() {
  let pawns_on_final_rank =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b8, #(Pawn, White)),
        #(coord.a1, #(Pawn, Black)),
        #(coord.c1, #(Pawn, Black)),
      ]),
    )

  assert c.new_custom_game(pawns_on_final_rank, White)
    == Error(c.PawnsOnFinalRank(set.from_list([coord.b8, coord.a1, coord.c1])))

  let enemy_already_in_check =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.e3, #(Rook, White)),
        #(coord.a4, #(Pawn, Black)),
      ]),
    )

  assert c.new_custom_game(enemy_already_in_check, White)
    == Error(c.EnemyIsInCheck)
}

pub fn pawn_can_move_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b2, #(Pawn, White)),
        #(coord.a3, #(Pawn, Black)),
        #(coord.c3, #(Pawn, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.b2
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(coord.b2, moves)
  |> birdie.snap(
    title: "Pawn can capture left/right and double-move on home row.",
  )
}

pub fn pawn_can_promote_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b7, #(Pawn, White)),
        #(coord.a8, #(Rook, Black)),
        #(coord.c8, #(Rook, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.b7
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure:, moves:)
  |> birdie.snap(
    title: "Pawn can promote through regular move and capture left/right.",
  )
}

pub fn pawn_cannot_promote_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b7, #(Pawn, White)),
        #(coord.a8, #(Knight, White)),
        #(coord.b8, #(Knight, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.b7
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure:, moves:)
  |> birdie.snap(title: "Pawn cannot promote.")
}

pub fn pawn_cannot_move_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b1, #(Pawn, White)),
        #(coord.b2, #(Pawn, Black)),
        #(coord.a2, #(Pawn, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.b1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Pawn cannot move as white.")
}

pub fn pawn_can_en_passant_left_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a7, #(Pawn, Black)),
        #(coord.b5, #(Pawn, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, Black)

  // Make a double pawn move as black to allow en passant
  let assert Ok(after) = c.player_move(before, c.StdMove(coord.a7, coord.a5))

  // Now select figure as white
  let selected_figure = coord.b5
  let assert Ok(moves) = c.get_moves(after, selected_figure)

  combine_renders(
    r.render(before),
    r.render_with_moves(after, selected_figure, moves),
  )
  |> birdie.snap(title: "White pawn can en passant left.")
}

pub fn pawn_can_en_passant_right_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.c7, #(Pawn, Black)),
        #(coord.b5, #(Pawn, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, Black)

  // Make a double pawn move as black to allow en passant
  let assert Ok(after) = c.player_move(before, c.StdMove(coord.c7, coord.c5))

  // Now select figure as white
  let selected_figure = coord.b5
  let assert Ok(moves) = c.get_moves(after, selected_figure)

  combine_renders(
    r.render(before),
    r.render_with_moves(after, selected_figure, moves),
  )
  |> birdie.snap(title: "White pawn can en passant right.")
}

pub fn pawn_cannot_en_passant_left_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a6, #(Pawn, Black)),
        #(coord.b5, #(Pawn, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, Black)

  // Make a single-step pawn move as black
  let assert Ok(after) = c.player_move(before, c.StdMove(coord.a6, coord.a5))

  // Now select figure as white
  let selected_figure = coord.b5
  let assert Ok(moves) = c.get_moves(after, selected_figure)

  combine_renders(
    r.render(before),
    r.render_with_moves(after, selected_figure, moves),
  )
  |> birdie.snap(title: "White pawn cannot en passant left.")
}

pub fn pawn_cannot_en_passant_right_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.c6, #(Pawn, Black)),
        #(coord.b5, #(Pawn, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, Black)

  // Make a single-step pawn move as black
  let assert Ok(after) = c.player_move(before, c.StdMove(coord.c6, coord.c5))

  // Now select figure as white
  let selected_figure = coord.b5
  let assert Ok(moves) = c.get_moves(after, selected_figure)

  combine_renders(
    r.render(before),
    r.render_with_moves(after, selected_figure, moves),
  )
  |> birdie.snap(title: "White pawn cannot en passant right.")
}

pub fn pawn_can_move_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b7, #(Pawn, Black)),
        #(coord.a6, #(Pawn, White)),
        #(coord.c6, #(Pawn, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, Black)
  let selected_figure = coord.b7
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(
    title: "Pawn can capture left/right and double-move on home row as black.",
  )
}

pub fn pawn_cannot_move_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b5, #(Pawn, Black)),
        #(coord.b4, #(Pawn, White)),
        #(coord.a4, #(Pawn, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, Black)
  let selected_figure = coord.b5
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Pawn cannot move as black.")
}

pub fn pawn_can_promote_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b2, #(Pawn, Black)),
        #(coord.a1, #(Rook, White)),
        #(coord.c1, #(Rook, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, Black)
  let selected_figure = coord.b2
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(
    title: "Pawn can promote through regular move and capture left/right as black.",
  )
}

pub fn pawn_cannot_promote_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b2, #(Pawn, Black)),
        #(coord.a1, #(Knight, Black)),
        #(coord.b1, #(Knight, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, Black)
  let selected_figure = coord.b2
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Pawn cannot promote as black.")
}

pub fn pawn_can_en_passant_left_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a2, #(Pawn, White)),
        #(coord.b4, #(Pawn, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)

  // Make a double pawn move as white to allow en passant
  let assert Ok(after) = c.player_move(before, c.StdMove(coord.a2, coord.a4))

  // Now select figure as black
  let selected_figure = coord.b4
  let assert Ok(moves) = c.get_moves(after, selected_figure)

  combine_renders(
    r.render(before),
    r.render_with_moves(after, selected_figure, moves),
  )
  |> birdie.snap(title: "Black pawn can en passant left.")
}

pub fn pawn_can_en_passant_right_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.c2, #(Pawn, White)),
        #(coord.b4, #(Pawn, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)

  // Make a double pawn move as black to allow en passant
  let assert Ok(after) = c.player_move(before, c.StdMove(coord.c2, coord.c4))

  // Now select figure as black
  let selected_figure = coord.b4
  let assert Ok(moves) = c.get_moves(after, selected_figure)

  combine_renders(
    r.render(before),
    r.render_with_moves(after, selected_figure, moves),
  )
  |> birdie.snap(title: "Black pawn can en passant right.")
}

pub fn pawn_cannot_en_passant_left_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a3, #(Pawn, White)),
        #(coord.b4, #(Pawn, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)

  // Make a single-step pawn move as white
  let assert Ok(after) = c.player_move(before, c.StdMove(coord.a3, coord.a4))

  // Now select figure as black
  let selected_figure = coord.b4
  let assert Ok(moves) = c.get_moves(after, selected_figure)

  combine_renders(
    r.render(before),
    r.render_with_moves(after, selected_figure, moves),
  )
  |> birdie.snap(title: "Black pawn cannot en passant left.")
}

pub fn pawn_cannot_en_passant_right_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.c3, #(Pawn, White)),
        #(coord.b4, #(Pawn, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)

  // Make a single-step pawn move as white
  let assert Ok(after) = c.player_move(before, c.StdMove(coord.c3, coord.c4))

  // Now select figure as black
  let selected_figure = coord.b4
  let assert Ok(moves) = c.get_moves(after, selected_figure)

  combine_renders(
    r.render(before),
    r.render_with_moves(after, selected_figure, moves),
  )
  |> birdie.snap(title: "Black pawn cannot en passant right.")
}

pub fn pawn_cannot_doublemove() {
  // Not on starting position
  let board1 =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a3, #(Pawn, White)),
      ]),
    )
  let assert Ok(game1) = c.new_custom_game(board1, White)
  let selected_figure1 = coord.a3
  let assert Ok(moves1) = c.get_moves(game1, selected_figure1)
  game1
  |> r.render_with_moves(selected_figure1, moves1)
  |> birdie.snap(title: "Pawn cannot double-move: not on starting position.")

  // Square directly in front blocked
  let board2 =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a3, #(Pawn, White)),
        #(coord.a4, #(Pawn, White)),
      ]),
    )
  let assert Ok(game2) = c.new_custom_game(board2, White)
  let selected_figure2 = coord.a3
  let assert Ok(moves2) = c.get_moves(game2, selected_figure2)
  game2
  |> r.render_with_moves(selected_figure2, moves2)
  |> birdie.snap(
    title: "Pawn cannot double-move: square directly in front blocked.",
  )

  // Destination square blocked
  let board3 =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a3, #(Pawn, White)),
        #(coord.a5, #(Pawn, White)),
      ]),
    )
  let assert Ok(game3) = c.new_custom_game(board3, White)
  let selected_figure3 = coord.a3
  let assert Ok(moves3) = c.get_moves(game3, selected_figure3)
  game3
  |> r.render_with_moves(selected_figure3, moves3)
  |> birdie.snap(title: "Pawn cannot double-move: destination square blocked.")
}

pub fn king_can_move_test() {
  let board =
    c.Board(
      white_king: coord.b2,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a3, #(Pawn, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.b2
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "King can move to all adjacent squares.")
}

pub fn king_cannot_move_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a2, #(Pawn, White)),
        #(coord.b2, #(Pawn, White)),
        #(coord.b1, #(Pawn, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.a1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "King cannot move: all adjacent squares blocked.")
}

pub fn king_can_castle_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Rook, White)),
        #(coord.h1, #(Rook, White)),
        #(coord.e7, #(Pawn, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.e1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "White King can castle both ways.")
}

pub fn king_cannot_castle_out_of_check_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Rook, White)),
        #(coord.h1, #(Rook, White)),
        #(coord.e7, #(Rook, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.e1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "White King cannot castle out of check both ways.")
}

pub fn king_cannot_castle_through_check_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Rook, White)),
        #(coord.h1, #(Rook, White)),
        #(coord.d7, #(Rook, Black)),
        #(coord.f7, #(Rook, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.e1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "White King cannot castle through check both ways.")
}

pub fn king_cannot_castle_into_check_as_white_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Rook, White)),
        #(coord.h1, #(Rook, White)),
        #(coord.c7, #(Rook, Black)),
        #(coord.g7, #(Rook, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.e1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "White King cannot castle into check both ways.")
}

pub fn king_cannot_castle_after_king_moved_test() {
  let board =
    c.Board(
      white_king: coord.e2,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Rook, White)),
        #(coord.h1, #(Rook, White)),
        #(coord.e7, #(Pawn, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let assert Ok(after_king_moved) =
    c.player_move(before, c.StdMove(from: coord.e2, to: coord.e1))

  // Filler move for black as it's now black's turn
  let assert Ok(after_black_moved) =
    c.player_move(after_king_moved, c.StdMove(from: coord.e7, to: coord.e6))

  let assert Ok(moves) = c.get_moves(after_black_moved, coord.e1)

  [
    r.render(before),
    r.render(after_king_moved),
    r.render_with_moves(after_black_moved, coord.e1, moves),
  ]
  |> combine_n_renders
  |> birdie.snap(
    title: "White King cannot castle both ways *after* moving king into position.",
  )
}

pub fn king_cannot_castle_after_rooks_moved_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a2, #(Rook, White)),
        #(coord.h2, #(Rook, White)),
        #(coord.e7, #(Pawn, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let assert Ok(after_rook1_moved) =
    c.player_move(before, c.StdMove(from: coord.a2, to: coord.a1))

  // Filler move for black as it's now black's turn
  let assert Ok(after_black_moved1) =
    c.player_move(after_rook1_moved, c.StdMove(from: coord.e7, to: coord.e6))

  let assert Ok(after_rook2_moved) =
    c.player_move(after_black_moved1, c.StdMove(from: coord.h2, to: coord.h1))

  // Filler move for black as it's now black's turn
  let assert Ok(after_black_moved2) =
    c.player_move(after_rook2_moved, c.StdMove(from: coord.e6, to: coord.e5))

  let assert Ok(moves) = c.get_moves(after_black_moved1, coord.e1)

  [
    r.render(before),
    r.render(after_rook1_moved),
    r.render(after_black_moved1),
    r.render(after_rook2_moved),
    r.render_with_moves(after_black_moved2, coord.e1, moves),
  ]
  |> combine_n_renders
  |> birdie.snap(
    title: "White King cannot castle both ways *after* moving rooks into position.",
  )
}

pub fn king_cannot_castle_after_rook_captured_test() {
  let assert Ok(game) =
    c.new_custom_game(
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.a8, #(c.Rook, Black)),
          #(coord.h8, #(c.Rook, Black)),
          #(coord.b7, #(c.Bishop, White)),
        ]),
      ),
      first_player: White,
    )

  let assert Ok(after) =
    c.player_move(game:, move: c.StdMove(coord.b7, coord.a8))

  let king = coord.e8
  let assert Ok(moves) = c.get_moves(after, king)

  combine_renders(r.render(game), r.render_with_moves(after, king, moves))
  |> birdie.snap(
    "King can only castle long, after king-side rook as been captured.",
  )
}

pub fn king_can_castle_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a8, #(Rook, Black)),
        #(coord.h8, #(Rook, Black)),
        #(coord.e2, #(Pawn, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, Black)
  let selected_figure = coord.e8
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Black King can castle both ways.")
}

pub fn king_cannot_castle_out_of_check_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a8, #(Rook, Black)),
        #(coord.h8, #(Rook, Black)),
        #(coord.e2, #(Rook, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, Black)
  let selected_figure = coord.e8
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Black King cannot castle out of check both ways.")
}

pub fn king_cannot_castle_through_check_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a8, #(Rook, Black)),
        #(coord.h8, #(Rook, Black)),
        #(coord.d2, #(Rook, White)),
        #(coord.f2, #(Rook, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, Black)
  let selected_figure = coord.e8
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Black King cannot castle through check both ways.")
}

pub fn king_cannot_castle_into_check_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a8, #(Rook, Black)),
        #(coord.h8, #(Rook, Black)),
        #(coord.c2, #(Rook, White)),
        #(coord.g2, #(Rook, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, Black)
  let selected_figure = coord.e8
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Black King cannot castle into check both ways.")
}

pub fn knight_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Knight, White))]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.d4
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Knight can move to all valid squares.")
}

pub fn knight_cannot_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Knight, White)),
        #(coord.b3, #(Pawn, White)),
        #(coord.c2, #(Pawn, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.a1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Knight cannot move: all destinations blocked.")
}

pub fn rook_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Rook, White))]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.d4
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Rook can move to all valid squares.")
}

pub fn rook_cannot_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Rook, White)),
        #(coord.a3, #(Pawn, White)),
        #(coord.c1, #(Bishop, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.a1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Rook's line of sight is limited.")
}

pub fn bishop_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Bishop, White))]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.d4
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Bishop can move to all valid squares.")
}

pub fn bishop_cannot_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.c1, #(Bishop, White)),
        #(coord.a3, #(Pawn, White)),
        #(coord.e3, #(Pawn, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.c1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Bishop's line of sight is blocked.")
}

pub fn queen_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Queen, White))]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.d4
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Queen can move to all valid squares.")
}

pub fn queen_cannot_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Queen, White)),
        #(coord.a2, #(Pawn, White)),
        #(coord.b2, #(Pawn, White)),
        #(coord.b1, #(Bishop, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.a1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Queen's line of sight is blocked.'")
}

pub fn get_moves_doesnt_stay_in_check_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a8, #(Rook, Black)),
        #(coord.b3, #(Rook, White)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)

  let selected_king = coord.a1
  let selected_rook = coord.b3

  let assert Ok(king_moves) = c.get_moves(game, selected_king)
  game
  |> r.render_with_moves(selected_king, king_moves)
  |> birdie.snap(title: "King only has moves that don't stay in check.")

  let assert Ok(rook_moves) = c.get_moves(game, selected_rook)
  game
  |> r.render_with_moves(selected_rook, rook_moves)
  |> birdie.snap(title: "Rook only has moves that don't leave king in check.")
}

pub fn standard_move_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b2, #(Pawn, Black)),
        #(coord.e7, #(Pawn, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.StdMove(coord.a1, coord.b2)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap("Standard move from A1 to B2 captures the figure.")
}

pub fn pawn_promotion_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.a8,
      other_figures: dict.from_list([
        #(coord.e7, #(Pawn, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.PawnPromotion(coord.e7, coord.e8, Queen)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap("Pawn promotion from A7 to A8 to a queen.")
}

pub fn en_passant_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a7, #(Pawn, Black)),
        #(coord.b5, #(Pawn, White)),
      ]),
    )
  let assert Ok(start) = c.new_custom_game(board, Black)

  // Black double moves up to allow en passant
  let move = c.StdMove(coord.a7, coord.a5)
  let assert Ok(allowed_en_passant) = c.player_move(start, move)

  // White does en_passant
  let move = c.EnPassant(from: coord.b5, to: coord.a6)
  let assert Ok(did_en_passant) = c.player_move(allowed_en_passant, move)

  combine_renders(r.render(allowed_en_passant), r.render(did_en_passant))
  |> birdie.snap(
    "White en passant's from B5 to A6 and captures the black pawn on A5",
  )
}

pub fn player_cannot_check_himself_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a3, #(Pawn, Black)),
        #(coord.b3, #(Pawn, Black)),
      ]),
    )
  let assert Ok(game) = c.new_custom_game(board, White)
  let selected_figure = coord.a1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "Player cannot move into check.")
}

pub fn stalemate_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.a8,
      other_figures: dict.from_list([
        #(coord.h7, #(Rook, White)),
        #(coord.h5, #(Rook, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.StdMove(coord.h5, coord.b5)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(title: "Move H5 to B5 results in stalemate.")
}

pub fn checkmate_test() {
  let board =
    c.Board(
      white_king: coord.e4,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b7, #(Rook, White)),
        #(coord.a6, #(Rook, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.StdMove(coord.a6, coord.a8)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(title: "Move A6 to A8 results in checkmate for white.")
}

pub fn forfeit_test() {
  let before = c.new_game()

  let assert Ok(after) = c.forfeit(before)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap("White forfeited in starting position.")
}

pub fn draw_through_mutual_agreement_test() {
  let before = c.new_game()

  let assert Ok(after) = c.draw(before)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap("Draw through mutual agreement in starting position.")
}

pub fn insufficient_material_by_king_vs_king_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.e2, #(Pawn, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.StdMove(coord.e1, coord.e2)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(
    title: "Move E1 to E2 results in draw insufficient material. (King vs king).",
  )
}

pub fn insufficient_material_by_king_vs_king_and_bishop_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.e2, #(Pawn, Black)),
        #(coord.f2, #(Bishop, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.StdMove(coord.e1, coord.e2)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(
    title: "Move E1 to E2 results in draw insufficient material. (King vs king and bishop).",
  )
}

pub fn insufficient_material_by_king_vs_king_and_knight_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.e2, #(Pawn, Black)),
        #(coord.f2, #(Knight, White)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.StdMove(coord.e1, coord.e2)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(
    title: "Move E1 to E2 results in draw insufficient material. (King vs king and knight).",
  )
}

pub fn insufficient_material_by_king_and_bishop_vs_king_and_bishop_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.e2, #(Pawn, Black)),
        #(coord.f2, #(Bishop, White)),
        #(coord.f6, #(Bishop, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.StdMove(coord.e1, coord.e2)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(
    title: "Move E1 to E2 results in draw insufficient material. (King and bishop vs king and bishop, same colour).",
  )
}

pub fn insufficient_material_by_king_and_bishop_vs_king_and_bishop_wrong_colour_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.e2, #(Pawn, Black)),
        #(coord.f2, #(Bishop, White)),
        #(coord.g6, #(Bishop, Black)),
      ]),
    )
  let assert Ok(before) = c.new_custom_game(board, White)
  let move = c.StdMove(coord.e1, coord.e2)
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(
    title: "Move E1 to E2 does not result in draw: bishops are on different colours.",
  )
}

pub fn threefold_repetition_test() {
  let assert Ok(start) = {
    let board =
      c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.e6, #(Pawn, Black)),
        ]),
      )
    c.new_custom_game(board, White)
  }

  let assert Ok(after_move11) =
    c.player_move(start, c.StdMove(coord.e1, coord.f1))

  let assert Ok(after_move12) =
    c.player_move(after_move11, c.StdMove(coord.e8, coord.f8))

  let assert Ok(after_move21) =
    c.player_move(after_move12, c.StdMove(coord.f1, coord.e1))

  let assert Ok(after_move22) =
    c.player_move(after_move21, c.StdMove(coord.f8, coord.e8))

  let assert Ok(after_move31) =
    c.player_move(after_move22, c.StdMove(coord.e1, coord.f1))

  let assert Ok(after_move32) =
    c.player_move(after_move31, c.StdMove(coord.e8, coord.f8))

  let assert Ok(after_move41) =
    c.player_move(after_move32, c.StdMove(coord.f1, coord.e1))

  let assert Ok(after_move42) =
    c.player_move(after_move41, c.StdMove(coord.f8, coord.e8))

  [
    start,
    after_move11,
    after_move12,
    after_move21,
    after_move22,
    after_move31,
    after_move32,
    after_move41,
    after_move42,
  ]
  |> list.map(r.render)
  |> combine_n_renders
  |> birdie.snap(
    title: "Threefold repetition gets recognized and results in a draw.",
  )
}

pub fn threefold_repetition_ignores_positions_with_special_moves_test() {
  let assert Ok(start) = {
    let board =
      c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.f5, #(Pawn, White)),
          #(coord.e7, #(Pawn, Black)),
        ]),
      )
    c.new_custom_game(board, Black)
  }

  // Make En Passant available
  let assert Ok(after_move02) =
    c.player_move(start, c.StdMove(coord.e7, coord.e5))

  let assert Ok(after_move11) =
    c.player_move(after_move02, c.StdMove(coord.e1, coord.f1))

  let assert Ok(after_move12) =
    c.player_move(after_move11, c.StdMove(coord.e8, coord.f8))

  let assert Ok(after_move21) =
    c.player_move(after_move12, c.StdMove(coord.f1, coord.e1))

  let assert Ok(after_move22) =
    c.player_move(after_move21, c.StdMove(coord.f8, coord.e8))

  let assert Ok(after_move31) =
    c.player_move(after_move22, c.StdMove(coord.e1, coord.f1))

  let assert Ok(after_move32) =
    c.player_move(after_move31, c.StdMove(coord.e8, coord.f8))

  let assert Ok(after_move41) =
    c.player_move(after_move32, c.StdMove(coord.f1, coord.e1))

  let assert Ok(after_move42) =
    c.player_move(after_move41, c.StdMove(coord.f8, coord.e8))

  [
    start,
    after_move02,
    after_move11,
    after_move12,
    after_move21,
    after_move22,
    after_move31,
    after_move32,
    after_move41,
    after_move42,
  ]
  |> list.map(r.render)
  |> combine_n_renders
  |> birdie.snap(
    title: "This does not result in a threefold repetition as en passant becomes available at the second position",
  )
}

pub fn fifty_move_rule_test() {
  let assert Ok(start) = {
    let board =
      c.Board(
        white_king: coord.a1,
        black_king: coord.a8,
        other_figures: dict.from_list([#(coord.e5, #(Pawn, White))]),
      )
    c.new_custom_game(board, White)
  }

  // We'll walk the kings back and forth in a straight line of different lengths
  // to avoid a threefold repetition

  let path_white =
    [
      coord.a1,
      coord.b1,
      coord.c1,
      coord.d1,
      coord.e1,
      coord.f1,
      coord.g1,
      coord.h1,
      coord.h2,
      coord.g2,
      coord.f2,
      coord.e2,
      coord.d2,
      coord.c2,
      coord.b2,
      coord.a2,
      coord.a1,
    ]
    |> list.window_by_2()
    |> list.repeat(10)
    |> list.flatten()
    |> list.take(50)

  let path_black =
    [
      coord.a8,
      coord.b8,
      coord.c8,
      coord.d8,
      coord.e8,
      coord.f8,
      coord.g8,
      coord.g7,
      coord.f7,
      coord.e7,
      coord.d7,
      coord.c7,
      coord.b7,
      coord.a7,
      coord.a8,
    ]
    |> list.window_by_2()
    |> list.repeat(10)
    |> list.flatten()
    |> list.take(50)

  let drawn_game =
    list.zip(path_white, path_black)
    |> list.fold(start, fn(game, move) {
      let #(#(white_from, white_to), #(black_from, black_to)) = move

      let assert Ok(game) =
        c.player_move(game:, move: c.StdMove(from: white_from, to: white_to))

      let assert Ok(game) =
        c.player_move(game:, move: c.StdMove(from: black_from, to: black_to))

      game
    })

  assert c.get_status(drawn_game) == c.GameEnded(c.Draw(by: c.FiftyMoveRule))
}

pub fn fifty_move_rule_disqualified_by_pawn_move_test() {
  let assert Ok(start) = {
    let board =
      c.Board(
        white_king: coord.a1,
        black_king: coord.a8,
        other_figures: dict.from_list([#(coord.e4, #(Pawn, White))]),
      )
    c.new_custom_game(board, White)
  }

  // We'll walk the kings back and forth in a straight line of different lengths
  // to avoid a threefold repetition

  let path_white =
    [
      coord.a1,
      coord.b1,
      coord.c1,
      coord.d1,
      coord.e1,
      coord.f1,
      coord.g1,
      coord.h1,
      coord.h2,
      coord.g2,
      coord.f2,
      coord.e2,
      coord.d2,
      coord.c2,
      coord.b2,
      coord.a2,
      coord.a1,
    ]
    |> list.window_by_2()
    |> list.repeat(10)
    |> list.flatten()
    |> list.take(49)
    // Add a pawn move at the end
    |> list.append([#(coord.e4, coord.e5)])

  let path_black =
    [
      coord.a8,
      coord.b8,
      coord.c8,
      coord.d8,
      coord.e8,
      coord.f8,
      coord.g8,
      coord.g7,
      coord.f7,
      coord.e7,
      coord.d7,
      coord.c7,
      coord.b7,
      coord.a7,
      coord.a8,
    ]
    |> list.window_by_2()
    |> list.repeat(10)
    |> list.flatten()
    |> list.take(50)

  let drawn_game =
    list.zip(path_white, path_black)
    |> list.fold(start, fn(game, move) {
      let #(#(white_from, white_to), #(black_from, black_to)) = move

      let assert Ok(game) =
        c.player_move(game:, move: c.StdMove(from: white_from, to: white_to))

      let assert Ok(game) =
        c.player_move(game:, move: c.StdMove(from: black_from, to: black_to))

      game
    })

  assert c.get_status(drawn_game) == c.GameOngoing(White)
}

pub fn fifty_move_rule_disqualified_by_capture_test() {
  let assert Ok(start) = {
    let board =
      c.Board(
        white_king: coord.a1,
        black_king: coord.a8,
        other_figures: dict.from_list([
          #(coord.g3, #(Pawn, White)),
          #(coord.b3, #(Knight, White)),
          #(coord.d4, #(Pawn, Black)),
        ]),
      )
    c.new_custom_game(board, White)
  }

  // We'll walk the kings back and forth in a straight line of different lengths
  // to avoid a threefold repetition

  let path_white =
    [
      coord.a1,
      coord.b1,
      coord.c1,
      coord.d1,
      coord.e1,
      coord.f1,
      coord.g1,
      coord.h1,
      coord.h2,
      coord.g2,
      coord.f2,
      coord.e2,
      coord.d2,
      coord.c2,
      coord.b2,
      coord.a2,
      coord.a1,
    ]
    |> list.window_by_2()
    |> list.repeat(10)
    |> list.flatten()
    |> list.take(49)
    // Add knight captures pawn at the end
    |> list.append([#(coord.b3, coord.d4)])

  let path_black =
    [
      coord.a8,
      coord.b8,
      coord.c8,
      coord.d8,
      coord.e8,
      coord.f8,
      coord.g8,
      coord.g7,
      coord.f7,
      coord.e7,
      coord.d7,
      coord.c7,
      coord.b7,
      coord.a7,
      coord.a8,
    ]
    |> list.window_by_2()
    |> list.repeat(10)
    |> list.flatten()
    |> list.take(50)

  let drawn_game =
    list.zip(path_white, path_black)
    |> list.fold(start, fn(game, move) {
      let #(#(white_from, white_to), #(black_from, black_to)) = move

      let assert Ok(game) =
        c.player_move(game:, move: c.StdMove(from: white_from, to: white_to))

      let assert Ok(game) =
        c.player_move(game:, move: c.StdMove(from: black_from, to: black_to))

      game
    })

  assert c.get_status(drawn_game) == c.GameOngoing(White)
}

pub fn move_history_test() {
  let game = c.new_game()
  let assert Ok(game) = c.player_move(game, c.StdMove(coord.e2, coord.e4))

  let assert Ok(game) = c.player_move(game, c.StdMove(coord.d7, coord.d5))

  let assert Ok(game) = c.player_move(game, c.StdMove(coord.e4, coord.d5))

  assert c.get_history(game)
    == [
      #(c.StdMove(coord.e2, coord.e4), c.White),
      #(c.StdMove(coord.d7, coord.d5), c.Black),
      #(c.StdMove(coord.e4, coord.d5), c.White),
    ]
}

pub fn get_past_board_position_test() {
  let init = c.new_game()
  let assert Ok(move11) = c.player_move(init, c.StdMove(coord.e2, coord.e4))

  let assert Ok(move12) = c.player_move(move11, c.StdMove(coord.d7, coord.d5))

  let assert Ok(move21) = c.player_move(move12, c.StdMove(coord.e4, coord.d5))

  let assert Ok(move12_of_history) = c.get_past_position(move21, 2)
  assert move12_of_history == move12
}

pub fn get_all_moves_test() {
  let assert Ok(game) =
    c.new_custom_game(
      board: c.Board(
        white_king: coord.a1,
        black_king: coord.h8,
        other_figures: dict.from_list([#(coord.e2, #(c.Pawn, White))]),
      ),
      first_player: White,
    )

  let assert Ok(all_moves) = c.get_all_moves(game:)
  // Render all moves
  all_moves
  |> dict.to_list()
  |> list.map(fn(coord_and_moves) {
    let #(coord, moves) = coord_and_moves
    r.render_with_moves(game, coord, moves)
  })
  |> combine_n_renders()
  |> birdie.snap(
    title: "Getting all moves returns all valid moves of all figures. Each figure get it's own board render.",
  )
}

pub fn is_in_check_test() {
  let assert Ok(game) =
    c.new_custom_game(
      board: c.Board(
        white_king: coord.a1,
        black_king: coord.h8,
        other_figures: dict.from_list([#(coord.b2, #(c.Pawn, Black))]),
      ),
      first_player: White,
    )

  assert c.is_in_check(game) == True
}

fn combine_renders(before: String, after: String) -> String {
  "Start:\n" <> before <> "\n---------------------\nAfter:\n" <> after
}

fn combine_n_renders(renders: List(String)) -> String {
  let content = string.join(renders, "\n---------------------\nNext:\n")
  "Start:\n" <> content
}
