class Point
  attr_accessor :x, :y
  def initialize(x=0, y=0)
    @x = x; @y = y
  end
  def dot(other)
    @x*other.x + @y*other.y
  end
  def cross(other)
    @x*other.y - @x*other.x
  end
  def +(other)
    new Point(@x+other.x, @y+other.y)
  end
  def -(other)
    new Point(@x-other.x, @y-other.y)
  end  
end

class Circle
  attr_accessor :centre, :radius
  def initialize(centre, radius)
    @centre = centre; @radius = radius
  end
end

# square only is sufficient for quadtree
class AABB
  # position is top left
  attr_accessor :position, :width
  def initialize(position, width)
    @position = position; @width = width
  end
end

