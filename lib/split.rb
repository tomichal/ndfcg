#!/usr/bin/env ruby

require 'active_support/inflector'
require 'fileutils'
require 'byebug'

class String
  def sanitize_filename
    # Replace non-alphanumeric characters with underscores
    gsub(/[\/:*?"<>|\\]/, '_')
  end
end

class Splitter
  RESOURCES = {}

  def initialize(path)
    @path = path

    RESOURCES["DIAGNOSTIC TESTING"] = {
      "Lectures" => ["AAN_Part 2_2024.pdf"],
      "Seminal Articles" => ["Ramachandan_et_al.pdf"],
      "External Links" => ["https://nextgendiagnostics.ucsf.edu/providers/"]
    }
  end

  def run
    FileUtils.rm_rf("./data")
    Dir.mkdir("./data")

    parent_pages = extract_pages(File.read(@path), /(?=^\*\*.*?\*\*$)/m)

    parent_pages.each do |parent_page|
      if RESOURCES[parent_page[:section][:title]].nil?
        RESOURCES[parent_page[:section][:title]] = {
          'Lectures' => ['...'],
          'Seminal Articles' => ['...'],
          'External Links' => ['...']
        }
      end

      parent_filename = "#{parent_page[:order]}.#{parent_page[:section][:title].sanitize_filename}"
      Dir.mkdir("./data/#{parent_filename}")

      child_pages = extract_pages(parent_page[:section][:content], /(?=^\d\..*?$)/m, parent_page)

      child_pages.each do |child_page|
        filename = child_page[:section][:title] == parent_page[:section][:title] ? "index" : "#{child_page[:order]}.#{child_page[:section][:title].sanitize_filename}"

        File.write("./data/#{parent_filename}/#{filename}.markdown", child_page[:markdown])

        puts child_page[:markdown]
      end
    end
  end

  private

  def extract_pages(input_str, regexp, parent = nil)
    # Use regex to split only on lines that start and end with '**'
    sections = input_str.split(regexp)

    # Convert into a hash or array for easier manipulation
    parsed_sections = sections.reject(&:empty?).map do |section|
      title, *content = section.split("\n", 2)
      # byebug if parent.nil?
      # title = title[/\*\*(.*?)\*\*/, 1] # Extract title text

      title = title.strip.gsub(/(\*\*)/, "").gsub(/:$/, "")

      content = content.join.strip
      content = content.gsub(/^(\s\s\s)/m, "") if parent

      { title: title.strip, content: content }
    end

    pages = []
    order = 1
    parsed_sections.each do |section|
      markdown = <<-TXT
---
title:  "#{section[:title]}"
#{parent ? "parent: #{parent[:section][:title]}" : nil }
layout: page
permalink: /#{section[:title].sanitize_filename}/
nav_order: #{order}
---

**#{section[:title]}**

#{section[:content]}

      TXT

      pages << { section:, markdown:, order: }

      order += 1
    end

    if parent
      markdown = <<-TXT
---
title: #{parent[:section][:title]}
layout: page
permalink: /#{parent[:section][:title].sanitize_filename}/
nav_order: #{parent[:order]}
---

# #{parent[:section][:title]}     
      TXT

      resoures = Splitter::RESOURCES[parent[:section][:title]]

      if resoures
        resources_md = <<-TXT
#{
  resoures.map do |k, v|
    "### #{k}\n{: .text-delta}\n#{v.map do |name|
      if name.match?(/^http/)
        url = name
      else
        url = "{{ site.baseurl }}/downloads/#{name}"
      end
      "* [#{name}](#{url}){: target='_blank' }"
    end.join("\n")}"
  end.join("\n\n")
}
        TXT
        markdown = "#{markdown}\n#{resources_md}"
      end

      pages << { section: { title: parent[:section][:title] }, markdown: markdown, order: parent[:order] }
    end

    pages
  end
end

splitter = Splitter.new("./lib/in/Neuroinfectious Disease Fellowship Curriculum Guide.md")
splitter.run