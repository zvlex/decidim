# frozen_string_literal: true

module Decidim
  module Admin
    # This form handles permissions for a particular action in the admin panel.
    class PermissionForm < Form
      # NOTE: el authorization handlers viene del controlador
      attribute :authorization_handlers, Hash
      attribute :options_collection, Array[Hash]

      def manifest_collection
        @manifest_collection ||= authorization_handlers.keys.map do |handler_name|
          Decidim::Verifications.find_workflow_manifest(handler_name)
        end
        @manifest_collection
      end

      def options_schema_collection
        options_manifest_collection.each_with_index.map do |options_manifest, index|
          #debugger
          # el options antes era un hash y se pasaba al instanciar el form
          options_manifest.schema.new(options_collection[index] || {})
        end
      end

      def options_attributes_collection
        options_manifest_collection.map do |options_manifest|
          options_manifest ? options_manifest.attributes : []
        end
      end

      private

      def options_manifest_collection
        @options_manifest_collection ||= manifest_collection.map(&:options)
        @options_manifest_collection
      end
    end
  end
end
