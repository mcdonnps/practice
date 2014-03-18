#3-18-14
#
#
puts 'Please enter your name:'
name = gets.chomp
puts 'Hi ' + name + '!'
if name == 'Joe'
  puts 'Sup my dude!'
else
puts 'Please allow me to configure your age in years to seconds.'
end
puts 'What is your current age in years please?'
age.to_i= gets.chomp
puts 'Your age in seconds is ' + age.to_i*(31536000) + '!'
