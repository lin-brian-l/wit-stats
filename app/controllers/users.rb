get '/users/settings' do
  authorize!
  @success = true if params[:success] 
  @error = "Passwords did not match." if params[:error] == "password"
  @error = "Old password is incorrect." if params[:error] == "old-password"
  @user = User.find_by(id: session[:user_id])
  erb :'users/settings'
end

put '/users' do
  authorize!
  @user = User.find_by(id: session[:user_id])
  if (params[:password1] != params[:password2])
    redirect "users/settings?error=password"
  end
  if @user.authenticate(params[:old_password])
    @user.change_password(params[:password1])
    redirect "users/settings?success=true"
  else 
    redirect "users/settings?error=old-password"
  end
end

get '/users/admin' do 
  authorize!
  erb :'users/admin'
end
