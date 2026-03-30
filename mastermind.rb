require "colorize"
require "io/console"

module Display
  attr_accessor :history, :screen

  def setup_display(colors, max_guesses, code_length)
    @history = Array.new(max_guesses * 2) do |i|
      {row_num: i,
      pegs: Array.new(code_length) { empty_cell }}
    end
    @screen = [colors.map do |color|
      {color: color, display: "  ".colorize(background: color.to_sym) }
    end,
               %w[__ __ __ __ __ __]]
  end

  def board_with_selector(selector_col)
    display_grid(@screen).each_with_index do |row, r|
      line = row.each_with_index.map do |cell, c|
        if r == 1 && c == selector_col
          "^^"
        else
          cell
        end
      end
      puts line.join(" ")
    end
  end

  def show_progress(board, player, guesses = 0)
    key = board.players[player]
    line = key[:queue]
    if player == :player_one
      print line.map { |color| "  ".colorize(background: color.to_sym) }.join(" ")
    else
      print line[guesses].map { |color| "  ".colorize(background: color.to_sym) }.join(" ")
    end
    puts
    puts
  end

  def display_history(data, round, code_length)
    rows_to_show = round * 2
    data.first(rows_to_show).each do |row|
      print "#{row[:row_num] + 1}: "
      row[:pegs].first(code_length).each do |cell|
        print cell[:display]
        print " "
      end
      puts
      puts ("____" * code_length)
      puts
    end
  end

  private

  def empty_cell
    { number: nil, color: nil, display: "  ".colorize(background: :light_black) }
  end

  def display_grid(screen)
    [
      screen[0].map { |cell| cell[:display] },
      screen[1]
    ]
  end
end

module Logic
  def compare_guess(answer, guess)
    line = []
    pegs = guess.clone
    count = answer.tally.clone
    guess.each_with_index do |element, index|
      if element == answer[index]
        line.push("red")
        pegs[index] = "correct"
        count[element] -= 1
      end
    end
    pegs.each_with_index do |element, index|
      if count.include?(element) && (count[element] > 0)
        line.push("white")
        count[element] -= 1
      end
    end
    return line
  end

  def modify_history(history, pins, round, parity)
    row = (parity == :even ? 0 : 1) + ((round - 1) * 2)

    history[row][:pegs].each_with_index do |peg, col|
      color = pins[col]
      if color.nil?
        return
      end
      peg[:color] = color
      peg[:display] = "  ".colorize(background: color.to_sym)
    end
  end
  def number_history(history, colors, guess)
    guess.times do |num|
        history[num][:pegs].each do | peg |
          if !(colors.index(peg[:color]).nil?)
            peg[:number] = (colors.index(peg[:color]) + 1)
          else
            peg[:number] = 0
          end
        end
      end
  end

  def simulate_feedback(code, guess)
    code_length = code.length
    reds = code.each_with_index.count { |num, i| num == guess[i] }
    code_counts = code.tally
    guess_counts = guess.tally

    total_matches = guess_counts.sum do |num, count|
      [count, code_counts[num] || 0].min
    end
    whites = total_matches - reds
    feedback = Array.new(reds, 4) + Array.new(whites, 1)
    feedback + Array.new(code_length - feedback.length, 0)
  end

  def pc_guess(p, history, round)
    return [1,1,2,2] if round == 0

    last_guess = history[(round - 1) * 2][:pegs]
                    .map { |cell| cell[:number] }
                    .compact

    last_feedback = history[(round * 2) - 1][:pegs]
                      .map { |cell| cell[:number] }
                      .compact
    p = p.select do |code|
      simulate_feedback(code, last_guess).sort == last_feedback.sort
    end

    [p.first, p]
  end
end

module PlayerInput
  def read_input
    key = $stdin.getch

    if key == "\e"
      key << $stdin.getch
      key << $stdin.getch
    end

    key
  end
  def get_input(prompt)
    loop do
      print prompt
      input = gets.chomp
      return input.to_s if input == "breaker" || input == "master"
      puts "please enter either breaker or master"
    end
  end
  def get_integer_input(prompt)
    loop do
      print prompt
      input = gets.chomp
      return input.to_i if input =~ /\A\d+\z/ # matches only digits (0-9)

      puts "Please enter a valid number!"
    end
  end
