--!strict
-- Journal collection milestones (TASK-0066). DRAFT: the list and the reward each one grants need jg's review.
-- Every milestone is earned only by what the player has really caught or discovered (the journal, written
-- by capture), never by anything owned in the Shop: a paid or earned skin cannot complete a discovery. The
-- reward ID equals the milestone ID and must exist in Config/Catalog.Rewards; a spec checks every ID here
-- against the real species, habitat, variant and catalog rosters.

export type Milestone = {
	id: string,
	title: string,
	kind: string, -- "habitat" | "variant" | "bestiary"
	habitat: string?, -- habitat: caught every species that spawns there
	variant: string?, -- variant: discovered this natural variant on any species
	count: number?, -- bestiary: caught at least this many species (nil: every species)
}

local Milestones = {}

Milestones.List = {
	{ id = "bestiary_half", title = "Bestiary: half complete", kind = "bestiary", count = 2 },
	{ id = "bestiary_all", title = "Bestiary: complete", kind = "bestiary" },
	{ id = "hab_Cemetery", title = "Ghost Cemetery: all residents caught", kind = "habitat", habitat = "Cemetery" },
	{ id = "hab_Woodland", title = "Cursed Woodland: all residents caught", kind = "habitat", habitat = "Woodland" },
	{ id = "var_Spectral", title = "Discovered a Spectral ghost", kind = "variant", variant = "Spectral" },
	{ id = "var_Ashen", title = "Discovered an Ashen ghost", kind = "variant", variant = "Ashen" },
} :: { Milestone }

Milestones.ById = {} :: { [string]: Milestone }
for _, m in Milestones.List do
	Milestones.ById[m.id] = m
end

return Milestones
