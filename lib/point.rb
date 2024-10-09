# Point class to represent a point in 2D space
class Point
  attr_reader :x, :y

  def self.[](p1, p2)
    @points ||= {}
    key = (p1 << 32) | p2

    return @points[key] if @points.key?(key)

    @points[key] = new(p1, p2)
  end

  def initialize(x, y)
    @x = x
    @y = y
  end

  def to_s
    "P[#{x}, #{y}]"
  end

  def inspect
    to_s
  end

  def distance_to(other_point)
    Segment[self, other_point].length
  end

  # Helper function to check if point p3 lies on line segment p1p2 (for collinear case)
  def on_segment?(p1, p2)
     # Check if the point is within the bounding box defined by p1 and p2
    return false unless x.between?([p1.x, p2.x].min, [p1.x, p2.x].max)
    return false unless y.between?([p1.y, p2.y].min, [p1.y, p2.y].max)

    # Check if the point is collinear with p1 and p2
    cross_product = (y - p1.y) * (p2.x - p1.x) - (x - p1.x) * (p2.y - p1.y)

    # If the cross product is not zero, the points are not collinear
    cross_product == 0
  end

  # add a transposition vector to a point to get its new location
  def +(vector)
    self.class[x + vector.x, y + vector.y]
  end

  def ==(other)
    return false unless other.is_a?(Point)

    x == other.x && y == other.y
  end

  def eql?(other)
    self == other
  end

  def hash
    [x, y].hash
  end
end
