# frozen_string_literal: true

module Decidim
  module Proposals
    # The data store for a Proposal in the Decidim::Proposals component.
    class Proposal < Proposals::ApplicationRecord
      include Decidim::Resourceable
      include Decidim::Coauthorable
      include Decidim::HasComponent
      include Decidim::ScopableComponent
      include Decidim::HasReference
      include Decidim::HasCategory
      include Decidim::Reportable
      include Decidim::HasAttachments
      include Decidim::Followable
      include Decidim::Proposals::CommentableProposal
      include Decidim::Searchable
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::Fingerprintable
      include Decidim::DataPortability
      include Decidim::Hashtaggable
      include Decidim::Proposals::ParticipatoryTextSection
      include Decidim::Amendable
      include Decidim::NewsletterParticipant
      include Decidim::Randomable

      fingerprint fields: [:title, :body]

      amendable(
        fields: [:title, :body],
        form: "Decidim::Proposals::ProposalForm"
      )

      component_manifest_name "proposals"

      has_many :endorsements, foreign_key: "decidim_proposal_id", class_name: "ProposalEndorsement", dependent: :destroy, counter_cache: "proposal_endorsements_count"

      has_many :votes,
               -> { final },
               foreign_key: "decidim_proposal_id",
               class_name: "Decidim::Proposals::ProposalVote",
               dependent: :destroy,
               counter_cache: "proposal_votes_count"

      has_many :notes, foreign_key: "decidim_proposal_id", class_name: "ProposalNote", dependent: :destroy, counter_cache: "proposal_notes_count"

      validates :title, :body, presence: true

      geocoded_by :address, http_headers: ->(proposal) { { "Referer" => proposal.component.organization.host } }

      scope :accepted, -> { where(state: "accepted") }
      scope :rejected, -> { where(state: "rejected") }
      scope :evaluating, -> { where(state: "evaluating") }
      scope :withdrawn, -> { where(state: "withdrawn") }
      scope :except_rejected, -> { where.not(state: "rejected").or(where(state: nil)) }
      scope :except_withdrawn, -> { where.not(state: "withdrawn").or(where(state: nil)) }
      scope :drafts, -> { where(published_at: nil) }
      scope :published, -> { where.not(published_at: nil) }

      acts_as_list scope: :decidim_component_id

      searchable_fields({
                          scope_id: :decidim_scope_id,
                          participatory_space: { component: :participatory_space },
                          D: :search_body,
                          A: :search_title,
                          datetime: :published_at
                        },
                        index_on_create: ->(proposal) { proposal.official? },
                        index_on_update: ->(proposal) { proposal.visible? })

      def self.log_presenter_class_for(_log)
        Decidim::Proposals::AdminLog::ProposalPresenter
      end

      # Returns a collection scoped by an author.
      # Overrides this method in DataPortability to support Coauthorable.
      def self.user_collection(author)
        return unless author.is_a?(Decidim::User)

        joins(:coauthorships)
          .where("decidim_coauthorships.coauthorable_type = ?", name)
          .where("decidim_coauthorships.decidim_author_id = ? AND decidim_coauthorships.decidim_author_type = ? ", author.id, author.class.base_class.name)
      end

      def self.retrieve_proposals_for(component)
        Decidim::Proposals::Proposal.where(component: component).joins(:coauthorships)
                                    .includes(:votes, :endorsements)
                                    .where(decidim_coauthorships: { decidim_author_type: "Decidim::UserBaseEntity" })
                                    .not_hidden
                                    .published
                                    .except_withdrawn
      end

      def self.newsletter_participant_ids(component)
        proposals = retrieve_proposals_for(component).uniq

        coauthors_recipients_ids = proposals.map { |p| p.notifiable_identities.pluck(:id) }.flatten.compact.uniq

        participants_has_voted_ids = Decidim::Proposals::ProposalVote.joins(:proposal).where(proposal: proposals).joins(:author).map(&:decidim_author_id).flatten.compact.uniq

        endorsements_participants_ids = Decidim::Proposals::ProposalEndorsement.joins(:proposal)
                                                                               .where(proposal: proposals)
                                                                               .where(decidim_author_type: "Decidim::UserBaseEntity")
                                                                               .map(&:decidim_author_id).flatten.compact.uniq

        (endorsements_participants_ids + participants_has_voted_ids + coauthors_recipients_ids).flatten.compact.uniq
      end

      # Public: Updates the vote count of this proposal.
      #
      # Returns nothing.
      # rubocop:disable Rails/SkipsModelValidations
      def update_votes_count
        update_columns(proposal_votes_count: votes.count)
      end
      # rubocop:enable Rails/SkipsModelValidations

      # Public: Check if the user has voted the proposal.
      #
      # Returns Boolean.
      def voted_by?(user)
        ProposalVote.where(proposal: self, author: user).any?
      end

      # Public: Check if the user has endorsed the proposal.
      # - user_group: may be nil if user is not representing any user_group.
      #
      # Returns Boolean.
      def endorsed_by?(user, user_group = nil)
        endorsements.where(author: user, user_group: user_group).any?
      end

      # Public: Checks if the proposal has been published or not.
      #
      # Returns Boolean.
      def published?
        published_at.present?
      end

      # Public: Checks if the organization has given an answer for the proposal.
      #
      # Returns Boolean.
      def answered?
        answered_at.present? && state.present?
      end

      # Public: Checks if the organization has accepted a proposal.
      #
      # Returns Boolean.
      def accepted?
        answered? && state == "accepted"
      end

      # Public: Checks if the organization has rejected a proposal.
      #
      # Returns Boolean.
      def rejected?
        answered? && state == "rejected"
      end

      # Public: Checks if the organization has marked the proposal as evaluating it.
      #
      # Returns Boolean.
      def evaluating?
        answered? && state == "evaluating"
      end

      # Public: Checks if the author has withdrawn the proposal.
      #
      # Returns Boolean.
      def withdrawn?
        state == "withdrawn"
      end

      # Public: Overrides the `reported_content_url` Reportable concern method.
      def reported_content_url
        ResourceLocatorPresenter.new(self).url
      end

      # Public: Whether the proposal is official or not.
      def official?
        authors.first.is_a?(Decidim::Organization)
      end

      # Public: Whether the proposal is created in a meeting or not.
      def official_meeting?
        authors.first.class.name == "Decidim::Meetings::Meeting"
      end

      # Public: The maximum amount of votes allowed for this proposal.
      #
      # Returns an Integer with the maximum amount of votes, nil otherwise.
      def maximum_votes
        maximum_votes = component.settings.threshold_per_proposal
        return nil if maximum_votes.zero?

        maximum_votes
      end

      # Public: The maximum amount of votes allowed for this proposal. 0 means infinite.
      #
      # Returns true if reached, false otherwise.
      def maximum_votes_reached?
        return false unless maximum_votes

        votes.count >= maximum_votes
      end

      # Public: Can accumulate more votres than maximum for this proposal.
      #
      # Returns true if can accumulate, false otherwise
      def can_accumulate_supports_beyond_threshold
        component.settings.can_accumulate_supports_beyond_threshold
      end

      # Checks whether the user can edit the given proposal.
      #
      # user - the user to check for authorship
      def editable_by?(user)
        return true if draft?

        !answered? && within_edit_time_limit? && !copied_from_other_component? && created_by?(user)
      end

      # Checks whether the user can withdraw the given proposal.
      #
      # user - the user to check for withdrawability.
      def withdrawable_by?(user)
        user && !withdrawn? && authored_by?(user) && !copied_from_other_component?
      end

      # Public: Whether the proposal is a draft or not.
      def draft?
        published_at.nil?
      end

      # method for sort_link by number of comments
      ransacker :commentable_comments_count do
        query = <<-SQL
        (SELECT COUNT(decidim_comments_comments.id)
         FROM decidim_comments_comments
         WHERE decidim_comments_comments.decidim_commentable_id = decidim_proposals_proposals.id
         AND decidim_comments_comments.decidim_commentable_type = 'Decidim::Proposals::Proposal'
         GROUP BY decidim_comments_comments.decidim_commentable_id
         )
        SQL
        Arel.sql(query)
      end

      def self.export_serializer
        Decidim::Proposals::ProposalSerializer
      end

      def self.data_portability_images(user)
        user_collection(user).map { |p| p.attachments.collect(&:file) }
      end

      # Public: Overrides the `allow_resource_permissions?` Resourceable concern method.
      def allow_resource_permissions?
        component.settings.resources_permissions_enabled
      end

      # Checks whether the proposal is inside the time window to be editable or not once published.
      def within_edit_time_limit?
        return true if draft?

        limit = updated_at + component.settings.proposal_edit_before_minutes.minutes
        Time.current < limit
      end

      private

      def copied_from_other_component?
        linked_resources(:proposals, "copied_from_component").any?
      end
    end
  end
end
