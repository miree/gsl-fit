import gsld.multifit_nlin;
import canvas;
import std.math;

void drawPointWithError(Canvas canvas, Dp!double p, double size, Canvas.Symbol symbol = Canvas.Symbol.circle)
{
	canvas.drawPoint(Point!double(p.c,p.v), size, symbol);
	canvas.drawError(Point!double(p.c,p.v), p.s, size/10);
}

void drawPointWithErrorMarginals(Canvas canvas, Dp!double p, double size, Canvas.Symbol symbol = Canvas.Symbol.circle)
{
	canvas.drawPoint(Point!double(p.c,p.v), size, symbol);
	canvas.drawError(Point!double(p.c,p.v), p.s, size/10);
	canvas.drawErrorMarginals(Point!double(p.c,p.v), p.s, size/10);
}

import cairo;
Box boundingBox(Dp!double[] points)
{
	assert(points.length >= 2);
	
	double x1 = points[0].c;
	double x2 = x1;
	double y1 = points[0].v-points[0].s;
	double y2 = points[0].v+points[0].s;
	foreach(point; points)
	{
		import std.algorithm;
		x1 = min(x1,point.c);
		x2 = max(x2,point.c);
		y1 = min(y1,point.v-point.s);
		y2 = max(y2,point.v+point.s);
	}
	return Box(x1,y1, x2,y2);
}
double width(Box box)
{
	return box.point2.x-box.point1.x;
}
double height(Box box)
{
	return box.point2.y-box.point1.y;
}
double xCenter(Box box)
{
	return 0.5*(box.point2.x+box.point1.x);
}
double yCenter(Box box)
{
	return 0.5*(box.point2.y+box.point1.y);
}
Box addLeftRightMargins(Box box, double left, double right)
{
	double w = box.width();
	return Box(box.point1.x-w*left,box.point1.y,box.point2.x+w*right,box.point2.y);
}
Box addBottomTopMargins(Box box, double bottom, double top)
{
	double h = box.height();
	return Box(box.point1.x,box.point1.y-h*bottom,box.point2.x,box.point2.y+h*top);
}

Box scaleWidthCenter(Box box, double factor)
{
	double x0 = box.xCenter();
	double w2 = 0.5*box.width();
	return Box(x0-factor*w2,box.point1.y, x0+factor*w2,box.point2.y);
}
Box scaleHeightCenter(Box box, double factor)
{
	double y0 = box.yCenter();
	double h2 = 0.5*box.height();
	return Box(box.point1.x,y0-factor*h2, box.point2.x,y0+factor*h2);
}
Box scaleCenter(Box box, double factor)
{
	return box.scaleWidthCenter(factor).scaleHeightCenter(factor);
}
