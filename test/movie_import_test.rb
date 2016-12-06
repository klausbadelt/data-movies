require 'test_helper'
require 'movie_db_import'

class MovieDbImportTest < Minitest::Test
  def setup
    @db = SQLite3::Database.new ':memory:'
    @import = MovieDbImport.new @db

    # Redirect stderr and stdout
    @stdout, @stderr                   = StringIO.new, StringIO.new
    @original_stdout, @original_stderr = $stdout, $stderr
    $stdout, $stderr                   = @stdout, @stderr
  end

  def teardown
    $stdout, $stderr                   = @original_stdout, @original_stderr
    @original_stdout, @original_stderr = nil, nil
  end

  def test_movies_table_exists
    assert_equal [['movies']],
      @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='movies';")
  end

  def test_movies_columns
    columns = @db.table_info('movies').map{ |column| column['name'] }

    assert_includes columns, 'title_index'
    assert_includes columns, 'year_from'
    assert_includes columns, 'year_to'
    assert_includes columns, 'title'
    assert_includes columns, 'season'
    assert_includes columns, 'episode'
  end

  def test_movies_tv
    @import.movies(StringIO.new '"#1 Single" (2006) {Cats and Dogs (#1.4)}		2006')

    assert_equal [['"#1 Single" (2006) {Cats and Dogs (#1.4)}', 2006, 0]],
      @db.execute("SELECT title_index, year_from, year_to FROM movies")
  end

  def test_movies_tv_with_year_to
    @import.movies(StringIO.new '"#2WheelzNHeelz" (2017)					2017-????')

    assert_equal [['"#2WheelzNHeelz" (2017)', 2017, 0]],
      @db.execute("SELECT title_index, year_from, year_to FROM movies")
  end

  def test_movies_tv_with_undef_year
    @import.movies(StringIO.new '"#15SecondScare" (2015) {Shriek (#1.13)}		????')

    assert_equal [['"#15SecondScare" (2015) {Shriek (#1.13)}', 0, 0]],
      @db.execute("SELECT title_index, year_from, year_to FROM movies")
  end

  def test_movies_tv_episode_title
    @import.movies(StringIO.new '"10 Grand in Your Hand" (2009) {A Warm & Welcoming Kitchen (#1.10)}	2009')
    assert_equal [['A Warm & Welcoming Kitchen']],
      @db.execute("SELECT title FROM movies")
  end

  def test_movies_tv_season_and_episode_number
    @import.movies(StringIO.new '"10 Grand in Your Hand" (2009) {A Warm & Welcoming Kitchen (#1.10)}	2009')

    assert_equal [[1,10]],
      @db.execute("SELECT season, episode FROM movies")
  end

  def test_movies_tv_title
    @import.movies(StringIO.new '"Ed Mort" (2011)					2011-????')
    assert_equal [['Ed Mort']],
      @db.execute("SELECT title FROM movies")
  end

  def test_movies_title
    @import.movies(StringIO.new 'Bouge pas! (2016)					2016')
    assert_equal [['Bouge pas!']],
      @db.execute("SELECT title FROM movies")
  end

  def test_movies_title_wo_date
    @import.movies(StringIO.new 'Dennis Wants More Than Tennis (????)			????')
    assert_equal [['Dennis Wants More Than Tennis',0]],
      @db.execute("SELECT title, year_from FROM movies")
  end

  def test_movies_title_w_curly_brackets
    @import.movies(StringIO.new 'Dependence (2014) {{SUSPENDED}}				2014')
    assert_equal [['Dependence',2014]],
      @db.execute("SELECT title, year_from FROM movies")
  end

end
