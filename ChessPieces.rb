# encoding: utf-8
module SlidingPiece
  
  def in_bounds(result_hash)
    result_hash.each_key do |direction|
      result_hash[direction].select! do |el| 
        (0...8).include?(el[0]) && (0...8).include?(el[1])
      end
    end
    result_hash
  end
  
  def flatten_hash(result_hash)
    result_hash.values
  end
    
    
  def diagonal(pos)
    results = {
      :top_left => [],
      :bottom_right => [],
      :top_right => [],
      :bottom_left => []
    }
    
    
    (-8...0).each do |inc|
      results[:top_left] << [pos[0] + inc, pos[1] + inc]
    end
    
    (1..8).each do |inc|
      results[:bottom_right] << [pos[0] + inc, pos[1] + inc]
    end
    
    (-8...0).each do |inc|
      results[:bottom_left] << [pos[0] - inc, pos[1] + inc] unless inc == 0
    end
    
    (1..8).each do |inc|
      results[:top_right] << [pos[0] - inc, pos[1] + inc] unless inc == 0
    end
    
    results[:top_left].reverse!
    results[:bottom_left].reverse!
    flatten_hash(in_bounds(results))
  end
  
  def straight(pos)
    results = {
      :left => [],
      :up => [],
      :right => [],
      :down => []
    }
    
    (-8...0).each do |inc|
      results[:left] << [pos[0], pos[1] + inc]
    end
    
    (-8...0).each do |inc|
      results[:up] << [pos[0] + inc, pos[1]]
    end
    
    (1..8).each do |inc|
      results[:down] << [pos[0] + inc, pos[1]]
    end
    
    (1..8).each do |inc|
      results[:right] << [pos[0], pos[1] + inc]
    end
    
    results[:left].reverse!
    results[:up].reverse!
    flatten_hash(in_bounds(results))
    
  end
end

module SteppingPiece
  
  def step(pos, change1, change2)
    results = []
    change1.each do |two|
      change2.each do |one|
        results << [pos[0] + two, pos[1] + one] unless one.zero? && two.zero?
        results << [pos[0] + one, pos[1] + two] unless one.zero? && two.zero?
      end
    end
    
    results = results.select do |el| 
      (0...8).include?(el[0]) && (0...8).include?(el[1])
    end
    
    (results.map { |el| [el] }).uniq
  end
  
  def jump(pos)
    step(pos, [-2, 2], [-1, 1])
  end
  
  def king_step(pos)
    step(pos, [-1, 0, 1], [-1, 0, 1])
  end
  
  def pawn_step(pos, direction)
    result = []
    if direction == :down
      result << [pos[0] + 1, pos[1]]
      if pos[0] == 1
        result << [pos[0] + 2, pos[1]]
      end
    else
      result << [pos[0] - 1, pos[1]]
      if pos[0] == 6
        result << [pos[0] - 2, pos[1]]
      end
    end
    return result
  end
end

class Piece
  attr_accessor :position
  attr_reader :color
  def initialize(color, position, board)
    @color = color
    @position = position
    @symbol = "X".red
    @board = board
  end
  
  def to_s
    @symbol
  end
  
  def dup
    new_piece = self.class.new(@color, @position, @board.dup)
  end
end

class Rook < Piece
  include SlidingPiece
  
  def initialize(color, position, board)
    super
    @symbol = (color == :white ? "♖" : "♜")
  end
  
  def moves
    straight(@position)
  end
end

class Bishop < Piece
  include SlidingPiece
  
  def initialize(color, position, board)
    super
    @symbol = (color == :white ? "♗" : "♝")
  end
  
  def moves
    diagonal(@position)
  end
end

class Queen < Piece
  include SlidingPiece
  
  def initialize(color, position, board)
    super
    @symbol = (color == :white ? "♕" : "♛")
  end
  
  def moves
    diagonal(@position) + straight(@position)
  end
end

class Knight < Piece
  include SteppingPiece
  
  def initialize(color, position, board)
    super
    @symbol = (color == :white ? "♘" : "♞")
  end
  
  def moves
    jump(@position)
  end
end
  
class King < Piece
  include SteppingPiece
  
  def initialize(color, position, board)
    super
    @symbol = (color == :white ? "♔" : "♚")
  end
  
  def moves
    king_step(@position)
  end
end

class Pawn < Piece
  include SteppingPiece
  
  def initialize(color, position, board)
    super
    @symbol = (color == :white ? "♙" : "♟")
    @direction = (color == :white ? :up : :down)
  end
  
  def blocked_front(step_result)
    step_result.select { |step| @board[step[0]][step[1]].occupant.nil? }
  end
  
  def killer_instinct
    targets = []
    if @direction == :down
      target1 = @board[@position[0]+1][@position[1]+1]
      unless target1.nil?
        targets << [@position[0]+1, @position[1]+1] unless target1.occupant.nil?
      end
      target2 = @board[@position[0]+1][@position[1]-1]
      unless target2.nil?
        targets << [@position[0]+1, @position[1]-1] unless target2.occupant.nil?
      end
    else
      target1 = @board[@position[0]-1][@position[1]-1]
      unless target1.nil?
        targets << [@position[0]-1, @position[1]-1] unless target1.occupant.nil?
      end
      target2 = @board[@position[0]-1][@position[1]+1]
      unless target2.nil?
        targets << [@position[0]-1, @position[1]+1] unless target2.occupant.nil?
      end
    end
    
    
    targets = targets.select { |el| (0...8).include?(el[1]) }
    targets.map{|el| [el]}
  end
  
  def moves
    [blocked_front(pawn_step(@position, @direction))] + killer_instinct
  end
end

