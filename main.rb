require './skill_definitions.rb'

class Randomizer
  def self.sanity_coin(sanity)
    threshold = (50+sanity).clamp(5,95)
    (rand * 100) + threshold > 100
  end
end

def sanity_coin(sanity)
  Randomizer.sanity_coin(sanity)
end

class Skill
  def initialize(name, basepower, coins, coinpower)
    @name = name
    @basepower = basepower
    @coins = coins
    @coinpower = coinpower
  end

  attr_reader :name, :basepower, :coins, :coinpower

  def all_coins
    [@coinpower] * @coins
  end
  def some_coins(count)
    [@coinpower] * count.clamp(0, @coins)
  end

  def coin_summary
    all_coins.join('+')
  end

  def summary
    "#{@name}: #{@basepower} + (#{coin_summary})"
  end

  def coin_points
    @coins * @coinpower * 0.5
  end

  def point_cost
    @basepower + coin_points
  end

  def self.roll_generic(coins, sanity)
    1.upto(coins).map { |_| sanity_coin(sanity) ? :heads : :tails }
  end
  def self.show_generic_roll(roll_result)
    roll_result.map { |it| it == :heads ? 'H' : 'T' }.join "" 
  end

  def roll(roll_results, sanity)
    if roll_results.is_a? Numeric
      roll_results = Skill.roll_generic(roll_results, sanity)
    end
    coin_results = roll_results.map do |r|
      (r == :heads) ? @coinpower : 0
    end.sum
    coin_results + @basepower
  end
end

class Deck
  def initialize(skills)
    @skills = skills
  end

  def summary
    @skills.map { |index, it| "#{index}: #{it.summary}" }
  end

  def points_summary
    @skills.map { |index, it| "#{index}: #{it.point_cost}" }
  end

  def lookup(skill_index)
    @skills[skill_index]
  end
end

class Critter
  @hand_size = 10
  def self.hand_size
    @hand_size
  end
  def initialize(name, deck, weights = {})
    @name = name
    @deck = deck
    @weights = weights
    @sanity = 0
    @hand = []
    @drawpile = []
    refill_drawpile
    refill_hand
  end
  attr_accessor :sanity, :name

  # deck management
  def expand_weights
    @weights.map do |index, weight|
      [index] * weight
    end.flatten
  end
  def shuffle_drawpile
    @drawpile.shuffle!
  end
  def refill_drawpile
    @drawpile.concat expand_weights
    @drawpile.shuffle!
  end
  def draw
    refill_drawpile unless @drawpile.any?
    @hand.push @drawpile.pop
  end
  def refill_hand
    while @hand.size < self.class.hand_size
      draw
    end
  end

  # stats management
  def gain_sanity(amount)
    @sanity += amount
  end
  def lose_sanity(amount)
    @sanity -= amount
  end

  # functions to "pick"

  def pick_random
    draw unless @hand.any?
    @deck.lookup @hand.first
  end

  # functions to "show"
  def show_hand
    @hand.join(" ")
  end
  def show_random
    pick_random.summary
  end
end

def setup
  orchid_deck = Deck.new(
    ORCHID_SKILLS.transform_values { |value|
      Skill.new(*value)
    }
  )
  miko_deck = Deck.new(
    MIKO_SKILLS.transform_values { |value|
      Skill.new(*value)
    }
  )
  {
    orchid: Critter.new("Orchid", orchid_deck, ORCHID_WEIGHTS),
    miko: Critter.new("Miko", miko_deck, MIKO_WEIGHTS)
  }
end

def clash_compare(attacker, defender)
  return :win if attacker > defender
  return :lose if attacker < defender
  return :draw
end

def clash(attacker, askill, defender, dskill)
  puts "#{attacker.name} (#{attacker.sanity} SP) vs #{defender.name} (#{defender.sanity} SP})"
  puts "#{askill.summary} vs #{dskill.summary}"
  # set up coins
  acoins = askill.coins
  dcoins = dskill.coins
  # perform clash
  clash_count = 0
  while acoins.positive? && dcoins.positive?
    a_rolls = Skill.roll_generic(acoins, attacker.sanity)
    d_rolls = Skill.roll_generic(dcoins, defender.sanity)
    puts "#{Skill.show_generic_roll(a_rolls)} vs #{Skill.show_generic_roll(d_rolls)}"
    aval = askill.roll(a_rolls, attacker.sanity)
    dval = dskill.roll(d_rolls, defender.sanity)
    result = clash_compare(aval, dval)
    puts "#{aval} vs #{dval} (#{result})"
    if result == :win
      dcoins -= 1
    elsif result == :lose
      acoins -= 1
    end
    clash_count += 1
  end
  # manage sanity
  result = clash_compare(acoins, dcoins)
  if result == :win
    attacker.gain_sanity(clash_count)
    defender.lose_sanity(clash_count)
  elsif result == :lose
    attacker.lose_sanity(clash_count)
    defender.gain_sanity(clash_count)
  end
  puts "Result: #{result} (SP: #{attacker.sanity} vs #{defender.sanity})"
  result
end

def main
  # set up fighters
  fighters = setup
  orchid = fighters[:orchid]
  miko = fighters[:miko]

  1.upto(10) do |_|
    orchid_skill = orchid.pick_random
    puts "Orchid skill: #{orchid_skill.summary}"
    
    miko_skill = miko.pick_random
    puts "Miko skill: #{miko_skill.summary}"
    clash(orchid, orchid_skill, miko, miko_skill)
  end
end

class PromptResult
  def initialize(key)
    puts ({
      start: "Enter command"
    }[key])
    @result = prompt_parse gets.chomp
  end
  attr_reader :result
  def prompt_parse(user_input)
    tokens = user_input.split
    return :empty unless tokens.any?
    command = tokens.shift
    return :help if command == "help"
    if ["look", "show"].include? command
      return :look unless tokens.any?
      return [:look, tokens]
    end
    if "select" == command
      # select a skill or character
      return [:select, tokens]
    end
    if "play" == command
      return [:play, tokens]
    end
  end
end
class InteractiveMode
  def initialize
    # set up fighters
    fighters = setup
    orchid = fighters[:orchid]
    miko = fighters[:miko]
    show_hand(miko)
    show_hand(orchid)
  
    @next_prompt = :start
    prompt_input
    while @action != :exit
      main_loop_once
    end
  end
  def main_loop_once
    prompt_result = interactive_prompt(:start)
    while prompt_result != :exit
      action_list.
  end
end

def main
  game_instance = InteractiveMode.new
  game_instance.main_loop_full
end
