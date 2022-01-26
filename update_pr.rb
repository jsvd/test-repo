require 'json'

def find_gemspec_version
  gemspec_path = Dir.glob("*.gemspec").first
  spec = Gem::Specification::load(gemspec_path)
  spec.version.to_s
end

def compute_next_version(version, bump_type)
  major, minor, patch = version.segments
  case bump_type
  when "major"; major = major.to_i.succ.to_s; minor = patch = "0"
  when "minor"; minor = minor.to_i.succ.to_s; patch = "0"
  when "patch"; patch = patch.to_i.succ.to_s
  end
  Gem::Version.new([major, minor, patch].join("."))
end

def bump_gemspec_version!(current_version, next_version)
  gemspec_path = if File.exist?("VERSION")
    "VERSION"
  elsif File.exist?("version")
    "version"
  else
    Dir.glob("*.gemspec").first
  end
  source = IO.read(gemspec_path)
  source.gsub!(current_version.to_s, next_version.to_s)
  IO.write(gemspec_path, source)
end

def edit_changelog!(next_version)
  source = IO.read("CHANGELOG.md")
  IO.write("CHANGELOG.md", "## #{next_version.to_s}\n  - TODO\n\n#{source}")
end

BUMP_MESSAGE_REGEX = /^bump\s+(?<bump_type>(?:major|minor|patch))$/

`git config --local user.email "$(git log --format='%ae' HEAD)"`
`git config --local user.name "$(git log --format='%an' HEAD)"`

event = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))

event_name = ENV['GITHUB_EVENT_NAME']

body = event["comment"]["body"]
match = body.match(BUMP_MESSAGE_REGEX)

if match.nil?
  $stderr.puts "❌ The bump argument must be either \"major\", \"minor\", or \"patch\""
  exit(1)
end

bump_type = match["bump_type"]

gemspec_version = Gem::Version.new(find_gemspec_version())
puts "Current gemspec version in the gemspec is: #{gemspec_version}"

next_version = compute_next_version(gemspec_version, bump_type)
puts "next version is #{next_version}"

bump_gemspec_version!(gemspec_version, next_version)
gemspec_path = Dir.glob("*.gemspec").first

edit_changelog!(next_version)

`git commit -a -m "bump to #{next_version}"`

puts "✅ All done!"