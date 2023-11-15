require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] = [] unless session[:lists]
  @lists = session[:lists]
end

get "/" do
  redirect "/lists"
end

#view all of the lists!
get "/lists" do
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
get "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  redirect "/lists" unless (0..@lists.size).cover?(@list_id)

  @list = @lists[@list_id]
  @todos = @list[:todos]

  erb :list
end

#Display edit of current list
get "/lists/:list_id/edit" do
  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]

  erb :edit_list
end

#Update the list name and redirect
post "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]

  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@list_id}"
  end
end

# delete curret list
post "/lists/:list_id/delete" do
  @list_id = params[:list_id].to_i
  @lists.delete_at(@list_id) if params[:delete]

  session[:success] = "The list has been deleted!"
  redirect "/lists"
end

#add a new todo to the @list_id list
post "/lists/:list_id/todos" do
  def error_for_todo_name(todo_name)
    if !(1..100).cover? todo_name.size
      "Todo must be between 1 and 100 characters!"
    end
  end

  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]
  @todos = @list[:todos]

  @todo_name = params[:todo_name].strip
  error = error_for_todo_name(@todo_name)

  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << {name: @todo_name, done: false}
    session[:success] = "The todo item was added!"
    redirect "/lists/#{@list_id}"
  end
end

#delete todo
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @todo_id = params[:todo_id].to_i

  @list = @lists[@list_id]
  @todos = @list[:todos]

  @todos.delete_at(@todo_id)
  session[:success] = "The todo has been deleted."

  redirect "/lists/#{@list_id}"
end