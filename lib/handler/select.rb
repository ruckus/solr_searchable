module SolrSearchable
  module Handler
    class Select < SolrSearchable::Handler::Base
      
      VALID_PARAMS = [:q, :sort, :default_field, :operator, :start, :rows, :query_type, :order,
        :fq, :fl, :debug_query, :explain_other, :facets, :highlighting, :collapse]

      def initialize(params, model, environment_options = {})
        super('standard', model, environment_options)
        raise "Invalid parameters: #{(params.keys - VALID_PARAMS).join(',')}" unless (params.keys - VALID_PARAMS).empty?
        raise ":q parameter required" unless params[:q]

        @params = params.dup
        
        # Validate start, rows can be transformed to ints
        @params[:start] = params[:start].to_i if params[:start]
        @params[:rows] = params[:rows].to_i if params[:rows]

        if @params[:fl]
          @params[:fl] = (@params[:fl] << 'score').uniq.join(",")
        else
          @params[:fl] = "*,score"
        end
      end
      
      def execute
        query = to_hash
        rsolr = SolrSearchable::IO.get_connection
        response = rsolr.select query
        parse_response(response)
      end

      def to_hash
        hash = {}
        # common parameter processing
        hash[:debugQuery] = @params[:debug_query] if @params[:debug_query]
        hash[:explainOther] = @params[:explain_other] if @params[:explain_other]
        hash = hash.merge(@params)
        hash.merge(super.to_hash)
      end
      
    end #class Standard
  end #Handler
end #SolrSearchable