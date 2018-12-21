# frozen_string_literal: true

module Decidim
  module Admin
    # Controller that allows managing component permissions.
    #
    class ComponentPermissionsController < Decidim::Admin::ApplicationController
      include Decidim::ComponentPathHelper

      helper Decidim::ResourceHelper

      helper_method :authorizations, :other_authorizations_for, :component, :resource_params, :resource

      def edit
        puts "[DEBUG] ComponentPermissionsController#edit parameters:"
        puts JSON.pretty_generate(JSON.parse params.to_json)

        enforce_permission_to :update, :component, component: component
        @permissions_form = PermissionsForm.new(
          permissions: permission_forms
        )
      end

      def update
        puts "[DEBUG][ComponentPermissionsController#update] parameters before parsing:"
        puts JSON.pretty_generate(JSON.parse params.to_json)

        enforce_permission_to :update, :component, component: component
        @permissions_form = PermissionsForm.from_params(parse_permissions_parameters)

        UpdateComponentPermissions.call(@permissions_form, component, resource) do
          on(:ok) do
            flash[:notice] = t("component_permissions.update.success", scope: "decidim.admin")
            redirect_to return_path
          end

          on(:invalid) do
            render action: :edit
          end
        end
      end

      private

      # Esto lo estoy utilizando para ajustar los parámetros que vienen del form HTML al formato que espera
      # el form object. Lo ideal sería encapsularlo dentro del FormObject.
      # Lo que viene del HTML debería tener este formato:
      # {
      #   "_method": "put",
      #   "component_permissions": {
      #     "permissions": {
      #       "vote" : {
      #         "authorization_handlers_names": [],
      #         "authorization_handlers_options": {}
      #       },
      #       "endorse": {
      #         "authorization_handlers_names": [
      #           "postal_letter",
      #           "dummy_authorization_handler"
      #         ],
      #         "authorization_handlers_options": {
      #           "dummy_authorization_handler": {
      #             "options": {
      #               "postal_code": "28007"
      #             }
      #           }
      #         }
      #       }
      #     }
      #   }
      # }
      #
      # En la BD se guarda con este formato:
      #
      # {
      #   "vote": {},
      #   "endorse": {
      #     "authorization_handlers": {
      #       "postal_letter": {},
      #       "dummy_authorization_handler": {
      #         "options": {
      #           "postal_code": "28007"
      #         }
      #       }
      #     }
      #   }
      # }
      def parse_permissions_parameters
        params_hash = JSON.parse(params.to_json).with_indifferent_access
        parsed_params = { permissions: params_hash[:component_permissions][:permissions].deep_dup }.with_indifferent_access

        params_hash[:component_permissions][:permissions].keys.each do |action|
          parsed_params[:permissions][action] = {}
          parsed_params[:permissions][action]["authorization_handlers"] = {}

          handlers_keys = params_hash[:component_permissions][:permissions][action]["authorization_handlers"].select(&:present?).deep_dup

          handlers_keys.each do |handler_name|
            handler_value = params_hash[:component_permissions][:permissions][action]["authorization_handlers_options"][handler_name].deep_dup
            handler_value ||= {}
            parsed_params[:permissions][action]["authorization_handlers"][handler_name] = handler_value
          end

        end

        puts "[DEBUG][ComponentPermissionsController#update] parameters after parsing:"
        puts JSON.pretty_generate(JSON.parse parsed_params.to_json)

        parsed_params
      end

      def return_path
        if resource
          manage_component_path(component)
        else
          components_path(current_participatory_space)
        end
      end

      def resource_params
        params.permit(:resource_id, :resource_name).to_h.symbolize_keys
      end

      def permission_forms
        actions.inject({}) do |result, action|
          # esto que
          form = PermissionForm.new(
            authorization_handlers: authorizations_for(action)#,
            #options_collection: []#permissions.dig(action, "options")
          )

          result.update(action => form)
        end
      end

      def actions
        @actions ||= (resource&.resource_manifest || component.manifest).actions
      end

      def authorizations
        Verifications::Adapter.from_collection(
          current_organization.available_authorizations
        )
      end

      def other_authorizations_for(action)
        puts "Available authorizations for organization: #{current_organization.available_authorizations}"
        puts "Authorizations already required for this action: #{authorizations_for(action).keys}"

        other_authorizations_names = current_organization.available_authorizations - authorizations_for(action).keys

        result = Verifications::Adapter.from_collection(
          other_authorizations_names
        )
        #puts "Returning verification adapters: #{result}"
        result
      end

      def resource
        @resource ||= if params[:resource_id] && params[:resource_name]
                        res = Decidim.find_resource_manifest(params[:resource_name])&.resource_scope(component)&.find_by(id: params[:resource_id])
                        res if res&.allow_resource_permissions?
                      end
      end

      def component
        @component ||= current_participatory_space.components.find(params[:component_id])
      end

      def permissions
        @permissions ||= (component.permissions || {}).merge(resource&.permissions || {})
      end

      def authorizations_for(action)
        permissions.dig(action, "authorization_handlers") || {}
      end

      # def authorizations_for(action)
      #   permissions.dig(action, "authorization_handler_name")
      # end
    end
  end
end
