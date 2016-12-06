require 'sqlite3'

class MovieDbImport
	TITLE_RE = "[a-z,&-;0-9$#+=\/!?. ]+"
	DATADIR = File.expand_path("../../data", __FILE__)

	def initialize(db = SQLite3::Database.new( "movies.sqlite3" ))
		@db = db
		create_tables
	end

	def create_tables
		@db.execute "PRAGMA synchronous = OFF;"
		@db.execute "PRAGMA journal_mode = MEMORY;"
		@db.execute "DROP TABLE IF EXISTS movies;"
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
		@db.execute "CREATE INDEX id on movies (id);"
		@db.execute "CREATE INDEX title_index on movies (title_index);"
  end

	def movies(list = File.new(File.join(DATADIR, "movies.list"),"r:ISO-8859-1:UTF-8"))
		@db.execute "DELETE FROM movies;"
		@db.execute "BEGIN TRANSACTION;"
		stmt = @db.prepare <<~SQL
		  INSERT INTO movies (title_index, title, year_from, year_to, season, episode)
			VALUES (?, ?, ?, ?, ?, ?);
		SQL
	  list.each_line.with_index do |l,i|
			print "#{i/1000}k\r" if i % 5000 == 0

			if l[0] == '"'
				# TV show
				title_index, title, year_from, year_to, season, episode = movies_attributes_tv(l)
			else
				# Single work
				title_index, title, year_from = movies_attributes(l)
				year_to, season, episode = nil, nil, nil
			end
			stmt.execute!(title_index, title, year_from, year_to, season, episode) if title_index
		end
		@db.execute "COMMIT TRANSACTION;"
		puts
	end

	private

	def movies_attributes_tv(l)
		if index_match = /^("[^\t]*)\t+([0-9,?]{4})-?([0-9,?]{0,4})$/i.match(l)
			title_index, year_from, year_to = index_match[1],index_match[2].to_i, index_match[3].to_i
			if episode_match = /^*+{(.*)\s+\(#(\d+)\.(\d+)\)}$/.match(index_match[1])
				# Episode title in {}
				title, season, episode = episode_match[1], episode_match[2], episode_match[3]
			else
				# Show "head", no episode
				if title_match = /^"(.*)"/.match(index_match[1])
  				title = title_match[1]
				else
					title = nil
				end
				season, episode = -1, -1
			end
		else
			title_index, title, year_from, year_to, season, episode = nil, nil, nil, nil, nil, nil
		end
		[title_index, title, year_from, year_to, season, episode]
	end

	def movies_attributes(l)
		if index_match = /^([^\t]*)\t+([0-9,?]{4})$/i.match(l)
			title_index, year_from = index_match[1],index_match[2].to_i
			if title_match = /^(.*)\s\([0-9,?]{4}\)/.match(index_match[1])
				title = title_match[1]
			else
				title = nil
			end
		else
			title_index, title, year_from = nil, nil, nil
		end
		[title_index, title, year_from]
	end

end
