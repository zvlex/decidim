# frozen_string_literal: true

module Decidim
  # This class is used to authorize a user against an action in the context of a
  # component.
  class ActionAuthorizer
    #
    # Initializes the ActionAuthorizer.
    #
    # user      - The user to authorize against.
    # action    - The action to authenticate.
    # component - The component to authenticate against.
    # resource  - The resource to authenticate against. Can be nil.
    #
    def initialize(user, action, component, resource)
      @user = user
      @action = action.to_s if action
      @component = resource&.component || component
      @resource = resource
    end

    #
    # Authorize user to perform an action in the context of a component.
    #
    # Returns:
    #   :ok an empty hash                      - When there is no authorization handler related to the action.
    #   result of authorization handler check  - When there is an authorization handler related to the action. Check Decidim::Verifications::DefaultActionAuthorizer class docs.
    #
    def authorize
      raise AuthorizationError, "Missing data" unless component && action

      results = []

      # TODO: esta implementación es temporal para que mas o menos pasen los tests.
      # Inicialmente llamaba al método authorize del único AuthorizationHandler y
      # devolvía el resultado encapsulado dentro de la clase AuthorizationStatus.
      # Hay que modficarla para que llame a `authorize` sobre todos los handlers y:
      # (1) devuelve todos los estados dentro de AuthorizationStatus, (2) devuelva un
      # array de AuthorizationStatus. Probablemente sea mas sencilla la opción (1)

      if authorization_handlers
        authorization_handlers.each do |handler_name, handler_attrs|
          authorization = get_authorization(handler_name)
          handler = Verifications::Adapter.from_element(handler_name)
          options = handler_attrs.fetch("options", {})
          results << handler.authorize(authorization, options, component, resource)
        end
      else
        results << [:ok, {}]
      end

      all_status_codes = results.map(&:first).uniq
      all_data = results.map(&:second)

      # provisionalmente devuelvo :ok si todos :ok, o el primero que no sea :ok
      status_code = all_status_codes == [:ok] ? :ok : all_status_codes.reject { |code| code == :ok }.first
      # provisionalmente se devuelve solo el primer handler
      authorization_handler = authorization_handlers ? authorization_handlers.first : nil

      AuthorizationStatus.new(status_code, authorization_handler, all_data.first)
    end

    private

    attr_reader :user, :component, :resource, :action

    def get_authorization(handler_name)
      return nil unless user && handler_name

      Verifications::Authorizations.new(organization: user.organization, user: user, name: handler_name).first
    end

    # def authorization_handler
    #   return unless authorization_handler_name
    #   @authorization_handler ||= Verifications::Adapter.from_element(authorization_handler_name)
    # end

    def authorization_handlers
      permission&.fetch("authorization_handlers", {})
    end

    # def authorization_handler_name
    #   handler_names = permission&.fetch("authorization_handler_name", [])
    #   handler_names.first if handler_names && handler_names.is_a?(Array) && handler_names.any?
    # end

    # def permission_options
    #   permission&.fetch("options", {})
    # end

    def permission
      return nil unless component && action
      @permission ||= resource&.permissions&.fetch(action, nil) || component.permissions&.fetch(action, nil)
    end

    class AuthorizationStatus
      attr_reader :code, :data

      def initialize(code, authorization_handler, data)
        @code = code.to_sym
        @authorization_handler = authorization_handler
        @data = data.symbolize_keys
      end

      def current_path(redirect_url: nil)
        return unless @authorization_handler

        if pending?
          @authorization_handler.resume_authorization_path(redirect_url: redirect_url)
        else
          @authorization_handler.root_path(redirect_url: redirect_url)
        end
      end

      def handler_name
        return unless @authorization_handler

        @authorization_handler.key
      end

      def ok?
        @code == :ok
      end

      def pending?
        @code == :pending
      end
    end

    class AuthorizationError < StandardError; end
  end
end
