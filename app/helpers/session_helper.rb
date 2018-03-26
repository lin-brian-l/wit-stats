def logged_in?
  !session[:user_id].nil?
end

def current_user
  @current_user ||= User.find_by(id: session[:user_id])
end

def is_admin?(current_user)
  current_user.admin
end

def authorize!()
  redirect '/tournaments' unless logged_in? && is_admin?(current_user)  
end