green  = "\033[0;32m"
white  = "\033[0;37m" 
red    = "\033[0;31m"
yellow = "\033[0;33m"
blue   = "\033[0;34m"

current_branch = `git branch 2>/dev/null`.lines.grep(/^\*/).first

if current_branch
  branch_name = current_branch.gsub(/^\*\s*/,'').strip
  color = branch_name  =~ /master/ ? green : red
  puts "#{color}[branch: #{branch_name}]" unless current_branch.empty?
end

