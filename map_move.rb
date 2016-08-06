require 'io/console'
require 'colorize'

# Reads keypresses from the user including 2 and 3 escape character sequences. 
=begin
  1 == wall
  0 == open space
  create a randomly sized map (height and width)
  create rooms in the map (height and width)
  create hallways between rooms (one high)
  only display the room that you are in
=end


@map = []

@playerView = []
@interface = [
  ["__________________________________________"],
  ["|", "Arrow Keys".white, " to move", "                      ", "|"],
  ["|", "Space".white,  " to pick up items ", "o".blue, "                ", "|"],
  ["|", "'i'".white,  " to open your inventory", "              ", "|"],
  ["|", "'v'".white, " to inspect a landmark ",":".green, "             ", "|"],
  ["|", "'q'".red, " to quit the game", "                    ", "|"],
  ["__________________________________________"],
]
@itemList = [
  {:name => 'rock'},
  {:name => 'knife'},
  {:name => 'spear'},
  {:name => 'stick'},
  {:name => 'torch'},
]
@key = {:name => 'key'}
@playerCoords = [10,10]
@exitCoords =[]
@inventory =[]
@messages =[]
#create a random number of rooms
@rooms =[]
@paths = []
@items = []
@traps = []
@landmarks = []

def generateLevel
  @map.clear
  numberOfRows = 50
  numberOfCols = 150
  for r in (0..numberOfRows)
    @map << []
  end
  count = 0
  for row in @map
    if count == 0 || count == numberOfRows
      for c in (0..numberOfCols)
        row << "_".white
      end
    else
      row << "|".white
      for c in (1...numberOfCols)
        row << " "
      end
      row << "|".white
    end
    count += 1
  end
  # @map.each do |r|
  #   puts r.each{|p| p}.join("")
  # end
  @playerView.clear
  count = 0
  for r in (0..25)
    @playerView << []
  end
  for row in @playerView
      for c in (0..65)
        row << "."
      end
    count += 1
  end
  system ('clear && printf "\e[3J"') or system ("cls")
  puts "- - - - - - - - -".cyan
  puts "Generating Level".yellow
  puts "- - - - - - - - -".cyan
  @rooms = []
  @paths = []
  @items = []
  @traps = []
  @exitCoords = []
  makeRooms()
  makePaths()
  drawPaths()
  drawWalls()
  placePlayer()
  placeTraps
  placeLandmarks
  placeItems
  validateLevel = false
  @map.each do |r|
    r.each {|c| if c == "#".yellow; validateLevel = true; end;}
  end
  if validateLevel == false
    generateLevel
  else
    slowShowMap()
    drawMap()
  # puts String.colors
  # puts String.color_samples
  show_single_key while(true)
  end
end

def makeRooms()
  numberOfRooms = rand(15..25)
  count = 0
 
  while count < numberOfRooms
    height = rand(5..15)
    width = rand(10..20)
    y = rand(1...@map.length - height)
    x = rand(1...@map[0].length - width)
    if validateRoom(y,x,height,width) == true
      @rooms.push({:x => x, :y => y, :height => height, :width => width})
      for row in (y..y+height)
        for column in (x..x+width)
          @map[row][column]='.'.light_black
        end
      end
      count += 1

    end
  end
  targetRoom = @rooms.last
  exitX = targetRoom[:x] + (targetRoom[:width]/2.to_i)
  exitY = targetRoom[:y] + (targetRoom[:height]/2.to_i)
  @map[exitY][exitX] = '#'.yellow
  @map [exitY + 2][exitX + 2] = '.'.red
  @exitCoords = [exitY,exitX]
end
def validateRoom(y,x,height,width)
  for row in (y..y+height)
    for column in (x..x+width)    
      if @map[row][column] != " " || row >= @map.length || column >= @map[0].length  
        return false
      end
    end
  end
  return true
end

