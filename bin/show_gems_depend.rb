#!/usr/bin/env ruby -w

require "set"

unless (ARGV & ['-h', '--help']).empty?
  abort <<-EOS
  Syntax:
    #{__FILE__}  [--dev]  [-O]
      --dev    show development dependency
      -O       auto create png file
  EOS
end

$create_development = ARGV.delete('--dev')
$auto_create_png = ARGV.delete('-O')

COLOR_MISSING = 'red'
COLOR_NODEP = 'green'
COLOR_DEVELOPMENT = 'blue'
COLOR_NOTE = 'brown'

gr_edges = Set.new
node_all = Set.new
node_in_left = Set.new
node_in_right = Set.new

def find_latest_gem(dependency)
  $gems ||= Gem::Specification.group_by { |spec| spec.name }
  gems = $gems[dependency.name]
  return if !gems

  gems.reverse.find do |spec|
    dependency.matches_spec?(spec)
  end
end


Gem::Specification.each do |spec|
  namever = %Q{"#{spec.name}-#{spec.version}"}
  node_all << namever
  spec.dependencies.each do |d|
    if d.type == :runtime
      g1 = find_latest_gem(d)
      if g1
        dep_namever = %Q{"#{g1.name}-#{g1.version}"}
        node_in_left << namever
        node_in_right << dep_namever
        gr_edges << "  #{namever} -> #{dep_namever}"
      else
        req_list = %Q{"#{d.name}\\n#{d.requirement.as_list.to_s.gsub '"', '\"'}"}
        gr_edges << "  #{namever} -> #{req_list}  [color=#{COLOR_MISSING}]"
      end
    elsif d.type == :development && $create_development != nil
      g1 = find_latest_gem(d)
      if g1
        dep_namever = %Q{"#{g1.name}-#{g1.version}"}
        node_in_left << namever
        node_in_right << dep_namever
        gr_edges << "  #{namever} -> #{dep_namever}  [color=#{COLOR_DEVELOPMENT}]"
      else
        req_list = %Q{"#{d.name}\\n#{d.requirement.as_list.to_s.gsub '"', '\"'}"}
        gr_edges << "  #{namever} -> #{req_list}  [color=#{COLOR_MISSING}]"
      end
    end
  end
  
end

=begin
  a -> b
  b -> c
  a -> d

  all   = a b c d e
  left  = a b
  right =   b c d 

  [a] == all & left - right # indep_node1
  [e] == all - left - right # indep_node2
=end
gr_indep_nodes1 = (node_all&node_in_left-node_in_right).to_a.sort.map { |x| "  #{x}  [color=#{COLOR_NODEP}]" }
gr_indep_nodes2 = (node_all-node_in_left-node_in_right).to_a.sort# .map { |x| "  #{x}  [shape=box, color=#{COLOR_NODEP}]" }

tmp1 = []
tmp1 << "color=#{COLOR_NODEP}    independent gems"
tmp1 << "color=#{COLOR_MISSING}  missed gems"
tmp1 << "color=#{COLOR_DEVELOPMENT}  development dependent gems"
msg = tmp1.join("\\n")
gr_box_readme =      %Q{  readme  [shape=note, color=#{COLOR_NOTE}, label="README\\n#{msg}"]}

msg = node_in_right.to_a.sort.join("\\n").gsub('"', '')
gr_box_deped_nodes = %Q{  deped_nodes  [shape=box, color=#{COLOR_NODEP}, fontsize=8, label="DEPED_NODES\\n#{msg}"]}

msg = gr_indep_nodes2.join("\\n").gsub('"', '')
gr_box_indep_nodes = %Q{  indep_nodes  [shape=box, color=#{COLOR_NODEP}, fontsize=8, label="INDEP_NODES\\n#{msg}"]}


if $auto_create_png
  dotfn = "#{File.basename(__FILE__, '.rb')}_#{Time.now.strftime '%Y%m%d%H%M%S'}.dot"
  o = File.open(dotfn, 'w')
  pngfn = dotfn + ".png"
else
  o = $stdout
end
o.puts "digraph G {"
o.puts gr_box_deped_nodes
o.puts gr_box_indep_nodes
o.puts "  #{(0..9).to_a.join(' -> ')} -> deped_nodes -> indep_nodes"
o.puts
o.puts gr_box_readme
o.puts
o.puts gr_edges.to_a.sort
o.puts
o.puts gr_indep_nodes1
o.puts
o.puts "}"

if pngfn
  o.close
  system "dot -Tpng -o#{pngfn} #{dotfn}"
end
