## Description

The `quickbooks-ruby-base` gem complements the [`quickbooks-ruby`](https://github.com/ruckus/quickbooks-ruby) library by providing a base class to handle routine tasks like creating a model, service, and displaying information.
See the [screencast](http://minimul.com/improve-your-quickbooks-ruby-integration-experience-with-the-quickbooks-ruby-base-gem.html) for more details.

## Installation

Add this line to your application's Gemfile:

    gem 'quickbooks-ruby-base'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install quickbooks-ruby-base

## Usage
1. The first argument is required and is a persistent object holding Intuit OAuth information (see Configuration section). 
2. The second argument is optional but if passed must be a valid `quickbooks-ruby` service type such as Invoice, Customer, Item, PaymentMethod, etc. When passing in a symbol, snake case must be used e.g. `:payment_method`. If a string you must use the explicit name, e.g. 'PaymentMethod'
```
def initialize(account, type = nil)      
  @account = account
  create_service_for(type) if type
end
```

### qr_model(*args)
Generate a `quickbooks-ruby` model. First argument must be valid `quickbooks-ruby` model.
```
>> base = Quickbooks::Base.new(account)
>> customer = base.qr_model(:customer) 

# Accepts more than 1 argument e.g.
>> base = Quickbooks::Base.new(account)
>> qb_invoice = base.qr_model :invoice
>> qb_invoice.bill_email = base.qr_model(:email_address, invoice.customer.email)
```

### service()
Returns `quickbooks-ruby` service.
```
>> base = Quickbooks::Base.new(account, :customer)
>> base.service
=> #<Quickbooks::Service::Customer:0x007faf7fe3f130 @base_uri="https://qb.sbfinance.intuit.com/v3/company", .etc
>> customer = base.qr_model(:customer) 
>> customer.display_name = 'Minimul X'
# Do a create
>> base.service.create(customer)
# Or an update
>> base.service.update(customer)
# Execute a query
>> base.service.query('SELECT * FROM INVOICES')
```

### show(options = {})
Returns an array of the QuickBooks' IDs and a "smart" description. Smart, meaning that different services have different identifiers. For a customer, employee, and vendor the `DESC` is `display_name`. For invoice, it is `doc_number`. For item, tax_code, and payment_method it is the `name`. 
```
base = Quickbooks::Base.new(account, :invoice)
# Returns an array of payment_methods from QBO account
base = Quickbooks::Base.new(account, :payment_method)
>> base.show
# Returns an array of payment_methods from QBO account
>> base.show
=> ["QBID: 5 DESC: American Express", "QBID: 1 DESC: Cash", "QBID: 2 DESC: Check", "QBID: 6 DESC: Diners Club", "QBID: 7 DESC: Discover", "QBID: 4 DESC: MasterCard", "QBID: 3 DESC: Visa"]
# With options
>> base.show page:1, per_page: 3
=> ["QBID: 5 DESC: American Express", "QBID: 1 DESC: Cash", "QBID: 2 DESC: Check"]
# Show another entity
>> base.show(entity: :vendor)
=> ["QBID: 5 DESC: Hampton's Car Parts", "QBID: 6 DESC: Good Eats", "QBID: 7 DESC: The Flower Shoppe"]

```

### find_by_id()
Convenience method to fetch an entity by its reference id
```
base = Quickbooks::Base.new(account, :customer)
>> base.find_by_id(1)
# Second argument to find Employee with id = 55
>> base.find_by_id(55, :employee)
```
  
### find_by_display_name()
Convenience method to search for a name entity by DisplayName.
Note: Leverages proper escaping via the [Quickbooks::Util::QueryBuilder](https://github.com/ruckus/quickbooks-ruby/blob/master/lib/quickbooks/util/query_builder.rb) module.
```
base = Quickbooks::Base.new(account, :customer)
>> base.find_by_display_name('Chuck Russell')
# Generates a query based on the following SQL
# "SELECT Id, DisplayName FROM Customer WHERE DisplayName = 'Chuck Russell'"
```
#### with options
```
base = Quickbooks::Base.new(account)
>> base.find_by_display_name("Jonnie O'Meara", entity: :vendor, select: '*')
# Generates a query based on the following SQL
# "SELECT * FROM Vendor WHERE DisplayName = 'Jonnie O\\'Meara'"
```

## Configuration

As the first argument, the `Quickbooks::Base` class expects a persistent object that holds OAuth connection information.

For example, if an account's OAuth information is stored like this:
```
account.qb_token
account.qb_secret
account.qb_company_id
```

Your `Quickbooks::Base` configuration would look like this.

```

QB_KEY = ENV['MINIMULCASTS_CONSUMER_KEY']
QB_SECRET = ENV['MINIMULCASTS_CONSUMER_SECRET']

$qb_oauth_consumer = OAuth::Consumer.new(QB_KEY, QB_SECRET, {
    :site                 => "https://oauth.intuit.com",
    :request_token_path   => "/oauth/v1/get_request_token",
    :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
    :access_token_path    => "/oauth/v1/get_access_token"
})

Quickbooks::Base.configure do |c|
  c.persistent_token = 'qb_token'
  c.persistent_secret = 'qb_secret'
  c.persistent_company_id = 'qb_company_id'
end

```

### Configuration defaults
```
p Quickbooks::Base.persistent_token
# "settings.qb_token"
p Quickbooks::Base.persistent_secret
# "settings.qb_secret"
p Quickbooks::Base.persistent_company_id
# "settings.qb_company_id"
```
By default `quickbooks-base-ruby` uses the `$qb_oauth_consumer` global var but can be overridden e.g.:

```
$intuit_oauth_consumer = OAuth::Consumer.new(QB_KEY, QB_SECRET, {
    :site                 => "https://oauth.intuit.com",
    :request_token_path   => "/oauth/v1/get_request_token",
    :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
    :access_token_path    => "/oauth/v1/get_access_token"
})

Quickbooks::Base.configure do |c|
  c.oauth_consumer = $intuit_oauth_consumer
end
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/quickbooks-ruby-base/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Create a spec to test your feature.
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
