require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

get('/') do
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    users = db.execute("SELECT * FROM users")
    listings = db.execute("SELECT * FROM listings")
    slim(:main, locals:{users:users, listings:listings})
end

post('/save_listing') do
  listing_id = params[:listing_id]
  user_id = session[:id]

  if user_id.nil?
      redirect('/login')
  else
      db = SQLite3::Database.new('db/todo2021.db')
      db.execute("INSERT INTO saved_listings (user_id, listing_id) VALUES (?, ?)", [user_id, listing_id])
      redirect('/')
  end
end

get('/create') do
    slim(:"/create")
end

post('/createTodo') do
    title = params[:title]
    puts session[:id]
    id = session[:id].to_i
    db = SQLite3::Database.new('db/todo2021.db')
    db.execute("INSERT INTO listings (title, user_id) VALUES (?, ?)", [title, id])
    redirect('create')
end

get('/profile') do
    id = session[:id].to_i
    name = session[:username]
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    saved_listings = db.execute("SELECT listing_id FROM saved_listings WHERE user_id = ?", id)
    listings = db.execute("SELECT * FROM listings WHERE user_id = ?", id)
    slim(:profile, locals:{listings:listings, saved_listings:saved_listings})
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/todo2021.db')
      db.execute("INSERT INTO users (username, pwdigest) VALUES (?, ?)", [username, password_digest])
      redirect('/')
    else
      "lösenorden matchade inte"
    end
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      puts session[:id]
      session[:username] = username
      redirect('/profile')
    else
      "FEL LÖSENORD"
    end
end