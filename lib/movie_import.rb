require 'sqlite3'

class MovieImport
	TITLE_RE = "[a-z,&-;0-9$#+=\/!?. ]+"

	def initialize(db = SQLite3::Database.new( "movies.sqlite3" ))
		@db = db
		create_tables
	end

	def create_tables
 		@db.execute <<~SQL
			CREATE TABLE movies (
			  id INTEGER PRIMARY KEY,
			  title_index varchar(250),
				title varchar(250),
			  year_from integer,
			  year_to integer,
				season integer,
				episode integer
			  -- budget integer,
			  -- length integer,
			  -- imdb_rating float,
			  -- imdb_votes integer,
			  -- imdb_rating_votes varchar(10),
			  -- mpaa_rating varchar(5)
			);
    SQL
  end

	def movies(list = File.new("data/movies.list","r:ISO-8859-1:UTF-8"))
		@db.execute "DELETE FROM movies;"
		stmt = @db.prepare <<~SQL
		  INSERT INTO movies (title_index, title, year_from, year_to, season, episode)
			VALUES (?, ?, ?, ?, ?, ?);
		SQL
	  list.each_line.with_index do |l,i|
			print "#{i}\r" if i % 5000 == 0

			if l[0] == '"'
				# TV show
				title_index, title, year_from, year_to, season, episode = movies_attributes_tv(l)
			  stmt.execute!(title_index, title, year_from, year_to, season, episode) if title_index
			else
				# Single work
				# @todo
			end
		end
		puts
	end

	private

	def movies_attributes_tv(l)
		if match = /^([^\t]*)\t+([0-9,?]{4})-?([0-9,?]{0,4})$/i.match(l)
			if episode_match = /^*+{(.*)\s+\(#(\d+)\.(\d+)\)}$/.match(match[1])
				title = episode_match[1]
				season = episode_match[2]
				episode = episode_match[3]
			else
				title = nil # @todo
				season = -1
				episode = -1
			end
			[match[1], title, match[2].to_i, match[3].to_i, season, episode]
		else
			[nil, nil, nil, nil, nil, nil]
		end
	end

end

# run if executed from command line
if __FILE__==$0
	# import = MovieImport.new
	# puts "Importing movies"
	# import.movies
	# puts "Importing times"
	# import_times
	# puts "Importing budgets"
	# import_budgets
	# puts "Importing ratings"
	# import_mpaa_ratings
	# puts "Importing votes"
	# import_ratings
	# puts "Importing genres"
	# import_genres
end
