# returns list of all files in folder and all subfolders
def all_folders(folder)
  Dir.chdir(folder) { Dir.glob("**/*").map {|path| File.expand_path(path) } }
end

# returns
def last_modified_date(dir)
  all_dates = all_folders(dir).map do |file|
    File.new(file).mtime.utc
  end
  all_dates.max
end


def is_build_needed?(src_dirs, build_dir)
  # they can multiple src dirs e.g. 'src' and 'public'
  all_src_dates = src_dirs.map { |x| last_modified_date(x) }
  last_modified_date_src = all_src_dates.max

  last_modified_date_build = last_modified_date(build_dir)

  # if files in src
  last_modified_date_src > last_modified_date_build
end


# in src/ui every folder represents one 'web' project. dependencies are installed
# via `yarn` so make sure it's installed.
serious_frontend_dirs = Dir['src/ui/*/package.json']

serious_frontend_dirs.each do |x|
  dir_path = x.chomp('package.json')
  run_build_str = ''
  # only run `yarn build` in folders that require a build
  run_build = open(x) { |f| f.grep(/build/) } # check if `build` appears
  unless run_build.empty?
    if is_build_needed?(["#{dir_path}src", "#{dir_path}public"], "#{dir_path}build")
      puts 'building frontend files for ' + x
      run_build_str = ' && yarn build'
    else
      puts 'not building frontend files for ' + x
    end
  end

  system("cd #{dir_path} && yarn install#{run_build_str}")
end
