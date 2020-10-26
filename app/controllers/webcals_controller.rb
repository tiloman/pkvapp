class WebcalsController < ApplicationController

  def show
    user = User.find(params[:user])
    operations = Operation.unscoped.where(person_id: [user.people])
    cal_name = "abile"

     respond_to do |format|
       format.ics do
         cal = Icalendar::Calendar.new
         cal.x_wr_calname = cal_name
         operations.each do |operation|
           cal.event do |e|
             e.dtstart     = operation.bill_deadline - 1.day
             e.dtend       = operation.bill_deadline
             e.location    = operation.title
             e.summary     = operation.title
             e.description = "geht noch nicht"
             e.url = operation_url(operation)
           end
        end
         cal.publish
         render plain: cal.to_ical
         end

     end
    end


end
