# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    # A factory class to ensure we always create ParticipatoryProcesses the same way since it involves some logic.
    module ParticipatoryProcessBuilder
      # Public: Creates a new ParticipatoryProcess.
      #
      # attributes        - The Hash of attributes to create the ParticipatoryProcess with.
      # form              - 
      #
      # Returns a ParticipatoryProcess.
      def import(attributes, form)
        Decidim.traceability.perform_action!(:create, ParticipatoryProcess, form.current_user, visibility: "all") do
          @imported_process = ParticipatoryProcess.new(
            organization: form.current_organization,
            title: form.title,
            slug: form.slug,
            subtitle: attributes["subtitle"],
            hashtag: attributes["hashtag"],
            description: attributes["description"],
            short_description: attributes["short_description"],
            promoted: attributes["promoted"],
            # scope: @participatory_process.scope,
            developer_group: attributes["developer_group"],
            local_area: attributes["local_area"],
            # area: @participatory_process.area,
            target: attributes["target"],
            participatory_scope: attributes["participatory_scope"],
            participatory_structure: attributes["participatory_structure"],
            meta_scope: attributes["meta_scope"],
            start_date: attributes["start_date"],
            end_date: attributes["end_date"],
            private_space: attributes["private_space"],
            participatory_process_group: import_process_group(attributes["participatory_process_group"], form)
          )
          @imported_process.remote_hero_image_url= attributes["remote_hero_image_url"] if remote_file_exists?(attributes["remote_hero_image_url"])
          @imported_process.remote_banner_image_url= attributes["remote_banner_image_url"] if remote_file_exists?(attributes["remote_banner_image_url"])
          @imported_process.save!
          @imported_process
        end
      end

      module_function :import

      def import_process_group(attributes, form)
        Decidim.traceability.perform_action!("create", ParticipatoryProcessGroup, form.current_user ) do
          group = ParticipatoryProcessGroup.find_or_initialize_by(
            name: attributes["name"],
            description: attributes["description"],
            organization: form.current_organization
          )

          group.remote_hero_image_url= attributes["remote_hero_image_url"] if remote_file_exists?(attributes["remote_hero_image_url"])
          group.save!
          group
        end
      end

      module_function :import_process_group

      def import_participatory_process_steps(steps, form)
        steps.map do |step_attributes|
          Decidim.traceability.create!(
            ParticipatoryProcessStep,
            form.current_user,
            title: step_attributes["title"],
            description: step_attributes["description"],
            start_date: step_attributes["start_date"],
            end_date: step_attributes["end_date"],
            participatory_process: @imported_process,
            active: step_attributes["active"],
            position: step_attributes["position"]
          )
        end
      end 

      module_function :import_participatory_process_steps

      def import_categories(categories, form)
        categories.map do |category_attributes|
          category = Decidim.traceability.create!(
            Category,
            form.current_user,
            name: category_attributes["name"],
            description: category_attributes["description"],
            parent_id: category_attributes["parent_id"],
            participatory_space: @imported_process
          )
          next if category_attributes["subcategories"].nil?
          category_attributes["subcategories"].map do |subcategory_attributes|
            Decidim.traceability.create!(
              Category,
              form.current_user,
              name: subcategory_attributes["name"],
              description: subcategory_attributes["description"],
              parent_id: category.id,
              participatory_space: @imported_process
            ) 
          end
        end
      end

      module_function :import_categories

      def import_folders_and_attachments(attachments, form)
        attachments["files"].map do |file|
          next unless remote_file_exists?(file["remote_file_url"])
          Decidim.traceability.perform_action!("create", Attachment, form.current_user ) do
            attachment = Attachment.new(
              title: file["title"],
              description: file["description"],
              remote_file_url: file["remote_file_url"],
              attached_to: @imported_process,
              weight: file["weight"]
            )
            attachment.create_attachment_collection(file["attachment_collection"])
            attachment.save!
            attachment
          end 
        end

        attachments["attachment_collections"].map do |collection|
          Decidim.traceability.perform_action!("create", AttachmentCollection, form.current_user ) do
            create_attachment_collection(collection)
          end
        end
      end

      module_function :import_folders_and_attachments

      def create_attachment_collection attributes
        return unless attributes.compact.any?
        attachment_collection = AttachmentCollection.find_or_initialize_by(
          name: attributes["name"],
          weight: attributes["weight"],
          description: attributes["description"],
          collection_for: @imported_process
        )
        attachment_collection.save!
        attachment_collection
      end

      module_function :create_attachment_collection

      def remote_file_exists?(url)
        return if url.nil?
        url = URI.parse(url)
        Net::HTTP.start(url.host, url.port) do |http|
          return http.head(url.request_uri)['Content-Type'].start_with? 'image'
        end
      end

      module_function :remote_file_exists?
    end
  end
end
