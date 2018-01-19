require 'middleman-core'
require 'v8'

module Middleman::Lunr
  class Indexer
    def initialize(extension)
      @extension = extension
    end

    def generate(options)
      docs = []
      fields = []
      map = {}

      if options[:body]
        fields.push(:body)
      end

      options[:data].each do |d|
        fields.push(d)
      end

      #@extension.sitemap.resources.each do |res|
      pages = @extension.sitemap.resources.find_all { |p| p.source_file.match(/\.md/) }

      pages.each_with_index do |res, index|
        #if res.data[:index]
          doc = { id: res.url.to_s }
          key = res.url.to_s
          data = {}

          #https://gist.github.com/hjc/4450428
          if options[:body]
              stopwords = %w{the a by on for of are with just but and to the my I has some in}
              text = res.render({:layout => false }).gsub(%r{</?[^>]+?>}, '' )
              sentences = text.gsub(/\s+/, ' ').strip.split(/\.|\?|!/)
              ideal_sentences = sentences
              #sentences_sorted = sentences.sort_by { |sent| sent.length }
             # one_third = sentences_sorted.length / 1.5
              #ideal_sentences = sentences_sorted.slice(one_third, one_third + 1)
             # ideal_sentences.select! { |s| s =~ /is|are/ }
              #descriptives = ideal_sentences.select! { |s| s =~ /is|are/ }
              # doc[:body] = ideal_sentences
             #doc[:body] = File.read(res.source_file)
             doc[:body] = ideal_sentences.join(". ") + "."#ideal_sentences#res.render({:layout => false }).gsub(%r{</?[^>]+?>}, '' )
          end

          options[:data].each do |d|
            doc[d] = res.data[d]
            data[d.to_s] = res.data[d]
          end

          docs << doc
          map[key] = data
        end
     # end

      cxt = V8::Context.new
      cxt.load(File.expand_path('../../../js/lunr.js', __FILE__))
      cxt.eval('lunr.Index.prototype.dumpIndex = function(){return JSON.stringify(this.toJSON());}')
      ref = cxt.eval('lunr')

      lunr_conf = proc do |this|
        this.ref('id')
        fields.each do |name|
          this.field(name) #, {:boost => boost})
        end
        docs.each do |doc|
          this.add(doc)
        end
      end

      idx = ref.call(lunr_conf)



      data = JSON.parse(idx.dumpIndex(), max_nesting: false)

      { index: data, map: map }
    end
  end
end
