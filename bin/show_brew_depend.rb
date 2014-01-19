#!/usr/bin/env ruby -w

require "set"

unless (ARGV & ['-h', '--help']).empty?
  abort <<-EOS
  Syntax:
    #{__FILE__}  [-O]
      -O       auto create png file
  EOS
end

$auto_create_png = ARGV.delete('-O')

#---------
COLOR_MISSING = 'red'
COLOR_NODEP = 'green'
COLOR_NOTE = 'brown'

pgs = %x{brew list}.split.sort
gr_edges = Set.new
node_deps = Set.new

pgs.each do |pg|
  deps = %x{brew deps --1 #{pg}}.split rescue next
  node_deps += deps
  deps.each do |x|
    gr_edges << %Q{  "#{pg}" -> "#{x}"}
  end
end
gr_edges = gr_edges.to_a.sort
node_deps = node_deps.to_a.sort

gr_indep_nodes = (pgs - node_deps).map { |x| %Q{  "#{x}"  [color=#{COLOR_NODEP}]} }
gr_mis_nodes = (node_deps - pgs).map { |x| %Q{  "#{x}"  [color=#{COLOR_MISSING}]} }
 
msg = "Program Count: #{pgs.size}.   Independed: #{gr_indep_nodes.size};  Missed: #{gr_mis_nodes.size}"
gr_box_summary = %Q{  summary [shape=note, color=#{COLOR_NOTE}, label="#{msg}"]}
#---------


if $auto_create_png
  dotfn = "#{File.basename(__FILE__, '.rb')}_#{Time.now.strftime '%Y%m%d%H%M%S'}.dot"
  o = File.open(dotfn, 'w')
  pngfn = dotfn + ".png"
else
  o = $stdout
end
o.puts "digraph G {"
o.puts gr_box_summary
o.puts
o.puts gr_edges
o.puts
o.puts gr_indep_nodes
o.puts
o.puts gr_mis_nodes
o.puts
o.puts "}"

if pngfn
  o.close
  system "dot -Tpng -o#{pngfn} #{dotfn}"
end
