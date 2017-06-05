require "byebug"

class Square
  attr_accessor :max_yield, :yield, :population, :row, :col
  def initialize(row, col)
    @row = row
    @col = col
    @population = weighted_sample(POPULATION).to_f
    @max_yield = weighted_sample(MAX_YEILD)
  end
end

BOARD_SIZE = 15
MAX_YEILD = {500 => 1, 100 => 10, 50 => 40, 25 => 50}
POPULATION = {0 => 63, 10 => 1}

# Amount of food one person consumes
FOOD_CONSUMPTION = 2.0

# Annual growth rate
GROWTH_RATE = 1.05

# base emigration rate
EMIGRATION_RATE = 0.01

# Percent of people over capacity who emigrate every year
EMIGRATION_MODIFIER = 0.25

# Percent of hungry people who die every year
STARVATION_MODIFIER = 0.75
board = []

def weighted_sample(hash)
  collection = []
  hash.each { |key, value| value.times { collection << key } }
  collection.sample
end

def each_square(board)
  for row in 0..BOARD_SIZE 
    for col in 0..BOARD_SIZE
      yield(board[row][col])
    end
  end
end

def population_growth(board)
  each_square(board) do |square|
    unless square.population.zero?
      emigration_square = board[square.row + adj_square(square.row)][square.col + adj_square(square.col)]
      population_loss = 0
      population_gain = 0

      square.population *= GROWTH_RATE

      hunger = square.population - (square.max_yield / FOOD_CONSUMPTION)

      if hunger > 1
        population_loss += (hunger * STARVATION_MODIFIER) + (hunger * EMIGRATION_MODIFIER) 
        population_gain += (hunger * EMIGRATION_MODIFIER)
      end

      population_loss += square.population * EMIGRATION_RATE
      population_gain += square.population * EMIGRATION_RATE

      square.population -= population_loss
      emigration_square.population += population_gain

    end
  end
end

def total_population(board)
  total = 0
  each_square(board) do |square|
    total += square.population
  end
  total
end

def total_capacity(board)
  total = 0
  each_square(board) do |square|
    total += square.max_yield
  end
  total / FOOD_CONSUMPTION.to_i
end

def adj_square(pos)
  case pos
  when 0 then [0, 1, 1, 2].sample
  when BOARD_SIZE then [0, -1, -1, -2].sample
  when 1 then [-1, 0, 1, 2].sample
  when BOARD_SIZE - 1 then [1, 1, 0, -1, -1, -2].sample
  else [-2, -1, -1, 0, 1, 1, 2].sample
  end
end

def pop_disp(square)
  if square.population < 0.5
    color = "\e[37;1m"
  elsif square.population < 5
    color = "\e[32m"
  elsif square.population < 25
    color = "\e[33m"
  elsif square.population < 50
    color = "\e[31m"
  elsif square.population < 100
    color = "\e[35m"    
  else
    color = "\e[35;1m"
  end    
  " " * (7 - square.population.round(2).to_s.length > 0 ? 7 - square.population.round(2).to_s.length : 7) + color + "#{square.population.round(2)}\e[0m"
end

def yield_disp(square)
  "\e[34;1m#{square.max_yield > 99 ? square.max_yield : square.max_yield.to_s + ' '}\e[0m"
end

def print_game(board)
  puts "\e[H\e[2J"
  puts
  board.each do |row|
    row.each do |square|
      print " |" + yield_disp(square) + pop_disp(square) + "|"
    end
    puts
  end
end

for row in 0..BOARD_SIZE
  board << []
  for col in 0..BOARD_SIZE
    board[-1] << Square.new(row, col)
  end
end

# ===== GAME LOOP =====
counter = 1
total_cap = total_capacity(board)
while true
  print_game(board)
  population_growth(board)
  counter += 1
  puts
  puts " Year:                " + counter.to_s
  puts " Total Population:    " + total_population(board).round(2).to_s
  puts " Total capacity:      " + total_cap.to_s
  puts
  puts " GROWTH_RATE:         " + GROWTH_RATE.to_s
  puts " EMIGRATION_MODIFIER: " + EMIGRATION_MODIFIER.to_s
  puts " STARVATION_MODIFIER: " + STARVATION_MODIFIER.to_s
  puts " EMIGRATION_RATE:     " + EMIGRATION_RATE.to_s
  sleep(0.2)
end