def makePaths()
  for room in @rooms
    x = room[:x]
    xMax = room[:x] + room[:width]
    y = room[:y]
    yMax = room[:y] + room[:height]
    closestYDist = 100
    closestRoomY = nil
    yPathX = nil
    closestXDist = 100
    closestRoomX = nil
    xPathY = nil
    count = 0
    for otherRoom in @rooms
      count += 1
      if otherRoom == room
        next 
      end
      otherX = otherRoom[:x]
      otherXMax = otherRoom[:x] + room[:width]
      otherY = otherRoom[:y]
      otherYMax = otherRoom[:y] + room[:height]

      #if within x
      for checkX in (x..xMax)
        if checkX < otherXMax && checkX > otherX
          #find closest y
          if closestRoomY == nil
            closestYDist = (y - (otherY + otherYMax)).abs
            closestRoomY = otherRoom
            yPathX = checkX
          elsif (y-(otherY+otherYMax)).abs < closestYDist && checkX < otherXMax && checkX > otherX
            closestYDist = (y - (otherY + otherYMax)).abs
            closestRoomY = otherRoom
            yPathX = checkX
          end
            
        end
      end
      for checkY in (y..yMax)
        if checkY < otherYMax && checkY > otherY
          #find closest y
          if closestRoomX == nil
            closestXDist = (x - (otherX + otherXMax)).abs
            closestRoomX = otherRoom
            xPathY = checkY
          elsif (x-(otherX+otherXMax)).abs < closestXDist && checkY < otherYMax && checkY > otherY
            closestXDist = (x - (otherX + otherXMax)).abs
            closestRoomX = otherRoom
            xPathY = checkY
          end
        end
      end
    end 
    if closestRoomY != nil
      @paths.push({:x => yPathX, :xMax => yPathX, :y =>room[:y], :yMax =>closestRoomY[:y] + closestRoomY[:height]})
    end
    if closestRoomX != nil
      @paths.push({:x => room[:x], :xMax => closestRoomX[:x] + closestRoomX[:width], :y => xPathY, :yMax => xPathY})
    end
  end
end
def drawPaths()
  for path in @paths
    y = path[:y]
    yMax = path[:yMax]
    x = path[:x]
    xMax = path[:xMax]
    for row in (y..yMax)
      for column in (x..xMax)
        unless @map[row][column] == '#'.yellow
          @map[row][column]='.'.light_black
        end
      end
    end
  end
  for path in @paths
    y = path[:yMax]
    yMax = path[:y]
    x = path[:xMax]
    xMax = path[:x]
    for row in (y..yMax)
      for column in (x..xMax)
        @map[row][column]='.'.light_black
      end
    end
  end
end
def drawWalls()
  rowCount = 0
  for row in @map
    colCount = 0
    for col in row
      if @map[rowCount][colCount] == '.'.light_black 
        if @map[rowCount+1][colCount].nil?
          @map[rowCount][colCount] = '_'
        elsif @map[rowCount+1][colCount] == ' '
          @map[rowCount+1][colCount] = '_'.white
        end
        if @map[rowCount-1][colCount].nil?
          @map[rowCount][colCount] = '_'
        elsif @map[rowCount-1][colCount] == ' '
          @map[rowCount-1][colCount] = '_'.white
        end
        if @map[rowCount][colCount+1].nil?
          @map[rowCount][colCount] = '|'
        elsif @map[rowCount][colCount+1] == ' '
          @map[rowCount][colCount+1] = '|'.white
        end
        if @map[rowCount][colCount-1].nil?
          @map[rowCount][colCount] = '|'
        elsif @map[rowCount][colCount-1] == ' '
          @map[rowCount][colCount-1] = '|'.white
        end
      end
      colCount += 1
    end
    rowCount +=1
  end
