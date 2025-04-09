require 'sinatra/reloader'

module Model
    ##
    # Fetches and renders the listing index page.
    #
    # @param [Integer] user_id the ID of the logged-in user.
    # @return [String] the rendered Slim template for the listing index page.
    def listing_index(user_id)
        db = SQLite3::Database.new('db/todo2021.db')
        db.results_as_hash = true
        listings = db.execute("SELECT listings.*, users.username FROM listings JOIN users ON listings.user_id = users.id")
        saved_listings = []
        if session[:id]
            saved_listings = db.execute("SELECT listing_id FROM saved_listings WHERE user_id = ?", user_id)
        end
        slim(:"/listing/index", locals: { listings: listings, saved_listings: saved_listings.map { |sl| sl['listing_id'] } })
    end

    ##
    # Saves a listing for the logged-in user.
    #
    # @param [Integer] listing_id the ID of the listing to save.
    # @param [Integer] user_id the ID of the logged-in user.
    # @return [void]
    def save_listing(listing_id, user_id)
        db = SQLite3::Database.new('db/todo2021.db')
        db.execute("INSERT INTO saved_listings (user_id, listing_id) VALUES (?, ?)", [user_id, listing_id])
    end

    ##
    # Unsaves a listing for the logged-in user and redirects to the appropriate page.
    #
    # @param [Integer] listing_id the ID of the listing to unsave.
    # @param [Integer] user_id the ID of the logged-in user.
    # @param [String] current_page the page to redirect to after unsaving.
    # @return [void]
    def unsave_listing(listing_id, user_id, current_page)
        db = SQLite3::Database.new('db/todo2021.db')
        db.execute("DELETE FROM saved_listings WHERE user_id = ? AND listing_id = ?", [user_id, listing_id])
        if current_page == 'profile'
            redirect('/profile')
        else
            redirect('/listing/index')
        end
    end

    ##
    # Creates a new listing for the logged-in user.
    #
    # @param [String] title the title of the new listing.
    # @param [Integer] id the ID of the logged-in user.
    # @return [void]
    def new_listing(title, id)
        db = SQLite3::Database.new('db/todo2021.db')
        db.execute("INSERT INTO listings (title, user_id) VALUES (?, ?)", [title, id])
    end

    ##
    # Fetches and renders the profile page for the logged-in user.
    #
    # @param [Integer] id the ID of the logged-in user.
    # @param [String] name the username of the logged-in user.
    # @return [String] the rendered Slim template for the profile page.
    def user_profile(id, name)
        db = SQLite3::Database.new('db/todo2021.db')
        db.results_as_hash = true
        saved_listings = db.execute("SELECT listings.id AS listing_id, listings.title FROM saved_listings JOIN listings ON saved_listings.listing_id = listings.id WHERE saved_listings.user_id = ?", id)
        listings = db.execute("SELECT * FROM listings WHERE user_id = ?", id)
        slim(:profile, locals: { listings: listings, saved_listings: saved_listings })
    end

    ##
    # Deletes a listing created by the logged-in user.
    #
    # @param [Integer] listing_id the ID of the listing to delete.
    # @param [Integer] user_id the ID of the logged-in user.
    # @return [void]
    def delete_listing(listing_id, user_id)
        db = SQLite3::Database.new('db/todo2021.db')
        owner = db.execute("SELECT user_id FROM listings WHERE id=?", listing_id).first.first
        if owner == user_id || session[:admin] == 2
            db.execute("DELETE FROM listings WHERE id = ?", listing_id)
        else
            redirect to('/error')
        end
    end

    ##
    # Fetches and renders the edit listing page.
    #
    # @param [Integer] id the ID of the listing to edit.
    # @return [String] the rendered Slim template for the edit listing page.
    def edit_listing(id)
        db = SQLite3::Database.new('db/todo2021.db')
        db.results_as_hash = true
        result = db.execute("SELECT * FROM listings WHERE id = ?", id).first
        slim(:"/listing/edit", locals: { result: result })
    end

    ##
    # Updates a listing created by the logged-in user.
    #
    # @param [Integer] listing_id the ID of the listing to update.
    # @param [String] title the new title for the listing.
    # @return [void]
    def update_listing(listing_id, title)
        db = SQLite3::Database.new('db/todo2021.db')
        db.execute("UPDATE listings SET title=? WHERE id = ?", [title, listing_id])
    end

    ##
    # Logs in a user by verifying their credentials.
    #
    # @param [String] username the username of the user.
    # @param [String] password the password of the user.
    # @return [void]
    def login(username, password)
        db = SQLite3::Database.new('db/todo2021.db')
        db.results_as_hash = true
        result = db.execute("SELECT * FROM users WHERE username = ?", username).first
        if result.nil?
            flash[:login_error] = "Användare finns ej."
            redirect('/profile')
        else
            pwdigest = result["pwdigest"]
            id = result["id"]
            admin = result["admin"]
            if BCrypt::Password.new(pwdigest) == password
                session[:id] = id
                session[:admin] = admin
                session[:username] = username
                redirect('/profile')
            else
                flash[:password_error] = "Fel lösenord."
                redirect('/profile')
            end
        end
    end

    ##
    # Registers a new user.
    #
    # @param [String] username the username of the new user.
    # @param [String] password the password of the new user.
    # @param [String] password_confirm the password confirmation.
    # @return [void]
    def register_user(username, password, password_confirm)
        if password == password_confirm
            password_digest = BCrypt::Password.create(password)
            db = SQLite3::Database.new('db/todo2021.db')
            db.execute("INSERT INTO users (username, pwdigest, admin) VALUES (?, ?, ?)", [username, password_digest, 1])
            redirect('/profile')
        else
            "lösenorden matchade inte"
        end
    end
end