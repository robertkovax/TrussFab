#!/usr/bin/env ruby

require 'csv'

def get_spring_table
  CSV.read(File.join(File.dirname(__FILE__), '../../assets/compression springs.csv'), :headers=>true, :col_sep=>";")
end

def detail_page_link_from_part_number(part_number)
  "https://www.federnshop.com/en/products/compression_springs/#{part_number}.html"
end

def price_lookup(part_number)
  require 'nokogiri'
  require 'open-uri'
  document = Nokogiri::HTML.parse(open(detail_page_link_from_part_number(part_number)))
  document.xpath("//div[@id='price']/div/div[2]/span[2]").text.gsub(" EUR", "").to_f
end

data = get_spring_table
p price_lookup(data['Part number'][700])
