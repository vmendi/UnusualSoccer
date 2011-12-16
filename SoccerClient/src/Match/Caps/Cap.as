package Match.Caps
{
	import Box2D.Common.*;
	import Box2D.Common.Math.*;
	
	import Assets.MatchAssets;
	
	import Match.Framework.*;
	import Match.MatchMain;
		
	import com.greensock.*;
	import com.greensock.plugins.RemoveTintPlugin;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	
	public class Cap extends PhyEntity
	{
		static public const Radius:Number = 15;
		
		protected var _Name:String = null;						// Nombre del jugador
		protected var _Dorsal:int = 0;							// Nº de dorsal del jugador
						
		protected var _OriginalDefense:int = 50;				// Tal y como vienen del manager, sin multiplicar por Fitness
		protected var _OriginalPower:int = 50;				
		protected var _OriginalControl:int = 50; 
				
		protected var _OwnerTeam:Team = null;					// Equipo dueño de la chapa
		
		private var _Influence:Sprite = null;					// Objeto visual para pintar la influencia de la chapa
		private var _TimeShowingInfluence:Number = 0;			// Tiempo que se lleva mostrando el area de influencias desde la última vez que se mando pintar
		private var _ShowInfluence:Boolean=false;				// Indica si se está pintando
		
		private var _CapId:int = (-1);							// Identificador de la chapa
		
		private var _ColorInfluence:int = Enums.FriendColor; 		// Color del radio de influencia visual
		private var _SizeInfluence:int = AppParams.RadiusPaseAlPie;	// tamaño del radio de influencia visual
		
		private var _IsInjured : Boolean = false;
				
		public var YellowCards:int = 0; 						// Número de tarjetas amarillas (2 => roja => expulsión)
		
		
		public function get OwnerTeam() : Team	  { return _OwnerTeam; }
		public function get Name() : String		  { return _Name; }
		public function get Id() : int			  { return _CapId; }
		
		public function get IsInjured() : Boolean { return _IsInjured; }
		
		public function get Power() : int		  {	return Math.floor((OwnerTeam.Fitness / 100.0) * OriginalPower); }
		public function get Control() : int		  {	return Math.floor((OwnerTeam.Fitness / 100.0) * OriginalControl); }
		public function get Defense() : int		  {	return Math.floor((OwnerTeam.Fitness / 100.0) * OriginalDefense); }
		
		public function get OriginalPower() : int	 { return _OriginalPower; }
		public function get OriginalControl() : int	 { return _OriginalControl; }
		public function get OriginalDefense() : int  { return _OriginalDefense; }
		
		public function get Ghost() : Entity { return this.OwnerTeam.Ghost; }	// Ghost de la chapa (solo hay uno por equipo)

		//
		// Inicializa una chapa
		//
		public function Cap(team:Team, id:int, descCap:Object) : void
		{	
			var phyInit : Object = { radius: AppParams.Screen2Physic( Radius ),
									 isBullet: true, 				// UseCCD: Detección de colisión continua (Ninguna chapa se debe atravesar)
									 mass: AppParams.CapMass,
									 isSleeping: true,
									 allowSleep: true, 
									 friction: .3, 
									 restitution: .8,			// Fuerza que recupera en un choque (old: 0.6)
									 linearDamping: AppParams.CapLinearDamping, 
									 angularDamping: AppParams.CapLinearDamping }
				
			var asset:Class = null;
				
			// Elegimos el asset de jugador o portero (y con la equipación primaria o secundaria)
			if (id != 0)
			{
				asset = team.UseSecondaryEquipment? Assets.MatchAssets.Cap2 : Assets.MatchAssets.Cap;
				phyInit.categoryBits = 1;			// Choca con todo	
			}
			else
			{
				asset = team.UseSecondaryEquipment? Assets.MatchAssets.Goalkeeper2 : Assets.MatchAssets.Goalkeeper;
				phyInit.categoryBits = 2;			// Choca con todo tb	
			}
			
			super(asset, MatchMain.Ref.Game.GameLayer, PhyEntity.Circle, phyInit);
			
			// Reasignamos la escala de la chapa, ya que la física la escala para que encaje con el radio físico asignado
			this.Visual.scaleX = 1.0;
			this.Visual.scaleY = 1.0;
		
			// Asigna el aspecto visual según que equipo sea. Tenemos que posicionarla en el frame que se llama como el quipo
			_Visual.gotoAndStop( team.Name );
			
			_Name = descCap.Name;
			_Dorsal = descCap.DorsalNumber;
			_OwnerTeam = team;
			_IsInjured = descCap.IsInjured;

			_OriginalPower   = descCap.Power;
			_OriginalControl = descCap.Control;
			_OriginalDefense = descCap.Defense;

			// Nos registramos a los eventos de entrada del ratón!
			_Visual.addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			_Visual.addEventListener(MouseEvent.MOUSE_OVER, OnMouseOver);
			_Visual.addEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
			
			_Visual.addEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);

			// Creamos un Sprite linkado a la chapa, donde pintaremos los radios de influencia de la chapa
			// Estos sprites los introducimos como hijos del campo, para asegurar que se vean debajo de las chapas 
			_Influence = new Sprite();
			MatchMain.Ref.Game.TheField.Visual.addChild(_Influence);
			DrawInfluence();
			_Influence.alpha = 0.0;
			
			_CapId = id;
			
			// Solo mostramos la foto de los amigos del equipo local (privacidad...)
			if (team.IsLocalUser)
				LoadFacebookPicture(descCap.FacebookID);
			
			// Auto-añadimos al manager de entidades
			MatchMain.Ref.Game.TheEntityManager.AddTagged(this, "Team"+(team.IdxTeam +1).toString() + "_" + _CapId.toString());
		}
		
		private function OnRemovedFromStage(e:Event) : void
		{
			_Visual.removeEventListener(MouseEvent.MOUSE_OVER, OnMouseOver);
			_Visual.removeEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
		}
		
		private function OnMouseDown(e : MouseEvent) : void
		{			
			MatchMain.Ref.Game.TheInterface.OnClickCap(this);
		}
		
		private function OnMouseOver(e : MouseEvent) : void
		{	
			if (TweenMax.getTweensOf(OnRealOver).length == 0)
				TweenMax.delayedCall(0.8, OnRealOver);
		}
		private function OnRealOver() : void
		{
			MatchMain.Ref.Game.TheInterface.OnOverCap(this);
		}
		private function OnMouseOut(e : MouseEvent) : void
		{
			// Nos aseguramos de que no hay Outs sin Overs
			if (TweenMax.getTweensOf(OnRealOver).length > 0)
				TweenMax.killDelayedCallsTo(OnRealOver);
			else
				MatchMain.Ref.Game.TheInterface.OnOutCap(this);
		}
		
		//
		// Dispara con una fuerza sobre una chapa. La fueza debe especificarse entre 0, 1
		//
		public function Shoot(dir:Point, force:Number) : void
		{
			// Calculamos el vector final
			var vecForce:Point = new Point();
			dir.normalize( force * AppParams.MaxCapImpulse );
			
			// El vector de fuerza lo aplicamos en el sentido contrario, ya que funciona como una goma elástica
			vecForce.x = -dir.x; 
			vecForce.y = -dir.y;
			
			// Aplicamos el impulso al cuerpo físico
			PhyObject.body.ApplyImpulse( new b2Vec2( vecForce.x, vecForce.y ), PhyObject.body.GetWorldCenter() );
		}
		
		//
		// Obtiene el vector de dirección desde la chapa que apunta hacia la portería contraria
		//
		public function get DirToGoal() : Point
		{
			// Obtenemos el punto donde está la portería contraria
			var target:Point = Field.GetCenterGoal( Enums.AgainstSide( OwnerTeam.Side ) );
			// Retornamos el vector de direccion
			return( target.subtract( GetPos() ) );
		}
		
		//
		// Devuelve si está atacando o no.
		// Se considera que una chapa está atacando cuando está en la mitad del campo oponente
		//
		public function get IsAttacking() : Boolean
		{
			var x:Number = GetPos().x;
			var centerX:Number = Field.CenterX;
			
			if( OwnerTeam.Side == Enums.Left_Side )
			{
				if( x < centerX )
					return false;
				return true;
			}
			else
			{
				if( x > centerX )
					return false;
				return true;
			}
		}
		
		//
		// Cambia el color del radio de influencia
		// NOTE: Esto no quiere decir que se pinte!
		//
		public function SetInfluenceAspect( color:int, size:Number ) : void
		{
			// Si algo cambia, reasignamos
			if( color != _ColorInfluence || size != _SizeInfluence )
			{
				_ColorInfluence = color;
				_SizeInfluence = size;
				
				DrawInfluence( );
			}
		}
		
		//
		// Pinta las influencias
		//
		protected function DrawInfluence( ) : void
		{
			_Influence.graphics.clear( );
			_Influence.graphics.lineStyle( 1, _ColorInfluence, 0.4 );
			
			_Influence.graphics.beginFill( _ColorInfluence, 0.3 );
			_Influence.graphics.drawCircle( 0, 0, _SizeInfluence );
			_Influence.graphics.endFill();
		}
		
		//
		// Mostramos/ocultamos el radio de influencia de la chapa
		// y reseteamos el tiempo mostrando influencia
		public function set ShowInfluence( value:Boolean ) : void
		{
			if (value != _ShowInfluence)
			{	
				_ShowInfluence = value;
				_TimeShowingInfluence = 0;
				
				if( _ShowInfluence )			
					TweenMax.to( this._Influence, 1, {alpha:1} );
				else
					TweenMax.to( this._Influence, 1, {alpha:0} );
			}
		}
		
		public function get ShowInfluence() : Boolean
		{
			return _ShowInfluence;
		}		
		
		public override function Draw( elapsed:Number ) : void
		{
			super.Draw( elapsed );
			
			if( this.Visual )
			{
				// Reasignamos la posicion del objeto de radio de influencia, para que siga a la chapa
				_Influence.x = GetPos().x;			
				_Influence.y = GetPos().y;
			}
				
			// Apagamos al cabo de 2 segundos
			if( ShowInfluence )
			{
				_TimeShowingInfluence += elapsed;
				
				if( _TimeShowingInfluence > 2.0 )
					ShowInfluence = false;
			}
		}
		
		private function LoadFacebookPicture(facebookID : Number) : void
		{
			if (facebookID != -1)
			{
				mFacebookPictureLoader = new Loader();
				mFacebookPictureLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
				mFacebookPictureLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, OnError);
				mFacebookPictureLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnError);
				mFacebookPictureLoader.load(new URLRequest("http://graph.facebook.com/"+facebookID+"/picture/?type=square"));
			}
			
			function OnLoadComplete(e:Event) : void
			{
				var loaderInfo : LoaderInfo = e.target as LoaderInfo;
				
				if (loaderInfo.bytesLoaded != 0 && loaderInfo.bytesLoaded == loaderInfo.bytesTotal)
				{
					var theBitmap : Bitmap = loaderInfo.content as Bitmap;

					theBitmap.scaleX = 0.55;
					theBitmap.scaleY = 0.55;
					theBitmap.x = -14;
					theBitmap.y = -14;
					theBitmap.smoothing = true;
					
					var maskSPR : Sprite = new Sprite();
					maskSPR.graphics.beginFill(0xFF00FF, 1);
					maskSPR.graphics.drawCircle(0, 0, 12.5);
					maskSPR.graphics.endFill();
					
					(Visual as DisplayObjectContainer).addChild(theBitmap);
					(Visual as DisplayObjectContainer).addChild(maskSPR)

					theBitmap.mask = maskSPR;
						
					mFacebookPictureLoader = null;
				}
			}
			
			function OnError(e:Event):void
			{
				// Poco podemos hacer... No merece la pena mandarlo al servidor, fallara mucho y no sabremos distinguir por qué
			}
			
		}
		
		private var mFacebookPictureLoader : Loader;
	}
}