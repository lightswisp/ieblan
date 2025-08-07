require "sinatra"
require 'sinatra/base'

class Server < Sinatra::Base
  if settings.development?
    set :bind, '0.0.0.0' 
    set :host_authorization, {
      "permitted_hosts" => [".local"]
    }
  end

  get '/' do 
    @apps = IO.popen(["cmd", "package", "list", "packages", "-U"]).read.split("\n")
    erb :index
  end
end
