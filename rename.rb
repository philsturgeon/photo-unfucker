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

# These will be updated as we go
previous_data = previous_filepath = nil

Dir.glob("#{importFolder}/**/*.{jpg,jpeg,JPG,JPEG}") do |filepath|
  i += 1

  puts "\nLoading #{filepath}"

  file = File.open(filepath)

  begin
    data = Exif::Data.new(file)
  rescue Exif::NotReadable
    puts "Skipping: Could not read EXIF data for \"#{filepath}\""
    next
  end

  if !data.date_time

    if !previous_filepath
      puts "Skipping: Couldn't find the date time"
      next
    end

    puts "Missing EXIF data, lets try this another way... \n\n"
    system "imgcat \"#{previous_filepath}\""
    puts "...aaaand..."
    system "imgcat \"#{filepath}\""

    puts "Does it look like these two photos are relevatively close together chronolocically? Or should we just delete the one at the bottom? [Y/n/s/d]"

    answer = STDIN.gets.strip.downcase
    if answer == "d"
      puts "Deleting photo entirely. Screw that shitty photo."
      system 'rm', filepath
      next

    elsif answer == "y"
      puts "answered! #{answer}"
      data = previous_data

    else
      # Clearly we've moved on in time
      previous_data = previous_filepath = nil
      puts "Skipping: Meh entering a date here would be annoying so just figure it out yourself"
      next
    end
  end

  date_time = DateTime.strptime(data.date_time, '%Y:%m:%d %H:%M:%S')

  folder = date_time.strftime('%Y/%Y-%m')
  dest_basename = date_time.strftime('%Y-%m-%d %H-%M-%S')
  dest_path = "#{exportFolder}/#{folder}"
  dest_filepath = "#{dest_path}/#{dest_basename}.jpg"

  # Uh oh, duplicate file!
  if File.exists?(dest_filepath)
    puts "Duplicate file name for #{dest_filepath}"

    if `md5 -q "#{filepath}"` === `md5 -q "#{dest_filepath}"`
      puts "Skipping, source and destination md5 signatures match"
    else
      dir = File.dirname(dest_filepath)
      ext = File.extname(dest_filepath)
      dest_filepath = "#{dir}/#{File.basename(dest_filepath, ext)}-#{i}#{ext}"

      puts "Giving new name #{dest_filepath}"
    end
  end

  puts "Moving to #{dest_filepath}"
  system 'mkdir', '-p', "#{dest_path}" unless File.exists?("#{dest_path}")
  system 'mv', filepath, dest_filepath

  previous_filepath = dest_filepath
  previous_data = data
end
