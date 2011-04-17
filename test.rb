# load with [irb -r ./RestAuth.rb] enter [source "test.rb"]
# server: http://test:test@localhost/
puts "---------- Opening Connection ----------"
conn = RestAuthConnection.new("http://localhost:8000/", "admin", "admin")
# http://test:test@localhost/users/astra/
#users = RestAuthUser.new(conn, "Astra")
puts "---------- Creating User 'Astra' ----------"
#resp = conn.post("/users/", params='{"user":"astra","password":"astra"}')
resp = conn.post("/users/", params='"user":"astra","password":"astra"')
puts "---------- Reading User 'Astra' ----------"
resp = conn.get("/users/astra/")
