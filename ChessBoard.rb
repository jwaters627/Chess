# # encoding: utf-8
require 'io/console'
require './ChessPieces'
require './ChessPlayer'

class String
  def black;          "\033[30m#{self}\033[0m" end
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def brown;          "\033[33m#{self}\033[0m" end
  def blue;           "\033[34m#{self}\033[0m" end
  def magenta;        "\033[35m#{self}\033[0m" end
  def cyan;           "\033[36m#{self}\033[0m" end
  def gray;           "\033[37m#{self}\033[0m" end
  def bg_black;       "\033[40m#{self}\033[0m" end
  def bg_red;         "\033[41m#{self}\033[0m" end
  def bg_green;       "\033[42m#{self}\033[0m" end
  def bg_brown;       "\033[43m#{self}\033[0m" end
  def bg_blue;        "\033[44m#{self}\033[0m" end
  def bg_magenta;     "\033[45m#{self}\033[0m" end
  def bg_cyan;        "\033[46m#{self}\033[0m" end
  def bg_gray;        "\033[47m#{self}\033[0m" end
  def bold;           "\033[1m#{self}\033[22m" end
  def reverse_color;  "\033[7m#{self}\033[27m" end
end

class Board
  attr_reader :board, :turn_over
  attr_accessor :cursor
  
  def initialize
    @board = create_board
    @cursor = [3,3]
    @selected_piece = nil
    @current_player = nil
    @finished = false
    @turn_over = false
    populate_board
  end
  
  def create_board
    board_array = Array.new(8) {Array.new(8) {nil}}
    gen_tiles(board_array)
  end
  
  def gen_tiles(aboard)
    aboard.each_with_index do |row, row_idx|
      row.each_with_index do |col, col_idx|
        aboard[row_idx][col_idx] = Tile.new(row_idx, col_idx)
      end
    end
  end
  
  def render
    system('clear')
    @board.each do |row|
      render_string = ""
      row.each do |atile|
        render_string << atile.to_s
      end
      puts render_string
    end
  end
  
  def populate_board
    starting_positions = {
      [0,0] => Rook.new(:black, [0,0], @board),
      [0,1] => Knight.new(:black, [0,1], @board),
      [0,2] => Bishop.new(:black, [0,2], @board),
      [0,3] => Queen.new(:black, [0,3], @board),
      [0,4] => King.new(:black, [0,4], @board),
      [0,5] => Bishop.new(:black, [0,5], @board),
      [0,6] => Knight.new(:black, [0,6], @board),
      [0,7] => Rook.new(:black, [0,7], @board),
      [7,0] => Rook.new(:white, [7,0], @board),
      [7,1] => Knight.new(:white, [7,1], @board),
      [7,2] => Bishop.new(:white, [7,2], @board),
      [7,3] => Queen.new(:white, [7,3], @board),
      [7,4] => King.new(:white, [7,4], @board),
      [7,5] => Bishop.new(:white, [7,5], @board),
      [7,6] => Knight.new(:white, [7,6], @board),
      [7,7] => Rook.new(:white, [7,7], @board),
    }
    
    [1, 6].each do |row|
      (0..7).each do |col|
        color = (row == 6 ? :white : :black)
        starting_positions[[row, col]] = Pawn.new(color, [row, col], @board)
      end
    end
    
    starting_positions.each_pair do |piece_pos, piece|
      @board[piece_pos[0]][piece_pos[1]].add_piece(piece)
    end
    
    @board[@cursor[0]][@cursor[1]].cursored = true
  end
  
  def dup
    new_board = create_board
    @board.each_with_index do |row, row_index|
      row.each do |tile, col_index|
        new_board[row_index][col_index] = tile.dup
      end
    end
  end
  
  def check_move(start_pos, end_pos)
    tile = @board[start_pos[0]][start_pos[1]]
    piece = tile.occupant
    possible_moves = piece.moves
    if possible_moves.flatten(1).include?(end_pos)
      if check_path(end_pos, possible_moves, piece)
        unless check_check(tile, @board[end_pos[0]][end_pos[1]])
          return true
        else
          
          # puts "That move puts you in check"
        end
      else
        # puts "There is a piece blocking this move"
      end
    else
      # puts "That move is not possible"
    end
    false
  end
  
  def get_all_pieces(color)
    result_tiles = @board.flatten.select do |tile| 
      !tile.occupant.nil? && tile.occupant.color == color 
    end
    result_tiles.map { |tile| tile.occupant }
  end
  
  def get_king(color)
    get_all_pieces(color).find{ |el| el.is_a? King }
  end    
  
  def in_check(color)
    other_color = (color == :white ? :black : :white)
    check_king = get_king(color)
    
    get_all_pieces(other_color).each do |enemy_piece|
      if check_path(check_king.position, enemy_piece.moves, enemy_piece)
        return true
      end
    end
    false
  end
  
  def check_check(start_tile, end_tile)
    piece = start_tile.remove_piece
    other_piece = end_tile.remove_piece
    end_tile.add_piece(piece)
    
    result = in_check(piece.color)
      
    end_tile.remove_piece
    start_tile.add_piece(piece)
    end_tile.add_piece(other_piece) unless other_piece.nil?
    
    result
  end
  
  def check_checkmate(color=:white)
    get_all_pieces(color).each do |my_piece|
      my_piece.moves.flatten(1).each do |possible_move|
        if check_move(my_piece.position, possible_move)
          return false
        end
      end
    end
    true
  end
  
  def move(start_pos, end_pos)
    start_tile = @board[start_pos[0]][start_pos[1]]
    end_tile = @board[end_pos[0]][end_pos[1]]
    
    if check_move(start_pos, end_pos)
      piece = start_tile.remove_piece
      end_tile.add_piece(piece)
      if piece.is_a?(Pawn) && (end_pos[0] == 0 || end_pos[0] == 7)
        color = piece.color
        end_tile.add_piece(Queen.new(color, end_pos, @board))
      end
      @turn_over = true
    end
    
    @current_player
    render
  end
  
  def check_path(end_pos, possible, moving_piece)
    color = moving_piece.color
    enemy_color = (color == :white ? :black : :white)
    path = possible.select{ |arry| arry.include?(end_pos)}.flatten(1)
    return false if path.empty?
    pos_in_path = path.index(end_pos)
    path[0..pos_in_path].each do |position|
      checked_tile = @board[position[0]][position[1]]
      unless checked_tile.occupant.nil?
        unless position == end_pos && checked_tile.occupant.color == enemy_color
          return false
        end
      end
    end
    true
  end
  
  def move_cursor(direction)
    if (0...8).include?(@cursor[0] + direction[0])
      @board[@cursor[0]][@cursor[1]].cursored = false
      @cursor[0] += direction[0]
      @board[@cursor[0]][@cursor[1]].cursored = true
    end
    if (0...8).include?(@cursor[1] + direction[1])
      @board[@cursor[0]][@cursor[1]].cursored = false
      @cursor[1] += direction[1]
      @board[@cursor[0]][@cursor[1]].cursored = true
    end
    render
  end
  
  def select_cursor(position=@cursor)
    if @selected_piece.nil?
      occupant = @board[position[0]][position[1]].occupant
      unless occupant.nil?
        if occupant.color == @current_player.color
          @selected_piece = position.dup
          @board[position[0]][position[1]].selected = true
        end
      end
    else
      move(@selected_piece, position)
      @board[@selected_piece[0]][@selected_piece[1]].selected = false
      @selected_piece = nil
    end
  end
  
  def cancel_cursor
    if @selected_piece
      @board[@selected_piece[0]][@selected_piece[1]].selected = false
      @selected_piece = nil
    end
  end
  
  def is_over?
    if check_checkmate(@current_player.color) || @finished
      return true
    end
    false
  end
  
  def get_move()
    until @turn_over || is_over?
      render
      instr = @current_player.get_input
      case instr
      when "f" then select_cursor()
      when "q" then quit
        #when "." then save
      when "g" then cancel_cursor
      when "w" then move_cursor([-1, 0])
      when "a" then move_cursor([0, -1])
      when "s" then move_cursor([1, 0])
      when "d" then move_cursor([0, 1])
      end
    end
  end
  
  def run
    turn = 0
    player_hash = {
      0 => HumanPlayer.new(:white, self),
      1 => ComputerPlayer.new(:black, self)
    }
    @current_player = player_hash[0]
    until is_over?
      @turn_over = false
      @current_player = player_hash[turn % 2]
      @current_player.get_move
      turn += 1
    end
    puts "Game over, gg"
    exit(0)
  end
end

class Tile
  attr_reader :occupant
  attr_accessor :cursored, :selected, :color
  
  def initialize(row, col)
    @position = [row, col]
    @color = ((row + col) % 2 == 0 ? :white : :black)
    @occupant_piece = " "
    @occupant = nil
    @cursored = false
    @selected = false
  end
  
  def add_piece(apiece)
    @occupant_piece = apiece.to_s
    @occupant = apiece
    @occupant.position = @position
    @occupant
  end
  
  def dup
    new_tile = Tile.new(@position[0], @position[1])
    new_tile.occupant = @occupant.dup
    new_tile.occupant_piece = @occupant_piece
    new_tile
  end
  
  def remove_piece
    @occupant_piece = " "
    temp_occ, @occupant = @occupant, nil
    temp_occ
  end
 
  def to_s
    contents = (" "+@occupant_piece+" ")
    if @cursored
      contents.bg_red
    elsif @selected
      contents.bg_green
    elsif @color == :black
      contents.bg_cyan
    else
      contents.bg_gray
    end
  end
end

b = Board.new
while true
  b.run
end
