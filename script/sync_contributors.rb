require "json"
require "net/http"
require "uri"
require "yaml"
require "fileutils"

# Fetch all contributors from GitHub API (handling pagination)
def fetch_contributors
  all_contributors = []
  page = 1
  per_page = 100 # Maximum allowed by GitHub API

  loop do
    uri = URI("https://api.github.com/repos/viewcomponent/view_component/contributors")
    uri.query = URI.encode_www_form(page: page, per_page: per_page)

    contributors = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      # Add User-Agent header as GitHub API recommends it
      request["User-Agent"] = "ViewComponent Contributors Sync Script"

      response = http.request(request)

      if response.code == "200"
        JSON.parse(response.body)
      else
        puts "Error fetching contributors (page #{page}): #{response.code} #{response.message}"
        exit 1
      end
    end

    # Break if no more contributors on this page
    break if contributors.empty?

    all_contributors.concat(contributors)
    puts "Fetched page #{page} with #{contributors.length} contributors"

    # Break if we got less than the full page size (last page)
    break if contributors.length < per_page

    page += 1
  end

  all_contributors
end

# Transform contributors data for YAML output
def transform_contributors(contributors)
  usernames = contributors.map do |contributor|
    contributor["login"].downcase
  end.sort

  {"usernames" => usernames}
end

# Write contributors data to YAML file
def write_contributors_yaml(data)
  output_path = File.join(__dir__, "..", "docs", "_data", "contributors.yml")

  # Ensure the directory exists
  FileUtils.mkdir_p(File.dirname(output_path))

  File.write(output_path, data.to_yaml)
  puts "Contributors synced to #{output_path}"
  puts "Found #{data["usernames"].length} contributors"
end

# Main execution
begin
  puts "Fetching contributors from GitHub API..."
  contributors = fetch_contributors

  puts "Transforming contributor data..."
  transformed_data = transform_contributors(contributors)

  puts "Writing to YAML file..."
  write_contributors_yaml(transformed_data)

  puts "Successfully synced contributors!"
rescue => e
  puts "Error: #{e.message}"
  exit 1
end