end
def drawMap()
  startRow = @playerCoords[0] - 12
  startCol = @playerCoords[1] - 32
  rowCount = 0
  for row in (startRow .. startRow+25)
    colCount = 0
    if @map[row].nil? && rowCount != 25
      @playerView[rowCount][0] = "|"
      for i in (1..64)
        @playerView[rowCount][i] = " "
      end
      @playerView[rowCount][65] = "|"
    elsif @map[row].nil? && rowCount == 25
      for i in (0..65)
        @playerView[rowCount][i] = "_"
      end
    else
      for col in (startCol .. startCol+65)
        if rowCount == 0 || rowCount == 25
          @playerView[rowCount][colCount] = '_'.green
        elsif colCount == 0 || colCount == 65
          @playerView[rowCount][colCount] = '|'.green
        elsif @map[row][col].nil?
          @playerView[rowCount][colCount] = ' '
        elsif row < 0 || col < 0
          @playerView[rowCount][colCount] = ' '
        else
          @playerView[rowCount][colCount] = @map[row][col]
        end
        colCount += 1
      end
    end
    rowCount += 1
  end
  
   system ("cls")

  system ('clear && printf "\e[3J"')
    @playerView.each do |r|
    puts r.each {|p| p}.join("")
  end

  drawInterface
  writeMessages
  
  if @playerCoords == @exitCoords
    generateLevel
  end
end

def placePlayer()
  @playerCoords = [@rooms[0][:y] + 1, @rooms[0][:x] + 1]
  @map[@playerCoords[0]][@playerCoords[1]] = '@'.magenta
end
def placeItems
  itemCount = rand(10..15)
  while @items.length < itemCount
    rowCount = 0
    for row in @map
      colCount = 0
      for col in row
        if col == '.'.light_black
          placeItem = rand(1..1000)
          positionRandom = rand(1..1000)
          if placeItem == positionRandom
            placedItem = rand(0...5)
            if @items.length == 0
              @items << {:row => rowCount, :col => colCount, :item =>@key}
              @map[rowCount][colCount] = 'o'.blue
            elsif @items.length < itemCount
              @items << {:row => rowCount, :col => colCount, :item => @itemList[placedItem]}
              @map[rowCount][colCount] = 'o'.blue
            end
          end
        end
        colCount += 1
      end
      rowCount += 1
    end
  end
end
def placeTraps
  trapCount = (20)
  while @traps.length < trapCount
    rowCount = 0
    for row in @map
      colCount = 0
      for col in row
        if col == '.'.light_black
          if @map[rowCount+1][colCount] == '.'.light_black && @map[rowCount-1][colCount] == '.'.light_black && @map[rowCount][colCount+1] == '.'.light_black && @map[rowCount][colCount-1] == '.'.light_black
            if @map[rowCount+1][colCount+1] == '.'.light_black && @map[rowCount-1][colCount-1] == '.'.light_black && @map[rowCount-1][colCount+1] == '.'.light_black && @map[rowCount+1][colCount-1] == '.'.light_black
              placeItem = rand(1..1000)
              positionRandom = rand(1..1000)
              if placeItem == positionRandom
                @map[rowCount][colCount] = '.'.red
                @traps << {:row => rowCount, :col => colCount}
              end
            end
          end
        end
        colCount += 1
      end
      rowCount += 1
    end
  end
end
def placeLandmarks
  landmarkCount = (5)
  while @landmarks.length < landmarkCount
    rowCount = 0
    for row in @map
      colCount = 0
      for col in row
        if col == '.'.light_black
          if @map[rowCount+1][colCount] == '.'.light_black && @map[rowCount-1][colCount] == '.'.light_black && @map[rowCount][colCount+1] == '.'.light_black && @map[rowCount][colCount-1] == '.'.light_black
            if @map[rowCount+1][colCount+1] == '.'.light_black && @map[rowCount-1][colCount-1] == '.'.light_black && @map[rowCount-1][colCount+1] == '.'.light_black && @map[rowCount+1][colCount-1] == '.'.light_black
              placeItem = rand(1..1000)
              positionRandom = rand(1..1000)
              if placeItem == positionRandom
                @map[rowCount][colCount] = ':'.green
                @landmarks << {:row => rowCount, :col => colCount}
              end
            end
          end
        end
        colCount += 1
      end
      rowCount += 1
    end
  end
end
def drawInterface
  @interface.each do |r| 
    puts r.each{|c| c}.join("")
  end
end
def writeMessages
  puts "________________________________________"
  @messages.reverse.each do |message|
    puts message
  end
  puts "________________________________________"
end
def addMessage(message)
    @messages << message
  if @messages.length >= 10
    @messages.delete_at(0)
  end
