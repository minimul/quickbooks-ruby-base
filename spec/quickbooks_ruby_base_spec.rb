require 'spec_helper'

describe Quickbooks::Base do
  let(:account) { double }
  let(:qr_base) { Quickbooks::Base.new(account) }

  describe ".quickbooks_ruby_namespace" do
    it "should generate quickbooks ruby model namespace given a symbol" do
     expect(qr_base.generate_quickbooks_ruby_namespace(:access_token)).to eq "Quickbooks::Model::AccessToken"
    end

    it "should generate quickbooks ruby service namespace given a string" do
      expect(qr_base.generate_quickbooks_ruby_namespace('AccessToken', 'Service')).to eq "Quickbooks::Service::AccessToken"
    end
  end

  describe ".qr_model" do

    it "should create a new instance of a quickbooks-ruby model" do
      expect(qr_base.qr_model(:invoice).class.name).to eq 'Quickbooks::Model::Invoice'
    end

    it "should create a new instance of a quickbooks-ruby model that take more than 1 argument" do
      result = qr_base.qr_model(:email_address, 'test@email.com')
      expect(result.address).to eq 'test@email.com'
    end
  end

  describe ".show" do
    let(:account) { account = double(settings: double( qb_token: 'tttttttttt', qb_secret: 'ssssssss', qb_company_id: '1234567')) }

    it "description should display using the dispay_name for vendor" do
      xml = File.read(File.join('spec', 'fixtures', 'vendors.xml'))
      response = Struct.new(:plain_body, :code).new(xml, 200)
      allow_any_instance_of(OAuth::AccessToken).to receive(:get).and_return(response)
      qr = Quickbooks::Base.new(account, :vendor)
      expect(qr.show.first).to match /Catherines Cupcakes/
    end

    it "description should display using the name for tax_code" do
      xml = File.read(File.join('spec', 'fixtures', 'tax_codes.xml'))
      response = Struct.new(:plain_body, :code).new(xml, 200)
      allow_any_instance_of(OAuth::AccessToken).to receive(:get).and_return(response)
      qr = Quickbooks::Base.new(account, :tax_code)
      expect(qr.show.last).to match /New York City/
    end

    it "description should display using the doc_number for invoice" do
      xml = File.read(File.join('spec', 'fixtures', 'invoices.xml'))
      response = Struct.new(:plain_body, :code).new(xml, 200)
      allow_any_instance_of(OAuth::AccessToken).to receive(:get).and_return(response)
      qr = Quickbooks::Base.new(account, :invoice)
      expect(qr.show.last).to match /1234/
    end

    it "description should display using the total for payment" do
      xml = File.read(File.join('spec', 'fixtures', 'payments.xml'))
      response = Struct.new(:plain_body, :code).new(xml, 200)
      allow_any_instance_of(OAuth::AccessToken).to receive(:get).and_return(response)
      qr = Quickbooks::Base.new(account, :payment)
      expect(qr.show.last).to match /100\.0/
    end

  end

  describe ".retrieve" do
    after do
     Quickbooks::Base.configure { |c| c.persistent_token = nil; c.persistent_secret = nil; c.persistent_company_id = nil }
    end

    it "should set the persistence token location" do
      Quickbooks::Base.configure do |c|
        c.persistent_token = 'quickbooks_token'
        c.persistent_company_id = 'quickbooks_company_id' 
      end
      expect(Quickbooks::Base.persistent_token).to eq 'quickbooks_token'
      expect(Quickbooks::Base.persistent_company_id).to eq 'quickbooks_company_id'
    end

    it "should retrieve token configuration that is 2 levels deep, which is the default" do
      token = 'xxxxxxxxxxxxxx'
      account = double(settings: double( qb_token: token ))
      qr_base = Quickbooks::Base.new(account)
      expect(qr_base.retrieve(:token)).to eq token
    end

    it "should retrieve token configuration that is 1 level deep" do
      token = 'xxxxxxxxxxxxxx'
      Quickbooks::Base.configure do |c|
        c.persistent_token = 'quickbooks_token'
      end
      account = double( quickbooks_token: token )
      qr_base = Quickbooks::Base.new(account)
      expect(qr_base.retrieve(:token)).to eq token
    end
  end

  describe ".create_service_for" do
    it "creates a access_token service" do
      account = double(settings: double( qb_token: 'tttttttttt', qb_secret: 'ssssssss', qb_company_id: '1234567'))
      qb = Quickbooks::Base.new(account)
      service = qb.create_service_for :access_token
      expect(service.class.name).to match /Service::AccessToken/
    end
  end
end
