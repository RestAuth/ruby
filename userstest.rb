# load with [irb -r ./RestAuth.rb] enter [source "test.rb"]
# server: http://test:test@localhost/
puts "---------- Opening Connection ----------"
conn = RestAuthConnection.new("http://localhost:8000/", "admin", "admin")
#
user = RestAuthUser.new(conn)
#
puts "---------- Creating User 'Astra' ----------"
#resp = conn.post("/users/", params={'user' => 'astra', 'password' => 'astra1'})
puts user.create( "Astra", "astra1" ).name + ' created'
#puts user.create( "Astrb", "astra1" ).name + ' created'
#puts user.create( "Astrc", "astra1" ).name + ' created'
#puts user.create( "Astrd", "astra1" ).name + ' created'

puts "---------- Reading User 'Astra' ----------"
# Properties schauen auf gross-kleinschreibung!!!
astra = user.get("astra")
puts astra.name

puts "---------- Listing all users ----------"
user.get_all

#puts "---------- Set Passwort to 'longsecretpassword' ----------"
#puts astra.set_password('longsecretpassword')

# verify old password
#puts "---------- Verify 'astra1' ----------"
#puts astra.verify_password('astra1')

# verify new password
#puts "---------- Verify 'longsecretpassword' ----------"
#puts astra.verify_password('longsecretpassword')

# and reset
#puts "---------- Reset Passwort to 'astra1' ----------"
#puts astra.set_password('astra1')

## Testing properties
puts "Set properties:"
astra.get_properties.each{ |prop|
  puts prop
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
astra.get_properties.each{ |prop|
  puts prop
}

puts "---------- Deleting User 'Astra' ----------"
puts astra.remove()
