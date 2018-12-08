package konstantinz.community.comStage{
    //Класс будет находится внутри особи и будет заставлять эту особь двигаться
	import flash.events.Event; 
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
	import konstantinz.community.comStage.*
	import konstantinz.community.auxilarity.*
	
	public class StepDispatcher extends EventDispatcher{
		
		private const IMMORTAL_SIGHN:int = -2;
		private var indState:String;
		private var lifeTime:int;
		private var pauseTime:int;
		private var messenger:Messenger;
		
		public static const DO_STEP:String = 'do_step';//Событие посылается особи, внутри которой находится экземпляр этого класса
		public static const STEP_DONE:String = 'step_done';
		public static const SUSPEND:String = 'suspend';
		
		public var indNumber:int//Номер особи, посылающей событие
		
		function StepDispatcher(){
			indState = "moving";
			indNumber = 0;
			lifeTime = IMMORTAL_SIGHN;
			messenger = new Messenger('3');
			messenger.setMessageMark('Step dispatcher');
			messenger.message('Step dispatcher ' + indNumber  + ' has been created');
			}
			
		public function setState(NewState:String, statementTime:int = 0):void{//Через эту функцию можно влиять на состояние особи
			switch(NewState){
				case 'moving':
					indState = 'moving';
				break;
				case 'suspend':
					indState = 'suspend';
					pauseTime = statementTime;
					dispatchEvent(new Event(StepDispatcher.SUSPEND));
				break;
				case 'stop':
					indState = 'stop';
				break;
				case 'dead':
					indState = 'dead';
				break;
				
				default:
					indState = 'moving';
				break;
				}
			}
		public function getState():String{
			return indState;
			}
		
		public function doStep():void{//Сигнал приходит от предыдущей особи
			if(indState != 'suspend' && pauseTime < 0){
			  if(lifeTime != IMMORTAL_SIGHN){//Если особь не бессмертная
				lifeTime --;
				if(lifeTime < -1 && indState != 'dead' && indState != 'suspend'){
					killIndividual();
					}
				}
			dispatchEvent(new Event(StepDispatcher.DO_STEP));
			}else{
				pauseTime--;
			
				if(pauseTime < 0){
					pauseTime = -1
					indState = 'moving';
					}
				}
			}
		public function stepDone():void{
			dispatchEvent(new Event(StepDispatcher.STEP_DONE));
			
			}
		public function killIndividual():void{
			indState = 'dead';
			}
		public function setLifeTime(newLifeTime:int):void{
			lifeTime = newLifeTime;
			}
		public function setIndividualNumber(newIndNumber:int):void{
			indNumber = newIndNumber;
			}
	
	}
}
