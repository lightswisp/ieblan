require "json"
require "sinatra"
require 'sinatra/base'
require_relative "../helpers/iptables"

App = Struct.new(
  :uid,
  :pkg_name,
  :icon_file,
  :blocked,
)

class Server < Sinatra::Base

  if settings.development?
    set :bind, '0.0.0.0' 
    set :host_authorization, {
      "permitted_hosts" => [".local"]
    }
  end

  set :appfilter, JSON.parse(File.read(File.join("ui", "appfilter.json")))
  set :iptables, IPTables.new()
  set :apps, []

  def initialize()
    apps_cmd = IO.popen(["cmd", "package", "list", "packages", "-3", "-U"]).read.split("\n")
    settings.iptables.init_rules()

    apps_cmd.each do |app|
      app = app[8..-1] # del package: 
      pkg_name, uid = app.split(" ")   
      uid = uid.split(":").last
      icon_name = settings.appfilter[pkg_name]
      if icon_name.nil?
        icon_file = File.join("icons", "android_system.png")
      else
        icon_file = File.join("icons", icon_name) 
      end
      settings.apps << App.new(
        uid,
        pkg_name,
        icon_file,
        settings.iptables.rule_exist?(uid)
      )
    end
    super
  end


  get '/' do 
    @apps = settings.apps
    @version = settings.iptables.version
    erb :index
  end

  post '/block-one' do
    json = JSON.parse(request.body.read)
    pkg_name = json['pkg_name']

    settings.iptables.rules_add([pkg_name])
    app = settings.apps.find{|app| app.pkg_name == pkg_name}
    app.blocked = true
    200
  end

  post '/unblock-one' do 
    json = JSON.parse(request.body.read)
    pkg_name = json['pkg_name']

    settings.iptables.rules_del([pkg_name])
    app = settings.apps.find{|app| app.pkg_name == pkg_name}
    app.blocked = false
    200
  end
end
