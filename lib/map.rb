class Map
  attr_reader :rows, :columns, :tile_size
  def initialize(columns:, rows:, tile_size:)
    @columns, @rows = columns, rows # Width|X, Height|Y

    @tiles = Hash.new {|hash, value| hash[value] = Hash.new { |h, v| h[v] = nil }}
    @array = []
    @threshold = 0.1

    @tile_size = tile_size

    generate
  end

  def tiles
    @array
  end

  def generate
    puts "Generating Tiles..."
    @rows.times do |y|
      @columns.times do |x|


        if @threshold < rand
          cost = rand(1..10)
          tile = Tile.new(x, y, cost, choose_color(cost))
          @tiles[x][y] = tile
          @array << tile
        end
      end
    end

    puts "Map tiles: #{@array.size}"
  end

  def choose_color(cost)
      return Gosu::Color.from_hsv(90, 1, 0.3)#(0.5 / cost) + 0.2)
  end

  def draw
    @record ||= Gosu.render(@columns * @tile_size, @rows * @tile_size) do # BIG maps are to big for A framebuffer
    # @record ||= Gosu.record(@columns * @tile_size, @rows * @tile_size) do
      @array.each do |tile|
        Gosu.draw_rect(tile.x * tile_size, tile.y * tile_size, @tile_size, @tile_size, tile.color)
      end
    end

    @record.draw(0,0,0)
  end

  def at(x, y)
    @tiles[x][y]
  end
end