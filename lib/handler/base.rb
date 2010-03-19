module SolrSearchable
  module Handler
    class Base
      attr_reader :handler, :model, :options, :activerecord_options
      
      def initialize(handler, model, options = {}, activerecord_options = {})
        @handler = handler
        @model = model
        @options = options
        @activerecord_options = {}
        if @options.has_key?(:include)
          @activerecord_options[:include] = @options[:include]
          @options.delete(:include)
        end
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
        #puts solr_data.inspect
        if @options[:format] == :objects
          ids = solr_data['response']['docs'].collect {|doc| doc["#{@model.solr_searchable_configuration[:primary_key_field]}"]}.flatten
          if ids.compact.size > 0
            ids.compact!
            conditions = [ "#{@model.table_name}.#{@model.primary_key} IN (?)", ids ]
            @activerecord_options[:conditions] = conditions
            result = reorder(@model.find(:all, @activerecord_options), ids).flatten
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
          record = things.select {|thing| @model.record_id(thing).to_s == id.to_s} 
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