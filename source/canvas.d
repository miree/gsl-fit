import cairo;
import cairo.pdf;	

struct Canvas
{
	Context c;
	/** w and h in inch
	 * x1 < x2 and y1 < y2 give the user space bounding box
	 */
	this(double x1, double y1, double x2, double y2, 
		 double w, double h)
	{
		c = Context(new PDFSurface("canvas.pdf",w,h));
		c.identityMatrix();
		c.scale(1,-1);      // invert y-axis
		c.translate(0,-h);  // origin is the lower left corner
		c.scale(w/(x2-x1),h/(y2-y1)); // scale the bounding box to fit in w and h
		c.translate(-x1,-y1); // move the bounding box to the left 

		//test();
	}
	
	//this(double x1, double y1, double x2,
	//	 double w, double h)
	//{
	//	this(w,h,x1,y1,x2,y1+(x2-x1)*h/w);
	//}
	this(double x1, double y1, double x2, double y2,
		 double w)
	{
		this(x1,y1,x2,y2, w,w*(y2-y1)/(x2-x1));
	}
	
	void identityStroke(double lineWidth = 1)
	{
		c.save();
		c.identityMatrix();
		c.lineWidth(lineWidth);
		c.stroke();
		c.restore();
	}
	
	void test()
	{
	 	c.lineWidth(1);
		c.setSourceRGB(1,0,0);
		c.moveTo(0,0);
		c.lineTo(10,0);
		c.stroke();
		c.setSourceRGB(0,0,1);
		c.moveTo(0,0);
		c.lineTo(0,10);
		c.stroke();
	}
	
}

