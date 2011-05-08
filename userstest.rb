# load with [irb -r ./RestAuth.rb] enter [source "test.rb"]
# server: http://test:test@localhost/
require 'yaml'
require 'restauth'

config = YAML.load_file("restauth.yml")
if !config.nil?
  restauth_host = config[:host] || "localhost"
  restauth_port = config[:port] || 8000
  restauth_user = config[:user] || "user"
  restauth_password = config[:password] || "password"
else
  restauth_host = "localhost"
  restauth_port = 8000
  restauth_user = "user"
  restauth_password = "password"
end

puts "---------- Opening Connection ----------"
conn = RestAuthConnection.new( "http://"+restauth_host+":"+restauth_port.to_s+"/", restauth_user, restauth_password )
#
puts "---------- Creating User 'Astra' ----------"
puts RestAuthUser.create( "Astra", "astra1", conn ).name + ' created'

#puts "---------- Reading User 'Astra' ----------"
# Properties schauen auf gross-kleinschreibung!!!
astra = RestAuthUser.get( "astra", conn )
puts astra.name

puts "---------- Listing all users ----------"
RestAuthUser.get_all( conn )

puts "---------- Set Passwort to 'longsecretpassword' ----------"
puts astra.set_password('longsecretpassword')

# verify old password
puts "---------- Verify 'astra1' ----------"
puts astra.verify_password('astra1')

# verify new password
puts "---------- Verify 'longsecretpassword' ----------"
puts astra.verify_password('longsecretpassword')

# and reset
puts "---------- Reset Passwort to 'astra1' ----------"
puts astra.set_password('astra1')

## Testing properties
puts "Set properties:"
astra.get_properties.each{ |prop, value|
  puts prop+': '+value
}

puts "---------- Creating 'testprop' of 'Astra' ----------"
astra.create_property("testprop", "booo!")

puts "---------- Setting 'testprop' of 'Astra' ----------"
astra.set_property("testprop", "booobooo!")

puts "---------- Getting properties of 'Astra' ----------"
astra.get_properties.each{ |prop, value|
  puts prop+': '+value
}

puts "---------- Getting 'testprop' of 'Astra' ----------"
puts astra.get_property("testprop")

puts "---------- Removing 'testprop' of 'Astra' ----------"
astra.del_property("testprop")

puts "---------- Getting properties of 'Astra' ----------"
astra.get_properties.each{ |prop, value|
  puts prop+': '+value
}

puts "---------- Deleting User 'Astra' ----------"
puts astra.remove()
