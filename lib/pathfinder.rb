class PathFinder
  Node = Struct.new(:tile, :parent, :distance, :cost, :visited)

  attr_reader :status
  attr_accessor :speed, :show_nodes
  def initialize(map:)
    @map = map
    @path = []
    @speed = 1
    @threads = []
    @threaded = (ARGV.join.include?("-t") || ARGV.join.include?("--threaded")) ? true : false
    @diagonal = (ARGV.join.include?("-nd") || ARGV.join.include?("--nodiagonal")) ? false : true
    @show_nodes = true

    @nodes = [] # pending traversal
    @checked_tiles = []

    @found_path = false
    @seeking = false
    @created_nodes = 0
    @depth = 0
    @max_depth = Float::INFINITY

    @status = "Waiting..."

    @visited = Hash.new do |hash, value|
      hash[value] = Hash.new {|h, v| h[v] = false}
    end

    @color_path    = Gosu::Color.rgba(255,255,255,150)
    @color_visited = Gosu::Color.rgba(0,0,255,100)
    @color_pending = Gosu::Color.rgba(0,0,100,255)
    @color_current_node = Gosu::Color.rgb(100, 0, 0)

    @color_origin  = Gosu::Color::CYAN
    @color_target  = Gosu::Color::FUCHSIA

    @start_time  = 0
    @last_update = Gosu.milliseconds
    @interval    = 100
  end

  def draw
    if @show_nodes
      (@checked_tiles + @nodes).each do |node|
        tile = node.tile
        Gosu.draw_rect(tile.x * @map.tile_size, tile.y * @map.tile_size, @map.tile_size, @map.tile_size, @color_pending, 10)
      end
    end

    @path.each do |node|
      tile = node.tile
      Gosu.draw_rect(tile.x * @map.tile_size, tile.y * @map.tile_size, @map.tile_size, @map.tile_size, @color_path, 10)
    end

    if @origin_x && origin = @map.at(@origin_x, @origin_y)
      Gosu.draw_rect(origin.x * @map.tile_size, origin.y * @map.tile_size, @map.tile_size, @map.tile_size, @color_origin, 10)
    end

    if @target_x && target = @map.at(@target_x, @target_y)
      Gosu.draw_rect(target.x * @map.tile_size, target.y * @map.tile_size, @map.tile_size, @map.tile_size, @color_target, 10)
    end

    if @current_node
      Gosu.draw_rect(@current_node.tile.x * @map.tile_size, @current_node.tile.y * @map.tile_size, @map.tile_size, @map.tile_size, @color_current_node, 10)
    end
  end

  def update
    if Gosu.milliseconds >= @last_update + @interval
      @last_update = Gosu.milliseconds

      @speed.to_i.times do
        break unless @seeking && @depth < @max_depth && !@threaded
        seek
      end
    end
  end

  def find(origin_x:, origin_y:, target_x:, target_y:, max_depth: @max_depth)
    @threads.each {|thread| thread.kill}

    @path.clear
    @nodes.clear
    @checked_tiles.clear

    @origin_x, @origin_y = origin_x, origin_y
    @target_x, @target_y = target_x, target_y


    @found_path = false
    @status = "Searching..."

    @start_time = Gosu.milliseconds

    @created_nodes = 0
    @depth = 0
    @max_depth = max_depth
    @seeking = true
    @visited = Hash.new do |hash, value|
      hash[value] = Hash.new {|h, v| h[v] = false}
    end

    @current_node = create_node(origin_x, origin_y)
    @current_node.distance = 0
    @current_node.cost     = 0 # Origin, travel cost is 0
    add_node(@current_node)

    run if @threaded
  end

  def run
    Thread.new do
      @threads << Thread.current
      me = Thread.current
      while(@seeking && @depth < @max_depth && me.alive?)
        seek
      end
    end
  end

  def seek
    unless @current_node && @map.at(@target_x, @target_y)
      @status = "No path found! Checked #{@depth} #{"(Target X: #{@target_x}, Y: #{@target_y} does not exist)" unless @map.at(@target_x, @target_y)}"
      @seeking = false
      return
    end

    # puts "Node: #{node.tile.x}:#{node.tile.y} Target: #{target_x}:#{target_y}"
    @visited[@current_node.tile.x][@current_node.tile.y] = true
    @checked_tiles << @nodes.delete(@current_node)

    if @current_node.tile.x == @target_x && @current_node.tile.y == @target_y
      # FOUND
      @found_path = true
      loop do
        break unless @current_node.parent

        @path << @current_node
        @current_node = @current_node.parent
      end
      @path.reverse!

      @seeking = false
      # pp @path
      @status = "Found path with #{@path.size} nodes, which had #{@depth} checks (Took #{((Gosu.milliseconds - @start_time)/1000.0).round(1)} seconds)"
      p "Path size: #{@path.size}"
      return
    end

    @status = "Searching at X: #{@current_node.tile.x}, Y: #{@current_node.tile.y}..."

    #LEFT
    add_node create_node(@current_node.tile.x - 1, @current_node.tile.y, @current_node)
    # RIGHT
    add_node create_node(@current_node.tile.x + 1, @current_node.tile.y, @current_node)
    # UP
    add_node create_node(@current_node.tile.x, @current_node.tile.y - 1, @current_node)
    # DOWN
    add_node create_node(@current_node.tile.x, @current_node.tile.y + 1, @current_node)

    if @diagonal
      # LEFT-UP
      if node_above? && node_above_left?
        add_node create_node(@current_node.tile.x - 1, @current_node.tile.y - 1, @current_node)
      end
      # LEFT-DOWN
      if node_below? && node_below_left?
        add_node create_node(@current_node.tile.x - 1, @current_node.tile.y + 1, @current_node)
      end
      # RIGHT-UP
      if node_above? && node_above_right?
        add_node create_node(@current_node.tile.x + 1, @current_node.tile.y - 1, @current_node)
      end
      # RIGHT-DOWN
      if node_below? && node_below_right?
        add_node create_node(@current_node.tile.x + 1, @current_node.tile.y + 1, @current_node)
      end
    end

    @current_node = next_node

    @depth += 1
  end

  def node_visited?(node)
    if defined?(node.tile)
      @visited[node.tile.x][node.tile.y]
    else
      @visited[node.x][node.y]
    end
  end

  def add_node(node)
    return unless node
    return if node_visited?(node)

    @nodes << node

    return node
  end

  def next_node
    fittest = nil
    fittest_distance = Float::INFINITY

    distance = nil
    @nodes.each do |node|
      next if node == @current_node

      distance = Gosu.distance(node.tile.x, node.tile.y, @target_x, @target_y)

      if distance < fittest_distance
        if fittest
          if fittest.distance < node.distance && fittest.cost < node.cost
            fittest = node
            fittest_distance = distance
          end
        else
          fittest = node
          fittest_distance = distance
        end
      end
    end

    return fittest
  end

  def create_node(x, y, parent = nil)
    tile = @map.at(x, y)
    return unless tile
    return if @visited[x][y]
    return if @nodes.detect {|node| node.tile.x == x && node.tile.y == y}

    node = Node.new
    node.tile = tile
    node.parent = parent
    node.distance = parent.distance + 1 if parent
    node.cost = parent.cost + tile.cost if parent #MATH TODO, includes tile weight/traversal cost
    node.visited = 0 # count for 1= left,  2=right, 3=up, 4=down node neighbors

    if x == @target_x && y == @target_y
      @current_node = node
    end

    @created_nodes += 1
    # puts "Nodes: #{@created_nodes} Alive: #{@nodes.size}"
    return node
  end

  def create_or_get_node(x, y, parent)
    if node = create_node(x, y, parent)
    else
      node = @nodes.detect {|node| node.tile.x == x && node.tile.y == y}
    end

    raise "No node was created or found!" unless node

    return node
  end

  def node_above?(node = @current_node)
    node && @map.at(node.tile.x, node.tile.y - 1)
  end
  def node_below?(node = @current_node)
    node && @map.at(node.tile.x, node.tile.y + 1)
  end
  def node_above_left?(node = @current_node)
    node && @map.at(node.tile.x - 1, node.tile.y - 1)
  end
  def node_above_right?(node = @current_node)
    node && @map.at(node.tile.x + 1, node.tile.y - 1)
  end
  def node_below_left?(node = @current_node)
    node && @map.at(node.tile.x - 1, node.tile.y + 1)
  end
  def node_below_right?(node = @current_node)
    node && @map.at(node.tile.x + 1, node.tile.y + 1)
  end
end