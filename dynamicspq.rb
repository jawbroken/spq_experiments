require 'thread'
Quadtree = Struct.new(:value, :topleft, :topright, :bottomleft, :bottomright)

$quadtree = Quadtree.new(1, nil, nil, nil, nil)
$qmutex = Mutex.new

$cursor_centre = [256, 256]
$cursor_radius = 16

def destroy_quadtree(qt, centre, radius)
  def destroy_quadtree_r(qt, x, y, w, h, centre, radius)
    
  end
  destroy_quadtree_r(qt, 0, 0, 512, 512, centre, radius)
end

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
  elsif key == ?w
    $cursor_centre[1] -= 1 if $cursor_centre[1] > 0
  elsif key == ?s
    $cursor_centre[1] += 1 if $cursor_centre[1] < 511
  elsif key == ?a
    $cursor_centre[0] -= 1 if $cursor_centre[0] > 0
  elsif key == ?d
    $cursor_centre[0] += 1 if $cursor_centre[0] < 511
  elsif key == ?-
    $cursor_radius -= 1 if $cursor_radius > 1
  elsif key == ?=
    $cursor_radius += 1 if $cursor_radius < 128
  elsif key == " "[0]
    $qmutex.synchronize do
      destroy_quadtree($quadtree, $cursor_centre, $cursor_radius)
    end
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
    $qmutex.synchronize do
      draw_quadtree($quadtree, 0, 0, 512, 512)
    end
    # show cursor
    glColor4f(0.0, 1.0, 0.0, 0.5)
    glBegin(GL_TRIANGLE_FAN)
      glVertex2f($cursor_centre[0], $cursor_centre[1])
      (0..360).step(5) do |theta|
        glVertex2f($cursor_centre[0]+Math::sin(theta*Math::PI/180)*$cursor_radius,
                   $cursor_centre[1]+Math::cos(theta*Math::PI/180)*$cursor_radius)
      end
    glEnd()
    glutSwapBuffers
end

glutDisplayFunc(method(:display).to_proc)
glutTimerFunc(SLEEP_TICKS, method(:timercall).to_proc, 0)
glutKeyboardFunc(keyboard)
glutMainLoop()

