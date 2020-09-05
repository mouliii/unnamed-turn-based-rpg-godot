extends Node

# https://fadden.com/tech/ShadowCast.cs.txt

class_name Map

var visionTiles = []
var visitedTiles = []
var shadedTilesMap = []
var tm : TileMap
var mapData : TileMap

var s_octantTransform = [
	   [ 1,  0,  0,  1 ],   # 0 E-NE
	   [ 0,  1,  1,  0 ],   # 1 NE-N
	   [ 0, -1,  1,  0 ],   # 2 N-NW
	   [-1,  0,  0,  1 ],   # 3 NW-W
	   [-1,  0,  0, -1 ],   # 4 W-SW
	   [ 0, -1, -1,  0 ],   # 5 SW-S
	   [ 0,  1, -1,  0 ],   # 6 S-SE
	   [ 1,  0,  0, -1 ],   # 7 SE-E
	]

func Setup(tilemap : TileMap, generatedMap : TileMap):
	tm = tilemap
	mapData = generatedMap
	
	tm.clear()
	var tiles = mapData.get_used_cells()
	for t in range(tiles.size()):
		var id = mapData.get_cellv(tiles[t])
		tm.set_cellv(tiles[t],id)


func ResetVisionMap():
	visionTiles.clear()
	visitedTiles.clear()
	var tiles = tm.get_used_cells()
	for cell in range(tiles.size()):
		tm.get_child(2).set_cellv(tiles[cell], 3)
		
func UpdateVision(pos : Vector2, radius, space : Physics2DDirectSpaceState):
	var p = tm.world_to_map(pos)
	visionTiles.clear()
	for i in range(8):
		# 1.3 on 3 wide, 1.5 on 5 wide, ei oo nelosta
		CastLight(p, radius + 1.5, 1, 1.0, 0.0, s_octantTransform[i], space)
	# drawaa visited tiles
	for tile in visitedTiles:
		var id = tm.get_cellv(tile)
		if id != -1:
			var foundId = false
			for i in range(shadedTilesMap.size()):
				if id == shadedTilesMap[i][0]:
					foundId = true
					tm.get_child(2).set_cellv(tile, shadedTilesMap[i][1])
			if !foundId:
				var newTileID = tm.get_child(2).tile_set.get_last_unused_tile_id()
				tm.get_child(2).tile_set.create_tile(newTileID)
				var oldTileTexture : Texture = tm.tile_set.tile_get_texture(tm.get_cellv(tile))
				var oldTileTextureRect = tm.tile_set.tile_get_region(id)
				tm.get_child(2).tile_set.tile_set_texture(newTileID, oldTileTexture)
				tm.get_child(2).tile_set.tile_set_region(newTileID, oldTileTextureRect)
				# TODO - tähä shader tai toimiiko modulate?
				tm.get_child(2).tile_set.tile_set_modulate(newTileID, Color(0.2,0,0,0.4))
				
				tm.get_child(2).set_cellv(tile, newTileID)
				shadedTilesMap.append([id,newTileID])
		
	# drawaa vision visitedin päälle
	tm.get_child(2).set_cellv(p,-1)
	for tile in visionTiles:
		tm.get_child(2).set_cellv(tile, -1)
	
func CastLight(gridPosn, viewRadius, startColumn, leftViewSlope, rightViewSlope, octantTransform, space):
	var tileOffset = tm.cell_size / 2
	var viewRadiusSq = viewRadius * viewRadius
	var viewCeiling = ceil(viewRadius)
	#Set true if the previous cell we encountered was blocked.
	var prevWasBlocked = false
	var savedRightSlope = -1;
	# map max width/height
	var dims = tm.get_used_rect().size
	var xDim = dims.x
	var yDim = dims.y
	
	# askel oikeelle ja ylhäältä alaspäin
	# TODO kato forloopit
	var currentCol = startColumn
	for xc in range(currentCol, viewCeiling + 1):
		for yc in range(xc, -1, -1):
			var gridX = gridPosn.x + xc * octantTransform[0] + yc * octantTransform[1];
			var gridY = gridPosn.y + xc * octantTransform[2] + yc * octantTransform[3];
			# min tai maks
			if gridX < 0 || gridX >= xDim || gridY < 0 || gridY >= yDim:
				continue
			var leftBlockSlope = (yc + 0.5) / (xc - 0.5)
			var rightBlockSlope = (yc - 0.5) / (xc + 0.5)
			
			if (rightBlockSlope > leftViewSlope):
				#Block is above the left edge of our view area; skip.
				continue
			elif (leftBlockSlope < rightViewSlope):
				#Block is below the right edge of our view area; we're done.
				break
			var distanceSquared = xc * xc + yc * yc
			if (distanceSquared <= viewRadiusSq):
				var curPos = Vector2(gridX, gridY)
				if not curPos in visitedTiles:
					visitedTiles.append(Vector2(gridX, gridY))
				visionTiles.append(curPos)
				#tm.get_child(2).set_cellv(curPos, -1)
			
			var curBlocked : bool = false
			var tilePos = Vector2(gridX,gridY)
			var isWall = space.intersect_point(tm.map_to_world(tilePos) + tileOffset,
			 32, [], 0x0000001, true, true)
			if isWall:
				if isWall[0]["collider"].name == "TileMap":
					curBlocked = true
				else:
					curBlocked = false
			
			if prevWasBlocked:
				if curBlocked:
					savedRightSlope = rightBlockSlope
				else:
					prevWasBlocked = false;
					leftViewSlope = savedRightSlope
			else:
				if curBlocked:
					if (leftBlockSlope <= leftViewSlope):
						CastLight(gridPosn, viewRadius, currentCol + 1, leftViewSlope,
						 leftBlockSlope, octantTransform, space)
					prevWasBlocked = true;
					savedRightSlope = rightBlockSlope;
		if prevWasBlocked:
			break

























