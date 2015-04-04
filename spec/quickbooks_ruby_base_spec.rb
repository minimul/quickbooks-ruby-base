require 'spec_helper'

describe Quickbooks::Base do
  let(:account) { double }
  let(:full_account) { account = double(settings: double( qb_token: 'tttttttttt', qb_secret: 'ssssssss', qb_company_id: '1234567')) }
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

    it "description should display using the display_name for vendor" do
      xml = read_fixture('vendors')
      stub_response(xml)
      qr = Quickbooks::Base.new(full_account, :vendor)
      expect(qr.show.first).to match /Catherines Cupcakes/
    end

    it "description should display using the name for tax_code" do
      xml = read_fixture('tax_codes')
      stub_response(xml)
      qr = Quickbooks::Base.new(full_account, :tax_code)
      expect(qr.show.last).to match /New York City/
    end

    it "description should display using the doc_number for invoice" do
      xml = read_fixture('invoices')
      stub_response(xml)
      qr = Quickbooks::Base.new(full_account, :invoice)
      expect(qr.show.last).to match /1234/
    end

    it "description should display using the total for payment" do
      xml = read_fixture('payments')
      stub_response(xml)
      qr = Quickbooks::Base.new(full_account, :payment)
      expect(qr.show.last).to match /100\.0/
    end

    it "description should display 'nil' as no description fits" do
      pending 'Need to find a transaction or name entity that does not match txn_date'
      xml = read_fixture('dummy')
      xml.gsub!('Dummy', 'SalesReceipt')
      stub_response(xml)
      qr = Quickbooks::Base.new(full_account, :sales_receipt)
      expect(qr.show.last).to match /nil/
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
      qb = Quickbooks::Base.new(full_account)
      service = qb.create_service_for :access_token
      expect(service.class.name).to match /Service::AccessToken/
    end
  end

  describe ".find_by_id" do
    it 'grabs a object by id' do
      xml = read_fixture('invoice') 
      stub_response(xml)
      qr = Quickbooks::Base.new(full_account, :invoice)
      result = qr.find_by_id(28)
      expect(result.id).to eq 156
    end
  end

  describe ".display_name_sql" do
    it 'for basic usage' do
      qr = Quickbooks::Base.new(full_account, :customer)
      expect(qr.display_name_sql('Chuck Russell')).to eq "Select Id, DisplayName From Customer WHERE DisplayName = 'Chuck Russell' LIMIT 1"
    end

    it 'for custom usage' do
      qr = Quickbooks::Base.new(full_account, :customer)
      sql = qr.display_name_sql('Chuck Russell', entity: 'Vendor', select: '*', limit: 5)
      expect(sql).to eq "Select * From Vendor WHERE DisplayName = 'Chuck Russell' LIMIT 5"
    end
  end

  def read_fixture(filename)
    File.read(File.join('spec', 'fixtures', "#{filename}.xml"))
  end

  def stub_response(xml)
    response = Struct.new(:plain_body, :code).new(xml, 200)
    allow_any_instance_of(OAuth::AccessToken).to receive(:get).and_return(response)
  end
end
