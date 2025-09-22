import gleam/dict

pub type Game {
  Game(board: Board, state: GameState)
}

pub type GameState {
  Checkmate(winner: Player)
  Forfeit(winner: Player)
  Stalemate
  WaitingOnNextMove(next_player: Player)
}

pub type Board =
  dict.Dict(Coordinate, Figure)

pub type Coordinate {
  Coordinate(file: File, row: Row)
}

pub type Figure {
  Pawn(Player)
  Knight(Player)
  Bishop(Player)
  Rook(Player)
  Queen(Player)
  King(Player)
}

pub type Player {
  White
  Black
}

pub type File {
  FileA
  FileB
  FileC
  FileD
  FileE
  FileF
  FileG
  FileH
}

pub type Row {
  Row1
  Row2
  Row3
  Row4
  Row5
  Row6
  Row7
  Row8
}

pub fn new_game() -> Game {
  let board =
    dict.from_list([
      #(a1, Rook(White)),
      #(b1, Knight(White)),
      #(c1, Bishop(White)),
      #(d1, Queen(White)),
      #(e1, King(White)),
      #(f1, Bishop(White)),
      #(g1, Knight(White)),
      #(h1, Rook(White)),
      #(a2, Pawn(White)),
      #(b2, Pawn(White)),
      #(c2, Pawn(White)),
      #(d2, Pawn(White)),
      #(e2, Pawn(White)),
      #(f2, Pawn(White)),
      #(g2, Pawn(White)),
      #(h2, Pawn(White)),
      #(a8, Rook(Black)),
      #(b8, Knight(Black)),
      #(c8, Bishop(Black)),
      #(d8, Queen(Black)),
      #(e8, King(Black)),
      #(f8, Bishop(Black)),
      #(g8, Knight(Black)),
      #(h8, Rook(Black)),
      #(a7, Pawn(Black)),
      #(b7, Pawn(Black)),
      #(c7, Pawn(Black)),
      #(d7, Pawn(Black)),
      #(e7, Pawn(Black)),
      #(f7, Pawn(Black)),
      #(g7, Pawn(Black)),
      #(h7, Pawn(Black)),
    ])
  Game(board:, state: WaitingOnNextMove(White))
}

pub const a1 = Coordinate(FileA, Row1)

pub const a2 = Coordinate(FileA, Row2)

pub const a3 = Coordinate(FileA, Row3)

pub const a4 = Coordinate(FileA, Row4)

pub const a5 = Coordinate(FileA, Row5)

pub const a6 = Coordinate(FileA, Row6)

pub const a7 = Coordinate(FileA, Row7)

pub const a8 = Coordinate(FileA, Row8)

pub const b1 = Coordinate(FileB, Row1)

pub const b2 = Coordinate(FileB, Row2)

pub const b3 = Coordinate(FileB, Row3)

pub const b4 = Coordinate(FileB, Row4)

pub const b5 = Coordinate(FileB, Row5)

pub const b6 = Coordinate(FileB, Row6)

pub const b7 = Coordinate(FileB, Row7)

pub const b8 = Coordinate(FileB, Row8)

pub const c1 = Coordinate(FileC, Row1)

pub const c2 = Coordinate(FileC, Row2)

pub const c3 = Coordinate(FileC, Row3)

pub const c4 = Coordinate(FileC, Row4)

pub const c5 = Coordinate(FileC, Row5)

pub const c6 = Coordinate(FileC, Row6)

pub const c7 = Coordinate(FileC, Row7)

pub const c8 = Coordinate(FileC, Row8)

pub const d1 = Coordinate(FileD, Row1)

pub const d2 = Coordinate(FileD, Row2)

pub const d3 = Coordinate(FileD, Row3)

pub const d4 = Coordinate(FileD, Row4)

pub const d5 = Coordinate(FileD, Row5)

pub const d6 = Coordinate(FileD, Row6)

pub const d7 = Coordinate(FileD, Row7)

pub const d8 = Coordinate(FileD, Row8)

pub const e1 = Coordinate(FileE, Row1)

pub const e2 = Coordinate(FileE, Row2)

pub const e3 = Coordinate(FileE, Row3)

pub const e4 = Coordinate(FileE, Row4)

pub const e5 = Coordinate(FileE, Row5)

pub const e6 = Coordinate(FileE, Row6)

pub const e7 = Coordinate(FileE, Row7)

pub const e8 = Coordinate(FileE, Row8)

pub const f1 = Coordinate(FileF, Row1)

pub const f2 = Coordinate(FileF, Row2)

pub const f3 = Coordinate(FileF, Row3)

pub const f4 = Coordinate(FileF, Row4)

pub const f5 = Coordinate(FileF, Row5)

pub const f6 = Coordinate(FileF, Row6)

pub const f7 = Coordinate(FileF, Row7)

pub const f8 = Coordinate(FileF, Row8)

pub const g1 = Coordinate(FileG, Row1)

pub const g2 = Coordinate(FileG, Row2)

pub const g3 = Coordinate(FileG, Row3)

pub const g4 = Coordinate(FileG, Row4)

pub const g5 = Coordinate(FileG, Row5)

pub const g6 = Coordinate(FileG, Row6)

pub const g7 = Coordinate(FileG, Row7)

pub const g8 = Coordinate(FileG, Row8)

pub const h1 = Coordinate(FileH, Row1)

pub const h2 = Coordinate(FileH, Row2)

pub const h3 = Coordinate(FileH, Row3)

pub const h4 = Coordinate(FileH, Row4)

pub const h5 = Coordinate(FileH, Row5)

pub const h6 = Coordinate(FileH, Row6)

pub const h7 = Coordinate(FileH, Row7)

pub const h8 = Coordinate(FileH, Row8)
