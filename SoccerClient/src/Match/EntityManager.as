package Match
{
	public class EntityManager
	{
		public function get Items() : Array
		{
			return ItemList;
		}
				
		// Si el identificador es nulo o está vacio se agregará el item sin etiqueta
		// El identificador debe ser único.
		public function AddTagged( item:*, identifier:String) : void
		{
			if (Find(identifier) != null)
				throw new Error("WTF 23");
			
			if (identifier != null && identifier != "")
				TaggedEntities[identifier] = item;
			
			Add(item);
		}
		
		// Obtiene un elemento a partir de su identificador. Si el elemento no existe devuelve NULL
		public function Find(identifier:String) : *
		{
			return TaggedEntities[identifier];
		}
		
		public function Add(item:*) : void
		{
			if (ItemList.indexOf(item) != -1)
				throw new Error("WTF 24");
			
			ItemList.push(item);
		}
		
		public function Remove(item:*) : void
		{			
			var idx:int = ItemList.indexOf(item);
			
			if (idx == -1)
				throw new Error("WTF 7233");
			
			ItemList.splice(idx, 1);
		}
				
		public function Run( elapsed:Number ) : void
		{
			for each (var item:Entity in Items)
			{
				item.Run(elapsed);
			}
		}
		
		public function Draw( elapsed:Number ) : void
		{
			for each (var item:Entity in Items)
			{
				item.Draw(elapsed);
			}
		}
		
		private var ItemList:Array = new Array();						// Lista de todos los elementos añadidos al manager
		private var TaggedEntities:Array = new Array();					// Lista de entidades etiquetadas
	}
	
}