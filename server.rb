require "sinatra"
require "pg"

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/' do
  redirect '/actors'
end

get '/actors' do
  sql = <<-eos
    SELECT actors.name, actors.id FROM actors ORDER BY actors.name;
  eos
  @actors = db_connection { |conn| conn.exec(sql) }
  erb :'actors/index'
end

get '/actors/:id' do
  sql = <<-eos
    SELECT actors.name, movies.id, movies.title, cast_members.character
    FROM cast_members
    JOIN movies ON (cast_members.movie_id = movies.id)
    JOIN actors ON (cast_members.actor_id = actors.id)
    WHERE actors.id = #{params[:id]};
  eos
  @actor_details = db_connection { |conn| conn.exec(sql) }
  erb :'actors/show'
end

get '/movies' do
  sql = <<-eos
    SELECT movies.title, movies.id, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    JOIN genres ON (movies.genre_id = genres.id)
    LEFT JOIN studios ON (movies.studio_id = studios.id)
    ORDER BY movies.title;
  eos
  @movies = db_connection { |conn| conn.exec(sql) }
  erb :'movies/index'
end

get '/movies/:id' do
  sql = <<-eos
    SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio, actors.name AS actor, actors.id, cast_members.character AS character
    FROM movies
    JOIN genres ON (movies.genre_id = genres.id)
    LEFT JOIN studios ON (movies.studio_id = studios.id)
    JOIN cast_members ON (movies.id = cast_members.movie_id)
    JOIN actors ON (actors.id = cast_members.actor_id)
    WHERE movies.id = #{params[:id]};
  eos
  @movie = db_connection { |conn| conn.exec(sql) }
  erb :'movies/show'
end
