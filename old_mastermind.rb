require "colorize"
require "io/console"

# Belt is like a utility belt for displaying the game, handling player input, handling data
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

  def move_down(_grid)
    "q"
  end

  def move_right(grid)
    @selector_col += 1 if @selector_col < grid[0].size - 1
  end

  def move_left(_grid)
    @selector_col -= 1 if @selector_col.positive?
  end

  def show_progress(players, player, guesses)
    key = players[player]
    line = key[:queue]
    if player == :player_one
      print line.map { |color| "  ".colorize(background: color.to_sym) }.join(" ")
    else
      print line[guesses].map { |color| "  ".colorize(background: color.to_sym) }.join(" ")
    end
    puts
    puts
  end

  def compare_guess(answer, guess)
    line = []
    guess.each_with_index do |element, index|
      if element == answer[index]
        line.push("green")
      elsif answer.include?(element)
        line.push("yellow")
      else
        line.push("red")
      end
    end
  end

  def display_history(data, round, code_length)
    rows_to_show = round * 2

    data.grid_rvw.first(rows_to_show).each do |row|
      row.first(code_length).each do |cell|
        print cell[:display]
        print " "
      end
      puts
      puts
    end
  end

  def modify_history(data, line, round, parity)
    max = round * 2

    start = parity == :even ? 0 : 1

    (start...max).step(2) do |row|
      queue = line[row / 2]
      data.add_correction(row, queue)
    end
  end
end

# This is the data storage for where the order of colors go for either guess or solve
class Order
  attr_reader :grid, :players, :grid_rvw

  def initialize(colors, guesses, code_length)
    @players = {
      player_one: { player: "player one", queue: [] },
      player_two: { player: "player two", queue: Array.new(guesses) { [] } }
    }
    @grid_rvw = Array.new(guesses * 2) do
      Array.new(code_length) { empty_cell }
    end
    @grid = [colors.map do |color|
      { color: color, display: "  ".colorize(background: color.to_sym) }
    end,
             %w[__ __ __ __ __ __]]
  end

  def add_color(piece_color, line, key = 0)
    @players[:player_one][:queue].push(piece_color) if line == "answer"
    return unless line == "guess"

    @players[:player_two][:queue][key].push(piece_color)
  end

  def add_correction(row, array)
    array.each_with_index do |color, index|
      @grid_rvw[row][index][:color] = color
      @grid_rvw[row][index][:display] = "  ".colorize(background: color.to_sym)
    end
  end

  def get_color(position)
    @players[:player_one][:queue][position]
  end

  private

  def empty_cell
    { color: nil, display: "  ".colorize(background: :light_black) }
  end
end

# Main controller to start the game.
class GameController
  include Belt

  attr_reader :controller

  def initialize(playercount, codelength, guesses)
    @player = :player_two
    @controller = playercount == "2" ? :player_one : :pc
    @code_length = codelength.to_i
    @game_guesses = guesses.to_i
    @colors = %w[white black blue red green yellow]
    @line = Order.new(@colors, @game_guesses, @code_length)
    setup_selector
  end

  def answer
    @code_length.times do
      color =
        if @controller == :pc
          @colors.sample
        else
          pick_color(@controller)
        end

      break if color.nil?

      @line.add_color(color, "answer", 0)
    end
  end

  def pick_color(player, round = 0, code = 0)
    loop do
      show_progress(@line.players, player, round)

      selected_color = selector(read_input, @line)
      modify_history(@line, @line.players[:player_two][:queue], round, :even)
      display_history(@line, round, code)
      comp = compare_guess(@line.players[:player_one][:queue], @line.players[:player_two][:queue][round])
      if comp.length == @code_length
        modify_history(@line, comp, 1, :odd)
        display_history(@line, round, code)
      end
      return nil if selected_color == "q"
      return selected_color if @colors.include?(selected_color)
    end
  end

  def round(code, round_num)
    code.times do
      color = pick_color(@player, round_num, code)
      break if color.nil?

      @line.add_color(color, "guess", round_num)
    end
  end

  def play
    loop do
      show_board_with_selector(@line)
      @game_guesses.times do |round_number|
        puts "#{@player} #{round_number + 1} turn. Press Enter when ready."
        gets.chomp
        round(@code_length, round_number)
      end
    end
  end

  def win(player)
    puts "#{player} won!"
    gets.chomp
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
