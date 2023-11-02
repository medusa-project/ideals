# frozen_string_literal: true

class SafUtils

  def remove_metadata_element(metadata_path, target_element)
    metadata_file_content=File.read(metadata_path)
    doc      = Nokogiri::XML(metadata_file_content)
    schema   = doc.xpath("/*/@schema").text
    schema   = "dc" if schema.blank?
    elements = {}
    doc.xpath("//dcvalue").each do |node|
      element   = node["element"]
      qualifier = node["qualifier"]
      name      = "#{schema}:#{element}"
      name     += ":#{qualifier}" if qualifier && qualifier != "none"

      elements[name]=node.text
      if name==target_element
        node.remove
        puts "Here #################"
      end
    end

    puts target_element
    File.write(metadata_path, doc)
  end

  def rename_file(path, filename, new_name)
    file_to_change=File.join(path, filename)
    File.rename(file_to_change, File.join(path, new_name))
  end

  def remove_metadata_whitespace(metadata_path)
    metadata_file_content=File.read(metadata_path)
    doc      = Nokogiri::XML(metadata_file_content)
    schema   = doc.xpath("/*/@schema").text
    schema   = "dc" if schema.blank?
    elements = {}
    doc.xpath("//dcvalue").each do |node|
      element   = node["element"]
      qualifier = node["qualifier"]
      name      = "#{schema}:#{element}"
      name     += ":#{qualifier}" if qualifier && qualifier != "none"

      elements[name]=node.text
      node.content = elements[name].strip
      if node.content.empty?
        puts "#{name} is empty so removing"
        node.remove
      end
      # if name==target_element
      #   node.remove
      #   puts "Here #################"
      # end
    end

    File.write(metadata_path, doc)

  end
  def orignal_to_content_bundle(content_path)
    content_file_text=File.read(content_path)

    content_file_text.gsub!("bundle:ORIGINAL", "bundle:CONTENT")
    puts content_file_text

    File.write(content_path, content_file_text)

  end

  def check_content_files(content_path)
    content_file_text=File.read(content_path)
    if content_file_text.include?("&")
      puts content_file_text
    end
  end

  def print_title_author(metadata_path)
    metadata_file_content=File.read(metadata_path)
    doc      = Nokogiri::XML(metadata_file_content)
    schema   = doc.xpath("/*/@schema").text
    schema   = "dc" if schema.blank?
    elements = {}
    doc.xpath("//dcvalue").each do |node|

      element   = node["element"]
      qualifier = node["qualifier"]
      name      = "#{schema}:#{element}"
      name     += ":#{qualifier}" if qualifier && qualifier != "none"
      if name=="dc:title"
        puts "title: #{node.text}"
      end
      if name=="dc:creator"
        puts "author: #{node.text}"
      end
    end

  end
end