#!/usr/bin/env ruby
# 20081114 by junegunn.c@gmail.com

vals = Hash.new { | hash, key | hash[key] = [] }

"
305737 : 2400000 : 7849 : 6900
306152 : 2600000 : 8492 : 7626
306470 : 2600000 : 8483 : 7443
306630 : 2600000 : 8479 : 7527
307427 : 2600000 : 8457 : 7778
308010 : 2600000 : 8441 : 7310
308341 : 2600000 : 8432 : 7373
309016 : 2500000 : 8090 : 7125
312689 : 2600000 : 8314 : 7514
315417 : 2600000 : 8243 : 7467
316369 : 2600000 : 8218 : 7662
316475 : 2600000 : 8215 : 7788
317090 : 2700000 : 8514 : 7831
317125 : 2600000 : 8198 : 7571
317653 : 2600000 : 8185 : 8044
"

begin
	while line = $stdin.gets
		line.strip.split(/[^-.0-9]+/).each_with_index do | v, i |
			vals[i].push v.to_f if v.match(/-?[.0-9]+/)
		end
	end
rescue Interrupt
end

sums = []
counts = []
avgs = []

def fmt(val)
	("%.2f" % val).sub(/\.00$/, '')
end

vals.keys.sort.each do | k |
	v = vals[k]
	sum = v.inject(:+)
	count = v.length
	avg = sum / count

	sum = fmt(sum)
	count = fmt(count)
	avg = fmt(avg)

	maxlen = [sum, count, avg].map { | e | e.length }.max
	sums.push("%#{maxlen}s" % sum)
	counts.push("%#{maxlen}s" % count)
	avgs.push("%#{maxlen}s" % avg)
end

exit 1 if counts.empty?

puts
puts "count #{counts.join(' ')}"
puts "sum   #{sums.join(' ')}"
puts "avg   #{avgs.join(' ')}"
puts
