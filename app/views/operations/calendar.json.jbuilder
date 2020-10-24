#json.array! @operations, partial: "operations/operation", as: :operation


json.array! @operations, :title, :bill_deadline

# json.array!(@operations) do |operation|
#   json.extract! operation, :id, :title
#   json.title operation.title
#   json.start operation.start_time
#   json.end operation.start_time + 1.days
#   json.url operation_url(operation, format: :html)
# end
