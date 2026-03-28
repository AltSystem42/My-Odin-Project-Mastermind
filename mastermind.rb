require "colorize"
require "io/console"

# Belt is like a utility belt for display the game and handling player input
module Belt
  def setup_selector
    @selector_row = 1
    @selector_col = 0
  end

  def selector(input, grid, player)
    system("clear")
    show_progress(grid.players, player)
    case input
    when "\e[A" then move_up(grid.grid) # Up
    when "\e[B" then move_down(grid.grid) # Down
    when "\e[C" then move_right(grid.grid) # Right
    when "\e[D" then move_left(grid.grid) # Left
    end
  end

  def show_board_with_selector(grid)
    display_grid(grid).each_with_index do |row, r|
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

  def display_grid(grid)
    [
      grid.grid[0].map { |cell| cell[:display] },
      grid.grid[1]
    ]
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

  def move_down(grid)
    "q"
  end

  def move_right(grid)
    @selector_col += 1 if @selector_col < grid[0].size - 1
  end

  def move_left(grid)
    @selector_col -= 1 if @selector_col.positive?
  end
  def show_progress(players, player)
    key = players[player]
    line = key[:queue]
    print line.map {|color| "  ".colorize(:background => color.to_sym)}.join(" ")
    puts
    puts
  end
end

# This is the data storage for where the order of colors go for either guess or solve
class Order
  def initialize(colors)
    @players = {
    player_one: {player: "player one", queue: []},
    player_two: {player: "player two", queue: []}
  }
    @grid = [colors.map do |color|
      { color: color, display: "  ".colorize(background: color.to_sym) }
    end,
             %w[__ __ __ __ __ __]]
  end

  def add_color(piece_color, line)
    @players[:player_one][:queue].push(piece_color) if line == "answer"
    return unless line == "guess"

    @players[:player_two][:queue].push(piece_color)
  end

  def get_color(position)
    @player_one[position]
  end

  def clear_guess
    @player_two = []
  end

  attr_reader :grid, :players
end

# Main controller to start the game.
class GameController
  include Belt
  attr_reader :controller
  def initialize(playercount, codelength, guesses)
    @player = :player_two
    @controller = if playercount == "2" then :player_one else "pc"
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
          player_pick_color(@controller)
        end

      break if color.nil?

      @line.add_color(color, "answer")
    end
  end

  def player_pick_color(player)
    loop do
      show_board_with_selector(@line)
      selected_color = selector(read_input, @line, player)

      return nil if selected_color == "q"
      return selected_color if @colors.include?(selected_color)
    end
  end

  def play
    @game_time.times do
      @code_length.times do
        color = player_pick_color(@player)
        break if color.nil?
        @line.add_color(color, "guess")
      end
      show_right_and_wrongs
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
puts "#{game.controller} goes first press enter when ready"
gets.chomp
game.answer
game.play
