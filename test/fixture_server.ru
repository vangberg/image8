FixtureServer = Rack::Builder.new {
  use Rack::Static, :urls => ["/fixtures"], :root => "test"
  run lambda {|env| [404, {}, []]}
}

run FixtureServer
