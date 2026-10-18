--!strict
-- Remote names. The server creates them under ReplicatedStorage.Remotes; clients wait for them.

local Net = {}

Net.Events = {
	"State", -- S->C: profile snapshot (coins, roster, journal, tutorial, carrying...)
	"Toast", -- S->C: { text, kind }
	"Inspect", -- S->C: inspect card for a monster
	"CaptureEnded", -- S->C: capture session finished (success/fled/cancelled)
	"CaptureFinisher", -- S->C: { species, variant, position } a Rare was just captured; cosmetic, that player only; variant is reserved for per-variant looks (TASK-0055)
	"RideState", -- S->C: ride started/ended
	"RequestState", -- C->S
	"CaptureCancel", -- C->S
	"TreeGaze", -- C->S (treeId: string, looking: boolean) cosmetic haunted-tree gaze report (ADR-0010)
}

Net.Functions = {
	"CaptureStart", -- C->S (monster: Model) -> params
	"CaptureRelease", -- C->S () -> outcome
	"Purchase", -- C->S (item: string) -> ok, reason
	"SubmitRoute", -- C->S (points, pieces) -> ok, reason
	"SetExhibit", -- C->S (slot: number, uid: string?) -> ok, reason
	"GetCatalog", -- C->S () -> { items, rewards } read-only cosmetic catalog (TASK-0061)
	"EquipLook", -- C->S (uid: string, slot: "skin"|"aura", id: string?) -> ok, message (TASK-0062)
	"Ack", -- C->S (what: string) -> () UI-only acknowledgements (journal opened)
}

return table.freeze(Net)
