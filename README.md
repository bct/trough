[Venus][] supports FOAF reading lists in this format:

    _                         a            foaf:Agent
    _                         foaf:name    "some name"
    _                         foaf:weblog  <http://example.com/>

    <http://example.com/>     a            foaf:Document
    <http://example.com/>     rdfs:seeAlso <http://example.com/feed>

    <http://example.com/feed> a            rss:channel

Trough serves a list like this from an SQLite database, in ntriples format.

Venus can also do a bunch of other cool stuff with FOAF reading lists, but we're
not doing anything with that right now.

All you need is Camping.

To set this up in Venus, add to your config.ini:

    [http://url_you_mounted_trough_at/?t=rdf]
    content_type = foaf
    depth=1

[Venus]: http://www.intertwingly.net/code/venus/
