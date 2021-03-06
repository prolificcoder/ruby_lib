# encoding: utf-8

require 'rubygems'
require 'yard'

def space amount
 '&nbsp;' * amount
end

def last_sha
  `git rev-parse --verify HEAD`.strip
end

def mobj_to_md obj
  out = ''
  # skip objects without method signatures
  sig = obj.signature
  return out unless sig

  # skip class vars
  if sig.start_with?('@@') ||
     # skip methods marked private
     obj.tag('private') ||
     # skip date and version from version.rb
     obj.name.match(/DATE|VERSION/)
     return out 
  end

  method_path = obj.file.split('/lib/').last
  os = method_path.downcase.match /ios|android/
  out += "##### [#{obj.name.to_s}](https://github.com/appium/ruby_lib/blob/#{last_sha}/lib/#{method_path}#L#{obj.line}) #{os}\n\n"
  out += "> #{obj.signature}\n\n"
  out += "#{obj.docstring}\n\n"


  indent = space 5
  params = obj.tags.select { |tag| tag.tag_name == 'param' }
  if !params.empty?
    out += "__Parameters:__\n\n"
    params.each do |param|
      out += indent + "[#{param.types.join ', '}] "
      out += "#{param.name} - #{param.text}\n\n"
    end
  end

  ret = obj.tag 'return'
  if ret
    out += "__Returns:__\n\n"
    out += indent + "[#{ret.types.join ', '}] #{ret.text}\n\n"
  end
  out += "--\n\n"

  out
end

def run out_file, globs
  YARD::Registry.clear
  puts "Globbing: #{globs}"
  puts "Writing: #{out_file}"
  YARD::Parser::SourceParser.parse globs
  File.open(out_file, 'w') do | file |
    YARD::Registry.entries.each do | entry |
      file.write mobj_to_md entry
    end
  end
end

def globs paths
  # Convert single string to array for map
  paths = [ paths ] unless paths.kind_of? Array
  # Adjust path based on system
  paths.map! { |path| "#{ENV['HOME']}/Desktop/appium/ruby_lib#{path}" }
end

common_globs = '/lib/appium_lib/*.rb', '/lib/appium_lib/common/**/*.rb'
android_globs = common_globs + [ '/lib/appium_lib/android/**/*.rb' ]
ios_globs = common_globs + [ '/lib/appium_lib/ios/**/*.rb' ]

run 'docs/android_docs.md', globs(android_globs)

run 'docs/ios_docs.md', globs(ios_globs)