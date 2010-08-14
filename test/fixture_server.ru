require "sinatra/base"

class FixtureServer < Sinatra::Base
  use Rack::Static, :urls => ["/fixtures"], :root => "test"
  
  get "/redirect" do
    redirect "/fixtures/matador.jpg"
  end
end

run FixtureServer
