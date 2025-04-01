require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

get('/') do
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    listings = db.execute("SELECT * FROM listings")
    saved_listings = []
    if session[:id]
      saved_listings = db.execute("SELECT listing_id FROM saved_listings WHERE user_id = ?", session[:id])
    end
    slim(:main, locals:{listings: listings, saved_listings: saved_listings.map { |sl| sl['listing_id'] }})
end

get('/error') do
    slim(:error)
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

post('/unsave_listing') do
    listing_id = params[:listing_id]
    user_id = session[:id]
    current_page = params[:current_page]
    p session[:admin]
    if user_id.nil?
        redirect('/login')
    else
        db = SQLite3::Database.new('db/todo2021.db')
        db.execute("DELETE FROM saved_listings WHERE user_id = ? AND listing_id = ?", [user_id, listing_id])
        if current_page == 'profile'
          redirect('/profile')
        else
          redirect('/')
        end
    end
end

before ('/create') do
  #Se tex om användare är inloggad
  if session[:id] == nil
    redirect to ('/error')
  end
end

get('/create') do
    slim(:"/create")
end

post('/listing/new') do
    title = params[:title]
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
    saved_listings = db.execute("SELECT listings.id AS listing_id, listings.title FROM saved_listings JOIN listings ON saved_listings.listing_id = listings.id WHERE saved_listings.user_id = ?", id)
    listings = db.execute("SELECT * FROM listings WHERE user_id = ?", id)
    slim(:profile, locals:{listings:listings, saved_listings:saved_listings})
end

post('/listing/delete') do
    listing_id = params[:listing_id]
    user_id = session[:id]
    db = SQLite3::Database.new('db/todo2021.db')
    owner = db.execute("SELECT user_id FROM listings WHERE id=?", listing_id).first.first
    if owner == user_id or session[:admin] == 2
      db.execute("DELETE FROM listings WHERE id = ?", listing_id)
    else
      redirect to ('/error')
    end

    #Ta med koll om user_id stämmer innan du tar bort. Säkerhet före allt.

    redirect('/profile')
end

post('/listing/delete') do
  listing_id = params[:listing_id]
  user_id = session[:id]
  db = SQLite3::Database.new('db/todo2021.db')
  owner = db.execute("SELECT user_id FROM listings WHERE id=?", listing_id).first.first
  if owner == user_id or session[:admin] == 2
    db.execute("DELETE FROM listings WHERE id = ?", listing_id)
  else
    redirect to ('/error')
  end

  #Ta med koll om user_id stämmer innan du tar bort. Säkerhet före allt.

  redirect('/profile')
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/todo2021.db')
      db.execute("INSERT INTO users (username, pwdigest, admin) VALUES (?, ?, ?)", [username, password_digest, 1])
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
    admin = result["admin"]
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:admin] = admin
      session[:username] = username
      redirect('/profile')
    else
      "FEL LÖSENORD"
    end
end

post('/logout') do
    session.clear
    redirect('/profile')
end