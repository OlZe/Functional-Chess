import birdie
import chess.{Bishop, Black, Knight, Pawn, Queen, Rook, White} as c
import chess/algebraic_notation as san
import chess/coordinates as coord
import chess/text_renderer as r
import gleam/dict
import gleam/list
import gleam/string

pub fn basic_pawn_move_test() {
  let game = c.new_game()
  let move = c.StandardFigureMove(from: coord.e2, to: coord.e4)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Normal pawn move has correct SAN:")
}

pub fn basic_knight_move_test() {
  let game = c.new_game()
  let move = c.StandardFigureMove(from: coord.b1, to: coord.c3)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Normal knight move has correct SAN:")
}

pub fn basic_capture_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.e3, #(Bishop, White)),
          #(coord.f2, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.StandardFigureMove(from: coord.e3, to: coord.f2)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Unambigous bishop capture move has correct SAN:")
}

pub fn basic_pawn_capture_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.e3, #(Pawn, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.StandardFigureMove(from: coord.e3, to: coord.f4)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Pawn capture move has correct SAN:")
}

pub fn short_castle_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.h1, #(Rook, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.ShortCastle

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Short castle has correct SAN:")
}

pub fn long_castle_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.a1, #(Rook, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.LongCastle

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Long castle has correct SAN:")
}

pub fn disambiguation_by_coord_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.a1, #(Queen, White)),
          #(coord.a2, #(Queen, White)),
          #(coord.b1, #(Queen, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.StandardFigureMove(coord.a1, coord.b2)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Ambigous move is disambiguated by coord in SAN:")
}

pub fn disambiguation_by_file_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.a1, #(Queen, White)),
          #(coord.a2, #(Queen, White)),
          #(coord.b1, #(Queen, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.StandardFigureMove(coord.b1, coord.b2)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Ambigous move is disambiguated by file in SAN:")
}

pub fn disambiguation_by_row_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.a1, #(Queen, White)),
          #(coord.a2, #(Queen, White)),
          #(coord.b1, #(Queen, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.StandardFigureMove(coord.a2, coord.b2)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Ambigous move is disambiguated by row in SAN:")
}

pub fn promotion_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e7,
        other_figures: dict.from_list([
          #(coord.a7, #(Pawn, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.PawnPromotion(coord.a7, coord.a8, Queen)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Pawn Promotion is correctly displayed in SAN:")
}

pub fn en_passant_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: Black,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.e7, #(Pawn, Black)),
          #(coord.d5, #(Pawn, White)),
        ]),
      ),
    )

  // Allow en passant for white
  let assert Ok(game) =
    c.player_move(game, c.StandardFigureMove(coord.e7, coord.e5))
  let move = c.EnPassant(coord.d5, coord.e6)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "En Passant is correctly displayed in SAN:")
}

pub fn complicated_move_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.h8,
        other_figures: dict.from_list([
          #(coord.d5, #(Queen, White)),
          #(coord.g5, #(Queen, White)),
          #(coord.d8, #(Queen, White)),
          #(coord.g8, #(Knight, Black)),
        ]),
      ),
    )
  let move = c.StandardFigureMove(coord.d5, coord.g8)

  render_move_with_san(game:, move:)
  |> birdie.snap(
    title: "Complicated move displays figure, coordinate disambiguation, takes, destination and checkmate in SAN.",
  )
}

pub fn checking_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.a2, #(Rook, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.StandardFigureMove(coord.a2, coord.e2)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Checking move has correct SAN:")
}

pub fn checkmating_test() {
  let assert Ok(game) =
    c.new_custom_game(
      first_player: White,
      board: c.Board(
        white_king: coord.e1,
        black_king: coord.e8,
        other_figures: dict.from_list([
          #(coord.a7, #(Rook, White)),
          #(coord.b7, #(Rook, White)),
          #(coord.f4, #(Pawn, Black)),
        ]),
      ),
    )
  let move = c.StandardFigureMove(coord.b7, coord.b8)

  render_move_with_san(game:, move:)
  |> birdie.snap(title: "Checkmating move has correct SAN:")
}

fn render_move_with_san(
  game game: c.GameState,
  move move: c.FigureMove,
) -> String {
  let assert Ok(after) = c.player_move(game:, move:)
  let assert Ok(description) = san.describe(game:, move:)

  [game, after]
  |> list.map(r.render)
  |> string.join("\nAfter move:\n")
  |> string.append("Before:\n", _)
  |> string.append("\nSAN described as: " <> description)
}
