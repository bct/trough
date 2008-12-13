require 'camping'

Camping.goes :Trough

module Trough
end

# define RDF vocabulary namespaces
RDF_NS =  'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
RDFS_NS = 'http://www.w3.org/2000/01/rdf-schema#'
FOAF_NS = 'http://xmlns.com/foaf/0.1/'
RSS_NS =  'http://purl.org/rss/1.0/'

module Trough::Models
  class Subscription < Base
    # turn a subscription into an ntriples line
    # <http://www.w3.org/2001/sw/RDFCore/ntriples/>
    def ntriplify
      # feed URL is unique, node names have to begin with a letter,
      # abs to remove any negative
      # this isn't a perfect hash, but it's probably good enough
      node_name = 'x' + self.feed_url.hash.abs.to_s(36)

      nt = ''

      # we don't know this is a Person (some blogs are written by many people),
      # so let's call it an Entity.
      nt << "_:#{node_name} <#{RDF_NS}type>    <#{FOAF_NS}Entity> .\n"
      # this Entity is called...
      nt << "_:#{node_name} <#{FOAF_NS}name>   \"#{self.name}\" .\n"
      # this Entity has a blog at...
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

  class Setup < V 0.1
    def self.up
      create_table :trough_subscriptions, :force => true do |t|
        t.column :name, :string, :limit => 255, :null => false
        t.column :blog_url, :string, :limit => 255, :null => false
        t.column :feed_url, :string, :limit => 255, :null => false
      end
    end
  end
end

module Trough::Controllers
  class Subscriptions < R '/'
    def get
      @subs = Subscription.find :all

      if @input['t'] == 'rdf'
        @headers['Content-Type'] = 'text/plain' # <-- that's a crappy mimetype
        @subs.map { |s| s.ntriplify }.join
      else
        render :subs
      end
    end

    def post
      Subscription.create! :name => @input.name,
                            :blog_url => @input.blog_url,
                            :feed_url => @input.feed_url

      redirect '/'
    end
  end

  class Add < R '/add'
    def get
      render :add
    end
  end

  class Delete < R '/delete'
    def post
      Subscription.find_by_feed_url(@input['feed_url']).destroy

      redirect '/'
    end
  end
end

module Trough::Views
  def layout
    html do
      body do
        self << yield
      end
    end
  end

  def subs
    h1 'browse.'

    a 'new', :href => R(Add)

    ul do
      @subs.each do |s|
        li.sub do
          a s.name, :href => s.blog_url
          text ' '
          a '[feed]', :href => s.feed_url
          form :method => 'post', :action => R(Delete) do
            input :type => 'hidden', :name => 'feed_url', :value => s.feed_url
            input :type => 'submit', :value => 'x'
          end
        end
      end
    end
  end

  def add
    h1 'add.'

    form :action => '/', :method => 'post' do
      text 'name:'; input :name => 'name' ; br
      text 'blog url:'; input :name => 'blog_url' ; br
      text 'feed url:'; input :name => 'feed_url' ; br

      input :type => 'submit'
    end
  end
end

def Trough.create
  Trough::Models.create_schema
end
