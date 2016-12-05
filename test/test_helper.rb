require 'sqlite3'
require 'minitest/autorun'
require 'minitest/pretty_diff'
require 'minitest/reporters'
require 'pry'

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(:color => true)]
