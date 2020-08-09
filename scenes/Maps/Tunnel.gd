extends Node

const mapSize = Vector2(70,40)
const nRooms = 30
const roomMinSize = 5
const roomMaxSize = 10
const maximumTries = 10

var rooms = []

# Called when the node enters the scene tree for the first time.
func _ready():
	GenerateMap()
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			rooms.clear()
			$TileMap.clear()
			GenerateMap()
			
func GenerateMap():
	randomize()
	
	var roomSize = Vector2(int( rand_range(roomMinSize,roomMaxSize) ), int(rand_range(roomMinSize,roomMaxSize)) )
	var pos = Vector2(int(rand_range(0,mapSize.x - roomSize.x)), int(rand_range(0,mapSize.y - roomSize.y)) )
	var room = Rect2(pos,roomSize)
	rooms.append(room)
	
	for _i in range(nRooms-1):
		roomSize = Vector2(int( rand_range(roomMinSize,roomMaxSize) ), int(rand_range(roomMinSize,roomMaxSize)) )
		pos = Vector2(int(rand_range(0,mapSize.x - roomSize.x)), int(rand_range(0,mapSize.y - roomSize.y)) )
		room = Rect2(pos,roomSize)

		# huoneet
		var maxTries = maximumTries
		var badRoom = false
		var not_colliding = false
		while not not_colliding and maxTries > 0:
			maxTries -= 1
			not_colliding = true
			badRoom = false
			for r in rooms:			
				while r.intersects(room, true):
					pos = Vector2(int(rand_range(0,mapSize.x - roomSize.x)), int(rand_range(0,mapSize.y - roomSize.y)) )
					room.position = pos
					not_colliding = false
					badRoom = true
		yield(get_tree().create_timer(0.5), "timeout")
		if not badRoom:
			rooms.append(room)
			# TODO - poista, demo mite generoi
			for room in rooms:
				for x in range(room.size.x):
					for y in range(room.size.y):
						$TileMap.set_cellv(Vector2(room.position.x+x,room.position.y+y), 1)
		# käytävät
		var centreX = rooms[-1].position.x + rooms[-1].size.x / 2
		var centreY = rooms[-1].position.y + rooms[-1].size.y / 2
		var centreX2 = rooms[-2].position.x + rooms[-2].size.x / 2
		var centreY2 = rooms[-2].position.y + rooms[-2].size.y / 2
		var deltaX = round(centreX2 - centreX)
		var deltaY = round(centreY2 - centreY)
		if (abs(deltaX) > abs(deltaY)):
			for x in range(min(centreX, centreX2), max(centreX, centreX2) + 1):
				$TileMap.set_cell(x, centreY, 1)
				CheckNeighbours(x,centreY)
			for y in range(min(centreY, centreY2), max(centreY, centreY2) + 1):
				$TileMap.set_cell(centreX2, y, 1)
				CheckNeighbours(centreX2, y)
		else:
			for y in range(min(centreY, centreY2), max(centreY, centreY2) + 1):
				$TileMap.set_cell(centreX2, y, 1)
				CheckNeighbours(centreX2, y)
			for x in range(min(centreX, centreX2), max(centreX, centreX2) + 1):
				$TileMap.set_cell(x, centreY, 1)
				CheckNeighbours(x, centreY)
	# huoneet mappii
	for room in rooms:
		for x in range(room.size.x):
			for y in range(room.size.y):
				$TileMap.set_cellv(Vector2(room.position.x+x,room.position.y+y), 1)

	#huoneiden reunat
	for room in rooms:
		for x in range(room.position.x, room.position.x + room.size.x):
			if $TileMap.get_cell(x, room.position.y - 1) == -1:
				$TileMap.set_cell(x, room.position.y - 1, 2)
			if $TileMap.get_cell(x, room.position.y + room.size.y) == -1:
				$TileMap.set_cell(x, room.position.y + room.size.y, 2)
		for y in range(room.position.y - 1, room.position.y + room.size.y + 1):
			if $TileMap.get_cell(room.position.x - 1, y) == -1:
				$TileMap.set_cell(room.position.x - 1, y, 2)
			if $TileMap.get_cell(room.position.x + room.size.x, y) == -1:
				$TileMap.set_cell(room.position.x + room.size.x, y, 2)

func CheckNeighbours(x, y):
	#vasen
	if $TileMap.get_cell(x-1,y) == -1:
		$TileMap.set_cell(x-1,y,2)
	#oikea
	if $TileMap.get_cell(x+1,y) == -1:
		$TileMap.set_cell(x+1,y,2)
	#ylös
	if $TileMap.get_cell(x,y-1) == -1:
		$TileMap.set_cell(x,y-1,2)
	#alas
	if $TileMap.get_cell(x,y+1) == -1:
		$TileMap.set_cell(x,y+1,2)



















