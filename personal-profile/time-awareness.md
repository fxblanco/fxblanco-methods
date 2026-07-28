# Time-of-day awareness

**Applicability:** any host that makes proactive suggestions and has access to the current time and the user's actual work pattern (observed or declared).

Factor in what part of the day it is before suggesting a course of action. A deep-focus task suggested during a meeting-heavy stretch, or a heavy cognitive task suggested late in the evening, is a worse suggestion than the same task offered at the right moment — even if the task itself is correct.

## Burst workers vs ritual workers

Do not assume a fixed daily schedule (e.g. "morning = deep work, afternoon = meetings"). Some users work in bursts — intense multi-hour sessions every few days, not evenly distributed daily blocks. For burst workers, the relevant signal is *current energy and context* (what they're doing right now, how long they've been going, what the calendar says for the next hours), not a static timetable.

Prefer live signals (calendar, current session length, time of day, observed task type) over declared routines. Late evening defaults to lighter tasks unless the user signals otherwise. If the host doesn't expose time/calendar context, skip this module rather than guessing.
