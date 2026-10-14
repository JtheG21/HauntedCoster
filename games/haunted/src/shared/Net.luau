--!strict
-- Remote names. The server creates them under ReplicatedStorage.Remotes; clients wait for them.

local Net = {}

Net.Events = {
	"State", -- S->C: profile snapshot (coins, roster, journal, tutorial, carrying...)
	"Toast", -- S->C: { text, kind }
	"Inspect", -- S->C: inspect card for a monster
	"CaptureEnded", -- S->C: capture session finished (success/fled/cancelled)
	"RideState", -- S->C: ride started/ended
	"RequestState", -- C->S
	"CaptureCancel", -- C->S
	"TreeGaze", -- C->S (treeId: string, looking: boolean) cosmetic haunted-tree gaze report (ADR-0010)
	"CosmeticFx", -- S->C { kind = "capture", id, position } cosmetic effects to play (TASK-0047)
}

Net.Functions = {
	"CaptureStart", -- C->S (monster: Model) -> params
	"CaptureRelease", -- C->S () -> outcome
	"Purchase", -- C->S (item: string) -> ok, reason
	"SubmitRoute", -- C->S (points, pieces) -> ok, reason
	"SetExhibit", -- C->S (slot: number, uid: string?) -> ok, reason
	"Ack", -- C->S (what: string) -> () UI-only acknowledgements (journal opened)
	"Cosmetic", -- C->S (action: string, ...) -> ok, reason, data (TASK-0047: buy, equip, select, claim, place...)
}

return table.freeze(Net)
