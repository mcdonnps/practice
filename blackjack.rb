require "rubygems"
require "pry"
# CONFIGURABLE PARAMETERS

# deck count is first command line argument or default of 2
deck_count = ARGV.size == 1 && ARGV[0].to_i || 2


# CONSTANTS

# The unique cards (10 and face cards are not distinguished).
CARDS = (2..10).to_a << :ace

# The possible results are 17--21 plus bust and natural.  The order is
# given in a what might be considered worst to best order.
POSSIBLE_RESULTS = [:bust] + (17..21).to_a + [:natural]


# CLASSES

class Shoe
  # A deck is a hash keyed by the card, and the value is how many of
  # that card there are.  There are four of all cards except the
  # 10-value cards, and there are sixteen of those.
  DECK = CARDS.inject(Hash.new) { |hash, card| hash[card] = 4; hash }
  DECK[10] = 16

  def initialize(deck_count = 2)
    @cards = DECK.inject(Hash.new) { |hash, card|
      hash[card.first] = deck_count * card.last; hash }

    @card_count = @cards.inject(0) { |sum, card_count|
      sum + card_count.last }
  end

  def count(card)
    @cards[card]
  end

  def any?(card)
    count(card) > 0
  end

  def odds_of(card)
    @cards[card].to_f / @card_count
  end

  def consume(card)
    current = @cards[card]
    raise "error, consuming non-existant card" if current <= 0
    @cards[card] = current - 1
    @card_count -= 1
  end

  def replace(card)
    @cards[card] += 1
    @card_count += 1
  end
end


# SET UP VARIABLES

# The shoe is a Hash that contains one or more decks and an embedded
# count of how many cards there are in the shoe (keyed by
# :cards_in_shoe)
shoe = Shoe.new(deck_count)


# The results for a given upcard is a hash keyed by the result and
# with values equal to the odds that that result is acheived.
results_for_upcard =
  POSSIBLE_RESULTS.inject(Hash.new) { |hash, r| hash[r] = 0; hash }

# The final results is a hash keyed by every possible upcard, and with
# a value equal to results_for_upcard.
results = CARDS.inject(Hash.new) { |hash, card|
  hash[card] = results_for_upcard.dup; hash }


# METHODS

# returns the value of a hand
def value(hand)
  ace_count = 0
  hand_value = 0

  hand.each do |card|
    if card == :ace
      ace_count += 1
      hand_value += 11
    else
      hand_value += card
    end
  end

  # flip aces from being worth 11 to being worth 1 until we get <= 21
  # or we run out of aces
  while hand_value > 21 && ace_count > 0
    hand_value -= 10
    ace_count -= 1
  end

  hand_value
end


# the dealer decides what to do -- stands on 17 or above, hits
# otherwise
def decide(hand)
  value(hand) >= 17 && :stand || :hit
end


# computes the result of a hand, returning a numeric value, :natural,
# or :bust
def result(hand)
  v = value(hand)
  case v
  when 21     : hand.size == 2 && :natural || 21
  when 17..20 : v
  when 0..16  : raise "error, illegal resulting hand value"
  else          :bust
  end
end


# plays the dealer's hand, tracking all possible permutations and
# putting the results into the results hash
def play_dealer(hand, shoe, odds, upcard_result)
  case decide(hand)
  when :stand
    upcard_result[result(hand)] += odds
  when :hit
    CARDS.each do |card|
      next unless shoe.any?(card)
      card_odds = shoe.odds_of(card)

      hand.push(card)
      shoe.consume(card)

      play_dealer(hand, shoe, odds * card_odds , upcard_result)

      shoe.replace(card)
      hand.pop
    end
  else
    raise "error, illegal hand action"
  end
end


# MAIN PROGRAM


# calculate results

CARDS.each do |upcard|
  shoe.consume(upcard)
  play_dealer([upcard], shoe, 1, results[upcard])
  shoe.replace(upcard)
end


# display results header

puts "Note: results are computed using a fresh %d-deck shoe.\n\n" %
  deck_count

printf "upcard  "
POSSIBLE_RESULTS.each do |result|
  printf "%9s", result.to_s
end
puts

printf "-" * 6 + "  "
POSSIBLE_RESULTS.length.times do
  print "  " + "-" * 7
end
puts


# display numeric results

CARDS.each do |upcard|
  printf "%6s |", upcard
  POSSIBLE_RESULTS.each do |result|
    printf "%8.2f%%", 100.0 * results[upcard][result]
  end
  puts
end

