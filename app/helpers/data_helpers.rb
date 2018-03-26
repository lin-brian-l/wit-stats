def reverse_tournament_date(array)
  array.sort_by { |element| element.tournament.date }.reverse
end

def return_tables_hash()
  {
    "Tournament": Tournament,
    "Player": Player,
    "Event": Event,
    "EventEntrant": EventEntrant,
    "Phase": Phase,
    "Group": Group,
    "Match": Match
  }
end

def percent(num1, num2)
  (num1.to_f / num2.to_f * 100).round(1)
end

def get_suffix(placing)
  return "th" if (placing.between?(4,20))
  case placing.digits.first
    when 1
      "st"
    when 2
      "nd"
    when 3
      "rd"
    else
      "th"
  end
end

def downcase_and_squash(string)
  string.gsub(/\s+/, "").downcase
end

# 11: 1493850