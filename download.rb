require 'mechanize'
require 'pry'
require 'pry-byebug'

# Read the .env file and set constants
File.foreach('.env') do |line|
  key, value =  line.strip.split('=')
  eval "#{key}='#{value}'"
end

# Login to the Scene
mechanize = Mechanize.new
login_page = mechanize.get("https://a.scn.jp/priv/#{ALBUM_URL}")
login_form = login_page.form
login_form.field_with(id: 'password').value = PASSWORD
page = mechanize.submit(login_form)

# GET the list of the picture ids
picture_list = []
body = nil
offset = 0
bulk_size = 1000
while offset < 2000
  body = JSON.parse(mechanize.get("https://a.scn.jp/priv/#{ALBUM_URL}/ajax/photos?f=#{offset}&n=#{bulk_size}&s=defaultSort").body)
  body.each{|e| picture_list << {id: e['id'], name: e['date_taken']}}
  offset += bulk_size
  puts offset
  offset = 1000000000000 if body.size == 0
  sleep 1
end

# Download the pictures
Dir.chdir 'download' do
  picture_list.each.with_index(1) do |pic, idx|
    mechanize.get("https://a.scn.jp/priv/#{ALBUM_URL}/photos/#{pic[:id]}/img/p").save("#{pic[:name]}.png")
    time = Time.new(pic[:name][0,4],pic[:name][4,2],pic[:name][6,2],pic[:name][8,2],pic[:name][10,2],pic[:name][12,2])
    File.utime(time, time, "#{pic[:name]}.png")
    sleep 0.1
    system "clear"
    puts  "progress: #{idx} / #{picture_list.size}"
  end
end

system "clear"
puts  "🎉 Finish"
