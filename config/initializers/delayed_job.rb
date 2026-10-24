# A job whose worker was killed stays locked until max_run_time passes; the default of
# 4 hours would leave a bill extraction stuck that long. Local models need minutes at most.
Delayed::Worker.max_run_time = 15.minutes
