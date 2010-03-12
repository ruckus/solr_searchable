module SolrSearchable
  module Handler
    class Base
      attr_reader :handler, :model, :options
      
      def initialize(handler, model, options = {})
        @handler = handler
        @model = model
        @options = options
      end
      
      def to_hash
        {:qt => @handler}
      end
      
      def parse_response(solr_data)
        results = {
          :docs => [],
          :total_hits => 0,
          :start => 0
        }
        return result if solr_data.nil? || !solr_data.has_key?('response')
        if @options[:format] == :objects
          ids = solr_data['response']['docs'].collect {|doc| doc["#{@model.solr_searchable_configuration[:primary_key_field]}"]}.flatten
          if ids.compact.size > 0
            conditions = [ "#{@model.table_name}.#{@model.primary_key} IN (?)", ids ]
            result = reorder(@model.find(:all, :conditions => conditions), ids)
          end
        elsif @options[:format] == :raw
          result = solr_data['response']['docs']
        end
        results.update({:docs => result, :total_hits => solr_data['response']['numFound'], 
            :start => solr_data['response']['start']})                  
        results
      end #parse_response

      # Reorders the instances keeping the order returned from Solr
      def reorder(things, ids)
        ordered_things = []
        ids.each do |id|
          record = things.find {|thing| @model.record_id(thing).to_s == id.to_s} 
          #raise "Out of sync! The id #{id} is in the Solr index but missing in the database!" unless record
          if record
            ordered_things << record
          end
        end
        ordered_things
      end
      
    end
  end
end