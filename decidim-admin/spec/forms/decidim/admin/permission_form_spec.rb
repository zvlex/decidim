# frozen_string_literal: true

require "spec_helper"

# TODO: algunas de estas specs son más para entender que reciben/devuelven algunos métodos
# y ver que no rompo las llamadas. De cara a crear la PR igual algunas que pierden la utilidad.

module Decidim
  module Admin
    describe PermissionForm do
      let(:organization) { create :organization }
      let(:handler_without_options_name) { "postal_letter" }
      let(:handler_with_options_name) { "dummy_authorization_handler" }
      let(:attributes) do
        {
          "authorization_handlers": {
            handler_without_options_name => {},
            handler_with_options_name => {
              "options": {
                "option_key": "option_value"
              }
            }
          }
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
        subject { permission_form.manifest(handler_with_options_name) }

        context "when there's an associated workflow" do
          it "returns the associated manifest" do
            expect(subject).to be_an_instance_of(Decidim::Verifications::WorkflowManifest)
          end
        end

        context "when the workflow can't be found" do
          let(:handler_with_options_name) { "missing_authorization_handler" }

          it { is_expected.to be_nil }
        end
      end

      describe "#options_schema" do
        subject { permission_form.options_schema(handler_with_options_name) }

        it "responds to manifest" do
          expect(subject).to respond_to(:manifest)
        end
      end

      describe "#options_attributes" do
        subject { permission_form.options_attributes(handler_with_options_name) }

        it "returns a hash with Decidim::SettingsManifest::Attribute values" do
          expect(subject).to be_an_instance_of(Hash)
          expect(subject.keys).to eq([:postal_code])
          expect(subject.values.first).to be_an_instance_of(Decidim::SettingsManifest::Attribute)
        end
      end

    end
  end
end
