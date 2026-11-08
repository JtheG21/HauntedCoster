--!strict
-- Profile save tunables (TASK-0141, jg decisions 2026-11-06). Exactly-once rests on two of these relations, so change
-- them only together with the design in the TASK-0141 note:
--  * RETRY_WINDOW_S < RETRY_WINDOW_S + CLOCK_SKEW_ALLOWANCE_S <= RECEIPT_TTL_S: a receipt outlives every attempt of its
--    operation, so a live operation's receipt is never pruned or evicted while it can still be retried.
--  * eviction at the cap touches only receipts older than RETRY_WINDOW_S + CLOCK_SKEW_ALLOWANCE_S (1200 s).
return table.freeze({
	RETRY_WINDOW_S = 900, -- monotonic seconds from taking an operation; at or past it no attempt starts
	CLOCK_SKEW_ALLOWANCE_S = 300, -- how far another server's os.time() may differ from ours
	RECEIPT_TTL_S = 604800, -- 7 days: receipts exactly this old are kept, older ones pruned
	RECEIPT_CAP = 200, -- at most this many session receipts per profile
	XP_MAX = 100000000, -- schema v4: a stored xp total above this is damaged data (daily mutation fails closed)
	COMMAND_QUEUE_CAP = 64, -- ordered quest/play commands waiting for the next op; more are dropped with a warning
	SEEN_EVENT_CAP = 256, -- recent event ids remembered per session so one logical event queues once
	MAX_EVENT_ID = 64,
	SHUTDOWN_DEADLINE_S = 25, -- shared local drain deadline inside Roblox's 30 s BindToClose budget
})
