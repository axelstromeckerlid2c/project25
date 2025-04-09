require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'
require_relative './model.rb'

enable :sessions

include Model

##
# Renders the start page.
#
# @return [String] the rendered Slim template for the start page.
get('/') do
  slim(:start)
end

##
# Displays the listing index page.
#
# @return [String] the rendered Slim template for the listing index page.
get('/listing/index') do
  user_id = session[:id]
  listing_index(user_id)
end

##
# Renders the error page.
#
# @return [String] the rendered Slim template for the error page.
get('/error') do
  slim(:error)
end

##
# Saves a listing for the logged-in user.
#
# @param [Integer] listing_id the ID of the listing to save.
# @param [Integer] user_id the ID of the logged-in user.
# @return [void]
post('/save_listing') do
  listing_id = params[:listing_id]
  user_id = session[:id]

  if user_id.nil?
    flash[:user_guest] = "Du måste vara inloggad för denna tjänst."
    redirect('/listing/index')
  else
    save_listing(listing_id, user_id)
    redirect('/listing/index')
  end
end

##
# Unsaves a listing for the logged-in user.
#
# @param [Integer] listing_id the ID of the listing to unsave.
# @param [Integer] user_id the ID of the logged-in user.
# @param [String] current_page the page to redirect to after unsaving.
# @return [void]
post('/unsave_listing') do
  listing_id = params[:listing_id]
  user_id = session[:id]
  current_page = params[:current_page]
  unsave_listing(listing_id, user_id, current_page)
end

##
# Ensures the user is logged in before accessing the new listing page.
#
# @return [void]
before('/listing/new') do
  if session[:id].nil?
    redirect to('/error')
  end
end

##
# Renders the new listing page.
#
# @return [String] the rendered Slim template for the new listing page.
get('/listing/new') do
  slim(:"/listing/new")
end

##
# Creates a new listing for the logged-in user.
#
# @param [String] title the title of the new listing.
# @param [Integer] id the ID of the logged-in user.
# @return [void]
post('/listing/new') do
  title = params[:title]
  id = session[:id].to_i
  new_listing(title, id)
  redirect('/listing/new')
end

##
# Displays the profile page for the logged-in user.
#
# @return [String] the rendered Slim template for the profile page.
get('/profile') do
  id = session[:id].to_i
  name = session[:username]
  user_profile(id, name)
end

##
# Deletes a listing created by the logged-in user.
#
# @param [Integer] listing_id the ID of the listing to delete.
# @param [Integer] user_id the ID of the logged-in user.
# @return [void]
post('/listing/:id/delete') do
  listing_id = params[:listing_id]
  user_id = session[:id]
  delete_listing(listing_id, user_id)
  redirect('/profile')
end

##
# Renders the edit listing page.
#
# @param [Integer] listing_id the ID of the listing to edit.
# @return [String] the rendered Slim template for the edit listing page.
get('/listing/:id/edit') do
  listing_id = params[:id].to_i
  edit_listing(listing_id)
end

##
# Updates a listing created by the logged-in user.
#
# @param [Integer] listing_id the ID of the listing to update.
# @param [String] title the new title for the listing.
# @return [void]
post('/listing/:id/update') do
  listing_id = params[:id].to_i
  title = params[:title]
  update_listing(listing_id, title)
  redirect('/profile')
end

##
# Logs in a user.
#
# @param [String] username the username of the user.
# @param [String] password the password of the user.
# @return [void]
post('/login') do
  username = params[:username]
  password = params[:password]
  login(username, password)
end

##
# Registers a new user.
#
# @param [String] username the username of the new user.
# @param [String] password the password of the new user.
# @param [String] password_confirm the password confirmation.
# @return [void]
post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  register_user(username, password, password_confirm)
end

##
# Logs out the current user.
#
# @return [void]
post('/logout') do
  session.clear
  redirect('/profile')
end