require 'test_helper'
require 'movie_import'

class MovieImportTest < Minitest::Test
  def setup
    @db = SQLite3::Database.new ':memory:'
    @import = MovieImport.new @db

    # Redirect stderr and stdout
    @stdout, @stderr                   = StringIO.new, StringIO.new
    @original_stdout, @original_stderr = $stdout, $stderr
    $stdout, $stderr                   = @stdout, @stderr
  end

  def teardown
    $stdout, $stderr                   = @original_stdout, @original_stderr
    @original_stdout, @original_stderr = nil, nil
  end

  def test_movies_columns
    columns = @db.table_info('movies').map{ |column| column['name'] }

    assert_includes columns, 'title_index'
    assert_includes columns, 'year_from'
    assert_includes columns, 'year_to'
  end

  def test_import_tv
    @import.movies(StringIO.new '"#1 Single" (2006) {Cats and Dogs (#1.4)}		2006')

    assert_equal [['"#1 Single" (2006) {Cats and Dogs (#1.4)}', 2006, 0]],
      @db.execute("select title_index, year_from, year_to from movies")
  end

  def test_import_tv_with_year_to
    @import.movies(StringIO.new '"#2WheelzNHeelz" (2017)					2017-????')

    assert_equal [['"#2WheelzNHeelz" (2017)', 2017, 0]],
      @db.execute("select title_index, year_from, year_to from movies")
  end

  def test_import_tv_with_undef_year
    @import.movies(StringIO.new '"#15SecondScare" (2015) {Shriek (#1.13)}		????')

    assert_equal [['"#15SecondScare" (2015) {Shriek (#1.13)}', 0, 0]],
      @db.execute("select title_index, year_from, year_to from movies")
  end
end
