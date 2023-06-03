# ActiveStorage::Attachment.find_each do |at|
#   next unless at.blob.service_name == "local"
#   begin
#     blob = at.blob
#     blob.open do |f|
#       at.record.send(at.name).attach(io: f, content_type: blob.content_type, filename: blob.filename)
#     end
#     # blob.destroy
#   rescue ActiveStorage::FileNotFoundError
#     # Add some message or warning here if you fancy
#   end
# end
