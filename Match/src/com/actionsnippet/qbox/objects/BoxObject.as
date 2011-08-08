﻿package com.actionsnippet.qbox.objects{		import flash.display.*	import flash.events.*;		import com.actionsnippet.qbox.*		import Box2D.Dynamics.*;	import Box2D.Collision.*;	import Box2D.Collision.Shapes.*;	import Box2D.Common.Math.*;	import Box2D.Dynamics.Joints.*;		/**	BoxObject is a subclass of {@link com.actionsnippet.qbox.QuickObject} and should only be instantiated with the {@link com.actionsnippet.qbox.QuickBox2D#addBox()} method.		@author Zevan Rosser	@version 1.0	*/	public class BoxObject extends QuickObject {				   		public function BoxObject(qbox:QuickBox2D, params:Object){			super(qbox, params);		}				override protected function defaultParams(p:Object):void{			 						 		}		 		override protected function build():void{			var p:Object = params;						if(p.skin is DisplayObject){				bodyDef.userData = p.skin;				var t:Number = p.skin.rotation;				 				p.skin.rotation = 0;				if (!p.width){				  p.width = p.skin.width / 30;				}				if (!p.height){				  p.height = p.skin.height / 30;				}				p.skin.rotation = t;			}						if (!p.width) p.width = 1;			if (!p.height) p.height = 1;						var boxDef:b2PolygonDef = new b2PolygonDef();			shapeDef = boxDef;			var hw:Number = p.width / 2;			var hh:Number = p.height / 2;			boxDef.SetAsBox(hw, hh);					boxDef.density = p.density;			boxDef.friction = p.friction;			boxDef.restitution = p.restitution;			boxDef.filter.maskBits = p.maskBits;			boxDef.filter.categoryBits = p.categoryBits;			boxDef.filter.groupIndex = p.groupIndex;			boxDef.isSensor = p.isSensor;						if (p.skin is Class){			    bodyDef.userData = new p.skin();				if (p.scaleSkin == true){					bodyDef.userData.width=p.width * 30;					bodyDef.userData.height=p.height * 30;				}			}else		    if (p.skin is DisplayObject){								 			}else if (p.skin != "none"){				bodyDef.userData = new Sprite();				with(bodyDef.userData.graphics){					 					lineStyle(p.lineThickness,p.lineColor, p.lineAlpha);					beginFill(p.fillColor, p.fillAlpha);					hw *= 30;					hh *= 30;					drawRect(-hw, -hh, p.width * 30, p.height * 30);				}				if (p.scaleSkin == true){				  bodyDef.userData.width=p.width * 30;			      bodyDef.userData.height=p.height * 30;				}			}						body =w.CreateBody(bodyDef);			shape = body.CreateShape(boxDef);					}	}}