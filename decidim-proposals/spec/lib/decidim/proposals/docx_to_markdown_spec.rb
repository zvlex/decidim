# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe DocxToMarkdown do

      context "from MS Word docx file" do
        it "transforms into markdown" do
          file= IO.read(Decidim::Dev.asset("participatory_text.docx"))
          transformer= DocToMarkdown.new(file, DocToMarkdown::DOCX_MIME_TYPE)

          expected= IO.read(Decidim::Dev.asset("participatory_text.md"))
          puts ">>>>>>>>>>>>>>>>>>>>>"
          puts transformer.to_md
          puts "<<<<<<<<<<<<<<<<<<<<<"
          expect(transformer.to_md).to eq(expected)
        end
      end

    end
  end
end
