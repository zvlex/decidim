# frozen_string_literal: true

require "spec_helper"

module Decidim::Exporters
  describe ParticipatorySpaceComponentsSerializer do
    describe "#serialize" do
      subject do
        described_class.new(participatory_space)
      end

      let!(:component_1) { create(:component, name: :one) }
      let!(:participatory_space) { component_1.participatory_space }
      let!(:component_2) { create(:component, name: :two, participatory_space: participatory_space) }
      let(:components) do
        { component_1.id => component_1, component_2.id => component_2 }
      end

      before do
        component_2.manifest.serializes_specific_data = true
        component_2.class.class_eval do
          def serialize_specific_data
            { specific: :data }
          end
        end
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "serializes space components" do
          expect(serialized.size).to eq(2)
          serialized.each do |serialized|
            serialized_component_attrs_should_be_as_expected(serialized)
            expect(serialized[:specific_data]).to eq(specific: :data) if serialized[:id] == component_2.id
          end
        end

        def serialized_component_attrs_should_be_as_expected(serialized)
          component = components[serialized[:id]]
          expect(serialized[:component_class]).to eq(component.class.name)
          expect(serialized[:manifest_name]).to eq(component.manifest_name)
          expect(serialized[:name]).to eq(component.name)
          expect(serialized[:participatory_space_id]).to eq(component.participatory_space_id)
          expect(serialized[:participatory_space_type]).to eq(component.participatory_space_type)
          expect(serialized[:settings]).to eq(component.settings.to_json)
          expect(serialized[:weight]).to eq(component.weight)
          expect(serialized[:permissions]).to eq(component.permissions)
        end
      end
    end
  end
end
