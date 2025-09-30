import birdie
import chess.{Bishop, Black, Knight, Pawn, Queen, Rook, White} as c
import chess/coordinates as coord
import chess/text_renderer as r
import gleam/dict
import gleam/list
import gleam/string

pub fn main() {
  stalemate_teasdfasdfst()
}

pub fn stalemate_teasdfasdfst() {
  let board =
    c.Board(
      white_king: coord.e1,
      black_king: coord.a8,
      other_figures: dict.from_list([
        #(coord.h7, #(Rook, White)),
        #(coord.h5, #(Rook, White)),
      ]),
    )
  let before = c.new_custom_game(board, White)
  let move = c.PlayerMovesFigure(c.StandardFigureMove(coord.h5, coord.b5))
  let assert Ok(after) = c.player_move(before, move)

  combine_renders(r.render(before), r.render(after))
  |> birdie.snap(title: "Move H5 to B5 results in stalemate.")
}

fn combine_renders(before: String, after: String) -> String {
  "Start:\n" <> before <> "\n---------------------\nAfter:\n" <> after
}

fn combine_n_renders(renders: List(String)) -> String {
  let content = string.join(renders, "\n---------------------\nNext:\n")
  "Start:\n" <> content
}