end
def showInventory
  system ('clear && printf "\e[3J"') or system ("cls")
  puts "Your inventory contains:\n"
  count = 1
  @inventory.each do |item|
    puts count.to_s + ": " + item[:name].yellow
    count += 1
  end
  puts "- - - - - - - - - - - - - - - - - -\n"
  puts "To select an item, press its number".white
  puts "- - - - - - - - - - - - - - - - - -\n"
  puts "To exit the inventory, press 'b'".white
  puts "- - - - - - - - - - - - - - - - - -\n"
  exit = false
  while exit != true
    char = read_char
    case char
    when "b"
      exit = true

      drawMap()
      show_single_key while(true)
    when '1'
      unless @inventory[0].nil?
        selectItem(0)
      end
    when '2'
      unless @inventory[1].nil?
        selectItem(1)
      end
    when '3'
      unless @inventory[2].nil?
        selectItem(2)
      end
    when '4'
      unless @inventory[3].nil?
        selectItem(3)
      end
    when '5'
      unless @inventory[4].nil?
        selectItem(4)
      end
    when '6'
      unless @inventory[5].nil?
        selectItem(5)
      end
    when '7'
      unless @inventory[6].nil?
        selectItem(6)
      end
    when '8'
      unless @inventory[7].nil?
        selectItem(7)
      end
    when '9'
      unless @inventory[8].nil?
        selectItem(8)
      end
    when "\u0003"
      puts "CONTROL-C"
      exit 0
    end
  end
end
def selectItem(number)

  system ('clear && printf "\e[3J"') or system ("cls")
  item = @inventory[number]
  puts "You are inspecting the " + item[:name]
  puts "- - - - - - - - - - - - - - - - - -\n"
  puts "Name: " + item[:name].yellow

  puts "- - - - - - - - - - - - - - - - - -\n"
  puts "Press 'd' to delete".red
  puts "- - - - - - - - - - - - - - - - - -\n"
  puts "Press 'b' to go back to your inventory".white
  puts "- - - - - - - - - - - - - - - - - -\n"

  exit = false
  while exit != true
    char = read_char
    case char
    when 'b'
      exit = true
      showInventory
    when 'd'
      addMessage("You deleted the " + @inventory[number][:name].red)
      @inventory.delete_at(number)
      exit = true
      showInventory
    when "\u0003"
      puts "CONTROL-C"
      exit 0
    end
  end
end
def showMap
  system ('clear && printf "\e[3J"') or system ("cls")
  @map.each do |r|
    puts r.each{|p| p}.join("")
  end
  puts "Press 'b' to return to the game".white
  exit = false
  while exit != true
    char = read_char
    case char
    when "b"
      exit = true
      drawMap()
      show_single_key while(true)
    else
      exit = false
    end
  end
end
def inspectMark(landmark)
  puts landmark
  system ('clear && printf "\e[3J"') or system ("cls")
  puts "You are inspecting a landmark!"
  exit = false
  while exit != true
    char = read_char
    case char
    when "b"
      exit = true
      drawMap()
      show_single_key while(true)
    end
  end
end
def inspectSurroundings
  if @map[@playerCoords[0]-1][@playerCoords[1]] == ':'.green
    @landmarks.each do |mark|
      if mark[:row] == @playerCoords[0] - 1 && mark[:col] == @playerCoords[1]
        inspectMark(mark)
      end
    end
  elsif @map[@playerCoords[0]+1][@playerCoords[1]] == ':'.green
    @landmarks.each do |mark|
      if mark[:row] == @playerCoords[0] + 1 && mark[:col] == @playerCoords[1]
        inspectMark(mark)
      end
    end
  elsif @map[@playerCoords[0]][@playerCoords[1]+1] == ':'.green
    @landmarks.each do |mark|
      if mark[:row] == @playerCoords[0] && mark[:col] == @playerCoords[1] + 1
        inspectMark(mark)
      end
    end
  elsif @map[@playerCoords[0]][@playerCoords[1]-1] == ':'.green
    @landmarks.each do |mark|
      if mark[:row] == @playerCoords[0] && mark[:col] == @playerCoords[1] - 1
        inspectMark(mark)
      end
    end
  end
