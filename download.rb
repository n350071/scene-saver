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
picture_id_list = []
body = nil
offset = 0
bulk_size = 1000
while offset < 2000
  body = JSON.parse(mechanize.get("https://a.scn.jp/priv/#{ALBUM_URL}/ajax/photos?f=#{offset}&n=#{bulk_size}&s=defaultSort").body)
  body.each{|e| picture_id_list << e['id']}
  offset += bulk_size
  puts offset
  offset = 1000000000000 if body.size == 0
  sleep 1
end

# Download the pictures
Dir.chdir 'download' do
  picture_id_list.each.with_index(1) do |id, idx|
    mechanize.get("https://a.scn.jp/priv/#{ALBUM_URL}/photos/#{id}/img/p").save("#{id}.png")
    sleep 0.1
    system "clear"
    puts  "progress: #{idx} / #{picture_id_list.size}"
  end
end

system "clear"
puts  "🎉 Finish"
