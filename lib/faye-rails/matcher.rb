module FayeRails
  module Matcher
    def self.match?(pattern, value)
      return false if value.include? "\0"
      File.fnmatch? pattern, value
    end
  end
end
