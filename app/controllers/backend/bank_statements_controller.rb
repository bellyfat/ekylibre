# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class BankStatementsController < Backend::BaseController
    manage_restfully(
      started_on: 'Cash.find(params[:cash_id]).last_bank_statement.stopped_on + 1 rescue (Time.zone.today-1.month-2.days)'.c,
      stopped_on: 'Cash.find(params[:cash_id]).last_bank_statement.stopped_on >> 1 rescue (Time.zone.today-2.days)'.c,
      redirect_to: "{controller: '/backend/bank_reconciliation/items', action: :index, bank_statement_id: 'id'.c}".c
    )

    unroll

    list(order: { started_on: :desc }) do |t|
      t.action :index, url: { controller: '/backend/bank_reconciliation/items' }
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :cash,   url: true
      t.column :started_on
      t.column :stopped_on
      t.column :debit,  currency: true
      t.column :credit, currency: true
    end

    # Displays the main page with the list of bank statements
    def index
      redirect_to backend_cashes_path
    end

    list(:items, model: :bank_statement_items, conditions: { bank_statement_id: 'params[:id]'.c }, order: :id) do |t|
      t.column :transfered_on
      t.column :name
      t.column :memo
      t.column :transaction_nature, label_method: "transaction_nature&.t(scope: 'interbank_transaction_codes')"
      t.column :letter
      t.column :journal_entry, url: true
      t.column :debit, currency: :currency
      t.column :credit, currency: :currency
    end

    def import_ofx
      @cash = Cash.find_by(id: params[:cash_id])
      if request.get?
        render :import
      elsif request.post?
        file = params[:upload]
        @import = OfxImport.new(file, @cash)
        if @import.run
          redirect_to action: :show, id: @import.bank_statement.id
        elsif @import.recoverable?
          @cash = @import.cash
          @bank_statement = @import.bank_statement
          @bank_statement.errors.add(:cash, :no_cash_match_ofx) unless @cash.valid?
          render :new
        end
      else
        head 404
      end
    end

    def import_cfonb
      if request.get?
        render :import
      elsif request.post?
        importer = Accountancy::Cfonb::Importer.build
        file = params[:upload]
        result = importer.import_bank_statement(Pathname.new(file.path))

        if result.success?
          @bank_statement = result.value

          redirect_to action: :show, id: @bank_statement.id
        else
          # recoverable? si validation error
          @error = result.error
          if @error.is_a?(Accountancy::Cfonb::Importer::ModelValidationError)
            @bank_statement = @error.bank_statement
            @cash = @bank_statement.cash
            render :new
          else
            error_message = @error.is_a?(Accountancy::Cfonb::Importer::ImporterError) ? @error.translated_message : :default_error_message.t(scope: 'errors.messages')
            notify_error_now(error_message)
            render :import
          end
        end
      else
        head 404
      end
    end

    def edit_interval; end
  end
end
