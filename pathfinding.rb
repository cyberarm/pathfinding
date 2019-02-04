require "gosu"
require_relative "lib/tile"
require_relative "lib/map"
require_relative "lib/pathfinder"

class Window < Gosu::Window
  def initialize
    @fullscreen = (ARGV.join.include?("-f") || ARGV.join.include?("--fullscreen"))
    p @fullscreen

    if @fullscreen
      super(Gosu.screen_width, Gosu.screen_height, fullscreen: @fullscreen)
    else
      super(720, 480, false)
    end
    $window = self

    width = 64
    height= 64

    width_size = self.width / width.to_f
    height_size= self.height / height.to_f

    tile_size = 1
    if width_size < height_size
      tile_size = width_size.to_i
    elsif height_size < width_size
      tile_size = height_size.to_i
    else
      tile_size = width_size.to_i
    end
    tile_size = 1 if tile_size < 1.0

    @map = Map.new(columns: width, rows: height, tile_size: tile_size)
    @pathfinder = PathFinder.new(map: @map)

    @zoom, @offset_x, @offset_y = 1, 0, 0
    @scroll_speed = 2
    @zoom_speed   = 0.01

    @font = Gosu::Font.new(18, bold: true)
    @color_font = Gosu::Color.rgb(100, 50, 0)#Gosu::Color.rgb(100, 200, 100)
  end

  def draw
    Gosu.translate(@offset_x, @offset_y) do
      Gosu.scale(@zoom) do
        @map.draw
        @pathfinder.draw
      end
    end

    @font.draw_text(@pathfinder.status, 10, 10, 12, 1,1, @color_font)
  end

  def update
    @pathfinder.update

    @offset_x += @scroll_speed if button_down?(Gosu::KbLeft)
    @offset_x -= @scroll_speed if button_down?(Gosu::KbRight)
    @offset_y += @scroll_speed if button_down?(Gosu::KbUp)
    @offset_y -= @scroll_speed if button_down?(Gosu::KbDown)

    self.caption = "X: #{(((self.mouse_x / @map.tile_size) - @offset_x) / @zoom).ceil}, Y: #{(((self.mouse_y / @map.tile_size) - @offset_x) / @zoom).ceil} (#{Gosu.fps})"
  end

  def button_down(id)
    case id
    when Gosu::KB_EQUALS
      @pathfinder.speed+=1
    when Gosu::KbMinus
      @pathfinder.speed-=1
      @pathfinder.speed = 1 if @pathfinder.speed < 1
    end
  end

  def button_up(id)
    case id
    when Gosu::KbTab
      @pathfinder.show_nodes = !@pathfinder.show_nodes
    when Gosu::MsWheelUp
      @zoom += @zoom_speed
    when Gosu::MsWheelDown
      @zoom -= @zoom_speed
      @zoom = @zoom_speed if @zoom < @zoom_speed
    when Gosu::KbF5
      tile = @map.tiles.sample
      @pathfinder.find(origin_x: tile.x, origin_y: tile.y, target_x: rand(@map.columns), target_y: rand(@map.rows))
    end
  end

  def needs_cursor?
    true
  end
end

Window.new.show