end
def slowShowMap
  system ('clear && printf "\e[3J"') or system ("cls")
  @map.each do |r|
    puts r.each {|p| p}.join("")

  sleep(0.05)
  end
  sleep(1)
end
def gameOver
  system ('clear && printf "\e[3J"') or system ("cls")
  empty = false
  while empty != true

    system ('clear && printf "\e[3J"') or system ("cls")
    @map.each do |r|
      puts r.each{|p| p}.join("")
    end
    rowCount = 0
    @map.each do |r|
      colCount = 0
      r.each do |c|
        randCheck = 0
        deleteCheck = rand (0..2)
        if randCheck == deleteCheck
          @map[rowCount][colCount] = " "
        end
        colCount += 1
      end
      rowCount += 1
    end
    nonEmptyCount = 0
    rowCount = 0
    @map.each do |r|
      colCount = 0
      r.each do |c|
        if c != " "
          nonEmptyCount += 1
        end
      colCount += 1
      end
    rowCount += 1
    end
    if nonEmptyCount < 20
      empty = true
    end
    sleep(0.2)
  end

  system ('clear && printf "\e[3J"') or system ("cls")
  string = ""
  for i in (0..20)
    string +=  "Game Over ".red
  end
  for i in (0..50)
    print string
    sleep(0.05)
  end
  puts "Press " + "'q'".white + " to quit"
end
def move(input)
  case input
  when "\e[A"
    if @map[@playerCoords[0]][@playerCoords[1]].nil?
      drawMap()
    elsif @map[@playerCoords[0]-1][@playerCoords[1]] == '.'.light_black
      @map[@playerCoords[0]][@playerCoords[1]] = '.'.light_black
      @playerCoords = [@playerCoords[0]-1, @playerCoords[1]]
      @map[@playerCoords[0]][@playerCoords[1]] = '@'.magenta
      drawMap()
    elsif  @map[@playerCoords[0]-1][@playerCoords[1]] == '#'.yellow
      hasKey = keyCheck
      if hasKey
        @inventory.delete_if{|item| item[:name] == 'key'}
        generateLevel
      end
    elsif @map[@playerCoords[0]-1][@playerCoords[1]] == '.'.red
        gameOver
    end
  when "\e[B"
    if @map[@playerCoords[0]][@playerCoords[1]].nil?
      drawMap()
    elsif @map[@playerCoords[0]+1][@playerCoords[1]] == '.'.light_black
      @map[@playerCoords[0]][@playerCoords[1]] = '.'.light_black
      @playerCoords = [@playerCoords[0]+1, @playerCoords[1]]
      @map[@playerCoords[0]][@playerCoords[1]] = '@'.magenta
      drawMap()
    elsif @map[@playerCoords[0]+1][@playerCoords[1]] == '#'.yellow
      hasKey = keyCheck
      if hasKey
        @inventory.delete_if{|item| item[:name] == 'key'}
        generateLevel
      end
    elsif @map[@playerCoords[0]+1][@playerCoords[1]] == '.'.red
        gameOver
    end
  when "\e[C"
    if @map[@playerCoords[0]][@playerCoords[1]].nil?
      drawMap()
    elsif @map[@playerCoords[0]][@playerCoords[1]+1] == '.'.light_black
      @map[@playerCoords[0]][@playerCoords[1]] = '.'.light_black
      @playerCoords = [@playerCoords[0], @playerCoords[1]+1]
      @map[@playerCoords[0]][@playerCoords[1]] = '@'.magenta
      drawMap()
    elsif @map[@playerCoords[0]][@playerCoords[1]+1] == '#'.yellow
      hasKey = keyCheck
      if hasKey
        @inventory.delete_if{|item| item[:name] == 'key'}
        generateLevel
      end
    elsif @map[@playerCoords[0]][@playerCoords[1]+1] == '.'.red
        gameOver
    end
  when "\e[D"
    if @map[@playerCoords[0]][@playerCoords[1]].nil?
      drawMap()
    elsif @map[@playerCoords[0]][@playerCoords[1]-1] =='.'.light_black
      @map[@playerCoords[0]][@playerCoords[1]] = '.'.light_black
      @playerCoords = [@playerCoords[0], @playerCoords[1]-1]
      @map[@playerCoords[0]][@playerCoords[1]] = '@'.magenta
      drawMap()
    elsif @map[@playerCoords[0]][@playerCoords[1]-1] == '#'.yellow
      hasKey = keyCheck
      if hasKey
        @inventory.delete_if{|item| item[:name] == 'key'}
        generateLevel
      end
    elsif @map[@playerCoords[0]][@playerCoords[1]-1] == '.'.red
        gameOver
    end
 end
