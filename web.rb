require 'sinatra'
require 'rack-cache'
require 'dalli'
require 'RMagick'
require 'excon'

memcache_address = ENV['MEMCACHIER_SERVERS'] || 'localhost:11211'
memcache = [
            memcache_address,
            {
              username: ENV['MEMCACHIER_USERNAME'] || nil,
              password: ENV['MEMCACHIER_PASSWORD'] || nil
            }
            ]
dalli = Dalli::Client.new memcache

use Rack::Cache,
  :metastore   => dalli,
  :entitystore => dalli

configure do
  set :cache, dalli

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

  image = fetch(url_string)
  great_job = greatjobify(image)


  headers 'Content-type'=>'image/jpeg'
  return great_job
end

helpers do
  def fetch(url)
    return Excon.get(url).body
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
