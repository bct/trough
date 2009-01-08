#!/usr/bin/env ruby

# import an existing Venus FOAF reading list into the trough.
# this requires ActiveRDF and the Redland adapter.

# you'll want to change these:
FOAF_URL = './reading.ttl' # your reading list's URL
FOAF_TYPE = 'turtle' # 'turtle', 'ntriples' or 'rdfxml'
MOUNT_URL = 'http://necronomicorp.com/reading' # URL trough is mounted at

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

require 'net/http'
require 'uri'

# load the original RDF data into our new database
a.query(q).each do |name, blog_url, feed_url|
  Net::HTTP.post_form(URI.parse(MOUNT_URL), {'name' => name,
                                            'blog_url' => blog_url.uri,
                                            'feed_url' => feed_url.uri})
end
