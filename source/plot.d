import gsld.multifit_nlin;
import canvas;
import std.math;
enum Symbol { circle, box, diamond, triangle, downtriangle, star, star2, star3, star4 }
void drawPoint(Canvas c, Dp!double p, double size, Symbol symbol = Symbol.circle)
{
	void drawStar(Canvas c, int N, double size, double reduction = 1.5)
	{
		c.context.moveTo(p.c+size*sin(0),p.v+size*cos(0));
	    foreach(i;0..(N*2))
	    {
			double radius = size/(1+reduction*(i%2));
			c.context.lineTo(p.c+radius*sin(2.0*PI*i/N/2),p.v+radius*cos(2.0*PI*i/N/2));
		}
		c.context.closePath();
	}
	
	c.context.setSourceRGB(1,0,0);
	final switch (symbol)
	{
		case Symbol.circle:
			c.context.arc(p.c, p.v,size*0.71,0,2*PI);
		break;             
		case Symbol.box:
			c.context.rectangle(p.c-size*0.71,p.v-size*0.71,2*size*0.71,2*size*0.71);
		break;             
		case Symbol.diamond:
			c.context.moveTo(p.c-size,p.v     );
			c.context.lineTo(p.c     ,p.v+size);
			c.context.lineTo(p.c+size,p.v     );
			c.context.lineTo(p.c     ,p.v-size);
			c.context.closePath();
		break;
		case Symbol.triangle:
			c.context.moveTo(p.c-size,p.v-size+size/4.0);
			c.context.lineTo(p.c+size,p.v-size+size/4.0);
			c.context.lineTo(p.c     ,p.v+size+size/4.0);
			c.context.closePath();
		break;
		case Symbol.downtriangle:
			c.context.moveTo(p.c-size,p.v+size-size/4.0);
			c.context.lineTo(p.c+size,p.v+size-size/4.0);
			c.context.lineTo(p.c     ,p.v-size-size/4.0);
			c.context.closePath();
		break;
		case Symbol.star:
			drawStar(c,5,size);
		break;
		case Symbol.star2:
			drawStar(c,4,size);
		break;
		case Symbol.star3:
			drawStar(c,6,size);
		break;
		case Symbol.star4:
			drawStar(c,7,size);
		break;
	}
	c.context.fill();
}
void drawPointWithError(Canvas c, Dp!double p, double size, Symbol symbol = Symbol.circle)
{
	drawPoint(c,p,size,symbol);
	c.context.moveTo(p.c,p.v-p.s);
	c.context.lineTo(p.c,p.v+p.s);
	c.identityStroke(size/3);
}
void drawPointWithErrorMarginals(Canvas c, Dp!double p, double size, Symbol symbol = Symbol.circle)
{
	drawPointWithError(c,p,size,symbol);
	c.context.moveTo(p.c-size/2,p.v-p.s);
	c.context.lineTo(p.c+size/2,p.v-p.s);
	c.context.moveTo(p.c-size/2,p.v+p.s);
	c.context.lineTo(p.c+size/2,p.v+p.s);
	c.identityStroke(size/3);
}
