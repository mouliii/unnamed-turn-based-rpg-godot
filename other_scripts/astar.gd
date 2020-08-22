extends Node

class _Node:
	func _init(_x, _y, step):
		self.x = _x
		self.y = _y
		self.fcost = 0
		self.gcost = 0
		self.hcost = 0
		self.child = null
		self.parent = null
		self.nStep = step
	var x
	var y
	var fcost
	var gcost
	var hcost
	var child
	var parent
	var nStep
	

# REPARENT juttu
# var skip -> continue
# lopussa *10 juttu 
# PoolVector2d muutos <- nopeempi

func astar(start : Vector2, end : Vector2, maxSteps, tilemap : TileMap, space, excludes, checkCharacters, diagonal, cornerCut):
	#var spaceState = space
	#var excludes = exclused_bodies
	var tm = tilemap
	var tileOffset = tm.cell_size / 2
	var startnode = _Node.new(start.x, start.y, 0)
	var endnode = _Node.new(end.x, end.y, null)
	var openlist = []
	var closedlist = []
	var path = []
	openlist.append(startnode)
	
	if tm.map_to_world(start) == tm.map_to_world(end):
		return null
	# check, että mouse ei paikassa, johon ei voi liikkua  # 2147483647 ja 0x7FFFFFFF <- check
	var mouseCheck = space.intersect_point(tm.map_to_world(end) + tileOffset, 32, excludes, 0x0000001, true, checkCharacters)
	if mouseCheck:
		return null
	
	var curParent : _Node
	# or iter < max == CRASH WTF
	while len(openlist) > 0:
		var current = 0
		var fcost = 99999
		for node in openlist:
			if node.fcost < fcost:
				fcost = node.fcost
				current = node
				curParent = node
		openlist.erase(current)
		closedlist.append(current)
		
		if current.x == endnode.x and current.y == endnode.y:
			var parent = current.parent
			path.append(Vector2(current.x, current.y))
			while parent != null:
				path.append(Vector2(parent.x, parent.y))
				parent = parent.parent
			return path
			
		if current.nStep == maxSteps + 1:
			var parent = current.parent
			while parent != null:
				path.append(Vector2(parent.x, parent.y))
				parent = parent.parent
			return path
#			"""
#			var parent = current.parent
#			path.append(Vector2(current.x, current.y))
#			while parent != null:
#				path.append(Vector2(parent.x, parent.y))
#				parent = parent.parent
#			return path
#			"""
		if diagonal:
			current.child = [_Node.new(current.x - 1, current.y, current.nStep + 1), _Node.new(current.x + 1, current.y, current.nStep + 1),
			_Node.new(current.x, current.y + 1, current.nStep + 1), _Node.new(current.x, current.y - 1, current.nStep + 1),
			_Node.new(current.x - 1, current.y - 1, current.nStep + 1), _Node.new(current.x - 1, current.y + 1, current.nStep + 1),
			_Node.new(current.x + 1, current.y + 1, current.nStep + 1), _Node.new(current.x + 1, current.y - 1, current.nStep + 1)]
		else:
			current.child = [_Node.new(current.x - 1, current.y, current.nStep + 1), _Node.new(current.x + 1, current.y, current.nStep + 1),
			_Node.new(current.x, current.y + 1, current.nStep + 1), _Node.new(current.x, current.y - 1, current.nStep + 1)]
		
		# kato minne contnue menee / break ?
		for i in current.child:
			var skip = false
			if i.nStep > maxSteps:
				skip = true
			if !cornerCut:
				# parent -> child
				# vas ylä -> oik ala
				if i.x > curParent.x and i.y > curParent.y:
					var result = space.intersect_ray(
						tm.map_to_world(Vector2(curParent.x + 1,curParent.y)) + tileOffset,
						tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)
					if result:
						skip = true
					result = space.intersect_ray(
						tm.map_to_world(Vector2(curParent.x,curParent.y + 1)) + tileOffset,
						tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)
					if result:
						skip = true
				# oik ala -> vas ylä
				if i.x < curParent.x and i.y < curParent.y:
					var result = space.intersect_ray(
						tm.map_to_world(Vector2(curParent.x - 1,curParent.y)) + tileOffset,
						tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)
					if result:
						skip = true
					result = space.intersect_ray(
						tm.map_to_world(Vector2(curParent.x,curParent.y - 1)) + tileOffset,
						tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)
					if result:
						skip = true
				# vas ala -> oik ylä
				if i.x > curParent.x and i.y < curParent.y:
					var result = space.intersect_ray(
						tm.map_to_world(Vector2(curParent.x + 1,curParent.y)) + tileOffset,
						tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)
					if result:
						skip = true
					result = space.intersect_ray(
						tm.map_to_world(Vector2(curParent.x,curParent.y - 1)) + tileOffset,
						tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)
					if result:
						skip = true
				# oik ylä -> vas ala
				if i.x < curParent.x and i.y > curParent.y:
					var result = space.intersect_ray(
						tm.map_to_world(Vector2(curParent.x - 1,curParent.y)) + tileOffset,
						tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)
					if result:
						skip = true
					result = space.intersect_ray(
						tm.map_to_world(Vector2(curParent.x,curParent.y + 1)) + tileOffset,
						tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)
					if result:
						skip = true					
								
			var res = space.intersect_point(tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, 32, excludes, 1, true, checkCharacters)
			#var result = space.intersect_ray( tm.map_to_world(Vector2(curParent.x,curParent.y)) + tileOffset,
			#				tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, excludes, 1, true, checkCharacters)

			if res:
				skip = true
			
			for l in closedlist:
				if i.x == l.x and i.y == l.y:
					skip = true
 
			for l in openlist:
				if i.x == l.x and i.y == l.y:
					skip = true
					
			if not skip:
				if not i in openlist:
					i.parent = current
					i.gcost = current.gcost + sqrt((abs(current.x - i.x) + abs(current.y - i.y))* 10)
					i.hcost = max(abs(i.x - endnode.x), abs(i.y - endnode.y)) * 10
					i.fcost = i.gcost + i.hcost
					openlist.append(i)
					# tähä kait reparentti
					# wiki pseudo tekee ennen add

func CheckPoint(point : Vector2, tilemap : TileMap, space, excludes, area2dCollision):
	var tm = tilemap
	var tileOffset = tm.cell_size / 2
	var mouseCheck = space.intersect_point(tm.map_to_world(point) + tileOffset, 32, excludes, 0x0000001, true, area2dCollision)
	if mouseCheck:
		return (mouseCheck[0]["collider"].name)
	else:
		return ""
