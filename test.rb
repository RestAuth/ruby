# load with [irb -r ./RestAuth.rb] enter [source "test.rb"]
# server: http://test:test@localhost/
conn = RestAuthConnection.new("http://localhost:8000/", "test", "test")
# http://test:test@localhost/users/astra/
#users = RestAuthUser.new(conn, "Astra")
resp = conn.get("/users/astra/")
puts resp.code
puts resp.body
