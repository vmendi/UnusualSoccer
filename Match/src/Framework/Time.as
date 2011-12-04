package Framework
{
	//
	// Clase para calcular el tiempo que ha pasado
	//
	public class Time
	{
		// Devuelve el tiempo en milisegundos que ha pasado desde la última vez que se llamó a GetElapsed
		public function GetElapsed() : Number
		{
			// Calculamos el tiempo en este instante.
			// NOTE: El objeto 'Date' se recrea, ya que getTime siempre devuelve el valor de tiempo en la creación
			var now:Date = new Date();
			var currentMS:Number = now.getTime();
			
			// Si no se ha pasado nunca por la función asignamos el último valor al actual (elapsed será 0 )
			if( _LastMilliseconds == 0 )
				_LastMilliseconds = currentMS;
			
			// Calculamos la diferencia de tiempo desde la última vez hasta ahora, y guardamos el valor de ahora
			_LastElapsed = currentMS - _LastMilliseconds; 
			_LastMilliseconds = currentMS;
			
			return _LastElapsed; 
		}
		
		// Obtiene el último elapsed que se calculó en milisegundos
		public function get LastElapsed() : Number
		{
			return _LastElapsed;
		}
		
		// La proxima vez devolveremos 0 independientemente del tiempo que haya pasado de verdad
		public function ResetElapsed() : void
		{
			_LastMilliseconds = 0
		}
		
		protected var _LastMilliseconds:Number = 0;			// Último valor en milisegundos 
		protected var _LastElapsed:Number = 0;				// Último elapsed time en milisegundos
	}
}