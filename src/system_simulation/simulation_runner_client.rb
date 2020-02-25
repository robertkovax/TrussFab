#!/usr/bin/env ruby

require 'net/http'
require "uri"

uri = URI.parse("http://localhost:8080/get_period")
Net::HTTP.get_print(uri)
