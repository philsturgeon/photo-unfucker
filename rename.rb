require "bundler"
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
previous_datetime = previous_filepath = nil

Dir.glob("#{importFolder}/**/*.{jpg,jpeg,JPG,JPEG,heic,HEIC}") do |filepath|
  i += 1

  fileext = File.extname(filepath).downcase

  puts "\nLoading #{filepath}"
  
  exif_date = `exiftool -DateTimeOriginal \"#{filepath}\" | awk '{ print $4 " " $5 }'`
  
  if exif_date == ""
    
    if !previous_filepath
      puts "Skipping: Couldn't find the date time"
      next
    end

    puts "Missing EXIF data, lets try this another way... \n\n"
    system "imgcat \"#{previous_filepath}\""
    puts "...aaaand..."
    system "imgcat \"#{filepath}\""

    puts "Does it look like these two photos are relevatively close together chronolocically (Y/n), or you can skip (s), or just delete the one at the bottom (d)? [Y/n/s/d]"
    
    answer = STDIN.gets.strip.downcase
    if answer == "d"
      puts "Deleting photo entirely. Screw it!"
      system 'rm', filepath
      next

    elsif answer == "y"
      puts "answered! #{answer}"
      date_time = previous_datetime

    else
      # Clearly we've moved on in time
      previous_datetime = previous_filepath = nil
      puts "Skipping: Meh entering a date here would be annoying so just figure it out yourself"
      next
    end

  else
    # Maybe its this format: 2018:07:15 12:16:59
    begin
      date_time = DateTime.strptime(exif_date, '%Y:%m:%d %H:%M:%S')
    
      # maybe its this format: 2018-04-29 11:48:45
    rescue ArgumentError
      date_time = DateTime.strptime(exif_date, '%Y-%m-%d %H:%M:%S')
    end
  end

  folder = date_time.strftime('%Y/%Y-%m')
  dest_basename = "#{date_time.strftime('%Y-%m-%d %H-%M-%S')}#{fileext}"
  dest_path = "#{exportFolder}/#{folder}"
  dest_filepath = "#{dest_path}/#{dest_basename}"

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
  previous_datetime = date_time
end
