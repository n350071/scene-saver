require 'mechanize'
require 'pry'
require 'pry-byebug'
require "json"

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
  body.each{|e| picture_list << {id: e['id'], name: e['date_taken'], caption: e['caption']}}
  offset += bulk_size
  puts offset
  offset = 1000000000000 if body.size == 0
  sleep 1
end

# 10世代ほど覚えておく
file_names = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]

# Download the pictures
Dir.chdir 'download' do
  picture_list.each.with_index(1) do |pic, idx|
    file_name = pic[:caption].empty? ? "#{pic[:name]}.png" : "#{pic[:name]}_#{pic[:caption]}.png"
    if file_name.length > 220
      file_name = file_name[0..220] + ".png"
    end

    # 同一ファイル名になってしまうときの対策（適当）
    if file_names.include?(file_name)
      file_name = file_name[0..-5] + '_' + (1..10000).to_a.sample.to_s + ".png"
    end

    mechanize.get("https://a.scn.jp/priv/#{ALBUM_URL}/photos/#{pic[:id]}/img/p").save("#{file_name}")

    # ファイル名の記憶の世代交代
    file_names.shift
    file_names.push(file_name)

    time = Time.new(pic[:name][0,4],pic[:name][4,2],pic[:name][6,2],pic[:name][8,2],pic[:name][10,2],pic[:name][12,2])

    File.utime(time, time, "#{file_name}")
    sleep 0.05
    system "clear"
    puts  "progress: #{idx} / #{picture_list.size}"
  end
end

system "clear"
puts  "🎉 Finish"
