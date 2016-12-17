require 'rss'
require 'open-uri'
require 'yaml'
require 'net/https'
require './settings'

# remove html
def sanitize s
  s = s.to_s.gsub( %r{</?[^>]+?>}, '' )
  s = s.sub! '/&gt;', ''
  s = s.sub! '&lt;', ''
  s = s.sub! " \n", ''
  s = s.gsub /&amp;amp;/, '&'
end

# comic class from csv
class Comic
  attr_accessor :date, :publisher, :name, :price
  def initialize(csv)
    data = sanitize(csv).split(',')
    @date = data[0]
    @publisher = data[1]
    @name = data[2]
    @price = data[3]
  end
  def to_s
    s = @name
  end
end

# pushover notification
def pushover(apptoken, usertoken, message)
  puts
  puts 'Responding via pushover.'
  url = URI.parse("https://api.pushover.net/1/messages.json")
  req = Net::HTTP::Post.new(url.path)
  req.set_form_data({
                        :token => apptoken,
                        :user => usertoken,
                        :message => message,
                    })
  res = Net::HTTP.new(url.host, url.port)
  res.use_ssl = true
  res.verify_mode = OpenSSL::SSL::VERIFY_PEER
  res.start {|http| http.request(req) }
end

# weekly comic feed
url = 'http://feeds.feedburner.com/ncrl?format=xml'

# pull list of comics
pull = File.read('pull.txt').split("\n").map(&:downcase)

# found comics
comics = []

# wednesday
wednesday = ''

open(url) do |rss|
  # parse RSS
  feed = RSS::Parser.parse(rss)

  print 'Comics release on '

  # crazy-ass parsing to get Wednesday of this week
  wednesday = (Date.today - (Date.today.wday - (Date.today.wday + 5) % 7).abs).strftime("%m/%d/%Y")

  # first item is this week
  feed.items.each do |item|

    # split per row
    item.to_s.split('br').each do |row|

      # looking only for numbered issues (not tradeback (TP) or AR merchandise)
      # remove the + ' #' if you want to allow less 'full titles'
      #   for example, 'Star Wars' will pick up seoncary comics like 'Star Wars: Han Solo'
      #   with the space #, it'll only pick up strictly 'Star Wars #' comics of that single series
      if row.include? '#' and row.include? '$' and pull.any?{ |c| row.downcase.include? c + ' #' }

        # add comic
        comic = Comic.new(row)
        comics.push(comic)

        # remove from pull (prevents dupes, usually from variants)
        pull.delete_if{|c| comic.name.downcase.include? c.downcase}
      end
    end
    break;
  end
end

# sort and print
comics = comics.sort_by { |c| [-c.name] }

# create message
message = "Comics released on '#{wednesday}'\n"
comics.each do |c|
  message += c.to_s
  message += "\n"
end

# display message
message = message.chomp("\n")
puts message

# if pushover setting exists, respond via pushover
settings = Settings.new
if !settings.list['pushover'].nil?
  apitoken = settings.list['pushover']['apitoken']
  usertoken = settings.list['pushover']['userkey']
  pushover(apitoken, usertoken, message)
end