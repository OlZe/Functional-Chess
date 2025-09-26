import chess.{Bishop, Black, Knight, Pawn, Queen, Rook, White} as c
import chess/coordinates as coord
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
      #(coord.a1, #(Rook, White)),
      #(coord.b1, #(Knight, White)),
      #(coord.c1, #(Bishop, White)),
      #(coord.d1, #(Queen, White)),
      #(coord.f1, #(Bishop, White)),
      #(coord.g1, #(Knight, White)),
      #(coord.h1, #(Rook, White)),
      #(coord.a2, #(Pawn, White)),
      #(coord.b2, #(Pawn, White)),
      #(coord.c2, #(Pawn, White)),
      #(coord.d2, #(Pawn, White)),
      #(coord.e2, #(Pawn, White)),
      #(coord.f2, #(Pawn, White)),
      #(coord.g2, #(Pawn, White)),
      #(coord.h2, #(Pawn, White)),
      #(coord.a8, #(Rook, Black)),
      #(coord.b8, #(Knight, Black)),
      #(coord.c8, #(Bishop, Black)),
      #(coord.d8, #(Queen, Black)),
      #(coord.f8, #(Bishop, Black)),
      #(coord.g8, #(Knight, Black)),
      #(coord.h8, #(Rook, Black)),
      #(coord.a7, #(Pawn, Black)),
      #(coord.b7, #(Pawn, Black)),
      #(coord.c7, #(Pawn, Black)),
      #(coord.d7, #(Pawn, Black)),
      #(coord.e7, #(Pawn, Black)),
      #(coord.f7, #(Pawn, Black)),
      #(coord.g7, #(Pawn, Black)),
      #(coord.h7, #(Pawn, Black)),
    ])
  c.Board(white_king: coord.e1, black_king: coord.e8, other_figures:)
}

pub fn new_game_test() {
  let game = c.new_game()
  assert game == c.Game(start_position(), c.GameOngoing(White))
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
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.b2
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [coord.a3, coord.b3, coord.c3, coord.b4]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.b1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves = set.new()
  assert actual_moves == expected_moves
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
  let game = c.Game(board, c.GameOngoing(Black))
  let selected_figure = coord.b7
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [coord.a6, coord.b6, coord.c6, coord.b5]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
}

pub fn pawn_cannot_move_as_black_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b8, #(Pawn, Black)),
        #(coord.b7, #(Pawn, White)),
        #(coord.a7, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.GameOngoing(Black))
  let selected_figure = coord.b8
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves = set.new()
  assert actual_moves == expected_moves
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
  let game1 = c.Game(board1, c.GameOngoing(White))
  let selected_figure1 = coord.a3
  let assert Ok(actual_moves1) = c.get_legal_moves(game1, selected_figure1)
  let expected_moves1 = set.new()
  assert actual_moves1 == expected_moves1

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
  let game2 = c.Game(board2, c.GameOngoing(White))
  let selected_figure2 = coord.a3
  let assert Ok(actual_moves2) = c.get_legal_moves(game2, selected_figure2)
  let expected_moves2 = set.new()
  assert actual_moves2 == expected_moves2

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
  let game3 = c.Game(board3, c.GameOngoing(White))
  let selected_figure3 = coord.a3
  let assert Ok(actual_moves3) = c.get_legal_moves(game3, selected_figure3)
  let expected_moves3 = set.new()
  assert actual_moves3 == expected_moves3
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
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.b2
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
      coord.b3,
      coord.c3,
      coord.c2,
      coord.c1,
      coord.b1,
      coord.a1,
      coord.a2,
      coord.a3,
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves = set.new()
  assert actual_moves == expected_moves
}

pub fn knight_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Knight, White))]),
    )
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.d4
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
      coord.b5,
      coord.c6,
      coord.e6,
      coord.f5,
      coord.f3,
      coord.e2,
      coord.c2,
      coord.b3,
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves = set.new()
  assert actual_moves == expected_moves
}

pub fn rook_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Rook, White))]),
    )
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.d4
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
      coord.d5,
      coord.d6,
      coord.d7,
      coord.d8,
      coord.d3,
      coord.d2,
      coord.d1,
      coord.e4,
      coord.f4,
      coord.g4,
      coord.h4,
      coord.c4,
      coord.b4,
      coord.a4,
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
}

pub fn rook_cannot_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a1, #(Rook, White)),
        #(coord.a3, #(Pawn, White)),
        #(coord.c1, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [coord.a2, coord.b1, coord.c1]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
}

pub fn bishop_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Bishop, White))]),
    )
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.d4
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
      coord.e5,
      coord.f6,
      coord.g7,
      coord.h8,
      coord.c3,
      coord.b2,
      coord.a1,
      coord.c5,
      coord.b6,
      coord.a7,
      coord.e3,
      coord.f2,
      coord.g1,
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.c1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [coord.b2, coord.d2, coord.e3]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
}

pub fn queen_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Queen, White))]),
    )
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.d4
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [
      coord.d5,
      coord.d6,
      coord.d7,
      coord.d8,
      coord.d3,
      coord.d2,
      coord.d1,
      coord.e4,
      coord.f4,
      coord.g4,
      coord.h4,
      coord.c4,
      coord.b4,
      coord.a4,
      coord.e5,
      coord.f6,
      coord.g7,
      coord.h8,
      coord.c3,
      coord.b2,
      coord.a1,
      coord.c5,
      coord.b6,
      coord.a7,
      coord.e3,
      coord.f2,
      coord.g1,
    ]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
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
        #(coord.b1, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)

  let expected_moves =
    [coord.b1]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list

  assert actual_moves == expected_moves
}

