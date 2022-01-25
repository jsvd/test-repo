require 'json'


def followup_notice
  $stderr.puts "⚠️  Please bump the version in a new pull request."
end

def find_gemspec_version
  gemspec_path = Dir.glob("*.gemspec").first
  spec = Gem::Specification::load(gemspec_path)
  spec.version.to_s
end

def fetch_git_versions
  `git tag --list 'v*'`.split("\n").map {|version| version.tr("v", "").strip }
end

def find_version_changelog_entry(version)
  IO.read("CHANGELOG.md").match(/## #{version}\n\s+.+$/)
end

# TODO refactor rubygem_published?
def rubygem_published?
  gemspec_path = Dir.glob("*.gemspec").first
  spec = Gem::Specification::load(gemspec_path)
  gem_name = spec.name
  version = spec.version.to_s
  platform = spec.platform.to_s == "java" ? "-java" : ""
  url = "https://rubygems.org/gems/#{gem_name}/versions/#{version}#{platform}"
  result = `curl -s -I #{url}`
  first_line = result.split("\n").first
  _, status, _ = first_line.split(" ")
  status == "200"
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

event = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))

event_name = ENV['GITHUB_EVENT_NAME']
body = event["comment"]["body"]

match = body.match(/^bump\s+(?<bump_type>(?:major|minor|patch))$/)
bump_type = match["bump_type"]

if match.nil?
  $stderr.puts "❌ The bump argument must be either \"major\", \"minor\", or \"patch\""
  exit(1)
end

gemspec_version = find_gemspec_version()
puts "Current gemspec version in the gemspec is: #{gemspec_version}"

published_versions = fetch_git_versions()

if published_versions.include?(gemspec_version)
  $stderr.puts "❌ A git tag \"v#{gemspec_version}\" already exists for version #{gemspec_version}"
  followup_notice()
  exit(1)
end

if rubygem_published?
  $stderr.puts "❌ Version \"#{gemspec_version}\" is already published on Rubygems.org"
  followup_notice()
  exit(1)
end

next_version = compute_next_version(gemspec_version, bump_type)
puts "next version is #{next_version}"

puts "✅ We're all set up! Starting publishing now"
