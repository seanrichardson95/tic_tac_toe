class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]]              # diagonals
  CENTER_SQUARE = 5

  def initialize
    @squares = {}
    reset
  end

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def immediate_threat(opponent_marker)
    WINNING_LINES.each do |line|
      three_squares = @squares.values_at(*line)
      next if all_marked?(three_squares)
      if count_marker(three_squares, opponent_marker) == 2
        line.each { |idx| return idx if @squares[idx].unmarked? }
      end
    end
    nil
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  private

  def count_marker(squares, marker)
    squares.collect(&:marker).count(marker)
  end

  def three_identical_markers?(three_squares)
    return false unless all_marked?(three_squares)
    count_marker(three_squares, three_squares[0].marker) == 3
  end

  def all_marked?(line_of_squares)
    line_of_squares.all?(&:marked?)
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize
    @marker = INITIAL_MARKER
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_reader :marker, :name
  attr_accessor :score

  def initialize(marker)
    @marker = marker
    @score = 0
  end

  def tally_win
    self.score += 1
  end

  def joinor(nums, delim=", ", last_delim="or")
    if nums.size == 1
      nums[0].to_s
    elsif nums.size == 2
      "#{nums[0]} #{last_delim} #{nums[1]}"
    elsif nums.size > 2
      nums[0..-2].join(delim) + " #{last_delim} " + nums[-1].to_s
    end
  end
end

class Human < Player
  def initialize
    @score = 0
  end

  def move(board)
    puts "Choose a square (#{joinor(board.unmarked_keys)}): "
    square = pick_valid_square_number(board)
    board[square] = marker
  end

  def pick_valid_square_number(board)
    loop do
      square = gets.chomp
      if square.to_f != square.to_i
        puts "Sorry, please only input whole numbers"
      elsif board.unmarked_keys.include?(square.to_i)
        return square.to_i
      else
        puts "Sorry, that's not a valid choice"
      end
    end
  end

  def assign_marker(new_marker)
    @marker = new_marker
  end

  def assign_name
    choice = nil
    puts "What is your name?"
    loop do
      choice = gets.chomp
      break unless choice == ''
      puts "Sorry, you have to input something"
    end
    @name = choice
  end
end

class Computer < Player
  COMPUTER_NAMES = ['R2D2', 'Sonny', 'Number 5']
  COMPUTER_MARKER = 'O'

  def initialize
    super(COMPUTER_MARKER)
    @name = COMPUTER_NAMES.sample
  end

  def move(board, human_marker)
    @has_moved = false
    offensive_move(board)
    defensive_move(board, human_marker)
    center_move(board)
    random_move(board)
  end

  private

  def offensive_move(board)
    winning_spot = board.immediate_threat(marker)
    return unless !!winning_spot
    board[winning_spot] = marker
    @has_moved = true
  end

  def defensive_move(board, human_marker)
    return if @has_moved
    threat = board.immediate_threat(human_marker)
    return unless !!threat
    board[threat] = marker
    @has_moved = true
  end

  def center_move(board)
    return if @has_moved
    return unless board.unmarked_keys.include?(Board::CENTER_SQUARE)
    board[Board::CENTER_SQUARE] = marker
    @has_moved = true
  end

  def random_move(board)
    return if @has_moved
    board[board.unmarked_keys.sample] = marker
  end
end

class GameEngine
  attr_reader :board, :human

  def initialize
    @board = Board.new
    @human = Human.new
  end

  private

  def continue
    puts "(Press enter to continue)"
    gets
  end

  def clear
    system 'clear'
  end
end

