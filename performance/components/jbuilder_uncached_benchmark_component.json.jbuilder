json.handler "jbuilder"
json.cached false
json.name name
json.generated_at Time.zone.now.to_f
json.total_score total_score
json.rows report_rows do |row|
  json.label row[:label]
  json.amount row[:amount]
  json.events row[:events]
  json.slug row[:slug]
end
