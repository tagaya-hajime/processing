class Arrow {
  PVector position;
  PVector to;
  color cc;
  int mode;
  Arrow(float px, float py, float tx, float ty, color c, int m) {
    position =new PVector(px, py);
    to = new PVector(tx, ty);
    cc=c;
    mode = m;
  }
  void draw() {
    stroke(cc);
    strokeWeight(10);
    float angle = atan2(to.y-position.y, to.x-position.x);
    line(position.x, position.y, to.x, to.y);
    pushMatrix();
    translate(to.x, to.y);
    rotate(angle);
    line(0, 0, -30*cos(0.5), 30*sin(0.5));
    line(0, 0, -30*cos(0.5), -30*sin(0.5));
    popMatrix();
    stroke(100, 100, 0);
    strokeWeight(1);
  }
  void mode() {
    switch(mode) {
    case 0:
      break;
    case 1:
      position.x += width_velocity;
      ball.setPosition(arrow.position.x, 900);
      if (position.x<300 || position.x>600)width_velocity = -width_velocity;
      break;
    case 2:
      to.x += width_velocity;
      if (to.x<300 || to.x>600)width_velocity = -width_velocity;
      break;
    case 3:
      to.y += height_velocity;
      if (to.y<10 || to.y>600)height_velocity = -height_velocity;
      break;
    case 4:
      ball.setVelocity((to.x-position.x)*1.5, (to.y-position.y)*1.5);
      mode++;
      break;
    default:
    }
  }
}
