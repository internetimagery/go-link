# Game Code

# TEST LAYOUT
#05001002005008007012011
#05---001002005008007012011---004006

# TODO: errors as alert popups
# TODO: alternate turns
# TODO: snapshop game state outside of place stone. revert if error from there
# TODO: add game mode bit to front of protocol
# TODO: add default "009" to url if no board is specified
# TODO: look into adding some animations
# TODO: traverse game states, and turn off stone placig in the process
# TODO: add gnugpg signing option to url for authenticity "https://openpgpjs.org/"
# TODO: google style diagonal lined background to board
# TODO: make board size work nicely on desktop and mobile

# Capture a group
capture = (stone, board)->
  if board.get_player(stone) != 0 # Check in case another loop already captured this group
    group = board.get_connected_stones(stone)
    for stone in group
      board.place(stone, 0)

# Play a stone! Validate game rules!
play_stone = (player, pos, board, ko_check_move)->
  # Validate Placement
  if board.get_player(pos) != 0 # There is a stone already there
    throw "Illegal Move: Space occupied."

  # Place the stone on board
  board.place(pos, player)

  # Check if we can capture anything
  check_ko = false
  for dir, stone of board.get_surroundings(pos)
    if board.is_surrounded(stone) # Found one!
      capture(stone, board) # Take it!
      check_ko = true

  # Record board state
  new_state = board.dump_state()

  # Check for an illegal ko
  if check_ko and ko_check_move
    ko = true # Asume Ko unless we can prove otherwise
    for i in [0 ... new_state.length]
      if new_state[i] != ko_check_move[i] # Only one cell needs to not match to break out of Ko
        ko = false
        break
    if ko
      throw "Illegal Move: Ko."

  # Check if a suicide placement
  if board.is_surrounded(pos)
    throw "Illegal Move: Suicide."
  return new_state

# Lets go!
main = ()->

  # Start by getting some game data
  # TODO: Add warning popup if gamedata throws error, and try/catch block here
  # TODO: Could always use alerts, probably best
  game_data = new Game_Data()
  game_states = [] # Record the state of the game as we progress

  # Parse ID from url
  url = window.location.href.split("#")
  if url.length == 2 and url[1] # If there is a hash we might have an ID
    console.log "!! LOADING GAME !!"
    game_data.read_id(url[1]) # Load game data
  else # No data to load? Set us up at default
    console.log "!! NEW GAME !!"
    window.location.href = "#{url[0]}##{game_data.write_id()}"

  # Initialize our board
  board = new Board(document.getElementById("board"), game_data.board_size)

  for move in game_data.moves
    if move == "---" # We have a pass
      if game_states.length == 0 # First entry into game states
        game_states.push(board.dump_state())
      else
        game_states.push(game_states[game_states.length - 2]) # Copy last game state
    else
      state = play_stone(game_states.length % 2 + 1, move, board, game_states[game_states.length - 1])
      game_states.push(state)
  game_data.current = game_states.length
  board.update() # Update board visuals

  # Allow the player to place stones!
  board.register (pos)->
    clean_state = board.dump_state()
    try
      clean_state = play_stone(game_data.current % 2 + 1, pos, board, game_states[game_states.length - 2])
      game_data.current += 1
      game_data.add_move(pos)
      window.location.href = "#{url[0]}##{game_data.write_id()}"
    finally
      board.load_state(clean_state) # This kinda doubles up. Ah well...
      board.update() # Update board visuals



main()
