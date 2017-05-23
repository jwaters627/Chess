class Player
  attr_reader :color
  
  def initialize(color, game)
    @color = color
    @board = game.board
    @game = game
  end
  
  def to_s
    @color.to_s
  end
end

class HumanPlayer < Player
  def get_move
    puts "#{@color}'s turn!"
    until @game.turn_over || @game.is_over?
      @game.render
      instr = STDIN.getch
      case instr
      when "f" then @game.select_cursor()
      when "q" then quit
        #when "." then save
      when "g" then @game.cancel_cursor
      when "w" then move_cursor([-1, 0])
      when "a" then move_cursor([0, -1])
      when "s" then move_cursor([1, 0])
      when "d" then move_cursor([0, 1])
      end
    end
  end
  
  def move_cursor(direction)
    if (0...8).include?(@game.cursor[0] + direction[0])
      @board[@game.cursor[0]][@game.cursor[1]].cursored = false
      @game.cursor[0] += direction[0]
      @board[@game.cursor[0]][@game.cursor[1]].cursored = true
    end
    if (0...8).include?(@game.cursor[1] + direction[1])
      @board[@game.cursor[0]][@game.cursor[1]].cursored = false
      @game.cursor[1] += direction[1]
      @board[@game.cursor[0]][@game.cursor[1]].cursored = true
    end
    @game.render
  end
end

class ComputerPlayer < Player
  
  def other_player
    @color == :white ? :black : :white
  end
  
  def get_move
    sleep(1.0/20.0)
    found_move = false
    all_pieces = @game.get_all_pieces(@color).shuffle
     chosen_piece = all_pieces.shift
    all_moves = chosen_piece.moves.flatten(1)
   
      
      until found_move
        if all_moves.empty?
          chosen_piece = all_pieces.shift
          all_moves = chosen_piece.moves.flatten(1)
        end
          start_pos = chosen_piece.position
          end_pos = all_moves.shift
          puts all_pieces
          puts "now"
          puts chosen_piece
          puts "now"
          print all_moves
        unless chosen_piece.nil?
          if @game.check_move(start_pos, end_pos)
            found_move = true
            break
          end
        end
      
      if all_pieces.empty? && all_moves.empty?
        puts "Congratulations #{other_player}! You won."
        exit(0)
      end
    end
    play_move(start_pos, end_pos)
  end
  
  def play_move(start_pos, end_pos)
    
    @game.select_cursor(start_pos)
    @game.select_cursor(end_pos)
  end
end