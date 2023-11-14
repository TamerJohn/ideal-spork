require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] = [] unless session[:lists]
end

get "/" do
  redirect "/lists"
end

#view all of the lists!
get "/lists" do
  @lists = session[:lists]

  erb :lists
end

#render new list form
get "/lists/new" do
  erb :new_list
end

#create a new list
post "/lists" do
  def error_for_list_name(list_name)
    if !(1..100).cover? list_name.size
      "The list name must be between 1 and 100 characters!"
    elsif session[:lists].any? { |list| list[:name] == list_name }
      "The list name must be unique!"
    end
  end

  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

#view a single list
get "/lists/:id" do
  redirect "/lists" unless @lists[params[:id]]
end