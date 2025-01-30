#!/usr/bin/env ruby

require 'active_support/inflector'
require 'fileutils'

class String
  def sanitize_filename
    # Replace non-alphanumeric characters with underscores
    gsub(/[\/:*?"<>|\\]/, '_')
  end
end

class Splitter
  def initialize(path)
    @path = path
  end

  def run
    FileUtils.rm_rf("./data")
    Dir.mkdir("./data")

    input_str = File.read(@path)

    # Use regex to split only on lines that start and end with '**'
    sections = input_str.split(/(?=^\*\*.*?\*\*$)/m)

    # Convert into a hash or array for easier manipulation
    parsed_sections = sections.reject(&:empty?).map do |section|
      title, *content = section.split("\n", 2)
      title = title[/\*\*(.*?)\*\*/, 1] # Extract title text
      { title: title.strip, content: content.join.strip }
    end

    pages = []
    order = 1
    parsed_sections.each do |section|
      markdown = <<-TXT
---
title:  "#{section[:title]}"
layout: page
permalink: /#{section[:title].sanitize_filename}/
nav_order: #{order}
---

#{section[:content]}

      TXT

      pages << { section:, markdown:, order: }

      order += 1
    end

    pages.each do |page|
      filename = "#{page[:order]}.#{page[:section][:title].sanitize_filename}"
      File.write("./data/#{filename}.markdown", page[:markdown])
    end
  end
end

splitter = Splitter.new("./lib/in/Neuroinfectious Disease Fellowship Curriculum Guide.md")
splitter.run