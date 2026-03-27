require "colorize"
require "io/console"

module Belt
  def setup_selector
    @selector_row = 1
    @selector_col = 0
  end
  def selector(input, grid)
    case input
    when "\e[A" then move_up(grid) # Up
    when "\e[B" then move_down(grid) # Down
    when "\e[C" then move_right(grid) # Right
    when "\e[D" then move_left(grid) # Left
    else
      return nil
    end
  end
  def show_board_with_selector(grid)
    grid.each_with_index do |row, r|
      line = row.each_with_index.map do |cell, c|
        if r == @selector_row && c == @selector_col
          "^^"  
        else
          cell
        end
      end
      puts line.join(" ")
    end
  end
  def read_input
    key = $stdin.getch

    if key == "\e"
      key << $stdin.getch
      key << $stdin.getch
    end

    key
  end
  def move_up(grid)
    return grid[0][@selector_col][:color].to_s
  end

  def move_down(grid)
    "q".to_s
  end

  def move_right(grid)
    @selector_col += 1 if @selector_col < grid[0].size - 1
  end

  def move_left(grid)
    @selector_col -= 1 if @selector_col > 0
  end
end

class Order
  def initialize(colors)
    @order = []
    @guess_order = []
    @grid = [colors.map do |color| { color: color, display: "  ".colorize(:background => color.to_sym)}      
    end,
             %w[__ __ __ __ __ __]]
  end
  def add_color(piece_color, line)
    if line == "awnser"
      @order.push(piece_color)
    end
    if line == "guess"
      @guess_order.push(piece_color)
    end
  end
  def get_color(position)
    @order[position]
  end
  def get_order
    @order
  end
  def grid
    @grid
  end
end


class Game_Controller
  include Belt
  def initialize(playerCount, codeLength, guesses)
    if playerCount == "1"
      @player = "player"
      @controller = "pc"
    elsif playerCount == "2"
      @player = "playerTwo"
      @controller = "playerOne"
    else
      puts "This is only a 1-2 player game."
    end
    @code_length = codeLength.to_i
    @game_time = guesses.to_i
    @colors = ["white", "black", "blue", "red", "green", "yellow"]
    @line = Order.new(@colors)
    setup_selector
  end
  def get_awnser
    @code_length.times do
    if @controller == "pc"
        @line.add_color(@colors.sample, "awnser")
    elsif @controller == "playerOne"
        selected_color = nil
        loop do
          system("clear")
          show_board_with_selector([
            @line.grid[0].map { |cell| cell[:display] },
            @line.grid[1]  
          ])
          input = read_input()
          selected_color = selector(input, @line.grid)
          if selected_color == "q"
            puts "Player pressed down! Exiting loop..."
            break
          elsif @colors.any?(selected_color)
            @line.add_color(selected_color, "awnser")
            break
          end
        end
      end
    end
  end
  def play
    @game_time.times do
        
    end
  end
end


puts "Welcome to mastermind. How many will be playing today?(1-2 player game)"
players = gets.chomp
puts "How long should the code be?"
codeLength = gets.chomp
puts "How many guess does the player get?"
guesses = gets.chomp
game = Game_Controller.new(players, codeLength, guesses)
game.get_awnser
game.play
