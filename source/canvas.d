import cairo;
import cairo.pdf;	

struct Canvas
{
	double w,h;
	Box box;
	Context context;

	/** w and h in inch
	 * box give the user space bounding box
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
	
	void identityStroke(double lineWidth)
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
	void line(T)(Point!T[] points)
	{
		if (points.length)
			context.moveTo(points[0].x, points[0].y);
		foreach(point; points[1..$])
			context.lineTo(point.x, point.y);
	}
	void line(T)(T[] xs, T[] ys)
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




	enum Symbol 
	{ 
		circle, 
		box, 
		diamond, 
		triangle, 
		downtriangle, 
		star, 
		star2, 
		star3, 
		star4 
	}
	
	struct DeviceTransformation
	{
		Point!double pDevice;
		Context *c;
		this(ref Context c, Point!double p)
		{
			this.c = &c;
			pDevice = c.userToDevice(p);
			c.save();
			c.identityMatrix();
			c.translate(pDevice.x, pDevice.y);
		}
		~this()
		{
			c.restore();
		}
	}
	
	void drawPoint(Point!double p, double size, Canvas.Symbol symbol)
	{
		void drawStar(int N, double size, double reduction = 1.5)
		{
			import std.math;
			context.moveTo(size*sin(0.0),-size*cos(0.0));
			foreach(i;1..(N*2))
			{
				double radius = size/(1+reduction*(i%2));
				context.lineTo(radius*sin(2.0*PI*i/N/2),-radius*cos(2.0*PI*i/N/2));
			}
			context.closePath();
		}
	
		auto dt = DeviceTransformation(context,p);
		final switch (symbol)
		{
			case Canvas.Symbol.circle:
				import std.math;
				context.arc(0,0, size*0.71, 0,2*PI);
			break;             
			case Canvas.Symbol.box:
				context.rectangle(-size*0.71,-size*0.71,
								  2*size*0.71,2*size*0.71);
			break;             
			case Canvas.Symbol.diamond:
				context.moveTo(-size, 0    );
				context.lineTo(0    ,  size);
				context.lineTo( size, 0    );
				context.lineTo(0    , -size);
				context.closePath();
			break;
			case Canvas.Symbol.triangle:
				context.moveTo(-size,-size+size/4.0);
				context.lineTo( size,-size+size/4.0);
				context.lineTo(    0, size+size/4.0);
				context.closePath();
			break;
			case Canvas.Symbol.downtriangle:
				context.moveTo(-size,  size-size/4.0);
				context.lineTo( size,  size-size/4.0);
				context.lineTo(    0, -size-size/4.0);
				context.closePath();
			break;
			case Canvas.Symbol.star:
				drawStar(5,size);
			break;
			case Canvas.Symbol.star2:
				drawStar(4,size);
			break;
			case Canvas.Symbol.star3:
				drawStar(6,size);
			break;
			case Canvas.Symbol.star4:
				drawStar(7,size);
			break;
		}
		context.fill();
	}
	
	void drawError(Point!double p, double deltaPlus, double deltaMinus, double size, Canvas.Symbol symbol = Canvas.Symbol.circle)
	{
		context.moveTo(p.x,p.y+deltaPlus);
		context.lineTo(p.x,p.y-deltaMinus);
		//identityStroke(0.1*size);
		identityStroke(3);
	}
	void drawError(Point!double p, double delta, double size)
	{
		drawError(p,delta,delta,size);
	}
	void drawErrorMarginals(Point!double p, double deltaPlus, double deltaMinus, double size)
	{
		auto sizeu = context.deviceToUser( Point!double(size,size) );
		context.moveTo(p.x-sizeu.x/20.,p.y-deltaMinus);
		context.lineTo(p.x+sizeu.x/20.,p.y-deltaMinus);
		context.moveTo(p.x-sizeu.x/20.,p.y+deltaPlus);
		context.lineTo(p.x+sizeu.x/20.,p.y+deltaPlus);
		//identityStroke(0.1*size);
		identityStroke(3);
	}
	void drawErrorMarginals(Point!double p, double delta, double size)
	{
		drawErrorMarginals(p,delta,delta,size);
	}
	
}
