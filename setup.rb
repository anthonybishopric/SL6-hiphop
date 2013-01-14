
class Steps
  def initialize()
    @steps = {}
    ['Install Vagrant', 'Install VirtualBox', 'Install SL6 Box', 'Build Your VM'].each do |step|
      @steps[step] = false
    end
  end
  
  def print
    puts "\n--- your progress so far ---"
    @steps.each_pair do |step, done|
      puts "#{step}\t#{done ? "\e[1;32mDONE\e[0m" : '--'}"
    end    
    puts "----------------------------\n\n"
  end
  
  def mark_done(step)
    @steps[step] = true
    print
  end
  
  def done?
    @steps.each_value.inject(true) do |injected, value|
      injected and value
    end
  end
  
  def in_step(step_name)
    begin
      yield
      mark_done step_name
    rescue
      puts "\e[1;31m#{step_name} failed!\e[0m"
      exit
    end
  end
end

def absent?(file)
  print_and_run_command("stat #{file} 2>/dev/null").chomp.empty?
end

def confirm(message)
  puts message
  puts "Press enter to continue or ctrl-C to exit"
  gets
end

def print_and_run_command(command, die_on_nonzero=false)
  puts "\e[1;33m#{command}\e[0m"
  value = %x(#{command})
  if $?.to_i != 0 and die_on_nonzero
    raise "Died"
  end
  return value
end

target_directory = File.dirname(__FILE__)

steps = Steps.new

steps.print

steps.in_step 'Install Vagrant' do

  vagrant = print_and_run_command('which vagrant')
  if vagrant.empty?
    puts "You need to install Vagrant. Downloading version 1.06 to Vagrant.dmg. You'll need to finish installing by hand. When you're done installing, hit enter."
    print_and_run_command("curl -L http://files.vagrantup.com/packages/476b19a9e5f499b5d0b9d4aba5c0b16ebe434311/Vagrant.dmg > #{target_directory}/Vagrant.dmg")
    print_and_run_command("open #{target_directory}/Vagrant.dmg")
    gets
  else
    puts "You already have vagrant! Great, let's move on."
  end

end

steps.in_step 'Install VirtualBox' do
  
  if absent? "/Applications/VirtualBox.app"
    puts "You need to install VirtualBox. Downloading version 4.2.6 to VirtualBox.dmg. You'll need to finish installing by hand. When you're done installing it, hit enter"
    print_and_run_command("curl -L http://download.virtualbox.org/virtualbox/4.2.6/VirtualBox-4.2.6-82870-OSX.dmg > #{target_directory}/VirtualBox.dmg")
    print_and_run_command("open #{target_directory}/VirtualBox.dmg")
    gets
  else
    puts "You already have VirtualBox! Awesome."
  end
end

steps.in_step 'Install SL6 Box' do

  sl6_image = print_and_run_command("vagrant box list | grep scientificlinux").chomp

  if sl6_image.empty?
    puts "You need a version of scientific linux 6. Downloading http://lyte.id.au/vagrant/sl6-64-lyte.box (this may take a while...)"
    print_and_run_command("vagrant box add scientificlinux-60 http://lyte.id.au/vagrant/sl6-64-lyte.box", true)
  else
    puts "You already have a scientificlinux box added! Excellent, let's keep going."
  end
  
end

steps.in_step 'Build Your VM' do

  if absent? "#{target_directory}/boxvm"
    confirm "Now we're ready to build your VM. First, we're going to make a directory called 'boxvm' and inside will go our VM's configuration. For more information on how to configure your VM, check out Vagrant's awesome documetation http://docs.vagrantup.com/v1/docs/getting-started/index.html"
    print_and_run_command("mkdir boxvm")
    print_and_run_command("cd boxvm && vagrant init scientificlinux-60")
  end
end

if steps.done?
  puts "You're all done!"
end