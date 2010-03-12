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

        # standard request param processing
        # if @params[:sort]
        #   hash[:sort] = @params[:sort].collect do |sort|
        #     key = sort.keys[0]
        #     "#{key.to_s} #{sort[key] == :descending ? 'desc' : 'asc'}"
        #   end.join(',') if @params[:sort]
        # end

        # common parameter processing
        hash[:debugQuery] = @params[:debug_query] if @params[:debug_query]
        hash[:explainOther] = @params[:explain_other] if @params[:explain_other]

        # # facet parameter processing
        # if @params[:facets]
        #   # TODO need validation of all that is under the :facets Hash too
        #   hash[:facet] = true
        #   hash["facet.field"] = []
        #   hash["facet.query"] = @params[:facets][:queries]
        #   hash["facet.sort"] = (@params[:facets][:sort] == :count) if @params[:facets][:sort]
        #   hash["facet.limit"] = @params[:facets][:limit]
        #   hash["facet.missing"] = @params[:facets][:missing]
        #   hash["facet.mincount"] = @params[:facets][:mincount]
        #   hash["facet.prefix"] = @params[:facets][:prefix]
        #   if @params[:facets][:fields]  # facet fields are optional (could be facet.query only)
        #     @params[:facets][:fields].each do |f|
        #       if f.kind_of? Hash
        #         key = f.keys[0]
        #         value = f[key]
        #         hash["facet.field"] << key
        #         hash["f.#{key}.facet.sort"] = (value[:sort] == :count) if value[:sort]
        #         hash["f.#{key}.facet.limit"] = value[:limit]
        #         hash["f.#{key}.facet.missing"] = value[:missing]
        #         hash["f.#{key}.facet.mincount"] = value[:mincount]
        #         hash["f.#{key}.facet.prefix"] = value[:prefix]
        #       else
        #         hash["facet.field"] << f
        #       end
        #     end
        #   end
        # end
        # 
        # # highlighting parameter processing - http://wiki.apache.org/solr/HighlightingParameters
        # #TODO need to add per-field overriding to snippets, fragsize, requiredFieldMatch, formatting, and simple.pre/post
        # if @params[:highlighting]
        #   hash[:hl] = true
        #   hash["hl.fl"] = @params[:highlighting][:field_list].join(',') if @params[:highlighting][:field_list]
        #   hash["hl.snippets"] = @params[:highlighting][:max_snippets]
        #   hash["hl.requireFieldMatch"] = @params[:highlighting][:require_field_match]
        #   hash["hl.simple.pre"] = @params[:highlighting][:prefix]
        #   hash["hl.simple.post"] = @params[:highlighting][:suffix]
        #   hash["hl.fragsize"] = @params[:highlighting][:fragsize] || 500
        # end

        # if @params[:collapse]
        #   hash["collapse.field"] = @params[:collapse][:field]
        # end
        # 
        # if @params[:order]
        #   hash["sort"] = @params[:order]
        # end
        hash = hash.merge(@params)
        #super_hash = super.to_hash
        # if @params[:query_type]
        #   super_hash[:qt] = @params[:query_type]
        # end
        hash.merge(super.to_hash)
      end
      
    end #class Standard
  end #Handler
end #SolrSearchable