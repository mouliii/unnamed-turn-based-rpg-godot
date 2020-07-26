extends Node

class _Node:
	func init(newPos, newParent, nStep):
		pos = newPos
		parent = newParent
		step = nStep
	var pos
	var parent : _Node
	var step = 0

class BFS:
	func _init(tilemap : TileMap):
		self.tm = tilemap
		self.tileOffset = tilemap.cell_size / 2
		
	var tm : TileMap
	var tileOffset
	var tempdiagonal = false
	
	func GetNeighbours(node : _Node, diagonal : bool):
		var nArray = []
		var nextStep = node.step + 1
		var pos : Vector2 = node.pos
		
		var right = _Node.new()
		right.init(Vector2(pos.x + 1, pos.y),node ,nextStep)
		var left = _Node.new()
		left.init(Vector2(pos.x - 1, pos.y),node, nextStep)
		var down = _Node.new()
		down.init(Vector2(pos.x, pos.y + 1),node, nextStep)
		var up = _Node.new()
		up.init(Vector2(pos.x, pos.y - 1),node, nextStep)
		nArray.append(right)
		nArray.append(left)
		nArray.append(down)
		nArray.append(up)
		
		if diagonal:
			var botRight = _Node.new()
			botRight.init(Vector2(pos.x + 1, pos.y + 1),node, nextStep)
			var topLeft = _Node.new()
			topLeft.init(Vector2(pos.x - 1, pos.y - 1),node, nextStep)
			var topRight = _Node.new()
			topRight.init(Vector2(pos.x + 1, pos.y - 1),node, nextStep)
			var botLeft = _Node.new()
			botLeft.init(Vector2(pos.x - 1, pos.y + 1),node, nextStep)
			nArray.append(botRight)
			nArray.append(topLeft)
			nArray.append(topRight)
			nArray.append(botLeft)
		return nArray
	
	func GetArea(start : Vector2, radius, diagonal : bool, space, exclusives, excludePos, cornerCut, collideArea2d = false):
		var visited = []
		var queue = []
		var node = _Node.new()
		var area = []
		node.init(start, null, -1)
		queue.append(node)
		area.append(node.pos)
		visited.append(node.pos)
		
		if radius == 0 or radius == null:
			return area
		
		while !queue.empty(): # lisää joku cutoff / limitti ettei forever loop
			node = queue.front()
			var neighbourList = GetNeighbours(node, diagonal)
			# parent pos - ei jaksa muuttaa kaikkia
			var curParent = node.pos
			for newnode in neighbourList: 
			# child pos - koska sama kuin ylmepänä
				var i = newnode.pos
				var skip = false
			# parent -> child
			# vas ylä -> oik ala
				var checked = false
				if diagonal:
					if i.x > curParent.x and i.y > curParent.y:
						var t1 = false
						var t2 = false
						checked = true
						var result = space.intersect_ray(
							tm.map_to_world(Vector2(curParent.x + 1,curParent.y)) + tileOffset,
							tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
						if result:
							t1 = true
						result = space.intersect_ray(
							tm.map_to_world(Vector2(curParent.x,curParent.y + 1)) + tileOffset,
							tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
						if result:
							t2 = true
						if t1 and t2:
							skip = true
						if !cornerCut:
							if t1 or t2:
								skip = true
					# oik ala -> vas ylä
					elif i.x < curParent.x and i.y < curParent.y:
						var t1 = false
						var t2 = false
						checked = true
						var result = space.intersect_ray(
							tm.map_to_world(Vector2(curParent.x - 1,curParent.y)) + tileOffset,
							tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
						if result:
							t1 = true
						result = space.intersect_ray(
							tm.map_to_world(Vector2(curParent.x,curParent.y - 1)) + tileOffset,
							tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
						if result:
							t2 = true
						if t1 and t2:
							skip = true
						if !cornerCut:
							if t1 or t2:
								skip = true
					# vas ala -> oik ylä
					elif i.x > curParent.x and i.y < curParent.y:
						var t1 = false
						var t2 = false
						checked = true
						var result = space.intersect_ray(
							tm.map_to_world(Vector2(curParent.x + 1,curParent.y)) + tileOffset,
							tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
						if result:
							t1 = true
						result = space.intersect_ray(
							tm.map_to_world(Vector2(curParent.x,curParent.y - 1)) + tileOffset,
							tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
						if result:
							t2 = true
						if t1 and t2:
							skip = true
						if !cornerCut:
							if t1 or t2:
								skip = true
					# oik ylä -> vas ala
					elif i.x < curParent.x and i.y > curParent.y:
						var t1 = false
						var t2 = false
						checked = true
						var result = space.intersect_ray(
							tm.map_to_world(Vector2(curParent.x - 1,curParent.y)) + tileOffset,
							tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
						if result:
							t1 = true
						result = space.intersect_ray(
							tm.map_to_world(Vector2(curParent.x,curParent.y + 1)) + tileOffset,
							tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
						if result:
							t2 = true
						if t1 and t2:
							skip = true
						if !cornerCut:
							if t1 or t2:
								skip = true
				if not checked:
					var result = space.intersect_ray( tm.map_to_world(Vector2(curParent.x,curParent.y)) + tileOffset,
								tm.map_to_world(Vector2(i.x,i.y)) + tileOffset, exclusives, 2147483647, true, collideArea2d)
					if result:
						skip = true
					
				if skip:
					continue
				var pos = newnode.pos
				if not pos in visited:
					if newnode.step < radius - 1:
						queue.append(newnode)	
					area.append(pos)			
				visited.append(pos)
			queue.pop_front()
		return area
					
					
					
					
					
					
					
					
					
					
					
		
