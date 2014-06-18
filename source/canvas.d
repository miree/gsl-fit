import cairo;
import cairo.pdf;	

struct Canvas
{
private:
	double w,h;
	Box box;
	
public:
	Context context;

	/** w and h in inch
	 * x1 < x2 and y1 < y2 give the user space bounding box
	 */
	this(Box box, double w, double h)
	{
		this.w = w;
		this.h = h;
		this.box = box;
		
		context = Context(new PDFSurface("canvas.pdf",w,h));
		context.identityMatrix();
		context.scale(1,-1);      // invert y-axis
		context.translate(0,-h);  // origin is the lower left corner
		context.scale(w/(box.point2.x-box.point1.x),h/(box.point2.y-box.point1.y)); // scale the bounding box to fit in w and h
		context.translate(-box.point1.x,-box.point1.y); // move the bounding box to the left 
	}
	
	this(Box box, double w)
	{
		this(box, w,w*(box.point2.y-box.point1.y)/(box.point2.x-box.point1.x));
	}
	
	void identityStroke(double lineWidth = 1)
	{
		context.save();
		context.identityMatrix();
		context.lineWidth(lineWidth);
		context.stroke();
		context.restore();
	}
	void horiLine(double y)
	{
		context.moveTo(box.point1.x, y);
		context.lineTo(box.point2.x, y);
	}
	void vertLine(double x)
	{
		context.moveTo(x, box.point1.y);
		context.lineTo(x, box.point2.y);
	}
	void line(T)(Point!T points[])
	{
		if (points.length)
			context.moveTo(points[0].x, points[0].y);
		foreach(point; points[1..$])
			context.lineTo(point.x, point.y);
	}
	void line(T)(T xs[], T ys[])
	{
		import std.algorithm;
		ulong len = min(xs.length, ys.length);
		if (len)
			context.moveTo(xs[0], ys[0]);
		foreach(i; 1..len)
			context.lineTo(xs[i], ys[i]);
	}
	
	// forward all calls to context
	auto opDispatch(string m, Args...)(Args args)
	{
		return mixin("context."~m~"(args)");
	}

}

