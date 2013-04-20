package utils
{
	import flash.geom.Point;

	public class MathUtils
	{
		static public function Multiply(vect : Point, scalar : Number) : Point
		{
			return new Point(vect.x*scalar, vect.y*scalar);
		}
		
		static public function Dot(vect1 : Point, vect2 : Point) : Number
		{
			return vect1.x*vect2.x + vect1.y*vect2.y;
		}
		
		
		//
		// Comprueba si un punto(pos) está contenido dentro de un rectángulo
		//
		static public function PointInRect(pos:Point, topLeft:Point, size:Point) : Boolean
		{
			if (pos.x < (topLeft.x) || pos.y < (topLeft.y))
				return false;
			if (pos.x >= topLeft.x+size.x || pos.y >= topLeft.y+size.y)
				return false;
			
			return true;
		}
		
		//
		// Comprueba si un círculo(pos, radio) está contenido "completamente" dentro de un rectángulo
		//
		static public function CircleInRect(pos:Point, radius:Number, topLeft:Point, size:Point) : Boolean
		{
			if (pos.x < (topLeft.x+radius) || pos.y < (topLeft.y+radius))
				return( false );
			if (pos.x > topLeft.x+size.x-radius || pos.y > topLeft.y+size.y-radius)
				return( false );
			
			return true;
		}
		
		//
		// Comparación con margen de error, fundamental para no comparar nunca dos flotantes con ==
		//
		static public function ThresholdEqual(a : Number, b : Number, threshold : Number) : Boolean
		{
			return Math.abs(b-a) <= threshold;
		}

		static public function ThresholdNotEqual(a : Number, b : Number, threshold : Number) : Boolean
		{
			return Math.abs(b-a) > threshold;
		}

		static public function Tanh(x : Number) : Number
		{
			return (Math.exp(2*x) - 1) / (Math.exp(2*x) + 1);
		}
		
		// http://keith-hair.net/blog/2008/08/04/find-intersection-point-of-two-lines-in-as3/
		//---------------------------------------------------------------
		//Checks for intersection of Segment if as_seg is true.
		//Checks for intersection of Line if as_seg is false.
		//Return intersection of Segment AB and Segment EF as a Point
		//Return null if there is no intersection
		//---------------------------------------------------------------
		static public function LineIntersectLine(A:Point,B:Point,E:Point,F:Point,as_seg:Boolean):Point 
		{
			var ip:Point;
			var a1:Number;
			var a2:Number;
			var b1:Number;
			var b2:Number;
			var c1:Number;
			var c2:Number;
			
			a1= B.y-A.y;
			b1= A.x-B.x;
			c1= B.x*A.y - A.x*B.y;
			a2= F.y-E.y;
			b2= E.x-F.x;
			c2= F.x*E.y - E.x*F.y;
			
			var denom:Number=a1*b2 - a2*b1;
			if (denom == 0) {
				return null;
			}
			ip=new Point();
			ip.x=(b1*c2 - b2*c1)/denom;
			ip.y=(a2*c1 - a1*c2)/denom;
			
			//---------------------------------------------------
			//Do checks to see if intersection to endpoints
			//distance is longer than actual Segments.
			//Return null if it is with any.
			//---------------------------------------------------
			if(as_seg){
				if(Math.pow(ip.x - B.x, 2) + Math.pow(ip.y - B.y, 2) > Math.pow(A.x - B.x, 2) + Math.pow(A.y - B.y, 2))
				{
					return null;
				}
				if(Math.pow(ip.x - A.x, 2) + Math.pow(ip.y - A.y, 2) > Math.pow(A.x - B.x, 2) + Math.pow(A.y - B.y, 2))
				{
					return null;
				}
				
				if(Math.pow(ip.x - F.x, 2) + Math.pow(ip.y - F.y, 2) > Math.pow(E.x - F.x, 2) + Math.pow(E.y - F.y, 2))
				{
					return null;
				}
				if(Math.pow(ip.x - E.x, 2) + Math.pow(ip.y - E.y, 2) > Math.pow(E.x - F.x, 2) + Math.pow(E.y - F.y, 2))
				{
					return null;
				}
			}
			return ip;
		}
	}
}