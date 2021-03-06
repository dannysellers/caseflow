require "rainbow"

desc "Runs the frontend React mocha tests"
task :mocha do
  mocha_result = ShellCommand.run("cd ./client && yarn run test")

  if mocha_result
    puts Rainbow("Passed. All frontend react tests look good").green
  else
    puts Rainbow("Failed. Please check the mocha tests in client/test").red
    exit(1)
  end
end
