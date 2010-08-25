green  = "\033[0;32m"
white  = "\033[0;37m" 
red    = "\033[0;31m"
yellow = "\033[0;33m"
blue   = "\033[0;34m"

current_branch = `git branch 2>/dev/null`.lines.grep(/^\*/).first

if current_branch
  rails_version = ENV["GEM_HOME"] =~ /rails2/ ? "#{yellow}[rails 2]" : "#{green}[rails 3]"
  ruby_version = "#{`rvm-prompt i v`.split.first}"

  branch_name = current_branch.gsub(/^\*\s*/,'').strip
  color = branch_name  =~ /master/ ? green : red
  puts "#{color}[#{branch_name}] #{blue}[#{ruby_version}] #{rails_version}#{white}" unless current_branch.empty?
end

