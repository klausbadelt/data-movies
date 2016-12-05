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
			  year_from integer,
			  year_to integer
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
		#$100,000 Pyramid, The (2001) (VG)			2001
		title_re = /^([^\t]*)\t+([0-9,?]{4})-?([0-9,?]{0,4})$/i
		i = 0
		stmt = @db.prepare("INSERT INTO movies (title_index, year_from, year_to) VALUES (?, ?, ?);")
		@db.execute "DELETE FROM movies;"
		  list.each_line do |l|
			if match = title_re.match(l)
				print "#{i}\r" if (i = i + 1) % 5000 == 0
				stmt.execute!(match[1], match[2].to_i, match[3].to_i)
			end
		end
		puts
	end

	def import_times
		# "#ATown" (2014) {Kayaking Adventure (#1.5)}		9	(approx.)
		# Confinement (2008)					USA:8	(approx.)
	  # "#LawstinWoods" (2013) {The Loop & Rocks (#1.9)} {{SUSPENDED}}	USA:20
	  # Confissıes de Adolescente (2013)			96
	  # Conflict (1988) (V)					99
	  # Conflict (1988) (V)					USA:89	(DVD version)
		time_re = /^([^\t]*\s+) \s+ (?:[a-z]+:)?([0-9]+)/i
		i = 0

		stmt = @db.prepare("UPDATE Movies set length=? WHERE title=? AND year=?;")
	  @db.transaction do
			File.new("data/running-times.list","r:ISO-8859-1:UTF-8").each_line do |l|
				print "." if (i = i + 1) % 5000 == 0; STDOUT.flush

				if match = time_re.match(l)
					stmt.execute!(match[3].to_i, match[1], match[2].to_i)
				end
			end
	  end

		puts
	end


	def import_budgets
		dashes = "-------------------------------------------------------------------------------"
		title_re = /MV:\s+(#{$title}?) \s \(([0-9]+)\)/ix
		budget_re = /BT:\s+USD\s+([0-9,.]+)/ix

		stmt = @db.prepare("UPDATE Movies set budget=? WHERE title=? AND year=?;")
		@db.transaction do
			File.new("data/business.list","r:ISO-8859-1:UTF-8").each(dashes) do |l|
				if match = title_re.match(l.to_s) and bt = budget_re.match(l.to_s)
					stmt.execute!(bt[1].gsub!(",","").to_i, match[1], match[2].to_i)
				end
			end
		end
	end

	def import_mpaa_ratings
		dashes = "-------------------------------------------------------------------------------"
		title_re = /MV:\s+(#{$title}?) \s \(([0-9]+)\)/ix
		rating_re = /RE: Rated (.*?) /i

		stmt = @db.prepare("UPDATE Movies set mpaa_rating=? WHERE title=? AND year=?;")
		@db.transaction do
			File.new("data/mpaa-ratings-reasons.list","r:ISO-8859-1:UTF-8").each(dashes) do |l|
				if match = title_re.match(l.to_s) and rt = rating_re.match(l.to_s)
					stmt.execute!(rt[1], match[1], match[2].to_i)
				end
			end
		end
	end


	def import_genres
		#D2: The Mighty Ducks (1994)				Family
		genre_re = /^(#{$title}?) \s+ \(([0-9]+)\) (?:\s*[({].*[})])*  \s+(.*?)$/ix
		i = 0

		stmt = @db.prepare("INSERT INTO Genres (genre, movie_id) VALUES (?, (SELECT id FROM Movies WHERE title=? AND year=?));")
		@db.transaction do
			@db.execute "DELETE FROM Genres;"

			File.new("data/genres.list","r:ISO-8859-1:UTF-8").each_line do |l|
				print "." if (i = i + 1) % 1000 == 0; STDOUT.flush
				if match = genre_re.match(l)
					stmt.execute!(match[3], match[1], match[2].to_i)
				end
			end
			puts
		end
	end


	def import_ratings
		#.0.1112000      14   5.9  365 Nights in Hollywood (1934)
		ratings_re = /([0-9.\*]+) \s+ ([0-9]+) \s+ ([0-9.]+) \s+ (#{$title}?) \s+ \(([0-9]+)\)/ix

		stmt = @db.prepare("UPDATE Movies set imdb_votes=?, imdb_rating=?, imdb_rating_votes=? WHERE title=? AND year=?;")
		@db.transaction

		File.new("data/ratings.list","r:ISO-8859-1:UTF-8").each_line do |l|
			if match = ratings_re.match(l)
				rating, votes, outof10, title, year = match[1], match[2], match[3], match[4], match[5]
				stmt.execute!(votes, outof10, rating, title, year)
			end
		end
		@db.commit

	end
end

# run if executed from command line
if __FILE__==$0
	import = MovieImport.new
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
