require 'restauth'
require 'yaml'

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
user = RestAuthUser.new(conn)
#
puts "---------- Creating User 'Astra' ----------"
puts user.create( "Astra", "astra1" ).name + ' created'

puts "---------- Reading User 'Astra' ----------"
# Properties schauen auf gross-kleinschreibung!!!
astra = user.get("astra")
puts astra.name

puts "---------- Creating 'testprop' of 'Astra' ----------"
astra.create_property("testprop", "booo!")

puts "---------- Removing 'testprop' of 'Astra' ----------"
astra.del_property("testprop")

puts "---------- Deleting User 'Astra' ----------"
puts astra.remove()
