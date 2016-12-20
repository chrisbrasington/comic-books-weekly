#!/usr/bin/env ruby
require 'rss'
require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'net/https'
require './settings'

# remove html
def sanitize s
   s = Nokogiri::HTML(s).text
   s = s.gsub(/\(.*\)/, "")
end

# comic class from csv
class Comic
  attr_accessor :name, :price
  def initialize(csv)
    data = sanitize(csv).split(',')
    @name = data[0].chomp(' ')
    @price = data[1].delete(' ')
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

# 0 - Sunday
# 1 - Monday
# 2 - Tuesday 
# 3 - Wednesday
# 4 - Thursday
# 5 - Friday
# 6 - Saturday
def get_wednesday 
  # Wednesday
  if Date.today.wday == 3
    return Date.today
  end
  # add if Sunday, Monday, Tuesday
  if(Date.today.wday < 3)
    return Date.today + (3 - Date.today.wday)
  end
  
  # subtract if Thursday, Friday, Saturday
  return Date.today - (Date.today.wday - 3)
end

# parse a week of comic content
def parse_feed_item(item, pull)
  # found comics
  comics = []

  # clean up item
  item = Nokogiri::HTML(item.to_s).text.to_s
  item = item.gsub("\n",'')

  # split per row
  item.to_s.split('<br />').each do |row|

    # looking only for numbered issues (not tradeback (TP) or AR merchandise)
    # remove the + ' #' if you want to allow less 'full titles'
    #   for example, 'Star Wars' will pick up seoncary comics like 'Star Wars: Han Solo'
    #   with the space #, it'll only pick up strictly 'Star Wars #' comics of that single series
    if row.include? '#' and row.include? '$' and pull.any?{ |c| row.to_s.downcase.include? c + ' #' }
    
      # add comic
      comic = Comic.new(row.to_s)
      comics.push(comic)

      # remove from pull (prevents dupes, usually from variants)
      pull.delete_if{|c| comic.name.downcase.include? c.downcase}
    end
  end
  # sort and print
  comics = comics.sort_by { |c| [-c.name] }
  
  return comics
end

# weekly comic feed
url_this_week = 'http://feeds.feedburner.com/comiclistfeed?format=xml'

# next weeks comic feed
url_next_week = 'http://feeds.feedburner.com/comiclistnextweek?format=xml'

# pull list of comics
pull = File.read('/home/christopher/repo/comic-books-weekly/pull.txt').split("\n").map(&:downcase)

# comics released every Wednesday
wednesday = get_wednesday()

# first check this week feed (includes last week)
# next check next weeks feed
feed = ''

# this week
open(url_this_week) do |rss|
  # parse RSS
  feed = RSS::Parser.parse(rss)
end

# pushover message
full_message = ''

# parse this week, then last week
iterations = 0
feed.items.each do |item|
  
  comics = parse_feed_item(item, pull)

  # wednesday
  message = "(#{wednesday.strftime("%m/%d/%Y")})\n"

  # this week or next week  
  if iterations == 0
    message = 'This Week ' + message
  elsif iterations == 1
    message = 'Last Week ' + message
  end
  
  # add each comic to message
  comics.each do |c|
    message += c.to_s
    message += "\n"
  end

  # display
  puts message
  puts
  
  # go back a week (if continuing in feed
  wednesday = wednesday - 7
  iterations = iterations +1

  # append message  
  full_message += message
  full_message += "\n"
end

# next week feed
open(url_next_week) do |rss|
  # parse RSS
  feed = RSS::Parser.parse(rss)
end

# parse next week
feed.items.each do |item|
  comics = parse_feed_item(item, pull)
  
  message = 'Next Week '
  message = message + "(#{(get_wednesday()+7).strftime("%m/%d/%Y")})\n"
    
  # add each comic to message
  comics.each do |c|
    message += c.to_s
    message += "\n"
  end
  
  # display
  puts message
  
  # append message
  full_message += message
  
  # break we've already checked prior weeks
  break;

end

# if pushover setting exists, respond via pushover
settings = Settings.new
if !settings.list['pushover'].nil?
  apitoken = settings.list['pushover']['apitoken']
  usertoken = settings.list['pushover']['userkey']
  pushover(apitoken, usertoken, full_message)
end