pub fn get_moves_doesnt_stay_in_check_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.a8, #(Rook, Black)),
        #(coord.b2, #(Rook, White)),
      ]),
    )
  let game = c.Game(board, c.GameOngoing(White))

  let selected_king = coord.a1
  let selected_rook = coord.b2

  let assert Ok(king_moves) = c.get_legal_moves(game, selected_king)
  let expected_king_moves =
    [coord.b1]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_king, to:) })
    |> set.from_list
  assert king_moves == expected_king_moves

  let assert Ok(rook_moves) = c.get_legal_moves(game, selected_rook)
  let expected_rook_moves =
    [coord.a2]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_rook, to:) })
    |> set.from_list
  assert rook_moves == expected_rook_moves
}

pub fn get_moves_errors_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.new(),
    )

  // Game is already won/lost
  let game1 =
    c.Game(board, c.GameEnded(c.Victory(winner: White, by: c.Checkmate)))
  assert c.get_legal_moves(game1, coord.a1)
    == Error(c.GetMovesWhilGameAlreadyOver)

  // Game is already drawn
  let game2 = c.Game(board, c.GameEnded(c.Draw(by: c.MutualAgreement)))
  assert c.get_legal_moves(game2, coord.a1)
    == Error(c.GetMovesWhilGameAlreadyOver)

  // Select figure which doesn't exist
  let game4 = c.Game(board, c.GameOngoing(White))
  assert c.get_legal_moves(game4, coord.b2)
    == Error(c.GetMovesWithInvalidFigure(c.SelectedFigureDoesntExist))

  // Select figure which isn't friendly
  let game5 = c.Game(board, c.GameOngoing(Black))
  assert c.get_legal_moves(game5, coord.a1)
    == Error(c.GetMovesWithInvalidFigure(c.SelectedFigureIsNotFriendly))
}

pub fn player_move_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.from_list([
        #(coord.b2, #(Pawn, Black)),
        #(coord.e7, #(Pawn, White)),
      ]),
    )
  let game = c.Game(board, c.GameOngoing(White))
  let expected_board =
    c.Board(
      white_king: coord.b2,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.e7, #(Pawn, White))]),
    )
  let move = c.StdFigureMove(coord.a1, coord.b2)
  assert c.player_move(game, move)
    == Ok(c.Game(expected_board, c.GameOngoing(Black)))
}

pub fn player_move_errors_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.new(),
    )
  let move = c.StdFigureMove(coord.a1, coord.a2)

  // Game is already won
  let game1 =
    c.Game(board, c.GameEnded(c.Victory(winner: White, by: c.Checkmate)))
  assert c.player_move(game1, move) == Error(c.PlayerMoveWhileGameAlreadyOver)

  // Game is already drawn
  let game2 = c.Game(board, c.GameEnded(c.Draw(by: c.MutualAgreement)))
  assert c.player_move(game2, move) == Error(c.PlayerMoveWhileGameAlreadyOver)
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
  let game = c.Game(board, c.GameOngoing(White))
  let selected_figure = coord.a1
  let assert Ok(actual_moves) = c.get_legal_moves(game, selected_figure)
  let expected_moves =
    [coord.b1]
    |> list.map(fn(to) { c.StdFigureMove(from: selected_figure, to:) })
    |> set.from_list
  assert actual_moves == expected_moves
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
  let game = c.Game(board, c.GameOngoing(White))
  let move = c.StdFigureMove(coord.h5, coord.b5)
  let assert Ok(c.Game(_, c.GameEnded(c.Draw(by: c.Stalemate)))) =
    c.player_move(game, move)
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
  let game = c.Game(board, c.GameOngoing(White))
  let move = c.StdFigureMove(coord.a6, coord.a8)
  let assert Ok(c.Game(
    _,
    c.GameEnded(c.Victory(winner: White, by: c.Checkmate)),
  )) = c.player_move(game, move)
}

pub fn forfeit_test() {
  let game = c.new_game()

  let assert Ok(c.Game(_, c.GameEnded(c.Victory(winner: Black, by: c.Forfeit)))) =
    c.forfeit(game)
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
  let game = c.Game(board, c.GameOngoing(White))
  let move = c.StdFigureMove(coord.e1, coord.e2)
  let assert Ok(c.Game(_, c.GameEnded(c.Draw(by: c.InsufficientMaterial)))) =
    c.player_move(game, move)
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
  let game = c.Game(board, c.GameOngoing(White))
  let move = c.StdFigureMove(coord.e1, coord.e2)
  let assert Ok(c.Game(_, c.GameEnded(c.Draw(by: c.InsufficientMaterial)))) =
    c.player_move(game, move)
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
  let game = c.Game(board, c.GameOngoing(White))
  let move = c.StdFigureMove(coord.e1, coord.e2)
  let assert Ok(c.Game(_, c.GameEnded(c.Draw(by: c.InsufficientMaterial)))) =
    c.player_move(game, move)
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
  let game = c.Game(board, c.GameOngoing(White))
  let move = c.StdFigureMove(coord.e1, coord.e2)
  let assert Ok(c.Game(_, c.GameEnded(c.Draw(by: c.InsufficientMaterial)))) =
    c.player_move(game, move)
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
  let game = c.Game(board, c.GameOngoing(White))
  let move = c.StdFigureMove(coord.e1, coord.e2)
  let assert Ok(c.Game(_, c.GameOngoing(Black))) = c.player_move(game, move)
}
