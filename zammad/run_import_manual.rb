puts "Finding LDAP Source..."
source = LdapSource.first
puts "Source: #{source.inspect}"

puts "Running Import::Ldap..."
begin
  # Try to instantiate the backend directly if possible
  # But ImportJob wrapper is easier
  job = ImportJob.create(name: 'Import::Ldap')
  puts "Job created: #{job.id}"
  job.start
  puts "Job finished."
  puts "Result: #{job.result}"
rescue => e
  puts "CRASH: #{e.message}"
  puts e.backtrace
end
