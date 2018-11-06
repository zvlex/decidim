# frozen_string_literal: true

module Decidim
  module Conferences
    # A presenter to render statistics in the homepage.
    class ConferenceStatsPresenter < Rectify::Presenter
      attribute :conference, Decidim::Conference
      include IconHelper

      # Public: Render a collection of primary stats.
      def conference_highlighted


        # highlighted_stats = Decidim.stats.only([:users_count, :processes_count]).with_context(organization).map { |name, data| [name, data] }
        # highlighted_stats = highlighted_stats.concat(global_stats(priority: StatsRegistry::HIGH_PRIORITY))
        # highlighted_stats = highlighted_stats.concat(component_stats(priority: StatsRegistry::HIGH_PRIORITY))
        # highlighted_stats = highlighted_stats.reject(&:empty?)
        # highlighted_stats = highlighted_stats.reject { |_name, data| data.zero? }
  
        highlighted_stats = participatory_space_stats(priority: StatsRegistry::HIGH_PRIORITY)
        highlighted_stats = highlighted_stats.concat(participatory_space_stats(priority: StatsRegistry::MEDIUM_PRIORITY))
        highlighted_stats = highlighted_stats.reject(&:empty?)
        
        # highlighted_stats = highlighted_stats.reject { |_name, data| data.zero? }
        # raise
        # highlighted_stats = highlighted_stats.reject { |_name, data| data.zero? }
        # raise
        # grouped_highlighted_stats = highlighted_stats.group_by { |stats| stats.first.name }
        # raise
        

        # safe_join(
          highlighted_stats.each do |block_stat|
          # raise
            block_stat.each_with_index.map  do |stats, index|
              content_tag :div, class: "process_stats-item" do
                # safe_join(
                  render_stats_data(stats[0], stats[1], stats[2], index).html_safe
                # )
              end
            end
          end
        # )
        # safe_join(
        #   highlighted_stats.each do |block_stat|
        #     safe_join(
        #       block_stat.each_with_index.map do |stat, index|
        #         content_tag :div, class: "process_stats-item" do
        #           render_conference_stats_data(stat[0], stat[1], index)
        #         end
        #       end
        #     )
        #   # end
            
        #     # block_stat.map do |_manifest_name, name, data|
        #     #   raise
        #     #   safe_join(
        #     #     block_stat.each_with_index.map do |stat, index|
        #     #       render_stats_data(, stat[1], index)
        #     #     end
        #     #   )
        #     # end
        #     # raise
            
        #   end
          
        #   # highlighted_stats.map do |_manifest_name, stats|
        #   #   raise
        #   #   content_tag :div, class: "process_stats-item" do
        #   #     safe_join(
        #   #       stats.each_with_index.map do |stat, index|
        #   #         raise
        #   #         render_stats_data(stat[0], stat[1], stat[2], index)
        #   #       end
        #   #     )
        #   #   end
        #   # end
        # )
      end
      
      def highlighted
        highlighted_stats = component_stats(priority: StatsRegistry::HIGH_PRIORITY)
        highlighted_stats = highlighted_stats.concat(component_stats(priority: StatsRegistry::MEDIUM_PRIORITY))
        highlighted_stats = highlighted_stats.reject(&:empty?)
        highlighted_stats = highlighted_stats.reject { |_manifest, _name, data| data.zero? }
        grouped_highlighted_stats = highlighted_stats.group_by { |stats| stats.first.name }

        safe_join(
          grouped_highlighted_stats.map do |_manifest_name, stats|
            content_tag :div, class: "process_stats-item" do
              safe_join(
                stats.each_with_index.map do |stat, index|
                  render_stats_data(stat[0], stat[1], stat[2], index)
                end
              )
            end
          end
        )
      end

      private

      def participatory_space_stats(conditions)
        Decidim.participatory_space_manifests.map do |participatory_space_manifest|
          participatory_space_manifest.stats.filter(conditions).with_context(conference).map { |name, data| [participatory_space_manifest, name, data] }
        end
      end

      def component_stats(conditions)
        Decidim.component_manifests.map do |component_manifest|
          component_manifest.stats.filter(conditions).with_context(published_components).map { |name, data| [component_manifest, name, data] }.flatten
        end
      end

      def render_stats_data(component_manifest, name, data, index)
        safe_join([
                    index.zero? ? manifest_icon(component_manifest) : " /&nbsp".html_safe,
                    content_tag(:span, "#{number_with_delimiter(data)} " + I18n.t(name, scope: "decidim.conferences.statistics"),
                                class: "#{name} process_stats-text")
                  ])
      end

      def render_conference_stats_data(name, data, index)
        safe_join([
                    # index.zero? ? manifest_icon(component_manifest) : " /&nbsp".html_safe,
                    content_tag(:span, "#{number_with_delimiter(data)} " + I18n.t(name.to_s, scope: "decidim.conferences.statistics"),
                                class: "#{name.to_s} process_stats-text")
                  ])
      end

      def published_components
        @published_components ||= Component.where(participatory_space: conference).published
      end
    end
  end
end
