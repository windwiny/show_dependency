#!/usr/bin/env ruby -w

require "tk"

unless (ARGV & ['-h', '--help']).empty?
  abort <<-EOS
  Syntax:
    #{__FILE__}  [-O]
      -O       auto create png file
  EOS
end

$auto_create_png = ARGV.delete('-O')

#---------
cls = []

Object.constants.each do |x|
  if /(Tk|Ttk)/ =~ x
    c = Object.const_get( x) rescue next
    cls << c if Class === c
  end
end
Tk.constants.each do |x|
    c= Tk.const_get( x) rescue next
    cls << c if Class === c
end
Ttk.constants.each do |x|
    c = Ttk.const_get( x)
    cls << c if Class === c
end
Tk::Tile.constants.each do |x|
    c = Tk::Tile.const_get( x)
    cls << c if Class === c
end

cls=cls.uniq.sort_by(&:name)


require "set"
ass = Set.new

cls.each do |x1|
  x1.ancestors.each_cons(2) do |x,y|
    ass << %Q{  "#{x.name}"  ->  "#{y.name}"}
  end
end

#---------
if $auto_create_png
  dotfn = "tk_cls.dot"
  o = File.open(dotfn, 'w')
  pngfn = dotfn + ".png"
else
  o = $stdout
end
o.puts "digraph G {"
o.puts ass.to_a.sort
o.puts
o.puts "}"

if pngfn
  o.close
  system "dot -Tpng -o#{pngfn} #{dotfn}"
end
