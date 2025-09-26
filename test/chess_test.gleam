import chess.{Bishop, Black, Knight, Pawn, Queen, Rook, White} as c
import gleam/dict
import gleam/list
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
  let selected_figure = c.coord_b2
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [c.coord_a3, c.coord_b3, c.coord_c3, c.coord_b4]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let selected_figure = c.coord_b1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves = set.new()
  assert actual_moves == expected_moves
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
  let selected_figure = c.coord_b7
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [c.coord_a6, c.coord_b6, c.coord_c6, c.coord_b5]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let selected_figure = c.coord_b8
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves = set.new()
  assert actual_moves == expected_moves
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
  let game1 = c.Game(board1, c.WaitingOnNextMove(White))
  let selected_figure1 = c.coord_a3
  let assert Ok(actual_moves1) = c.get_legal_moves(game1, selected_figure1)
  let expected_moves1 = set.new()
  assert actual_moves1 == expected_moves1

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
  let game2 = c.Game(board2, c.WaitingOnNextMove(White))
  let selected_figure2 = c.coord_a3
  let assert Ok(actual_moves2) = c.get_legal_moves(game2, selected_figure2)
  let expected_moves2 = set.new()
  assert actual_moves2 == expected_moves2

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
  let game3 = c.Game(board3, c.WaitingOnNextMove(White))
  let selected_figure3 = c.coord_a3
  let assert Ok(actual_moves3) = c.get_legal_moves(game3, selected_figure3)
  let expected_moves3 = set.new()
  assert actual_moves3 == expected_moves3
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
  let selected_figure = c.coord_b2
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
      c.coord_b3,
      c.coord_c3,
      c.coord_c2,
      c.coord_c1,
      c.coord_b1,
      c.coord_a1,
      c.coord_a2,
      c.coord_a3,
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let selected_figure = c.coord_a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves = set.new()
  assert actual_moves == expected_moves
}

pub fn knight_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_d4, #(Knight, White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let selected_figure = c.coord_d4
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
      c.coord_b5,
      c.coord_c6,
      c.coord_e6,
      c.coord_f5,
      c.coord_f3,
      c.coord_e2,
      c.coord_c2,
      c.coord_b3,
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let selected_figure = c.coord_a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves = set.new()
  assert actual_moves == expected_moves
}

pub fn rook_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_d4, #(Rook, White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let selected_figure = c.coord_d4
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
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
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let selected_figure = c.coord_a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [c.coord_a2, c.coord_b1, c.coord_c1]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
}

pub fn bishop_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_d4, #(Bishop, White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let selected_figure = c.coord_d4
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
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
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let selected_figure = c.coord_c1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [c.coord_b2, c.coord_d2, c.coord_e3]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
}

pub fn queen_can_move_test() {
  let board =
    c.Board(
      white_king: c.coord_e1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([#(c.coord_d4, #(Queen, White))]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))
  let selected_figure = c.coord_d4
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
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
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let selected_figure = c.coord_a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [c.coord_b1]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
}

pub fn get_moves_doesnt_stay_in_check_test() {
  let board =
    c.Board(
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.from_list([
        #(c.coord_a8, #(Rook, Black)),
        #(c.coord_b2, #(Rook, White)),
      ]),
    )
  let game = c.Game(board, c.WaitingOnNextMove(White))

  let selected_king = c.coord_a1
  let selected_rook = c.coord_b2

  let assert Ok(king_moves) = c.get_legal_moves(game, selected_king)
  let expected_king_moves =
    [c.coord_b1]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_king, to:) })
    |> set.from_list
  assert king_moves == expected_king_moves

  let assert Ok(rook_moves) = c.get_legal_moves(game, selected_rook)
  let expected_rook_moves =
    [c.coord_a2]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_rook, to:) })
    |> set.from_list
  assert rook_moves == expected_rook_moves
}

pub fn get_moves_errors_test() {
  let board =
    c.Board(
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.new(),
    )

  // Game is already won/lost
  let game1 = c.Game(board, c.Victory(winner: White, by: c.Checkmate))
  assert c.get_legal_moves(game1, c.coord_a1) == Error(c.GameAlreadyOver)

  // Game is already drawn
  let game2 = c.Game(board, c.Draw(by: c.MutualAgreement))
  assert c.get_legal_moves(game2, c.coord_a1) == Error(c.GameAlreadyOver)

  // Select figure which doesn't exist
  let game4 = c.Game(board, c.WaitingOnNextMove(White))
  assert c.get_legal_moves(game4, c.coord_b2)
    == Error(c.SelectedFigureDoesntExist)

  // Select figure which isn't friendly
  let game5 = c.Game(board, c.WaitingOnNextMove(Black))
  assert c.get_legal_moves(game5, c.coord_a1)
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
  let move = c.StdFigureMove(c.coord_a1, c.coord_b2)
  assert c.player_move(game, move)
    == Ok(c.Game(expected_board, c.WaitingOnNextMove(Black)))
}

pub fn player_move_errors_test() {
  let board =
    c.Board(
      white_king: c.coord_a1,
      black_king: c.coord_e8,
      other_figures: dict.new(),
    )
  let move = c.StdFigureMove(c.coord_a1, c.coord_a2)

  // Game is already won
  let game1 = c.Game(board, c.Victory(winner: White, by: c.Checkmate))
  assert c.player_move(game1, move) == Error(c.GameAlreadyOver)

  // Game is already drawn
  let game2 = c.Game(board, c.Draw(by: c.MutualAgreement))
  assert c.player_move(game2, move) == Error(c.GameAlreadyOver)
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
  let selected_figure = c.coord_a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves =
    [c.coord_b1]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list
  assert actual_moves == expected_moves
}

// TODO: this should be draw by insufficient material
// 
// pub fn stalemate_by_empty_board_test() {
//   let board =
//     c.Board(
//       white_king: c.coord_e1,
//       black_king: c.coord_e8,
//       other_figures: dict.from_list([
//         #(c.coord_e2, #(Pawn, Black)),
//       ]),
//     )
//   let game = c.Game(board, c.WaitingOnNextMove(White))
//   let move = c.StdFigureMove(c.coord_e1, c.coord_e2)
//   let assert Ok(c.Game(_, c.Stalemated)) = c.player_move(game, move)
// }

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
  let move = c.StdFigureMove(c.coord_h5, c.coord_b5)
  let assert Ok(c.Game(_, c.Draw(by: c.Stalemate))) = c.player_move(game, move)
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
  let move = c.StdFigureMove(c.coord_a6, c.coord_a8)
  let assert Ok(c.Game(_, c.Victory(winner: White, by: c.Checkmate))) =
    c.player_move(game, move)
}

pub fn forfeit_test() {
  let game = c.new_game()

  let assert Ok(c.Game(_, c.Victory(winner: Black, by: c.Forfeit))) =
    c.forfeit(game)
}
