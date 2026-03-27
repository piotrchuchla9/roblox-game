export type Brainrot = {
	id: string,
	name: string,
	rarity: string,
	modelId: string,
	sellValue: number,
}

export type Bed = {
	seedId: string?,
	plantedAt: number?,
	rarity: string?,
	growthTime: number?,
	isReady: boolean,
	wateredAt: number?,
}

export type PlayerData = {
	garden: {
		beds: {Bed},
		bedCount: number,
		tools: {wateringCan: string},
	},
	collection: {[string]: {count: number, firstObtainedAt: number}},
	collectionCount: number,
	currencies: {seeds: number, goldenSeeds: number},
	gamepasses: {[string]: boolean},
	dailyReward: {lastClaimed: number, streak: number},
	stats: {totalHarvested: number, totalSold: number, gardenLikes: number},
	freeSeedTimer: number,
}

export type Plot = {
	slotIndex: number,
	ownerUserId: number,
	position: Vector3,
	model: Model?,
}

export type TradeOffer = {
	fromUserId: number,
	toUserId: number,
	offerBrainrotIds: {string},
	requestBrainrotIds: {string},
	status: string, -- "pending" | "accepted" | "declined" | "expired"
	createdAt: number,
}

return {}
