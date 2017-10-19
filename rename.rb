require "bundler"
require "exif"
require "date"

importFolder = ENV['IMPORT_PATH']
exportFolder = ENV['EXPORT_PATH'] || './export'

unless importFolder && File.exists?(importFolder)
  puts "Run again with IMPORT_PATH=/foo/bar"
  exit
end

unless File.exists?(importFolder)
  puts "The import folder '#{importFolder}' does not exist"
  exit
end

puts "Scanning #{importFolder}"

i = 0

Dir.glob("#{importFolder}/**/*.{jpg,jpeg,JPG,JPEG}") do |filepath|
  i += 1
  # exit if i > 1000

  puts "\nLoading #{filepath}"

  file = File.open(filepath)

  begin
    data = Exif::Data.new(file)
  rescue Exif::NotReadble

    puts file
    exit

    puts "Skipping: Could not read EXIF data for #{filepath}"
    next
  end

  if !data.date_time
    puts "Skipping: Couldn't find the date time"
    next
  end

  date_time = DateTime.strptime(data.date_time, '%Y:%m:%d %H:%M:%S')

  folder = date_time.strftime('%Y/%Y-%m')
  dest_basename = date_time.strftime('%Y-%m-%d %H-%M-%S')
  dest_path = "#{exportFolder}/#{folder}"

  # TODO MAAAYBE we need some second duplicate avoidance
  # dest_count = `ls -1 #{dest_path} | wc -l`.to_i
  # dest_filepath = "#{dest_path}/#{dest_basename} - #{dest_count}.jpg"
  dest_filepath = "#{dest_path}/#{dest_basename}.jpg"

  puts "Moving to #{dest_filepath}"
  system 'mkdir', '-p', "#{dest_path}" unless File.exists?("#{dest_path}")
  system 'mv', filepath, dest_filepath
end
