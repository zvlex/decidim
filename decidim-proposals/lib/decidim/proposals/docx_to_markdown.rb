# frozen_string_literal: true
require "doc2text"
require "tempfile"

module Decidim
  module Proposals
    # This class parses a participatory text document in open document (libre office .odt) format and
    # produces a Markdown version of the document.
    #
    # This implementation uses doc2text.
    #
    class DocxToMarkdown
      # Public: Initializes the serializer with a proposal.
      def initialize(doc)
        @doc = doc
      end

      def to_md
        doc_file= doc_to_tmp_file
        md_file= transform_to_md_file(doc_file)
        md_file.read
      end

      #-----------------------------------------------------

      private

      #-----------------------------------------------------

      def doc_to_tmp_file
        file = Tempfile.new('doc-to-markdown-docx')
        file.write(@doc)
        file
      end
      # def transform_to_md_file(doc_file)
      #   md_file= Tempfile.new
      #   Doc2Text::Markdown::OdtParser(md_file)
      #   md_file
      # end
      def transform_to_md_file(doc_file)
        puts "DOCSIZE::::#{doc_file.size}"
        md_file= Tempfile.new
        Doc2Text::XmlBasedDocument::Docx::Document.parse_and_save(doc_file, md_file)
        md_file
      end

    end
  end
end
