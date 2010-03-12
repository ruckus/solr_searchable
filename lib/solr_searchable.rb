require 'rsolr'
require File.dirname(__FILE__) + '/class_methods'
require File.dirname(__FILE__) + '/instance_methods'
require File.dirname(__FILE__) + '/common_methods'
require File.dirname(__FILE__) + '/handler'
require File.dirname(__FILE__) + '/clause'


module SolrSearchable
  
  # def self.included(base)
  #   base.send :extend, SolrSearchable::ClassMethods 
  # end
  
  module IO
    
    # Currently a new connection will be loaded per request (per ActiveRecord save/destroy)
    # call. This means the YAML config file is parsed each time. If we really wanted to eek out
    # as much performance as possible we could cache this connection - sacrificing the flexibility
    # of establising a fresh request each time. If we cached the connection and Solr went down
    # then the whole Rails process would be referring to a defunct connection
    def self.get_connection
      return @__connection if @__connection
      if File.exists?(RAILS_ROOT+'/config/solr.yml')
        config = YAML::load_file(RAILS_ROOT+'/config/solr.yml')
        url = config[RAILS_ENV]['url']
      else
        url = 'http://localhost:8982/solr'
      end
      @__connection = RSolr.connect :url => url
      @__connection
    end

    class Request    
      def self.execute(request)
        begin
          connection = SolrSearchable::IO.get_connection
          connection.request(request)
        rescue => ex
          Rails.logger.info "Solr error: #{ex.message} : #{$!}"
          # if Rails.env == 'production'
          #   HoptoadNotifier.notify(
          #     :error_class => "Solr Error", 
          #     :error_message => "Solr Error: #{ex.message}", 
          #     :request => { :params => request }
          #   )
          # end
          false
        end
      end
    end
  end
  
  module SolrSearchableMethods
    def solr_searchable(opts = {})
      extend ClassMethods
      include InstanceMethods
      include CommonMethods
      include ParserMethods
      
      class_inheritable_accessor :solr_searchable_configuration
      class_inheritable_accessor :solr_searchable_column_types
      class_inheritable_accessor :solr_searchable_default_query_options
      self.solr_searchable_configuration = { 
        :fields => nil,
        :additional_fields => nil,
        :exclude_fields => [],
        :auto_commit => true,
        :include => nil,
        :facets => nil,
        :boost => nil,
        :if => "true",
        :type_field => "type_s",
        :primary_key_field => "pk_i",
        :default_boost => 1.0,
        :limit => 10     
      }
      # :format can be one of :objects or :ids    
      # defaults to :objects
      self.solr_searchable_default_query_options = {
        :format => :objects
      }
      if opts[:fields]
        self.solr_searchable_configuration[:fields] = opts[:fields]
        self.solr_searchable_column_types = {}
        # generate another data structure that is inverted and has the field names as keys
        opts[:fields].each do |field_definition|
          type = field_definition.keys.first
          attribute = field_definition[type]
          self.solr_searchable_column_types[attribute.to_sym] = type.to_sym
        end
      else
        raise StandardError, 'no :fields declared for the solr_searchable plugin'
      end
      
      #== ActiveRecord callback hooks
      before_save :solr_save
      before_destroy :solr_destroy
    end #solr_searchable
    
  end # module SolrSearchableMethods
  
end
