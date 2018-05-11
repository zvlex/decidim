# frozen_string_literal: true

module Decidim
  # The controller to handle the user's public profile page.
  class ProfilesController < Decidim::ApplicationController
    helper Decidim::Messaging::ConversationHelper
    helper Decidim::PaginateHelper
    helper Decidim::IconHelper
    include Paginable

    helper_method :user, :active_content

    def show
      @collection = []
      @collection = send(active_content) if respond_to?(active_content, true)
    end

    private

    def user
      @user ||= Decidim::User.find_by!(
        nickname: params[:nickname],
        organization: current_organization
      )
    end

    def notifications
      @notifications ||= paginate current_user.notifications.order(created_at: :desc)
    end

    def following
      @following ||= Kaminari.paginate_array(following_users).page(params[:page]).per(per_page)
    end

    def following_users
      @following_users ||= user.following.select do |following|
        following.is_a?(Decidim::User)
      end
    end

    def followers
      @followers ||= paginate user.followers
    end

    def per_page
      50
    end

    def active_content
      return "following" if current_user != user && (params[:active] == "notifications" || params[:active].blank?)
      params[:active].presence || "notifications"
    end
  end
end
