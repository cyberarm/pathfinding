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

    start = @map.tiles.sample
    @start_x, @start_y = start.x, start.y
    target = @map.tiles.sample
    @target_x, @target_y = target.x, target.y

    @font = Gosu::Font.new(18, bold: true)
    @color_font = Gosu::Color.rgb(100, 200, 100)
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

    delete_tile                      if button_down?(Gosu::KbR)
    add_tile(relative_x, relative_y) if button_down?(Gosu::MsMiddle)

    self.caption = "X: #{relative_x}, Y: #{relative_y} (#{Gosu.fps})"
  end

  def relative_x
    (((self.mouse_x / @map.tile_size) - @offset_x) / @zoom).floor
  end
  def relative_y
    (((self.mouse_y / @map.tile_size) - @offset_x) / @zoom).floor
  end

  def add_tile(x, y, cost = nil)
    @map.add(x, y)
  end

  def delete_tile
    if tile = @map.at(relative_x, relative_y)
      @map.remove(tile)
    end
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
    when Gosu::MsLeft
      start = @map.at(relative_x, relative_y)
      if start
        @start_x, @start_y = start.x, start.y
      end
    when Gosu::MsRight
      target = @map.at(relative_x, relative_y)
      if target
        @target_x, @target_y = target.x, target.y
      end
    when Gosu::KbTab
      @pathfinder.show_nodes = !@pathfinder.show_nodes
    when Gosu::MsWheelUp
      @zoom += @zoom_speed
    when Gosu::MsWheelDown
      @zoom -= @zoom_speed
      @zoom = @zoom_speed if @zoom < @zoom_speed
    when Gosu::KbF5
      tile = @map.tiles.sample
      @pathfinder.find(origin_x: @start_x, origin_y: @start_y, target_x: @target_x, target_y: @target_y)
    end
  end

  def needs_cursor?
    true
  end
end

Window.new.show