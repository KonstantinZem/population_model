package konstantinz.community.comStage.behaviour{
	
	import konstantinz.community.auxilarity.*

	public class BaseMotionBehaviour implements MotionBehaviour{
		
		
		protected const CONSTANT_STATE:String = 'constant';//Отмечаются только модели поведения для которого не предусмотрено переключение между различными состояниями
		protected const HOLD_STATE:String = 'hold';
		protected const RESET_STATE:String = 'reset';
		protected const BORDERS_APPROACHING_LIMIT:int = 3;
		protected const STAY:int = 0;
		protected const ON_RIGHT:int = 1;
		protected const ON_LEFT:int = 2;
		protected const ON_DOWN:int = 3;
		protected const ON_UP:int = 4;
		
		private var previosChessDeskI:int;
		private var previosChessDeskJ:int;
		
		protected var rightCorner:int//Правый край моделируемой территории
		protected var bottomCorner:int//Нижний край моделируемой территории
		protected var debugLevel:String;
		protected var currentPlaceQuality:int;
		protected var stepLength:int;
		protected var populationArea:Array;
		protected var behaviourName:String;
		protected var state:String;
		protected var directionAlreadyChoised:Boolean;
		protected var amINearBorder:Boolean;//Флаг того, что особь находится возле границы
		
		protected var newPosition:Array = new Array();
		protected var individualName:int;
		protected var indDirection:int;
		
		ARENA::DEBUG{
			protected var modelEvent:ModelEvent;
			protected var msgString:String;
			public var messenger:Messenger;
			}
		
		function BaseMotionBehaviour(dbgLevel:String='3'){
			behaviourName = 'RandomWalker';
			directionAlreadyChoised = false;
			state = CONSTANT_STATE;//По умолчанию модель поведения не имеет условия начала и окончания
			debugLevel = dbgLevel;
			
			ARENA::DEBUG{
				messenger = new Messenger();
				modelEvent = new ModelEvent();
				messenger.setDebugLevel (debugLevel);
				messenger.setMessageMark('Behaviour');
				//castRandomGenerator();
				}
			
			previosChessDeskI = 0;
			previosChessDeskJ = 0;
			stepLength = 1;
			indDirection = 0;
			}
		
		public function setPopulationArea(area:Array):void{//передает классу ссылку на массив координат внутри класса CommunityStage А еще лучше передавать это через конструктор
			try{
			
				if(area.length == 0){
					throw new Error('Population area array is empty');
					}
				populationArea = area;
				rightCorner = populationArea[0].length -1;//Отнимаем два, чтобы особь не вышла за край массива сделав шаг [длинна масива -1] + 1
				bottomCorner = populationArea.length - 1;
				
			}catch(err:Error){
				ARENA::DEBUG{
					msgString = err.message;
					messenger.message(msgString, modelEvent.ERROR_MARK);
					}
				}
			} 
		
		public function getPlaceQuality(currentY:int, currentX:int):int{
			return populationArea[currentY][currentX].speedDeleyA;
			}
			
		public function getNewPosition(currentY:int, currentX:int):Array{//Класс на основе выбранного алгоритма поведения определяет новую позицию особи
			
			onBeginChoisingPosition(currentY, currentX);
			
			try{
				
				if(currentY < 0|| currentX < 0){
					throw new Error('Cordinates out of scene')
					}
				
				if(directionAlreadyChoised == false){//Направление передвижения может выбираться и в другом месте. Флаг подымается, чтобы небыло повторов
					if(state != HOLD_STATE){//Если выбранное направление не нужно удерживать в течении нескольких ходов
						indDirection = getMovieDirection();//Вычисляем новое направление движения особи
						if(state != CONSTANT_STATE){ //Если линия поведение имеет начало и конец
							state = HOLD_STATE;//Делаем пометку о начале данной линии поведения, чтобы удерживать направление до конца 
							}
						}
					}
					
			doStep(indDirection, currentY, currentX);
		
			onEndChoisingPosition();
			
			}catch(err:Error){
				ARENA::DEBUG{
					msgString = 'Individual ' + individualName + ': ' + 'in getNewPosition() ' + err.message + ' (Y=' + currentY + ', X=' + currentX + ')';
					messenger.message(msgString, modelEvent.ERROR_MARK);
					}
				}	
				
			return newPosition;
			}
		

		public function getState():String{//На основе выбранного алгоритма поведения определяется новое состояние особи
			return state;
			}
		
		public function getName():String{
			return behaviourName;
			};
		
		public function getDirection():int{
			return indDirection;
			};
		
		public function setIndividualNumber(newNumber:int):void{
			individualName = newNumber;
			}
			
		public function setStepLength(stLength:int = 1):void{
			stepLength = stLength;
			}
		
		public function setDirection(currentDirection:int):void{
			if(currentDirection < 6){
				state = HOLD_STATE;
				}else{
					state = CONSTANT_STATE;
					}
			
			indDirection = currentDirection;
			};
		
		public function isOnBorder():Boolean{
			return amINearBorder;
		};
		
		protected function getMovieDirection():int{
			//В самой среде flash, если поставить цифру 4 генератор будет выдавать направления неравномерно, с перекосом в значение 3
			return Math.round(Math.random()*5);//Пускай лучше этот код будет прописан в одном месте
			};
		
		protected function castRandomGenerator():void{
			var castDirection:int;
			var rightNumb:int = 0;
			var leftNumb:int = 0;
			var upNumb:int = 0;
			var downNumb:int = 0;
			var stayNumb:int = 0;
			
			for(var i:int = 0; i < 1000; i++){
				castDirection = getMovieDirection();
				switch(castDirection){
					case STAY: //Стоим наместе
						stayNumb++;
					break;
					case ON_RIGHT://Направо
						rightNumb++;
					break;
					case ON_LEFT://Налево
						leftNumb++;
					break;
					case ON_DOWN: //Вниз
						downNumb++;
					break;
					case ON_UP://Вверх
						upNumb++;
					break;

					default://Стоим на месте
						stayNumb++;
					break;
				}
			}
				ARENA::DEBUG{
					msgString = ('Random number generator casting results:\n up = ' + upNumb + '\n down = ' + downNumb + '\n right = ' + rightNumb + '\n left = ' + leftNumb + '\n stay = ' + stayNumb)
					messenger.message(msgString, modelEvent.DEBUG_MARK);
					}
			}
		
		protected function doStep(direction:int, currentY:int, currentX:int):void{
			switch(direction){
				case STAY: //Стоим наместе
					onStay(currentY, currentX);
				break;
				case ON_RIGHT://Направо
					onStepRight(currentY, currentX);
				break;
				case ON_LEFT://Налево
					onStepLeft(currentY, currentX);
				break;
				case ON_DOWN: //Вниз
					onStepDown(currentY, currentX);
				break;
				case ON_UP://Вверх
					onStepUp(currentY, currentX);
				break;

				default://Стоим на месте
					onStay(currentY, currentX);
				break;
				}
		};
		
		protected function onStepUp(currentY:int, currentX:int):void{
			if (currentY >= BORDERS_APPROACHING_LIMIT){
				newPosition.y = currentY - stepLength;
				}else{
					newPosition.y = currentY + stepLength;
					amINearBorder = true;
					}
			}
		
		protected function onStepDown(currentY:int, currentX:int):void{
			if(currentY >= bottomCorner - BORDERS_APPROACHING_LIMIT){//Если особь дошла до нижнего края сцены
				newPosition.y = currentY - stepLength;
				amINearBorder = true;
				}else{
					newPosition.y = currentY + stepLength;
					}
			}
		
		protected function onStepRight(currentY:int, currentX:int):void{
			if(currentX >= rightCorner - BORDERS_APPROACHING_LIMIT){//Если особь дошла до правого края сцены
				newPosition.x = currentX - stepLength;//Делаем шаг назад
				amINearBorder = true;
				}else{
					newPosition.x = currentX + stepLength;
					}
		}
		
		protected function onStepLeft(currentY:int, currentX:int):void{//По моему это шаг вниз
			if(currentX <= BORDERS_APPROACHING_LIMIT){//Если особь дошла до левого края сцены
				newPosition.x = currentX + stepLength;
				amINearBorder = true;
				}else{
					newPosition.x = currentX - stepLength;
					}
		}
		
		protected function onStay(currentY:int, currentX:int):void{
			newPosition.x = currentX;
			newPosition.y = currentY;
			};
		
		protected function onBeginChoisingPosition(currentY:int, currentX:int):void{
			amINearBorder = false;
			newPosition.x = currentX;
			newPosition.y = currentY;
			};
		
		protected function onEndChoisingPosition():void{
			
		};
	
	}

}
