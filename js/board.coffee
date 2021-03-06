# Game board

# Deferred render
window.requestAnimFrame = window.requestAnimFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or (callback)-> callback()

# Size element
Resize = (x, y, w, h, style)->
  this.setAttribute("style", "margin-left:#{x}%;margin-top:#{y}%;width:#{w}%;height:#{h}%;" + style)

# Create an Element
Create = (name, parent)->
  elem = document.createElement("div")
  elem.setAttribute("class", name)
  elem.resize = Resize
  parent.appendChild(elem)
  return elem

class Board
  constructor: (@element) ->
    @callbacks = []
    @stone_class = [
      "empty", # Completely empty
      "stone set black",
      "stone set white", # White stone on board
      "play-black",
      "play-white" # Empty hover pieces
    ]

  build: (@size)->
    @element.innerHTML = "" # Clear the contents of element first
    if @size < 2
      throw "Board size not big enough."

    # Size some things proportionate to the board size
    grid_chunk = 100 / (@size - 1) # Space between grids
    stone_size = grid_chunk * 0.9
    star_size = stone_size * 0.2

    # Create an @grid frame, smaller than the board, so our stones don't fall off the sides
    @board_state = []
    @grid = Create("grid #{@stone_class[3]}", @element)
    inner_frame_pos = stone_size * 0.6
    inner_frame_span = 100 - inner_frame_pos * 2
    @grid.resize(inner_frame_pos, inner_frame_pos, inner_frame_span, inner_frame_span, "position:relative;")
    @element.appendChild(@grid)

    for row in [0 ... @size]
      Create("line-horiz", @grid).setAttribute("style", "top:#{row * grid_chunk}%;")

    for col in [0 ... @size]
      Create("line-vert", @grid).setAttribute("style", "left:#{col * grid_chunk}%;")

    # Add placeholder positions to place stones
    @sockets = []

    stars = []
    if @size % 2 == 1
      center = @size // 2
      stars.push [center, center]
    if 7 < @size < 13
      stars.push [2, 2]
      stars.push [2, @size - 3]
      stars.push [@size - 3, 2]
      stars.push [@size - 3, @size - 3]
    if 13 <= @size
      stars.push [3, 3]
      stars.push [3, @size - 4]
      stars.push [@size - 4, 3]
      stars.push [@size - 4, @size - 4]

    for col in [0 ... @size]
      for row in [0 ... @size]
        for star in stars
          if star[0] == row and star[1] == col
            star = Create("star", @grid)
            star.resize(row * grid_chunk - star_size * 0.5, col * grid_chunk - star_size * 0.5, star_size, star_size, "position:absolute;")
        socket = Create("empty", @grid)
        socket.player = 0
        socket.resize(row * grid_chunk - stone_size * 0.5, col * grid_chunk - stone_size * 0.5, stone_size, stone_size, "position:absolute;")
        do ()=>
          pos = @sockets.length
          socket.addEventListener "touchstart", (e)=>
            e.preventDefault()
            @placement_event pos
        @sockets.push(socket)
        @board_state.push(0)

  # Register callback for placement events
  register: (func)->
    @callbacks.push(func)

  # Trigger events on board click
  placement_event: (pos)->
    for func in @callbacks
      func(pos)

  # Place a stone on the requested spot
  place: (pos, stone)->
    if pos > @size ** 2
      throw "Requested position not within board size."
    @board_state[pos] = stone

  # Dump the state of the board. Positions and players
  dump_state: ()->
    return @board_state[..] # Copy to not modify original

  # Load up a state to the board
  load_state: (state)->
    if state.length != @size ** 2
      throw "Invalid State Size"
    @board_state = state[..] # replace our state with new one

  # Update board to current state.
  update: (player)->
    window.requestAnimFrame ()=>
      @grid.setAttribute("class", "grid #{@stone_class[player + 2]}")
      for pos in [0 ... @sockets.length]
        if @board_state[pos] != @sockets[pos].player # Check for differences in setup
          @sockets[pos].setAttribute("class", @stone_class[@board_state[pos]])
          @sockets[pos].player = @board_state[pos]

  # UTILITY

  # Get the current player at position
  get_player: (pos)->
    if pos > @size ** 2
      throw "Requested position not within board size."
    return @board_state[pos]

  # Get surrounding locations of a stone
  get_surroundings: (pos)->
    surroundings = {}
    # LEFT
    dir = pos - 1
    dir_check = dir % @size
    if dir_check != @size - 1 and dir_check >= 0
      surroundings.left = dir
    # RIGHT
    dir = pos + 1
    dir_check = dir % @size
    if dir_check != 0 and dir_check <= @size
      surroundings.right = dir
    # UP
    dir = pos - @size
    if dir >= 0
      surroundings.up = dir
    # DOWN
    dir = pos + @size
    if dir < @size ** 2
      surroundings.down = dir
    return surroundings

  # Walk through all stones connected together and put into an array.
  get_connected_stones: (pos)->
    group = [pos]
    player = @get_player(pos) # Get the player we're tracking
    stack = [pos]

    while stack.length > 0
      pos = stack.pop()
      for dir, dir_pos of @get_surroundings(pos) # Loop our options
        if @get_player(dir_pos) == player and dir_pos not in group
          group.push(dir_pos)
          stack.push(dir_pos)
    return group

  # Get the liberties of a group
  get_liberties: (group)->
    liberties = []
    for pos in group
      for dir, dir_pos of @get_surroundings(pos)
        if @get_player(dir_pos) == 0 and dir_pos not in liberties # Check for empty fields
          liberties.push(dir_pos)
    return liberties

  # Check if stone is captured
  is_surrounded: (pos)->
    player = @get_player(pos)
    if player != 0 # Empty spaces are always surrounded. :o
      group = @get_connected_stones(pos)
      liberties = @get_liberties(group)
      return if liberties.length > 0 then false else true
    return false

# Export Class
this.Board = Board

#
# # TESTING
# # Using Eample Grid
# # POSITION GRID 6X
# #  0  1  2  3  4  5
# #  6  7 [8] 9 10 11
# # 12 13 14 15 16 17
# # 18 19 20 21 22 23
# # 24 25 26 27 28 29
# # 30 31 32 33 34 35
