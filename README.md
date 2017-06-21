# HATT (HTTP API Testing Tool)

HATT is a tool, and a pattern, for testing HTTP APIs (RESTful or otherwise).  It can be used to
construct fully automated tests, and also provides support for simple manual testing.

HATT is a Ruby tool and gem.  It leverages the full power of Ruby.  That said, HATT should be usable by those
with little familiarity of Ruby, but some knowledge of scripting languages in general.  HATT works with standard
Ruby testing frameworks like RSpec and MiniTest.

## Basic testing features

* Easily configure and interact with one or more HTTP services (RESTful services).
* "Point" tests and requests at various deployment environments (eg, QA, Staging, Production)
* Using RSpec or MiniTest or any other testing framework, construct fully automated tests.
* Easily define a "DSL", or domain-specific-language for interacting with your API in your
  own terms.  This allows for writing self-documenting, easy to understand tests.
* Easily integrates into popular Continuos Integration tools like Jenkins.  This means
  your tests can run on a central server where all team members can access them.


## Short Example

The code for this entire example lives at [https://github.com/rschultheis/hatt_example].
Looking through that project shows examples of using nearly every hatt feature,
and examples of many kinds of tests and assertions against APIs.

This example is based on a free API: OpenWeatherMap.  While the API is free, one must sign-up for an API key here:
[http://openweathermap.org/appid].  Keep your API key handy you will need it soon...

### Configure HATT, and setup a simple DSL method

#### install hatt

    gem install hatt

#### make a project directory

    mkdir open_weather_map_api_test_suite
    cd open_weather_map_api_test_suite

#### Make a file called 'hatt.yml' with these contents:

    hatt_services:
      # shothand of owm for "open weather map api"
      owm:
        url: http://api.openweathermap.org

#### Put our API key into hatt.secret.yml

We need a special place to put our API key. For that make a file called hatt.secret.yml.  This is a file that is generally not to be checked into source control, it should be used for configuring any secrets (like API keys or passwords). Put this one line into the file:

    owm_app_id: <your api key here>

#### make the hattdsl directory:

    mkdir hattdsl

#### add method for checking weather to hattdsl/open_weather_map_hattdsl.rb

    def weather_for city
      owm.get "/data/2.5/weather?q=#{URI.encode(city)}&APPID=#{appid}"
    end

    def appid
      hatt_configuration['owm_app_id']
    end

#### Call it from the cmd line:

    hatt -v weather_for "Pleasantville, NY"

And that returns something like this:

    ... <detailed logging showing full request / response>
    D: [06/14/17 17:07:53][hatt] - HATT method 'weather_for' returned:
    {"coord"=>{"lon"=>-73.79, "lat"=>41.13}, "weather"=>[{"id"=>800, "main"=>"Clear", "description"=>"clear sky", "icon"=>"01d"}], "base"=>"stations", "main"=>{"temp"=>299.68, "pressure"=>1014, "humidity"=>39, "temp_min"=>296.15, "temp_max"=>303.15}, "visibility"=>16093, "wind"=>{"speed"=>4.1, "deg"=>190}, "clouds"=>{"all"=>1}, "dt"=>1497480900, "sys"=>{"type"=>1, "id"=>1980, "message"=>0.0057, "country"=>"US", "sunrise"=>1497432119, "sunset"=>1497486575}, "id"=>5131757, "name"=>"Pleasantville", "cod"=>200}


So, at this point we are able to call the API, and see the full details of the request and response.  We can manually
test a lot at this point.  But HATT can do more....


### Make a ruby script, that uses the hattdsl:

#### Make a file called temperatures.rb with this in it:

    [
      'New York, NY',
      'Toronto, Canada',
      'Paris, France',
      'Tokyo, Japan',
      'Sydney, Australia',
    ].each do |city|
      weather = weather_for city
      kelvin = weather['main']['temp']
      celcius = (kelvin - 273.15).round
      puts "#{city}: #{celcius} celcius"
    end

#### And then run the hatt script like so:

    hatt -q -f temperatures.rb

And get this nice output (-q supresses all the detailed request/response logging, leaving only the puts in the script):

    New York, NY: 18 celcius
    Toronto, Canada: 7 celcius
    Paris, France: 18 celcius
    Tokyo, Japan: 16 celcius
    Sydney, Australia: 14 celcius


### Make an automated test

Using the included Hatt::Mixin and Hatt::SingletonMixin module, testing an api becomes easy.  Lets setup a simple RSpec example here.

#### Install rspec:

    gem install rspec

#### Create the spec folder:

    mkdir spec

#### Setup spec/spec_helper.rb with these contents to :

    require 'hatt'

    RSpec.configure do |config|

      config.include Hatt::SingletonMixin

      config.before(:all) do
        hatt_initialize
      end
    end

#### Setup spec/weather_spec.rb with contents like:

    require 'spec_helper'
    describe "getting weather reports" do
      it "should know the weather for New York City" do
        response = weather_for 'New York, NY'
        expected_items = ['temp', 'temp_min', 'temp_max', 'humidity', 'pressure']
        # the actual assertions here
        expect(response['main'].keys).to include(*expected_items)
        # the temp is in kelvin, so it looks kinda wierd
        expect(response['main']['temp']).to be_between(100, 400)
      end
    end

#### Run it:

    rspec

And get back:

    ... <detailed logging showing all request response details> ...

    1 example, 0 failures



And THAT is the basic way to use HATT to test an API.

For more information, and more detailed examples of how to do nearly anything using HATT, see the example
project: [https://github.com/rschultheis/hatt_example]
