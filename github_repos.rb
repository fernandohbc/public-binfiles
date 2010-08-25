#!/usr/bin/env ruby
#
# Brute-force way to retrieve all Github's repositories at once
# Usage:
#   github_repos.rb clone # will clone all the user's repositories
#   github_repos.rb clone test # will just clone 6 repositories for testing purposes
#   github_repos.rb pull # will update all of the user's local repositories
#
# If you have forked repositories, the original sources will be added
# as remotes with the default 'forked_from' name, and a new 'forked_from'
# branch will also be created.
#
# This naming convention is also used in the "pull" task, where it will update
# the original remote sources
#
# Author: Fabio Akita (www.akitaonrails.com)
require 'rubygems'
require 'httparty'
require 'mechanize'

class Github
  include HTTParty
  base_uri "http://github.com/api/v2/yaml"
  attr_reader :config
  attr_accessor :orig_repos_cache

  # very opinionated way to clone all github repos
  def self.mass_clone(is_test = nil)
    raise "Couldn't find folder 'public'" unless File.exists?("./public")
    raise "Couldn't find folder 'watched'" unless File.exists?("./watched")
    github = Github.new

    puts "Loading public repositories ..."
    repos = github.repositories
    puts "Going to clone #{repos.size} public repositories."
    repos = repos[0..6] if is_test
    repos.each do |repo|
      local_path = File.join('.', 'public', repo[:name])
      puts "Cloning #{repo[:url]}"
      unless File.exists?(local_path)
        `git clone #{github.git_url(repo[:url], true)} #{local_path}`
        if repo[:original_repository]
          puts "Adding Remote #{repo[:original_repository][:url]}"
          `cd #{local_path} ; git remote add forked_from #{github.git_url(repo[:original_repository][:url])}`
          `cd #{local_path} ; git fetch forked_from && git checkout -b forked_from remotes/forked_from/master && git checkout master`
          if File.exists?(File.join(local_path, ".gitmodules"))
            puts "Initializing submodules for #{repo[:original_repository][:url]}"
            `cd #{local_path} ; git submodule init; git submodule update`
          end
        end
      end
    end

    puts "Loading watched repositories ..."
    watched = github.watched
    puts "Going to clone #{watched.size} watched repositories."
    watched = watched[0..6] if is_test
    watched.each do |repo|
      local_path = File.join('.', 'watched', repo[:name])
      next if repo[:url] =~ /#{github.config["github"]["user"]}/ # probably in the public folder already
      if github.orig_repos_cache.keys.include?(repo[:url])
        if File.exists?(local_path)
          puts "You've forked the repository. Deleting old watched #{local_path}"
          FileUtils.rm_rf(local_path)
        end
      else
        unless File.exists?(local_path)
          puts "Cloning #{repo[:url]}"
          `git clone #{github.git_url(repo[:url])} #{local_path}`
          if File.exists?(File.join(local_path, ".gitmodules"))
            puts "Initializing submodules for #{repo[:url]}"
            `cd #{local_path} ; git submodule init; git submodule update`
          end
        end
      end
    end
  end

  # go thru all the user's repositories and updates them
  def self.mass_pull
    raise "Couldn't find folder 'public'" unless File.exists?("./public")
    raise "Couldn't find folder 'watched'" unless File.exists?("./watched")
    updated_forked_projects = []
    Dir.glob(File.join('.', 'public', '*')).each do |repo|
      branches = `cd #{repo} ; git branch`
      if branches =~ /forked_from/
        puts "Updating #{repo}"
        output = `cd #{repo} ; git reset --hard ; git clean -f ; git checkout forked_from ; git pull forked_from master; git checkout master`
        if output =~ /100\%/
          updated_forked_projects << repo
        end
        if File.exists?(File.join(repo, ".gitmodules"))
          puts "Initializing submodules for #{repo}"
          `cd #{repo} ; git submodule update`
        end
      end
    end
    updated_projects = []
    Dir.glob(File.join('.', 'watched', '*')).each do |repo|
      puts "Updating #{repo}"
      output = `cd #{repo} ; git reset --hard ; git clean -f ; git checkout master ; git pull origin master`
      if output =~ /100\%/
        updated_projects << repo
      end
      if File.exists?(File.join(repo, ".gitmodules"))
        puts "Initializing submodules for #{repo}"
        `cd #{repo} ; git submodule update`
      end
    end
    puts ""
    if updated_forked_projects.size > 0
      puts "Updated Forked Projects: "
      updated_forked_projects.each do |project|
        puts project
      end
    end
    if updated_projects.size > 0
      puts "Updated Watched Projects: "
      updated_projects.each do |project|
        puts project
      end
    end
  end

  def self.require_merge(execute_merge = false)
    raise "Couldn't find folder 'public'" unless File.exists?("./public")
    repos = []
    Dir.glob(File.join('.', 'public', '*')).each do |repo|
      branches = `cd #{repo} ; git branch`
      if branches =~ /forked_from/
        output = `cd #{repo} ; git checkout forked_from ; git log --date=iso -n 1`
        forked_date = if output =~ /^Date\:\s+(.*)$/
          $1
        end
        output = `cd #{repo} ; git checkout master ; git log --date=iso -n 1`
        master_date = if output =~ /^Date\:\s+(.*)$/
          $1
        end
        repos << repo if forked_date > master_date
      end
    end
    repos.each do |repo|
      if execute_merge
        output = `cd #{repo} ; git stash; git merge forked_from ; git stash apply; git stash drop; push origin master`
        puts "Merged: #{repo}"
      else
        puts "Needs Merge: #{repo}"
      end
    end
  end

  def initialize
    @agent = Mechanize::Mechanize.new
    read_gitconfig
  end

  # list of all the user's watched 3rd party repositories
  def watched
    @watched ||= self.class.get("/repos/watched/#{config["github"]["user"]}", auth_params)["repositories"]
  end

  # list of all the user's public repositories
  def repositories
    @repositories ||= begin
      repos = self.class.get("/repos/show/#{config["github"]["user"]}", auth_params)["repositories"]
      @orig_repos_cache = {}
      repos.inject([]) do |buf, repo|
        if repo[:fork]
          orig_repo = find_fork_source(repo[:url])
          repo.merge!(:original_repository => orig_repo)
          @orig_repos_cache.merge!( orig_repo[:url] => orig_repo )
        end
        buf << repo
      end
    end
  end

  # Given a forked repository, try to find it's original repository
  def find_fork_source(url)
    # because this is a screen scrapping, it can change
    fork_source = @agent.get(url).search(".text a").text
    self.class.get("/repos/show/#{fork_source}")["repository"]
  end

  # get a public HTTP Github URL and translate it to a Git repository URL
  def git_url(url, owner=false)
    url = if owner
      url.gsub("http://github.com/", "git@github.com:")
    else
      url.gsub("http", "git")
    end
    url + ".git"
  end

  private

  def auth_params
    { :login => config["github"]["user"], :token => config["github"]["token"] }
  end

  # method extracted from Octopi
  def read_gitconfig
    @config = {}
    group = nil
    File.foreach("#{ENV['HOME']}/.gitconfig") do |line|
      line.strip!
      if line[0] != ?# && line =~ /\S/
        if line =~ /^\[(.*)\]$/
          group = $1
          @config[group] ||= {}
        else
          key, value = line.split("=").map { |v| v.strip }
          @config[group][key] = value
        end
      end
    end
    if @config["github"].nil? || @config["github"]["user"].nil? || @config["github"]["token"].nil?
      puts "Please configure your github token."
      exit 0
    end
    @config
  end
end

param = ARGV.first || ""
test = ARGV.size > 1
case param.strip.downcase
when "clone"
  Github.mass_clone(test)
when "pull"
  Github.mass_pull
when "log"
  Github.require_merge(test)
else
  puts "Parameter not recognized. Use 'clone' or 'pull'."
end
