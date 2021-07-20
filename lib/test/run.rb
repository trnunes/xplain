test_files = Dir[File.join(File.dirname(File.absolute_path(__FILE__)), "../**/*_test.rb")]
test_files = test_files.delete_if{|f| f.include?("xplain_unit_test") || f.include?("functional")}
test_files.each do |file|
  puts "------------------RUNNING #{file.to_s}----------------------"
  require file
end