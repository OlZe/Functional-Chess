import birdie
import chess.{Bishop, Black, Knight, Pawn, Queen, Rook, White} as c
import chess/coordinates as coord
import chess/text_renderer as r
import gleam/dict
import gleam/option.{None, Some}
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let before = c.Game(board, c.GameOngoing(Black), None)

  // Make a double pawn move as black to allow en passant
  let assert Ok(after) =
    c.player_move(
      before,
      c.PlayerMovesFigure(c.StandardFigureMove(coord.a7, coord.a5)),
    )

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
  let before = c.Game(board, c.GameOngoing(Black), None)

  // Make a double pawn move as black to allow en passant
  let assert Ok(after) =
    c.player_move(
      before,
      c.PlayerMovesFigure(c.StandardFigureMove(coord.c7, coord.c5)),
    )

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
  let before = c.Game(board, c.GameOngoing(Black), None)

  // Make a single-step pawn move as black
  let assert Ok(after) =
    c.player_move(
      before,
      c.PlayerMovesFigure(c.StandardFigureMove(coord.a6, coord.a5)),
    )

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
  let before = c.Game(board, c.GameOngoing(Black), None)

  // Make a single-step pawn move as black
  let assert Ok(after) =
    c.player_move(
      before,
      c.PlayerMovesFigure(c.StandardFigureMove(coord.c6, coord.c5)),
    )

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
  let game = c.Game(board, c.GameOngoing(Black), None)
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
  let game = c.Game(board, c.GameOngoing(Black), None)
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
  let game = c.Game(board, c.GameOngoing(Black), None)
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
  let game = c.Game(board, c.GameOngoing(Black), None)
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
  let before = c.Game(board, c.GameOngoing(White), None)

  // Make a double pawn move as white to allow en passant
  let assert Ok(after) =
    c.player_move(
      before,
      c.PlayerMovesFigure(c.StandardFigureMove(coord.a2, coord.a4)),
    )

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
  let before = c.Game(board, c.GameOngoing(White), None)

  // Make a double pawn move as black to allow en passant
  let assert Ok(after) =
    c.player_move(
      before,
      c.PlayerMovesFigure(c.StandardFigureMove(coord.c2, coord.c4)),
    )

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
  let before = c.Game(board, c.GameOngoing(White), None)

  // Make a single-step pawn move as white
  let assert Ok(after) =
    c.player_move(
      before,
      c.PlayerMovesFigure(c.StandardFigureMove(coord.a3, coord.a4)),
    )

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
  let before = c.Game(board, c.GameOngoing(White), None)

  // Make a single-step pawn move as white
  let assert Ok(after) =
    c.player_move(
      before,
      c.PlayerMovesFigure(c.StandardFigureMove(coord.c3, coord.c4)),
    )

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
  let game1 = c.Game(board1, c.GameOngoing(White), None)
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
  let game2 = c.Game(board2, c.GameOngoing(White), None)
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
  let game3 = c.Game(board3, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
  let selected_figure = coord.a1
  let assert Ok(moves) = c.get_moves(game, selected_figure)

  game
  |> r.render_with_moves(selected_figure, moves)
  |> birdie.snap(title: "King cannot move: all adjacent squares blocked.")
}

pub fn knight_can_move_test() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.e8,
      other_figures: dict.from_list([#(coord.d4, #(Knight, White))]),
    )
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
        #(coord.c1, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
        #(coord.b1, #(Pawn, Black)),
      ]),
    )
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let game = c.Game(board, c.GameOngoing(White), None)

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

pub fn get_moves_errors_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.new(),
    )

  // Game is already won/lost
  let game1 =
    c.Game(board, c.GameEnded(c.Victory(winner: White, by: c.Checkmated)), None)
  assert c.get_moves(game1, coord.a1) == Error(c.GetMovesWhileGameAlreadyOver)

  // Game is already drawn
  let game2 = c.Game(board, c.GameEnded(c.Draw(by: c.MutualAgreement)), None)
  assert c.get_moves(game2, coord.a1) == Error(c.GetMovesWhileGameAlreadyOver)

  // Select figure which doesn't exist
  let game4 = c.Game(board, c.GameOngoing(White), None)
  assert c.get_moves(game4, coord.b2)
    == Error(c.GetMovesWithInvalidFigure(c.SelectedFigureDoesntExist))

  // Select figure which isn't friendly
  let game5 = c.Game(board, c.GameOngoing(Black), None)
  assert c.get_moves(game5, coord.a1)
    == Error(c.GetMovesWithInvalidFigure(c.SelectedFigureIsNotFriendly))
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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.a1, coord.b2))
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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.PawnPromotion(coord.e7, coord.e8, Queen))
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
  let start = c.Game(board, c.GameOngoing(Black), None)

  // Black double moves up to allow en passant
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.a7, coord.a5))
  let assert Ok(allowed_en_passant) = c.player_move(start, move)

  // White does en_passant
  let move = c.PlayerMovesFigure(c.EnPassant(from: coord.b5, to: coord.a6))
  let assert Ok(did_en_passant) = c.player_move(allowed_en_passant, move)

  combine_renders(r.render(allowed_en_passant), r.render(did_en_passant))
  |> birdie.snap(
    "White en passant's from B5 to A6 and captures the black pawn on A5",
  )
}

pub fn player_move_errors_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.e8,
      other_figures: dict.new(),
    )
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.a1, coord.a2))

  // Game is already won
  let game1 =
    c.Game(board, c.GameEnded(c.Victory(winner: White, by: c.Checkmated)), None)
  assert c.player_move(game1, move) == Error(c.PlayerMoveWhileGameAlreadyOver)

  // Game is already drawn
  let game2 = c.Game(board, c.GameEnded(c.Draw(by: c.MutualAgreement)), None)
  assert c.player_move(game2, move) == Error(c.PlayerMoveWhileGameAlreadyOver)
}

pub fn player_move_keeps_previous_state_test() {
  let board =
    c.Board(
      white_king: coord.a1,
      black_king: coord.a8,
      other_figures: dict.from_list([
        #(coord.e4, #(Pawn, White)),
      ]),
    )
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.e4, coord.e5))
  let assert Ok(after) = c.player_move(before, move)

  let assert Some(#(previous_move_from_after, previous_state_from_after)) =
    after.previous_state

  assert previous_move_from_after == move
  assert previous_state_from_after == before
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
  let game = c.Game(board, c.GameOngoing(White), None)
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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.h5, coord.b5))
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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.a6, coord.a8))
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(title: "Move A6 to A8 results in checkmate for white.")
}

pub fn forfeit_test() {
  let before = c.new_game()

  let assert Ok(after) = c.player_move(before, c.PlayerForfeits)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap("White forfeited in starting position.")
}

pub fn draw_through_mutual_agreement_test() {
  let before = c.new_game()

  let assert Ok(after) = c.player_move(before, c.PlayersAgreeToDraw)

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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.e1, coord.e2))
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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.e1, coord.e2))
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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.e1, coord.e2))
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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.e1, coord.e2))
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
  let before = c.Game(board, c.GameOngoing(White), None)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.e1, coord.e2))
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(
    title: "Move E1 to E2 does not result in draw: bishops are on different colours.",
  )
}

fn combine_renders(before: String, after: String) {
  "Start:\n" <> before <> "\n---------------------\nAfter:\n" <> after
}
