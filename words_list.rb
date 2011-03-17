t remote add origin git@github.com:christophebiocca/WordsList.git
  git push -u origin master
#!/usr/bin/ruby

class WordsList

  attr_reader :words

  def WordsList.all_words
    @all_words ||= (
      list = []
      File.open("/usr/share/dict/words") do |file|
        file.each_line{|l| list << l.chomp}
      end
      new(list)
    )
  end

  # words should be a filterable collection of strings
  def initialize(words)
    @words = words.dup
  end

  def filter(&filtr)
    WordsList.new(@words.select(&filtr))
  end

  def regex_filter(regex)
    filter{|w| regex.match(w)}
  end

  def letter_frequencies(&mapper)
    @freq ||= (
      mapper ||= Proc.new{|l| l.upcase}
      freq = {}
      @words.each do |word|
        word.split(//).collect{|l| mapper.call(l)}.uniq.each do |letter|
          freq[letter] = (freq[letter] || 0) + 1
        end
      end
      freq.collect{|k,v| [k,v.to_f/@words.size]}.sort_by{|i|-i[1]}
    )
  end

  def hangman_filter(wildcard, missed = [], charset=(("a".."z").to_a))
    used_in_wildcard = wildcard.split(//).uniq - ["_"]
    possible_for_underscore = charset - missed - used_in_wildcard
    underscore_regex = "(?:" + possible_for_underscore.collect{|c| Regexp.escape(c)}.join('|') + ")"
    full_regex = Regexp.compile("\\A" + wildcard.split(//).collect do |letter|
      (letter == "_") ? underscore_regex : Regexp.escape(letter)
    end.join + "\\Z", Regexp::IGNORECASE)
    return regex_filter(full_regex)
  end
end
