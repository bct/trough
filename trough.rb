require 'haml'
require 'sinatra'

require 'activerecord'

configure do
  ActiveRecord::Base.establish_connection(
    :adapter => 'sqlite3',
    :database => '/home/bct/.camping.db',
    :encoding => 'utf8'
  )
end

USERNAME = 'user'
PASSWORD = 'pass'

# define RDF vocabulary namespaces
RDF_NS =  'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
RDFS_NS = 'http://www.w3.org/2000/01/rdf-schema#'
FOAF_NS = 'http://xmlns.com/foaf/0.1/'
RSS_NS =  'http://purl.org/rss/1.0/'

class Subscription < ActiveRecord::Base
  set_table_name 'trough_subscriptions'

  # turn a subscription into an ntriples line
  # this is far from a complete implementation...
  # <http://www.w3.org/2001/sw/RDFCore/ntriples/>
  def ntriplify
    # feed URL is unique, node names have to begin with a letter,
    # abs to remove any negative
    # this isn't a perfect hash, but it's probably good enough
    node_name = 'x' + self.feed_url.hash.abs.to_s(36)

    nt = ''

    # we don't know this is a Person (some blogs are written by many people),
    # so let's call it an Agent.
    nt << "_:#{node_name} <#{RDF_NS}type> <#{FOAF_NS}Agent> .\n"
    # this Agent is called...
    nt << "_:#{node_name} <#{FOAF_NS}name> \"#{self.name}\" .\n"
    # this Agent has a blog at...
    nt << "_:#{node_name} <#{FOAF_NS}weblog> <#{self.blog_url}> .\n"

    # that blog is a Document...
    nt << "<#{self.blog_url}> <#{RDF_NS}type> <#{FOAF_NS}Document> .\n"
    # if you're interested in that blog you should also see...
    nt << "<#{self.blog_url}> <#{RDFS_NS}seeAlso> <#{self.feed_url}> .\n"

    # this url is an RSS channel...
    nt << "<#{self.feed_url}> <#{RDF_NS}type> <#{RSS_NS}channel> .\n"

    nt
  end
end

class Setup < ActiveRecord::Migration
  def self.up
    create_table :trough_subscriptions, :force => true do |t|
      t.column :name, :string, :limit => 255, :null => false
      t.column :blog_url, :string, :limit => 255, :null => false
      t.column :feed_url, :string, :limit => 255, :null => false
    end
  end
end

helpers do
  def url(path)
    u = request.script_name
    u = u[0..-2] if u[-1] and u[-1].chr == '/'
    u + path
  end
end

get '/?' do
  @subs = Subscription.find :all

  if params['t'] == 'rdf'
    content_type 'text/plain' # <-- that's a crappy mimetype
    @subs.map { |s| s.ntriplify }.join
  elsif params['t'] == 'feedurls'
    content_type 'text/plain'
    @subs.map { |s| s.feed_url + "\n" }.join
  else
    haml <<END
%h1 browse.

%a{:href => url('/add')} new

%ul
  - @subs.each do |s|
    %li.sub
      %a{:href => s.blog_url}= s.name
      [
      %a{:href => s.feed_url} feed
      ]
      %form{:method => 'post', :action => url('/delete')}
        %input{:type => 'hidden', :name => 'feed_url', :value => s.feed_url}/
        %input{:type => 'submit', :value => 'x'}/
END
  end
end

post '/' do
  Subscription.create! :name => params[:name],
                        :blog_url => params[:blog_url],
                        :feed_url => params[:feed_url]

  redirect url('/')
end

get '/add' do
  haml <<END
%h1 add.

%form{:method => 'post', :action => url('/')}
  name: <input name="name"><br>
  blog url: <input name="blog_url"><br>
  feed url: <input name="feed_url"><br>

  <input type="submit">
END
end

post '/delete' do
  Subscription.find_by_feed_url(params[:feed_url]).destroy

  redirect url('/')
end

# spammers go home
require 'rack/auth/basic'

class PostAuth
  def initialize app
    @app = app
    @auth = Rack::Auth::Basic.new(app) do |u,p|
      u == USERNAME && p == PASSWORD
    end
  end

  def call env
    if env['REQUEST_METHOD'] == 'POST'
      @auth.call(env)
    else
      @app.call(env)
    end
  end
end

use PostAuth
