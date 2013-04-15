package Match
{
	import Box2D.Collision.Shapes.b2MassData;
	import Box2D.Common.*;
	import Box2D.Common.Math.*;
	import Box2D.actionsnippet.qbox.QuickObject;
	
	import com.greensock.*;
	
	import flash.display.Bitmap;
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
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.resources.ResourceManager;
	
	import utils.Delegate;
	
	public class Cap extends PhyEntity
	{
		static public const Radius:Number = 15;
		
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
	
		public function set TeletransportPos(v:Point) : void { _TeletransportPos = v; }
		
		// Almacenamos en la propia chapa el tiro en paralelo con el enemigo a ejecutar en el siguiente tiro
		public function get ParallelShoot() : ShootInfo { return _ParallelShoot; }
		public function set ParallelShoot(s:ShootInfo) : void { _ParallelShoot = s; }
		
		
		private var _CapId:int = -1;							// Identificador de la chapa
		private var _Name:String;								// Nombre del jugador
		private var _Dorsal:int;								// Nº de dorsal del jugador
		
		private var _OriginalDefense:int = 50;					// Tal y como vienen del manager, sin multiplicar por Fitness
		private var _OriginalPower:int = 50;				
		private var _OriginalControl:int = 50; 
		
		private var _OwnerTeam:Team;							// Equipo dueño de la chapa
		
		private var _Influence:Sprite;							// Objeto visual para pintar la influencia de la chapa
		private var _TimeShowingInfluence:Number;				// Tiempo que se lleva mostrando el area de influencias desde la última vez que se mando pintar
		private var _ShowInfluence:Boolean=false;				// Indica si se está pintando
		
		private var _ColorInfluence:int=Enums.FriendColor; 			// Color del radio de influencia visual
		private var _SizeInfluence:int=MatchConfig.RadiusPaseAlPie;	// tamaño del radio de influencia visual
		
		private var _IsInjured : Boolean = false;
		
		private var _TeletransportPos : Point;
		private var _ParallelShoot : ShootInfo;
		private var _FacebookPictureLoader : Loader;
		
		
		public var YellowCards:int = 0; 						// Número de tarjetas amarillas (2 => roja => expulsión)
		
		
		public function Cap(team:Team, id:int, descCap:Object, useSecondaryEquipment:Boolean, game : Game) : void
		{			
			super(game.GameLayer, ResourceManager.getInstance().getClass("match", "Cap"), game);
									
			// Elegimos el asset de jugador o portero y con la equipación primaria o secundaria
			PrepareVisualCap(_Visual, team.PredefinedTeamNameID, useSecondaryEquipment, id == 0)
						
			// Reasignamos la escala de la chapa, ya que la física la escala para que encaje con el radio físico asignado
			_Visual.scaleX = 1.0;
			_Visual.scaleY = 1.0;
			
			_CapId = id;
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
			_Game.InfluencesLayer.addChild(_Influence);
			DrawInfluence();
			_Influence.alpha = 0.0;
						
			// Solo mostramos la foto de los amigos del equipo local (privacidad...)
			if (team.IsLocalUser) // Ahora si ahora no (3/23/2013, 4/10/2013)
				LoadFacebookPicture(descCap.FacebookID);
		}
		
		protected override function get PhysicsParams() : Object
		{
			return { radius: MatchConfig.Screen2Physic(Radius),
					 categoryBits: 1,								// Choca con todo
					 isBullet: true, 								// UseCCD: Detección de colisión continua (Ninguna chapa se debe atravesar)
					 mass: MatchConfig.CapMass,
					 isSleeping: true,
					 allowSleep: true, 
					 friction: .3, 
					 restitution: .8,								// Fuerza que recupera en un choque
					 linearDamping: MatchConfig.CapLinearDamping, 
					 angularDamping: MatchConfig.CapLinearDamping };	
		}
		
		static public function PrepareVisualCap(visualCap : *, predefinedTeamNameID : String, useSecondary : Boolean, isGoalKeeper : Boolean) : void
		{
			if (useSecondary)
				visualCap.First.visible = false;
			visualCap.Second.visible = !visualCap.First.visible;
			
			if (isGoalKeeper)
				visualCap.Regular.visible = false;
			visualCap.Goalkeeper.visible = !visualCap.Regular.visible;
			
			// Mandamos al frame de la equipacion
			visualCap.First.gotoAndStop(predefinedTeamNameID);
			visualCap.Second.gotoAndStop(predefinedTeamNameID);
			
			// Paramos la animacion del Halo
			visualCap.Halo.addFrameScript(0, function():void { visualCap.Halo.stop(); });
		}
		
		// Cue visual de que es el turno del equipo de la chapa
		public function ShowMyTurnVisualCue() : void
		{
			_Visual.Halo.play();
		}
		
		private function OnRemovedFromStage(e:Event) : void
		{
			try 
			{
				_Visual.removeEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
				_Visual.removeEventListener(MouseEvent.MOUSE_OVER, OnMouseOver);
				_Visual.removeEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
			}
			catch(e:Error) 
			{ 
				ErrorMessages.LogToServer("WTF 198"); 
			}
		}
		
		private function OnMouseDown(e : MouseEvent) : void
		{
			try 
			{
				_Game.TheInterface.OnClickCap(this);
			}
			catch(e:Error) 
			{ 
				ErrorMessages.LogToServer("WTF 98"); 
			}
		}
		
		private function OnMouseOver(e : MouseEvent) : void
		{	
			try 
			{
				if (TweenMax.getTweensOf(OnRealOver).length == 0)
					TweenMax.delayedCall(0.8, OnRealOver);
			}
			catch(e:Error) 
			{ 
				ErrorMessages.LogToServer("WTF 88"); 
			}
		}
		private function OnRealOver() : void
		{
			try 
			{
				_Game.TheInterface.OnOverCap(this);
			}
			catch(e:Error)
			{
				ErrorMessages.LogToServer("WTF 38");
			}
		}
		private function OnMouseOut(e : MouseEvent) : void
		{
			try 
			{
				// Si habia algun over pendiente, lo cancelamos
				if (TweenMax.getTweensOf(OnRealOver).length > 0)
					TweenMax.killDelayedCallsTo(OnRealOver);
				
				_Game.TheInterface.OnOutCap(this);
			}
			catch(e:Error) 
			{ 
				ErrorMessages.LogToServer("WTF 78"); 
			}
		}
				
		// Obtiene el vector de dirección desde la chapa que apunta hacia la portería contraria
		public function get DirToGoal() : Point
		{
			// Obtenemos el punto donde está la portería contraria
			var target:Point = Field.GetCenterGoal( Enums.AgainstSide( OwnerTeam.Side ) );
			// Retornamos el vector de direccion
			return target.subtract(GetPos());
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
		// Cambia el color del radio de influencia. NOTE: Esto no quiere decir que se pinte!
		//
		public function SetInfluenceAspect(color:int, size:Number) : void
		{
			// Si algo cambia, reasignamos
			if (color != _ColorInfluence || size != _SizeInfluence)
			{
				_ColorInfluence = color;
				_SizeInfluence = size;
				
				DrawInfluence( );
			}
		}
		
		//
		// Pinta las influencias
		//
		protected function DrawInfluence() : void
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
		public function set ShowInfluence(value:Boolean) : void
		{
			if (value != _ShowInfluence)
			{	
				_ShowInfluence = value;
				_TimeShowingInfluence = 0;
				
				if (_ShowInfluence)			
					TweenMax.to(this._Influence, 1, {alpha:1});
				else
					TweenMax.to(this._Influence, 1, {alpha:0});
			}
		}
		
		public function get ShowInfluence() : Boolean
		{
			return _ShowInfluence;
		}		
		
		public override function Draw(elapsed:Number) : void
		{
			super.Draw(elapsed);
			
			// Reasignamos la posicion del objeto de radio de influencia, para que siga a la chapa
			_Influence.x = GetPos().x;			
			_Influence.y = GetPos().y;
							
			// Apagamos al cabo de 2 segundos
			if (ShowInfluence)
			{
				_TimeShowingInfluence += elapsed;
				
				if (_TimeShowingInfluence > 2.0)
					ShowInfluence = false;
			}
		}
		
		private function LoadFacebookPicture(facebookID : Number) : void
		{	
			if (facebookID != -1)
			{
				_FacebookPictureLoader = new Loader();
				_FacebookPictureLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
				_FacebookPictureLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, OnError);
				_FacebookPictureLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnError);
				_FacebookPictureLoader.load(new URLRequest("//graph.facebook.com/"+facebookID+"/picture/?type=square"),
											new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain));
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
						
					_FacebookPictureLoader = null;
				}
			}
			
			function OnError(e:Event):void
			{
				// Poco podemos hacer... No merece la pena mandarlo al servidor, fallara mucho y no sabremos distinguir por qué
			}
		}
		
		
		public function FadeClone(timeInSeconds : Number) : void
		{
			var cloned : DisplayObject = new (getDefinitionByName(getQualifiedClassName(Visual)) as Class)();
			Visual.parent.addChild(cloned);
			cloned.x = Visual.x; 
			cloned.y = Visual.y;
			cloned.rotationZ = PhyObj.angle * 180.0 / Math.PI;
			
			Cap.PrepareVisualCap(cloned, OwnerTeam.PredefinedTeamNameID, Visual.Second.visible, Visual.Goalkeeper.visible);
			
			// Hacemos desvanecer el clon
			TweenMax.to(cloned, timeInSeconds, {alpha:0, onComplete: Delegate.create(onFinishTween, cloned) });
			
			function onFinishTween(theCap:DisplayObject) : void
			{
				theCap.parent.removeChild(theCap);
			}
		}
		
		public function GotoTeletransportAndResetPos() : void
		{
			if (_TeletransportPos != null)
			{
				FadeClone(0.3);
				SetPos(_TeletransportPos);
				_TeletransportPos = null;
			}
		}
				
		// Immovable Goalkeeper...
		public function SetImmovable(immovable : Boolean) : void
		{
			Cap.SetImmovable(_PhyObject, immovable);
		}
		
		static public function SetImmovable(phyObject : QuickObject, immovable : Boolean) : void
		{
			var massData : b2MassData = new b2MassData();			
			massData.I = phyObject.body.m_I;
			
			if (immovable)
				massData.mass = 0;
			else
				massData.mass = MatchConfig.CapMass;
			
			phyObject.body.SetMass(massData);
		}
	}
}