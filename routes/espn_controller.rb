class Calx < Grape::API

  format :json
  before do
    header "Access-Control-Allow-Origin", "*"
    header "Access-Control-Allow-Methods", "POST, GET, PUT, DELETE, OPTIONS"
    header "Access-Control-Allow-Headers", "X-Requested-With,If-Modified-Since,Cache-Control,Content-Type"
  end

  helpers do
    def current_user
      @current_user ||= User.my_token(env['HTTP_X_APP_TOKEN']) 
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_user
    end
  end

  module Entities
    class User < Grape::Entity
      expose :id, :first_name, :last_name, :email
    end

    class AccessToken < Grape::Entity
      expose :token
    end
  end

  options 'user' do end

  desc "User sign up"
  params do
    requires :first_name, :type => String, :desc => "First Name"
    requires :last_name, :type => String, :desc => "Last Name"
    requires :email, :type => String, :desc => "Email"
    requires :password, :type => String, :desc => "Password"
    requires :password_confirmation, :type => String, :desc => "Password confirmation"
  end
  post :user do
    user = User.new(params.slice(:first_name, :last_name, :email, :password, :password_confirmation))
    unless user.save
      throw :error, :status => 400, :message => user.errors.map{ |error| error.to_s }
    end
    present user, with: Entities::User
  end

  options 'login' do end

  desc "User login"
  params do
    requires :client_id, :type => String, :desc => "Email address"
    requires :client_secret, :type => String, :desc => "Password"
  end
  post :login do
    unless user = User.authenticate(params[:client_id], params[:client_secret])
      throw :error, :status => 401, :message => "Unable to match email and password" 
    end
    present user.access_token, with: Entities::AccessToken
  end

  namespace :secure do
    before do
      authenticate!
    end

    desc "logout"
    get :logout do   
      current_user.access_token.clear_token
    end
  end
  
end
