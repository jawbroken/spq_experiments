require 'rubygems'
require 'rmagick'
require 'chipmunk'

$space = CP::Space.new
$space.gravity = CP::Vec2.new(0, 50)
$static_body = CP::Body.new(1.0/0, 1.0/0)
$static_body.p = CP::Vec2.new(0, 0)

$image = Magick::Image::read('128.png').first
pixels = $image.export_pixels_to_str(0, 0, $image.columns, $image.rows, "I")
pixel_table = []

# convert string to table
(0..$image.columns-1).each do |x|
  row = []
  (0..$image.rows-1).each do |y|
    row << pixels[y*$image.columns + x]
  end
  pixel_table << row
end

Quadtree = Struct.new(:value, :topleft, :topright, :bottomleft, :bottomright)

# simple recursive definition, fairly inefficient as it resums regions
# bottom up build would be better
def make_quadtree(pixels, width, height)
  $count = 0
  def make_quadtree_r(pixels, x, y, w, h)
    sum = 0
    (0..w-1).each do |x_off|
      (0..h-1).each do |y_off|
        sum += pixels[x+x_off][y+y_off]
      end
    end
    # all black or white test
    if sum == 0
      $count += 1
      sides = [
      CP::Shape::Segment.new($static_body, CP::Vec2.new(x,y), CP::Vec2.new(x+w,y), 0.1),
      CP::Shape::Segment.new($static_body, CP::Vec2.new(x+w,y), CP::Vec2.new(x+w,y+h), 0.1),
      CP::Shape::Segment.new($static_body, CP::Vec2.new(x+w,y+h), CP::Vec2.new(x,y+h), 0.1),
      CP::Shape::Segment.new($static_body, CP::Vec2.new(x,y+h), CP::Vec2.new(x,y), 0.1),
      ]
      sides.each{|x| x.e = 1.0; $space.add_static_shape(x)}
      Quadtree.new(0, nil, nil, nil, nil)
    elsif sum == 255*w*h
      $count += 1
      Quadtree.new(1, nil, nil, nil, nil)
    else
      Quadtree.new(nil, 
        make_quadtree_r(pixels, x,     y,     w/2, h/2),
        make_quadtree_r(pixels, x+w/2, y,     w/2, h/2),
        make_quadtree_r(pixels, x,     y+h/2, w/2, h/2),
        make_quadtree_r(pixels, x+w/2, y+h/2, w/2, h/2))
    end
  end
  tree = make_quadtree_r(pixels, 0, 0, width, height)
  puts "Number of nodes: #{$count} vs #{width*height} for full data (#{$count.to_f/(width*height)*100}%)"
  tree
end

$quadtree = make_quadtree(pixel_table, $image.columns, $image.rows)

$ball_body = CP::Body.new(5, CP.moment_for_circle(5, 0, 2, CP::Vec2.new(0,0)))
$ball_shape = CP::Shape::Circle.new($ball_body, 2, CP::Vec2.new(0,0))
$ball_body.p = CP::Vec2.new(85, 30)
$ball_shape.e = 0.875

$space.add_body($ball_body)
$space.add_shape($ball_shape)

#############################
# bunch of hacky GL code here
require 'rubygems'
require 'gl'
require 'glu'
require 'glut'

include Gl
include Glu
include Glut

glutInit
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA)
glutInitWindowSize(512, 512)
glutCreateWindow("Sparse Pixel Quadtree")
# nice mid blue, make sure everything is being rendered
glClearColor(0.5, 0.5, 1.0, 1.0)
glPointSize(1.0)
glLineWidth(0.5)
glEnable(GL_LINE_SMOOTH)
glEnable(GL_POINT_SMOOTH)
glEnable(GL_BLEND)
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
glHint(GL_LINE_SMOOTH_HINT, GL_DONT_CARE)
glHint(GL_POINT_SMOOTH_HINT, GL_DONT_CARE)
glMatrixMode(GL_PROJECTION)
glLoadIdentity()
glOrtho(0, 512, 512, 0, -1.0, 1.0)

SLEEP_TICKS = 10
def timercall(value)
  glutTimerFunc(SLEEP_TICKS, method(:timercall).to_proc, 0)
  glutPostRedisplay
end

keyboard = lambda do |key, x, y|
  if key == ?\e || key == ?q
      exit(0)
  end
end

def draw_quadtree(qt, x, y, w, h)
  return if qt.nil?
  if !qt.value.nil?
    if qt.value == 1
      glColor3f(1.0,1.0,1.0)
    else
      glColor3f(0.0, 0.0, 0.0)
    end
    glBegin(GL_QUADS)
      glVertex2f(x,y)
      glVertex2f(x+w,y)
      glVertex2f(x+w,y+h)
      glVertex2f(x, y+h)
    glEnd()
    glColor3f(1.0, 0.0, 0.0)
    glBegin(GL_LINE_STRIP)
      glVertex2f(x,y)
      glVertex2f(x+w,y)
      glVertex2f(x+w,y+h)
      glVertex2f(x, y+h)
      glVertex2f(x, y)
    glEnd()
  else
    draw_quadtree(qt.topleft,     x,     y,     w/2, h/2)
    draw_quadtree(qt.topright,    x+w/2, y,     w/2, h/2)
    draw_quadtree(qt.bottomleft,  x,     y+h/2, w/2, h/2)
    draw_quadtree(qt.bottomright, x+w/2, y+h/2, w/2, h/2)
  end
end

def display
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    draw_quadtree($quadtree, 0, 0, 512, 512)
    
    10.times do
      $space.step(1.0/60.0/10)
    end
    
    pos = $ball_body.p
    
    glColor4f(0.0, 1.0, 0.0, 0.5)
    glBegin(GL_TRIANGLE_FAN)
      glVertex2f(pos.x*4, pos.y*4)
      (0..360).step(5) do |theta|
        glVertex2f(pos.x*4+Math::sin(theta*Math::PI/180)*2*4,
                   pos.y*4+Math::cos(theta*Math::PI/180)*2*4)
      end
    glEnd()
    
    glutSwapBuffers
end

glutDisplayFunc(method(:display).to_proc)
glutTimerFunc(SLEEP_TICKS, method(:timercall).to_proc, 0)
glutKeyboardFunc(keyboard)
glutMainLoop()

