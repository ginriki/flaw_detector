detector_path = File.expand_path("..", __FILE__) 
detector_files = Dir.entries(detector_path).grep(/\.rb$/) - ["detector.rb","abstract_detector.rb"]
detector_files.each do |file_name|
  require detector_path + "/" + file_name
end
