require 'net/http'
require 'uri'
require 'feedjira'

module Feedjira
  module Parser
    # Parser for dealing with RDF feed entries.
    class ArxivAtomEntryAuthor
      include SAXMachine
      include FeedEntryUtilities

      element :name
    end
  end
end

module Feedjira
  module Parser
    # Parser for dealing with RDF feed entries.
    class ArxivAtomEntry
      include SAXMachine
      include FeedEntryUtilities

      element :id, as: :entry_id
      element :updated
      element :published
      element :title
      element :summary
      elements :author, as: :authors, class: ArxivAtomEntryAuthor
      element :arxiv
      elements :category, as: :categories, value: :term
      elements :link, as: :links, value: :href
    end
  end
end

module Feedjira
  module Parser
    # Parser for dealing with RSS feeds.
    class ArxivAtom
      include SAXMachine
      include FeedUtilities

      element :title
      element :link, as: :url, value: :href, with: { type: "text/html" }
      element :link, as: :feed_url, value: :href, with: { rel: "self" }
      elements :entry, as: :entries, class: ArxivAtomEntry

      def self.able_to_parse?(xml)
        %r{\<feed[^\>]+xmlns\s?=\s?[\"\'](http://www\.w3\.org/2005/Atom|http://purl\.org/atom/ns\#)[\"\'][^\>]*\>} =~ xml # rubocop:disable Metrics/LineLength
      end

    end
  end
end

module Jekyll

  class Arxiv < Liquid::Tag

    # def initialize(tag_name, remote_include, tokens)
    #   super
    #   @remote_include = remote_include
    # end

    # def open(url)
    #   Net::HTTP.get(URI.parse(url.strip)).force_encoding 'utf-8'
    # end

    # def render(context)
    #   open("#{@remote_include}")
    # end
    def initialize(tag_name, input, tokens)
      @input = input
      super
    end

    def render(context)
      puts 'Fetching content of Arxiv input: ' + @input
      arxiv_id = Liquid::Template.parse(@input).render(context)
      puts 'Fetching content of Arxiv id: ' + arxiv_id
      @feed = fetchContent(arxiv_id)
      if @feed
        title = @feed.entries[0].title
        link = @feed.entries[0].links[0]
        link_pdf = @feed.entries[0].links[1]
        authors_entries = @feed.entries[0].authors.entries
        abstract = @feed.entries[0].summary
        puts "Author nubers: ", authors_entries.length
        if authors_entries.length == 1
          puts "One author"
          names = authors_entries[0].name
        end
        if authors_entries.length == 2
          puts "Two authors"
          names = authors_entries[0].name + ', ' + authors_entries[1].name
        end
        if authors_entries.length == 3
          puts "Three authors"
          names = authors_entries[0].name + ', ' + authors_entries[1].name + ', ' + authors_entries[2].name
        end
        if authors_entries.length > 3
          puts "Many authors"
          names = authors_entries[0].name + ', ' + authors_entries[1].name + ', ' + authors_entries[2].name + ' et al.'
        end
        # output = title.sub! "\n", ''
        output = "- " + names + " - [" + title + "](" + link + ") \n\n" + 
            "<div class='abstract'>"+abstract+"</div>"
        puts 'OUTput:'
        puts output
        return output
      else
        raise 'Something went wrong in extracting Arxiv data'
      end
    end

    def fetchContent(arxiv_id)
      Feedjira::Feed.add_feed_class Feedjira::Parser::ArxivAtom
      url = 'http://export.arxiv.org/api/query?id_list='+arxiv_id
      puts "url: " + url
      feed = Feedjira::Feed.fetch_and_parse(url)
      return feed
    end

  end
end

Liquid::Template.register_tag('arxiv', Jekyll::Arxiv)