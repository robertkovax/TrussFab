#!/usr/bin/env ruby

require 'csv'

def get_spring_table
  # Instructions to update the CSV

  # 1. Go to  [Gute Kunst Federshop](https://www.federnshop.com/de/produkte/druckfedern.html)
  # 2. Click on the export icon right next to "Search Results"
  # 4. Convert File to UTF-8 with your go-to Text Editor (Sublime Text)
  # 5. Place the downloaded CSV in `assets/compression_springs.csv`
  # 6. Done

  # The keys of the table can be found at https://www.federnshop.com/en/products/compression_springs/d-001.html
  # these are the columns of the csv

  # Mat EN 10270-1 - type of material
  # s2 mm Loaded spring deflection
  # L2 mm Loaded spring length
  # F2 N Loaded spring force
  # Fdn - spring ends
  # d mm Wire diameter
  # D mm Mean coil diameter
  # Dd mm maximum diameter of mandrel
  # De mm Outer coil diameter
  # Detol mm (+/-) tolerances of outer coil diameter
  # Dh 3.4 mm minimum diameter of bush
  # F1tol N (+/-) tolerance of prestressed spring force
  # F2tol N (+/-) tolerance of loaded spring force
  # Fn 0.46 N maximum force in static use
  # Fntol 0.1 N (+/-) tolerance of maximum force in static use
  # Lk mm buckling length
  # L0 7.5 mm unstressed spring length
  # L0tol 0.96 mm (+/-) tolerance of unstressed spring length
  # L1 mm Prestressed spring length
  # Ln 2.68 mm Minimum length in static use
  # s1 mm Prestressed spring deflection
  # sn 4.82 mm Maximum spring deflection in static use
  # S 1 mm pitch of spring
  # n 7 pc. number of active coils
  # nt pc. total number of coils
  # R 0.095 N/mm Spring rate
  # Fndyn 0.433 N maximum force in dynamic use
  # Fndtol 0.1 N (+/-) tolerance of maximum dynamic force
  # Lndyn 2.97 mm Minimum length in dynamic use
  # shdyn 4.53 mm Maximum stroke in dynamic use
  # Gew 0.0204 g weight of one spring
  # PG A - price group

  header_aliases = {
    "R (N/mm)" => "k",
    "n (pc.)" => "windings",
    "Lndyn (mm)" => "min length",
    "L0 (mm)" => "unstreched length",
    "Gew (g)" => "weight",
    "Lk (mm)" => "buckling length",
    "d (mm)" => "wire diameter",
    "D (mm)" => "coil diameter",
  }

  table = CSV.read(File.join(File.dirname(__FILE__), '../../assets/compression_springs.csv'),
    :headers => true, :col_sep => ";", :converters => :numeric, :header_converters => lambda { |name| header_aliases[name] })

  # table = table.select{ |row| 10 < row['k'] > 100 }

  return table
end

def price_lookup(part_number)
  # TODO if needed the pricing table can be also used instead of the online lookup
  # https://www.federnshop.com/download/pdf/gutekunst_federn_preisliste_eu_12_d.pdf
  require 'nokogiri'
  require 'open-uri'
  document = Nokogiri::HTML.parse(open("https://www.federnshop.com/en/products/compression_springs/#{part_number}.html"))
  document.xpath("//div[@id='price']/div/div[2]/span[2]").text.gsub(" EUR", "").to_f
end

yo = get_spring_table
p yo["k"]
