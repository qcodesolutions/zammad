# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Overviews', type: :system do
  let(:group) { create(:group) }

  let(:owner_one) { create(:agent, groups: [group]) }
  let(:owner_two) { create(:agent, groups: [group]) }
  let(:owner_three) { create(:agent, groups: [group]) }

  let(:customer_one) { create(:customer, organization_id: organization_one.id, groups: [group]) }
  let(:customer_two) { create(:customer, organization_id: organization_two.id, groups: [group]) }
  let(:customer_three) { create(:customer, organization_id: organization_three.id, groups: [group]) }

  let(:organization_one) { create(:organization, name: 'Test Org One') }
  let(:organization_two) { create(:organization, name: 'Test Org Two') }
  let(:organization_three) { create(:organization, name: 'Test Org Three') }

  let!(:ticket_one) do
    create(:ticket,
           title:       'Test Ticket One',
           group:       group,
           owner_id:    owner_one.id,
           customer_id: customer_one.id)
  end

  let!(:ticket_two) do
    create(:ticket,
           title:       'Test Ticket Two',
           group:       group,
           owner_id:    owner_two.id,
           customer_id: customer_two.id)
  end

  let!(:ticket_three) do
    create(:ticket,
           title:       'Test Ticket Three',
           group:       group,
           owner_id:    owner_three.id,
           customer_id: customer_three.id)
  end

  let(:overview) { create(:overview, condition: condition) }

  shared_examples 'previewing the correct ticket for single selected object' do
    context "with 'is' operator" do
      let(:operator) { 'is' }

      it 'shows selected customer ticket' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_selector('tr.item', text: ticket_one.title)
        end
      end

      it 'does not show customer ticket that is not selected' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_no_selector('tr.item', text: ticket_two.title)
          expect(page).to have_no_selector('tr.item', text: ticket_three.title)
        end
      end
    end

    context "with 'is not' operator" do
      let(:operator) { 'is not' }

      it 'does not show selected customer ticket' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_no_selector('tr.item', text: ticket_one.title)
        end
      end

      it 'does not show customer ticket that is not selected' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_selector('tr.item', text: ticket_two.title)
          expect(page).to have_selector('tr.item', text: ticket_three.title)
        end
      end
    end
  end

  shared_examples 'previewing the correct ticket for multiple selected objects' do
    context "with 'is' operator" do
      let(:operator) { 'is' }

      it 'shows selected customer ticket' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_selector('tr.item', text: ticket_one.title)
          expect(page).to have_selector('tr.item', text: ticket_two.title)
        end
      end

      it 'does not show customer ticket that is not selected' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_no_selector('tr.item', text: ticket_three.title)
        end
      end
    end

    context "with 'is not' operator" do
      let(:operator) { 'is not' }

      it 'does not show selected customer ticket' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_no_selector('tr.item', text: ticket_one.title)
          expect(page).to have_no_selector('tr.item', text: ticket_two.title)
        end
      end

      it 'does not show customer ticket that is not selected' do
        within '.js-preview .js-tableBody' do
          expect(page).to have_selector('tr.item', text: ticket_three.title)
        end
      end
    end
  end

  context 'conditions for shown tickets' do
    context 'for customer' do
      context 'for new overview' do
        before do
          visit '/#manage/overviews'
          click_on 'New Overview'

          modal_ready

          within '.ticket_selector' do
            ticket_select = find('.js-attributeSelector select .js-ticket')
            ticket_select.select 'Customer'
            select operator, from: 'condition::ticket.customer_id::operator'
            select 'specific', from: 'condition::ticket.customer_id::pre_condition'
          end
        end

        context 'when single customer is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.customer_id::value_completion',	with: customer_one.firstname

              find("[data-object-id='#{customer_one.id}'].js-object").click
            end
          end

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple customer is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.customer_id::value_completion',	with: customer_one.firstname
              find("[data-object-id='#{customer_one.id}'].js-object").click

              fill_in 'condition::ticket.customer_id::value_completion',	with: customer_two.firstname
              find("[data-object-id='#{customer_two.id}'].js-object").click
            end
          end

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end

      context 'for existing overview' do
        let(:condition) do
          { 'ticket.customer_id' => {
            operator:      operator,
            pre_condition: 'specific',
            value:         condition_value
          } }
        end

        before do
          overview

          visit '/#manage/overviews'

          within '.table-overview .js-tableBody' do
            find("tr[data-id='#{overview.id}']   td.table-draggable").click
          end

          within '.ticket_selector' do
            # trigger the preview
            fill_in 'condition::ticket.customer_id::value_completion',	with: customer_one.firstname
          end
        end

        context 'when single customer exists' do
          let(:condition_value) { customer_one.id }

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple customer exists' do
          let(:condition_value) { [customer_one.id, customer_two.id] }

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end
    end

    context 'for owner' do
      context 'for new overview' do
        before do
          visit '/#manage/overviews'
          click_on 'New Overview'

          modal_ready

          within '.ticket_selector' do
            ticket_select = find('.js-attributeSelector select .js-ticket')
            ticket_select.select 'Owner'
            select operator, from: 'condition::ticket.owner_id::operator'
            select 'specific', from: 'condition::ticket.owner_id::pre_condition'
          end
        end

        context 'when single owner is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.owner_id::value_completion',	with: owner_one.firstname

              first('.recipientList-entry.js-object').click
            end
          end

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple owner is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.owner_id::value_completion',	with: owner_one.firstname
              find("[data-object-id='#{owner_one.id}'].js-object").click

              fill_in 'condition::ticket.owner_id::value_completion',	with: owner_two.firstname
              find("[data-object-id='#{owner_two.id}'].js-object").click
            end
          end

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end

      context 'for existing overview' do
        let(:condition) do
          { 'ticket.owner_id' => {
            operator:      operator,
            pre_condition: 'specific',
            value:         condition_value
          } }
        end

        before do
          overview

          visit '/#manage/overviews'

          within '.table-overview .js-tableBody' do
            find("tr[data-id='#{overview.id}']   td.table-draggable").click
          end

          within '.ticket_selector' do
            # trigger the preview
            fill_in 'condition::ticket.owner_id::value_completion',	with: owner_one.firstname
          end
        end

        context 'when single owner exists' do
          let(:condition_value) { owner_one.id }

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple owner exists' do
          let(:condition_value) { [owner_one.id, owner_two.id] }

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end
    end

    context 'for organization' do
      # let(:condition) do
      #   { 'ticket.organization_id' => {
      #     operator:      operator,
      #     pre_condition: 'specific',
      #     value:         [101, 102, 103]
      #   } }
      # end

      context 'for new overview' do
        before do
          visit '/#manage/overviews'
          click_on 'New Overview'

          modal_ready

          within '.ticket_selector' do
            ticket_select = find('.js-attributeSelector select .js-ticket')
            ticket_select.select 'Organization'
            select operator, from: 'condition::ticket.organization_id::operator'
            select 'specific', from: 'condition::ticket.organization_id::pre_condition'
          end
        end

        context 'when single organization is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.organization_id::value_completion',	with: organization_one.name

              find(".js-optionsList [data-value='#{organization_one.id}'].js-option").click
            end
          end

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple organization is selected' do
          before do
            within '.ticket_selector' do
              fill_in 'condition::ticket.organization_id::value_completion',	with: organization_one.name
              find(".js-optionsList [data-value='#{organization_one.id}'].js-option").click

              fill_in 'condition::ticket.organization_id::value_completion',	with: organization_two.name
              find(".js-optionsList [data-value='#{organization_two.id}'].js-option").click
            end
          end

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end

      context 'for existing overview' do
        let(:condition) do
          { 'ticket.organization_id' => {
            operator:      operator,
            pre_condition: 'specific',
            value:         condition_value
          } }
        end

        before do
          overview

          visit '/#manage/overviews'

          within '.table-overview .js-tableBody' do
            find("tr[data-id='#{overview.id}']   td.table-draggable").click
          end

          within '.ticket_selector' do
            # trigger the preview
            fill_in 'condition::ticket.organization_id::value_completion',	with: organization_one.name
          end
        end

        context 'when single organization exists' do
          let(:condition_value) { organization_one.id }

          it_behaves_like 'previewing the correct ticket for single selected object'
        end

        context 'when multiple organization exists' do
          let(:condition_value) { [organization_one.id, organization_two.id] }

          it_behaves_like 'previewing the correct ticket for multiple selected objects'
        end
      end
    end
  end
end
