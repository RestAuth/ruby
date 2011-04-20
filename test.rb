# load with [irb -r ./RestAuth.rb] enter [source "test.rb"]
# server: http://test:test@localhost/
puts "---------- Opening Connection ----------"
conn = RestAuthConnection.new("http://localhost:8000/", "admin", "admin")
# http://test:test@localhost/users/astra/
user = RestAuthUser.new(conn)
#users = RestAuthUser.new(conn, "Astra")
puts "---------- Creating User 'Astra' ----------"
#resp = conn.post("/users/", params={'user' => 'astra', 'password' => 'astra1'})
puts user.create( "Astra", "astra1" ).name + ' created'
#puts user.create( "Astrb", "astra1" ).name + ' created'
#puts user.create( "Astrc", "astra1" ).name + ' created'
#puts user.create( "Astrd", "astra1" ).name + ' created'

puts "---------- Reading User 'Astra' ----------"
astra = user.get("Astra")
puts astra.name

puts "---------- Listing all users ----------"
user.get_all

puts "---------- Set Passwort to 'longsecretpassword' ----------"
astra.set_password('longsecretpassword')

# verify old password
puts "---------- Verify 'astra1' ----------"
astra.verify_password('astra1')

# verify new password
puts "---------- Verify 'longsecretpassword' ----------"
astra.verify_password('longsecretpassword')

# and reset
puts "---------- Reset Passwort to 'astra1' ----------"
astra.set_password('astra1')

puts "---------- Deleting User 'Astra' ----------"
resp = conn.delete("/users/astra/")
