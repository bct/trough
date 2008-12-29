#!/usr/bin/env ruby

# import an existing Venus FOAF reading list into the trough.
# this requires ActiveRDF and the Redland adapter.

# you'll want to change these:
FOAF_URL = 'http://necronomicorp.com/reading' # your reading list's URL
FOAF_TYPE = 'turtle' # 'turtle', 'ntriples' or 'rdfxml'

require 'trough'

db = File.join(ENV['HOME'], '.camping.db') # the default camping database
Camping::Models::Base.establish_connection :adapter => 'sqlite3',
  :database => db

require 'active_rdf'

a = ConnectionPool.add_data_source :type => :redland

# parse the reading list
a.load(FOAF_URL, FOAF_TYPE)

# set up ActiveRDF
Namespace.register :foaf, 'http://xmlns.com/foaf/0.1/'
Namespace.register :rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
ObjectManager.construct_classes

# set up our query
q = Query.new.select(:name, :blog_url, :feed_url) \
  .where(:blog,     FOAF::name,   :name) \
  .where(:blog,     FOAF::weblog, :blog_url) \
  .where(:blog_url, RDFS::seeAlso,:feed_url)

# load the original RDF data into our new database
a.query(q).each do |name, blog_url, feed_url|
  Trough::Models::Subscription.create :name => name,
    :blog_url => blog_url.uri,
    :feed_url => feed_url.uri
end
