package Match
{
	import flash.geom.Point;	
	import mx.collections.ArrayCollection;

	public final class Formations
	{
		// Todas las formaciones en coordenadas del manager.
		static public function get TheFormations() : ArrayCollection
		{
			var ret : ArrayCollection = new ArrayCollection();
			
			ret.addItem( {	Name:"3-2-2", 
							Points: [ 	new Point(173, 320),
										new Point(73, 248),
										new Point(173, 248),
										new Point(273, 248),
										new Point(128, 165),
										new Point(218, 165),
										new Point(103, 90),
										new Point(243, 90) ] 
			} );
			ret.addItem( {	Name:"3-3-1", 
							Points: [	new Point(173, 320),
										new Point(73, 248),
										new Point(173, 248),
										new Point(273, 248),
										new Point(73, 165),
										new Point(173, 165),
										new Point(273, 165),
										new Point(173, 90) ] 
			} );
			ret.addItem( {	Name:"4-1-2",			
							Points: [ 	new Point(173, 320),
										new Point(52, 248),
										new Point(132, 248),
										new Point(214, 248),
										new Point(296, 248),
										new Point(173, 165),
										new Point(103, 90),
										new Point(243, 90) ] 
			} );
			ret.addItem( {	Name:"4-2-1", 
							Points: [ 	new Point(173, 320),
										new Point(52, 248),
										new Point(132, 248),
										new Point(214, 248),
										new Point(296, 248),
										new Point(128, 165),
										new Point(218, 165),
										new Point(173, 90) ] 
			} );
			ret.addItem( {	Name:"1-2-4", 
							Points: [ 	new Point(173, 320),
										new Point(173, 248),
										new Point(128, 165),
										new Point(218, 165),
										new Point(52, 90),
										new Point(132, 90),
										new Point(214, 90),
										new Point(296, 90) ] 
			} );
			ret.addItem( {	Name:"1-3-3",			
							Points: [ 	new Point(173, 320),
										new Point(173, 248),
										new Point(73, 165),
										new Point(173, 165),
										new Point(273, 165),										
										new Point(73, 90),
										new Point(173, 90),
										new Point(273, 90) ] 	
			} );				
			ret.addItem( {	Name:"1-4-2",			
							Points: [ 	new Point(173, 320),
										new Point(173, 248),
										new Point(52, 165),
										new Point(132, 165),
										new Point(214, 165),
										new Point(296, 165),					
										new Point(103, 90),
										new Point(243, 90) ] 					
			} );			
			ret.addItem( {	Name:"2-1-4",			
							Points: [ 	new Point(173, 320),
										new Point(128, 248),
										new Point(218, 248),
										new Point(173, 165),
										new Point(52, 90),
										new Point(132, 90),
										new Point(214, 90),
										new Point(296, 90) ] 
			} );
			ret.addItem( {	Name:"2-2-3", 
							Points: [ 	new Point(173, 320),
										new Point(128, 248),
										new Point(218, 248),
										new Point(128, 165),
										new Point(218, 165),
										new Point(73, 90),
										new Point(173, 90),
										new Point(273, 90) ] 
			} );
			ret.addItem( {	Name:"2-3-2",
							Points: [ 	new Point(173, 320),
										new Point(128, 248),
										new Point(218, 248),
										new Point(73, 165),
										new Point(173, 165),
										new Point(273, 165),
										new Point(103, 90),
										new Point(243, 90) ] 
			} );
			ret.addItem( {	Name:"2-4-1",			
							Points: [ 	new Point(173, 320),
										new Point(128, 248),
										new Point(218, 248),
										new Point(52, 165),
										new Point(132, 165),
										new Point(214, 165),
										new Point(296, 165),
										new Point(173, 90) ] 
			} );			
			ret.addItem( {	Name:"3-1-3",			
							Points: [ 	new Point(173, 320),
										new Point(73, 248),
										new Point(173, 248),
										new Point(273, 248),
										new Point(173, 165),
										new Point(73, 90),
										new Point(173, 90),
										new Point(273, 90) ] 					
			} );
			
			return ret;
		}
		
		// Formaciones en el formato que le gusta al partido: Un hash que va de "nombre" a un array de Points. En coordenadas de campo de partido.
		static public function get TheFormationsTransformedToMatch() : Object
		{
			var formations : ArrayCollection = TheFormations;
			var ret : Object = new Object();
			
			for each(var form : Object in formations)
			{
				ret[form.Name] = new Array();
				
				for each(var p : Point in form.Points)
				{
					var transformed : Point = new Point( (363 - (p.y*1.02))*0.93, (p.x - 8)*1.333*0.93 );
					ret[form.Name].push(transformed);
				}
			}
			return ret;
		}
		
	}
}