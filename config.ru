require 'rack'
use Rack::ContentLength

run(proc do
  [ 200, { 'Content-type'=>'text/plain'}, ['hi']]
end)
