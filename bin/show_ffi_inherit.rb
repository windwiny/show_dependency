#!/usr/bin/env ruby -w

require "ffi"
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
cls = FFI.constants.uniq.select{ |x| x !~ /Error/i }
      .map { |x|
        m=FFI.module_eval(x.to_s)
        m.class == Class && x.to_s == m.name.split('::')[-1] ? m : nil
      }.compact.sort_by { |x| x.name }

cls.sort_by! { |x| [x.ancestors.size, x.ancestors[1..-1].to_s] }

gr_edges = Set.new
gr_mods = Set.new
cls.each do |cl1|
    ances = cl1.ancestors
    ances.select { |x| x.class == Class }.each_cons(2) do |x, y|
      gr_edges << "  #{format '%-22s', x.name.split('::')[-1]}  ->  #{y.name.split('::')[-1]}"
    end
    ances[1..-1].each do |m|
      break if m.class == Class
      gr_edges << "  #{format '%-22s', cl1.name.split('::')[-1]}  ->  #{m.name.split('::')[-1]}  [color=green]"
      gr_mods << "  #{m.name.split('::')[-1]} [color=green]"
    end
end

gr_most_use = %w{MemoryPointer Struct Union Enums Buffer }.map { |x| "  #{x}  [color=blue]" }
#---------


if $auto_create_png
  dotfn = "ffi_cls.dot"
  o = File.open(dotfn, 'w')
  pngfn = dotfn + ".png"
else
  o = $stdout
end
o.puts "digraph G {"
o.puts gr_edges.to_a.sort
o.puts
o.puts gr_mods.to_a.sort
o.puts
o.puts gr_most_use
o.puts
o.puts "}"

if pngfn
  o.close
  system "dot -Tpng -o#{pngfn} #{dotfn}"
end

