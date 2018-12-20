# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Admin
    describe PermissionForm do
      let(:organization) { create :organization }
      let(:handler_name) { "dummy_authorization_handler" }
      let(:attributes) do
        {
          "authorization_handler_name" => handler_name,
          "options" => { "option_key" => "option_value" }
        }
      end
      let(:context) do
        { current_organization: organization }
      end
      let(:permission_form) { described_class.from_params(attributes).with_context(context) }

      context "when everything is OK" do
        subject { permission_form }

        it { is_expected.to be_valid }
      end

      describe "#manifest" do
        subject { permission_form.manifest }

        context "when there's an associated workflow" do
          it "returns the associated manifest" do
            expect(subject).to be_an_instance_of(Decidim::Verifications::WorkflowManifest)
          end
        end

        context "when the workflow can't be found" do
          let(:handler_name) { "missing_authorization_handler" }

          it { is_expected.to be_nil }
        end
      end

      describe "#options_schema" do
        subject { permission_form.options_schema }

        it "responds to manifest" do
          expect(subject).to respond_to(:manifest)
        end
      end

      describe "#options_attributes" do
        subject { permission_form.options_attributes }

        it "returns a hash with Decidim::SettingsManifest::Attribute values" do
          expect(subject).to be_an_instance_of(Hash)
          expect(subject.keys).to eq([:postal_code])
          expect(subject.values.first).to be_an_instance_of(Decidim::SettingsManifest::Attribute)
        end
      end

    end
  end
end
