require "faraday"
require "nokogiri"

require "subscene/version"
require "subscene/error"
require "subscene/response"
require "subscene/response/raise_error"
require "subscene/response/html"
require "subscene/subtitle_result_set"
require "subscene/subtitle"

module Subscene

  # Subscene.com is a very complete and reliable catalog of subtitles.
  # If you're reading this you probably know they don't have an API.
  #
  # This gem will help you communicate with Subscene.com easily.
  #
  # == Searches
  #
  # Subscene.com handles two kinds of searches:
  #
  #   a) Search by Film or TV Show 'title'
  #   e.g. "The Big Bang Theory", "The Hobbit", etc.
  #
  #   b) Search for a particular 'release'
  #   e.g. "The Big Bang Theory s01e01" or "The Hobbit HDTV"
  #
  # There are certain keywords that trigger one search or the other,
  # this gem initially will support the second type (by release)
  # so make sure to format your queries properly.
  #
  extend self

  ENDPOINT     = "https://subscene.com"
  RELEASE_PATH = "subtitles/release"

  # Public: Search for a particular release.
  #
  # query - The String to be found.
  #
  # Examples
  #
  #   Subscene.search('The Big Bang Theory s01e01')
  #   # => [#<Subscene::SubtitleResult:0x007feb7c9473b0
  #     @attributes={:id=>"136037", :name=>"The.Big.Bang.Theory.."]
  #
  # Returns the Subtitles found.
  def self.search(query=nil)
    params = { q: query, l: '', r: true } unless query.nil?
    params ||= {}

    response = connection.get do |req|
      req.url RELEASE_PATH, params
      req.headers['Cookie'] = "LanguageFilter=#{@lang_id};" if @lang_id
    end

    html = response.body
    SubtitleResultSet.build(html).instances
  end

  # Public: Find a subtitle by id.
  #
  # id - The id of the subtitle.
  #
  # Examples
  #
  #   Subscene.find(136037)
  #   # => TODO: display example result
  #
  # Returns the complete information of the Subtitle.
  def self.find(id)
    response = connection.get(id.to_s)
    html     = response.body

    subtitle = Subtitle.build(html)
    subtitle.id = id
    subtitle
  end
  def self.endpoint_url
    ENDPOINT
  end

  # Public: Find a subtitle by id.
  #
  # id - The id of the subtitle.
  #
  # Examples
  #
  #   Subscene.find(136037)
  #   # => TODO: display example result
  #
  # Returns the complete information of the Subtitle.
  def self.findUrl(id, url)
    params = {}
    response = connection.get do |req|
      req.url url, params
      req.headers['Cookie'] = "LanguageFilter=#{@lang_id};" if @lang_id
    end
    html     = response.body

    subtitle = Subtitle.build(html)
    subtitle.id = id
    subtitle
  end

  # Public: Set the language id for the search filter.
  #
  # lang_id - The id of the language. Maximum 3, comma separated.
  #           Ids can be found at http://subscene.com/filter
  #
  # Examples
  #
  #   Subscene.language = 13 # English
  #   Subscene.search("...") # Results will be only English subtitles
  #   Subscene.language = "13,38" # English, Spanish
  #   ...
  #
  def language=(lang_id)
    @lang_id = lang_id
  end
  def language_name=(lang_name)
    if lang_name.match(",")
      lang_array=lang_name.split(",")
      ret=[]
      lang_array.each do |l|
        ret<<languages_ids(l) unless languages_ids(l).nil?
      end
      @lang_id=ret.join(",")
    else
      @lang_id = languages_ids(lang_name)    
    end
  end
  def self.lang_id
    @lang_id
  end


  private

  def connection
    @connection ||= Faraday.new(url: ENDPOINT) do |faraday|
      faraday.response :logger if ENV['DEBUG']
      faraday.adapter  Faraday.default_adapter
      faraday.use      Subscene::Response::HTML
      faraday.use      Subscene::Response::RaiseError
    end
  end


  def languages_ids(name)
    langs = { "Arabic" => 2 , "Brazillian Portuguese" => 4 , "Danish" => 10, "Dutch" => 11, "English" => 13, "Farsi/Persian" => 46, "Finnish" => 17, "French" => 18, "Greek" => 21, "Hebrew" => 22, "Indonesian" => 44, "Italian" => 26, "Korean" => 28, "Malay" => 50, "Norwegian" => 30, "Portuguese" => 32, "Romanian" => 33, "Spanish" => 38, "Swedish" => 39, "Turkish" => 41, "Vietnamese" => 45, "Albanian" => 1 , "Armenian" => 73, "Azerbaijani" => 55, "Basque" => 74, "Belarusian" => 68, "Bengali" => 54, "Big 5 code" => 3, "Bosnian" => 60, "Bulgarian" => 5 , "Bulgarian/ English" => 6 , "Burmese" => 61, "Cambodian/Khmer" => 79, "Catalan" => 49, "Chinese BG code" => 7 , "Croatian" => 8 , "Czech" => 9 , "Dutch/ English" => 12, "English/ German" => 15, "Esperanto" => 47, "Estonian" => 16, "Georgian" => 62, "German" => 19, "Greenlandic" => 57, "Hindi" => 51, "Hungarian" => 23, "Hungarian/ English" => 24, "Icelandic" => 25, "Japanese" => 27, "Kannada" => 78, "Kurdish" => 52, "Latvian" => 29, "Lithuanian" => 43, "Macedonian" => 48, "Malayalam" => 64, "Manipuri" => 65, "Mongolian" => 72, "Nepali" => 80, "Pashto" => 67, "Polish" => 31, "Punjabi" => 66, "Russian" => 34, "Serbian" => 35, "Sinhala" => 58, "Slovak" => 36, "Slovenian" => 37, "Somali" => 70, "Sundanese" => 76, "Swahili" => 75, "Tagalog" => 53, "Tamil" => 59, "Telugu" => 63, "Thai" => 40, "Ukrainian" => 56, "Urdu" => 42, "Yoruba" => 71 }
    if langs.has_key?(name)
      langs[name]
    else
      nil
    end

  end
end
