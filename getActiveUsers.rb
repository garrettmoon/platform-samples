require 'optparse'
require 'date'
require 'open3'

options = {}
OptionParser.new do |opts|
  opts.banner = "#{$0} - Find and output active members in an organization"

  opts.on('-d', '--days MANDATORY',Integer, "Number of days to search for activity") do |d|
    options[:days] = d
  end

  opts.on('-h', '--help', "Display this help") do |h|
    puts opts
    exit 0
  end
end.parse!

class ActiveMemberSearch
  def cmd(cmd)
    Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
      while line = stdout_err.gets
        puts line
      end

      exit_status = wait_thr.value
      unless exit_status.success?
        abort "FAILED !!! #{cmd}"
      end
    end
  end
  
  def initialize(options={})
    raise(OptionParser::MissingArgument) if (
      options[:days].nil?
    )
    now = Date.today
    ago = now - options[:days]
    
    # Get subsites
    command = "ruby api/ruby/find-inactive-members/find_inactive_members.rb -o pinterest-subsites -d #{ago}"
    puts "running: #{command}"
    cmd(command)
    cmd('mv active_users.csv subsites_active_members.csv')
    # Get pinterest (all)
    command = "ruby api/ruby/find-inactive-members/find_inactive_members.rb -o pinterest -d #{ago}"
    puts "running: #{command}"
    cmd(command)
    cmd('mv active_users.csv all_pinterest_active_members.csv')
    # Get pinterest (private)
    command = "ruby api/ruby/find-inactive-members/find_inactive_members.rb -o pinterest -p -d #{ago}"
    puts "running: #{command}"
    cmd(command)
    cmd('mv active_users.csv pinterest_private_active_members.csv')
  end
end

ActiveMemberSearch.new(options)