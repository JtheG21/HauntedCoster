--!strict
-- Interactive haunted trees (TASK-0041, ADR-0010): appearance odds, gaze thresholds and face animation
-- tuning in one place. The server picks archetype and palette once per tree and replicates them as
-- attributes; clients read the same table for gaze tests and animation. Distances are studs, angles degrees.

export type Palette = {
	id: string,
	eye: Color3, -- the eyeball (iris) colour
	pupil: Color3,
	neon: boolean, -- Neon on the eyeball: a dim colour keeps the glow restrained
}

export type Config = {
	tag: string, -- CollectionService tag on every faced tree model
	archetypes: { string },
	palettes: { Palette },
	faceShare: number, -- share of the placed trees that get a face
	treeCount: number, -- haunted trees placed in the Woodland
	smallShare: number, -- share of the placed trees built at the small scale
	gaze: {
		range: number, -- head to face, studs (brief: 9-14)
		angle: number, -- camera aim off the face centre, degrees (brief: 10-15), widened by the face's size
		maxSideAngle: number, -- a face seen more edge-on than this from the head is not "visible"
		exitSlack: number, -- extra degrees and studs before a current gaze ends (hysteresis)
		serverRangeSlack: number, -- the server allows this much movement and latency on the range
		keepalive: number, -- client re-sends "still looking" this often, seconds
		ttl: number, -- the server drops a report not renewed within this, seconds
		resumeDelay: number, -- continuous seconds with no observer before the face resumes
		checkRadius: number, -- clients only test trees within this
		checkHz: number, -- client gaze tests per second
		rate: number, -- server token bucket: reports per second per player
		burst: number,
	},
	face: {
		trackRange: number, -- eyes follow the nearest visible player within this
		yawLimit: number, -- eye rotation limits, degrees
		pitchLimit: number,
		blinkEvery: { number }, -- seconds, min and max between blinks
		glanceEvery: { number },
		mouthEvery: { number },
		frozenLid: number, -- 0 open, 1 closed: the lifeless half-lidded stare
		frozenMouth: number, -- 0 closed, 1 open
		restMouth: number,
		settleRate: number, -- damping toward the frozen pose (per second, high = fast)
		idleRate: number, -- damping in normal animation
		recoverSeconds: number, -- blend from frozen back to full idle speed
	},
}

local HauntedTrees: Config = {
	tag = "HauntedTree",
	archetypes = { "Pillar", "Broad", "Angular" }, -- A (ASSET-REF-001), B, C (ASSET-REF-003)
	palettes = {
		{ id = "Dark", eye = Color3.fromRGB(34, 28, 24), pupil = Color3.fromRGB(4, 3, 3), neon = false },
		{ id = "Amber", eye = Color3.fromRGB(122, 88, 18), pupil = Color3.fromRGB(12, 8, 4), neon = true },
		{ id = "Violet", eye = Color3.fromRGB(88, 38, 128), pupil = Color3.fromRGB(10, 4, 14), neon = true },
	},
	faceShare = 0.5,
	treeCount = 16,
	smallShare = 0.25,
	gaze = {
		range = 12,
		angle = 12,
		maxSideAngle = 70,
		exitSlack = 3,
		serverRangeSlack = 4,
		keepalive = 0.4,
		ttl = 1.25,
		resumeDelay = 1,
		checkRadius = 40,
		checkHz = 15,
		rate = 10,
		burst = 20,
	},
	face = {
		trackRange = 30,
		yawLimit = 35,
		pitchLimit = 22,
		blinkEvery = { 2.5, 6 },
		glanceEvery = { 1.2, 3.5 },
		mouthEvery = { 4, 10 },
		frozenLid = 0.38,
		restMouth = 0.1, -- idle jaw opening, so the mouth reads as a dark slit
		frozenMouth = 0.18,
		settleRate = 40,
		idleRate = 9,
		recoverSeconds = 1.2,
	},
}

return table.freeze(HauntedTrees)
