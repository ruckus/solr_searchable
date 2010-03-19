require 'will_paginate' #required for pagination support
require 'solr_searchable'

#require 'rsolr/curb'
# monkey patch RSolr to use our new Curb based HTTP client
# module RSolr
#   module Connectable  
#     def connect opts={}
#       Client.new RSolr::Connection::Curb.new(opts)
#     end
#   end
#   extend Connectable
# end
# begin
#   RSolr.connect :url => '' #dummy
# rescue => ex
#   #ignore
# end

ActiveRecord::Base.send(:extend, SolrSearchable::SolrSearchableMethods)
