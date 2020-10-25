json.array!(@operations) do |operation|
  json.extract! operation, :id, :title
  json.title "Fällig: " + operation.title
  json.allDay true
  json.start operation.bill_deadline.strftime('%Y-%m-%d')
  json.end operation.bill_deadline.strftime('%Y-%m-%d')
  json.url operation_url(operation, format: :html)
end
