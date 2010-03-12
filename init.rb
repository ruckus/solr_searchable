require 'will_paginate' #required for pagination support
require 'solr_searchable'

ActiveRecord::Base.send(:extend, SolrSearchable::SolrSearchableMethods)