class TTTGame < GameEngine
  # put HUMAN_MARKER, COMPUTER_MARKER, or "Choose" here
  FIRST_TO_MOVE = "Choose"
  MAX_WINS = 2

  attr_reader :computer
  attr_accessor :current_marker, :goes_first

  def initialize
    super
    @computer = Computer.new
    human.assign_name
  end

  def play
    display_welcome_message
    enter_tutorial if tutorial?
    choose_marker
    loop do
      game_setup
      main_game
      break unless play_again?("a new game")
      reset_game
    end
    display_goodbye_message
  end

  private

  def game_setup
    setup_first_move
    display_wins_needed
  end

  def display_wins_needed
    puts "\nYou can quit after the end of each round"
    puts "OR you can try to continue until someone"
    puts "wins #{MAX_WINS} times and is crowned the ULTIMATE WINNER"
    continue
  end

  def tutorial?
    puts "Would you like to enter a tutorial? (y/n)"
    choice = nil
    loop do
      choice = gets.chomp.downcase
      break if %w(y n).include?(choice)
      puts "Sorry, please only enter 'y' or 'n'"
    end
    choice == 'y'
  end

  def enter_tutorial
    tutorial = TTTTutorial.new
    tutorial.play
  end

  def choose_marker
    clear
    choice = nil
    puts "Please choose one character to be your marker"
    puts "(The computer's marker is '#{computer.marker}' so don't pick that)"
    loop do
      choice = gets.chomp
      break if valid_marker?(choice)
    end
    human.assign_marker(choice)
  end

  def valid_marker?(choice)
    if choice.size != 1
      puts "I'm sorry, your marker must be one character"
    elsif choice.upcase == computer.marker
      puts "I'm sorry, that's the computer's marker"
    elsif choice == " "
      puts "Your marker cannot be a space"
    else
      true
    end
  end

  def setup_first_move
    self.goes_first = FIRST_TO_MOVE == "Choose" ? choose_first : FIRST_TO_MOVE
    self.current_marker = goes_first
  end

  def choose_first
    choice = nil
    puts "\nWould you like to go first or second?"
    puts "Enter '1' to go first or '2' to go second"
    loop do
      choice = gets.chomp
      break if %w(1 2).include? choice
      puts "\nSorry, please input either '1' or '2'"
    end
    choice == '1' ? human.marker : computer.marker
  end

  def main_game
    loop do
      reset
      display_board
      player_move
      adjust_scores
      display_result
      break if game_over? || !play_again?("another round")
      display_play_again_message
    end
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def current_player_moves
    if human_turn?
      human.move(board)
      self.current_marker = computer.marker
    else
      computer.move(board, human.marker)
      self.current_marker = human.marker
    end
  end

  def human_turn?
    current_marker == human.marker
  end

  def adjust_scores
    case board.winning_marker
    when human.marker
      human.tally_win
    when computer.marker
      computer.tally_win
    end
  end

  def reset
    board.reset
    self.current_marker = goes_first
    clear
  end

  def reset_game
    board.reset
    clear
    computer.score = 0
    human.score = 0
  end

  def play_again?(message)
    answer = nil
    loop do
      puts "Would you like to play #{message}? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def max_wins_achieved?
    human.score == MAX_WINS || computer.score == MAX_WINS
  end

  def game_over?
    if max_wins_achieved?
      display_ultimate_winner
      true
    else
      false
    end
  end

  def display_ultimate_winner
    case board.winning_marker
    when human.marker
      puts "Congratulations, #{human.name} is the ULTIMATE WINNER!"
    when computer.marker
      puts "#{computer.name} is the ULTIMATE WINNER"
      puts "Better luck next time!"
    end
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def display_welcome_message
    clear
    puts "Hello #{human.name}, welcome to Tic Tac Toe!"
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def display_board
    puts "You're a #{human.marker}. #{computer.name} is a #{computer.marker}."
    puts ""
    board.draw
    puts ""
  end

  def display_scoreboard
    puts ""
    puts "------Scoreboard------"
    puts "Human: #{human.score}   Computer: #{computer.score}"
    unless max_wins_achieved?
      puts "First to #{MAX_WINS} is the ultimate winner!"
    end
    puts ""
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "#{human.name} won!"
    when computer.marker
      puts "#{computer.name} won!"
    else
      puts "It's a tie!"
    end

    display_scoreboard
  end

  def clear_screen_and_display_board
    clear
    display_board
  end
end

class TTTTutorial < GameEngine
  def initialize
    super
    human.assign_marker('X')
  end

  def play
    display_welcome_message
    display_instructions
    move_tutorial
    display_winning_conditions
    display_goodbye_message
  end

  private

  def display_welcome_message
    clear
    puts "Welcome to the Tic Tac Toe tutorial!"
    continue
  end

  def display_instructions
    clear
    puts "Tic Tac Toe is a 2-player board game played on a 3x3 grid."
    puts "Players take turns marking a square."
    puts "The first player to mark 3 squares in a row wins."
    continue
  end

  def move_tutorial
    clear
    display_numbers_on_board
    practice_entering_numbers
  end

  def display_winning_conditions
    clear
    puts "There are three ways you can win:"
    continue
    display_horizontal_win
    display_vertical_win
    display_diagonal_win
  end

  def display_horizontal_win
    board.reset
    puts "You can get three in a row horizontally:"
    (1..3).each { |key| board[key] = 'X' }
    board.draw
    continue
  end

  def display_vertical_win
    clear
    board.reset
    puts "You can get three in a row vertically:"
    [2, 5, 8].each { |key| board[key] = 'X' }
    board.draw
    continue
  end

  def display_diagonal_win
    clear
    board.reset
    puts "Or you can get three in a row diagonally:"
    [1, 5, 9].each { |key| board[key] = 'X' }
    board.draw
    continue
  end

  def display_numbers_on_board
    puts "The board is numbered, like so...\n"
    (1..9).each { |key| board[key] = key.to_s }
    board.draw
    puts "Next, we'll practice placing moves on the board"
    continue
  end

  def display_board
    clear
    puts ""
    board.draw
    puts ""
  end

  def practice_entering_numbers
    board.reset
    display_board
    enter_numbers
  end

  def enter_numbers
    loop do
      human.move(board)
      display_board
      if board.full?
        continue
        break
      end
      choice = enter_or_continue
      break if choice == 'exit'
    end
  end

  def enter_or_continue
    puts "Hit 'enter' to continue or type 'exit' to move on"
    gets.chomp
  end

  def display_goodbye_message
    puts "That concludes this tutorial!"
    puts "Good luck!"
    continue
  end
end

game = TTTGame.new
game.play
