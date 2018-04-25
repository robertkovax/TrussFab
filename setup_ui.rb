# in src/ui every folder represents one 'web' project. dependencies are installed
# via `yarn` so make sure it's installed.
serious_frontend_dirs = Dir['src/ui/*/package.json']

serious_frontend_dirs.each do |x|
  dir_path = x.chomp('package.json')

  # only run `yarn build` in folders that require a build
  run_build = open(x) { |f| f.grep(/build/) } # check if `build` appears
  run_build_str = run_build.empty? ? '' : ' && yarn build'
  system("cd #{dir_path} && yarn install#{run_build_str}")
end
