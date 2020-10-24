json.array!(@operations) do |operation|
  json.extract! operation, :id, :title
  json.title operation.title
  json.start operation.bill_deadline
  json.end operation.bill_deadline + 2.hours
  json.url operation_url(operation, format: :html)
end
