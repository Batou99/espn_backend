require 'spec_helper'

describe "signup" do
  let(:user) { FactoryGirl.build(:user) }
  subject { post '/user', user.to_json(:methods => [:password, :password_confirmation]) }

  it "should sign up user" do
    subject
    last_response.status.should eq 201
  end

  it "should contain response first_name" do
    subject
    last_response.body.should have_json_path('first_name')
  end

  it "should contain response last_name" do
    subject
    last_response.body.should have_json_path('last_name')
  end

  it "should contain response email" do
    subject
    last_response.body.should have_json_path('email')
  end
  
  it "should contain response id" do
    subject
    last_response.body.should have_json_path('id')
  end

  context "password mismatch" do
    let(:user) { FactoryGirl.build(:user, :password_confirmation => 'aeiou') }

    it "should fail signup" do
      subject
      last_response.status.should eq 400
    end
  end
end

describe "login" do
  let(:user) { FactoryGirl.create(:user) }
  let(:client_id) { user.email  }
  let(:client_secret) { user.password  }
  subject { post '/login', {:client_id => client_id, :client_secret => client_secret }.to_json }

  it "should login user" do
    subject
    last_response.status.should eq 201
  end

  it "should contain token" do
    subject
    last_response.body.should have_json_path('token')
  end

  it "should register token" do
    subject
    user.reload
    user.access_token.token.should_not be nil
  end

  context "login details incorrect" do
    let(:client_id) { 'hello@myworld.com' }

    it "should fail login" do
      subject
      last_response.status.should eq 401
    end
  end
end

describe "logout" do
  let(:user){ FactoryGirl.create(:user) }
  subject { get '/secure/logout', {}, 'HTTP_X_APP_TOKEN' => user.access_token.token }

  before do
    post '/login', {:client_id => user.email, :client_secret => user.password}.to_json
    user.reload
  end

  it "should log out user" do
    subject
    user.reload
    user.access_token.token.should be nil
  end
end
