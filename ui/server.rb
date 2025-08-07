require "json"
require "sinatra"
require 'sinatra/base'

class Server < Sinatra::Base
  @@appfilter = JSON.parse(File.read(File.join("ui", "appfilter.json")))
  if settings.development?
    set :bind, '0.0.0.0' 
    set :host_authorization, {
      "permitted_hosts" => [".local"]
    }
  end

  get '/' do 
    @apps = IO.popen(["cmd", "package", "list", "packages", "-3", "-U"]).read.split("\n")
    erb :index
  end
end
