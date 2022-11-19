require "sinatra"
require "sinatra/namespace"
require "sinatra/activerecord"
require "cgi"

# DB Setup
set :database_file, 'config/database.yml'

# Environment
set :bind, '127.0.0.1'
set :port, 9494

# Model
class Article < ActiveRecord::Base
  scope :location, -> (loc) {where(location: loc)}
  scope :date, -> (dat) {where(published_date: dat)}
  scope :category, -> (cat) {where(category: cat)}


  def aid
    self.published_date.to_s.gsub(/\-/,'') + self.category_idx.to_s.rjust(2,'0') + self.idx.to_s.rjust(3,'0')
  end

  def category_url
    '/api/v1/articles?category=' + CGI.escape(self.category)
  end

  def date_url
    '/api/v1/articles?date=' + CGI.escape(self.published_date.to_s)
  end

  def location_url
    '/api/v1/articles?location=' + CGI.escape(self.location)
  end

end 

namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  get '/articles' do
    if params.length <= 0 then
      articles = Article.all
    else
      articles = Article.all
      [:category, :date, :location].each do |filter|
        articles = articles.send(filter, params[filter]) if params[filter]
      end
   end
    articles.to_json(:methods => :aid, :only => [ :id, :title, :category, :location, :published_date, :md_data])
  end

  get '/article/:id' do
    halt(404, { message:'Not Found'}.to_json) if(params.length<=0)
    article = Article.find_by(id: params[:id])
    halt(404, { message:'Not Found'}.to_json) if(article.nil?)
    article.to_json(:methods => :aid, :only => [ :id, :title, :category, :location, :published_date, :md_data])
  end


  get '/categories' do
    categories = Article.select(:category).distinct
    categories.to_json(:only => :category, :methods => :category_url)
  end

  get '/locations' do
    locations = Article.select(:location).distinct
    locations.to_json(:only => :location, :methods => :location_url)
  end

  get '/dates' do
    dates = Article.select(:published_date).distinct
    dates.to_json(:only => :published_date, :methods => :date_url)
  end

end

# Catch All
get '/*' do
  content_type 'application/json'
  halt(404, { message:'Not Found'}.to_json)
end
