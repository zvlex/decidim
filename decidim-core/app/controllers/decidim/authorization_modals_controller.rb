# frozen_string_literal: true

module Decidim
  class AuthorizationModalsController < Decidim::ApplicationController
    helper_method :status, :authorize_action_path
    layout false

    def show; end

    private

    def resource
      @resource ||= if params[:resource_name] && params[:resource_id]
                      manifest = Decidim.find_resource_manifest(params[:resource_name])
                      manifest&.resource_scope(current_component)&.find_by(id: params[:resource_id])
                    end
    end

    def current_component
      @current_component ||= Decidim::Component.find(params[:component_id])
    end

    def authorization_action
      @authorization_action ||= params[:authorization_action]
    end

    def authorize_action_path
      # esto hay que actualizarlo, si no en la modal me llevan todos los botones al mismo path
      status.current_path(redirect_url: URI(request.referer).path)
    end

    def status
      # de aquí se saca el nombre que aparece en el botón
      # devuelve la clase de status normal
      @status ||= action_authorized_to(authorization_action, resource: resource)
      Rails.logger.debug "**************************"
      Rails.logger.debug "Status returned by the AuthorizationModalsController"
      Rails.logger.debug @status
      Rails.logger.debug "**************************"

      @status
    end
  end
end
