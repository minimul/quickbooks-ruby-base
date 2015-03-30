require 'quickbooks-ruby'
require_relative 'base/configuration'
require_relative 'base/finders'

module Quickbooks
  class Base
    attr_reader :service, :entity
    include Finders
    extend Configuration

    def initialize(account, type = nil)
      @account = account
      create_service_for(type) if type
    end

    def generate_quickbooks_ruby_namespace(entity, type = 'Model')
      @entity = entity.is_a?(Symbol) ? entity.to_s.camelcase : entity
      "Quickbooks::#{type}::#{@entity}"
    end

    def quickbooks_ruby_model(entity, *args)
      generate_quickbooks_ruby_namespace(entity, 'Model').constantize.new(*args)
    end
    alias_method :qr_model, :quickbooks_ruby_model

    def quickbooks_ruby_service(entity)
      generate_quickbooks_ruby_namespace(entity, 'Service').constantize.new
    end
    alias_method :qr_service, :quickbooks_ruby_service

    def oauth_client
      @oauth_client ||= OAuth::AccessToken.new(Quickbooks::Base.oauth_consumer, token, secret)
    end

    def show(options = {})
      options = { per_page: 20, page: 1 }.merge(options)
      @service.query(nil, options).entries.collect do |e|
        "QBID: #{e.id} DESC: #{description(e)}"
      end
    end

    def id(id)
      @service.fetch_by_id(id)
    end

    def description(e)
      desc = (method = describing_method) =~ /(total)/ ? e.send(method).to_f : e.send(method)
    rescue => e
      'nil'
    end

    def describing_method
      case @service.class.name
      when /(Item|TaxCode|PaymentMethod|Account)/
        'name'
      when /(Invoice|CreditMemo)/
        'doc_number'
      when /Payment/
        'total'
      when /(Vendor|Customer|Employee)/
        'display_name'
      else
        'txn_date'
      end
    end

    def token
      retrieve(:token)
    end

    def secret
      retrieve(:secret)
    end

    def company_id
      retrieve(:company_id)
    end

    def retrieve(type)
      meth = "persistent_#{type}"
      arr = Quickbooks::Base.send(meth).split('.')
      send_chain(arr)
    end

    def create_service_for(type)
      @service = quickbooks_ruby_service(type)
      @service.access_token = oauth_client
      @service.company_id = company_id
      @service
    end

    private

    def send_chain(arr)
      arr.inject(@account) {|o, a| o.send(a) }
    end

  end
end
