
# OpenWeatherMap uses a simple form of authentication
# it requires an 'APPID' query param on gets
# the value is an API Key you get by signing up at their website (free)
def owm_appid
  appid = hatt_configuration['hatt_services']['owm']['appid']
  raise "Open Weather Map API KEY must be defined in hatt.yml" unless appid =~ /^\w+$/
  appid
end

# a simple call to open weather map that takes a string for the city
def weather_for location
  owm.get "/data/2.5/weather?q=#{URI.encode(location)}&APPID=#{owm_appid}"
end

# a simple call that returns the callers IP and geographic info
def my_location
  freegeoip.get '/json/'
end

# A cross service call that first gets your localtion, then gets weather at location
def my_weather
  location = my_location
  location_str = "#{location['city']}, #{location['region_code']}"
  weather_for location_str
end

def kelvin_to_celcius kelvin
  (kelvin - 273.15).round
end

# A call that gets your weather report and filters it into a nice report on temperatures only
def my_temperature
  weather = my_weather
  temps = {
    'current' => kelvin_to_celcius(weather['main']['temp']),
    'low' => kelvin_to_celcius(weather['main']['temp_min']),
    'high' => kelvin_to_celcius(weather['main']['temp_max']),
  }
  "Temperatures today:\n#{temps.to_yaml}"
end
