require 'quickbooks-ruby'
require_relative 'base/configuration'

module Quickbooks
  class Base
    attr_reader :service
    extend Configuration

    def initialize(account, type = nil)
      @account = account
      create_service_for(type) if type
    end

    def generate_quickbooks_ruby_namespace(which, type = 'Model')
      which = which.to_s.camelcase if which.is_a?(Symbol)
      "Quickbooks::#{type}::#{which}"
    end

    def quickbooks_ruby_model(which, *args)
      generate_quickbooks_ruby_namespace(which, 'Model').constantize.new(*args)
    end
    alias_method :qr_model, :quickbooks_ruby_model

    def quickbooks_ruby_service(which)
      generate_quickbooks_ruby_namespace(which, 'Service').constantize.new
    end
    alias_method :qr_service, :quickbooks_ruby_service

    def oauth_client
      @oauth_client ||= OAuth::AccessToken.new(Quickbooks::Base.oauth_consumer, token, secret)
    end

    def show(options = {})
      options = { per_page: 20, page: 1 }.merge(options)
      method = describing_method
      @service.query(nil, options).entries.collect do |e|
        desc = (method = describing_method) =~ /(total)/ ? e.send(method).to_f : e.send(method)
        "QBID: #{e.id} DESC: #{desc}"
      end
    end

    def describing_method
      case @service.class.name
      when /(Item|TaxCode|PaymentMethod)/
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
