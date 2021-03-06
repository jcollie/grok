require "grok-pure"
require "logger"
require "cabin"

# A grok pile is an easy way to have multiple patterns together so
# that you can try to match against each one.
# The API provided should be similar to the normal Grok
# interface, but you can compile multiple patterns and match will
# try each one until a match is found.
class Grok
  class Pile
    attr_accessor :logger

    def initialize
      @groks = []
      @patterns = {}
      @pattern_files = []
      @logger = Cabin::Channel.new
      @logger.subscribe(Logger.new(STDOUT))
    end # def initialize

    def logger=(logger)
      @logger = logger
      @groks.each { |g| g.logger = logger }
    end

    # see Grok#add_pattern
    def add_pattern(name, string)
      @patterns[name] = string
    end # def add_pattern

    # see Grok#add_patterns_from_file
    def add_patterns_from_file(path)
      if !File.exists?(path)
        raise "File does not exist: #{path}"
      end
      @pattern_files << path
    end # def add_patterns_from_file

    # see Grok#compile
    def compile(pattern)
      grok = Grok.new
      grok.logger = @logger unless @logger.nil?
      @patterns.each do |name, value|
        grok.add_pattern(name, value)
      end
      @pattern_files.each do |path|
        grok.add_patterns_from_file(path)
      end
      grok.compile(pattern)
      @logger.info("Pile compiled new grok", :pattern => pattern,
                   :expanded_pattern => grok.expanded_pattern)
      @groks << grok
    end # def compile

    # Slight difference from Grok#match in that it returns
    # the Grok instance that matched successfully in addition
    # to the GrokMatch result.
    # See also: Grok#match
    def match(string)
      @groks.each do |grok|
        match = grok.match(string)
        if match
          return [grok, match]
        end
      end
      return false
    end # def match
  end # class Pile
end # class Grok
