require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

class Seen < Struct.new(:who, :where, :what, :time)
  def to_s
    "[#{time.asctime}] #{who} was seen in #{where} saying #{what}"
  end
end
$users = {}

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = ["#mushin-rb"]
    c.nick     = "mushin-rb"
  end

  on :message, "help" do |m|
    m.reply "Hello #{m.user.nick}, you can always visit http://mushin-rb.github.io for information!"
  end

  helpers do
    # Extremely basic method, grabs the first result returned by Google
    # or "No results found" otherwise
    def google(query)
      url = "http://www.google.com/search?q=#{CGI.escape(query)}"
      res = Nokogiri.parse(open(url).read).at("h3.r")

      title = res.text
      link = res.at('a')[:href]
      desc = res.at("./following::div").children.first.text
    rescue
      "No results found"
    else
      CGI.unescape_html "#{title} - #{desc} (#{link})"
    end
  end

  on :message, /^!google (.+)/ do |m, query|
    m.reply google(query)
  end
  # Only log channel messages
  on :channel do |m|
    $users[m.user.nick] = Seen.new(m.user.nick, m.channel, m.message, Time.new)
  end

  on :channel, /^!seen (.+)/ do |m, nick|
    if nick == bot.nick
      m.reply "That's me!"
    elsif nick == m.user.nick
      m.reply "That's you!"
    elsif $users.key?(nick)
      m.reply $users[nick].to_s
    else
      m.reply "I haven't seen #{nick}"
    end
  end
end

bot.start
