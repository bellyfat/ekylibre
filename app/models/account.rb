# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: accounts
#
#  already_existing          :boolean          default(FALSE), not null
#  auxiliary_number          :string
#  centralizing_account_name :string
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  debtor                    :boolean          default(FALSE), not null
#  description               :text
#  id                        :integer          not null, primary key
#  label                     :string           not null
#  last_letter               :string
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  nature                    :string
#  number                    :string           not null
#  reconcilable              :boolean          default(FALSE), not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  usages                    :text
#

class Account < Ekylibre::Record::Base
  include Customizable
  @@references = []
  # has_many :account_balances
  # has_many :attorneys, class_name: "Entity", foreign_key: :attorney_account_id
  has_many :balances, class_name: 'AccountBalance', dependent: :destroy
  has_many :cashes, dependent: :restrict_with_exception, foreign_key: :main_account_id
  has_many :suspense_cashes, dependent: :restrict_with_exception, foreign_key: :suspense_account_id, class_name: 'Cash'
  has_many :clients,             class_name: 'Entity', foreign_key: :client_account_id
  has_many :collected_taxes,     class_name: 'Tax', foreign_key: :collect_account_id
  has_many :commissioned_incoming_payment_modes, class_name: 'IncomingPaymentMode',
                                                 foreign_key: :commission_account_id
  has_many :depositables_incoming_payment_modes, class_name: 'IncomingPaymentMode',
                                                 foreign_key: :depositables_account_id
  has_many :journal_entries, through: :journal_entry_items, source: :entry
  has_many :journal_entry_items,          class_name: 'JournalEntryItem', dependent: :restrict_with_exception
  has_many :paid_taxes,                   class_name: 'Tax', foreign_key: :deduction_account_id
  has_many :collected_fixed_asset_taxes,  class_name: 'Tax', foreign_key: :fixed_asset_collect_account_id
  has_many :deductible_fixed_asset_taxes, class_name: 'Tax', foreign_key: :fixed_asset_deduction_account_id
  has_many :charges_categories,           class_name: 'ProductNatureCategory', foreign_key: :charge_account_id
  has_many :purchase_items,               class_name: 'PurchaseItem', dependent: :restrict_with_exception
  has_many :sale_items,                   class_name: 'SaleItem'
  has_many :payslip_natures, dependent: :restrict_with_exception
  has_many :payslips, dependent: :restrict_with_exception
  has_many :products_categories,          class_name: 'ProductNatureCategory', foreign_key: :product_account_id
  has_many :stocks_categories,            class_name: 'ProductNatureCategory', foreign_key: :stock_account_id
  has_many :stocks_movement_categories,   class_name: 'ProductNatureCategory', foreign_key: :stock_movement_account_id
  has_many :suppliers,                    class_name: 'Entity', foreign_key: :supplier_account_id
  has_many :employees,                    class_name: 'Entity', foreign_key: :employee_account_id
  has_many :stocks_variants,              class_name: 'ProductNatureVariant', foreign_key: :stock_account_id
  has_many :stocks_movement_variants,     class_name: 'ProductNatureVariant', foreign_key: :stock_movement_account_id
  has_many :loans,                        class_name: 'Loan', foreign_key: :loan_account_id
  has_many :loans_as_interest,            class_name: 'Loan', foreign_key: :interest_account_id
  has_many :loans_as_insurance,           class_name: 'Loan', foreign_key: :insurance_account_id
  has_many :bank_guarantees_loans,        class_name: 'Loan', foreign_key: :bank_guarantee_account_id

  refers_to :centralizing_account, -> { where(centralizing: true) }, class_name: 'Account'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :already_existing, :debtor, :reconcilable, inclusion: { in: [true, false] }
  validates :auxiliary_number, :last_letter, length: { maximum: 500 }, allow_blank: true
  validates :description, :usages, length: { maximum: 500_000 }, allow_blank: true
  validates :label, :name, :number, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :last_letter, length: { allow_nil: true, maximum: 10 }
  validates :name, length: { allow_nil: true, maximum: 500 }
  validates :number, uniqueness: true
  validates :number, length: { minimum: 4 }, if: :auxiliary?
  validates :number, format: { with: /\A\d(\d(\d[0-9A-Z]*)?)?\z/ }
  validates :auxiliary_number, presence: true, format: { without: /\A(0*)\z/ }, if: :auxiliary?
  validates :centralizing_account_name, presence: true, if: :auxiliary?

  enumerize :nature, in: %i[general auxiliary], default: :general, predicates: true

  # default_scope order(:number, :name)
  scope :of_usage, lambda { |usage|
    unless Nomen::Account.find(usage)
      raise ArgumentError, "Unknown usage #{usage.inspect}"
    end
    where('usages ~ E?', "\\\\m#{usage}\\\\M")
  }
  # return Account which contains usages mentionned (OR)
  scope :of_usages, lambda { |*usages|
    where('usages ~ E?', usages.sort.map { |usage| "\\\\m#{usage.to_s.gsub(/\W/, '')}\\\\M" }.join('.*|')).reorder(:number)
  }

  scope :used_between, lambda { |started_at, stopped_at|
    # where("id IN (SELECT account_id FROM #{JournalEntryItem.table_name} WHERE printed_on BETWEEN ? AND ? )", started_at, stopped_at)
    where(id: JournalEntryItem.between(started_at, stopped_at).select(:account_id))
  }

  scope :clients,   -> { of_usages(:clients, :social_agricultural_mutuality, :usual_associates_current_accounts) }
  scope :suppliers, -> { of_usages(:suppliers, :social_agricultural_mutuality, :usual_associates_current_accounts) }
  scope :employees, -> { of_usages(:staff_due_remunerations) }
  scope :attorneys, -> { of_usage(:attorneys) }
  scope :banks, -> { of_usage(:banks) }
  scope :cashes, -> { of_usage(:cashes) }
  scope :loans, -> { of_usage(:loans) }
  scope :interests, -> { of_usages(:campaigns_interests, :long_term_loans_interests, :short_term_loans_interests) }
  scope :insurances, -> { of_usages(:equipment_maintenance_expenses, :exploitation_risk_insurance_expenses, :infirmity_and_death_insurance_expenses, :insurance_expenses) }
  scope :payment_guarantees, -> { of_usage(:payment_guarantees) }
  scope :banks_or_cashes, -> { of_usages(:cashes, :banks) }
  scope :banks_or_cashes_or_associates, -> { of_usages(:cashes, :banks, :principal_associates_current_accounts, :associates_current_accounts, :usual_associates_current_accounts, :associates_frozen_accounts) } # , :owner_account doesn't exist
  scope :thirds, -> { of_usages(:suppliers, :clients, :social_agricultural_mutuality, :usual_associates_current_accounts, :attorneys, :compensation_operations) }

  scope :assets, -> {
    of_usages(:fixed_assets, :adult_animal_assets, :brands_and_patents_assets, :building_assets, :concession_assets,
              :construction_on_other_land_parcel_assets, :construction_on_own_land_parcel_assets, :cooperative_participation_assets,
              :corporeal_assets, :equipment_assets, :equipment_cooperative_participation_assets, :establishment_charge_assets,
              :general_installation_assets, :global_land_parcel_assets, :incorporeal_assets, :industrial_cooperative_participation_assets,
              :installation_sustainable_plant_assets, :land_parcel_assets, :land_parcel_construction_assets, :living_corporeal_assets,
              :office_equipment_assets, :other_corporeal_assets, :other_general_installation_assets, :other_incorporeal_assets,
              :other_professional_agricultural_participation_assets, :outstanding_adult_animal_assets, :outstanding_assets,
              :outstanding_construction_on_other_land_parcel_assets, :outstanding_construction_on_own_land_parcel_assets,
              :outstanding_corporeal_assets, :outstanding_equipment_assets, :outstanding_land_parcel_assets,
              :outstanding_land_parcel_construction_assets, :outstanding_living_corporeal_assets,
              :outstanding_other_general_installation_assets, :outstanding_service_animal_assets,
              :outstanding_sustainables_plants_assets, :outstanding_young_animal_assets, :ownership_assets,
              :professional_agricultural_organization_assets, :redeemable_land_parcel_construction_assets,
              :research_and_development_charge_assets, :service_animal_assets, :sustainable_packaging_assets,
              :sustainables_plants_assets, :sustainables_plants_on_other_land_parcel_assets, :sustainables_plants_on_own_land_parcel_assets,
              :technical_installation_equipment_and_tools_assets, :technical_installation_on_other_land_parcel_assets,
              :technical_installation_on_own_land_parcel_assets, :tools_assets, :transport_vehicle_assets, :young_animal_assets)
  }
  scope :assets_depreciations, lambda {
    of_usages(:incorporeal_asset_depreciations, :other_incorporeal_asset_depreciations, :corporeal_asset_depreciations,
              :land_parcel_asset_depreciations, :land_parcel_construction_asset_depreciations, :own_building_asset_depreciations,
              :other_building_asset_depreciations, :equipment_asset_depreciations, :other_corporeal_asset_depreciations,
              :general_installation_asset_depreciations, :transport_vehicle_asset_depreciations,
              :office_equipment_asset_depreciations, :office_furniture_asset_depreciations,
              :sustainable_packaging_asset_depreciations, :other_asset_depreciations,
              :biocorporeal_asset_depreciations, :adult_animal_asset_depreciations, :young_animal_asset_depreciations, :sustainables_plants_asset_depreciations)
  }

  # scope :asset_depreciations_inputations_expenses, -> { where('number LIKE ?', '68%').order(:number, :name) }
  scope :asset_depreciations_inputations_expenses, -> { of_usages(:incorporeals_depreciations_inputations_expenses, :land_parcel_construction_depreciations_inputations_expenses, :building_depreciations_inputations_expenses, :animals_depreciations_inputations_expenses, :equipments_depreciations_inputations_expenses, :others_corporeals_depreciations_inputations_expenses) }

  scope :stocks_variations, -> {
    of_usages(:fertilizer_stocks_variation, :seed_stocks_variation, :plant_medicine_stocks_variation,
              :livestock_feed_stocks_variation, :animal_medicine_stocks_variation, :animal_reproduction_stocks_variation,
              :merchandising_stocks_variation, :adult_reproductor_animals_inventory_variations, :young_reproductor_animals_inventory_variations,
              :long_cycle_product_inventory_variations, :short_cycle_product_inventory_variations,
              :stocks_variation, :supply_stocks_variation, :other_supply_stocks_variation,
              :long_cycle_vegetals_inventory_variations, :short_cycle_vegetals_inventory_variations,
              :products_inventory_variations,
              :short_cycle_animals_inventory_variations, :long_cycle_animals_inventory_variations)
  }

  scope :collected_vat, -> {
    of_usages(:collected_vat, :enterprise_collected_vat, :collected_intra_eu_vat)
  }

  scope :deductible_vat, -> {
    of_usages(:deductible_vat, :enterprise_deductible_vat, :deductible_intra_eu_vat)
  }

  scope :intracommunity_payable, -> {
    of_usages(:collected_intra_eu_vat)
  }



  scope :general, -> {
    where(nature: 'general')
  }

  scope :auxiliary, -> {
    where(nature: 'auxiliary')
  }

  before_validation do
    if general? && number && !already_existing
      errors.add(:number, :centralizing_number) if number.match(/\A401|\A411/).present?
      errors.add(:number, :radical_class) if number.match(/\A[1-9]0*\z/).present?
      self.number = number.ljust(Preference[:account_number_digits], '0')
    elsif auxiliary? && centralizing_account
      centralizing_account_number = centralizing_account.send(Account.accounting_system)
      self.number = centralizing_account_number + auxiliary_number
    end
  end

  # This method:allows to create the parent accounts if it is necessary.
  before_validation(on: :create) do
    if general?
      self.auxiliary_number = nil
      self.centralizing_account = nil
      errors.add(:number, :incorrect_length, number_length: Preference[:account_number_digits]) if number.length != Preference[:account_number_digits] && !already_existing
      errors.add(:number, :cant_start_with_0) if number.match(/\A0/).present? && !already_existing
    end
    self.reconcilable = reconcilableable? if reconcilable.nil?
    self.label = tc(:label, number: number.to_s, name: name.to_s)
    self.usages = Account.find_parent_usage(number) if usages.blank? && number
  end

  after_validation do
    self.label = tc(:label, number: number.to_s, name: name.to_s)
  end

  def protected_auxiliary_number?
    journal_entry_items.where.not(state: :draft).any?
  end

  protect(on: :destroy) do
    self.class.reflect_on_all_associations(:has_many).any? { |a| send(a.name).any? }
  end

  class << self
    # Create an account with its number (and name)
    def find_or_create_by_number(*args)
      options = args.extract_options!
      number = args.shift.to_s.strip
      options[:name] ||= args.shift
      numbers = Nomen::Account.items.values.collect { |i| i.send(accounting_system) }
      item = Nomen::Account.items.values.detect { |i| i.send(accounting_system) == number }
      number = number.ljust(Preference[:account_number_digits], '0') unless numbers.include?(number) || options[:already_existing]
      account = find_by(number: number)
      if account
        if item && !account.usages_array.include?(item)
          account.usages ||= ''
          account.usages << ' ' + item.name.to_s
          account.save!
        end
      else
        if item
          options[:name] ||= item.human_name
          options[:usages] ||= ''
          options[:usages] << ' ' + item.name.to_s
        end
        options[:name] ||= number.to_s
        merge_attributes = {
          number: number,
          already_existing: (options[:already_existing] || false)
        }
        account = create!(options.merge(merge_attributes))
      end
      account
    end

    # Find account with its usage among all existing account records
    def find_by_usage(usage, except: [], sort_by: [])
      accounts = of_usage(usage)
      accounts = Array(except).reduce(accounts) do |accs, (criterion_or_key, value)|
        key = criterion = criterion_or_key
        next accs.where.not(key => value) if value
        next accs.where.not(id: Account.send(criterion)) if criterion_or_key.is_a? Symbol
        accounts.where.not(id: except)
      end
      accounts = Array(sort_by).reduce(accounts) do |accs, (criterion_or_key, desc_or_asc)|
        key = criterion = criterion_or_key
        next accs.order(key => desc_or_asc) if desc_or_asc
        accs.order(criterion)
      end
      return accounts.first if accounts.any?
      item = Nomen::Account[usage]
      find_by(number: item.send(accounting_system)) if item
    end

    # Find usage in parent account by number
    def find_parent_usage(number)
      number = number.to_s

      parent_accounts = []
      items = []

      max = number.size - 1
      # get usages of nearest existing account by number
      (0..max).to_a.reverse.each do |i|
        n = number[0, i]
        items << Nomen::Account.where(accounting_system.to_sym => n)
        parent_accounts << Account.find_with_regexp(n).where('LENGTH("accounts"."number") <= ?', i).reorder(:number)
        break if parent_accounts.flatten.any?
      end

      usages = if parent_accounts && parent_accounts.flatten.any? && parent_accounts.flatten.first.usages
                 parent_accounts.flatten.first.usages
               elsif items.flatten.any?
                 items.flatten.first.name
               end

      usages
    end

    # Find all account matching with the regexp in a String
    # 123 will take all accounts 123*
    # ^456 will remove all accounts 456*
    def regexp_condition(expr, options = {})
      table = options[:table] || table_name
      normals = ['(XD)']
      excepts = []
      for prefix in expr.strip.split(/[\,\s]+/)
        code = prefix.gsub(/(^(\-|\^)|[CDX]+$)/, '')
        excepts << code if prefix =~ /^\^\d+$/
        normals << code if prefix =~ /^\-?\d+[CDX]?$/
      end
      conditions = ''
      if normals.any?
        conditions << '(' + normals.sort.collect do |c|
          "#{table}.number LIKE '#{c}%'"
        end.join(' OR ') + ')'
      end
      if excepts.any?
        conditions << ' AND NOT (' + excepts.sort.collect do |c|
          "#{table}.number LIKE '#{c}%'"
        end.join(' OR ') + ')'
      end
      conditions
    end
    alias find_with_regexp regexp_condition

    # Find all account matching with the regexp in a String
    # 123 will take all accounts 123*
    # ^456 will remove all accounts 456*
    def find_with_regexp(expr)
      where(regexp_condition(expr))
    end

    def number_unique?(number)
      Account.where(number: number).count == 0
    end

    def valid_item?(item)
      item_number = item.send(accounting_system)
      return false unless item_number != 'NONE' && number_unique?(item_number.ljust(Preference[:account_number_digits], '0'))
      Nomen::Account.find_each do |compared_account|
        compared_account_number = compared_account.send(accounting_system)
        return false if item_number == compared_account_number.sub(/0*$/, '') && item_number != compared_account_number
      end
      true
    end

    # Find or create an account with its name in accounting system if not exist in DB
    def find_or_import_from_nomenclature(usage, create_if_nonexistent: true)
      item = Nomen::Account.find(usage)
      raise ArgumentError, "The usage #{usage.inspect} is unknown" unless item
      raise ArgumentError, "The usage #{usage.inspect} is not implemented in #{accounting_system.inspect}" unless item.send(accounting_system)
      account = find_by_usage(usage, except: { nature: :auxiliary })
      unless account
        return unless valid_item?(item) && item.send(accounting_system).match(/\A[1-9]0*\z|\A0/).nil?
        account = new(
          name: item.human_name,
          number: item.send(accounting_system),
          debtor: !!item.debtor,
          usages: item.name,
          nature: 'general'
        )
        account.save! if create_if_nonexistent
      end
      account
    end
    alias import_from_nomenclature find_or_import_from_nomenclature

    def generate_auxiliary_account_number(usage)
      item = Nomen::Account.select { |a| a.name == usage.to_s && a.centralizing }.first
      raise ArgumentError, "The usage #{usage.inspect} is unknown" unless item
      raise ArgumentError, "The usage #{usage.inspect} is not implemented in #{accounting_system.inspect}" unless item.send(accounting_system)
      centralizing_number = item.send(accounting_system)
      auxiliary_number = '1'
      until Account.find_by('number LIKE ?', centralizing_number + auxiliary_number).nil?
        auxiliary_number.succ!
      end
      auxiliary_number
    end

    # Returns the name of the used accounting system
    # It takes the information in preferences
    def accounting_system
      @tenant_when_last_cached ||= Ekylibre::Tenant.current
      invalid_cache = @tenant_when_last_cached && @tenant_when_last_cached != Ekylibre::Tenant.current
      @accounting_system = nil if invalid_cache
      @accounting_system ||= Preference[:accounting_system]
    end

    # FIXME: This is an aberration of internationalization.
    def french_accounting_system?
      %w[fr_pcg82 fr_pcga].include?(accounting_system)
    end

    # Returns the name of the used accounting system
    # It takes the information in preferences
    def accounting_system=(name)
      unless item = Nomen::AccountingSystem[name]
        raise ArgumentError, "The accounting system #{name.inspect} is unknown."
      end
      Preference.set!(:accounting_system, item.name)
      @accounting_system = item.name
    end

    # Returns the human name of the accounting system
    def accounting_system_name(name = nil)
      Nomen::AccountingSystem[name || accounting_system].human_name
    end

    # Find.all available accounting systems in all languages
    def accounting_systems
      Nomen::AccountingSystem.all
    end

    # Load a accounting system
    def load_defaults(**_options)
      transaction do
        # Destroy unused existing accounts
        find_each do |account|
          account.destroy if account.destroyable?
        end
        Nomen::Account.find_each do |item|
          # Load except radical and centralizing accounts
          if item.send(accounting_system).match(/\A[1-9]0*\z|\A0/).nil? && !item.centralizing
            find_or_import_from_nomenclature(item.name)
          end
        end
      end
      true
    end

    # Clean ranges of accounts
    # Example : 1-3 41 43
    def clean_range_condition(range, _table_name = nil)
      expression = ''
      if range.present?
        valid_expr = /^\d(\d(\d[0-9A-Z]*)?)?$/
        for expr in range.split(/[^0-9A-Z\-\*]+/)
          if expr =~ /\-/
            start, finish = expr.split(/\-+/)[0..1]
            next unless start < finish && start.match(valid_expr) && finish.match(valid_expr)
            expression << " #{start}-#{finish}"
          elsif expr.match(valid_expr)
            expression << " #{expr}"
          end
        end
      end
      expression.strip
    end

    # Build an SQL condition to restrein accounts to some ranges
    # Example : 1-3 41 43
    def range_condition(range, table_name = nil)
      conditions = []
      if range.blank?
        return connection.quoted_true
      else
        range = clean_range_condition(range)
        table = table_name || Account.table_name
        for expr in range.split(/\s+/)
          if expr =~ /\-/
            start, finish = expr.split(/\-+/)[0..1]
            max = [start.length, finish.length].max
            conditions << "SUBSTR(#{table}.number, 1, #{max}) BETWEEN #{connection.quote(start.ljust(max, '0'))} AND #{connection.quote(finish.ljust(max, 'Z'))}"
          else
            conditions << "#{table}.number LIKE #{connection.quote(expr + '%%')}"
          end
        end
      end
      return false if conditions.empty?
      '(' + conditions.join(' OR ') + ')'
    end

    # Returns list of reconcilable prefixes defined in preferences
    def reconcilable_prefixes
      %i[clients suppliers attorneys].collect do |mode|
        Nomen::Account[mode].send(accounting_system).to_s
      end
    end

    # Returns a RegExp based on reconcilable_prefixes
    def reconcilable_regexp
      Regexp.new("^(#{reconcilable_prefixes.join('|')})")
    end
  end

  # Returns list of usages as an array of usage items from the nomenclature
  def usages_array
    usages.to_s.strip.split(/[\,\s]/).collect do |i|
      Nomen::Account[i]
    end.compact
  end

  # Check if the account is a third account and therefore returns if it should be reconcilable
  def reconcilableable?
    (number.to_s.match(self.class.reconcilable_regexp) ? true : false)
  end

  def reconcilable_entry_items(period, started_at, stopped_at)
    relation_name = 'journal_entry_items'
    journal_entry_items
      .where(JournalEntry.period_condition(period, started_at, stopped_at, relation_name))
      .reorder(relation_name + '.printed_on, ' + relation_name + '.real_credit, ' + relation_name + '.real_debit')
  end

  def new_letter
    letter = last_letter
    letter = letter.blank? ? 'A' : letter.succ
    update_column(:last_letter, letter)
    letter
  end

  # Finds entry items to mark, checks their "markability" and
  # if.all valids mark.all with a new letter or the first defined before
  def mark_entries(*journal_entries)
    ids = journal_entries.flatten.compact.collect(&:id)
    mark(journal_entry_items.where(entry_id: ids).map(&:id))
  end

  # Mark entry items with the given +letter+. If no +letter+ given, it uses a new letter.
  # Don't mark unless.all the marked items will be balanced together
  def mark(item_ids, letter = nil)
    conditions = ['id IN (?) AND (letter IS NULL OR LENGTH(TRIM(letter)) <= 0 OR (letter SIMILAR TO ?))', item_ids, '[A-z]*\*?']
    items = journal_entry_items.where(conditions)
    return nil unless item_ids.size > 1 && items.count == item_ids.size &&
                      items.collect { |l| l.debit - l.credit }.sum.to_f.zero?
    letter ||= new_letter
    journal_entry_items.where(conditions).update_all(letter: letter)
    letter
  end

  # Mark entry items with the given +letter+, even when the items are not balanced together.
  # If no +letter+ given, it uses a new letter.
  def mark!(item_ids, letter = nil)
    return nil unless item_ids.is_a?(Array) && item_ids.any?
    letter ||= new_letter
    conditions = ['id IN (?) AND (letter IS NULL OR LENGTH(TRIM(COALESCE(letter, \'\'))) <= 0 OR letter SIMILAR TO \'[A-z]+\\*\')', item_ids]
    journal_entry_items.where(conditions).update_all(letter: letter)
    letter
  end

  # Unmark.all the entry items concerned by the +letter+
  def unmark(letter)
    journal_entry_items.where(letter: letter).update_all(letter: nil)
  end

  # Check if the balance of the entry items of the given +letter+ is zero.
  def balanced_letter?(letter)
    items = journal_entry_items.where('letter = ?', letter.to_s)
    return true if items.count.zero?
    items.sum('debit - credit').to_f.zero?
  end

  # Merge given account into self. Given account is destroyed at the end, self
  # remains.
  def merge_with(other)
    Ekylibre::Record::Base.transaction do
      # Relations with DB approach to prevent missing reflection
      connection = self.class.connection
      base_class = self.class.base_class
      base_model = base_class.name.underscore.to_sym
      models_set = ([base_class] + base_class.descendants)
      models_group = '(' + models_set.map do |model|
        "'#{model.name}'"
      end.join(', ') + ')'
      Ekylibre::Schema.tables.each do |table, columns|
        columns.each do |_name, column|
          next unless column.references
          if column.references.is_a?(String) # Polymorphic
            connection.execute("UPDATE #{table} SET #{column.name}=#{id} WHERE #{column.name}=#{other.id} AND #{column.references} IN #{models_group}")
          elsif column.references == base_model # Straight
            connection.execute("UPDATE #{table} SET #{column.name}=#{id} WHERE #{column.name}=#{other.id}")
          end
        end
      end

      # Update attributes
      self.class.columns_definition.each do |attr, column|
        next if column.references
        send("#{attr}=", other.send(attr)) if send(attr).blank?
      end

      # Update custom fields
      self.custom_fields ||= {}
      other.custom_fields ||= {}
      Entity.custom_fields.each do |custom_field|
        attr = custom_field.column_name
        if self.custom_fields[attr].blank? && other.custom_fields[attr].present?
          self.custom_fields[attr] = other.custom_fields[attr]
        end
      end

      save!
      other.destroy!
    end
  end

  # Compute debit, credit, balance, balance_debit and balance_credit of the account
  # with.all the entry items
  def totals(on = nil, validated = false)
    financial_year = FinancialYear.on(on) if on
    entry_items = journal_entry_items
    entry_items = entry_items.between(financial_year.started_on, financial_year.stopped_on) if financial_year
    entry_items = entry_items.where.not(state: 'draft') if validated

    hash = {}
    hash[:debit]  = entry_items.sum(:debit)
    hash[:credit] = entry_items.sum(:credit)
    hash[:balance_debit] = 0.0
    hash[:balance_credit] = 0.0
    hash[:balance] = (hash[:debit] - hash[:credit]).abs
    hash["balance_#{hash[:debit] > hash[:credit] ? 'debit' : 'credit'}".to_sym] = hash[:balance]
    hash
  end

  # def journal_entry_items_between(started_at, stopped_at)
  #   self.journal_entry_items.joins("JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)").where(printed_on: started_at..stopped_at).order("printed_on, journal_entries.id, #{JournalEntryItem.table_name}.id")
  # end

  def journal_entry_items_calculate(column, started_at, stopped_at, operation = :sum)
    column = (column == :balance ? "#{JournalEntryItem.table_name}.real_debit - #{JournalEntryItem.table_name}.real_credit" : "#{JournalEntryItem.table_name}.real_#{column}")
    journal_entry_items.where(printed_on: started_at..stopped_at).calculate(operation, column)
  end

  def previous
    self.class.order(number: :desc).where('number < ?', number).limit(1).first
  end

  def following
    self.class.order(:number).where('number > ?', number).limit(1).first
  end

  class << self
    def get_auxiliary_accounts(centralizing_number)
      Account.auxiliary.where('number ~* ?', '^' + centralizing_number + '(.*$)')
    end

    # This method loads the balance for a given period.
    def balance(from, to, list_accounts = [])
      balance = []
      conditions = '1=1'
      unless list_accounts.empty?
        conditions += ' AND ' + list_accounts.collect do |account|
          "number LIKE '" + account.to_s + "%'"
        end.join(' OR ')
      end
      accounts = Account.where(conditions).order('number ASC')
      # solde = 0

      res_debit = 0
      res_credit = 0
      res_balance = 0

      accounts.each do |account|
        debit  = account.journal_entry_items.sum(:debit,  conditions: { 'r.created_at' => from..to }, joins: "INNER JOIN #{JournalEntry.table_name} AS r ON r.id=#{JournalEntryItem.table_name}.entry_id").to_f
        credit = account.journal_entry_items.sum(:credit, conditions: { 'r.created_at' => from..to }, joins: "INNER JOIN #{JournalEntry.table_name} AS r ON r.id=#{JournalEntryItem.table_name}.entry_id").to_f

        compute = HashWithIndifferentAccess.new
        compute[:id] = account.id.to_i
        compute[:number] = account.number.to_i
        compute[:name] = account.name.to_s
        compute[:debit] = debit
        compute[:credit] = credit
        compute[:balance] = debit - credit

        if debit.zero? || credit.zero?
          compute[:debit] = debit
          compute[:credit] = credit
        end

        # if not debit.zero? and not credit.zero?
        #         if compute[:balance] > 0
        #           compute[:debit] = compute[:balance]
        #           compute[:credit] = 0
        #         else
        #           compute[:debit] = 0
        #           compute[:credit] = compute[:balance].abs
        #         end
        #       end

        # if account.number.match /^12/
        # raise StandardError.new compute[:balance].to_s
        # end

        if account.number =~ /^(6|7)/
          res_debit += compute[:debit]
          res_credit += compute[:credit]
          res_balance += compute[:balance]
        end

        # solde += compute[:balance] if account.number.match /^(6|7)/
        #      raise StandardError.new solde.to_s if account.number.match /^(6|7)/
        balance << compute
      end
      # raise StandardError.new res_balance.to_s
      balance.each do |account|
        if res_balance > 0
          if account[:number].to_s =~ /^12/
            account[:debit] += res_debit
            account[:credit] += res_credit
            account[:balance] += res_balance # solde
          end
        elsif res_balance < 0
          if account[:number].to_s =~ /^129/
            account[:debit] += res_debit
            account[:credit] += res_credit
            account[:balance] += res_balance # solde
          end
        end
      end
      # raise StandardError.new(balance.inspect)
      balance.compact
    end

    # this method loads the general ledger for all the accounts.
    def ledger(options = {})
      # build filter for accounts
      accounts_filter_conditions = '1=1'
      list_accounts = options[:accounts] ? options[:accounts] : ''
      p list_accounts
      unless list_accounts.empty?
        accounts_filter_conditions += ' AND ' + list_accounts.collect do |account|
          "accounts.number LIKE '" + account.to_s + "%'"
        end.join(' OR ')
      end
      p accounts_filter_conditions

      # build filter for lettering_state
      # "lettering_state"=>["unlettered", "partially_lettered"]
      c = options[:lettering_state].count if options[:lettering_state]
      lettering_state_filter_conditions = if c == 3 && options[:lettering_state].to_set.superset?(%w[unlettered partially_lettered lettered].to_set)
                                            '1=1'
                                          elsif c == 2 && options[:lettering_state].to_set.superset?(%w[partially_lettered lettered].to_set)
                                            'letter IS NOT NULL'
                                          elsif c == 2 && options[:lettering_state].to_set.superset?(%w[partially_lettered unlettered].to_set)
                                            "letter IS NULL OR letter ILIKE '%*' "
                                          elsif c == 2 && options[:lettering_state].to_set.superset?(%w[lettered unlettered].to_set)
                                            "letter IS NULL OR letter NOT ILIKE '%*' "
                                          elsif c == 1 && options[:lettering_state].to_set.superset?(['unlettered'].to_set)
                                            'letter IS NULL'
                                          elsif c == 1 && options[:lettering_state].to_set.superset?(['lettered'].to_set)
                                            "letter IS NOT NULL AND letter NOT ILIKE '%*'"
                                          elsif c == 1 && options[:lettering_state].to_set.superset?(['partially_lettered'].to_set)
                                            "letter IS NOT NULL AND letter ILIKE '%*'"
                                          else
                                            '1=1'
                                          end

      # options[:states]
      if options[:states]&.any?
        a = options[:states].select { |_k, v| v.to_i == 1 }.map { |pair| "'#{pair.first}'" }.join(', ')
        states_array = "state IN (#{a})"
      else
        states_array = '1=1'
      end

      # build dates
      start = options[:period].split('_').first if options[:period]
      stop = options[:period].split('_').last if options[:period]

      ledger = []

      accounts = Account
                 .where(accounts_filter_conditions)
                 .includes(journal_entry_items: %i[entry variant])
                 .where(journal_entry_items: { printed_on: start..stop })
                 .reorder('accounts.number ASC, journal_entries.number ASC')

      accounts.each do |account|
        journal_entry_items = account.journal_entry_items.where(lettering_state_filter_conditions).where(states_array).where(printed_on: start..stop).reorder('printed_on ASC, entry_number ASC')

        account_entry = HashWithIndifferentAccess.new
        # compute << account.number.to_i
        # compute << account.name.to_s
        account_balance = 0.0
        total_debit = 0.0
        total_credit = 0.0
        entry_count = 0

        account_entry[:account_number] = account.number
        account_entry[:account_name] = account.name
        account_entry[:currency] = journal_entry_items.first.currency if journal_entry_items.any?

        account_entry[:items] = []

        journal_entry_items.each do |e|
          item = HashWithIndifferentAccess.new
          item[:entry_number] = e.entry_number
          item[:continuous_number] = e.continuous_number.to_s if e.continuous_number
          item[:reference_number] = e.entry.reference_number.to_s if e.entry.reference_number
          item[:printed_on] = e.printed_on.strftime('%d/%m/%Y')
          item[:name] = e.name.to_s
          item[:journal_name] = e.entry.journal.name.to_s
          item[:letter] = e.letter
          item[:real_debit] = e.real_debit
          item[:real_credit] = e.real_credit
          item[:cumulated_balance] = (account_balance += (e.real_debit - e.real_credit))

          account_entry[:items] << item

          total_debit += e.real_debit
          total_credit += e.real_credit
          entry_count += 1
        end

        account_entry[:count] = entry_count.to_s
        account_entry[:total_debit] = total_debit
        account_entry[:total_credit] = total_credit

        ledger << account_entry
      end

      ledger.compact
    end
  end
end
