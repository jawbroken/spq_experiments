class Point
  attr_accessor :x, :y
  def initialize(x=0, y=0)
    @x = x; @y = y
  end
  def dot(other)
    @x*other.x + @y*other.y
  end
  def cross(other)
    @x*other.y - @y*other.x
  end
  def +(other)
    Point.new(@x+other.x, @y+other.y)
  end
  def -(other)
    Point.new(@x-other.x, @y-other.y)
  end
  def distance(other)
    Math::sqrt((@x-other.x)**2+(@y-other.y)**2)
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
  def contains?(point)
    (@position.x..@position.x+@width).include? point.x and
      (@position.y..@position.y+@width).include? point.y
  end
end

def distance_to_segment(seg_start, seg_end, point)
  start_end = seg_end-seg_start
  start_point = point-seg_start
  dist = (point-seg_end).cross(start_point).to_f / seg_end.distance(seg_start)
  return seg_end.distance(point) if (point-seg_end).dot(start_end) > 0
  return seg_start.distance(point) if (point-seg_start).dot(seg_start-seg_end) > 0
  return dist.abs
end

def circle_aabb_overlap?(circle, aabb)
  return "contained" if aabb.contains? circle.centre
  return "one" if distance_to_segment(aabb.position,
                                     aabb.position+Point.new(aabb.width,0),
                                     circle.centre) <= circle.radius
  return "two" if distance_to_segment(aabb.position+Point.new(aabb.width,0),
                                     aabb.position+Point.new(aabb.width,aabb.width),
                                     circle.centre) <= circle.radius
  return "three" if distance_to_segment(aabb.position+Point.new(aabb.width,aabb.width),
                                     aabb.position+Point.new(0,aabb.width),
                                     circle.centre) <= circle.radius
  return "four" if distance_to_segment(aabb.position+Point.new(0,aabb.width),
                                     aabb.position,
                                     circle.centre) <= circle.radius
  return false
end



