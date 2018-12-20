# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Admin
    describe PermissionsForm do
      let(:organization) { create :organization }
      let(:permission_form) do
        PermissionForm.from_params(
          "authorization_handler_name" => "dummy_authorization_handler",
          "options" => { "option_key" => "option_value" }
        ).with_context(context)
      end
      let(:attributes) do
        { "permissions" => { "dummy" => permission_form } }
      end
      let(:context) do
        { current_organization: organization }
      end
      let(:permissions_form) { described_class.from_params(attributes).with_context(context) }

      context "when everything is OK" do
        subject { permissions_form }

        it { is_expected.to be_valid }
      end

      describe "#permissions" do
        subject { permissions_form.permissions }

        it "returns a mapping of action_name => PermissionForm" do
          expect(subject).to be_an_instance_of(Hash)
          expect(subject.keys.first).to eq("dummy")
          expect(subject.values.first).to eq(permission_form)
        end
      end

      describe "#valid?" do
        subject { permissions_form }

        context "when all permissions are valid" do
          it { is_expected.to be_valid }
        end

        context "when any permission is not valid" do
          before do
            allow(permissions_form).to receive(:valid?).and_return(false)
          end

          it { is_expected.to be_invalid }
        end
      end

    end
  end
end
