# load with [irb -r ./RestAuth.rb] enter [source "test.rb"]
# server: http://test:test@localhost/
puts "---------- Opening Connection ----------"
conn = RestAuthConnection.new("http://localhost:8000/", "admin", "admin")
#
group = RestAuthGroup.new(conn)
#
puts "---------- Creating Group 'testgroup' ----------"
group.create("testgroup")

puts "---------- Fetching All Groups ----------"
group.get_all.each{ |group|
  puts group.name
}

puts "---------- Fetching Group 'testgroup' ----------"
testgroup = group.get("testgroup")
puts testgroup.name

#puts "---------- Add a member to 'testgroup' ----------"
#astra = RestAuthUser.new(conn, "astra")
#testgroup.add_user(astra, false)

#puts "---------- Test 'astra' for membership in 'testgroup' ----------"
#puts testgroup.is_member(astra)

#puts "---------- Get all members of 'testgroup' ----------"
#testgroup.get_members

#puts "---------- Delete 'astra' from 'testgroup' ----------"
#testgroup.remove_user(astra)

#puts "---------- Test 'astra' for membership in 'testgroup' ----------"
#puts testgroup.is_member(astra)

puts "---------- Testing Group 'testgroup' ----------"
testsubgroup = group.create("testsubgroup")

puts "---------- Adding 'testsubgroup' to 'testgroup' ----------"
testgroup.add_group(testsubgroup)

puts "---------- Gett all groups in 'testgroup' ----------"
testgroup.get_groups.each{ |group|
  puts group.name
}

puts "---------- Removing 'testsubgroup' from 'testgroup' ----------"
testgroup.remove_group(testsubgroup)

puts "---------- Removing 'testsubgroup' ----------"
testsubgroup.remove()

puts "---------- Deleting Group 'testgroup' ----------"
testgroup.remove()
