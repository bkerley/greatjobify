require 'sinatra'
require 'rack-cache'
require 'dalli'
require 'rmagick'
require 'net/http'

use Rack::Cache,
  :metastore   => 'memcached://localhost:11211/meta',
  :entitystore => 'memcached://localhost:11211/body'

configure do
  set :cache, Dalli::Client.new

  GREAT_JOB = Magick::Image.read('./static/GreatJob.gif').first
end

get '/' do
  'hi2u'
end

get %r{/gj/(.+)} do
  url_string = params[:captures].first
  unless request.query_string.empty?
    url_string << '?'
    url_string << request.query_string
  end

  cache_control :public, :max_age => 36000
  etag Digest::SHA1.hexdigest(url_string)

  url = URI.parse(url_string)
  image = fetch(url)
  great_job = greatjobify(image)


  headers 'Content-type'=>'image/jpeg'
  return great_job
end

helpers do
  def fetch(url)
    return Net::HTTP.get(url)
  end

  def greatjobify(image)
    source = Magick::Image.from_blob(image).first
    grey = source.quantize(256, Magick::GRAYColorspace)
    goal_size = source.columns / 4
    smaller_great_job = GREAT_JOB.change_geometry("x#{goal_size}") do |c,r,i|
      i.resize c, r
    end
    composited = grey.composite(smaller_great_job, Magick::SouthEastGravity, Magick::OverCompositeOp)

    composited.format = 'JPEG'
    composited.to_blob
  end
end
