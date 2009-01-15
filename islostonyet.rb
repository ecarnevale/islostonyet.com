require 'rubygems'
gem 'sinatra', '~> 0.3'
require 'sinatra'
require 'json'

configure do
  require File.join(File.dirname(__FILE__), 'config', 'lost.rb')
end

before do
  Time.zone = IsLOSTOnYet.time_zone
  @is_lost_on = IsLOSTOnYet.answer
end

get '/' do
  @posts = IsLOSTOnYet::Post.all
  @users = users_for @posts

  haml :index
end

get '/tags' do
  # placeholders until implemented
  #
  # tags
  # @tags = %w(jack sayid kate s5e4)
  #
  # weighted tags
  @tags  = [['jack', 54], ['kate', 45], ['s5e4', 30]]
  @posts = IsLOSTOnYet::Post.find_replies
  @users = users_for @posts
  
  @tags.map { |(tag, weight)| tag } * ", " # temp output until theres a template
end

get '/episodeguide' do
  @episodes = IsLOSTOnYet.episodes
  @posts    = IsLOSTOnYet::Post.find_replies
  @users = users_for @posts

  @episodes.map { |e| e.to_s } * ", " # temp output until theres a template
end

get '/*' do
  @tags  = params[:splat].first.split("/")
  @posts = IsLOSTOnYet::Post.find_replies
  @users = users_for @posts

  "<ul>\n#{%w(jack kate sayid).map { |tag| link_to_tag(tag) + "\n" }}\n</ul>"
end

get '/json' do
  json = IsLOSTOnYet.answer.to_json
  if params[:callback]
    "#{params[:callback]}(#{json})"
  else
    json
  end
end

get '/main.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :main
end

helpers do
  def link_to_tag(name)
    in_collection = @tags.include?(name)
    collection    = in_collection ? [] : @tags
    %(<li#{%( class="selected") if in_collection}><a href="#{url_for_tag(name, collection)}">#{name}</a></li>)
  end

  def url_for_tag(name, existing = @tags)
    "/" + 
      if existing.empty?
        name
      else
        (existing.dup << name) * "/"
      end
  end

  def users_for(posts)
    user_ids = posts.map { |p| p.user_id.to_i }
    user_ids.uniq!
    IsLOSTOnYet::User.where(:id => user_ids).inject({}) do |memo, user|
      memo.update user.id => user
    end
  end

  def page_title(answer = nil)
    if answer
      "Is LOST#{" (Season #{answer.next_episode.season})" if answer.next_episode} on yet?"
    elsif params[:episode]
      "Is LOST (Season #{params[:season]}, Episode #{params[:episode]}) on yet?"
    elsif params[:season]
      "Is LOST (Season #{params[:season]}) on yet?"
    else
      "Is LOST on yet?"
    end
  end
end