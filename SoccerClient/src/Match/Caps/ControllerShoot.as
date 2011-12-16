package Match.Caps
{
	import Box2D.Common.Math.b2Math;
	
	import Match.Framework.*;
	import Match.MatchMain;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;

	
	public class ControllerShoot extends Controller
	{		
		protected var canvas       : Sprite;
		protected var angle	       : Number; 
		protected var maxLongLine  : uint;
		protected var colorLine	   : uint;
		protected var thickness	   : uint;
		protected var potenciaTiro : TextField;
		
		static protected const MIN_FORCE : Number = 0.1; // Fuerza mínima que debe tener un disparo.
		
		public function ControllerShoot(canvas:Sprite, maxLongLine: uint, colorLine: uint = 0, thickness: uint = 1)
		{
			// Campo de texto en el que indicaremos la potencia
			var myFormat:TextFormat = new TextFormat();
			myFormat.size = 14;
			myFormat.bold = true;
			myFormat.font = "HelveticaNeue LT 77 BdCn"; 
			var campoPotenciaTiro : TextField = new TextField(); 
			campoPotenciaTiro.selectable = false;
			campoPotenciaTiro.mouseEnabled = false;
			campoPotenciaTiro.embedFonts = true;
			campoPotenciaTiro.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			campoPotenciaTiro.defaultTextFormat = myFormat;
			campoPotenciaTiro.textColor = 0xFFFFFF;
			campoPotenciaTiro.width = 800;
			
			canvas.addChild(campoPotenciaTiro);
			
			this.maxLongLine = maxLongLine;
			this.canvas 	 = canvas;
			this.thickness   = thickness;
			this.potenciaTiro = campoPotenciaTiro;
		}
	
		//
		// Detiene el sistema de control direccional con el ratón, lo que
		// implica dejar de visualizarlo
		//
		public override function Start( _cap:Cap ):void
		{
			super.Start(_cap);
			
			// Hacemos visible el campo de texto de potencia
			potenciaTiro.text = "";
			potenciaTiro.visible = true;
		}
		
		public override function Stop(reason:int):void
		{
			super.Stop(reason);
				
			// Eliminamos la parte visual
			canvas.graphics.clear( );
						
			potenciaTiro.visible = false;
		}
		
		//
		// Hemos soltado el botón del ratón = Efectuamos el disparo!
		//
		public override function MouseUp( e: MouseEvent ) : void
		{
			super.MouseUp( e );
		}
		
		public override function IsValid() : Boolean
		{
			// Obtenemos la dirección truncada a la máxima longitud
			return Direction.length >= Cap.Radius;
		}
			
		public override function MouseMove(e: MouseEvent) :void
		{			
			super.MouseMove(e);
			
			angle = Math.atan2(-( canvas.mouseY - yInit ), -( canvas.mouseX - xInit ));
			
			var dir:Point = Direction.clone(); // Dirección truncada a la máxima longitud
			var source:Point = new Point( xInit, yInit); // Posición del centro de la chapa
			var recoil:Point = source.add( dir ); // Punto del mouse respecto a la chapa, cuando soltemos nos dará la potencia del tiro
			
			// Mientras que no sacas la flecha de la chapa no es un tiro válido
			canvas.graphics.clear( );
			var color:uint = this.colorLine;

			if( !this.IsValid() )
			{
				color = 0xff0000;
				// Campo de texto de la potencia
				potenciaTiro.text = ""
			}
			else
			{
				// Queremos calcular el lugar exacto al que llegará la chapa si no choca con nada
				// Hacemos lo mismo que hace el Box2D
				var impulse:Number = Force*AppParams.MaxCapImpulse;
				// Calculamos la velocidad inicial como lo hace el motor al aplicar un impulso
				var v:Number = (1.0/AppParams.CapMass) * impulse;
				// Calculamos la modificación que la velocidad sufrirá en cada iteración por acción del linearDamping: b2Island.as line 188
				var vmod:Number = b2Math.b2Clamp(1.0 - MatchMain.Ref.Game.TheGamePhysics.TheBox2D.timeStep * AppParams.CapLinearDamping, 0.0, 1.0);
				var dist:Number = 0;
				while (v > 0.01)
				{
					v *= vmod;
					dist += (v * MatchMain.Ref.Game.TheGamePhysics.TheBox2D.timeStep);
				}
				dist *= AppParams.PixelsPerMeter;

				var target : Point = Direction.clone();
				target.normalize(dist)
				var destination:Point = source.subtract( target );
				
				//var gradientBoxMatrix:Matrix = new Matrix();
				//gradientBoxMatrix.createGradientBox(760, 760, 0, source.x-(766/2), source.y-(760/2));
				//gradientBoxMatrix.rotate(0.5*Math.PI);
				canvas.graphics.lineStyle( Cap.Radius*2, 0xFFFFFF, 0.2 );
				//canvas.graphics.lineGradientStyle(GradientType.RADIAL, [0xFFFFFF, 0xFFFFFF], [0.3, 0.0], [0, 100], gradientBoxMatrix);
				canvas.graphics.moveTo( source.x, source.y );
				canvas.graphics.lineTo( destination.x, destination.y );
				
				// Campo de texto de la potencia
				potenciaTiro.text = "PO: " + Math.round(Force*100);
				potenciaTiro.x = recoil.x;
				potenciaTiro.y = recoil.y - 30;
			}
			
			canvas.graphics.lineStyle( thickness, color, 0.7 );
			canvas.graphics.moveTo( source.x, source.y );
			canvas.graphics.lineTo( recoil.x, recoil.y );
			//e.updateAfterEvent( );
		}
		
		//
		// Obtenemos el vector de dirección del disparo
		// NOTE: El vector estará truncado a una longitud máxima de maxLongLine 
		// 
		public override function get Direction() : Point
		{
			var dir:Point = super.Direction;
			var distance:Number = dir.length;
			
			var myScale : Number = maxLongLine / AppParams.MaxCapImpulse;
			var myMaxLongLine : Number = ( AppParams.MinCapImpulse + ( (AppParams.MaxCapImpulse - AppParams.MinCapImpulse ) * ( _Target.Power / 100 ) ) ) * myScale;
			
			if ( distance > myMaxLongLine )
			{
				dir.normalize( myMaxLongLine );
				distance = myMaxLongLine;
			}
			
			return( dir );
		}
		//
		// Obtiene la fuerza de disparo como un valor de ( 0 - 1.0)
		// 
		public function get Force() : Number
		{
			var len:Number = Direction.length - Cap.Radius;
			
			if( len < MIN_FORCE)
				len = MIN_FORCE;

			return( len / (maxLongLine-Cap.Radius) );
		}
	}
}