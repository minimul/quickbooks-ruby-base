require 'quickbooks-ruby'
require_relative 'base/configuration'
require_relative 'base/finders'

module Quickbooks
  class Base
    attr_reader :service
    include Finders
    extend Configuration

    def initialize(account, type = nil)
      @account = account
      create_service_for(type) if type
    end

    def qbo_case(type)
      type.is_a?(Symbol) ? type.to_s.camelcase : type
    end

    def generate_quickbooks_ruby_namespace(type, variety = 'Model')
      type = qbo_case(type)
      "Quickbooks::#{variety}::#{type}"
    end

    def quickbooks_ruby_model(type, *args)
      generate_quickbooks_ruby_namespace(type, 'Model').constantize.new(*args)
    end
    alias_method :qr_model, :quickbooks_ruby_model

    def quickbooks_ruby_service(type)
      generate_quickbooks_ruby_namespace(type, 'Service').constantize.new
    end
    alias_method :qr_service, :quickbooks_ruby_service

    def oauth_client
      @oauth_client ||= OAuth::AccessToken.new(Quickbooks::Base.oauth_consumer, token, secret)
    end

    def show(options = {})
      options = { per_page: 20, page: 1 }.merge(options)
      service = determine_service(options[:entity])
      service.query(nil, options).entries.collect do |e|
        "QBID: #{e.id} DESC: #{description(e)}"
      end
    end

    def description(e)
      desc = (method = describing_method(e)) =~ /(total)/ ? e.send(method).to_f : e.send(method)
    rescue => e
      'nil'
    end

    def entity(obj = nil)
      obj ||= @service
      obj.class.name.split('::').last
    end

    def describing_method(e)
      case entity(e)
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

    def service_for(type)
      service = quickbooks_ruby_service(type)
      service.access_token = oauth_client
      service.company_id = company_id
      service
    end

    def create_service_for(type)
      @service = service_for(type)
    end

    private

    def determine_service(entity)
      entity ? service_for(entity) : @service
    end

    def send_chain(arr)
      arr.inject(@account) {|o, a| o.send(a) }
    end

  end
end
