require "colorize"
require "io/console"

# Belt is like a utility belt for display the game and handling player input
module Belt
  def setup_selector
    @selector_row = 1
    @selector_col = 0
  end

  def selector(input, grid)
    system("clear")
    case input
    when "\e[A" then move_up(grid.grid) # Up
    when "\e[B" then move_down(grid.grid) # Down
    when "\e[C" then move_right(grid.grid) # Right
    when "\e[D" then move_left(grid.grid) # Left
    end
  end

  def show_board_with_selector(grid)
    display_grid = [
      grid.grid[0].map { |cell| cell[:display] },
      grid.grid[1]
    ]

    display_grid.each_with_index do |row, r|
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
    grid[0][@selector_col][:color].to_s
  end

  def move_down(_grid)
    "q"
  end

  def move_right(grid)
    @selector_col += 1 if @selector_col < grid[0].size - 1
  end

  def move_left(_grid)
    @selector_col -= 1 if @selector_col.positive?
  end
end

# This is the data storage for where the order of colors go for either guess or solve
class Order
  def initialize(colors)
    @order = []
    @guess_order = []
    @grid = [colors.map do |color|
      { color: color, display: "  ".colorize(background: color.to_sym) }
    end,
             %w[__ __ __ __ __ __]]
  end

  def add_color(piece_color, line)
    @order.push(piece_color) if line == "answer"
    return unless line == "guess"

    @guess_order.push(piece_color)
  end

  def get_color(position)
    @order[position]
  end

  def read_order
    @order
  end

  attr_reader :grid
end

# Main controller to start the game.
class GameController
  include Belt

  def initialize(playercount, codelength, guesses)
    if playercount == "1"
      @player = "player"
      @controller = "pc"
    elsif playercount == "2"
      @player = "playerTwo"
      @controller = "playerOne"
    else
      puts "This is only a 1-2 player game."
    end
    @code_length = codelength.to_i
    @game_time = guesses.to_i
    @colors = %w[white black blue red green yellow]
    @line = Order.new(@colors)
    setup_selector
  end

  def answer 
    @code_length.times do
      color =
        if @controller == "pc"
          @colors.sample
        else
          player_pick_color
        end

      break if color.nil?

      @line.add_color(color, "answer ")
    end
  end

  def player_pick_color
    loop do
      show_board_with_selector(@line)
      selected_color = selector(read_input, @line)

      return nil if selected_color == "q"
      return selected_color if @colors.include?(selected_color)
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
code_length = gets.chomp
puts "How many guess does the player get?"
guesses = gets.chomp
game = GameController.new(players, code_length, guesses)
game.answer 
game.play