end

module Selector
  attr_accessor :selector_col

  def setup_selector
    @seletor_row = 1
    @selector_col = 0
  end

  def selector(input, grid)
    system("clear")
    case input
    when "\e[A" then move_up(grid) # Up
    when "\e[B" then move_down(grid) # Down
    when "\e[C" then move_right(grid) # Right
    when "\e[D" then move_left(grid) # Left
    end
  end

  def move_up(_grid)
    "submit"
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

class Storage
  attr_reader :grid, :players, :grid_rvw

  def initialize(_colors, guesses, _code_length)
    @players = {
      player_one: { player: "player one", queue: [] },
      player_two: { player: "player two", queue: Array.new(guesses) { [] } }
    }
  end

  def add_color(piece_color, line, key = 0)
    @players[:player_one][:queue].push(piece_color) if line == "answer"
    return unless line == "guess"

    @players[:player_two][:queue][key].push(piece_color)
  end
end

class Game
  include PlayerInput
  include Selector
  include Logic
  include Display

  def initialize(whois)
    @player = (whois == "breaker" ? :player_two : :pc_two)
    @controller = (whois == "master" ? :player_one : :pc)
    @code_length = 4
    @max_guesses = 12
    @colors = %w[white black blue red green yellow]
    @board = Storage.new(@colors, @max_guesses, @code_length)
    setup_selector
    setup_display(@colors, @max_guesses, @code_length)
  end

  def color_pick
    board_with_selector(@selector_col)
    input = selector(read_input, @screen)

    case input
    when "submit"
      @screen[0][@selector_col][:color].to_s
    when "q"
      "blank"
    end
  end

  def turn(player)
    num = 0
    case player
    when :pc
      @code_length.times do
        @board.players[:player_one][:queue] << @colors.sample
      end
    when :pc_two
      solution = @board.players[:player_one][:queue]
      digits = [1, 2, 3, 4, 5, 6]
      possibilities = digits.repeated_permutation(@code_length).to_a
      until num == @max_guesses
        int = 0
        line = pc_guess(possibilities, @history, num)
          if !(num == 0)
            guess = line[0]
            possibilities = line[1].clone
          else
            guess = line
          end
        until int == @code_length
          peg = guess[int]
          display_history(@history, num, @code_length)
          show_progress(@board, :player_two, num)
          color = @colors[peg - 1]
          sleep(1)
          system("clear")
          @board.players[:player_two][:queue][num] << color
          int += 1
        end
        guess = @board.players[:player_two][:queue][num]
        modify_history(@history, guess, num + 1, :even)
        corrections = compare_guess(solution, guess)
        if solution == guess
          modify_history(@history, corrections, num + 1, :odd)
          display_history(@history, num + 1, @code_length)
          return "You lost"
        end
           
        modify_history(@history, corrections, num + 1, :odd)
        number_history(@history, @colors, (num + 1) * 2)
        num += 1
      end
      puts "You win!"
    when :player_one
      until num == @code_length
        show_progress(@board, player)
        result = color_pick
        if result
          @board.players[player][:queue] << result
          num += 1
        end
      end
    when :player_two
      solution = @board.players[:player_one][:queue]
      until num == @max_guesses
        int = 0
        until int == @code_length
          display_history(@history, num, @code_length)
          show_progress(@board, player, num)
          puts "guesses left #{@max_guesses - num}"
          result = color_pick
          if result
            @board.players[player][:queue][num] << result
            int += 1
          end
        end
        guess = @board.players[player][:queue][num]
        modify_history(@history, guess, num + 1, :even)
        corrections = compare_guess(solution, guess)
        return "You won!" if solution == guess

        modify_history(@history, corrections, num + 1, :odd)
        num += 1
      end
      puts "computer wins!"
      puts solution
    end
  end

  def run
    puts "player one's turn. press enter to begin!"
    gets.chomp
    turn(@controller)
    puts "player two's turn to guess. press enter to begin!"
    gets.chomp
    puts turn(@player)
    
  end
end

class Main
  include PlayerInput
  def main
    who = get_input("Who are you going to play as (breaker/master)")
    
    game = Game.new(who)
    game.run
  end
end

main = Main.new
main.main
