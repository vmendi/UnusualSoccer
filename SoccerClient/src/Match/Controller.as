package Match
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import org.osflash.signals.Signal;

	public class Controller extends EventDispatcher
	{
		public static const SuccessMouseUp:int = 0;			// Finalizó terminando la operación (Mouse Up)
		public static const Canceled:int = 1;				// Finalizó por cancelación (Llamada externa al stop)
		
		// Eventos		
		public var OnStart:Signal = new Signal();			// Evento lanzado cuanto el controlador se arranca
		public var OnStop:Signal = new Signal( int );		// Evento lanzado cuanto el controlador se detiene por cualquier razón
		
		// Estamos entre un Start y un Stop?
		public function get IsStarted() : Boolean	{	return _IsStarted; 	}
		
		// Chapa sobre la que se esta aplicando el controlador
		public function get Target() : Cap	{ return _Target; }
		
		
		//
		// Arranca el sistema de control direccional con el ratón
		//
		public function Start(_cap: Cap): void					
		{	
			_Target = _cap;
			_TargetPos = _Target.GetPos().clone();								
			
			// Nos registramos a los eventos de entrada de todo el flash
			AddHandlers(_Target.Visual.stage);
			
			_IsStarted = true;
			
			// lanzamos evento
			OnStart.dispatch();
		}
		
		//
		// Detiene el sistema de control direccional con el ratón, lo que implica dejar de visualizarlo
		//
		public function Stop(reason:int):void
		{
			// Nos desregistramos de los eventos de entrada 
			RemoveHandlers(_Target.Visual.stage);
			
			// Indicamos que estamos detenidos
			_IsStarted = false;
			
			// lanzamos evento
			OnStop.dispatch(reason);
		}
		
		//
		// Nos registramos a los eventos de ratón del objeto indicado "stage" 
		//
		protected function AddHandlers(object:DisplayObject):void
		{
			object.stage.addEventListener(MouseEvent.MOUSE_UP, MouseUp);	
			object.stage.addEventListener(MouseEvent.MOUSE_MOVE, MouseMove);
		}
		protected function RemoveHandlers(object:DisplayObject):void
		{
			object.stage.removeEventListener(MouseEvent.MOUSE_UP, MouseUp);	
			object.stage.removeEventListener(MouseEvent.MOUSE_MOVE, MouseMove);
		}
		
		public function MouseUp(e: MouseEvent) :void { Stop(SuccessMouseUp); }		
		public function MouseMove(e: MouseEvent) :void { e.updateAfterEvent(); }	// updateAfterEvent -> Refresca a la velocidad del evento, no a la del framerate
		
		// Verifica si el controlador tiene unos valores válidos (para overrides en hijos)
		public function IsValid() : Boolean	{ return true; }
				
		// Vector que va desde el centro del Target a las coordenadas actuales del raton
		public function get Direction() : Point
		{			
			// 
			// MouseX, MouseY es relativo a espacio de transformación del DisplayObject sobre el cual lo pedimos
			// TargetPos fue pedida respecto al padre (GetPos), asi que para ambas coordenadas esten en el mismo espacio:
			var relativeTo:DisplayObject = _Target.Visual.parent;
			
			return new Point((relativeTo.mouseX - _TargetPos.x), (relativeTo.mouseY - _TargetPos.y));
		}		
		
		protected var _Target:Cap; 
		protected var _TargetPos:Point;
		protected var _IsStarted:Boolean = false;		
	}		
}