end

def pickUpItem()
  if @map[@playerCoords[0]-1][@playerCoords[1]] == 'o'.blue
    if @inventory.length >= 9
      addMessage("Your inventory is full!".light_red)
    else
      @items.each do |item|
        if item[:row] == @playerCoords[0] - 1 && item[:col] == @playerCoords[1]
          @inventory << item[:item]
          picked = item[:item]
          addMessage("Picked up: " + picked[:name].yellow)
          @map[@playerCoords[0]-1][@playerCoords[1]] = '.'.light_black
        end
      end
    end
   drawMap()
  elsif @map[@playerCoords[0]+1][@playerCoords[1]] == 'o'.blue
    if @inventory.length >= 9
      addMessage("Your inventory is full!".light_red)
    else
      @items.each do |item|
        if item[:row] == @playerCoords[0]+1 && item[:col] == @playerCoords[1]
          @inventory << item[:item]
          picked = item[:item]
          addMessage("Picked up: " + picked[:name].yellow)
          @map[@playerCoords[0]+1][@playerCoords[1]] = '.'.light_black
        end
      end
    end
    drawMap()
  elsif @map[@playerCoords[0]][@playerCoords[1]+1] == 'o'.blue
    if @inventory.length >= 9
      addMessage("Your inventory is full!".light_red)
    else
      @items.each do |item|
        if item[:row] == @playerCoords[0]&& item[:col] == @playerCoords[1] + 1
          @inventory << item[:item]
          picked = item[:item]
          addMessage("Picked up: " + picked[:name].yellow)
          @map[@playerCoords[0]][@playerCoords[1]+1] = '.'.light_black
        end
      end
    end
    drawMap()
  elsif @map[@playerCoords[0]][@playerCoords[1]-1] =='o'.blue
    if @inventory.length >= 9
      addMessage("Your inventory is full!".light_red)
    else
      @items.each do |item|
        if item[:row] == @playerCoords[0]&& item[:col] == @playerCoords[1] - 1
          @inventory << item[:item]
          picked = item[:item]
          addMessage("Picked up: " + picked[:name].yellow)
          @map[@playerCoords[0]][@playerCoords[1]-1] = '.'.light_black
        end
      end
    end
    drawMap()
  end
end
def keyCheck
  for item in @inventory
    if item[:name] == 'key'
      addMessage("Used: " + "key".red)
      return true
    end
  end
  return false
end

def read_char
  STDIN.echo = false
  STDIN.raw!

  input = STDIN.getc.chr
  if input == "\e" then
    input << STDIN.read_nonblock(3) rescue nil
    input << STDIN.read_nonblock(2) rescue nil
  end
ensure
  STDIN.echo = true
  STDIN.cooked!

  return input
end

# oringal case statement from:
# http://www.alecjacobson.com/weblog/?p=75
def show_single_key
  c = read_char

  case c
  when " "
    pickUpItem()
  when "i"
    showInventory
  when "m"
    showMap
  when "v"
    inspectSurroundings
    puts "working"
  when "q"
    system ('clear && printf "\e[3J"') or system ("cls")
    exit 0
  when "k"
    gameOver
  when "\e[A"
    move(c)
  when "\e[B"
    move(c)
  when "\e[C"
    move(c)
  when "\e[D"
    move(c)
  when "\u0003"
    puts "CONTROL-C"
    exit 0
  end
end


generateLevel