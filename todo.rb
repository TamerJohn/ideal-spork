require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "securerandom"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

before do
  session[:lists] = [] unless session[:lists]
  @lists = session[:lists]
end

helpers do
  def h(content)
    Rack::Utils.escape_html(content)
  end

  def list_complete?(list)
    todos_count(list) > 0 && remaining_todos_count(list) == 0
  end

  def list_class(list)
    if list_complete?(list)
      "complete"
    end
  end

  def todos_count(list)
    list[:todos].size
  end

  def remaining_todos_count(list)
    list[:todos].select { |todo| !todo[:done] }.size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each {|list| yield(list, lists.index(list)) }
    complete_lists.each {|list| yield(list, lists.index(list)) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:done] }

    incomplete_todos.each {|todo| yield(todo, todos.index(todo)) }
    complete_todos.each {|todo| yield(todo, todos.index(todo)) }
  end
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
  def list_completion_rate(list)
    "#{remaining_todos_count(list)} / #{todos_count(list)}"
  end

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
  unless (0..@lists.size).cover?(@list_id)
    session[:error] = "List Not Found"
    redirect "/lists"
  end

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

#toggle done/undone at a todo
post "/lists/:list_id/todos/:todo_id/update" do
  @list_id = params[:list_id].to_i
  @todo_id = params[:todo_id].to_i

  @list = @lists[@list_id]
  @todos = @list[:todos]

  @todos[@todo_id][:done] = @params[:completed] == "true"
  session[:success] = "The todo has been updated!"

  redirect "/lists/#{@list_id}"
end

#complete all todos in a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]

  @list[:todos].each do |todo|
    todo[:done] = true
  end

  session[:success] = "All the todos have been completed!"
  redirect "/lists/#{@list_id}"
end
