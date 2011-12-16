package Match.Framework
{
	//
	// Manager de entidades. Tiene las siguientes características
	//
	// 	- Centralización --> Contenedor de todas las entidades del mundo; lo que permite poder realizar una acción a "todas" las entidades
	//	- Abstracto --> Soporta cualquier tipo de entidad  
	//  - Globalización --> Recuperar entidades desde cualquier punto de la aplicación
	//  - Identificación --> Permite identificar las entidadas por etiquetas, para poder recuperarlas
	//	  en cualquier momento sin la necesidad de guardar punteros 
	//
	public class EntityManager
	{
		protected var ItemList:Array = new Array();							// Lista de todos los elementos añadidos al manager
		protected var TaggedEntities:Array = new Array();					// Lista de entidades etiquetadas
		
		//
		// Retorna la lista de items
		//
		public function get Items( ) : Array
		{
			return( ItemList );
		}
				
		//
		// Añade un elemento a la lista del manager y lo asocia con una etiqueta (identifier), de tal 
		// forma que posteriormente podamos manejarlo a través del mismo.
		// Si el identificador es nulo o está vacio se agregará el item sin etiqueta
		// El identificador debe ser único.
		//
		public function AddTagged( item:*, identifier:String = null ) : void
		{
			if( Find( identifier ) == null )
			{
				// Registramos la etiqueta asociada al identificador
				if( identifier != null && identifier != "" )
					TaggedEntities [ identifier ] = item;
				
				// Añadimos a la lista de entidades
				Add( item );
			}
			else
				throw new Error("WTF 23");
		}
		
		//
		// Obtiene un elemento a partir de su identificador
		// NOTE: Si el elemento no existe devuelve NULL
		//
		public function Find( identifier:String ) : *
		{
			return( TaggedEntities [ identifier ] );
		}
		
		//
		// Añade un elemento a la lista del manager 
		//
		public function Add(item:*) : void
		{
			if (ItemList.indexOf(item) == -1)
				ItemList.push(item);
			else
				throw new Error("WTF 24");
		}
		
		//
		// Retorno: Devuelve 'true' si lo elimina o 'false' si no lo encuentra
		//
		public function Remove( item:* ) : Boolean
		{			
			var idx:int = ItemList.indexOf(item);
			if (idx != -1)
				ItemList.splice(idx, 1);
			
			return idx != -1;
		}
				
		//
		// Se ejecuta a frecuencia constante, una vez cada tick lógic		
		//
		public function Run( elapsed:Number ) : void
		{
			// Ejecutamos todas las entidades
			for each (var item:Entity in Items)
			{
				item.Run(elapsed);
			}
		}
		
		//
		// Se ejecuta a velocidad de pintado
		//
		public function Draw( elapsed:Number ) : void
		{
			// Ejecutamos todas las entidades
			for each (var item:Entity in Items )
			{
				item.Draw(elapsed);
			}
		}
	}
	
}