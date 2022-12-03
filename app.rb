require "sinatra"
require "sinatra/namespace"
require "sinatra/activerecord"
require "sinatra/cors"
require "cgi"

# DB Setup
set :database_file, 'config/database.yml'

# Environment
set :bind, '127.0.0.1'
set :port, 9494

# CORS
set :allow_origin, "http://localhost:5173"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"

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
    headers 'Access-Control-Allow-Origin' => '*', 
            'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']
  end

  # get '/articles' do
  #   articles = Article.all.order(published_date: :desc)
  #   [:category, :date, :location].each do |filter|
  #     articles = articles.send(filter, params[filter]) if params[filter]
  #   end
  #   articles.to_json(:methods => :aid, :only => [ :id, :title, :category, :location, :published_date, :md_data, :category_en, :title_en, :md_data_en])
  # end

  get '/search' do
    if(params[:q] && params[:q].length >= 3) then
      sql = "SELECT * from articles where MATCH(category, location, title, md_data, category_en, title_en, md_data_en) AGAINST (:query IN NATURAL LANGUAGE MODE)"
      if(params[:location]) then
        sql += " AND location=:location"
      end
      if(params[:date]) then
        sql += " AND published_date=:date"
      end
      if(params[:category]) then
        sql += " AND category=:category"
      end
      sql += ";"
      puts sql
      articles = Article.find_by_sql([sql, query: params[:q], date: params[:date], category: params[:category], location: params[:location]])
      articles.to_json(:methods => :aid, :only => [ :id, :title, :category, :location, :published_date, :md_data, :category_en, :title_en, :md_data_en])
    else 
      halt(404, { message:'Not Found'}.to_json)
    end
  end

  # get '/article/:id' do
  #   halt(404, { message:'Not Found'}.to_json) if(params.length<=0)
  #   article = Article.find_by(id: params[:id])
  #   halt(404, { message:'Not Found'}.to_json) if(article.nil?)
  #   article.to_json(:methods => :aid, :only => [ :id, :title, :category, :location, :published_date, :md_data, :category_en, :title_en, :md_data_en])
  # end


  get '/categories' do
    categories = Article.select(:category).distinct
    categories.to_json(:only => :category, :methods => :category_url)
  end

  get '/locations' do
    locations = Article.select(:location).distinct
    locations.to_json(:only => :location, :methods => :location_url)
  end

  get '/dates' do
    dates = Article.select(:published_date).distinct.order(published_date: :desc)
    dates.to_json(:only => :published_date, :methods => :date_url)
  end

end

# Catch All
get '/*' do
  content_type 'application/json'
  halt(404, { message:'Not Found'}.to_json)
end
